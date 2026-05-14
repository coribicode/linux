#!/bin/bash
clear

apt update > /dev/null 2>&1
apt upgrade -y > /dev/null 2>&1
apt install -y curl > /dev/null 2>&1

curl -fsSL https://raw.githubusercontent.com/coribicode/linux/main/debian_repository.sh | sh
curl -fsSL https://raw.githubusercontent.com/coribicode/linux/main/essentials13.sh | sh
curl -fsSL https://raw.githubusercontent.com/coribicode/linux/main/xpra.sh | sh
curl -fsSL https://raw.githubusercontent.com/coribicode/linux/main/wine-stable.sh | sh

GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
CYAN='\033[0;36m'
NC='\033[0m'

FAILED_PACKAGES=()

PACKAGES=(
python3 python3-venv python3-pyqt5 python3-tk python3-psutil python3-pyqt5.qtsvg python3-netifaces systemd-container cgroup-tools x11-xserver-utils procps psmisc cabextract zenity xdg-utils wmctrl p7zip-full zram-tools unzip
)

center_text() {
local TEXT="$1"
local WIDTH=$(tput cols)
local PADDING=$(( (WIDTH - ${#TEXT}) / 2 ))
printf "%*s%s\n" "$PADDING" "" "$TEXT"
}
is_installed() {
dpkg-query -W -f='${Status}' "$1" 2>/dev/null | grep -q "install ok installed"
}
apt-get update -y >/dev/null 2>&1
echo
center_text "========================================================"
center_text "[ CHECKLIST ]: INSTALAÇÃO DE PACOTES"
center_text "========================================================"
echo
for PKG in "${PACKAGES[@]}"; do
if is_installed "$PKG"; then
printf "${GREEN}✔${NC} %-30s ${GREEN}[ OK ]${NC} Já instalado\n" "$PKG"
else
printf "${RED}✘${NC} %-30s ${RED}[ NÃO INSTALADO ]${NC}\n" "$PKG"
printf "${YELLOW}⠋${NC} %-30s ${YELLOW}[ INSTALANDO... ]${NC}\n" "$PKG"
if DEBIAN_FRONTEND=noninteractive apt-get install -y "$PKG" >/dev/null 2>&1; then
if is_installed "$PKG"; then
printf "${GREEN}✔${NC} %-30s ${GREEN}[ INSTALADO ]${NC}\n" "$PKG"
else
printf "${RED}✘${NC} %-30s ${RED}[ FALHA ]${NC}\n" "$PKG"
FAILED_PACKAGES+=("$PKG")
fi
else
printf "${RED}✘${NC} %-30s ${RED}[ ERRO INSTALL ]${NC}\n" "$PKG"
FAILED_PACKAGES+=("$PKG")
fi
fi
done
echo
center_text "========================================================"
center_text "[ CHECKLIST ]: VALIDAÇÃO FINAL"
center_text "========================================================"
echo
for PKG in "${PACKAGES[@]}"; do
if is_installed "$PKG"; then
printf "${GREEN}✔${NC} %-30s ${GREEN}[ OK ]${NC} Instalado\n" "$PKG"
else
printf "${RED}✘${NC} %-30s ${RED}[ ERRO ]${NC} Não instalado\n" "$PKG"
fi
done
echo
if [ ${#FAILED_PACKAGES[@]} -eq 0 ]; then
printf "${GREEN}✔ Todos os pacotes instalados com sucesso${NC}\n"
else
printf "${RED}Pacotes com falha:${NC}\n"
for PKG in "${FAILED_PACKAGES[@]}"; do
echo " - $PKG"
done
fi
echo
center_text "========================================================"

USER=xpra-painel
useradd -m -s /bin/bash $USER && echo "$USER:123" | sudo chpasswd
sudo usermod -aG sudo,cdrom,floppy,audio,dip,video,plugdev,users,netdev $USER

cat <<'EOF'> /etc/sudoers.d/xpra-painel
%sudo ALL=(ALL:ALL) NOPASSWD: ALL
EOF

XPRA_USER=$USER
XPRA_USER_DISPLAY=$(id -u $USER)
XPRA_USER_PORT=$(($(id -u $USER) * 10))
XPRA_USER_UID=$(id -u "$XPRA_USER")
XPRA_USER_RUNTIME_DIR="/run/user/$XPRA_USER_UID"
mkdir -p "$XPRA_USER_RUNTIME_DIR"
chown "$XPRA_USER:$XPRA_USER" "$XPRA_USER_RUNTIME_DIR"
chmod 700 "$XPRA_USER_RUNTIME_DIR"
XDG_RUNTIME_DIR="$XPRA_USER_RUNTIME_DIR"

cat <<'EOF'>> /usr/local/bin/start_xpra_user.sh
#!/bin/bash
# Recebe parâmetros: usuário, display, porta
USER=$1
DISPLAY_NUM=$2
PORT=$3

# Pega UID
UID=$(id -u "$USER")
RUNTIME_DIR="/run/user/$UID"

# Garante que o diretório exista
mkdir -p "$RUNTIME_DIR"
chown "$USER:$USER" "$RUNTIME_DIR"
chmod 700 "$RUNTIME_DIR"

# Exporta variáveis
export XDG_RUNTIME_DIR="$RUNTIME_DIR"
export DISPLAY=":$DISPLAY_NUM"

# Inicia o xpra como o usuário especificado
sudo -u "$USER" \
XDG_RUNTIME_DIR="$RUNTIME_DIR" \
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
  −−use−display=no \
  --exit-with-children=no \
  --bind-tcp=0.0.0.0:$PORT \
  --html=on \
  --start-child="sudo python3 /opt/painel.py"
EOF

chmod +x /usr/local/bin/start_xpra_user.sh

cat <<EOF> /etc/systemd/system/xpra-$XPRA_USER.service
[Unit]
Description=XPRA for Multiple MetaTrader5 
After=network.target

[Service]
Type=simple
ExecStart=$(find / | grep start_xpra_user.sh) $XPRA_USER $XPRA_USER_DISPLAY $XPRA_USER_PORT
Restart=on-failure

[Install]
WantedBy=multi-user.target
EOF

sudo systemctl daemon-reload
sudo systemctl enable xpra-$XPRA_USER.service
sudo systemctl start xpra-$XPRA_USER.service
