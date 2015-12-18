#!/bin/bash

# running, unfinhed beta template

#TODO:   complete MK depedencies

# 1.initial source: make minimal rootfs on amd64 Debian Jessie, according to "How to create bare minimum Debian Wheezy rootfs from scratch"
# http://olimex.wordpress.com/2014/07/21/how-to-create-bare-minimum-debian-wheezy-rootfs-from-scratch/

#------------------------------------------------------------------------------------------------------
# Variables
#------------------------------------------------------------------------------------------------------
SCRIPT_ROOT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
CURRENT_DIR=`pwd`
WORK_DIR=$1

ROOTFS_DIR=${CURRENT_DIR}/rootfs
distro=jessie

#-------------------------------------------
# u-boot, toolchain, imagegen vars
#-------------------------------------------
set -e
# cross toolchain
CC_DIR="${CURRENT_DIR}/gcc-linaro-arm-linux-gnueabihf-4.9-2014.09_linux"
CC_URL="https://releases.linaro.org/14.09/components/toolchain/binaries/gcc-linaro-arm-linux-gnueabihf-4.9-2014.09_linux.tar.bz2"
CC_FILE="${CC_DIR}.tar.bz2"
CC="${CC_DIR}/bin/arm-linux-gnueabihf-"

#UBOOT_VERSION=''
UBOOT_VERSION='v2015.10'
UBOOT_SPLFILE=${CURRENT_DIR}/uboot/u-boot-with-spl-dtb.sfp

IMG_FILE=${CURRENT_DIR}/mksoc_sdcard.img
DRIVE=/dev/loop0

KERNEL_DIR=${CURRENT_DIR}/arm-linux-gnueabifh-kernel

NCORES=`nproc`

BOOT_MNT=/mnt/boot
ROOTFS_MNT=/mnt/rootfs

#-----------------------------------------------------------------------------------
# build files
#-----------------------------------------------------------------------------------

function create_image {
$SCRIPT_ROOT_DIR/create_img.sh $CURRENT_DIR
}

function build_chroot_into_image {
$SCRIPT_ROOT_DIR/gen_rootfs.sh $CURRENT_DIR /mnt
}

function build_chroot_into_folder {
$SCRIPT_ROOT_DIR/gen_rootfs.sh $CURRENT_DIR
}

function build_uboot {
$SCRIPT_ROOT_DIR/build_uboot.sh $CURRENT_DIR
}

function build_kernel {
$SCRIPT_ROOT_DIR/build_kernel.sh $CURRENT_DIR
}

#-----------------------------------------------------------------------------------
# install func
#-----------------------------------------------------------------------------------
function install_files {
echo "#-------------------------------------------------------------------------------#"
echo "#-------------------------------------------------------------------------------#"
echo "#-----------------------------          ----------------------------------------#"
echo "#----------------     +++    Installing files         +++ ----------------------#"
echo "#-----------------------------          ----------------------------------------#"
echo "#-------------------------------------------------------------------------------#"
echo "#-------------------------------------------------------------------------------#"

sudo losetup --show -f $IMG_FILE

# --------- install boot partition files (kernel, dts, dtb) ---------
sudo mkdir -p $BOOT_MNT
sudo mount -o uid=1000,gid=1000 ${DRIVE}p1 $BOOT_MNT

echo "copying boot sector files"
sudo cp $KERNEL_DIR/linux/arch/arm/boot/zImage $BOOT_MNT
sudo cp $KERNEL_DIR/linux/arch/arm/boot/dts/socfpga_cyclone5.dts $BOOT_MNT/socfpga.dts
sudo cp $KERNEL_DIR/linux/arch/arm/boot/dts/socfpga_cyclone5.dtb $BOOT_MNT/socfpga.dtb
sudo umount $BOOT_MNT

# --------- install rootfs partition files (chroot, kernel modules) ---------
sudo mkdir -p $ROOTFS_MNT
sudo mount ${DRIVE}p2 $ROOTFS_MNT

# chroot -------#
#cd $ROOTFS_DIR
#sudo tar cf - . | (sudo tar xvf - -C $ROOTFS_MNT)

# kernel modules -------#
cd $KERNEL_DIR/linux
export PATH=$CC_DIR/bin/:$PATH
#export CROSS_COMPILE=$CC
sudo make ARCH=arm INSTALL_MOD_PATH=$ROOTFS_MNT modules_install
#sudo make -j$NCORES LOADADDR=0x8000 modules_install INSTALL_MOD_PATH=$ROOTFS_MNT

sudo umount $ROOTFS_MNT
sudo losetup -D
sync
}

function install_uboot {
echo "installing u-boot-with-spl"
sudo dd bs=512 if=$UBOOT_SPLFILE of=$IMG_FILE seek=2048 conv=notrunc
sync
}

#------------------.............. run functions section ..................-----------#
echo "#---------------------------------------------------------------------------------- "
echo "#-------             Image building process start                          -------- "
echo "#---------------------------------------------------------------------------------- "

create_image
#build_chroot_into_image
#build_chroot_into_folder
#build_uboot
#build_kernel
#install_files
#install_uboot

echo "#---------------------------------------------------------------------------------- "
echo "#-------             Image building process complete                       -------- "
echo "#---------------------------------------------------------------------------------- "

