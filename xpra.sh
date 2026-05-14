#!/bin/sh
set -e
clear
LOG_FILE="install_log.json"
FAILED_PACKAGES=""
XPRA_GPG="/etc/apt/keyrings/xpra.gpg"
printf "[\n" > "$LOG_FILE"
check_debian_stable() {
. /etc/os-release
if [ "$ID" != "debian" ]; then
echo "❌ Apenas Debian suportado"
exit 1
fi
}
is_installed() {
dpkg-query -W -f='${Status}' "$1" 2>/dev/null | grep -q "install ok installed"
}
check_provides() {
apt-cache show "$1" 2>/dev/null | grep -q "Provides:"
}
log_json() {
printf '{"package":"%s","status":"%s"},\n' "$1" "$2" >> "$LOG_FILE"
}
add_failed() {
FAILED_PACKAGES="$FAILED_PACKAGES $1"
}
install_pkg() {
PKG="$1"
if is_installed "$PKG"; then
log_json "$PKG" "installed"
STATUS="✅ Instalado"
return
fi
if apt-get install -y "$PKG" >/dev/null 2>&1; then
if is_installed "$PKG"; then
log_json "$PKG" "installed"
else
log_json "$PKG" "installed_unverified"
add_failed "$PKG"
fi
else
if check_provides "$PKG"; then
log_json "$PKG" "provided"
else
log_json "$PKG" "failed"
add_failed "$PKG"
fi
fi
}
print_pkg() {
printf "📦 %-35s : %s\n" "$1" "$2"
}
install_group() {
NAME="$1"
shift
echo
echo "=================================================="
echo "[ $NAME ]"
echo "=================================================="
for PKG in "$@"; do
if is_installed "$PKG"; then
STATUS="✅ Instalado"
else
printf "📦 %-35s : ⚡ Instalando...\n" "$PKG"
install_pkg "$PKG"
if is_installed "$PKG"; then
STATUS="✅ Instalado"
else
STATUS="❌ Falha"
fi
fi
print_pkg "$PKG" "$STATUS"
done
}
install_xpra_repo() {
echo
echo "=================================================="
echo "[ XPRA REPOSITORY ]"
echo "=================================================="
if [ -f "$XPRA_GPG" ]; then
echo "✔ XPRA GPG já existe"
return
fi
CODENAME=$(grep VERSION_CODENAME /etc/os-release | cut -d= -f2)
mkdir -p /etc/apt/keyrings
curl -fsSL https://xpra.org/gpg.asc | gpg --dearmor -o "$XPRA_GPG" >/dev/null 2>&1 || {
echo "❌ Falha GPG"
add_failed "xpra-gpg"
return
}
echo "deb [signed-by=$XPRA_GPG] https://xpra.org/ $CODENAME main" > /etc/apt/sources.list.d/xpra.list
apt-get update -y >/dev/null 2>&1 || {
echo "❌ Falha apt update XPRA"
add_failed "xpra-update"
return
}
echo "✔ XPRA repo configurado"
}
check_debian_stable
apt-get update -y >/dev/null 2>&1
install_group "ESSENTIALS" git curl wget sudo ca-certificates pkg-config
install_group "XPRA DRIVERS" i965-va-driver x264 va-driver-all vdpau-driver-all intel-media-va-driver-non-free pulseaudio
install_group "GRAPHICS" gstreamer1.0-plugins-base gstreamer1.0-plugins-good gstreamer1.0-plugins-ugly vainfo
install_group "LIBS" libva-drm2 libva-x11-2 libvpx9 libx264-dev libwebp-dev libgtk-3-dev libsystemd-dev
install_xpra_repo
install_group "XPRA" xpra xpra-client-gtk3 xpra-codecs-extras xpra-codecs xpra-common xpra-client xpra-audio xpra-x11 xpra-html5 xpra-server
echo
echo "=================================================="
echo "[ XPRA VERSION ]"
echo "=================================================="
if command -v xpra >/dev/null 2>&1; then
XPRA_VERSION=$(xpra --version | head -n1)
echo "✔ $XPRA_VERSION"
else
echo "❌ XPRA não instalado"
add_failed "xpra-binary"
fi
echo
echo "=================================================="
echo "[ FINAL CHECK - FAILED PACKAGES ]"
echo "=================================================="
if [ -z "$FAILED_PACKAGES" ]; then
echo "✔ Tudo instalado com sucesso"
else
for PKG in $FAILED_PACKAGES; do
echo "❌ $PKG"
done
fi
sed -i '$ s/,$//' "$LOG_FILE"
printf "]\n" >> "$LOG_FILE"
echo
echo "📄 Log salvo: $LOG_FILE"
