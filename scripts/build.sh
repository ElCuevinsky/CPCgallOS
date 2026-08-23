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

for command in curl xorriso unsquashfs mksquashfs rsync sha256sum snap; do
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
cleanup_mounts
mount_points=()

"$project_root/scripts/seed-snap.sh" "$chroot_dir" chromium
"$project_root/scripts/configure-boot.sh" \
    "$iso_tree" "$project_root/config/grub/grub.cfg.in" \
    "$CPCGALLOS_GRUB_PASSWORD_HASH"

# Conserva el kernel de la ISO base. El driver NVIDIA queda dentro del squashfs;
# una prueba de Secure Boot forma parte de la matriz obligatoria del prototipo.
rm -f "$squashfs"
if [[ -f "$live_layer" ]]; then
    rm -f "$live_layer" \
        "$iso_tree/casper/${squashfs_stem}.live.manifest" \
        "$iso_tree/casper/${squashfs_stem}.live.manifest.full" \
        "$iso_tree/casper/${squashfs_stem}.live.size"
    if [[ -f "$iso_tree/casper/install-sources.yaml" ]]; then
        sed -i 's/type: fsimage-layered/type: fsimage/' \
            "$iso_tree/casper/install-sources.yaml"
    fi
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
        find . -type f ! -name md5sum.txt -print0 \
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

sha256sum "$output_iso" | tee "$output_iso.sha256"
echo "ISO creada: $output_iso"
