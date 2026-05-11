#!/bin/bash
set -e
clear

LOG_FILE="install_log.json"
FAILED_PACKAGES=()

echo "[" > "$LOG_FILE"

# ==========================================================
# CHECK DEBIAN
# ==========================================================
check_debian_stable() {
    . /etc/os-release
    if [[ "$ID" != "debian" ]]; then
        echo "❌ Apenas Debian suportado"
        exit 1
    fi
}

# ==========================================================
# CHECK INSTALADO
# ==========================================================
is_installed() {
    dpkg-query -W -f='${Status}' "$1" 2>/dev/null | grep -q "install ok installed"
}

# ==========================================================
# LOG JSON
# ==========================================================
log_json() {
    echo "{\"package\":\"$1\",\"status\":\"$2\"}," >> "$LOG_FILE"
}

# ==========================================================
# INSTALL PACKAGE
# ==========================================================
install_pkg() {
    PKG="$1"

    if is_installed "$PKG"; then
        log_json "$PKG" "installed"
        return
    fi

    if apt-get install -y "$PKG" >/dev/null 2>&1; then
        if is_installed "$PKG"; then
            log_json "$PKG" "installed"
        else
            log_json "$PKG" "installed_unverified"
            FAILED_PACKAGES+=("$PKG")
        fi
    else
        log_json "$PKG" "failed"
        FAILED_PACKAGES+=("$PKG")
    fi
}

# ==========================================================
# INSTALL GROUP
# ==========================================================
install_group() {
    NAME="$1"
    shift
    PACKAGES="$@"

    echo
    echo "=================================================="
    echo "[ $NAME ]"
    echo "=================================================="

    for PKG in $PACKAGES; do
        if is_installed "$PKG"; then
            STATUS="✅ Instalado"
        else
            echo -ne "📦 $PKG : ⚡ Instalando...\r"
            install_pkg "$PKG"

            if is_installed "$PKG"; then
                STATUS="✅ Instalado"
            else
                STATUS="❌ Falha"
            fi
        fi

        printf "📦 %-35s : %s\n" "$PKG" "$STATUS"
    done
}

# ==========================================================
# WINEHQ REPOSITORY SETUP
# ==========================================================
setup_winehq_repo() {

    echo
    echo "=================================================="
    echo "[ WINEHQ REPOSITORY ]"
    echo "=================================================="

    CODENAME=$(grep VERSION_CODENAME /etc/os-release | cut -d '=' -f2)

    mkdir -pm755 /etc/apt/keyrings

    # key
    wget -qO /etc/apt/keyrings/winehq-archive.key \
        https://dl.winehq.org/wine-builds/winehq.key

    # source list
    wget -qO /etc/apt/sources.list.d/winehq-${CODENAME}.sources \
        https://dl.winehq.org/wine-builds/debian/dists/stable/winehq-${CODENAME}.sources

    dpkg --add-architecture i386

    apt-get update -y >/dev/null 2>&1

    echo "✔ WineHQ repo configurado"
}

# ==========================================================
# WINE PACKAGES (mantidos do código original)
# ==========================================================
WINE_PACKAGES="wine winetricks mono-complete fonts-wine wine-binfmt winbind ttf-mscorefonts-installer binfmt-support xorg xvfb gtk2-engines-pixbuf imagemagick xauth vulkan-tools python3 libwine libwine-dev libkwin6 libvulkan1 libvkd3d1 libvulkan-dev libasound2-dev libinput-dev libssl-dev libxcomposite-dev libx11-dev libxrandr-dev libpng-dev libgtk-3-dev libsqlite3-dev libz-mingw-w64 libc6-i386 zlib1g libxft2 libcairo2 libpcl-dev libmpg123-dev libeio1 libeinfo1 libxext-dev libfreetype-dev libxfixes-dev libpcap-dev libdbus-1-dev libopenal-dev libgl1-mesa-dev libv4l-dev libsdl2-dev libgphoto2-dev libodbc2 libgnutls28-dev zlib1g-dev libglm-dev libdrm-dev mesa-utils"

# ==========================================================
# START
# ==========================================================
check_debian_stable

apt-get update -y >/dev/null 2>&1
apt-get upgrade -y >/dev/null 2>&1

setup_winehq_repo

install_group "WINEHQ PACKAGES" $WINE_PACKAGES

# ==========================================================
# MS CORE FONTS ACCEPT
# ==========================================================
echo ttf-mscorefonts-installer msttcorefonts/accepted-mscorefonts-eula select true | debconf-set-selections
echo
WINE_VERSION=$(wine --version)
	printf "✅ %-35s %s\n" "$WINE_VERSION"

# ==========================================================
# FINAL CHECK
# ==========================================================
echo
echo "=================================================="
echo "[ FINAL CHECK - FAILED PACKAGES ]"
echo "=================================================="

if [ ${#FAILED_PACKAGES[@]} -eq 0 ]; then
    echo "✔ Tudo instalado com sucesso"
else
    for PKG in "${FAILED_PACKAGES[@]}"; do
        echo "❌ $PKG"
    done
fi

# ==========================================================
# CLOSE JSON
# ==========================================================
sed -i '$ s/,$//' "$LOG_FILE"
echo "]" >> "$LOG_FILE"

echo
echo "📄 Log salvo: $LOG_FILE"
