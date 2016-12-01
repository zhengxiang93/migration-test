#!/bin/bash

# Takes the QEMU binary as the argument

DISK=debian-sid.qcow2

./qemu-migrate-file.expect \
	qemu-system-aarch64 \
	-smp 4 -m 4096 \
	-machine virt -cpu host -enable-kvm \
	-device virtio-blk-pci,drive=vda \
	-netdev user,id=net0 \
	-device virtio-net-pci,netdev=net0 \
	-nographic \
	-kernel Image \
	-drive if=none,file=$DISK,id=vda,format=qcow2,cache=none \
	-append "console=ttyAMA0 root=/dev/vda1 rw"
