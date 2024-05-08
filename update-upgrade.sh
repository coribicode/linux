DEBIAN_VERSION_CODENAME=$(cat /etc/*release* | grep VERSION_CODENAME | cut -d '=' -f 2)

mv /etc/apt/sources.list /etc/apt/sources.list.bkp

cat <<EOF>> /etc/apt/sources.list.d/debian.sources
Types: deb deb-src
URIs: http://deb.debian.org/debian 
Suites: $DEBIAN_VERSION_CODENAME $DEBIAN_VERSION_CODENAME-updates $DEBIAN_VERSION_CODENAME-backports
Components: main contrib non-free non-free-firmware
Signed-By: /usr/share/keyrings/debian-archive-keyring.gpg

Types: deb deb-src
URIs: http://deb.debian.org/debian-security
Suites: $DEBIAN_VERSION_CODENAME-security
Components: main contrib non-free non-free-firmware
Signed-By: /usr/share/keyrings/debian-archive-keyring.gpg
EOF

apt update && apt upgrade -y && systemctl daemon-reload

