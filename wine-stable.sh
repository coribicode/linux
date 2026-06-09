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
        log_json "$PKG" "failed"
        add_failed "$PKG"
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
# CONFIGURA REPOSITÓRIO WINEHQ
# ==============================================================================
setup_winehq_repo() {
    echo
    echo -e "${WHITE}────────────────────────────────────────────────────────────────────────────────${NC}"
    echo -e "${CYAN}📦 [ WINEHQ REPOSITORY ]${NC}"
    echo -e "${WHITE}────────────────────────────────────────────────────────────────────────────────${NC}"
    echo
    
    CODENAME=$(grep VERSION_CODENAME /etc/os-release | cut -d '=' -f2)
    
    echo -e "${YELLOW}⚠ Configurando repositório WineHQ...${NC}"
    
    mkdir -pm755 /etc/apt/keyrings
    
    (
        wget -qO /etc/apt/keyrings/winehq-archive.key https://dl.winehq.org/wine-builds/winehq.key 2>/dev/null
    ) &
    PID=$!
    show_progress "$PID" "Baixando GPG key"
    wait "$PID"
    
    if [ ! -f /etc/apt/keyrings/winehq-archive.key ]; then
        echo -e "\n${RED}❌ Falha download key${NC}"
        add_failed "winehq-key"
        return 1
    fi
    
    (
        wget -qO /etc/apt/sources.list.d/winehq-"$CODENAME".sources https://dl.winehq.org/wine-builds/debian/dists/stable/winehq-"$CODENAME".sources 2>/dev/null
    ) &
    PID=$!
    show_progress "$PID" "Baixando repo"
    wait "$PID"
    
    if [ ! -f /etc/apt/sources.list.d/winehq-"$CODENAME".sources ]; then
        echo -e "\n${RED}❌ Falha download repo${NC}"
        add_failed "winehq-repo"
        return 1
    fi
    
    (
        dpkg --add-architecture i386 >/dev/null 2>&1
    ) &
    PID=$!
    show_progress "$PID" "Adicionando i386"
    wait "$PID"
    
    (
        apt-get update -y >/dev/null 2>&1
    ) &
    PID=$!
    show_progress "$PID" "Atualizando repositórios"
    wait "$PID"
    
    if [ $? -ne 0 ]; then
        echo -e "\n${RED}❌ Falha apt update${NC}"
        add_failed "winehq-update"
        return 1
    fi
    
    echo -e "\n${GREEN}✔ WineHQ repo configurado${NC}"
}

# ==============================================================================
# CABEÇALHO
# ==============================================================================
clear

echo -e "${WHITE}"
echo "════════════════════════════════════════════════════════════════════════════════════════"
echo "                         INSTALADOR WINEHQ - DEBIAN 13                           "
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
echo -e "${CYAN}▶ ATUALIZANDO PACOTES${NC}"
echo

(
    apt-get upgrade -y >/dev/null 2>&1
) &
PID=$!
show_progress "$PID" "Atualizando pacotes"
wait "$PID"
echo -e "\n${GREEN}✔ Pacotes atualizados${NC}"

# ==============================================================================
# CONFIGURA REPO WINEHQ
# ==============================================================================
setup_winehq_repo

# ==============================================================================
# INSTALAÇÃO DOS PACOTES WINEHQ
# ==============================================================================
install_group "WINEHQ PACKAGES" \
wine \
winetricks \
mono-complete \
fonts-wine \
wine-binfmt \
winbind \
ttf-mscorefonts-installer \
binfmt-support \
xorg \
xvfb \
gtk2-engines-pixbuf \
imagemagick \
xauth \
vulkan-tools \
python3 \
libwine \
libwine-dev \
libkwin6 \
libvulkan1 \
libvkd3d1 \
libvulkan-dev \
libasound2-dev \
libinput-dev \
libssl-dev \
libxcomposite-dev \
libx11-dev \
libxrandr-dev \
libpng-dev \
libgtk-3-dev \
libsqlite3-dev \
libz-mingw-w64 \
libc6-i386 \
zlib1g \
libxft2 \
libcairo2 \
libpcl-dev \
libmpg123-dev \
libeio1 \
libeinfo1 \
libxext-dev \
libfreetype-dev \
libxfixes-dev \
libpcap-dev \
libdbus-1-dev \
libopenal-dev \
libgl1-mesa-dev \
libv4l-dev \
libsdl2-dev \
libgphoto2-dev \
libodbc2 \
libgnutls28-dev \
zlib1g-dev \
libglm-dev \
libdrm-dev \
mesa-utils

# ==============================================================================
# CONFIGURAÇÃO MS FONTS
# ==============================================================================
echo
echo -e "${WHITE}────────────────────────────────────────────────────────────────────────────────${NC}"
echo -e "${CYAN}📦 [ CONFIGURANDO MICROSOFT FONTS ]${NC}"
echo -e "${WHITE}────────────────────────────────────────────────────────────────────────────────${NC}"
echo

echo -e "${YELLOW}⚠ Aceitando EULA do ttf-mscorefonts-installer...${NC}"
echo ttf-mscorefonts-installer msttcorefonts/accepted-mscorefonts-eula select true | debconf-set-selections
echo -e "${GREEN}✔ EULA aceita${NC}"

# ==============================================================================
# VERIFICA VERSÃO DO WINE
# ==============================================================================
echo
echo -e "${WHITE}────────────────────────────────────────────────────────────────────────────────${NC}"
echo -e "${CYAN}📦 [ WINE VERSION ]${NC}"
echo -e "${WHITE}────────────────────────────────────────────────────────────────────────────────${NC}"
echo

if command -v wine >/dev/null 2>&1; then
    WINE_VERSION=$(wine --version 2>/dev/null | head -n1)
    echo -e "${GREEN}✔ $WINE_VERSION${NC}"
else
    echo -e "${RED}❌ Wine não instalado${NC}"
    add_failed "wine-binary"
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
