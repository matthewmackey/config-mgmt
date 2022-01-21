#!/bin/bash

set -e
set -o pipefail


#-----------------------------------------------------------------------
# Helper Functions
#-----------------------------------------------------------------------
usage() {
  cat <<EOF

USAGE

  $0 ENV_FILE

ARGUMENTS

  ENV_FILE - file sourced that contains required variable definitions

EOF

}


verify_vars_provided() {
  REQUIRED_VARS=(
    BOOT_DEV
    ROOTFS_DEV
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
setup_luks_keys() {
  header "[Luks - create & add keyfiles]"

  mkdir ${LUKS_DIR}
  chmod 0500 ${LUKS_DIR}

  dd if=/dev/urandom of=${LUKS_KEY_FILE} bs=4096 count=1
  chmod 0400 ${LUKS_KEY_FILE}

  echo -n "$PASSPHRASE" | cryptsetup luksAddKey ${BOOT_DEV} ${LUKS_KEY_FILE}
  echo -n "$PASSPHRASE" | cryptsetup luksAddKey ${ROOTFS_DEV} ${LUKS_KEY_FILE}
}


#-----------------------------------------------------------------------
# Step:
#-----------------------------------------------------------------------
setup_crypt_files() {
  header "[Setup crypt files]"

  if [[ $(sed -n -e "/^$BOOT_DEV_MAPPER/p" /etc/crypttab | wc -l) -eq 0 ]]; then
    echo "$BOOT_DEV_MAPPER UUID=$(blkid -s UUID -o value ${BOOT_DEV}) ${LUKS_KEY_FILE} luks,discard" >> /etc/crypttab
  fi
  if [[ $(sed -n -e "/^$ROOTFS_DEV_MAPPER/p" /etc/crypttab | wc -l) -eq 0 ]]; then
    echo "$ROOTFS_DEV_MAPPER UUID=$(blkid -s UUID -o value ${ROOTFS_DEV}) ${LUKS_KEY_FILE} luks,discard" >> /etc/crypttab
  fi

  if [[ $(sed -n -e "/^KEYFILE_PATTERN.*keyfile$/p" /etc/cryptsetup-initramfs/conf-hook | wc -l) -eq 0 ]]; then
    echo "KEYFILE_PATTERN=${LUKS_DIR}/*.keyfile" >> /etc/cryptsetup-initramfs/conf-hook
  fi
  if [[ $(sed -n -e '/^UMASK=0077$/p' /etc/initramfs-tools/initramfs.conf | wc -l) -eq 0 ]]; then
    echo "UMASK=0077" >> /etc/initramfs-tools/initramfs.conf
  fi
}


#-----------------------------------------------------------------------
# Step:
#-----------------------------------------------------------------------
verify_luks_keys_added() {
  header "[Verify LUKS keys added]"

  local was_error=n

  for luks_dev in $BOOT_DEV $ROOTFS_DEV; do
    cryptsetup open --test-passphrase --key-file $LUKS_KEY_FILE ${luks_dev}

    if [[ $? -ne 0 ]]; then
      echo "  ERROR -> luks keyfile could NOT unlock ${luks_dev}"
      was_error=y
    else
      echo "  OK -> luks keyfile could unlock ${luks_dev}"
    fi
  done

  if [[ x$was_error = "xy" ]]; then
    exit -1
  fi
}


#-----------------------------------------------------------------------
# CLI
#-----------------------------------------------------------------------
BOOT_DEV_MAPPER=bootcrypt_luks1
ROOTFS_DEV_MAPPER=rootcrypt

LUKS_DIR=/root/.luks
LUKS_KEY_FILE=${LUKS_DIR}/full_disk.keyfile


# Placeholder global var
PASSPHRASE=

#-----------------------------
# REQUIRED Variables
#-----------------------------
# Using ROOTFS_* vs. ROOT_*, which breaks the convention of how I relate those
# vars to the DEV_MAPPER names below; doing this b/c it would be to easy to confuse
# variables named BOOT_* and ROOT_* when reading/editing this script, and I
# want to try to avoid any confusion that could cause developer errors
BOOT_DEV=
ROOTFS_DEV=

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

read_passphrase
setup_luks_keys
verify_luks_keys_added
setup_crypt_files
update-initramfs -u -k all
