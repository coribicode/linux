#!/bin/bash
clear
GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
CYAN='\033[0;36m'
NC='\033[0m'
PACKAGES=(
build-essential firmware-linux lsb-release apt-transport-https lsof which module-assistant ca-certificates aptitude sudo wget acl git curl perl tar unzip lzip xorg xvfb xauth pulseaudio alsa-utils alsa-tools libasound2 libasound2-dev udns-utils net-tools rfkill screenfetch cmake g++ gcc make automake autoconf flex bison bc gdb gnupg gnupg1 gnupg2 gnutls-bin libjwt-gnutls-dev
)
center_text() {
    local TEXT="$1"
    local WIDTH=$(tput cols)
    local PADDING=$(( (WIDTH - ${#TEXT}) / 2 ))
    printf "%*s%s\n" "$PADDING" "" "$TEXT"
}
echo
center_text "========================================================"
center_text "[ CHECKLIST ]: INSTALAÇÃO DE PACOTES"
center_text "========================================================"
echo
for PKG in "${PACKAGES[@]}"; do
    if dpkg -s "${PKG}" >/dev/null 2>&1; then
        printf "${GREEN}✔${NC} %-30s ${GREEN}[ OK ]${NC} Já instalado\n" "${PKG}"
    else
        printf "${RED}✘${NC} %-30s ${RED}[ NÃO INSTALADO ]${NC}\n" "${PKG}"
        sleep 1
        printf "${YELLOW}⠋${NC} %-30s ${YELLOW}[ INSTALANDO... ]${NC}\n" "${PKG}"
        DEBIAN_FRONTEND=noninteractive apt install -y "${PKG}" >/dev/null 2>&1
        sleep 1
    fi
done
echo
center_text "========================================================"
center_text "[ CHECKLIST ]: VALIDAÇÃO FINAL"
center_text "========================================================"
echo
for PKG in "${PACKAGES[@]}"; do
    if dpkg -s "${PKG}" >/dev/null 2>&1; then
        printf "${GREEN}✔${NC} %-30s ${GREEN}[ OK ]${NC} Instalado\n" "${PKG}"
    else
        printf "${RED}✘${NC} %-30s ${RED}[ ERRO ]${NC} Não instalado\n" "${PKG}"
    fi
done
echo
center_text "========================================================"
