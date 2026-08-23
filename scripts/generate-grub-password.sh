#!/usr/bin/env bash
set -Eeuo pipefail

if ! command -v grub-mkpasswd-pbkdf2 >/dev/null 2>&1; then
    echo "Falta grub-mkpasswd-pbkdf2 (paquete grub-common)." >&2
    exit 1
fi

echo "La contraseña se solicitará dos veces y solo se imprimirá el hash PBKDF2."
grub-mkpasswd-pbkdf2 | awk '/grub.pbkdf2/ { print $NF }'
