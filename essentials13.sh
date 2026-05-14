#!/bin/sh
set -e
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

check_debian_stable

install_group "ESSENTIALS 13" build-essential firmware-linux lsb-release apt-transport-https lsof gnu-which module-assistant ca-certificates aptitude sudo wget acl git curl perl tar unzip lzip xorg xvfb xauth pulseaudio alsa-utils alsa-tools libasound2t64 libasound2-dev udns-utils net-tools rfkill screenfetch cmake g++ gcc make automake autoconf flex bison bc gdb gnupg gnutls-bin libjwt-gnutls-dev

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
