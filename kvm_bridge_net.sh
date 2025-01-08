#!/bin/bash
# Variáveis
BRIDGE_NAME=br0
PHYSICAL_INTERFACE=$(ip -4 a | grep $(hostname -I | cut -d ' ' -f 1) | grep -o '[^ ]*$')   # Nome da interface de rede física, ajuste conforme sua configuração

# Verificar se o script está rodando como root
if [ "$(id -u)" -ne 0 ]; then
    echo "Este script precisa ser executado como root."
    exit 1
fi

# Instalar pacotes necessários
apt update
apt install -y bridge-utils ifupdown

# Criar backup do arquivo de configuração de rede
cp /etc/network/interfaces /etc/network/interfaces.bak

# Configuração do bridge no arquivo /etc/network/interfaces
echo "Configurando o bridge $BRIDGE_NAME..."

cat <<EOF > /etc/network/interfaces
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

# Reiniciar a rede para aplicar as configurações
echo "Reiniciando a rede..."
systemctl restart networking

# Verificar se o bridge foi criado com sucesso
brctl show

echo "Bridge $BRIDGE_NAME configurado com sucesso!"

wget https://fedorapeople.org/groups/virt/virtio-win/direct-downloads/archive-virtio/virtio-win-0.1.266-1/virtio-win.iso

echo "Foi realizado o download dos drives do VirtIO para Windows na pasta $USER"
echo "Anexe na unidade de CD-ROM e instale os drivers de rede no Windows"
