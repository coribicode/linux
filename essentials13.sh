#!/bin/bash
GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
CYAN='\033[0;36m'
NC='\033[0m'
FAILED_PACKAGES=()
PACKAGES=(
build-essential firmware-linux lsb-release apt-transport-https lsof gnu-which module-assistant ca-certificates aptitude sudo wget acl git curl perl tar unzip lzip xorg xvfb xauth pulseaudio alsa-utils alsa-tools libasound2t64 libasound2-dev udns-utils net-tools rfkill screenfetch cmake g++ gcc make automake autoconf flex bison bc gdb gnupg gnutls-bin libjwt-gnutls-dev
)
center_text() {
local TEXT="$1"
local WIDTH=$(tput cols)
local PADDING=$(( (WIDTH - ${#TEXT}) / 2 ))
printf "%*s%s\n" "$PADDING" "" "$TEXT"
}
is_installed() {
dpkg-query -W -f='${Status}' "$1" 2>/dev/null | grep -q "install ok installed"
}
apt-get update -y >/dev/null 2>&1
echo
center_text "========================================================"
center_text "[ CHECKLIST ]: INSTALAÇÃO DE PACOTES"
center_text "========================================================"
echo
for PKG in "${PACKAGES[@]}"; do
if is_installed "$PKG"; then
printf "${GREEN}✔${NC} %-30s ${GREEN}[ OK ]${NC} Já instalado\n" "$PKG"
else
printf "${RED}✘${NC} %-30s ${RED}[ NÃO INSTALADO ]${NC}\n" "$PKG"
printf "${YELLOW}⠋${NC} %-30s ${YELLOW}[ INSTALANDO... ]${NC}\n" "$PKG"
if DEBIAN_FRONTEND=noninteractive apt-get install -y "$PKG" >/dev/null 2>&1; then
if is_installed "$PKG"; then
printf "${GREEN}✔${NC} %-30s ${GREEN}[ INSTALADO ]${NC}\n" "$PKG"
else
printf "${RED}✘${NC} %-30s ${RED}[ FALHA ]${NC}\n" "$PKG"
FAILED_PACKAGES+=("$PKG")
fi
else
printf "${RED}✘${NC} %-30s ${RED}[ ERRO INSTALL ]${NC}\n" "$PKG"
FAILED_PACKAGES+=("$PKG")
fi
fi
done
echo
center_text "========================================================"
center_text "[ CHECKLIST ]: VALIDAÇÃO FINAL"
center_text "========================================================"
echo
for PKG in "${PACKAGES[@]}"; do
if is_installed "$PKG"; then
printf "${GREEN}✔${NC} %-30s ${GREEN}[ OK ]${NC} Instalado\n" "$PKG"
else
printf "${RED}✘${NC} %-30s ${RED}[ ERRO ]${NC} Não instalado\n" "$PKG"
fi
done
echo
if [ ${#FAILED_PACKAGES[@]} -eq 0 ]; then
printf "${GREEN}✔ Todos os pacotes instalados com sucesso${NC}\n"
else
printf "${RED}Pacotes com falha:${NC}\n"
for PKG in "${FAILED_PACKAGES[@]}"; do
echo " - $PKG"
done
fi
echo
center_text "========================================================"
