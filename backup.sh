#!/bin/bash

copy_contents() {
	cd "$mountpoint"
	tar -cvX "$actual/exclude.txt" . | pigz > "$actual/$partition.tar.gz"
	cd "$actual"
	umount "$mountpoint"
}

copy_as_raw() {
	dd if="/dev/$partition" bs=20M status=progress | pigz > "$actual/$partition.dd.gz"
}

DISK=$1

if [[ -z "$DISK" ]];  then
	echo "Define your block device as an argument"
	exit 1;
fi;

if [[ "$(whoami)" != "root" ]]; then
	echo "run this script as root"
	exit 1;
fi;

disks=$(lsblk -nr "$DISK" | awk '{print $1}' | tail -n +2)


for partition in $disks; do
	mountpoint="/tmp/backup/$partition";
	echo "Making backup for partition $partition"
	mkdir -p "$mountpoint"
	actual="$(pwd)"
	mount "/dev/$partition" "$mountpoint" && copy_contents || copy_as_raw
done;
sfdisk -d "$DISK" > partition.dump
