#!/bin/bash
set -e

CONFIG_FILE="/etc/xpra-users.conf"
SERVICE_FILE="/etc/systemd/system/xpra-service@.service"
SCRIPT_FILE="/usr/local/bin/xpra-service.sh"

echo "=== Instalação do Xpra Multiusuário ==="

# 1️⃣ Criar arquivo de configuração se não existir
if [ ! -f "$CONFIG_FILE" ]; then
    echo "Criando arquivo de configuração padrão em $CONFIG_FILE"
    sudo tee "$CONFIG_FILE" > /dev/null << 'EOF'
xpra1 :101 10101
xpra2 :102 10102
xpra3 :103 10103
xpra4 :104 10104
xpra5 :105 10105
EOF
else
    echo "Arquivo de configuração já existe: $CONFIG_FILE"
fi

# 2️⃣ Criar script principal
echo "Criando script $SCRIPT_FILE"
sudo tee "$SCRIPT_FILE" > /dev/null << 'EOF'
#!/bin/bash
CONFIG_FILE="/etc/xpra-users.conf"

# Verifica se o usuário existe na config
if ! grep -q "^$USER " "$CONFIG_FILE"; then
    echo "Usuário $USER não encontrado em $CONFIG_FILE"
    exit 1
fi

# Lê display e porta da config
read DISPLAY_NUM PORT <<< "$(grep "^$USER " "$CONFIG_FILE" | awk '{print $2, $3}')"

export LIBGL_ALWAYS_SOFTWARE=1
export XPRA_IPV6=no

exec xpra start "$DISPLAY_NUM" \
    --start=xterm \
    --bind-tcp=0.0.0.0:$PORT \
    --html=on \
    --daemon=no \
    --input-method=xim \
    --opengl=no \
    --pulseaudio=yes \
    --min-quality=100 \
    --speed=1000 \
EOF
sudo chmod +x "$SCRIPT_FILE"

# 3️⃣ Criar serviço systemd parametrizado
echo "Criando serviço $SERVICE_FILE"
sudo tee "$SERVICE_FILE" > /dev/null << 'EOF'
[Unit]
Description=Xpra Service para %i
After=network.target
Requires=network.target

[Service]
User=%i
RuntimeDirectory=%U
#Environment=XDG_RUNTIME_DIR=/run/user/$(id -u $i)
Environment=LIBGL_ALWAYS_SOFTWARE=1
Environment=XPRA_IPV6=no
RuntimeDirectory=%i-runtime
RuntimeDirectoryMode=0700
Environment=XDG_RUNTIME_DIR=/run/%i-runtime

ExecStart=/usr/local/bin/xpra-service.sh
Restart=on-failure

[Install]
WantedBy=multi-user.target
EOF

# 4️⃣ Criar usuários conforme config
echo "Criando usuários..."
while read -r user display port; do
    if id "$user"; then
        echo "Usuário $user já existe"
    else
        sudo useradd -r -s /bin/bash -m "$user"
	    sudo mkdir /run/user/$(id -u $user)
        sudo chown $user /run/user/$(id -u $user)
	    sudo chmod 2700 /run/user/$(id -u $user)
        echo "Usuário $user criado | $(ls -llah /run/user/)"
    fi
done < "$CONFIG_FILE"

# 5️⃣ Ativar e iniciar serviços
echo "Recarregando systemd..."
sudo systemctl daemon-reexec
sudo systemctl daemon-reload

echo "Ativando e iniciando serviços..."
while read -r user display port; do
    sudo systemctl enable "xpra-service@${user}"
    sudo systemctl start "xpra-service@${user}"
done < "$CONFIG_FILE"

echo "=== Instalação concluída! ==="
echo "Status dos serviços:"
while read -r user display port; do
    [[ "$user" =~ ^# ]] && continue
    systemctl status "xpra-service@${user}" --no-pager -l || true
done < "$CONFIG_FILE"
