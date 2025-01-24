#!/bin/bash
# Verificar se o script está rodando como root
if [ "$(id -u)" -ne 0 ]; then
    echo "Este script precisa ser executado como root."
    exit 1
fi
# Variáveis
BRIDGE_NAME=br0
PHYSICAL_INTERFACE=$(ip -4 a | grep $(hostname -I | cut -d ' ' -f 1) | grep -o '[^ ]*$')   # Nome da interface de rede física, ajuste conforme sua configuração

echo "Instalando pacotes necessários .."
apt-get install -y bridge-utils ifupdown > /dev/null
echo
if [ -e /etc/network/interfaces.d/$BRIDGE_NAME ] > /dev/null
then
echo "[ $PHYSICAL_INTERFACE já configurado para $BRIDGE_NAME! ]"
else
echo "Configuração do bridge $BRIDGE_NAME no arquivo /etc/network/interfaces"
sleep 5
# Criar backup do arquivo de configuração de rede
# cp /etc/network/interfaces /etc/network/interfaces.$PHYSICAL_INTERFACE.bkp

sed -i 's/^/#/' /etc/network/interfaces.d/$PHYSICAL_INTERFACE
cat >> /etc/network/interfaces.d/$PHYSICAL_INTERFACE << EOF
auto $PHYSICAL_INTERFACE
iface $PHYSICAL_INTERFACE inet manual
EOF

# Configuração da interface física para o bridge $BRIDGE_NAME
#auto $PHYSICAL_INTERFACE
#iface $PHYSICAL_INTERFACE inet manual
#up ip link set dev $PHYSICAL_INTERFACE up
#down ip link set dev $PHYSICAL_INTERFACE down
# -----------------------------------------------------
cat >> /etc/network/interfaces.d/$BRIDGE_NAME << EOF
auto $BRIDGE_NAME
iface $BRIDGE_NAME inet dhcp
bridge_ports $PHYSICAL_INTERFACE
bridge_fd 0
bridge_maxwait 0
bridge_stp on
EOF
fi
echo "-------------------------------------------------"
echo "Reiniciar a rede para aplicar as configurações."
systemctl restart networking
systemctl restart NetworkManager
echo "-------------------------------------------------"
echo "Verificar se o bridge $BRIDGE_NAME foi criado com sucesso"
brctl show
echo "-------------------------------------------------"
echo "Download dos drives do VirtIO para Windows na pasta /opt/ISO"
mkdir /opt/ISO
wget -P /opt/ISO https://fedorapeople.org/groups/virt/virtio-win/direct-downloads/archive-virtio/virtio-win-0.1.266-1/virtio-win.iso
echo
ls /opt/ISO
echo "-------------------------------------------------"
echo "Para dispositivos VIRTIO, insira esta ISO na unidade de CD-ROM e instale os drivers nas VMs Windows (Se necessário)"
