sudo apt install -y cpu-checker
sudo kvm-ok

sudo apt-get install -y qemu-kvm qemu-user-static qemu-utils bridge-utils dnsmasq virt-manager libvirt-clients libvirt-daemon-system libguestfs-tools libosinfo-bin ovmf
sudo systemctl start libvirtd
sudo systemctl enable libvirtd

sudo usermod -a -G libvirt $USER

sudo sed -i 's|#uri_default = "qemu:///system"|uri_default = "qemu:///system"|g' /etc/libvirt/libvirt.conf

virsh --connect=qemu:///system net-autostart default

sudo modprobe vhost_net
cat <<"EOF">> /etc/modules
vhost_net
vfio
vfio_iommu_type1
vfio_pci
vfio_virqfd
EOF

sudo sed -i 's|GRUB_CMDLINE_LINUX_DEFAULT="quiet"|GRUB_CMDLINE_LINUX_DEFAULT="intel_iommu=on iommu=pt"|g' /etc/default/grub

sudo grub-mkconfig -o /boot/grub/grub.cfg

sudo update-initramfs -c -k $(uname -r)

###################################################################################
## Teste IOMMU support pelo Windows via powershell
## (Get-VMHost).IovSupport; (Get-VMHost).IovSupportReasons
## get-vmswitch | fl *iov*
## Get-VM | Format-List -Property *

## https://www.youtube.com/watch?v=g--fe8_kEcw

## cat <<'EOF'>> /etc/modprobe.d/vfio.conf
## options vfio-pci ids=10de:1f99,10de:10fa
## softdep nvidia pre: vfio-pci
## EOF

## lspci -k | grep -E "vfio-pci|NVIDIA"

## wget -P /opt/ https://fedorapeople.org/groups/virt/virtio-win/direct-downloads/stable-virtio/virtio-win.iso
