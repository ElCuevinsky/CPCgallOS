#!/usr/bin/env bash
set -Eeuo pipefail

export DEBIAN_FRONTEND=noninteractive
export LC_ALL=C

payload=/tmp/cpcgallos
nvidia_package=${NVIDIA_DRIVER_PACKAGE:-nvidia-driver-580-open}

# The minimal base image ships an offline CD-ROM source. The ISO contents are
# already unpacked into the chroot, so leaving this source enabled makes APT
# fail before it can use the Ubuntu mirrors.
if [[ -f /etc/apt/sources.list.d/cdrom.sources ]]; then
    mv /etc/apt/sources.list.d/cdrom.sources \
        /etc/apt/sources.list.d/cdrom.sources.disabled
fi
rm -f /etc/apt/sources.list.d/cdrom.list
if [[ -f /etc/apt/sources.list ]]; then
    sed -i -E '/^[^#].*(cdrom:|file:\/{2,3}cdrom)/s/^/# /' \
        /etc/apt/sources.list
fi

apt-get update
mapfile -t packages < <(sed -E '/^[[:space:]]*(#|$)/d' "$payload/config/packages.list")
apt-get install -y --no-install-recommends "${packages[@]}"
apt-get install -y "$nvidia_package"

# OpenJDK 25 de resolute no localiza libjli.so mediante su RPATH en el chroot.
cat >/etc/ld.so.conf.d/cpcgallos-java.conf <<'EOF'
/usr/lib/jvm/default-java/lib
EOF
ldconfig
javac -version
java -version

# Algunos postinst consultan uname y generan un initrd del kernel anfitrión
# WSL. Solo se conserva material de kernels que existan dentro de la imagen.
host_kernel=$(uname -r)
if [[ ! -d "/lib/modules/$host_kernel" ]]; then
    rm -f -- "/boot/initrd.img-$host_kernel" \
        "/boot/vmlinuz-$host_kernel" "/boot/config-$host_kernel" \
        "/boot/System.map-$host_kernel"
fi

apt-get purge -y firefox update-manager || true

install -d -m 0755 /etc/apt/keyrings
curl -fsSL https://packages.microsoft.com/keys/microsoft.asc \
    | gpg --dearmor --yes -o /etc/apt/keyrings/packages.microsoft.gpg
cat >/etc/apt/sources.list.d/vscode.sources <<'EOF'
Types: deb
URIs: https://packages.microsoft.com/repos/code
Suites: stable
Components: main
Architectures: amd64
Signed-By: /etc/apt/keyrings/packages.microsoft.gpg
EOF
apt-get update
apt-get install -y --no-install-recommends code

install -d -m 0755 /etc/vscode
install -m 0644 "$payload/config/vscode/policy.json" /etc/vscode/policy.json
install -d -m 0755 /etc/skel/.config/Code/User /etc/skel/.vscode/extensions
install -m 0644 "$payload/config/vscode/settings.json" /etc/skel/.config/Code/User/settings.json
install -m 0644 "$payload/config/system/default-keyboard" /etc/default/keyboard
install -d -m 0755 /etc/skel/.config/xfce4/xfconf/xfce-perchannel-xml
install -m 0644 "$payload/config/system/xfce4-keyboard-layout.xml" \
    /etc/skel/.config/xfce4/xfconf/xfce-perchannel-xml/keyboard-layout.xml

