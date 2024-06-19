#https://www.youtube.com/watch?v=g--fe8_kEcw

sudo apt install -y cpu-checker
sudo kvm-ok

sudo apt-get install -y qemu-kvm qemu-user-static qemu-utils bridge-utils dnsmasq virt-manager libvirt-clients libvirt-daemon-system libguestfs-tools libosinfo-bin ovmf
sudo systemctl start libvirtd
sudo systemctl enable libvirtd

sudo usermod -a -G libvirt $USER

sudo sed -i 's|#uri_default = "qemu:///system"|uri_default = "qemu:///system"|g' /etc/libvirt/libvirt.conf

virsh --connect=qemu:///system net-autostart default

sudo modprobe vhost_net
echo vhost_net | sudo tee -a /etc/modules


sudo sed -i 's|GRUB_CMDLINE_LINUX_DEFAULT="quiet"|GRUB_CMDLINE_LINUX_DEFAULT="intel_iommu=on iommu=pt vfio-pci.ids=10de:1f99,10de:10fa"|g' /etc/default/grub

sudo grub-mkconfig -o /boot/grub/grub.cfg

sudo reboot

cat 'EOF' >> /etc/modprobe.d/vfio.conf
options vfio-pci ids=10de:1f99,10de:10fa
softdep nvidia pre: vfio-pci
EOF

sudo update-initramfs -c -k $(uname -r)

sudo reboot

lspci -k | grep -E "vfio-pci|NVIDIA"

wget -P /opt/ https://fedorapeople.org/groups/virt/virtio-win/direct-downloads/stable-virtio/virtio-win.iso
