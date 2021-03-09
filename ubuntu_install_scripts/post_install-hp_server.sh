#!/bin/bash

DEV=/dev/sda

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

function display_chroot_setup() {
  echo -e "\n-------- [Display chroot setup]------------------------------"
  cat <<-END
    Run the following to setup chroot environment:

    mount /dev/mapper/ubuntu--vg-root /target

    for n in proc sys dev etc/resolv.conf
    do
      mount --rbind /\$n /target/\$n
    done

    chroot /target
	END
}

function setup_luks_keys() {
  echo -e "\n-------- [Luks - ADD KEYS]------------------------------"

  mkdir /etc/luks
  chmod u=rx,go-rwx /etc/luks

  dd if=/dev/urandom of=/etc/luks/boot_os.keyfile bs=4096 count=1
  chmod u=r,go-rwx /etc/luks/boot_os.keyfile

  echo -n "$PASSPHRASE" | cryptsetup luksAddKey ${DEV}2 /etc/luks/boot_os.keyfile
  echo -n "$PASSPHRASE" | cryptsetup luksAddKey ${DEV}3 /etc/luks/boot_os.keyfile
}

function setup_crypt_files() {
  echo -e "\n-------- [Setup crypt files]------------------------------"

  echo "boot_crypt UUID=$(blkid -s UUID -o value ${DEV}2) /etc/luks/boot_os.keyfile luks,discard" >> /etc/crypttab
  echo "rootfs_crypt UUID=$(blkid -s UUID -o value ${DEV}3) /etc/luks/boot_os.keyfile luks,discard" >> /etc/crypttab

  echo "KEYFILE_PATTERN=/etc/luks/*.keyfile" >> /etc/cryptsetup-initramfs/conf-hook
  echo "UMASK=0077" >> /etc/initramfs-tools/initramfs.conf
}

function dangerous() {
  setup_luks_keys
  setup_crypt_files
  update-initramfs -u -k all
}

# -----[MAIN]---------------------------------------
display_chroot_setup

# -----[Inside chroot]------------------------------
#read_passphrase

# Mounts: /, /home, /boot (see /etc/fstab in chroot environment)
#mount -a

#dangerous

