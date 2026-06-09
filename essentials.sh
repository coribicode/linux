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
# PACOTES
# ==============================================================================
PACKAGES=(
util-linux
build-essential
firmware-linux
lsb-release
apt-transport-https
dbus-user-session
systemd-container
lsof
gnu-which
module-assistant
ca-certificates
udns-utils
net-tools
rfkill
flex
bison
bc
gdb
gnupg
gnutls-bin
aptitude
sudo
wget
acl
git
curl
perl
cmake
g++
gcc
make
automake
autoconf
ssh
tar
unzip
lzip
xorg
xvfb
xauth
pulseaudio
pulseaudio-utils
alsa-utils
alsa-tools
screenfetch
wmctrl
)
# ==============================================================================
# ARRAYS
# ==============================================================================
declare -A INSTALLED
declare -A VERSION
declare -A STATUS
declare -A STATUS_COLOR
MISSING_PACKAGES=()
SPINNER=("⠋" "⠙" "⠹" "⠸" "⠼" "⠴" "⠦" "⠧" "⠇" "⠏")
# ==============================================================================
# CARREGA PACOTES INSTALADOS
# ==============================================================================
load_installed_packages() {
    INSTALLED=()
    while read -r pkg ver
    do
        INSTALLED["$pkg"]="$ver"
    done < <(
        dpkg-query -W -f='${Package} ${Version}\n' 2>/dev/null
    )
}
# ==============================================================================
# VERIFICA PACOTE
# ==============================================================================
check_package() {
    local pkg="$1"
    if [[ -n "${INSTALLED[$pkg]:-}" ]]
    then
        VERSION["$pkg"]="${INSTALLED[$pkg]}"
        STATUS["$pkg"]="Instalado"
        STATUS_COLOR["$pkg"]="$GREEN"
        return 0
    fi
    VERSION["$pkg"]="---"
    STATUS["$pkg"]="Não instalado"
    STATUS_COLOR["$pkg"]="$RED"
    return 1
}
# ==============================================================================
# VERIFICA TODOS
# ==============================================================================
verify_packages() {
    MISSING_PACKAGES=()
    load_installed_packages
    for pkg in "${PACKAGES[@]}"
    do
        if ! check_package "$pkg"
        then
            MISSING_PACKAGES+=("$pkg")
        fi
    done
}
# ==============================================================================
# TABELA
# ==============================================================================
draw_table() {
    echo -e "${WHITE}"
    echo "════════════════════════════════════════════════════════════════════════════════════════"
    echo "                         INSTALADOR DE PACOTES - DEBIAN 13                           "
    echo "════════════════════════════════════════════════════════════════════════════════════════"
    echo -e "${NC}"
    printf "${WHITE}%-25s %-30s %-25s${NC}\n" "PACOTE" "VERSAO" "STATUS"
    printf "${WHITE}%-25s %-30s %-25s${NC}\n" "-------------------------" "------------------------------" "-------------------------"
    for pkg in "${PACKAGES[@]}"
    do
        printf "%b%-25s%b " \
            "$ORANGE" "$pkg" "$NC"
        printf "%-30s " "${VERSION[$pkg]}"
        printf "%b%-25s%b\n" \
            "${STATUS_COLOR[$pkg]}" \
            "${STATUS[$pkg]}" \
            "$NC"
    done
    echo
}
# ==============================================================================
# PROGRESSO
# ==============================================================================
show_install_progress() {
    local pid="$1"
    local total="$2"
    local start
    start=$(date +%s)
    local frame=0
    echo
    echo "Pacotes solicitados : $total"
    echo
    while kill -0 "$pid" 2>/dev/null
    do
        local now elapsed hh mm ss
        now=$(date +%s)
        elapsed=$((now - start))
        hh=$((elapsed / 3600))
        mm=$(((elapsed % 3600) / 60))
        ss=$((elapsed % 60))
        printf "\rTempo: %02d:%02d:%02d   %s Instalando pacotes..." \
            "$hh" "$mm" "$ss" \
            "${SPINNER[$frame]}"
        frame=$(( (frame + 1) % ${#SPINNER[@]} ))
        sleep 0.2
    done
    echo
    echo
}
# ==============================================================================
# ROOT
# ==============================================================================
if [ "$(id -u)" -ne 0 ]
then
    echo
    echo "Execute como root."
    echo
    exit 1
fi
# ==============================================================================
# LIMPA TELA E ATUALIZA REPOSITÓRIOS
# ==============================================================================
clear
echo
echo -e "${CYAN}Atualizando repositórios...${NC}"
if ! apt-get update -qq >/dev/null 2>&1
then
    echo
    echo -e "${RED}Falha ao atualizar repositórios.${NC}"
    exit 1
fi
echo -e "${GREEN}✓ Repositórios atualizados${NC}"
echo
# ==============================================================================
# VERIFICAÇÃO INICIAL
# ==============================================================================
verify_packages
draw_table
# ==============================================================================
# TUDO INSTALADO
# ==============================================================================
if [ "${#MISSING_PACKAGES[@]}" -eq 0 ]
then
    echo -e "${GREEN}Todos os pacotes já estão instalados.${NC}"
    echo
    exit 0
fi
# ==============================================================================
# LISTA DE PACOTES A INSTALAR
# ==============================================================================
echo -e "${WHITE}Pacotes que serão instalados:${NC}"
echo
for pkg in "${MISSING_PACKAGES[@]}"
do
    echo -e "  ${ORANGE}${pkg}${NC}"
done
echo
read -rp "Deseja continuar? [s/N]: " CONFIRM
case "$CONFIRM" in
    s|S|sim|SIM|y|Y)
        echo
        ;;
    *)
        echo
        echo "Instalação cancelada."
        exit 0
        ;;
esac
# ==============================================================================
# INSTALAÇÃO
# ==============================================================================
LOG_FILE="/tmp/install_packages.log"
# Inicia a instalação em segundo plano
apt-get install -y \
    "${MISSING_PACKAGES[@]}" \
    >"$LOG_FILE" 2>&1 &
PID=$!
# Mostra o progresso da instalação
show_install_progress "$PID" "${#MISSING_PACKAGES[@]}"
wait "$PID"
RET=$?
# ==============================================================================
# ERRO
# ==============================================================================
if [ "$RET" -ne 0 ]
then
    echo -e "${RED}Falha durante a instalação.${NC}"
    echo

    tail -20 "$LOG_FILE"

    exit 1
fi
# ==============================================================================
# FINAL - MOSTRA RESULTADO (SEM LIMPAR TELA)
# ==============================================================================
# Verifica novamente os pacotes e desenha a tabela final
verify_packages
draw_table
if [ "${#MISSING_PACKAGES[@]}" -eq 0 ]
then
    echo -e "${GREEN}✓ Todos os pacotes foram instalados com sucesso.${NC}"
else
    echo -e "${YELLOW}Alguns pacotes ainda não foram instalados:${NC}"

    for pkg in "${MISSING_PACKAGES[@]}"
    do
        echo " - $pkg"
    done
fi
echo
