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
    config/system/cpcgallos-desktop-cpp-template.desktop
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

sed -E '/^[[:space:]]*(#|$)/d' config/whitelist.txt | sort > /tmp/cpcgallos-domains.expected
jq -r '.URLAllowlist[] | select(test("^[a-z0-9.-]+\\.[a-z]{2,}$"))' config/chromium/cpcgallos.json | sort \
    > /tmp/cpcgallos-domains.actual
diff -u /tmp/cpcgallos-domains.expected /tmp/cpcgallos-domains.actual
rm -f /tmp/cpcgallos-domains.expected /tmp/cpcgallos-domains.actual

jq -e '.URLBlocklist == ["http://*", "https://*"] and
    .ExtensionInstallBlocklist == ["*"] and
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

echo "Validación estática completada correctamente."
