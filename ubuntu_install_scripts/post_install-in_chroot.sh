#!/bin/bash

DEV=/dev/nvme0n1

BOOT_DEV=${DEV}p5
ROOTFS_DEV=${DEV}p6

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


function setup_luks_keys() {
  echo -e "\n-------- [Luks - create & add keyfiles]------------------------------"

  local -r luks_dir=/etc/luks
  local -r key_file=${luks_dir}/boot_os.keyfile
 
  mkdir ${luks_dir}
  chmod u=rx,go-rwx ${luks_dir}
  
  dd if=/dev/urandom of=${key_file} bs=4096 count=1
  chmod u=r,go-rwx ${key_file}
  
  echo -n "$PASSPHRASE" | cryptsetup luksAddKey ${BOOT_DEV} ${key_file}
  echo -n "$PASSPHRASE" | cryptsetup luksAddKey ${ROOTFS_DEV} ${key_file}
}

function setup_crypt_files() {
  echo -e "\n-------- [Setup crypt files]------------------------------"

  if [[ $(sed -n -e '/^boot_crypt/p' /etc/crypttab | wc -l) -eq 0 ]]; then
    echo "boot_crypt UUID=$(blkid -s UUID -o value ${BOOT_DEV}) ${key_file} luks,discard" >> /etc/crypttab
  fi
  if [[ $(sed -n -e '/^root_crypt/p' /etc/crypttab | wc -l) -eq 0 ]]; then
    echo "root_crypt UUID=$(blkid -s UUID -o value ${ROOTFS_DEV}) ${key_file} luks,discard" >> /etc/crypttab
  fi

  if [[ $(sed -n -e "/^KEYFILE_PATTERN.*keyfile$/p" /etc/cryptsetup-initramfs/conf-hook | wc -l) -eq 0 ]]; then
    echo "KEYFILE_PATTERN=${luks_dir}/*.keyfile" >> /etc/cryptsetup-initramfs/conf-hook 
  fi
  if [[ $(sed -n -e '/^UMASK=0077$/p' /etc/initramfs-tools/initramfs.conf | wc -l) -eq 0 ]]; then
    echo "UMASK=0077" >> /etc/initramfs-tools/initramfs.conf 
  fi
}

function verify_luks_keys_added() {
  echo -e "\n-------- [Verify LUKS keys added]------------------------------"

  local was_error=n

  for luks_dev in $BOOT_DEV $ROOTFS_DEV; do
    cryptsetup open --test-passphrase --key-file /etc/luks/boot_os.keyfile ${luks_dev}

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

# Borrows from `refreshgrub` script in "ManualFullSystemEncryption":
#  https://help.ubuntu.com/community/ManualFullSystemEncryption/DetailedProcessPrepareInstall
#    |--> Uses: https://www.dropbox.com/s/dmqnzqs1bbp6dm9/encryptinstallation?dl=1
#      |--> Downloads: https://www.dropbox.com/s/npoazngcj3khcvf/refreshgrub?dl=1
function copy_grub_to_esp() {
  local -r efi_bootloader_id=ubuntu2004
  local -r efi_root=/boot/efi/EFI/${efi_bootloader_id}

  mkdir -p ${efi_root}
  cp -r /boot/grub/x86_64-efi ${efi_root}/

  echo -e "\n  [grub-install]"
  grub-install \
    --boot-directory=${efi_root} \
    --bootloader=${efi_bootloader_id} \
    --efi-directory=/boot/efi \
    --recheck \
    --target=x86_64-efi \
    $DEV

  echo -e "\n  [grub-mkconfig]"
  grub-mkconfig --output=${efi_root}/grub/grub.cfg
}

#read_passphrase
#setup_luks_keys
#verify_luks_keys_added
setup_crypt_files
#copy_grub_to_esp
#update-initramfs -u -k all

