#!/bin/bash
# ============================================================
# Script de mapeamento automático de compartilhamentos de rede
# Suporta: SMB/CIFS (Windows/Samba) e NFS (Linux ↔ Linux)
# Autor: ChatGPT
# ============================================================

set -e

echo "=== Mapeamento Automático de Compartilhamentos (CIFS/NFS) ==="
echo

# ------------------------------------------------------------
# 1. Perguntas iniciais
# ------------------------------------------------------------
read -rp "A. Diretório local de montagem (ex: /mnt/rede): " MOUNT_DIR
read -rp "B. Caminho do compartilhamento (ex: //192.168.0.10/Publico ou 192.168.0.20:/dados): " SHARE_PATH

# Detectar tipo pelo formato
if [[ "$SHARE_PATH" == //* ]]; then
    SHARE_TYPE="cifs"
elif [[ "$SHARE_PATH" == *:* ]]; then
    SHARE_TYPE="nfs"
else
    echo "❌ Não foi possível identificar o tipo de compartilhamento (use // para CIFS ou :/ para NFS)"
    exit 1
fi

echo "→ Tipo detectado: $SHARE_TYPE"
echo

# ------------------------------------------------------------
# 2. Instalar dependências conforme o tipo
# ------------------------------------------------------------
if [ "$SHARE_TYPE" = "cifs" ]; then
    echo "[1/6] Verificando dependências para CIFS..."
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
    fi
    echo "✔ Dependências CIFS instaladas."
else
    echo "[1/6] Verificando dependências para NFS..."
    if ! command -v mount.nfs >/dev/null 2>&1; then
        echo "Instalando pacote 'nfs-common'..."
        if [ -f /etc/debian_version ]; then
            sudo apt update && sudo apt install -y nfs-common
        elif [ -f /etc/redhat-release ]; then
            sudo dnf install -y nfs-utils || sudo yum install -y nfs-utils
        else
            echo "Distribuição não reconhecida. Instale manualmente 'nfs-common'."
            exit 1
        fi
    fi
    echo "✔ Dependências NFS instaladas."
fi
echo

# ------------------------------------------------------------
# 3. Criar diretório de montagem
# ------------------------------------------------------------
echo "[2/6] Criando diretório de montagem..."
sudo mkdir -p "$MOUNT_DIR"
echo "✔ Diretório criado: $MOUNT_DIR"
echo

# ------------------------------------------------------------
# 4. Configuração e /etc/fstab
# ------------------------------------------------------------
if [ "$SHARE_TYPE" = "cifs" ]; then
    read -rp "Usuário do Windows/Samba (deixe vazio para anônimo): " CIFS_USER

    if [ -n "$CIFS_USER" ]; then
        while true; do
            read -rsp "Senha: " CIFS_PASS
            echo
            read -rsp "Confirme a senha: " CIFS_PASS_CONFIRM
            echo
            [ "$CIFS_PASS" = "$CIFS_PASS_CONFIRM" ] && break
            echo "❌ As senhas não coincidem. Tente novamente."
        done

        echo "[3/6] Criando arquivo de credenciais..."
        sudo bash -c "cat > /etc/cifs-creds <<EOF
username=$CIFS_USER
password=$CIFS_PASS
EOF"
        sudo chmod 600 /etc/cifs-creds
        FSTAB_LINE="$SHARE_PATH $MOUNT_DIR cifs credentials=/etc/cifs-creds,iocharset=utf8,uid=$(id -u),gid=$(id -g),file_mode=0777,dir_mode=0777 0 0"
    else
        FSTAB_LINE="$SHARE_PATH $MOUNT_DIR cifs guest,iocharset=utf8,uid=$(id -u),gid=$(id -g),file_mode=0777,dir_mode=0777 0 0"
    fi

else
    echo "[3/6] Configurando NFS..."
    FSTAB_LINE="$SHARE_PATH $MOUNT_DIR nfs defaults 0 0"
fi

# Adicionar no fstab se não existir
if ! grep -qF "$SHARE_PATH" /etc/fstab; then
    echo "$FSTAB_LINE" | sudo tee -a /etc/fstab > /dev/null
    echo "✔ Entrada adicionada ao /etc/fstab."
else
    echo "⚠ Entrada já existe no /etc/fstab. Pulando..."
fi
echo

# ------------------------------------------------------------
# 5. Montar e listar conteúdo
# ------------------------------------------------------------
echo "[4/6] Montando compartilhamento..."
sudo mount -a

if mount | grep -q "$MOUNT_DIR"; then
    echo "✔ Compartilhamento montado com sucesso!"
    echo
    echo "[5/6] Conteúdo de $MOUNT_DIR:"
    ls -lha "$MOUNT_DIR"
else
    echo "❌ Erro ao montar o compartilhamento. Verifique permissões e exportações do servidor."
    exit 1
fi
echo

# ------------------------------------------------------------
# 6. Opções para desmontar
# ------------------------------------------------------------
echo "[6/6] Opções para desmontar:"
echo "-----------------------------------------"
echo "Para desmontar este compartilhamento:"
echo "  sudo umount $MOUNT_DIR"
echo
if [ "$SHARE_TYPE" = "cifs" ]; then
    echo "Para desmontar todos os compartilhamentos CIFS:"
    echo "  sudo umount -a -t cifs"
else
    echo "Para desmontar todos os compartilhamentos NFS:"
    echo "  sudo umount -a -t nfs"
fi
echo "-----------------------------------------"
echo
echo "✅ Processo concluído com sucesso!"
