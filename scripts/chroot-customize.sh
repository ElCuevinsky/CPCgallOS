#!/usr/bin/env bash
set -Eeuo pipefail

export DEBIAN_FRONTEND=noninteractive
export LC_ALL=C

payload=/tmp/cpcgallos
nvidia_package=${NVIDIA_DRIVER_PACKAGE:-nvidia-driver-580-open}

apt-get update
mapfile -t packages < <(sed -E '/^[[:space:]]*(#|$)/d' "$payload/config/packages.list")
apt-get install -y --no-install-recommends "${packages[@]}"
apt-get install -y "$nvidia_package"
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

while IFS= read -r extension; do
    [[ -z "$extension" || "$extension" == \#* ]] && continue
    HOME=/etc/skel code --no-sandbox --user-data-dir=/tmp/vscode-profile \
        --extensions-dir=/etc/skel/.vscode/extensions \
        --install-extension "$extension" --force
done < "$payload/config/vscode/extensions.list"

install -d -m 0755 \
    /etc/chromium-browser/policies/managed \
    /usr/share/cpcgallos/branding \
    /usr/share/cpcgallos/welcome \
    /usr/share/backgrounds/cpcgallos \
    /etc/xdg/autostart \
    /usr/share/applications
install -m 0644 "$payload/config/chromium/cpcgallos.json" \
    /etc/chromium-browser/policies/managed/cpcgallos.json
install -m 0644 "$payload/assets/branding/gallos.jpeg" \
    /usr/share/cpcgallos/branding/gallos.jpeg
install -m 0644 "$payload/assets/branding/cpcgallos-wallpaper.png" \
    /usr/share/backgrounds/cpcgallos/cpcgallos-wallpaper.png
cp -a "$payload/welcome/." /usr/share/cpcgallos/welcome/
install -m 0644 "$payload/config/system/chromium.desktop" \
    /usr/share/applications/chromium.desktop
install -m 0644 "$payload/config/system/cpcgallos-welcome.desktop" \
    /usr/share/applications/cpcgallos-welcome.desktop
install -m 0644 "$payload/config/system/cpcgallos-autostart.desktop" \
    /etc/xdg/autostart/cpcgallos-welcome.desktop

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

apt-get clean
rm -rf /tmp/vscode-profile /var/lib/apt/lists/* /tmp/cpcgallos
