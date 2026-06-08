#!/bin/bash
set -e
# ==================================================
# CORES
# ==================================================
if [ -t 1 ]
then
    GREEN='\033[0;32m'
    RED='\033[0;31m'
    YELLOW='\033[1;33m'
    CYAN='\033[0;36m'
    WHITE='\033[1;37m'
    NC='\033[0m'
else
    GREEN=''
    RED=''
    YELLOW=''
    CYAN=''
    WHITE=''
    NC=''
fi
# ==================================================
# CONFIGURAÇÕES
# ==================================================
CODENAME="stable"
TYPES="deb deb-src"
URIS="http://deb.debian.org/debian"
URIS_SEC="http://deb.debian.org/debian-security"
SUITES="$CODENAME $CODENAME-updates $CODENAME-backports"
SUITES_SEC="$CODENAME-security"
COMPONENTES="main contrib non-free non-free-firmware"
SIGNED="/usr/share/keyrings/debian-archive-keyring.gpg"
PATH_SOURCE="/etc/apt/sources.list.d/${CODENAME}.sources"
# ==================================================
# FUNÇÕES
# ==================================================
status_line() {
    local LABEL="$1"
    local STATUS="$2"
    local COLOR="$3"
    printf "\r\033[2K✔ %-35s %b%s%b" \
        "$LABEL" \
        "$COLOR" \
        "$STATUS" \
        "$NC"
}
# ==================================================
# CABEÇALHO
# ==================================================
printf "\n"
printf "%b============================================%b\n" "$CYAN" "$NC"
printf "%b🧰 AJUSTANDO O SISTEMA%b\n" "$CYAN" "$NC"
printf "%b============================================%b\n" "$CYAN" "$NC"
printf "\n"
printf "%b⚙️ CONFIGURANDO O SISTEMA%b\n" "$WHITE" "$NC"
printf "\n"
# ==================================================
# PRIORIDADE IPV4
# ==================================================
if grep -q "^precedence ::ffff:0:0/96  100" /etc/gai.conf 2>/dev/null
then
    status_line "Prioridade IPv4" "OK" "$GREEN"
    printf "\n"
else
    status_line "Prioridade IPv4" "Não definido" "$RED"
    sleep 1
    status_line "Prioridade IPv4" "Definindo..." "$YELLOW"
    sed -i \
        's|#precedence ::ffff:0:0/96  100|precedence ::ffff:0:0/96  100|g' \
        /etc/gai.conf
    sleep 1
    status_line "Prioridade IPv4" "OK" "$GREEN"
    printf "\n"
fi
# ==================================================
# REPOSITÓRIOS
# ==================================================
printf "\n"
printf "%b⚡ ATUALIZAÇÃO DO SISTEMA%b\n" "$WHITE" "$NC"
printf "\n"
if [ -f "$PATH_SOURCE" ]
then
    status_line "Repositório Stable" "Adicionado" "$GREEN"
    printf "\n"
else
    status_line "Repositório Stable" "Não adicionado" "$RED"
    sleep 1
    status_line "Repositório Stable" "Adicionando..." "$YELLOW"
    if [ -f /etc/apt/sources.list ]
    then
        mv \
            /etc/apt/sources.list \
            /etc/apt/sources.list.bkp
    fi
    cat > "$PATH_SOURCE" <<EOF
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
    status_line "Repositório Stable" "Adicionado" "$GREEN"
    printf "\n"
fi
# ==================================================
# UPDATE / UPGRADE
# ==================================================
status_line "Atualização do Sistema" "Atualizando..." "$YELLOW"
export DEBIAN_FRONTEND=noninteractive
apt-get update \
    -qq \
    >/dev/null 2>&1
apt-get upgrade \
    -qqy \
    >/dev/null 2>&1
apt-get --fix-broken install \
    -qqy \
    >/dev/null 2>&1
systemctl daemon-reload \
    >/dev/null 2>&1
status_line "Atualização do Sistema" "Atualizado" "$GREEN"
printf "\n"
# ==================================================
# FINAL
# ==================================================
printf "\n"
printf "%b✓ Processo concluído com sucesso%b\n" "$GREEN" "$NC"
printf "\n"
