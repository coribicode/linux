#!/bin/bash
apt update > /dev/null 2>&1
apt upgrade -y > /dev/null 2>&1
apt install -y curl > /dev/null 2>&1
curl -fsSL https://raw.githubusercontent.com/coribicode/linux/main/debian_repository.sh | sh
curl -fsSL https://raw.githubusercontent.com/coribicode/linux/main/essentials13.sh | sh
curl -fsSL https://raw.githubusercontent.com/coribicode/linux/main/xpra.sh | sh
curl -fsSL https://raw.githubusercontent.com/coribicode/linux/main/wine-stable.sh | sh

PACKAGES="python3 python3-pyqt5 python3-psutil python3-netifaces cgroup-tools x11-xserver-utils procps psmisc cabextract zenity xdg-utils p7zip-full unzip"
echo
curl -LO https://raw.githubusercontent.com/coribicode/linux/main/install.sh > /dev/null 2>&1
INSTALLER="install.sh"

echo "[ Packages Painel ]: Inicio"
if grep PACKAGE_NAME $INSTALLER > /dev/null 2>&1
  then
    sed -i "s|PACKAGE_NAME|$PACKAGES|g" $INSTALLER
    sh $INSTALLER
  else
    sh $INSTALLER
fi
echo "[ Packages Painel ]: Fim."
sleep 2

USER=xpra-painel
useradd -m -s /bin/bash $USER && echo "$USER:123" | sudo chpasswd
sudo usermod -aG sudo $USER

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
    xpra start ":$DISPLAY_NUM" --exit-with-children=no --pulseaudio=yes --bind-tcp=0.0.0.0:$PORT --start-child="python3 /opt/painel.py" --html=on \
    --daemon=no --systemd-run=no
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
