#!/bin/bash

DEV=/dev/sda
DM=${DEV##*/}

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
  # GRUB - unencrypted 
  sgdisk --new 1:0:+2M $DEV

  # /boot - encrypted
  sgdisk --new 2:0:+768M $DEV

  # / - encrypted
  sgdisk --new 3:0:0 $DEV

  sgdisk --typecode 1:ef02 $DEV
  sgdisk --typecode 2:8301 $DEV
  sgdisk --typecode 3:8301 $DEV

  sgdisk --change-name 1:GRUB $DEV
  sgdisk --change-name 2:/boot $DEV 
  sgdisk --change-name 3:rootfs $DEV 
}


function create_luks() {
  echo -e "\n------ [Luks FORMAT] --------------------------"
  echo -n "$PASSPHRASE" | cryptsetup luksFormat ${DEV}2
  echo -n "$PASSPHRASE" | cryptsetup luksFormat ${DEV}3
}

function open_luks() {
  echo -e "\n------ [Luks OPEN] --------------------------"
  echo -n "$PASSPHRASE" | cryptsetup open ${DEV}2 boot_crypt
  echo -n "$PASSPHRASE" | cryptsetup open ${DEV}3 rootfs_crypt
}

function format_boot_partition() {
  mkfs.ext4 -L boot /dev/mapper/boot_crypt
}

function setup_lvm() {
  LVM_DM=/dev/mapper/rootfs_crypt
  VG_NAME=ubuntu-vg

  pvcreate $LVM_DM

  vgcreate $VG_NAME $LVM_DM

  lvcreate -L 12G -n swap $VG_NAME
  lvcreate -L 40G -n root $VG_NAME
  lvcreate -L 60G -n home $VG_NAME 
}

function display_grub_message() {
  echo -e "\n------ [GRUB message] --------------------------"
  cat <<-END
    After you start the installer, you need to come back to the
    echo terminal and run:

    echo "GRUB_ENABLE_CRYPTODISK=y" >> /target/etc/default/grub
	END
}

read_passphrase
#create_partitions
#create_luks
#open_luks
#format_boot_partition
#setup_lvm
display_grub_message

