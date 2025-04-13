#!/bin/bash
mkdir /opt/mt5
winedir=/opt/mt5

wget -P /opt/ https://dl.winehq.org/wine/wine-mono/9.4.0/wine-mono-9.4.0-x86.msi
wget -P /opt/ https://dl.winehq.org/wine/wine-gecko/2.47.4/wine-gecko-2.47.4-x86_64.msi
wget -P /opt/ https://download.mql5.com/cdn/web/metaquotes.software.corp/mt5/mt5setup.exe

mkdir $HOME/.cache
mkdir $HOME/.cache/wine
cp /opt/*.msi $HOME/.cache/wine

WINEPREFIX="$winedir/" wine msiexec -i /opt/wine-mono-9.4.0-x86.msi
WINEPREFIX="$winedir/" wine msiexec -i /opt/wine-gecko-2.47.4-x86_64.msi
WINEPREFIX="$winedir/" wine /opt/mt5setup.exe /auto

cat <<'EOF'>> /opt/mt5/MetaTrader5
wine /opt/mt5/drive_c/Program\ Files/MetaTrader\ 5/terminal64.exe
EOF
chmod +x /opt/mt5/MetaTrader5

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
chmod 2700 "$RUNTIME_DIR"

# Exporta variáveis
export XDG_RUNTIME_DIR="$RUNTIME_DIR"
export DISPLAY=":$DISPLAY_NUM"

# Inicia o xpra como o usuário especificado
sudo -u "$USER" \
    XDG_RUNTIME_DIR="$RUNTIME_DIR" \
    xpra start ":$DISPLAY_NUM" --bind-tcp=0.0.0.0:$PORT --start-child=lxterminal --html=on \
    --daemon=no --systemd-run=no
EOF

chmod +x /usr/local/bin/start_xpra_user.sh

XPRA_USER=user001
XPRA_USER_DISPLAY=101
XPRA_USER_PORT=10001

XPRA_USER_PASSWORD=123
useradd -m -s /bin/bash $XPRA_USER && echo "$XPRA_USER:$XPRA_USER_PASSWORD" | sudo chpasswd

cat <<EOF>> /etc/systemd/system/xpra-$XPRA_USER.service
[Unit]
Description=XPRA para $XPRA_USER
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

sudo -u $XPRA_USER XDG_RUNTIME_DIR=/run/user/$(id -u $XPRA_USER) WINEPREFIX="/home/$XPRA_USER/.wine" WINEARCH=win64 wine wineboot -u -f -r
sudo -u $XPRA_USER XDG_RUNTIME_DIR=/run/user/$(id -u $XPRA_USER) WINEPREFIX="/home/$XPRA_USER/.wine" wineserver -k
sudo -u $XPRA_USER mkdir -p  /home/$XPRA_USER/.cache/wine
cp /opt/*.msi /home/$XPRA_USER/.cache/wine
sudo -u $XPRA_USER XDG_RUNTIME_DIR=/run/user/$(id -u $XPRA_USER) wine msiexec /i /home/$XPRA_USER/.cache/wine/wine-gecko-2.47.4-x86_64.msi
sudo -u $XPRA_USER XDG_RUNTIME_DIR=/run/user/$(id -u $XPRA_USER) wine msiexec /i /home/$XPRA_USER/.cache/wine/wine-mono-9.4.0-x86.msi
sudo -u $XPRA_USER XDG_RUNTIME_DIR=/run/user/$(id -u $XPRA_USER) WINEPREFIX="/home/$XPRA_USER/.wine" wine winecfg -v win10


XPRA_USER=user002
XPRA_USER_DISPLAY=102
XPRA_USER_PORT=10002

XPRA_USER_PASSWORD=123
useradd -m -s /bin/bash $XPRA_USER && echo "$XPRA_USER:$XPRA_USER_PASSWORD" | sudo chpasswd

cat <<EOF>> /etc/systemd/system/xpra-$XPRA_USER.service
[Unit]
Description=XPRA para $XPRA_USER
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

sudo -u $XPRA_USER XDG_RUNTIME_DIR=/run/user/$(id -u $XPRA_USER) WINEPREFIX="/home/$XPRA_USER/.wine" WINEARCH=win64 wine wineboot -u -f -r
sudo -u $XPRA_USER XDG_RUNTIME_DIR=/run/user/$(id -u $XPRA_USER) WINEPREFIX="/home/$XPRA_USER/.wine" wineserver -k
sudo -u $XPRA_USER mkdir -p  /home/$XPRA_USER/.cache/wine
cp /opt/*.msi /home/$XPRA_USER/.cache/wine
sudo -u $XPRA_USER XDG_RUNTIME_DIR=/run/user/$(id -u $XPRA_USER) wine msiexec /i /home/$XPRA_USER/.cache/wine/wine-gecko-2.47.4-x86_64.msi
sudo -u $XPRA_USER XDG_RUNTIME_DIR=/run/user/$(id -u $XPRA_USER) wine msiexec /i /home/$XPRA_USER/.cache/wine/wine-mono-9.4.0-x86.msi
sudo -u $XPRA_USER XDG_RUNTIME_DIR=/run/user/$(id -u $XPRA_USER) WINEPREFIX="/home/$XPRA_USER/.wine" wine winecfg -v win10

