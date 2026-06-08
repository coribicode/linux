#!/bin/bash

clear

# =========================
# CORES
# =========================

COR_VERDE="\e[32m"
COR_VERMELHO="\e[31m"
COR_AMARELO="\e[33m"
COR_AZUL="\e[34m"
COR_RESET="\e[0m"

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
# SPINNER
# =========================

spinner() {
    local PID=$1
    local SPIN='|/-\'

    while kill -0 "$PID" 2>/dev/null
    do
        for ((i=0; i<${#SPIN}; i++))
        do
            printf "\r${COR_AMARELO}[%c] Instalando...${COR_RESET}" "${SPIN:$i:1}"
            sleep 0.10
        done
    done

    printf "\r%-60s\r" ""
}

# =========================
# CABEÇALHO
# =========================

echo
printf "%-4s %-35s %-20s %-25s\n" \
"#" \
"PACOTE" \
"STATUS" \
"VERSÃO"

printf "%-4s %-35s %-20s %-25s\n" \
"----" \
"-----------------------------------" \
"--------------------" \
"-------------------------"

# =========================
# CONTADORES
# =========================

TOTAL=${#PACOTES[@]}
ATUAL=0
OK=0
FALHA=0

# =========================
# PROCESSAMENTO
# =========================

for PACOTE in "${PACOTES[@]}"
do

    ((ATUAL++))

    STATUS=$(dpkg-query -W -f='${db:Status-Abbrev}' "$PACOTE" 2>/dev/null)

    if [[ "$STATUS" == ii* ]]
    then

        VERSAO=$(dpkg-query -W -f='${Version}' "$PACOTE" 2>/dev/null)

        printf "%-4s %-35s ${COR_VERDE}%-20s${COR_RESET} ${COR_AZUL}%-25s${COR_RESET}\n" \
            "[$ATUAL/$TOTAL]" \
            "$PACOTE" \
            "Instalado" \
            "$VERSAO"

        ((OK++))

        continue

    fi

    printf "%-4s %-35s ${COR_VERMELHO}%-20s${COR_RESET} %-25s\n" \
        "[$ATUAL/$TOTAL]" \
        "$PACOTE" \
        "Não Instalado" \
        "--"

    read -rp "Instalar $PACOTE ? (s/N): " RESP < /dev/tty

    if [[ ! "$RESP" =~ ^[sS]$ ]]
    then
        ((FALHA++))
        continue
    fi

    echo

    apt install -y "$PACOTE" >/dev/null 2>&1 &
    APT_PID=$!

    spinner "$APT_PID"

    wait "$APT_PID"
    RESULTADO=$?

    if [ "$RESULTADO" -eq 0 ]
    then

        VERSAO=$(dpkg-query -W -f='${Version}' "$PACOTE" 2>/dev/null)

        printf "%-4s %-35s ${COR_VERDE}%-20s${COR_RESET} ${COR_AZUL}%-25s${COR_RESET}\n" \
            "[$ATUAL/$TOTAL]" \
            "$PACOTE" \
            "Instalado" \
            "$VERSAO"

        ((OK++))

    else

        printf "%-4s %-35s ${COR_VERMELHO}%-20s${COR_RESET} %-25s\n" \
            "[$ATUAL/$TOTAL]" \
            "$PACOTE" \
            "Falhou" \
            "--"

        ((FALHA++))

    fi

done

# =========================
# RESUMO
# =========================

echo
echo "=============================================================="
echo "RESUMO FINAL"
echo "=============================================================="

echo -e "Total     : ${COR_AZUL}$TOTAL${COR_RESET}"
echo -e "Sucesso   : ${COR_VERDE}$OK${COR_RESET}"
echo -e "Falhas    : ${COR_VERMELHO}$FALHA${COR_RESET}"

PERCENTUAL=$((OK * 100 / TOTAL))

echo
printf "["

BARRA=$((PERCENTUAL / 2))

for ((i=0;i<50;i++))
do
    if [ "$i" -lt "$BARRA" ]
    then
        printf "#"
    else
        printf "."
    fi
done

printf "] %d%%\n" "$PERCENTUAL"

echo
echo -e "${COR_VERDE}Processo concluído.${COR_RESET}"
echo

read -rp "Pressione ENTER para continuar..." < /dev/tty
