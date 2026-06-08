#!/bin/bash
set -e
# ==================================================
# CORES
# ==================================================
if [ -t 1 ]; then
    GREEN='\033[0;32m'
    RED='\033[0;31m'
    YELLOW='\033[1;33m'
    CYAN='\033[0;36m'
    WHITE='\033[1;37m'
    NC='\033[0m'
else
    GREEN=''; RED=''; YELLOW=''; CYAN=''; WHITE=''; NC=''
fi
# ==================================================
# DETECTA CODENAME REAL (CORREÇÃO PRINCIPAL)
# ==================================================
CODENAME="$(. /etc/os-release && echo "$VERSION_CODENAME")"
TYPES="deb deb-src"
URIS="http://deb.debian.org/debian"
URIS_SEC="http://deb.debian.org/debian-security"
SUITES="$CODENAME $CODENAME-updates $CODENAME-backports"
SUITES_SEC="$CODENAME-security"
COMPONENTES="main contrib non-free non-free-firmware"
SIGNED="/usr/share/keyrings/debian-archive-keyring.gpg"
PATH_SOURCE="/etc/apt/sources.list.d/${CODENAME}.sources"
# ==================================================
# FUNÇÃO STATUS
# ==================================================
status_line() {
    printf "\r\033[2K✔ %-35s %b%s%b" "$1" "$3" "$2" "$NC"
}
# ==================================================
# CABEÇALHO
# ==================================================
printf "\n%b🧰 AJUSTANDO SISTEMA (%s)%b\n\n" "$CYAN" "$CODENAME" "$NC"
# ==================================================
# IPV4 PRIORITY
# ==================================================
if grep -q "^precedence ::ffff:0:0/96  100" /etc/gai.conf 2>/dev/null; then
    status_line "Prioridade IPv4" "OK" "$GREEN"
else
    status_line "Prioridade IPv4" "Aplicando..." "$YELLOW"
    sed -i 's|#precedence ::ffff:0:0/96  100|precedence ::ffff:0:0/96  100|' /etc/gai.conf
    status_line "Prioridade IPv4" "OK" "$GREEN"
fi
printf "\n\n%b⚡ REPOSITÓRIOS%b\n\n" "$WHITE" "$NC"
# ==================================================
# REPOSITÓRIOS
# ==================================================
if [ ! -f "$PATH_SOURCE" ]; then
    status_line "Repo Debian" "Criando..." "$YELLOW"

    # backup seguro
    if [ -f /etc/apt/sources.list ]; then
        cp /etc/apt/sources.list /etc/apt/sources.list.bkp
    fi
cat > "$PATH_SOURCE" <<EOF
Types: $TYPES
URIs: $URIS
Suites: $SUITES
Components: $COMPONENTES
Signed-By: $SIGNED
Enabled: yes

Types: $TYPES
URIs: $URIS_SEC
Suites: $SUITES_SEC
Components: $COMPONENTES
Signed-By: $SIGNED
Enabled: yes
EOF
    status_line "Repo Debian" "OK" "$GREEN"
else
    status_line "Repo Debian" "Já existe" "$GREEN"
fi

# ==================================================
# UPDATE SEGURO
# ==================================================
printf "\n\n%b🔄 ATUALIZANDO SISTEMA%b\n\n" "$WHITE" "$NC"
export DEBIAN_FRONTEND=noninteractive
if ! apt-get update; then
    printf "%bErro no apt update%b\n" "$RED" "$NC"
    exit 1
fi
apt-get upgrade -y
apt-get --fix-broken install -y
systemctl daemon-reload >/dev/null 2>&1 || true
printf "\n%b✓ SISTEMA ATUALIZADO COM SUCESSO%b\n\n" "$GREEN" "$NC"
