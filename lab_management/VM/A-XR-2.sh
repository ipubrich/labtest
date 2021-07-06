sudo cp /home/ipub/vm_build/iosxrv-demo-6.5.1.qcow2 /var/lib/libvirt/images/${1}.qcow2

sudo virt-install \
--name=${1} \
--description "${1} VM" \
--os-type=generic \
--ram=3072 \
--vcpus=1 \
--boot hd,cdrom,menu=on \
--disk path=/var/lib/libvirt/images/${1}.qcow2,bus=ide,size=4 \
--import \
--graphic vnc \
--serial tcp,host=0.0.0.0:2222,mode=bind,protocol=telnet \
--network=bridge:br0,mac=52:54:00:22:01:00,model=virtio \
--network=bridge:br11,mac=52:54:00:22:01:01,model=virtio \
--network=bridge:br12,mac=52:54:00:22:01:02,model=virtio \
--network=bridge:br13,mac=52:54:00:22:01:03,model=virtio \
--wait 0