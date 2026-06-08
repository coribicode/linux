#!/bin/bash
clear
# =========================
# CORES
# =========================
VERDE=$'\033[32m'
VERMELHO=$'\033[31m'
RESET=$'\033[0m'
# =========================
# PACOTES
# =========================
PACOTES=(
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
# =========================
# MAPA DEBIAN
# =========================
declare -A MAPA=(
    [which]="debianutils"
    [dnsutils]="bind9-dnsutils"
)
# =========================
# CHECK
# =========================
resolve_installed() {
    local p="$1"
    if [[ -z "${MAPA[$p]}" ]]; then
        dpkg -s "$p" >/dev/null 2>&1 && return 0
        return 1
    fi
    for pkg in ${MAPA[$p]}; do
        dpkg -s "$pkg" >/dev/null 2>&1 && return 0
    done
    return 1
}
get_version() {
    local p="$1"
    if [[ -n "${MAPA[$p]}" ]]; then
        for pkg in ${MAPA[$p]}; do
            if dpkg -s "$pkg" >/dev/null 2>&1; then
                dpkg -s "$pkg" | awk -F': ' '/Version/ {print $2}'
                return
            fi
        done
    fi
    dpkg -s "$p" 2>/dev/null | awk -F': ' '/Version/ {print $2}'
}
# =========================
# RENDER
# =========================
render() {
    clear
    echo "╔════════════════════════════════════════════════════════════╗"
    echo "║                 PAINEL DE PACOTES APT                      ║"
    echo "╚════════════════════════════════════════════════════════════╝"
    # HEADER INVERTIDO
    printf "%-25s %-20s %-10s\n" "PACOTE" "VERSÃO" "STATUS"
    echo "------------------------------------------------------------"
    for p in "${PACOTES[@]}"; do
        if resolve_installed "$p"; then
            version="$(get_version "$p")"
            status="${VERDE}OK${RESET}"
        else
            version="--"
            status="${VERMELHO}FALTA${RESET}"
        fi
        # ORDEM INVERTIDA AQUI:
        printf "%-25s %-20s %-10b\n" "$p" "$version" "$status"
    done
}
# =========================
# EXECUÇÃO
# =========================
render
# =========================
# VERIFICA FALTANTES
# =========================
MISSING=()
for p in "${PACOTES[@]}"; do
    if ! resolve_installed "$p"; then
        MISSING+=("$p")
    fi
done
if [ "${#MISSING[@]}" -eq 0 ]; then
    echo
    echo -e "${VERDE}✔ Todos os pacotes já estão instalados.${RESET}"
    exit 0
fi
echo
read -rp "Instalar ${#MISSING[@]} pacotes faltantes? (s/N): " RESP < /dev/tty
[[ ! "$RESP" =~ ^[sS]$ ]] && exit 0
# =========================
# INSTALAÇÃO
# =========================
for p in "${MISSING[@]}"; do
    if [[ -n "${MAPA[$p]}" ]]; then
        apt install -y ${MAPA[$p]} >/dev/null 2>&1
    else
        apt install -y "$p" >/dev/null 2>&1
    fi
done
# =========================
# FINAL
# =========================
render
echo
echo -e "${VERDE}✔ CONCLUÍDO${RESET}"
