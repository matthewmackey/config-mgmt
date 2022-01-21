#!/bin/bash

set -e
set -o pipefail


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
  REQUIRED_VARS=(
    BOOT_DEV
    BOOT_CRYPT_SIZE
    ROOTFS_DEV
    ROOTFS_CRYPT_SIZE
    SWAP_LVM_SIZE
    ROOT_LVM_SIZE
    HOME_LVM_SIZE
  )

  OPTIONAL_VARS=(
    PASSPHRASE_FILE
  )

  OPTIONAL_ARRAY_VARS=(
    ROOTFS_CRYPT_EXTRA_LVM_PARTITIONS
  )


  for v in ${REQUIRED_VARS[@]}; do
    if [ "${!v}" = "" ]; then
      error "variable $v required"
    else
      echo "REQUIRED variable $v found"
      echo "  ${!v}"
    fi
  done

  for v in ${OPTIONAL_VARS[@]}; do
    if [ "${!v}" != "" ]; then
      echo "OPTIONAL variable $v found"
      echo "  ${!v}"
    fi
  done

  for v in ${OPTIONAL_ARRAY_VARS[@]}; do
    _arr_ref="$v[@]"
    _arr=(${!_arr_ref})
    _arr_len="${#_arr[@]}"

    if [ $_arr_len -gt 0 ]; then
      echo "OPTIONAL array variable $v found"
      echo "  ${_arr[@]}"
    fi
  done
}


header() {
  echo
  echo "#--------------------------------------------------------"
  echo "# $1"
  echo "#--------------------------------------------------------"
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
create_partitions() {
  header "[Create Partitions]"

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
create_luks() {
  header "[LUKS Format]"
  echo -n "$PASSPHRASE" | cryptsetup luksFormat --type=luks1 $BOOT_DEV
  echo -n "$PASSPHRASE" | cryptsetup luksFormat $ROOTFS_DEV
}


#-----------------------------------------------------------------------
# Step:
#-----------------------------------------------------------------------
open_luks() {
  header "[LUKS Open]"
  echo -n "$PASSPHRASE" | cryptsetup open $BOOT_DEV $BOOT_DM
  echo -n "$PASSPHRASE" | cryptsetup open $ROOTFS_DEV $ROOTFS_DM
}


#-----------------------------------------------------------------------
# Step:
#-----------------------------------------------------------------------
format_boot_partition() {
  echo -e "\n------ [Format /boot] --------------------------"
  mkfs.ext4 -L boot /dev/mapper/$BOOT_DM
}


#-----------------------------------------------------------------------
# Step:
#-----------------------------------------------------------------------
setup_root_lvm() {
  echo -e "\n------ [Setup root LVM] --------------------------"
  LVM_DM=/dev/mapper/$ROOTFS_DM
  VG_NAME=ubuntu-vg

  pvcreate $LVM_DM

  vgcreate $VG_NAME $LVM_DM

  lvcreate -L $SWAP_SIZE -n swap $VG_NAME
  lvcreate -L $ROOT_PART_SIZE -n root $VG_NAME
  lvcreate -L $HOME_PART_SIZE -n home $VG_NAME
}


#-----------------------------------------------------------------------
# Step:
#-----------------------------------------------------------------------
display_grub_message() {
  echo -e "\n------ [GRUB message] --------------------------"
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


#-----------------------------------------------------------------------
# MAIN()
#-----------------------------------------------------------------------
main() {
  read_luks_passphrase
  # create_partitions
  # create_luks
  # open_luks
  # format_boot_partition
  # setup_root_lvm
  display_grub_message
}


#-----------------------------------------------------------------------
# CLI
#-----------------------------------------------------------------------

BOOT_DM=bootcrypt_luks1
ROOTFS_DM=rootcrypt

#-----------------------------
# REQUIRED Variables
#-----------------------------
# Using ROOTFS_* vs. ROOT_*, which breaks the convention of how I relate those
# vars to the DM names below; doing this b/c it would be to easy to confuse
# variables named BOOT_* and ROOT_* when reading/editing this script, and I
# want to try to avoid any confusion that could cause developer errors
BOOT_DEV=
BOOT_CRYPT_SIZE=

ROOTFS_DEV=
ROOTFS_CRYPT_SIZE=

SWAP_LVM_SIZE=
ROOT_LVM_SIZE=
HOME_LVM_SIZE=

#-----------------------------
# OPTIONAL Variables
#-----------------------------
ROOTFS_CRYPT_EXTRA_LVM_PARTITIONS=()
PASSPHRASE_FILE=


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
