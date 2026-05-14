#!/bin/bash
apt update > /dev/null 2>&1
apt upgrade -y > /dev/null 2>&1
apt install -y curl > /dev/null 2>&1

curl -fsSL https://raw.githubusercontent.com/coribicode/linux/main/debian_repository.sh | sh
curl -fsSL https://raw.githubusercontent.com/coribicode/linux/main/essentials13.sh | sh
curl -fsSL https://raw.githubusercontent.com/coribicode/linux/main/xpra.sh | sh
curl -fsSL https://raw.githubusercontent.com/coribicode/linux/main/wine-stable.sh | sh

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

install_group "XPRA-PAINEL-PY" python3 python3-venv python3-pyqt5 python3-tk python3-psutil python3-pyqt5.qtsvg python3-netifaces systemd-container cgroup-tools x11-xserver-utils procps psmisc cabextract zenity xdg-utils wmctrl p7zip-full zram-tools unzip

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

echo "=================================================="
echo "[ SERVICE XPRA PAINEL ]"
echo "=================================================="

clear
USER="xpra-painel"
USER_PASSWORD="123"
USER_EXISTS=$(id "$USER" >/dev/null 2>&1; echo $?)
if [ "$USER_EXISTS" -ne 0 ]; then
useradd -m -s /bin/bash "$USER"
echo "$USER:$USER_PASSWORD" | chpasswd
echo "✔ Usuário criado: $USER"
else
echo "✔ Usuário já existe: $USER"
fi
usermod -aG sudo,cdrom,floppy,audio,dip,video,plugdev,users,netdev "$USER"
SUDOERS_FILE="/etc/sudoers.d/xpra-painel"
if [ ! -f "$SUDOERS_FILE" ]; then
cat <<'EOF' > "$SUDOERS_FILE"
%sudo ALL=(ALL:ALL) NOPASSWD: ALL
EOF
chmod 440 "$SUDOERS_FILE"
echo "✔ Arquivo sudoers criado"
else
echo "✔ Arquivo sudoers já existe"
fi
XPRA_USER="$USER"
XPRA_USER_UID=$(id -u "$XPRA_USER")
XPRA_USER_DISPLAY="$XPRA_USER_UID"
XPRA_USER_PORT=$(("$XPRA_USER_UID" * 10))
XPRA_USER_RUNTIME_DIR="/run/user/$XPRA_USER_UID"
mkdir -p "$XPRA_USER_RUNTIME_DIR"
chown "$XPRA_USER:$XPRA_USER" "$XPRA_USER_RUNTIME_DIR"
chmod 700 "$XPRA_USER_RUNTIME_DIR"
START_SCRIPT="/usr/local/bin/start_xpra_user.sh"
cat <<'EOF' > "$START_SCRIPT"
#!/bin/bash
USER=$1
DISPLAY_NUM=$2
PORT=$3
USER_UID=$(id -u "$USER")
RUNTIME_DIR="/run/user/$USER_UID"
mkdir -p "$RUNTIME_DIR"
chown "$USER:$USER" "$RUNTIME_DIR"
chmod 700 "$RUNTIME_DIR"
export XDG_RUNTIME_DIR="$RUNTIME_DIR"
export DISPLAY=":$DISPLAY_NUM"
sudo -u "$USER" \
XDG_RUNTIME_DIR="$RUNTIME_DIR" \
DISPLAY=":$DISPLAY_NUM" \
xpra start ":$DISPLAY_NUM" \
--daemon=no \
--systemd-run=no \
--pulseaudio=no \
--border=no \
--opengl=on \
--encoding=h264 \
--video-encoders=nvenc,x264 \
--quality=90 \
--min-quality=70 \
--speed=100 \
--compress=0 \
--use-display=no \
--exit-with-children=no \
--bind-tcp=0.0.0.0:$PORT \
--html=on \
--start-child="sudo python3 /opt/painel.py"
EOF
chmod +x "$START_SCRIPT"
echo "✔ Script XPRA atualizado"
SERVICE_FILE="/etc/systemd/system/xpra-$XPRA_USER.service"
cat <<EOF > "$SERVICE_FILE"
[Unit]
Description=XPRA for Multiple MetaTrader5
After=network.target
[Service]
Type=simple
ExecStart=$START_SCRIPT $XPRA_USER $XPRA_USER_DISPLAY $XPRA_USER_PORT
Restart=on-failure
RestartSec=3
[Install]
WantedBy=multi-user.target
EOF
echo "✔ Serviço systemd atualizado"
systemctl daemon-reload
systemctl enable "xpra-$XPRA_USER.service" >/dev/null 2>&1
systemctl restart "xpra-$XPRA_USER.service"
systemctl status "xpra-$XPRA_USER.service" --no-pager
echo
xpra --version
wine --version
echo
echo "Acesse http://$(hostname -I | tr ' ' '\n' | grep -E '^[0-9]+\.' | head -n1):$XPRA_USER_PORT"
echo
sleep 2
if systemctl is-active --quiet "xpra-$XPRA_USER.service"; then
echo "✔ XPRA iniciado com sucesso"
else
echo "❌ Falha ao iniciar XPRA"
systemctl status "xpra-$XPRA_USER.service" --no-pager
fi
