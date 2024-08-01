NIC=$(ip -br -4 a | grep UP | cut -d ' ' -f 1)
IP=$(hostname -I | cut -d ' ' -f 1)

## Prioridade IPV4 ##
echo "precedence ::ffff:0:0/96  100" >> /etc/gai.conf

echo
echo "[ Dependências ]: Instalando ..."
apt-get install -y wget gnupg sudo systemd-timesyncd ca-certificates > /dev/null
echo "[ Dependências ]: OK!"
sleep 2

cat > repo << 'EOF'
#!/bin/bash
apt install -y curl

ID=openmediavault
CODENAME=sandworm
URIS=http://packages.openmediavault.org/public
URI_KEY=$URIS/archive.key

COMPONENTS=$(curl -fsSL $URIS/dists/$CODENAME/Release | grep Components | cut -d ':' -f 2) 

PATH_FILE_SIGNED=/usr/share/keyrings/$ID-archive-keyring.gpg
PATH_FILE_SOURCE=/etc/apt/sources.list.d/$ID-sources.list

if [ ! -e $PATH_FILE_SOURCE ];
  then
  echo
  echo "[ Repositório ]: Configurando ..."

cat > $PATH_FILE_SOURCE << EOL
deb [signed-by=$PATH_FILE_SIGNED] $URIS $CODENAME $COMPONENTS
EOL

wget --quiet --output-document=- $URI_KEY | gpg --dearmor --yes --output $PATH_FILE_SIGNED > /dev/null
sleep 2

  echo "[ Repositório ]: OK!"
  echo
  echo "[ Repositório ]: Atualizando..."
  apt update -qq 2>&1 | grep "E:"
  apt upgrade -qqy 2>&1 | grep "E:"
  systemctl daemon-reload 2>&1 | grep "E:"
  apt --fix-broken -qq install 2>&1 | grep "E:"
  echo "[ Repositório ]: OK!"
  echo
fi
sleep 2
EOF



echo
echo "[ OpenMediaVault ]: Instalando OpenMediaVault ..."
export LANG=C.UTF-8
export DEBIAN_FRONTEND=noninteractive
export APT_LISTCHANGES_FRONTEND=none
apt-get --yes --auto-remove --show-upgraded \
    --allow-downgrades --allow-change-held-packages \
    --no-install-recommends \
    --option DPkg::Options::="--force-confdef" \
    --option DPkg::Options::="--force-confold" \
    install openmediavault openvswitch-switch 2>&1 | grep "E:"
sleep 2

echo "[ OpenMediaVault ]: Reconfigurando Conexão de Rede ..."
sudo omv-salt deploy run systemd-networkd 2>&1 | grep "Ey:"
sleep 2

cat >> /etc/netplan/10-openmediavault-default.yaml << EOF
  ethernets:
    $NIC:
      dhcp4: true
EOF
sudo netplan apply 2>&1
echo "[ OpenMediaVault ]: Conexão de Rede - OK!"
sleep 2

echo
echo "[ OpenMediaVault ]: Instalação Concluída!"
echo
echo "Acesse http://$IP"
echo
echo "Login: admin"
echo "Senha: openmediavault"
echo

#echo
#echo "Buscando as últimas atualizações do OpenMediaVault..."
#echo
#sudo apt --only-upgrade install openmediavault
#sudo omv-upgrade
#echo
