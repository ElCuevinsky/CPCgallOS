#!/usr/bin/env bash
set -Eeuo pipefail

project_root=$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)
cd "$project_root"

for command in jq rg; do
    command -v "$command" >/dev/null || {
        echo "Falta el validador requerido: $command" >&2
        exit 1
    }
done

required=(
    README.md
    config/build.env
    config/packages.list
    config/chromium/cpcgallos.json
    config/vscode/policy.json
    config/vscode/settings.json
    config/grub/grub.cfg.in
    assets/branding/gallos.jpeg
    assets/branding/cpcgallos-wallpaper.png
)

for path in "${required[@]}"; do
    [[ -s "$path" ]] || {
        echo "Falta o está vacío: $path" >&2
        exit 1
    }
done

for json in config/chromium/cpcgallos.json config/vscode/policy.json \
    config/vscode/settings.json; do
    jq empty "$json"
done

mapfile -t scripts < <(find scripts -maxdepth 1 -type f -name '*.sh' -print | sort)
if command -v shellcheck >/dev/null 2>&1; then
    shellcheck "${scripts[@]}"
else
    bash -n "${scripts[@]}"
    echo "Aviso: shellcheck no está instalado; se ejecutó bash -n." >&2
fi

if rg -n '(PASSWORD|TOKEN|SECRET)=' \
    --glob '!scripts/validate.sh' \
    --glob '!work/**' \
    --glob '!.cache/**' \
    --glob '!out/**' \
    .; then
    echo "Posible secreto asignado dentro del repositorio." >&2
    exit 1
fi

expected_domains=$(sed -E '/^[[:space:]]*(#|$)/d' config/whitelist.txt | sort)
for domain in $expected_domains; do
    jq -e --arg domain "$domain" '.URLAllowlist | index($domain) != null' \
        config/chromium/cpcgallos.json >/dev/null || {
        echo "Dominio ausente de la política Chromium: $domain" >&2
        exit 1
    }
done

echo "Validación estática completada correctamente."
