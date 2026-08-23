#!/usr/bin/env bash
set -Eeuo pipefail

if [[ $# -ne 2 ]]; then
    echo "Uso: $0 <raíz-del-chroot> <snap>" >&2
    exit 2
fi

chroot_dir=$1
snap_name=$2
seed_dir="$chroot_dir/var/lib/snapd/seed"
download_dir=$(mktemp -d)
trap 'rm -rf -- "$download_dir"' EXIT

mkdir -p "$seed_dir/snaps" "$seed_dir/assertions"
(
    cd "$download_dir"
    snap download "$snap_name" --channel=latest/stable
)

snap_file=$(find "$download_dir" -maxdepth 1 -type f -name "${snap_name}_*.snap" -print -quit)
assert_file=$(find "$download_dir" -maxdepth 1 -type f -name "${snap_name}_*.assert" -print -quit)

if [[ -z "$snap_file" || -z "$assert_file" ]]; then
    echo "No se pudo descargar el snap y su assertion: $snap_name" >&2
    exit 1
fi

install -m 0644 "$snap_file" "$seed_dir/snaps/"
install -m 0644 "$assert_file" "$seed_dir/assertions/"

python3 - "$seed_dir/seed.yaml" "$snap_name" "$(basename "$snap_file")" <<'PY'
from pathlib import Path
import sys

path = Path(sys.argv[1])
name = sys.argv[2]
filename = sys.argv[3]
lines = path.read_text(encoding="utf-8").splitlines()

preamble = []
entries = []
current = []
for line in lines:
    if line == "  -":
        if current:
            entries.append(current)
        current = [line]
    elif current:
        current.append(line)
    else:
        preamble.append(line)
if current:
    entries.append(current)

remove = {name, "firefox", "snap-store", "ubuntu-desktop-bootstrap"}
entries = [entry for entry in entries if not any(
    line.strip().startswith("name:") and line.split(":", 1)[1].strip() in remove
    for line in entry
)]
entries.append([
    "  -",
    f"    name: {name}",
    "    channel: latest/stable",
    f"    file: {filename}",
])

output = preamble[:]
for entry in entries:
    output.extend(entry)
path.write_text("\n".join(output) + "\n", encoding="utf-8")
PY

find "$seed_dir/snaps" -maxdepth 1 -type f \( \
    -name 'firefox_*.snap' -o \
    -name 'snap-store_*.snap' -o \
    -name 'ubuntu-desktop-bootstrap_*.snap' \
\) -delete
find "$seed_dir/assertions" -maxdepth 1 -type f \( \
    -name 'firefox_*.assert' -o \
    -name 'snap-store_*.assert' -o \
    -name 'ubuntu-desktop-bootstrap_*.assert' \
\) -delete
