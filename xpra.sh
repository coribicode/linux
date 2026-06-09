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
# VARIÁVEIS GLOBAIS
# ==============================================================================
LOG_FILE="install_log.json"
FAILED_PACKAGES=""
XPRA_GPG="/etc/apt/keyrings/xpra.gpg"
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
        printf "\r\033[KTempo: %02d:%02d:%02d   %s %s..." \
            "$hh" "$mm" "$ss" \
            "${SPINNER[$frame]}" \
            "$message"
        frame=$(( (frame + 1) % ${#SPINNER[@]} ))
        sleep 0.2
    done
    printf "\r\033[K"
}
# ==============================================================================
# INICIALIZA LOG JSON
# ==============================================================================
printf "[\n" > "$LOG_FILE"
# ==============================================================================
# VERIFICA DEBIAN
# ==============================================================================
check_debian_stable() {
    . /etc/os-release
    if [ "$ID" != "debian" ]; then
        echo -e "${RED}❌ Apenas Debian suportado${NC}"
        exit 1
    fi
}
# ==============================================================================
# VERIFICA PACOTE INSTALADO
# ==============================================================================
is_installed() {
    dpkg-query -W -f='${Status}' "$1" 2>/dev/null | grep -q "install ok installed"
}
# ==============================================================================
# VERIFICA PROVIDES
# ==============================================================================
check_provides() {
    apt-cache show "$1" 2>/dev/null | grep -q "Provides:"
}
# ==============================================================================
# LOG JSON
# ==============================================================================
log_json() {
    printf '{"package":"%s","status":"%s"},\n' "$1" "$2" >> "$LOG_FILE"
}
# ==============================================================================
# ADICIONA FALHA
# ==============================================================================
add_failed() {
    FAILED_PACKAGES="$FAILED_PACKAGES $1"
}
# ==============================================================================
# INSTALA PACOTE COM PROGRESSO
# ==============================================================================
install_pkg() {
    PKG="$1"
    if is_installed "$PKG"; then
        log_json "$PKG" "installed"
        return 0
    fi
    (
        apt-get install -y "$PKG" >/dev/null 2>&1
    ) &
    PID=$!
    show_progress "$PID" "Instalando $PKG"
    wait "$PID"
    if is_installed "$PKG"; then
        log_json "$PKG" "installed"
        return 0
    else
        if check_provides "$PKG"; then
            log_json "$PKG" "provided"
        else
            log_json "$PKG" "failed"
            add_failed "$PKG"
        fi
        return 1
    fi
}
# ==============================================================================
# IMPRIME PACOTE
# ==============================================================================
print_pkg() {
    printf "${ORANGE}%-35s${NC} : ${GREEN}%s${NC}\n" "$1" "$2"
}
# ==============================================================================
# INSTALA GRUPO
# ==============================================================================
install_group() {
    NAME="$1"
    shift   
    echo
    echo -e "${WHITE}────────────────────────────────────────────────────────────────────────────────${NC}"
    echo -e "${CYAN}📦 [ $NAME ]${NC}"
    echo -e "${WHITE}────────────────────────────────────────────────────────────────────────────────${NC}"
    echo
    for PKG in "$@"; do
        if is_installed "$PKG"; then
            print_pkg "$PKG" "✅ Instalado"
        else
            printf "${ORANGE}%-35s${NC} : ${YELLOW}⚡ Instalando...${NC}\n" "$PKG"
            if install_pkg "$PKG"; then
                # Move cursor up one line to overwrite the "Instalando..." line
                printf "\033[1A\r"
                print_pkg "$PKG" "✅ Instalado"
            else
                printf "\033[1A\r"
                print_pkg "$PKG" "❌ Falha"
            fi
        fi
    done
}
# ==============================================================================
# INSTALA REPOSITÓRIO XPRA
# ==============================================================================
install_xpra_repo() {
    echo
    echo -e "${WHITE}────────────────────────────────────────────────────────────────────────────────${NC}"
    echo -e "${CYAN}📦 [ XPRA REPOSITORY ]${NC}"
    echo -e "${WHITE}────────────────────────────────────────────────────────────────────────────────${NC}"
    echo   
    if [ -f "$XPRA_GPG" ]; then
        echo -e "${GREEN}✔ XPRA GPG já existe${NC}"
        return 0
    fi
    CODENAME=$(grep VERSION_CODENAME /etc/os-release | cut -d= -f2)
    echo -e "${YELLOW}⚠ Configurando repositório XPRA...${NC}"
    mkdir -p /etc/apt/keyrings
    (
        curl -fsSL https://xpra.org/gpg.asc | gpg --dearmor -o "$XPRA_GPG" >/dev/null 2>&1
    ) &
    PID=$!
    show_progress "$PID" "Baixando GPG key"
    wait "$PID"
    if [ ! -f "$XPRA_GPG" ]; then
        echo -e "\n${RED}❌ Falha GPG${NC}"
        add_failed "xpra-gpg"
        return 1
    fi
    echo "deb [signed-by=$XPRA_GPG] https://xpra.org/ $CODENAME main" > /etc/apt/sources.list.d/xpra.list
    (
        apt-get update -y >/dev/null 2>&1
    ) &
    PID=$!
    show_progress "$PID" "Atualizando repositórios"
    wait "$PID"
    if [ $? -ne 0 ]; then
        echo -e "\n${RED}❌ Falha apt update XPRA${NC}"
        add_failed "xpra-update"
        return 1
    fi
    echo -e "\n${GREEN}✔ XPRA repo configurado${NC}"
}
# ==============================================================================
# CABEÇALHO
# ==============================================================================
clear
echo -e "${WHITE}"
echo "════════════════════════════════════════════════════════════════════════════════════════"
echo "                         INSTALADOR XPRA - DEBIAN 13                           "
echo "════════════════════════════════════════════════════════════════════════════════════════"
echo -e "${NC}"
echo
# ==============================================================================
# VERIFICAÇÕES INICIAIS
# ==============================================================================
echo -e "${CYAN}▶ VERIFICANDO SISTEMA${NC}"
echo
check_debian_stable
echo -e "${GREEN}✔ Distribuição: Debian${NC}"
echo
echo -e "${CYAN}▶ ATUALIZANDO REPOSITÓRIOS${NC}"
echo
(
    apt-get update -y >/dev/null 2>&1
) &
PID=$!
show_progress "$PID" "Atualizando repositórios"
wait "$PID"
echo -e "\n${GREEN}✔ Repositórios atualizados${NC}"
echo
# ==============================================================================
# INSTALAÇÃO DOS GRUPOS
# ==============================================================================
install_group "ESSENTIALS" git curl wget sudo ca-certificates pkg-config
install_group "XPRA DRIVERS" i965-va-driver x264 va-driver-all vdpau-driver-all intel-media-va-driver-non-free pulseaudio
install_group "GRAPHICS" gstreamer1.0-plugins-base gstreamer1.0-plugins-good gstreamer1.0-plugins-ugly vainfo
install_group "LIBS" libva-drm2 libva-x11-2 libvpx9 libx264-dev libwebp-dev libgtk-3-dev libsystemd-dev
# ==============================================================================
# INSTALA XPRA REPO
# ==============================================================================
install_xpra_repo
# ==============================================================================
# INSTALA XPRA
# ==============================================================================
install_group "XPRA" xpra xpra-client-gtk3 xpra-codecs-extras xpra-codecs xpra-common xpra-client xpra-audio xpra-x11 xpra-html5 xpra-server
# ==============================================================================
# VERIFICA VERSÃO DO XPRA
# ==============================================================================
echo
echo -e "${WHITE}────────────────────────────────────────────────────────────────────────────────${NC}"
echo -e "${CYAN}📦 [ XPRA VERSION ]${NC}"
echo -e "${WHITE}────────────────────────────────────────────────────────────────────────────────${NC}"
echo
if command -v xpra >/dev/null 2>&1; then
    XPRA_VERSION=$(xpra --version | head -n1)
    echo -e "${GREEN}✔ $XPRA_VERSION${NC}"
else
    echo -e "${RED}❌ XPRA não instalado${NC}"
    add_failed "xpra-binary"
fi
# ==============================================================================
# FINAL CHECK
# ==============================================================================
echo
echo -e "${WHITE}════════════════════════════════════════════════════════════════════════════════════════${NC}"
echo -e "${CYAN}📋 FINAL CHECK - FAILED PACKAGES${NC}"
echo -e "${WHITE}════════════════════════════════════════════════════════════════════════════════════════${NC}"
echo
if [ -z "$FAILED_PACKAGES" ]; then
    echo -e "${GREEN}✓ Tudo instalado com sucesso${NC}"
else
    for PKG in $FAILED_PACKAGES; do
        echo -e "${RED}❌ $PKG${NC}"
    done
fi
# ==============================================================================
# FINALIZA LOG JSON
# ==============================================================================
sed -i '$ s/,$//' "$LOG_FILE"
printf "]\n" >> "$LOG_FILE"
echo
echo -e "${GREEN}📄 Log salvo: $LOG_FILE${NC}"
echo
