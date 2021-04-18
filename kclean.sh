#!/bin/sh

SUFFIX=gentoo

mount /boot

while [ "$1" != "" ];
do
	KERNEL=/boot/kernel-$1-$SUFFIX
	CONFIG=/boot/config-$1-$SUFFIX
	SMAP=/boot/System.map-$1-$SUFFIX
	MODULES=/lib/modules/$1-$SUFFIX
	SOURCES=/usr/src/linux-$1-$SUFFIX
	emerge -Ca =gentoo-sources-"$1"
	rm -rf $KERNEL
	rm -rf $CONFIG
	rm -rf $SMAP
	rm -rf $MODULES
	rm -rf $SOURCES
	shift
done

grub-mkconfig -o /boot/grub/grub.cfg
umount /boot
sync
