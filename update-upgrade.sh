VERSION_CODENAME=$(cat /etc/*release* | grep ^VERSION_CODENAME | cut -d '=' -f 2)
ID=$(cat /etc/*release* | grep ^ID | cut -d '=' -f2)

TYPES='deb deb-src'
URIS='http://deb.debian.org/debian'
URIS_SEC='http://deb.debian.org/debian-security'
SUITES="$VERSION_CODENAME $VERSION_CODENAME-updates $VERSION_CODENAME-backports"
COMPONENTES='main contrib non-free non-free-firmware'
SIGNED='/usr/share/keyrings/debian-archive-keyring.gpg'
PATH_SOURCE="/etc/apt/sources.list.d/$ID.sources"

mv /etc/apt/sources.list /etc/apt/sources.list.bkp

cat <<EOF>> $PATH_SOURCE 
Types: $TYPES
URIs: $URIS
Suites: $SUITES
Components: $COMPONENTES
Signed-By: $SIGNED

Types: $TYPES
URIs: $URIS_SEC
Suites: $VERSION_CODENAME-security
Components: $COMPONENTES
Signed-By: $SIGNED
EOF

apt update && apt upgrade -y && systemctl daemon-reload

