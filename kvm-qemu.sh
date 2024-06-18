sudo apt install -y cpu-checker
sudo kvm-ok

sudo apt-get install -y qemu-kvm qemu-user-static bridge-utils dnsmasq virt-manager libvirt-clients libvirt-daemon-system libguestfs-tools libosinfo-bin
sudo systemctl start libvirtd
sudo systemctl enable libvirtd

sudo usermod -a -G libvirt $USER

sudo sed -i 's|#uri_default = "qemu:///system"|uri_default = "qemu:///system"|g' /etc/libvirt/libvirt.conf

virsh --connect=qemu:///system net-autostart default

sudo modprobe vhost_net
echo vhost_net | sudo tee -a /etc/modules
