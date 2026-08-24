#!/usr/bin/env bash
set -Eeuo pipefail

project_root=$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)
# La ruta se resuelve desde la ubicación del script.
# shellcheck disable=SC1091
source "$project_root/config/build.env"

if [[ ${EUID:-$(id -u)} -ne 0 ]]; then
    echo "La construcción debe ejecutarse como root dentro del contenedor." >&2
    exit 1
fi

: "${CPCGALLOS_GRUB_PASSWORD_HASH:?Define CPCGALLOS_GRUB_PASSWORD_HASH; usa make password}"

cache_dir=${CPCGALLOS_CACHE_DIR:-/cache}
work_dir=${CPCGALLOS_WORK_DIR:-/work}
out_dir=${CPCGALLOS_OUT_DIR:-/out}
base_iso="$cache_dir/$BASE_ISO_NAME"
iso_tree="$work_dir/iso"
chroot_dir="$work_dir/chroot"
layer_dir="$work_dir/layers"
output_iso="$out_dir/$OUTPUT_ISO_NAME"

mkdir -p "$cache_dir" "$work_dir" "$out_dir"

for command in chroot curl mount xorriso unsquashfs mksquashfs rsync \
    sha256sum snap; do
    command -v "$command" >/dev/null || {
        echo "Falta la herramienta requerida: $command" >&2
        exit 1
    }
done

if [[ ! -f "$base_iso" ]]; then
    echo "Descargando $BASE_ISO_NAME..."
    curl --fail --location --continue-at - --output "$base_iso" "$BASE_ISO_URL"
fi
printf '%s  %s\n' "$BASE_ISO_SHA256" "$base_iso" | sha256sum --check -

rm -rf -- "$iso_tree" "$chroot_dir" "$layer_dir"
mkdir -p "$iso_tree" "$chroot_dir" "$layer_dir"
xorriso -osirrox on -indev "$base_iso" -extract / "$iso_tree"
chmod -R u+w "$iso_tree"

if [[ -f "$iso_tree/casper/minimal.squashfs" ]]; then
    squashfs="$iso_tree/casper/minimal.squashfs"
elif [[ -f "$iso_tree/casper/filesystem.squashfs" ]]; then
    squashfs="$iso_tree/casper/filesystem.squashfs"
else
    echo "No se encontró una capa base squashfs compatible en casper/." >&2
    exit 1
fi
squashfs_stem=$(basename "$squashfs" .squashfs)

