sudo cp /home/ipub/vm_build/cumulus-linux-4.1.1-vx-amd64-qemu.qcow2 /var/lib/libvirt/images/${1}.qcow2

sudo virt-install \
--name=${1}  \
--description "${1} VM" \
--os-type=generic \
--ram=1024 \
--vcpus=1 \
--boot hd,cdrom,menu=on \
--disk path=/var/lib/libvirt/images/${1}.qcow2,bus=ide,size=4 \
--import \
--serial tcp,host=0.0.0.0:2223,mode=bind,protocol=telnet \
--network=bridge:br0,mac=52:54:00:23:03:00,model=virtio \
--network=bridge:br15,mac=52:54:00:23:03:01,model=virtio \
--network=bridge:br12,mac=52:54:00:23:03:02,model=virtio \
--network=bridge:br14,mac=52:54:00:23:03:03,model=virtio \
--wait 0