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
# PATH GLOBAL DO SISTEMA
# ==============================================================================
echo -e "${WHITE}────────────────────────────────────────────────────────────────────────────────${NC}"
echo -e "${CYAN}🛠️ CONFIGURANDO PATH GLOBAL${NC}"
echo
FIX_PATH="/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin"
PATH_OK=1
[ -f /etc/environment ] || PATH_OK=0
[ -f /etc/profile.d/path.sh ] || PATH_OK=0
grep -q "^PATH=\"$FIX_PATH\"$" /etc/environment 2>/dev/null || PATH_OK=0
grep -q "^export PATH=\"$FIX_PATH\"$" /etc/profile.d/path.sh 2>/dev/null || PATH_OK=0
if [ "$PATH_OK" -eq 1 ]
then
    echo -e "${GREEN}✔ PATH global já configurado${NC}"
else
    echo -e "${YELLOW}⚠ Configurando PATH global...${NC}"
    mkdir -p /etc/profile.d
    cat > /etc/environment <<EOF
PATH="$FIX_PATH"
EOF
    cat > /etc/profile.d/path.sh <<EOF
export PATH="$FIX_PATH"
EOF
    chmod 644 /etc/environment
    chmod 644 /etc/profile.d/path.sh
    echo -e "${GREEN}✔ PATH global configurado${NC}"
fi
# Aplicação imediata na sessão atual
export PATH="$FIX_PATH"
source /etc/profile 2>/dev/null
echo -e "${GREEN}✔ PATH aplicado na sessão atual${NC}"
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
    
    # Cria o arquivo de sources usando echo em vez de here-document
    echo "Types: $TYPES" > "$PATH_SOURCE"
    echo "URIs: $URIS" >> "$PATH_SOURCE"
    echo "Suites: $SUITES" >> "$PATH_SOURCE"
    echo "Components: $COMPONENTES" >> "$PATH_SOURCE"
    echo "Signed-By: $SIGNED" >> "$PATH_SOURCE"
    echo "Enabled: yes" >> "$PATH_SOURCE"
    echo "" >> "$PATH_SOURCE"
    echo "Types: $TYPES" >> "$PATH_SOURCE"
    echo "URIs: $URIS_SEC" >> "$PATH_SOURCE"
    echo "Suites: $SUITES_SEC" >> "$PATH_SOURCE"
    echo "Components: $COMPONENTES" >> "$PATH_SOURCE"
    echo "Signed-By: $SIGNED" >> "$PATH_SOURCE"
    echo "Enabled: yes" >> "$PATH_SOURCE"
    
    echo -e "${GREEN}✔ Repositório Debian configurado em: $PATH_SOURCE${NC}"
else
    echo -e "${GREEN}✔ Repositório Debian já existe${NC}"
fi

echo
echo -e "${WHITE}────────────────────────────────────────────────────────────────────────────────${NC}"
echo -e "${CYAN}🔄 ATUALIZANDO SISTEMA${NC}"
echo

# ==============================================================================
# UPDATE SEGURO (COMPLETAMENTE SILENCIOSO)
# ==============================================================================
export DEBIAN_FRONTEND=noninteractive

# Atualiza lista de pacotes com progresso
echo -ne "${CYAN}▶ Atualizando lista de pacotes...${NC}\n"
(
    apt-get update -qq 2>&1 >/dev/null | true
) &
PID=$!
show_progress "$PID" "Atualizando lista de pacotes"
wait "$PID" 2>/dev/null
echo -e "\r${GREEN}✔ Lista de pacotes atualizada${NC}    "
echo

# Atualiza pacotes com progresso (completamente silencioso)
echo -ne "${CYAN}▶ Atualizando pacotes...${NC}\n"
(
    apt-get upgrade -y -qq 2>&1 >/dev/null | true
) &
PID=$!
show_progress "$PID" "Atualizando pacotes"
wait "$PID" 2>/dev/null
echo -e "\r${GREEN}✔ Pacotes atualizados${NC}    "
echo

# Corrige dependências quebradas com progresso (completamente silencioso)
echo -ne "${CYAN}▶ Corrigindo dependências quebradas...${NC}\n"
(
    apt-get --fix-broken install -y -qq 2>&1 >/dev/null | true
) &
PID=$!
show_progress "$PID" "Corrigindo dependências"
wait "$PID" 2>/dev/null
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
