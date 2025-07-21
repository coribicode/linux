#!/bin/bash
apt install lxterminal -y

XPRA_USER=$USER
XPRA_USER_DISPLAY=100
XPRA_USER_PORT=10000
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
    --env=GTK_IM_MODULE=ibus \
    --env=QT_IM_MODULE=ibus \
    --env=XMODIFIERS=@im=ibus \
    --bind-tcp=0.0.0.0:$PORT \
    --opengl=yes \
    --tcp-auth=none \
    --compression=0 \    
    --start-child=lxterminal \
    --html=on \
    --daemon=no \
    --encoding=video \
    --min-quality=50 \
    --min-speed=50 \
    --speed=100 \
    --quality=100 \
    --dpi=96 \
    --webcam=no \
    --systemd-run=no \
    --no-mdns \    
    --systemd-run=no
EOF

chmod +x /usr/local/bin/start_xpra_user.sh

cat <<EOF>> /etc/systemd/system/xpra-$XPRA_USER.service
[Unit]
Description=XPRA para user001
After=network.target

[Service]
Type=simple
ExecStart=$(find / | grep start_xpra_user.sh) $XPRA_USER $XPRA_USER_DISPLAY $XPRA_USER_PORT
Restart=on-failure

[Install]
WantedBy=multi-user.target
EOF

sudo -u $USER pip3 install --user --break-system-packages PyOpenGL_accelerate

pip3 install --user --break-system-packages PyOpenGL_accelerate

ibus-daemon -drx
ibus engine xkb:us::eng

export GTK_IM_MODULE=ibus
export QT_IM_MODULE=ibus
export XMODIFIERS=@im=ibus

sudo systemctl daemon-reload
sudo systemctl enable xpra-$XPRA_USER.service
sudo systemctl start xpra-$XPRA_USER.service
