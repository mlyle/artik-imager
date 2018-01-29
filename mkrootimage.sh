#!/bin/bash

set -e -v

if [ "$UID" -ne 0 ] ; then
	exec fakeroot $0 $*
fi

BASETARNAME=armhf-rootfs-ubuntu-xenial
KERNEL=4.14.15-artik-armv7-r0
OUTNAME=/home/mlyle.nocrypt/rootimg.ext4
ROOTDEV=/dev/mmcblk2

rm -f ${OUTNAME} ${OUTNAME}.gz
rm -rf rootimg

cp -r skel rootimg

tar -C rootimg -xvf ${BASETARNAME}.tar
tar -C rootimg -xvf kernl/${KERNEL}-modules.tar.gz

cat >rootimg/etc/fstab <<EOT
${ROOTDEV}p2  /  auto  errors=remount-ro  0  1
${ROOTDEV}p1  /boot/uboot  auto  defaults  0  2
EOT

genext2fs -d rootimg -b 1950000 -i 8192 ${OUTNAME}

tune2fs -O has_journal,dir_index,filetype,extent,flex_bg,sparse_super,large_file,huge_file,dir_nlink,extra_isize -o acl ${OUTNAME}
e2fsck -y ${OUTNAME} || true
gzip -9 ${OUTNAME}
