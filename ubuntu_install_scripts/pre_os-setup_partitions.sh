#!/bin/bash

set -e
set -o pipefail

if [ "$EUID" -ne 0 ]; then
  echo "Please run as root"
  exit
fi


#-----------------------------------------------------------------------
# GLOBAL Placeholder Variables
#-----------------------------------------------------------------------
PASSPHRASE=


#-----------------------------------------------------------------------
# Constants
#-----------------------------------------------------------------------
CONSTANTS_ENV_FILE=constants.env

if [ ! -e "$CONSTANTS_ENV_FILE" ]; then
  echo "A \"$CONSTANTS_ENV_FILE\" must be in the same directory as this script"
  exit 1
fi

source $CONSTANTS_ENV_FILE


#-----------------------------------------------------------------------
# REQUIRED Variables
#-----------------------------------------------------------------------
# Using ROOTFS_* vs. ROOT_*, which breaks the convention of how I relate those
# vars to the DEV_MAPPER names below; doing this b/c it would be to easy to confuse
# variables named BOOT_* and ROOT_* when reading/editing this script, and I
# want to try to avoid any confusion that could cause developer errors
REQUIRED_VARS=(
  SHOULD_CREATE_EFI_PARTITION
  SHOULD_CREATE_LVM_SWAP_PARTITION

  INSTALL_DEV

  EFI_PART_NUM
  BOOT_PART_NUM
  ROOTFS_PART_NUM

  EFI_DEV
  BOOT_DEV
  ROOTFS_DEV

  BOOT_PART_NAME
  ROOTFS_PART_NAME

  ROOT_LVM_SIZE
  HOME_LVM_SIZE
  DOCKER_LVM_SIZE
)

#-----------------------------------------------------------------------
# OPTIONAL Variables
#-----------------------------------------------------------------------
OPTIONAL_VARS=(
  PASSPHRASE_FILE
  SWAP_LVM_SIZE
)


#-----------------------------------------------------------------------
# Helper Functions
#-----------------------------------------------------------------------
usage() {
  cat <<EOF

USAGE

  $0 ENV_FILE <-u>

ARGUMENTS

  ENV_FILE - file sourced that contains required variable definitions

OPTIONS

  -u - when present, the partitioning is undone vs. created
EOF

}


verify_vars_provided() {
  for v in ${REQUIRED_VARS[@]}; do
    if [ "${!v}" = "" ]; then
      error "variable $v required"
    else
      echo "REQUIRED variable $v found -> [${!v}]"
    fi
  done

  for v in ${OPTIONAL_VARS[@]}; do
    if [ "${!v}" != "" ]; then
      echo "OPTIONAL variable $v found -> [${!v}]"
    fi
  done
}


header() {
  echo
  echo "#--------------------------------------------------------"
  echo "# $1"
  echo "#--------------------------------------------------------"
}


msg() {
  echo "[MSG] $1"
}


error() {
  echo "[ERROR] $1"
  echo
  echo
  usage
  exit 1
}


