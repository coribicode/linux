apt_dist=openmediavault
keyring_gpg_path=/usr/share/keyrings/$apt_dist-archive-keyring.gpg
key_uri='https://packages.openmediavault.org/public/archive.key'

## Prioridade IPV4 ##
echo "precedence ::ffff:0:0/96  100" >> /etc/gai.conf

echo "[OpenMediaVault]: Instalando dependências..."
apt-get install -y wget gnupg sudo systemd-timesyncd ca-certificates 2>&1
echo "[OpenMediaVault]: Verificando repositórios ..."

FILE=/etc/apt/sources.list.d/$apt_dist.list
if [ -e $FILE ]
  then
    echo "[OpenMediaVault]: Repositórios OK!"
  else
    echo "[OpenMediaVault]: Atualizando repositórios ..."
cat > $FILE << EOF
deb [signed-by=$keyring_gpg_path] http://packages.openmediavault.org/public/ sandworm main
deb [signed-by=$keyring_gpg_path] https://openmediavault.github.io/packages/ sandworm main
EOF
wget --quiet --output-document=- $key_uri | gpg --dearmor --yes --output "$keyring_gpg_path" 2>&1
    echo "[OpenMediaVault]: Repositórios - OK!"
fi

systemctl daemon-reload
apt update 2>&1
apt upgrade -y 2>&1
systemctl daemon-reload

echo "[OpenMediaVault]: Instalando OpenMediaVault ..."
export LANG=C.UTF-8
export DEBIAN_FRONTEND=noninteractive
export APT_LISTCHANGES_FRONTEND=none
apt-get --yes --auto-remove --show-upgraded \
    --allow-downgrades --allow-change-held-packages \
    --no-install-recommends \
    --option DPkg::Options::="--force-confdef" \
    --option DPkg::Options::="--force-confold" \
    install openmediavault openvswitch-switch 2>&1

sleep 2
echo "[OpenMediaVault]: Reconfigurando Conexão de Rede ..."
NIC=$(ip -br -4 a | grep UP | cut -d ' ' -f 1)

cat >> /etc/netplan/*openmediavault*.yaml << "EOF"
ethernets:
  $NIC:
    dhcp4: true
EOF

sudo netplan apply
echo "[OpenMediaVault]: Conexão de Rede - OK!"
echo
echo "Acesse http://$(hostname -I | cut -d ' ' -f 1)"
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
