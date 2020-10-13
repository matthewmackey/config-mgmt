#!/bin/bash

DEV=/dev/nvme0n1

# Using ROOTFS_* vs. ROOT_*, which breaks the convention of how I relate those
# vars to the DM names below; doing this b/c it would be to easy to confuse
# variables named BOOT_* and ROOT_* when reading/editing this script, and I
# want to try to avoid any confusion that could cause developer errors
BOOT_DEV=${DEV}p5
ROOTFS_DEV=${DEV}p6

BOOT_DM=boot_crypt
ROOTFS_DM=root_crypt

BOOT_PART_SIZE=1G
SWAP_SIZE=24G           # 16G x 1.5
ROOT_PART_SIZE=40G
HOME_PART_SIZE=100G
EMPTY_PART_SIZE=100G

PASSPHRASE_FILE="$1"

function read_passphrase() {
  echo -e "\n------ [Read PASSPHRASE] --------------------------"

  if [[ -e "$PASSPHRASE_FILE" ]]; then
    echo "  Reading pass from file"
    PASSPHRASE=$(cat $PASSPHRASE_FILE)
  else
    read -rsp "Enter passphrase: " PASSPHRASE
    echo
    read -rsp "Enter again: " PASSPHRASE_AGAIN
    echo

    if [[ "$PASSPHRASE" != "$PASSPHRASE_AGAIN" ]]; then
      echo "Passphrases don't match...exiting"
      exit -1
    else
      echo -e "\nPassphrases: OK\n"
    fi
  fi
  echo
}

function create_partitions() {
  echo -e "\n------ [Create Partitions] --------------------------"
  # /boot - encrypted
  sgdisk --new 5:0:+${BOOT_PART_SIZE} $DEV

  # EMPTY partition for future use
  sgdisk --new 7:-${EMPTY_PART_SIZE}:0 $DEV

  # / - encrypted (declared after part #7 so can fill rest of space)
  sgdisk --new 6:0:0 $DEV

  sgdisk --typecode 5:8300 $DEV
  sgdisk --typecode 6:8300 $DEV

  sgdisk --change-name 5:"Ubuntu 20.04 /boot" $DEV 
  sgdisk --change-name 6:"Ubuntu 20.04 /" $DEV 
  sgdisk --change-name 7:"EMPTY" $DEV 
}


function create_luks() {
  echo -e "\n------ [Luks FORMAT] --------------------------"
  echo -n "$PASSPHRASE" | cryptsetup luksFormat --type=luks1 $BOOT_DEV
  echo -n "$PASSPHRASE" | cryptsetup luksFormat $ROOTFS_DEV
}

function open_luks() {
  echo -e "\n------ [Luks OPEN] --------------------------"
  echo -n "$PASSPHRASE" | cryptsetup open $BOOT_DEV $BOOT_DM
  echo -n "$PASSPHRASE" | cryptsetup open $ROOTFS_DEV $ROOTFS_DM
}

function format_boot_partition() {
  echo -e "\n------ [Format /boot] --------------------------"
  mkfs.ext4 -L boot /dev/mapper/$BOOT_DM
}

function setup_root_lvm() {
  echo -e "\n------ [Setup root LVM] --------------------------"
  LVM_DM=/dev/mapper/$ROOTFS_DM
  VG_NAME=ubuntu-vg

  pvcreate $LVM_DM

  vgcreate $VG_NAME $LVM_DM

  lvcreate -L $SWAP_SIZE -n swap $VG_NAME 
  lvcreate -L $ROOT_PART_SIZE -n root $VG_NAME
  lvcreate -L $HOME_PART_SIZE -n home $VG_NAME 
}

function display_grub_message() {
  echo -e "\n------ [GRUB message] --------------------------"
  cat <<-END
    After you start the installer, you need to come back to the
    echo terminal and run:

    echo "GRUB_ENABLE_CRYPTODISK=y" >> /target/etc/default/grub
	END
}

function undo() {
  # Reverse order of creation

  # Delete LVM
  echo -e "\n------ [Delete LVM] --------------------------"
  lvremove -y /dev/mapper/ubuntu--vg-*
  vgremove -y ubuntu-vg
  pvremove -y /dev/mapper/$ROOTFS_DM

  # Close LUKS devices
  echo -e "\n------ [Close LUKS devices] --------------------------"
  for i in $BOOT_DM $ROOTFS_DM; do
    cryptsetup close /dev/mapper/$i
  done

  # Wipe LUKS crypt signatures
  echo -e "\n------ [Wipe LUKS fs signatures] --------------------------"
  for i in $BOOT_DEV $ROOTFS_DEV; do
    wipefs --all $i
  done

  # Delete partitions
  echo -e "\n------ [Delete partitions] --------------------------"
  for i in 5 6 7; do
    sgdisk --delete $i $DEV
  done
}

undo

#read_passphrase
#create_partitions
#create_luks
#open_luks
#format_boot_partition
#setup_root_lvm
#display_grub_message

