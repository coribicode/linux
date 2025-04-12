GROUP_METATRADER=metatrader
XPRA_USERS=("user001" "user002" "user003") 

sudo groupadd $GROUP_METATRADER

for i in "${!XPRA_USERS[@]}"; do
    XPRA_USER="${XPRA_USERS[$i]}"

    # Verifica se o usuário existe
    if ! id "$XPRA_USER" &>/dev/null; then
        echo "⚠️  Usuário '$XPRA_USER' não existe. Cadastrando..."
        XPRA_USER_PASSWORD=123
        GROUP_METATRADER=metatrader
        useradd -m -s /bin/bash $XPRA_USER && echo "$XPRA_USER:$XPRA_USER_PASSWORD" | sudo chpasswd
        usermod -aG $GROUP_METATRADER $XPRA_USER
        continue
    fi
done

getent group $GROUP_METATRADER | cut -d: -f4 | tr ',' ' '

newgrp $GROUP_METATRADER

cat << 'EOF' > /usr/local/bin/start_xpra_user.sh
#!/bin/bash

# Recebe parâmetros: usuário, display, porta
USER=$1
DISPLAY_NUM=$2
PORT=$3
XPRA_APP=lxterminal

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
    xpra start ":$DISPLAY_NUM" --bind-tcp=0.0.0.0:$PORT --start-child=$XPRA_APP \
    --daemon=no --systemd-run=no
EOF

cat << 'EOF' > /usr/local/bin/gerar_servicos_xpra.sh
#!/bin/bash

# Nome do grupo
GRUPO="metatrader"

# Caminho do script XPRA
SCRIPT_XPRA="/usr/local/bin/start_xpra_user.sh"

# Contadores base
DISPLAY_BASE=100
PORT_BASE=10000

# Verifica se o script existe
if [ ! -x "$SCRIPT_XPRA" ]; then
  echo "❌ Script $SCRIPT_XPRA não encontrado ou não é executável."
  exit 1
fi

# Coleta usuários do grupo
USUARIOS=($(getent group "$GRUPO" | cut -d: -f4 | tr ',' ' '))

if [ -z "$USUARIOS" ]; then
  echo "⚠️ Nenhum usuário encontrado no grupo '$GRUPO'."
  exit 0
fi

# Loop pelos usuários do grupo
for i in "${!USUARIOS[@]}"; do
    USER="${USUARIOS[$i]}"

    # Verifica se o usuário existe
    if ! id "$USER" &>/dev/null; then
        echo "⚠️  Usuário '$USER' não existe. Pulando..."
        continue
    fi

    DISPLAY_NUM=$((DISPLAY_BASE + i))
    PORT_NUM=$((PORT_BASE + i))
    SERVICE_FILE="/etc/systemd/system/xpra-${USER}.service"

    echo "🛠️  Gerando serviço para $USER (Display :$DISPLAY_NUM | Porta $PORT_NUM)..."

    cat <<EOF | sudo tee "$SERVICE_FILE" > /dev/null
[Unit]
Description=XPRA para $USER (grupo $GRUPO)
After=network.target

[Service]
Type=simple
ExecStart=$SCRIPT_XPRA $USER $DISPLAY_NUM $PORT_NUM
Restart=on-failure

[Install]
WantedBy=multi-user.target
EOF

    # Habilita o serviço no boot
    sudo systemctl enable "xpra-${USER}.service"
done

echo "✅ Todos os serviços válidos foram gerados e habilitados!"
EOF

chmod +x /usr/local/bin/start_xpra_user.sh
chmod +x /usr/local/bin/gerar_servicos_xpra.sh
sudo ./gerar_servicos_xpra.sh

# usermod -aG $(groups $USER | cut -d ":" -f2 | sed -e 's/^[[:space:]]*//g' | tr ' ' ',') $XPRA_USER