mount_points=()
cleanup_mounts() {
    local index
    for ((index=${#mount_points[@]}-1; index>=0; index--)); do
        umount -lf "${mount_points[$index]}" 2>/dev/null || true
    done
}
trap cleanup_mounts EXIT

live_layer="$iso_tree/casper/${squashfs_stem}.live.squashfs"
if [[ -f "$live_layer" ]]; then
    base_mount="$layer_dir/base"
    live_mount="$layer_dir/live"
    merged_mount="$layer_dir/merged"
    mkdir -p "$base_mount" "$live_mount" "$merged_mount"
    mount -t squashfs -o loop,ro "$squashfs" "$base_mount"
    mount_points+=("$base_mount")
    mount -t squashfs -o loop,ro "$live_layer" "$live_mount"
    mount_points+=("$live_mount")
    mount -t overlay overlay -o "lowerdir=$live_mount:$base_mount" "$merged_mount"
    mount_points+=("$merged_mount")
    rsync -aHAX "$merged_mount/." "$chroot_dir/"
    cleanup_mounts
    mount_points=()
else
    unsquashfs -d "$chroot_dir" "$squashfs"
fi

mkdir -p "$chroot_dir/tmp/cpcgallos"
rsync -a "$project_root/config" "$project_root/assets" "$project_root/welcome" \
    "$chroot_dir/tmp/cpcgallos/"
install -m 0755 "$project_root/scripts/chroot-customize.sh" \
    "$chroot_dir/tmp/cpcgallos/chroot-customize.sh"
resolv_backup="$chroot_dir/etc/resolv.conf.cpcgallos-original"
resolv_existed=false
if [[ -e "$chroot_dir/etc/resolv.conf" || -L "$chroot_dir/etc/resolv.conf" ]]; then
    cp -a -- "$chroot_dir/etc/resolv.conf" "$resolv_backup"
    resolv_existed=true
fi
cp -L --remove-destination /etc/resolv.conf "$chroot_dir/etc/resolv.conf"

for source in /dev /dev/pts /proc /sys /run; do
    target="$chroot_dir$source"
    mkdir -p "$target"
    mount --bind "$source" "$target"
    mount_points+=("$target")
done

chroot "$chroot_dir" /usr/bin/env \
    NVIDIA_DRIVER_PACKAGE="$NVIDIA_DRIVER_PACKAGE" \
    /bin/bash /tmp/cpcgallos/chroot-customize.sh

mapfile -t kernel_versions < <(
    find "$chroot_dir/lib/modules" -mindepth 1 -maxdepth 1 -type d \
        -printf '%f\n' | sort -V
)
if ((${#kernel_versions[@]} != 1)); then
    echo "Se esperaba exactamente un kernel en la imagen." >&2
    exit 1
fi
kernel_version=${kernel_versions[0]}
install -m 0644 "$chroot_dir/boot/initrd.img-$kernel_version" \
    "$iso_tree/casper/initrd"
install -m 0644 "$chroot_dir/boot/vmlinuz-$kernel_version" \
    "$iso_tree/casper/vmlinuz"

# Casper genera un UUID nuevo dentro de cada initramfs y solo acepta medios
# cuyo marcador .disk coincida. Sincroniza ambos y comprueba además que la
# referencia a la antigua capa live ya no esté presente.
initrd_probe=/tmp/cpcgallos-initrd-probe
rm -rf -- "$chroot_dir$initrd_probe"
install -m 0644 "$iso_tree/casper/initrd" \
    "$chroot_dir/tmp/cpcgallos-initrd"
chroot "$chroot_dir" unmkinitramfs /tmp/cpcgallos-initrd "$initrd_probe"
grep -q '^LAYERFS_PATH=$' \
    "$chroot_dir$initrd_probe/conf/conf.d/default-layer.conf"
install -m 0644 "$chroot_dir$initrd_probe/conf/uuid.conf" \
    "$iso_tree/.disk/casper-uuid-generic"
rm -rf -- "$chroot_dir$initrd_probe"
rm -f -- "$chroot_dir/tmp/cpcgallos-initrd"
rm -f -- "$chroot_dir/boot/initrd.img-$kernel_version"
rm -f -- "$chroot_dir/etc/resolv.conf"
if [[ "$resolv_existed" == true ]]; then
    mv -- "$resolv_backup" "$chroot_dir/etc/resolv.conf"
fi
cleanup_mounts
mount_points=()

"$project_root/scripts/seed-snap.sh" \
    "$chroot_dir" "$project_root/config/snaps.list"
"$project_root/scripts/configure-boot.sh" \
    "$iso_tree" "$project_root/config/grub/grub.cfg.in" \
    "$CPCGALLOS_GRUB_PASSWORD_HASH"

# El kernel firmado y su initramfs regenerado quedan sincronizados con el
# sistema raíz. Secure Boot y NVIDIA físico siguen en la matriz posterior.
rm -f "$squashfs"
if [[ -f "$live_layer" ]]; then
    # casper's initramfs requires the live layer to be present even though the
    # build customizes the merged filesystem and repacks the base layer.
    # Keep the original layer and its metadata in the final ISO.
    :
fi
mksquashfs "$chroot_dir" "$squashfs" \
    -comp xz \
    -b 1M \
    -processors "$BUILD_CPUS" \
    -mem "$SQUASHFS_MEMORY" \
    -no-progress \
    -noappend

du -sx --block-size=1 "$chroot_dir" | cut -f1 \
    > "$iso_tree/casper/${squashfs_stem}.size"
# Las variables pertenecen al formato de dpkg-query.
# shellcheck disable=SC2016
chroot "$chroot_dir" dpkg-query -W --showformat='${Package} ${Version}\n' \
    > "$iso_tree/casper/${squashfs_stem}.manifest"
cp "$iso_tree/casper/${squashfs_stem}.manifest" \
    "$iso_tree/casper/${squashfs_stem}.manifest.full"

if [[ -f "$iso_tree/md5sum.txt" ]]; then
    (
        cd "$iso_tree"
        # xorriso actualiza la Boot Info Table de esta imagen al grabar la ISO,
        # por lo que su MD5 previo al repaquetado nunca puede coincidir.
        find . -type f ! -name md5sum.txt \
            ! -path './boot/grub/i386-pc/eltorito.img' -print0 \
            | sort -z \
            | xargs -0 md5sum
    ) > "$iso_tree/md5sum.txt"
fi

rm -f "$output_iso"
xorriso -indev "$base_iso" -outdev "$output_iso" \
    -boot_image any replay \
    -volid "$VOLUME_ID" \
    -update_r "$iso_tree" / \
    -commit

(
    cd "$out_dir"
    sha256sum "$OUTPUT_ISO_NAME"
) | tee "$output_iso.sha256"
echo "ISO creada: $output_iso"
