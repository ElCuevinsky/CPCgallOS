#!/usr/bin/env bash
set -Eeuo pipefail

if [[ $# -ne 3 ]]; then
    echo "Uso: $0 <árbol-iso> <plantilla-grub> <hash-pbkdf2>" >&2
    exit 2
fi

iso_tree=$1
template=$2
password_hash=$3

if [[ ! "$password_hash" =~ ^grub\.pbkdf2\.sha512\. ]]; then
    echo "CPCGALLOS_GRUB_PASSWORD_HASH no parece un hash PBKDF2 de GRUB." >&2
    exit 1
fi

if [[ ! -f "$iso_tree/boot/grub/grub.cfg" ]]; then
    echo "La ISO base no contiene boot/grub/grub.cfg." >&2
    exit 1
fi

sed "s|@GRUB_PASSWORD_HASH@|$password_hash|g" "$template" \
    > "$iso_tree/boot/grub/grub.cfg"

# Algunas variantes incluyen un loopback.cfg usado por Ventoy/grub loopback.
if [[ -f "$iso_tree/boot/grub/loopback.cfg" ]]; then
    sed "s|@GRUB_PASSWORD_HASH@|$password_hash|g" "$template" \
        > "$iso_tree/boot/grub/loopback.cfg"
fi
