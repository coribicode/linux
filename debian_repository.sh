#!/bin/bash
clear

GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
CYAN='\033[0;36m'
WHITE='\033[1;37m'
NC='\033[0m'

CODENAME='stable'
TYPES='deb deb-src'
URIS='http://deb.debian.org/debian'
URIS_SEC='http://deb.debian.org/debian-security'
SUITES="$CODENAME $CODENAME-updates $CODENAME-backports"
SUITES_SEC="$CODENAME-security"
COMPONENTES='main contrib non-free non-free-firmware'
SIGNED="/usr/share/keyrings/debian-archive-keyring.gpg"
PATH_SOURCE="/etc/apt/sources.list.d/$CODENAME.sources"

status_line() {
    local LABEL="$1"
    local STATUS="$2"
    local COLOR="$3"
    printf "\r\033[2K✔ %s: %b%s%b" "$LABEL" "$COLOR" "$STATUS" "$NC"
}

echo "${CYAN}=====================================${NC}"
echo "${CYAN} 🧰 AJUSTANDO O SISTEMA${NC}"
echo "${CYAN}=====================================${NC}"
echo

echo "${WHITE} ⚙️ CONFIGURANDO O SISTEMA:${NC}"
echo

# IPv4
if grep "^precedence ::ffff:0:0/96  100" /etc/gai.conf >/dev/null 2>&1; then
    status_line "Prioridade IPv4" "OK" "$GREEN"
    echo
else
    status_line "Prioridade IPv4" "Não definido" "$RED"
    sleep 1
    status_line "Prioridade IPv4" "Definindo..." "$YELLOW"
    sed -i 's|#precedence ::ffff:0:0/96  100|precedence ::ffff:0:0/96  100|g' /etc/gai.conf
    sleep 1
    status_line "Prioridade IPv4" "OK" "$GREEN"
    echo
fi

# Swap
if swapon --show | grep -q .; then
    status_line "Swap Desativado" "Não desativado" "$RED"
    sleep 1
    status_line "Swap Desativado" "Desativando..." "$YELLOW"
    sed -i.bak '/ swap / s/^\(.*\)$/#\1/g' /etc/fstab
    swapoff -a >/dev/null 2>&1
    rm -f /swapfile >/dev/null 2>&1
    sleep 1
    status_line "Swap Desativado" "Desativado" "$GREEN"
    echo
else
    status_line "Swap Desativado" "Desativado" "$GREEN"
    echo
fi

# zRAM
if systemctl is-active zramswap.service >/dev/null 2>&1; then
    status_line "zRAM Desativado" "Não desativado" "$RED"
    sleep 1
    status_line "zRAM Desativado" "Desativando..." "$YELLOW"
    systemctl stop zramswap.service >/dev/null 2>&1
    systemctl disable zramswap.service >/dev/null 2>&1
    sleep 1
    status_line "zRAM Desativado" "Desativado" "$GREEN"
    echo
else
    status_line "zRAM Desativado" "Desativado" "$GREEN"
    echo
fi

echo
echo "${WHITE}⚡ ATUALIZAÇÃO DO SISTEMA:${NC}"
echo

# Repo
if [ -e "$PATH_SOURCE" ]; then
    status_line "Repositório 'STABLE'" "Adicionado" "$GREEN"
    echo
else
    status_line "Repositório 'STABLE'" "Não adicionado" "$RED"
    sleep 1
    status_line "Repositório 'STABLE'" "Adicionando..." "$YELLOW"

    mv /etc/apt/sources.list /etc/apt/sources.list.bkp >/dev/null 2>&1

    cat > "$PATH_SOURCE" << EOF
Types: $TYPES
URIs: $URIS
Suites: $SUITES
Components: $COMPONENTES
Signed-By: $SIGNED

Types: $TYPES
URIs: $URIS_SEC
Suites: $SUITES_SEC
Components: $COMPONENTES
Signed-By: $SIGNED
EOF

    sleep 1
    status_line "Repositório 'STABLE'" "Adicionado" "$GREEN"
    echo
fi

# Update
status_line "Atualização do Sistema" "Não atualizado" "$RED"
sleep 1
status_line "Atualização do Sistema" "Atualizando..." "$YELLOW"

apt-get update -qq >/dev/null 2>&1
apt-get upgrade -qqy >/dev/null 2>&1
apt-get --fix-broken -qq install >/dev/null 2>&1
systemctl daemon-reload >/dev/null 2>&1

sleep 1
status_line "Atualização do Sistema" "Atualizado" "$GREEN"
echo
