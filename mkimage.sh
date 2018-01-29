#!/bin/sh

set -e -v

# Work around no sparse files on ecryptfs
DISK=/home/mlyle.nocrypt/imgfile
SIZE=7810000	# Conservative "4 GB" in sectors
KERNEL=4.14.15-artik-armv7-r0
ROOTNAME=/home/mlyle.nocrypt/rootimg.ext4.gz

rm -f ${DISK}
rm -rf dtbs

# Layout a new disk image from scratch (sparse)
dd if=loaders/bl1.bin of=${DISK} seek=1 bs=512
dd if=loaders/bl2.bin of=${DISK} seek=31 bs=512
dd if=loaders/u-boot-artik5-v2012.07-r3.bin of=${DISK} seek=63 bs=512
dd if=loaders/tzsw.bin of=${DISK} seek=719 bs=512
dd if=/dev/zero of=${DISK} seek=${SIZE} bs=512 count=1

sfdisk ${DISK} <<-__EOF__
1M,48M,0xE,*
,,,-
__EOF__

# Make a DOS boot filesystem.
mformat -i ${DISK}@@1M -v boot -T 98304 -h 2 -s 256

# Copy the kernel to it
mcopy -i ${DISK}@@1M kernl/${KERNEL}.zImage ::/zImage

# Copy devicetree blobs to it
mkdir -p dtbs
tar -C dtbs -xvf kernl/${KERNEL}-dtbs.tar.gz
mcopy -i ${DISK}@@1M -s dtbs ::

# Position the root filesystem at the right place
# 49 * 1048576 / 512 = 100352
zcat ${ROOTNAME} | dd of=${DISK} seek=100352 bs=512 conv=sparse