while IFS= read -r extension; do
    [[ -z "$extension" || "$extension" == \#* ]] && continue
    DONT_PROMPT_WSL_INSTALL=1 HOME=/etc/skel \
        code --no-sandbox --user-data-dir=/tmp/vscode-profile \
        --extensions-dir=/etc/skel/.vscode/extensions \
        --install-extension "$extension" --force
done < "$payload/config/vscode/extensions.list"

expected_extensions=$(mktemp)
installed_extensions=$(mktemp)
sed -E '/^[[:space:]]*(#|$)/d' "$payload/config/vscode/extensions.list" \
    | tr '[:upper:]' '[:lower:]' | sort -u > "$expected_extensions"
DONT_PROMPT_WSL_INSTALL=1 HOME=/etc/skel \
    code --no-sandbox --user-data-dir=/tmp/vscode-profile \
    --extensions-dir=/etc/skel/.vscode/extensions \
    --list-extensions | tr '[:upper:]' '[:lower:]' | sort -u > "$installed_extensions"
diff -u "$expected_extensions" "$installed_extensions"
rm -f -- "$expected_extensions" "$installed_extensions"

python3 - /etc/vscode/policy.json \
    /usr/share/code/resources/app/policies/policy.json <<'PY'
import json
from pathlib import Path
import sys

configured = json.loads(Path(sys.argv[1]).read_text(encoding="utf-8"))
supported = json.loads(Path(sys.argv[2]).read_text(encoding="utf-8"))
unknown = sorted(set(configured) - set(supported))
if unknown:
    raise SystemExit(f"Políticas de VS Code no soportadas: {', '.join(unknown)}")
PY

install -d -m 0755 \
    /etc/chromium-browser/policies/managed \
    /etc/chromium/policies/managed \
    /usr/share/cpcgallos/branding \
    /usr/share/cpcgallos/welcome \
    /usr/share/cpcgallos/templates \
    /usr/share/cpcgallos/desktop \
    /usr/share/backgrounds/cpcgallos \
    /etc/xdg/autostart \
    /usr/share/applications
install -m 0644 "$payload/config/chromium/cpcgallos.json" \
    /etc/chromium-browser/policies/managed/cpcgallos.json
install -m 0644 "$payload/config/chromium/cpcgallos.json" \
    /etc/chromium/policies/managed/cpcgallos.json
install -m 0644 "$payload/assets/branding/gallos.jpeg" \
    /usr/share/cpcgallos/branding/gallos.jpeg
install -m 0644 "$payload/assets/branding/cpcgallos-wallpaper.png" \
    /usr/share/backgrounds/cpcgallos/cpcgallos-wallpaper.png
# Xfdesktop 4.20 usa esta ruta compilada como fallback cuando el identificador
# del monitor todavía no tiene propiedades en xfconf. Se conserva el nombre
# esperado por Xubuntu, pero el contenido pasa a ser el fondo de CPCgallOS.
install -m 0644 "$payload/assets/branding/cpcgallos-wallpaper.png" \
    /usr/share/xfce4/backdrops/cpcgallos-wallpaper.png
ln -sfn cpcgallos-wallpaper.png \
    /usr/share/xfce4/backdrops/xubuntu-wallpaper.png
cp -a "$payload/welcome/." /usr/share/cpcgallos/welcome/
cp -a "$payload/config/vscode/templates/." /usr/share/cpcgallos/templates/
for desktop_file in "$payload"/config/system/cpcgallos-desktop-*.desktop; do
    install -m 0755 "$desktop_file" /usr/share/cpcgallos/desktop/
done
install -m 0644 "$payload/config/system/chromium.desktop" \
    /usr/share/applications/chromium.desktop
install -m 0644 "$payload/config/system/cpcgallos-welcome.desktop" \
    /usr/share/applications/cpcgallos-welcome.desktop
install -m 0644 "$payload/config/system/cpcgallos-autostart.desktop" \
    /etc/xdg/autostart/cpcgallos-welcome.desktop
install -m 0755 "$payload/config/system/cpcgallos-session-init" \
    /usr/local/bin/cpcgallos-session-init

install -m 0755 "$payload/config/system/cpcgallos-lockdown" \
    /usr/local/sbin/cpcgallos-lockdown
install -m 0644 "$payload/config/system/cpcgallos-lockdown.service" \
    /etc/systemd/system/cpcgallos-lockdown.service
systemctl enable cpcgallos-lockdown.service
systemctl mask apt-daily.service apt-daily.timer apt-daily-upgrade.service \
    apt-daily-upgrade.timer packagekit.service unattended-upgrades.service || true

# Oculta instaladores y gestores de software sin romper snapd, necesario para Chromium.
find /usr/share/applications /etc/xdg/autostart -maxdepth 1 -type f \( \
    -iname '*install*.desktop' -o \
    -iname '*software*.desktop' -o \
    -iname '*update-manager*.desktop' \
\) -delete

# Configuración XFCE predeterminada: fondo gris de CPC Gallos.
install -d -m 0755 /etc/skel/.config/xfce4/xfconf/xfce-perchannel-xml
cat >/etc/skel/.config/xfce4/xfconf/xfce-perchannel-xml/xfce4-desktop.xml <<'EOF'
<?xml version="1.0" encoding="UTF-8"?>
<channel name="xfce4-desktop" version="1.0">
  <property name="backdrop" type="empty">
    <property name="screen0" type="empty">
      <property name="monitor0" type="empty">
        <property name="workspace0" type="empty">
          <property name="last-image" type="string" value="/usr/share/backgrounds/cpcgallos/cpcgallos-wallpaper.png"/>
          <property name="image-style" type="int" value="5"/>
        </property>
      </property>
    </property>
  </property>
</channel>
EOF

# La ISO base usa dos SquashFS y fija la capa superior en el initramfs. El
# prototipo las consolida en minimal.squashfs, por lo que Casper debe volver al
# descubrimiento normal de la única imagen disponible.
cat >/etc/initramfs-tools/conf.d/default-layer.conf <<'EOF'
LAYERFS_PATH=
EOF
mapfile -t kernel_versions < <(
    find /lib/modules -mindepth 1 -maxdepth 1 -type d -printf '%f\n' | sort -V
)
if ((${#kernel_versions[@]} != 1)); then
    echo "Se esperaba exactamente un kernel instalable; encontrados: ${kernel_versions[*]}" >&2
    exit 1
fi
kernel_version=${kernel_versions[0]}
rm -f -- "/boot/initrd.img-$kernel_version"
update-initramfs -c -k "$kernel_version"
test -s "/boot/initrd.img-$kernel_version"

apt-get clean
rm -rf /tmp/vscode-profile /var/lib/apt/lists/* /tmp/cpcgallos
