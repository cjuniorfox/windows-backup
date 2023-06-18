#!/bin/bash
DEVICE=$1

copy_as_raw(){
	pigz -dc "$i" | dd of="/dev/$PART" bs=20M status=progress
}

define_parttype(){
	if [[ "$COUNT" = "1" ]]; then
		PARTTYPE="msdos";
	else
		PARTTYPE="ntfs";
	fi
}

copy_contents(){
	#PARTTYPE="$(blkid /dev/$PART --output export | grep TYPE | awk -F= '{print $2}')"
	define_parttype
	mountpoint="/tmp/backup/$PART"
	if [[ "$PARTTYPE" = "ntfs" ]]; then
		"mkfs.$PARTTYPE" -f "/dev/$PART"
	else
		"mkfs.$PARTTYPE" "/dev/$PART"
	fi
	echo "Restoring partition $PART"
	mkdir -p "$mountpoint"
	actual="$(pwd)"
	mount "/dev/$PART" "$mountpoint"
	cd "$mountpoint"
	pigz -dc "$actual/$file" | tar -xvf -
	cd "$actual"
	umount "$mountpoint"
}

python3 ./partition.py $DEVICE > restore.dump
sfdisk "$DEVICE" < restore.dump
partprobe "$DEVICE"
PARTITIONS="$(lsblk -nr "$DEVICE" | awk '{print $1}' | tail -n +2)"

COUNT=1

for file in $(ls *.{tar.gz,dd.gz}); do 
	PART="$(echo -e "$PARTITIONS" | sed -n ${COUNT}p)"
	echo $file | grep 'tar' && copy_contents || copy_as_raw
	COUNT=$(expr "$COUNT" + 1)
done
