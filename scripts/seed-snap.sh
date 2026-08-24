#!/usr/bin/env bash
set -Eeuo pipefail

if [[ $# -ne 2 ]]; then
    echo "Uso: $0 <raíz-del-chroot> <lista-de-snaps>" >&2
    exit 2
fi

chroot_dir=$1
snap_list=$2
seed_dir="$chroot_dir/var/lib/snapd/seed"
model_assertion="$seed_dir/assertions/model"
prepared_dir=$(mktemp -d)
trap 'rm -rf -- "$prepared_dir"' EXIT

[[ -s "$model_assertion" ]] || {
    echo "La imagen base no contiene la assertion de modelo de snapd." >&2
    exit 1
}
[[ -s "$snap_list" ]] || {
    echo "Falta la lista de snaps: $snap_list" >&2
    exit 1
}

prepare_args=(--classic --arch=amd64)
while IFS= read -r snap_spec; do
    [[ -z "$snap_spec" || "$snap_spec" == \#* ]] && continue
    prepare_args+=(--snap="$snap_spec")
done < "$snap_list"

snap prepare-image "${prepare_args[@]}" \
    "$model_assertion" "$prepared_dir"
prepared_seed="$prepared_dir/var/lib/snapd/seed"

[[ -s "$prepared_seed/seed.yaml" ]] || {
    echo "snap prepare-image no produjo una semilla válida." >&2
    exit 1
}
rg -q '^[[:space:]-]*name:[[:space:]]+chromium$' \
    "$prepared_seed/seed.yaml" || {
    echo "La semilla preparada no contiene Chromium." >&2
    exit 1
}
if rg -q 'name:[[:space:]]+(firefox|snap-store|ubuntu-desktop-bootstrap)$' \
    "$prepared_seed/seed.yaml"; then
    echo "La semilla preparada contiene software excluido." >&2
    exit 1
fi

# La base live ya trae snaps de instalación montados. Se elimina su estado
# instalado completo; snapd reconstruirá únicamente la semilla aprobada en el
# primer arranque.
rm -rf -- "$chroot_dir/var/lib/snapd" "$chroot_dir/var/cache/snapd" \
    "$chroot_dir/var/snap" "$chroot_dir/snap"
find "$chroot_dir/etc/systemd/system" -type f -o -type l \
    | while IFS= read -r unit; do
        case "${unit##*/}" in
            snap-*.mount|snap.*.service) rm -f -- "$unit" ;;
        esac
    done

mkdir -p "$seed_dir"
rsync -a --delete "$prepared_seed/" "$seed_dir/"
install -d -m 0755 "$chroot_dir/var/cache/snapd" \
    "$chroot_dir/var/snap" "$chroot_dir/snap"

if find "$chroot_dir/var/lib/snapd" "$chroot_dir/etc/systemd/system" \
    -iname '*ubuntu*desktop*bootstrap*' -print -quit | grep -q .; then
    echo "Persisten archivos del instalador snap excluido." >&2
    exit 1
fi
