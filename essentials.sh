clear
#!/bin/bash
# =========================
# CORES
# =========================
COR_VERDE="\e[32m"
COR_VERMELHO="\e[31m"
COR_AZUL="\e[34m"
COR_AMARELO="\e[33m"
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
# VERIFICAÇÃO
# =========================
FALTANDO=()
echo
printf "%-35s %-20s %-35s\n" \
"PACOTE" \
"STATUS" \
"VERSÃO"
printf "%-35s %-20s %-35s\n" \
"-----------------------------------" \
"--------------------" \
"-----------------------------------"
for PACOTE in "${PACOTES[@]}"
do
    if dpkg-query -W "$PACOTE" >/dev/null 2>&1
    then
        VERSAO=$(dpkg-query -W -f='${Version}' "$PACOTE" 2>/dev/null)
        printf "%-35s ${COR_VERDE}%-20s${COR_RESET} ${COR_AZUL}%-35s${COR_RESET}\n" \
            "$PACOTE" \
            "Instalado" \
            "$VERSAO"
    else
        printf "%-35s ${COR_VERMELHO}%-20s${COR_RESET} %-35s\n" \
            "$PACOTE" \
            "Não Instalado" \
            "-"
        FALTANDO+=("$PACOTE")
    fi
done
# =========================
# RESUMO
# =========================
echo
echo "====================================================="
echo "RESUMO"
echo "====================================================="
echo "Total Pacotes : ${#PACOTES[@]}"
echo "Instalados    : $((${#PACOTES[@]}-${#FALTANDO[@]}))"
echo "Ausentes      : ${#FALTANDO[@]}"
echo
# =========================
# TODOS INSTALADOS
# =========================
if [ ${#FALTANDO[@]} -eq 0 ]
then
    echo -e "${COR_VERDE}✓ Todos os pacotes estão instalados.${COR_RESET}"
    echo
    # NÃO ENCERRA O SCRIPT
    # Apenas continua normalmente
else
    # =========================
    # PACOTES AUSENTES
    # =========================
    echo -e "${COR_AMARELO}Pacotes Ausentes:${COR_RESET}"
    echo
    printf ' - %s\n' "${FALTANDO[@]}"
    echo
    echo "Comando de instalação:"
    echo
    echo "apt update && apt install -y ${FALTANDO[*]}"
    echo
    read -p "Deseja instalar os pacotes ausentes? (s/N): " RESP
    if [[ "$RESP" =~ ^[sS]$ ]]
    then
        echo
        echo "Atualizando repositórios..."
        apt update
        echo
        echo "Instalando pacotes..."
        apt install -y "${FALTANDO[@]}" 2>/dev/null
        echo
        echo -e "${COR_VERDE}✓ Instalação concluída.${COR_RESET}"
    else
        echo
        echo -e "${COR_VERMELHO}✗ Instalação cancelada.${COR_RESET}"
    fi
fi
