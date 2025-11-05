#!/bin/bash
# ============================================================
# Script Automático de Mapeamento de Compartilhamento de Rede
# Suporta: CIFS (Windows/Samba) e NFS (Linux ↔ Linux)
# Autor: ChatGPT
# ============================================================

set -e

echo "=== Mapeamento Automático de Compartilhamento de Rede ==="
echo

# ------------------------------------------------------------
# 1. Coleta de informações
# ------------------------------------------------------------
read -rp "A. Diretório local de montagem (ex: /mnt/compartilhado): " MOUNT_DIR
read -rp "B. IP do servidor: " SERVER_IP
read -rp "C. Nome da pasta compartilhada: " SHARE_NAME
echo

SHARE_PATH_CIFS="//${SERVER_IP}/${SHARE_NAME}"
SHARE_PATH_NFS="${SERVER_IP}:/${SHARE_NAME}"

# ------------------------------------------------------------
# 2. Testar conectividade
# ------------------------------------------------------------
echo "[1/8] Testando conectividade com ${SERVER_IP}..."
if ping -c 1 -W 2 "$SERVER_IP" >/dev/null 2>&1; then
    echo "✔ Servidor acessível."
else
    echo "❌ Não foi possível alcançar ${SERVER_IP}. Verifique a rede."
    exit 1
fi
echo

# ------------------------------------------------------------
# 3. Detectar tipo de compartilhamento (CIFS ou NFS)
# ------------------------------------------------------------
echo "[2/8] Detectando tipo de compartilhamento..."

SHARE_TYPE=""

# Tenta detectar via smbclient
if command -v smbclient >/dev/null 2>&1; then
    if smbclient -L "$SERVER_IP" -N 2>/dev/null | grep -q "$SHARE_NAME"; then
        SHARE_TYPE="cifs"
    fi
else
    echo "⚠ smbclient não instalado, pulando detecção CIFS explícita."
fi

# Se ainda não detectado, tenta via showmount (NFS)
if [ -z "$SHARE_TYPE" ]; then
    if command -v showmount >/dev/null 2>&1; then
        if showmount -e "$SERVER_IP" 2>/dev/null | grep -q "$SHARE_NAME"; then
            SHARE_TYPE="nfs"
        fi
    else
        echo "⚠ showmount não instalado, pulando detecção NFS explícita."
    fi
fi

# fallback: se nada detectado, tentar heurística
if [ -z "$SHARE_TYPE" ]; then
    echo "⚠ Nenhum tipo detectado automaticamente. Tentando heurística..."
    nc -z -w1 "$SERVER_IP" 445 >/dev/null 2>&1 && SHARE_TYPE="cifs"
    nc -z -w1 "$SERVER_IP" 2049 >/dev/null 2>&1 && SHARE_TYPE="nfs"
fi

if [ -z "$SHARE_TYPE" ]; then
    echo "❌ Não foi possível detectar o tipo de compartilhamento (CIFS/NFS)."
    echo "Verifique se o servidor realmente compartilha a pasta '$SHARE_NAME'."
    exit 1
fi

echo "→ Tipo detectado: $SHARE_TYPE"
echo

# ------------------------------------------------------------
# 4. Instalar dependências
# ------------------------------------------------------------
if [ "$SHARE_TYPE" = "cifs" ]; then
    echo "[3/8] Verificando dependências CIFS..."
    if ! command -v mount.cifs >/dev/null 2>&1; then
        echo "Instalando 'cifs-utils'..."
        if [ -f /etc/debian_version ]; then
            sudo apt update && sudo apt install -y cifs-utils smbclient
        elif [ -f /etc/redhat-release ]; then
            sudo dnf install -y cifs-utils samba-client || sudo yum install -y cifs-utils samba-client
        fi
    fi
else
    echo "[3/8] Verificando dependências NFS..."
    if ! command -v mount.nfs >/dev/null 2>&1; then
        echo "Instalando 'nfs-common'..."
        if [ -f /etc/debian_version ]; then
            sudo apt update && sudo apt install -y nfs-common
        elif [ -f /etc/redhat-release ]; then
            sudo dnf install -y nfs-utils || sudo yum install -y nfs-utils
        fi
    fi
fi
echo "✔ Dependências verificadas."
echo

# ------------------------------------------------------------
# 5. Criar diretório de montagem
# ------------------------------------------------------------
echo "[4/8] Criando diretório de montagem..."
sudo mkdir -p "$MOUNT_DIR"
echo "✔ Diretório criado: $MOUNT_DIR"
echo

# ------------------------------------------------------------
# 6. Configurar /etc/fstab
# ------------------------------------------------------------
echo "[5/8] Configurando /etc/fstab..."

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
        sudo bash -c "cat > /etc/cifs-creds <<EOF
username=$CIFS_USER
password=$CIFS_PASS
EOF"
        sudo chmod 600 /etc/cifs-creds
        FSTAB_LINE="$SHARE_PATH_CIFS $MOUNT_DIR cifs credentials=/etc/cifs-creds,iocharset=utf8,uid=$(id -u),gid=$(id -g),file_mode=0777,dir_mode=0777 0 0"
    else
        FSTAB_LINE="$SHARE_PATH_CIFS $MOUNT_DIR cifs guest,iocharset=utf8,uid=$(id -u),gid=$(id -g),file_mode=0777,dir_mode=0777 0 0"
    fi
else
    FSTAB_LINE="$SHARE_PATH_NFS $MOUNT_DIR nfs defaults 0 0"
fi

if ! grep -qF "$MOUNT_DIR" /etc/fstab; then
    echo "$FSTAB_LINE" | sudo tee -a /etc/fstab > /dev/null
    echo "✔ Entrada adicionada ao /etc/fstab."
else
    echo "⚠ Entrada já existe no /etc/fstab. Pulando..."
fi
echo

# ------------------------------------------------------------
# 7. Montar e listar conteúdo
# ------------------------------------------------------------
echo "[6/8] Montando compartilhamento..."
sudo mount -a
if mount | grep -q "$MOUNT_DIR"; then
    echo "✔ Compartilhamento montado com sucesso!"
    echo
    echo "[7/8] Conteúdo de $MOUNT_DIR:"
    ls -lha "$MOUNT_DIR"
else
    echo "❌ Erro ao montar o compartilhamento. Verifique permissões e exportações do servidor."
    exit 1
fi
echo

# ------------------------------------------------------------
# 8. Instruções finais
# ------------------------------------------------------------
echo "[8/8] Opções para desmontar:"
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