#-----------------------------------------------------------------------
# Step:
#-----------------------------------------------------------------------
read_luks_passphrase() {
  header "[Read PASSPHRASE]"

  echo -e "PASSPHRASE_FILE=$PASSPHRASE_FILE"
  if [[ -e "$PASSPHRASE_FILE" ]]; then
    echo "  Reading pass from file"
    PASSPHRASE=$(cat $PASSPHRASE_FILE)
  else
    echo -e "\nPassphrase file NOT found."
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


#-----------------------------------------------------------------------
# Step:
#-----------------------------------------------------------------------
# sgdisk Notes:
#
# <part_num>:0:+<part_size> -> create partition of size <part_size> at 1st available sector
#                              (ie - after end of the currently last partition)
# <part_num>:0:0            -> fill remaining space
#
create_partitions() {
  header "[Create Partitions]"

  if [[ "$SHOULD_CREATE_EFI_PARTITION" = "y" ]]; then
    msg "Option to create an EFI system partion has been chosen"
    create_boot_efi_partition
  fi

  create_boot_partition
  create_root_partition
}


create_boot_efi_partition() {
  msg "Creating /boot/efi partition"

  sgdisk --new ${EFI_PART_NUM}:0:+${EFI_PART_SIZE} $INSTALL_DEV
  sgdisk --change-name ${EFI_PART_NUM}:"${EFI_PART_NAME}" $INSTALL_DEV
  sgdisk --typecode ${EFI_PART_NUM}:${EFI_SYSTEM_PART_TYPE} $INSTALL_DEV
}

# /boot (encrypted - LUKS v1)
create_boot_partition() {
  msg "Creating /boot partition"

  sgdisk --new ${BOOT_PART_NUM}:0:+${BOOT_PART_SIZE} $INSTALL_DEV
  sgdisk --change-name ${BOOT_PART_NUM}:"${BOOT_PART_NAME}" $INSTALL_DEV
  sgdisk --typecode ${BOOT_PART_NUM}:${LINUX_FS_PART_TYPE} $INSTALL_DEV

}

# / (encrypted - LUKS v2)
create_root_partition() {
  msg "Creating / partition"

  # Fill remaining space on disk
  sgdisk --new ${ROOTFS_PART_NUM}:0:0 $INSTALL_DEV
  sgdisk --change-name ${ROOTFS_PART_NUM}:"${ROOTFS_PART_NAME}" $INSTALL_DEV
  sgdisk --typecode ${ROOTFS_PART_NUM}:${LINUX_FS_PART_TYPE} $INSTALL_DEV

}


#-----------------------------------------------------------------------
# Step:
#-----------------------------------------------------------------------
create_luks() {
  header "[LUKS Format]"
  create_boot_crypt_luks1
  create_root_crypt_luks2
}


create_boot_crypt_luks1() {
  msg "Creating LUKS v1 crypt on /boot partition"
  echo -n "$PASSPHRASE" | cryptsetup luksFormat --type=luks1 $BOOT_DEV

}

create_root_crypt_luks2() {
  msg "Creating LUKS v2 crypt on / partition"
  echo -n "$PASSPHRASE" | cryptsetup luksFormat $ROOTFS_DEV
}


#-----------------------------------------------------------------------
# Step:
#-----------------------------------------------------------------------
open_luks() {
  header "[LUKS Open]"
  open_boot_crypt
  open_root_crypt
}

open_boot_crypt() {
  msg "Opening LUKS crypt for /boot partition"
  echo -n "$PASSPHRASE" | cryptsetup open $BOOT_DEV $BOOT_DEV_MAPPER
}

open_root_crypt() {
  msg "Opening LUKS crypt for / partition"
  echo -n "$PASSPHRASE" | cryptsetup open $ROOTFS_DEV $ROOTFS_DEV_MAPPER
}


#-----------------------------------------------------------------------
# Step:
#-----------------------------------------------------------------------
# We leave formatting of LVM partitions to the Installer because
# creating a script to handle the /dev/mapper/* LVM volume names
# with how the dashes are handled can get complicated, and just
# doing it in the Installer is not very time consuming.
format_partitions() {
  header "[Format Partitions]"
  format_boot_efi_partition_fat32
  format_boot_partition_ext4
}

format_boot_efi_partition_fat32() {
  msg "Formatting /boot/efi as fat32"
  mkfs.vfat -F 32  $EFI_DEV
}

format_boot_partition_ext4() {
  msg "Formatting /boot as ext4"
  mkfs.ext4 -L boot /dev/mapper/$BOOT_DEV_MAPPER
}


#-----------------------------------------------------------------------
# Step:
#-----------------------------------------------------------------------
# Formatting done by OS installer
setup_rootfs_lvm() {
  header "[Setup rootfs LVM]"

  pvcreate $PV

  vgcreate $VG_NAME $PV

  lvcreate -L $ROOT_LVM_SIZE -n root $VG_NAME
  lvcreate -L $HOME_LVM_SIZE -n home $VG_NAME
  lvcreate -L $DOCKER_LVM_SIZE -n docker $VG_NAME

  if [[ "$SHOULD_CREATE_LVM_SWAP_PARTITION" = "y" ]]; then
    lvcreate -L $SWAP_LVM_SIZE -n swap $VG_NAME
  fi
}


#-----------------------------------------------------------------------
# Step:
#-----------------------------------------------------------------------
function display_grub_message() {
  header "[GRUB message]"

  cat <<-END
    After you start the installer, you need to come back to the
    echo terminal and run:

    echo "GRUB_ENABLE_CRYPTODISK=y" >> /target/etc/default/grub
	END
}


#-----------------------------------------------------------------------
# UNDO Operation
#-----------------------------------------------------------------------
# Steps in reverse order of creation
undo() {
  header "[UNDO Partitioning (LUKS/LVM)]"

  # Delete LVM
  msg "Delete LVM"
  lvremove -y /dev/mapper/$VG_NAME-*
  vgremove -y $VG_NAME
  pvremove -y $PV

  # Close LUKS devices
  msg "Close LUKS devices"
  for i in $BOOT_DEV_MAPPER $ROOTFS_DEV_MAPPER; do
    cryptsetup close /dev/mapper/$i
  done

  msg "Wipe LUKS crypt signatures"
  for i in $BOOT_DEV $ROOTFS_DEV; do
    wipefs --all $i
  done

  msg "Delete partitions"
  if [[ "$SHOULD_CREATE_EFI_PARTITION" = "y" ]]; then
    sgdisk --delete $EFI_PART_NUM $INSTALL_DEV
  fi

  for i in $BOOT_PART_NUM $ROOTFS_PART_NUM; do
    sgdisk --delete $i $INSTALL_DEV
  done
}


#-----------------------------------------------------------------------
# MAIN()
#-----------------------------------------------------------------------
main() {
  read_luks_passphrase
  create_partitions
  create_luks
  open_luks
  format_partitions
  setup_rootfs_lvm
  display_grub_message
}


#-----------------------------------------------------------------------
# MAIN()
#-----------------------------------------------------------------------
ENV_FILE=$1

if [ ! -f "$ENV_FILE" ]; then
  error "You must provide and ENV_FILE"
fi

source $ENV_FILE
verify_vars_provided

OPTION=
if [ $# = 2 ]; then
  OPTION=$2
fi

if [ "$OPTION" = "-u" ]; then
  undo
else
  main
fi
