#!/usr/bin/env bash
set -Eeuo pipefail

project_root=$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)
: "${CPCGALLOS_GRUB_PASSWORD_HASH:?Define CPCGALLOS_GRUB_PASSWORD_HASH; usa make password}"
# shellcheck disable=SC1091
source "$project_root/config/build.env"

mkdir -p "$project_root/.cache" "$project_root/work" "$project_root/out"
docker build -t cpcgallos-builder:26.04 "$project_root"
docker run --rm --privileged \
    --cpus "$BUILD_CPUS" \
    --memory "$CONTAINER_MEMORY" \
    --memory-swap "$CONTAINER_MEMORY_SWAP" \
    -e CPCGALLOS_GRUB_PASSWORD_HASH \
    -v "$project_root:/src:ro" \
    -v "$project_root/.cache:/cache" \
    -v "$project_root/work:/work" \
    -v "$project_root/out:/out" \
    cpcgallos-builder:26.04 \
    /bin/bash /src/scripts/build.sh
