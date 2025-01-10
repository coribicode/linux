#!/bin/bash
modprobe bonding

if grep ^'bonding' /etc/modules > /dev/null
then
echo "[ Modules BONDING ]: OK!"
else
echo "[ Modules BONDING ]: Configurando ... "
echo "bonding" >> /etc/modules
sleep 2
echo "----------------------------------"
lsmod | grep bond
echo "----------------------------------"
echo "[ Modules BONDING ]: OK!"
fi

# Inicializa um contador para as variáveis
count=0
# Identifica as interfaces de rede que estão UP e as configura como variáveis INTERFACE0, INTERFACE1, etc.
for iface in $(ip link show | awk '/state UP/ {print $2}' | sed 's/:$//'); do
    # Incrementa o contador
    count=$((count + 1))
    
    # Cria a variável dinamicamente com o nome INTERFACEX e atribui o nome da interface
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
BOND_MODE="balance-alb"

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

if grep $BOND_INTERFACE /etc/network/interfaces > /dev/null
then
echo "[ Interface $BOND_INTERFACE ]: Já existe uma configuração $BOND_INTERFACE em /etc/network/interfaces."
else
echo "[ Interface $BOND_INTERFACE ]: Configurando $BOND_INTERFACE em $BOND_MODE... "
# Backup da configuração no arquivo /etc/network/interfaces
cp /etc/network/interfaces /etc/network/interfaces.bkp

cat >> EOF | sudo tee /etc/network/interfaces > /dev/null
# Configuração do Bonding - $BOND_INTERFACE
auto $BOND_INTERFACE
iface $BOND_INTERFACE inet dhcp
    bond-mode $BOND_MODE
    bond-miimon 100
    bond-updelay 200
    bond-downdelay 200
    bond-primary $INTERFACE1 $INTERFACE2    
    bond-slaves $INTERFACE1 $INTERFACE2
 
# Configuração das interfaces físicas
iface $INTERFACE1 inet manual
    bond-master $BOND_INTERFACE
    bond-mode $BOND_MODE
iface $INTERFACE2 inet manual
    bond-master $BOND_INTERFACE
    bond-mode $BOND_MODE
EOF

ifdown $INTERFACE1
ifdown $INTERFACE2
ifup $BOND_INTERFACE

# Reiniciar o serviço de rede para aplicar as configurações
echo "Reiniciando a rede..."
sudo systemctl restart networking
sleep 2
echo "[ Interface $BOND_INTERFACE ]: OK!"
fi
sleep 2
echo
# Verificando o estado do bonding
echo "Verificando o estado do bonding..."
echo "----------------------------------"
cat /proc/net/bonding/$BOND_INTERFACE
echo "----------------------------------"
ethtool $BOND_INTERFACE
echo "----------------------------------"
lsmod | grep bond

## ChatGPT "codigo unico para unificar duas placas de rede no linux debian  em RLB"
## https://www.server-world.info/en/note?os=Debian_12&p=bonding&f=1
## https://www.baeldung.com/linux/ethernet-dual-cards-increase-throughput
