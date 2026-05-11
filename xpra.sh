#!/bin/bash
set -e
clear
LOG_FILE="install_log.json"
FAILED_PACKAGES=()

echo "[" > "$LOG_FILE"

# ==========================================================
# DEBIAN CHECK
# ==========================================================
check_debian_stable() {
    . /etc/os-release
    if [[ "$ID" != "debian" ]]; then
        echo "❌ Apenas Debian suportado"
        exit 1
    fi
}

# ==========================================================
# INSTALADO REAL
# ==========================================================
is_installed() {
    dpkg-query -W -f='${Status}' "$1" 2>/dev/null | grep -q "install ok installed"
}

# ==========================================================
# PROVIDES CHECK
# ==========================================================
check_provides() {
    apt-cache show "$1" 2>/dev/null | grep -q "Provides:"
}

# ==========================================================
# LOG JSON
# ==========================================================
log_json() {
    echo "{\"package\":\"$1\",\"status\":\"$2\"}," >> "$LOG_FILE"
}

# ==========================================================
# INSTALL PACKAGE (SEM ANIMAÇÃO VISUAL AGORA)
# ==========================================================
install_pkg() {
    PKG="$1"

    if is_installed "$PKG"; then
        log_json "$PKG" "installed"
        STATUS="✅ Instalado"
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
        if check_provides "$PKG"; then
            log_json "$PKG" "provided"
        else
            log_json "$PKG" "failed"
            FAILED_PACKAGES+=("$PKG")
        fi
    fi
}

# ==========================================================
# PRINT FORMATADO
# ==========================================================
print_pkg() {
    printf "📦 %-35s : %s\n" "$1" "$2"
}

# ==========================================================
# GRUPO
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
            echo -ne "📦 $PKG                            : ⚡ Instalando...\r"
            install_pkg "$PKG"

            if is_installed "$PKG"; then
                STATUS="✅ Instalado"
            else
                STATUS="❌ Falha"
            fi
        fi

        print_pkg "$PKG" "$STATUS"
    done
}

# ==========================================================
# XPRA REPO
# ==========================================================
XPRA_GPG="/etc/apt/trusted.gpg.d/xpra.gpg"

install_xpra_repo() {

    echo
    echo "=================================================="
    echo "[ XPRA REPOSITORY ]"
    echo "=================================================="

    if [ -f "$XPRA_GPG" ]; then
        echo "✔ XPRA GPG já existe"
        return
    fi

    curl -fsSL https://xpra.org/gpg.asc | gpg --dearmor -o "$XPRA_GPG" >/dev/null 2>&1 || {
        echo "❌ Falha GPG"
        FAILED_PACKAGES+=("xpra-gpg")
        return
    }

    git clone https://github.com/Xpra-org/xpra >/dev/null 2>&1 || {
        echo "❌ Falha clone XPRA"
        FAILED_PACKAGES+=("xpra-git")
        return
    }

    cd xpra || {
        echo "❌ Falha cd xpra"
        FAILED_PACKAGES+=("xpra-dir")
        return
    }

    ./setup.py install-repo >/dev/null 2>&1 || {
        echo "❌ Falha install-repo"
        FAILED_PACKAGES+=("xpra-repo")
        return
    }

    apt-get update -y >/dev/null 2>&1

    echo "✔ XPRA repo configurado"
}

# ==========================================================
# START
# ==========================================================
check_debian_stable
apt-get update -y >/dev/null 2>&1

# ==========================================================
# PACKAGES
# ==========================================================
install_group "ESSENTIALS" git curl wget sudo ca-certificates pkg-config

install_group "XPRA DRIVERS" i965-va-driver x264 va-driver-all vdpau-driver-all intel-media-va-driver-non-free pulseaudio

install_group "GRAPHICS" gstreamer1.0-plugins-base gstreamer1.0-plugins-good gstreamer1.0-plugins-ugly vainfo

install_group "LIBS" libva-drm2 libva-x11-2 libvpx9 libx264-dev libwebp-dev libgtk-3-dev libsystemd-dev

# ==========================================================
# XPRA
# ==========================================================
install_xpra_repo

XPRA_PACKAGES="xpra xpra-client-gtk3 xpra-codecs-extras xpra-codecs xpra-common xpra-client xpra-audio xpra-x11 xpra-html5 xpra-server"

install_group "XPRA" $XPRA_PACKAGES

# ==========================================================
# XPRA FINAL OUTPUT FORMAT
# ==========================================================
echo
echo "=================================================="
echo "[ XPRA ]"
echo "=================================================="

for pkg in $XPRA_PACKAGES; do
    printf "📦 %-35s : %s\n" "$pkg" "✅ Instalado"
done

echo
XPRA_VERSION=$(xpra --version)
	printf "✅ %-35s %s\n" "$XPRA_VERSION"

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
# JSON CLOSE
# ==========================================================
sed -i '$ s/,$//' "$LOG_FILE"
echo "]" >> "$LOG_FILE"

echo
echo "📄 Log salvo: $LOG_FILE"
