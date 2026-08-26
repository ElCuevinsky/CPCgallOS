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
    config/system/cpcgallos-desktop-chromium.desktop
    config/system/cpcgallos-desktop-vscode.desktop
    config/system/cpcgallos-desktop-codeblocks.desktop
    config/system/cpcgallos-desktop-notepad.desktop
    config/system/cpcgallos-desktop-calculator.desktop
    config/system/default-keyboard
    config/system/xfce4-keyboard-layout.xml
    assets/branding/gallos.jpeg
    assets/branding/cpcgallos-wallpaper.png
)

for path in "${required[@]}"; do
    [[ -s "$path" ]] || {
        echo "Falta o está vacío: $path" >&2
        exit 1
    }
done

template_files=(
    config/vscode/templates/cpp/.vscode/tasks.json
    config/vscode/templates/cpp/.vscode/launch.json
    config/vscode/templates/cpp/main.cpp
    config/vscode/templates/java/.vscode/tasks.json
    config/vscode/templates/java/.vscode/launch.json
    config/vscode/templates/java/Main.java
    config/vscode/templates/python/.vscode/tasks.json
    config/vscode/templates/python/.vscode/launch.json
    config/vscode/templates/python/main.py
)
for path in "${template_files[@]}"; do
    [[ -s "$path" ]] || {
        echo "Falta la plantilla de VS Code: $path" >&2
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

jq -e '.URLBlocklist == null and .URLAllowlist == null and
    .ExtensionInstallBlocklist == ["*"]' \
    config/chromium/cpcgallos.json >/dev/null || {
    echo "Chromium no debe tener una whitelist ni una URLBlocklist activa." >&2
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
jq -e '."security.workspace.trust.enabled" == false' \
    config/vscode/settings.json >/dev/null || {
    echo "VS Code debe iniciar sin Restricted Mode por confianza de workspace." >&2
    exit 1
}
jq -e '.tasks | any(.[]; .label == "CPCgallOS: g++ build active file")' \
    config/vscode/templates/cpp/.vscode/tasks.json >/dev/null
jq -e '.configurations | any(.[]; .preLaunchTask == "CPCgallOS: g++ build active file")' \
    config/vscode/templates/cpp/.vscode/launch.json >/dev/null

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
rg -q 'XKBLAYOUT="latam"' config/system/default-keyboard
rg -q 'DivyanshuAgrawal\.competitive-programming-helper' config/vscode/extensions.list
rg -q 'mousepad' config/system/cpcgallos-desktop-notepad.desktop
rg -q 'galculator' config/system/cpcgallos-desktop-calculator.desktop
for package in galculator keyboard-configuration mousepad x11-xkb-utils xkb-data; do
    rg -q "^[[:space:]]*${package}[[:space:]]*$" config/packages.list || {
        echo "Falta el paquete requerido: ${package}" >&2
        exit 1
    }
done

echo "Validación estática completada correctamente."
