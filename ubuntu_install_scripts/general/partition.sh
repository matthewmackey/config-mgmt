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
    BOOT_PART_NUM
    ROOTFS_PART_NUM
    DEV
    BOOT_DEV
    ROOTFS_DEV
    BOOT_PART_NAME
    BOOT_PART_SIZE
    ROOTFS_PART_NAME
    SWAP_LVM_SIZE
    ROOT_LVM_SIZE
    HOME_LVM_SIZE
    DOCKER_LVM_SIZE
  )

  OPTIONAL_VARS=(
    PASSPHRASE_FILE
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
create_partitions() {
  header "[Create Partitions]"

  # /boot (encrypted - LUKS v1)
  #
  # <part_num>:0:+<part_size> -> create partition of size <part_size> after
  #                              end of last partition
  sgdisk --new ${BOOT_PART_NUM}:0:+${BOOT_PART_SIZE} $DEV
  sgdisk --change-name ${BOOT_PART_NUM}:"${BOOT_PART_NAME}" $DEV
  sgdisk --typecode ${BOOT_PART_NUM}:8300 $DEV

  # / (encrypted - LUKS v2)
  #
  # <part_num>:0:0 -> fill remaining space
  sgdisk --new ${ROOTFS_PART_NUM}:0:0 $DEV
  sgdisk --change-name ${ROOTFS_PART_NUM}:"${ROOTFS_PART_NAME}" $DEV
  sgdisk --typecode ${ROOTFS_PART_NUM}:8300 $DEV
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
  echo -n "$PASSPHRASE" | cryptsetup open $BOOT_DEV $BOOT_DEV_MAPPER
  echo -n "$PASSPHRASE" | cryptsetup open $ROOTFS_DEV $ROOTFS_DEV_MAPPER
}


#-----------------------------------------------------------------------
# Step:
#-----------------------------------------------------------------------
format_boot_partition() {
  header "[Format /boot]"
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

  lvcreate -L $SWAP_LVM_SIZE -n swap $VG_NAME
  lvcreate -L $ROOT_LVM_SIZE -n root $VG_NAME
  lvcreate -L $HOME_LVM_SIZE -n home $VG_NAME
  lvcreate -L $DOCKER_LVM_SIZE -n docker $VG_NAME
}


#-----------------------------------------------------------------------
# UNDO Operation
#-----------------------------------------------------------------------
# Steps in reverse order of creation
undo() {
  header "[UNDO Partitioning (LUKS/LVM)]"

  # Delete LVM
  echo -e "\n------ [Delete LVM] --------------------------"
  lvremove -y /dev/mapper/$VG_NAME-*
  vgremove -y $VG_NAME
  pvremove -y $PV

  # Close LUKS devices
  echo -e "\n------ [Close LUKS devices] --------------------------"
  for i in $BOOT_DEV_MAPPER $ROOTFS_DEV_MAPPER; do
    cryptsetup close /dev/mapper/$i
  done

  # Wipe LUKS crypt signatures
  echo -e "\n------ [Wipe LUKS fs signatures] --------------------------"
  for i in $BOOT_DEV $ROOTFS_DEV; do
    wipefs --all $i
  done

  # Delete partitions
  echo -e "\n------ [Delete partitions] --------------------------"
  for i in $BOOT_PART_NUM $ROOTFS_PART_NUM; do
    sgdisk --delete $i $DEV
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
  format_boot_partition
  setup_rootfs_lvm
  display_grub_message
}


#-----------------------------------------------------------------------
# CLI
#-----------------------------------------------------------------------

BOOT_DEV_MAPPER=bootcrypt_luks1
ROOTFS_DEV_MAPPER=rootcrypt
PV=/dev/mapper/$ROOTFS_DEV_MAPPER
VG_NAME=ubuntuvg

# Placeholder global var
PASSPHRASE=

#-----------------------------
# REQUIRED Variables
#-----------------------------
# Using ROOTFS_* vs. ROOT_*, which breaks the convention of how I relate those
# vars to the DEV_MAPPER names below; doing this b/c it would be to easy to confuse
# variables named BOOT_* and ROOT_* when reading/editing this script, and I
# want to try to avoid any confusion that could cause developer errors
BOOT_PART_NUM=
ROOTFS_PART_NUM=

DEV=
BOOT_DEV=
ROOTFS_DEV=

BOOT_PART_NAME=
BOOT_PART_SIZE=

ROOTFS_PART_NAME=

SWAP_LVM_SIZE=
ROOT_LVM_SIZE=
HOME_LVM_SIZE=
DOCKER_LVM_SIZE=

#-----------------------------
# OPTIONAL Variables
#-----------------------------
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
