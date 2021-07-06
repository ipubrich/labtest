sudo cp /home/ipub/vm_build/Aboot-veos-8.0.0.iso /tmp/${1}-Aboot-veos-8.0.0.iso
sudo cp /home/ipub/vm_build/vEOS-lab-4.2.qcow2 /var/lib/libvirt/images/${1}.qcow2

sudo virt-install \
--name=${1} \
--description "${1} VM" \
--os-type=generic \
--ram=2048 \
--vcpus=2 \
--boot cdrom,hd,menu=on \
--cdrom /tmp/${1}-Aboot-veos-8.0.0.iso \
--livecd \
--graphics vnc \
--disk path=/var/lib/libvirt/images/${1}.qcow2,bus=ide,size=4 \
--serial tcp,host=0.0.0.0:2224,mode=bind,protocol=telnet \
--network=bridge:br0,mac=52:54:00:24:01:00,model=virtio \
--network=bridge:br13,mac=52:54:00:24:01:01,model=virtio \
--network=bridge:br14,mac=52:54:00:24:01:03,model=virtio \
--wait 0