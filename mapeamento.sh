#!/bin/bash
# ============================================================
# Script de mapeamento de compartilhamento Windows no Linux
# Autor: ChatGPT
# ============================================================

set -e

echo "=== Mapeamento de Compartilhamento Windows no Linux com montagem automatica no boot ==="
echo

# ------------------------------------------------------------
# 1. Verificar dependências
# ------------------------------------------------------------
echo "[1/7] Verificando dependências..."
if ! command -v mount.cifs >/dev/null 2>&1; then
    echo "Instalando pacote 'cifs-utils'..."
    if [ -f /etc/debian_version ]; then
        sudo apt update && sudo apt install -y cifs-utils
    elif [ -f /etc/redhat-release ]; then
        sudo dnf install -y cifs-utils || sudo yum install -y cifs-utils
    else
        echo "Distribuição não reconhecida. Instale manualmente o pacote 'cifs-utils'."
        exit 1
    fi
else
    echo "✔ Dependências já instaladas."
fi
echo

# ------------------------------------------------------------
# 2. Coleta de informações do usuário
# ------------------------------------------------------------
read -rp "A. Diretório local de montagem (ex: /mnt/compartilhamento): " MOUNT_DIR
read -rp "B. Caminho do compartilhamento (ex: //192.168.0.10/Publico): " SHARE_DIR
read -rp "C. Usuário do Windows: " CIFS_USER

while true; do
    read -rsp "D. Senha: " CIFS_PASS
    echo
    read -rsp "Confirme a senha: " CIFS_PASS_CONFIRM
    echo
    [ "$CIFS_PASS" = "$CIFS_PASS_CONFIRM" ] && break
    echo "❌ As senhas não coincidem. Tente novamente."
done

# ------------------------------------------------------------
# 3. Cria diretório de montagem
# ------------------------------------------------------------
echo "[2/7] Criando diretório de montagem..."
sudo mkdir -p "$MOUNT_DIR"
echo "✔ Diretório criado: $MOUNT_DIR"
echo

# ------------------------------------------------------------
# 4. Cria arquivo de credenciais
# ------------------------------------------------------------
echo "[3/7] Criando arquivo de credenciais..."
sudo bash -c "cat > /etc/cifs-creds <<EOF
username=$CIFS_USER
password=$CIFS_PASS
EOF"
sudo chmod 600 /etc/cifs-creds
echo "✔ Credenciais salvas em /etc/cifs-creds"
echo

# ------------------------------------------------------------
# 5. Adiciona no /etc/fstab
# ------------------------------------------------------------
echo "[4/7] Configurando /etc/fstab..."
FSTAB_LINE="$SHARE_DIR $MOUNT_DIR cifs credentials=/etc/cifs-creds,iocharset=utf8,uid=$(id -u),gid=$(id -g),file_mode=0777,dir_mode=0777 0 0"
if ! grep -qF "$SHARE_DIR" /etc/fstab; then
    echo "$FSTAB_LINE" | sudo tee -a /etc/fstab > /dev/null
    echo "✔ Entrada adicionada ao /etc/fstab."
else
    echo "⚠ Entrada já existe no /etc/fstab. Pulando..."
fi
echo

# ------------------------------------------------------------
# 6. Monta e lista o compartilhamento
# ------------------------------------------------------------
echo "[5/7] Montando compartilhamento..."
sudo mount -a
if mount | grep -q "$MOUNT_DIR"; then
    echo "✔ Compartilhamento montado com sucesso!"
    echo
    echo "[6/7] Listando conteúdo de $MOUNT_DIR:"
    ls -lha "$MOUNT_DIR"
else
    echo "❌ Erro ao montar o compartilhamento. Verifique suas credenciais."
    exit 1
fi
echo

# ------------------------------------------------------------
# 7. Mostra opções para desmontar
# ------------------------------------------------------------
echo "[7/7] Opções para desmontar:"
echo "-----------------------------------------"
echo "Para desmontar este compartilhamento:"
echo "  sudo umount $MOUNT_DIR"
echo
echo "Para desmontar todos os compartilhamentos CIFS:"
echo "  sudo umount -a -t cifs"
echo "-----------------------------------------"
echo
echo "✅ Processo concluído com sucesso!"
