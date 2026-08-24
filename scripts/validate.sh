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
    config/snaps.list
    config/chromium/cpcgallos.json
    config/vscode/policy.json
    config/vscode/settings.json
    config/grub/grub.cfg.in
    config/system/cpcgallos-session-init
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
    jq -e --arg domain "[*.]$domain" '.URLAllowlist | index($domain) != null' \
        config/chromium/cpcgallos.json >/dev/null || {
        echo "Dominio ausente de la política Chromium: $domain" >&2
        exit 1
    }
done

jq -e '.URLBlocklist == ["*"] and
    .ExtensionInstallBlocklist == ["*"] and
    (.URLAllowlist | index("file://*") != null) and
    (.URLAllowlist | index("file:///*") != null)' \
    config/chromium/cpcgallos.json >/dev/null || {
    echo "Las políticas de bloqueo de Chromium no son las esperadas." >&2
    exit 1
}

diff -u \
    <(sed -E '/^[[:space:]]*(#|$)/d' config/vscode/extensions.list | sort -u) \
    <(jq -r '.AllowedExtensions | to_entries[] |
        select(.value == true) | .key' config/vscode/policy.json | sort -u)
jq -e '.ExtensionsAutoUpdate == "off" and .TelemetryLevel == "off" and
    .UpdateMode == "none" and .ChatAgentMode == false and
    .ChatMCP == "none" and .ChatPluginsEnabled == false' \
    config/vscode/policy.json >/dev/null || {
    echo "Las políticas de bloqueo de VS Code no son las esperadas." >&2
    exit 1
}

[[ $(rg -c '^menuentry ' config/grub/grub.cfg.in) -eq 2 ]] || {
    echo "El menú GRUB debe contener exactamente dos entradas." >&2
    exit 1
}
[[ $(rg -c '^[[:space:]]+linux .* toram ' config/grub/grub.cfg.in) -eq 2 ]] || {
    echo "Ambas entradas GRUB deben usar toram." >&2
    exit 1
}
rg -q '^menuentry .*persistente.*--users root' config/grub/grub.cfg.in || {
    echo "El modo persistente no está protegido para root." >&2
    exit 1
}

rg -q '^LAYERFS_PATH=$' scripts/chroot-customize.sh
rg -q 'update-initramfs -c -k' scripts/chroot-customize.sh
rg -q 'boot/initrd.img-' scripts/build.sh
rg -q 'casper-uuid-generic' scripts/build.sh
rg -q "! -path './boot/grub/i386-pc/eltorito.img'" scripts/build.sh

echo "Validación estática completada correctamente."
