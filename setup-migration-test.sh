#!/bin/bash

PROGNAME=migration-test.sh

function error_exit
{
	#	----------------------------------------------------------------
	#	Function for exit due to fatal program error
	#		Accepts 1 argument:
	#			string containing descriptive error message
	#	----------------------------------------------------------------

	echo "${PROGNAME}: ${1:-"Unknown Error"}" 1>&2
		exit 1
}

# Check we have the tools we need
declare -a tools=("expect")
for tool in "${tools[@]}"
do
	if ! tool_loc="$(type -p "$tool")" || [ -z "$tool_loc" ]; then
		  error_exit "$tool is required, please install, aborting"
	fi
done

# Let's make sure we have a guest file system
if [[ ! -e debian-sid.qcow2 ]]; then
	./create-guest-image.sh debian-sid || exit $?
fi

# Let's make sure we have a guest kernel
if [[ ! -e Image ]]; then
	read -p "No guest kernel Image detected. I can build one for you. Proceed? [Y/n]" -n 1 -r
	if [[ ! $REPLY =~ ^[Nn]$ ]]; then
		error_exit "No guest kernel, please put one here and name it Image"
	fi
	./create-guest-kernel.sh || exit $?
fi

# Let's make sure we have a QEMU version for you
if [[ ! -e qemu-system-aarch64 ]]; then
	read -p "No qemu binary detected. I can build one for you. Proceed? [Y/n]" -n 1 -r
	if [[ ! $REPLY =~ ^[Nn]$ ]]; then
		error_exit "No qemu binary, please put one here and name it qemu-system-aarch64"
	fi
	./build-qemu.sh || exit $?
fi

echo "Migration test ready"
