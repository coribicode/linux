#!/bin/bash
modprobe bonding

# Inicializa um contador para as variáveis
count=0
# Identifica as interfaces de rede que estão UP e as configura como variáveis INTERFACE0, INTERFACE1, etc.
for iface in $(ip link show | awk '/state UP/ {print $2}' | sed 's/:$//'); do
    # Incrementa o contador
    count=$((count + 1))
    
    # Cria a variável dinamicamente com o nome ethX e atribui o nome da interface
    eval "INTERFACE$count='$iface'"
done

# Exibe as variáveis configuradas
echo "Interfaces UP configuradas em variáveis:"
for i in $(seq 1 $count); do
    eval "echo INTERFACE$i=\${INTERFACE$i}"
done

## ChatGPT "codigo unico para identificar as placas de rede que estao UP no linux debian e configurar em variaveis eth0, eth1... assim por diante"

# Defina as interfaces de rede a serem unificadas
BOND_INTERFACE="bond0"

# Instalar o pacote ifenslave (caso não esteja instalado)
if ! dpkg -l | grep -qw ifenslave; then
    echo "Instalando ifenslave..."
    sudo apt update
    sudo apt install -y ifenslave
fi
# Instalar ethtool (caso não esteja instalado)
if ! dpkg -l | grep -qw ethtool; then
    echo "Instalando ethtool..."
    sudo apt install -y ethtool
fi

# Backup da configuração no arquivo /etc/network/interfaces
cp /etc/network/interfaces /etc/network/interfaces.bkp

# Criando a configuração no arquivo /etc/network/interfaces
echo "Configurando /etc/network/interfaces para bonding no modo RLB (Balance-ALB)..."

cat <<EOF | sudo tee /etc/network/interfaces > /dev/null
# Configuração do Bonding - $BOND_INTERFACE
auto $BOND_INTERFACE
iface $BOND_INTERFACE inet dhcp
    bond-mode 6
    bond-miimon 100
    bond-updelay 200
    bond-downdelay 200
    bond-slaves $INTERFACE1 $INTERFACE2

# Configuração das interfaces físicas
iface $INTERFACE1 inet manual
iface $INTERFACE2 inet manual
EOF

ifdown $INTERFACE1
ifdown $INTERFACE2
ifup $BOND_INTERFACE

# Reiniciar o serviço de rede para aplicar as configurações
echo "Reiniciando a rede..."
sudo systemctl restart networking

# Verificando o estado do bonding
echo "Verificando o estado do bonding..."
cat /proc/net/bonding/$BOND_INTERFACE

lsmod | grep bond
ethtool $BOND_INTERFACE

## ChatGPT "codigo unico para unificar duas placas de rede no linux debian  em RLB"
## https://www.server-world.info/en/note?os=Debian_12&p=bonding&f=1
## https://www.baeldung.com/linux/ethernet-dual-cards-increase-throughput
