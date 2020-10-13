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

function open_luks() {
  echo -e "\n------ [Luks OPEN] --------------------------"
  echo -n "$PASSPHRASE" | cryptsetup open $BOOT_DEV $BOOT_DM
  echo -n "$PASSPHRASE" | cryptsetup open $ROOTFS_DEV $ROOTFS_DM
}

function setup_chroot_mounts() {
  echo -e "\n-------- [Setup chroot mounts]------------------------------"

  if [[ ! -d /target ]]; then
    mkdir /target
  fi

  mount /dev/mapper/ubuntu--vg-root /target

  for n in proc sys dev etc/resolv.conf
  do
    mount --rbind /"$n" /target/"$n"
  done
}

# -----[MAIN]---------------------------------------
read_passphrase
open_luks
setup_chroot_mounts

cat <<-END
  Run the following to setup chroot environment:

  chroot /target
  mount -a         # mounts /boot, /boot/efi, /home (from fstab)

	END
