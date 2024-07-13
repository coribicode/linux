echo "deb http://packages.openmediavault.org/public kralizec" main >> /etc/apt/sources.list.d/openmediavault.list

apt update && apt upgrade

apt install openmediavault-keyring postfix -y

apt install openmediavault -y

