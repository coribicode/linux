#!/bin/bash
set -u
# ==============================================================================
# CORES
# ==============================================================================
if [ -t 1 ]; then
    RED='\033[0;31m'
    GREEN='\033[0;32m'
    YELLOW='\033[1;33m'
    ORANGE='\033[38;5;208m'
    CYAN='\033[1;36m'
    WHITE='\033[1;37m'
    NC='\033[0m'
else
    RED=''
    GREEN=''
    YELLOW=''
    ORANGE=''
    CYAN=''
    WHITE=''
    NC=''
fi
# ==============================================================================
# SPINNER
# ==============================================================================
SPINNER=("⠋" "⠙" "⠹" "⠸" "⠼" "⠴" "⠦" "⠧" "⠇" "⠏")
# ==============================================================================
# DETECTA CODENAME REAL
# ==============================================================================
CODENAME="$(. /etc/os-release && echo "$VERSION_CODENAME")"
# ==============================================================================
# CONFIGURAÇÕES DOS REPOSITÓRIOS
# ==============================================================================
TYPES="deb deb-src"
URIS="http://deb.debian.org/debian"
URIS_SEC="http://deb.debian.org/debian-security"
SUITES="$CODENAME $CODENAME-updates $CODENAME-backports"
SUITES_SEC="$CODENAME-security"
COMPONENTES="main contrib non-free non-free-firmware"
SIGNED="/usr/share/keyrings/debian-archive-keyring.gpg"
PATH_SOURCE="/etc/apt/sources.list.d/${CODENAME}.sources"
# ==============================================================================
# FUNÇÃO PARA MOSTRAR PROGRESSO
# ==============================================================================
show_progress() {
    local pid="$1"
    local message="$2"
    local start
    start=$(date +%s)
    local frame=0
    while kill -0 "$pid" 2>/dev/null
    do
        local now elapsed hh mm ss
        now=$(date +%s)
        elapsed=$((now - start))
        hh=$((elapsed / 3600))
        mm=$(((elapsed % 3600) / 60))
        ss=$((elapsed % 60))
        printf "\rTempo: %02d:%02d:%02d   %s %s..." \
            "$hh" "$mm" "$ss" \
            "${SPINNER[$frame]}" \
            "$message"
        frame=$(( (frame + 1) % ${#SPINNER[@]} ))
        sleep 0.2
    done
    printf "\r\033[K"
}
# ==============================================================================
# FUNÇÃO PARA EXECUTAR COMANDOS SILENCIOSAMENTE
# ==============================================================================
run_silent() {
    "$@" >/dev/null 2>&1
}
# ==============================================================================
# TABELA DE STATUS
# ==============================================================================
draw_status_table() {
    echo -e "${WHITE}"
    echo "════════════════════════════════════════════════════════════════════════════════════════"
    echo "                         AJUSTANDO SISTEMA - DEBIAN 13 ($CODENAME)                          "
    echo "════════════════════════════════════════════════════════════════════════════════════════"
    echo -e "${NC}"
    echo
}
# ==============================================================================
# CABEÇALHO
# ==============================================================================
clear
draw_status_table
echo -e "${CYAN}▶ INICIANDO CONFIGURAÇÃO DO SISTEMA${NC}"
echo
# ==============================================================================
# IPV4 PRIORITY
# ==============================================================================
echo -e "${WHITE}────────────────────────────────────────────────────────────────────────────────${NC}"
echo -e "${CYAN}📡 CONFIGURANDO PRIORIDADE IPv4${NC}"
echo
if grep -q "^precedence ::ffff:0:0/96  100" /etc/gai.conf 2>/dev/null; then
    echo -e "${GREEN}✔ Prioridade IPv4${NC}"
else
    echo -e "${YELLOW}⚠ Aplicando prioridade IPv4...${NC}"
    sed -i 's|#precedence ::ffff:0:0/96  100|precedence ::ffff:0:0/96  100|' /etc/gai.conf
    echo -e "${GREEN}✔ Prioridade IPv4 configurada${NC}"
fi
echo
echo -e "${WHITE}────────────────────────────────────────────────────────────────────────────────${NC}"
echo -e "${CYAN}📦 CONFIGURANDO REPOSITÓRIOS${NC}"
echo
# ==============================================================================
# REPOSITÓRIOS
# ==============================================================================
if [ ! -f "$PATH_SOURCE" ]; then
    echo -e "${YELLOW}⚠ Criando arquivo de repositórios...${NC}"
    
    # backup seguro
    if [ -f /etc/apt/sources.list ]; then
        cp /etc/apt/sources.list /etc/apt/sources.list.bkp
        echo -e "${GREEN}✔ Backup criado: /etc/apt/sources.list.bkp${NC}"
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
    echo -e "${GREEN}✔ Repositório Debian configurado em: $PATH_SOURCE${NC}"
else
    echo -e "${GREEN}✔ Repositório Debian já existe${NC}"
fi
echo
echo -e "${WHITE}────────────────────────────────────────────────────────────────────────────────${NC}"
echo -e "${CYAN}🔄 ATUALIZANDO SISTEMA${NC}"
echo
# ==============================================================================
# UPDATE SEGURO (SILENCIOSO)
# ==============================================================================
export DEBIAN_FRONTEND=noninteractive
# Atualiza lista de pacotes com progresso
echo -ne "${CYAN}▶ Atualizando lista de pacotes...${NC}\n"
(
    apt-get update -qq 2>/dev/null
) &
PID=$!
show_progress "$PID" "Atualizando lista de pacotes"
wait "$PID"
if [ $? -eq 0 ]; then
    echo -e "\r${GREEN}✔ Lista de pacotes atualizada${NC}    "
else
    echo -e "\r${RED}✖ Erro no apt update${NC}    "
    exit 1
fi
echo
# Atualiza pacotes com progresso
echo -ne "${CYAN}▶ Atualizando pacotes...${NC}\n"
(
    apt-get upgrade -y -qq 2>/dev/null
) &
PID=$!
show_progress "$PID" "Atualizando pacotes"
wait "$PID"
echo -e "\r${GREEN}✔ Pacotes atualizados${NC}    "
echo
# Corrige dependências quebradas com progresso
echo -ne "${CYAN}▶ Corrigindo dependências quebradas...${NC}\n"
(
    apt-get --fix-broken install -y -qq 2>/dev/null
) &
PID=$!
show_progress "$PID" "Corrigindo dependências"
wait "$PID"
echo -e "\r${GREEN}✔ Dependências corrigidas${NC}    "
echo
# Recarrega systemd (silencioso)
echo -ne "${CYAN}▶ Recarregando systemd...${NC}\n"
run_silent systemctl daemon-reload
echo -e "${GREEN}✔ Systemd recarregado${NC}"
echo
echo -e "${WHITE}════════════════════════════════════════════════════════════════════════════════════════${NC}"
echo -e "${GREEN}✓ SISTEMA ATUALIZADO COM SUCESSO${NC}"
echo -e "${WHITE}════════════════════════════════════════════════════════════════════════════════════════${NC}"
echo
