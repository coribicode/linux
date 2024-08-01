apt install -y sudo curl wget gnupg ca-certificates 2>&1 | grep "E:"

ID=openmediavault
CODENAME=sandworm
URIS=http://packages.openmediavault.org/public
PACKAGES='openmediavault openvswitch-switch'
URI_KEY=$URIS/archive.key
COMPONENTS=$(curl -fsSL $URIS/dists/$CODENAME/Release | grep Components | cut -d ':' -f 2) 
PATH_FILE_SIGNED=/usr/share/keyrings/$ID-archive-keyring.gpg
PATH_FILE_SOURCE=/etc/apt/sources.list.d/$ID-sources.list

NIC=$(ip -br -4 a | grep UP | cut -d ' ' -f 1)
IP=$(hostname -I | cut -d ' ' -f 1)

export LANG=C.UTF-8
export DEBIAN_FRONTEND=noninteractive
export APT_LISTCHANGES_FRONTEND=none

cat > repo << EOF
#!/bin/bash
if [ ! -e $PATH_FILE_SOURCE ];
  then
  echo
  echo "[ Repositório $ID ]: Configurando ..."

cat > $PATH_FILE_SOURCE << EOL
deb [signed-by=$PATH_FILE_SIGNED] $URIS $CODENAME $COMPONENTS
EOL

wget --quiet --output-document=- $URI_KEY | gpg --dearmor --yes --output $PATH_FILE_SIGNED > /dev/null
sleep 2

  echo "[ Repositório $ID ]: OK!"
fi
EOF
sleep 2

curl -LO https://raw.githubusercontent.com/davigalucio/linux/main/install.sh 2>&1 | grep "E:"
INSTALLER="install.sh"

echo
echo "[ OpenMediaVault ]: Instalando ..."
echo
echo "[ Instalação de Pacotes ]"
if grep PACKAGE_NAME $INSTALLER > /dev/null
  then
    sed -i "s|PACKAGE_NAME|$PACKAGES|g" $INSTALLER
    sh $INSTALLER
  else
    sh $INSTALLER
fi
echo "[ Instalação de Pacotes ]: OK!"
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
