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
apt install -y bridge-utils ifupdown > /dev/null
echo
echo "Configuração do bridge $BRIDGE_NAME no arquivo /etc/network/interfaces"
# Criar backup do arquivo de configuração de rede
cp /etc/network/interfaces /etc/network/interfaces.bak
cat >> /etc/network/interfaces << EOF
# Interface loopback
auto lo
iface lo inet loopback

# Configuração da interface física para o bridge
auto $PHYSICAL_INTERFACE
iface $PHYSICAL_INTERFACE inet manual
    up ip link set dev $PHYSICAL_INTERFACE up
    down ip link set dev $PHYSICAL_INTERFACE down

# Configuração do bridge
auto $BRIDGE_NAME
iface $BRIDGE_NAME inet dhcp
    bridge_ports $PHYSICAL_INTERFACE
    bridge_fd 0
    bridge_maxwait 0
EOF
cat /etc/network/interfaces 
echo "-------------------------------------------------"
echo "Reiniciar a rede para aplicar as configurações."
systemctl restart networking
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
