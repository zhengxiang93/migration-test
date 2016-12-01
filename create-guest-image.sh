#!/bin/bash

# Written to be called from migration-test.sh

PROGNAME=create-guest-image.sh
NAME="$1"
IMAGE="$NAME.qcow2"
SIZE=2G

function error_exit
{
	#	----------------------------------------------------------------
	#	Function for exit due to fatal program error
	#		Accepts 1 argument:
	#			string containing descriptive error message
	#	----------------------------------------------------------------

	echo "${PROGNAME}: ${1:-"Unknown Error"}" 1>&2
		exit 2
}

if [[ -z "$NAME" ]]; then
	error_exit "usage: $0 <vm fs name>"
fi

declare -a tools=("debootstrap" "expect" "qemu-img" "qemu-nbd" "parted" "kpartx" "mkfs.ext4")
for tool in "${tools[@]}"
do
	if ! tool_loc="$(type -p "$tool")" || [ -z "$tool_loc" ]; then
		  error_exit "$tool is required, please install, aborting"
	fi
done

# Test if we can mount images
if [[ ! -e /dev/nbd0 ]]; then
	error_exit "cannot find /dev/nbd0; do you have CONFIG_BLK_DEV_NBD?"
elif [[ ! -e /sys/class/misc/device-mapper/ ]]; then
	error_exit "cannot find /sys/class/misc/device-mapper/; do you have CONFIG_BLK_DEV_DM?"
fi

if [[ -e "$IMAGE" ]]; then
	error_exit "$IMAGE already exists.  Did you mean to clean up and start from scratch?"
fi

if [[ ! -d "$NAME" ]]; then
	echo "Debootstapping a debian directory for you..."
	debootstrap --arch arm64 sid `pwd`/"$NAME" http://ftp.debian.org/debian ||
		error_exit "debootstrap failed"
	echo "root:kvm" | sudo chpasswd --root `pwd`/"$NAME"
fi

echo "Creating image file for VM..."
qemu-img create -f qcow2 -o preallocation=metadata "$IMAGE" $SIZE ||
	error_exit "qemu-img create failed"

###
# Parition, format, and populate image file
###
sudo qemu-nbd --connect=/dev/nbd0 "$IMAGE" || error_exit "failed to mount qcow2 image, aborting"
sudo parted -s -a optimal /dev/nbd0 mklabel gpt -- mkpart primary ext4 1 -1 ||
	error_exit "partitioning failed, please cleanup manually"
sudo kpartx -a /dev/nbd0
sudo mkfs.ext4 /dev/mapper/nbd0p1

mkdir -p tmp-mount
sudo mount /dev/mapper/nbd0p1 tmp-mount
echo "Image file created and formatted, copying FS into image..."
sudo cp -a "$NAME"/* tmp-mount/.
echo "Copy complete, clearning up"
sudo umount tmp-mount
rmdir tmp-mount

sudo kpartx -d /dev/nbd0
sudo qemu-nbd -d /dev/nbd0
