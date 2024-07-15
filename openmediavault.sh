apt_dist='openmediavault'

keyring_gpg_path="/usr/share/keyrings/"$apt_dist"-archive-keyring.gpg"

key_uri='https://packages.openmediavault.org/public/archive.key'

ip=$(hostname -I | cut -d ' ' -f 1)

cat <<"EOL">> /opt/$apt_dist.list
deb [signed-by=keyring_gpg_path] http://packages.openmediavault.org/public/ sandworm main
deb [signed-by=keyring_gpg_path] https://openmediavault.github.io/packages/ sandworm main
EOL

cat "/opt/$apt_dist.list" >> /etc/apt/sources.list.d/$apt_dist.list

sed -i "s|keyring_gpg_path|$keyring_gpg_path|g" /etc/apt/sources.list.d/$apt_dist.list

cp /etc/network/interfaces /etc/network/interfaces.bkp

cp /etc/resolv.conf /etc/resolv.conf.bkp

apt-get install -y wget gnupg sudo systemd-timesyncd ca-certificates

wget --quiet --output-document=- $key_uri | gpg --dearmor --yes --output "$keyring_gpg_path"

## Lista as KEY
dpkg -l | grep keyring

apt update && apt upgrade -y

sudo systemctl restart systemd-networkd.service
sudo systemctl status systemd-networkd.service


sudo systemctl restart networking.service
sudo systemctl status networking.service

mac=$(ip add | grep link/ether | awk '{print $2}')


mkdir /run/systemd/network

cat <<"EOF">> /run/systemd/network/10-netplan-eth0.network
[Match]
PermanentMACAddress=mac

[Network]
DHCP=ipv4
LinkLocalAddressing=no

[DHCP]
RouteMetric=100
UseMTU=true
UseDomains=true
EOF

sed -i "s|mac|$mac|g" /run/systemd/network/10-netplan-eth0.network

networkctl

export LANG=C.UTF-8
export DEBIAN_FRONTEND=noninteractive
export APT_LISTCHANGES_FRONTEND=none
apt-get update
apt-get --yes --auto-remove --show-upgraded \
    --allow-downgrades --allow-change-held-packages \
    --no-install-recommends \
    --option DPkg::Options::="--force-confdef" \
    --option DPkg::Options::="--force-confold" \
    install openmediavault

cp /etc/netplan/10-openmediavault-default.yaml /etc/netplan/10-openmediavault-default.yaml.bkp

cat <<"EOF">> /etc/netplan/10-openmediavault-default.yaml
    ethernets:
        eth0:
        dhcp4:true
EOF

sudo netplan apply


cp /etc/network/interfaces.bkp /etc/network/interfaces

cp /etc/resolv.conf.bkp /etc/resolv.conf


/etc/init.d/networking restart


sudo omv-salt deploy run systemd-networkd

echo
echo "Buscando as últimas atualizações do OpenMediaVault..."
echo
apt --only-upgrade install openmediavault
sudo omv-upgrade
echo

echo
echo "Instalando pacotes essencias do OpenMediaVault..."
echo
apt install -y \
openmediavault-apt \
openmediavault-clamav \
openmediavault-diskstats \
openmediavault-filebrowser \
openmediavault-ftp \
openmediavault-photoprism \
openmediavault-snmp \
openmediavault-usbbackup \
openmediavault-wetty
echo

echo
echo "Acesse http://$ip"
echo
echo "Login: admin"
echo "Senha: openmediavault"
echo
