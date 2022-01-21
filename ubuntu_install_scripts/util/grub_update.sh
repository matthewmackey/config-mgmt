#!/bin/bash

#---------------------------------------------------------------------------
# TLDR;
# This makes a copy of the GRUB modules and configuration in /boot directly
# to the EFI SP (thus, we could acheive this with symlinks if we could).
#---------------------------------------------------------------------------
#
# The point of this is so that we don't have to type the LUKS password
# before entering GRUB.  In order to do this, we need to have a full copy
# of GRUB that runs directly from the EFI system partion.  The GRUB
# config file for that GRUB instance then has `Ubuntu` entries that have the
# commands to unlock the /boot LUKS partition and then load the kernel
# from that unlocked /boot partition all from
#
# Without doing this, the current implementation is to have a minimal
# GRUB config that unlocks the /boot partition and then loads the
# GRUB config there.  This means we must unlock before we run GRUB.
# We don't want this b/c then we even need to unlock /boot when we
# are just loading Windows.  This also implies that the current
# implementation has the `luks`, `cryptodisk` and any other
# GRUB modules required to the unlock the /boot partition baked
# into the GRUB executable since there currently is no modules
# (x86_64-efi) directory on the EFI SP partition:
# 
#  root@mmlenovo:/boot/grub# ls -al /boot/efi/EFI/ubuntu/
#  total 4200
#  drwx------ 2 root root    4096 May  8 22:16 .
#  drwx------ 7 root root    4096 May  8 20:40 ..
#  -rwx------ 1 root root     108 May  8 20:40 BOOTX64.CSV
#  -rwx------ 1 root root     204 May  8 20:40 grub.cfg
#  -rwx------ 1 root root 1677176 May  8 20:40 grubx64.efi
#  -rwx------ 1 root root 1269496 May  8 20:40 mmx64.efi
#  -rwx------ 1 root root 1334816 May  8 20:40 shimx64.efi
#
#--------------------------------------------------------
# List of current modules used in /boot/grub/grub.cfg
#-------------------------------------------------------
#  root@mmlenovo:/boot/grub# cat grub.cfg |grep insmod|sed -E "s/^[ \t]*(.*)/\1/g"|sort |uniq

#  if [ x$grub_platform = xxen ]; then insmod xzio; insmod lzopio; fi
#  insmod all_video
#  insmod cryptodisk
#  insmod efi_gop
#  insmod efi_uga
#  insmod ext2
#  insmod fat
#  insmod gcry_rijndael
#  insmod gcry_sha256
#  insmod gettext
#  insmod gfxterm
#  insmod gzio
#  insmod ieee1275_fb
#  insmod luks
#  insmod lvm
#  insmod part_gpt
#  insmod vbe
#  insmod vga
#  insmod video_bochs
#  insmod video_cirrus


BOOTLOADER_ID=mmubuntu
EFI_HOME=/boot/efi/EFI/${BOOTLOADER_ID}

EFI_ROOT_GRUB_DIR=${EFI_HOME}/grub
EFI_ROOT_GRUB_CFG=${EFI_HOME}/grub.cfg

mkdir -p ${EFI_ROOT_GRUB_DIR}


function copy_current_ubuntu_efi_executables() { 
  echo -e "\n----[Copy current Ubuntu efi executables to new EFI root]------------"

  # Copy EFI/ubuntu/(*.efi;.CSV) files to new EFI root
  cp /boot/efi/EFI/ubuntu/*.efi       ${EFI_HOME}/
  cp /boot/efi/EFI/ubuntu/BOOTX64.CSV ${EFI_HOME}/
}

function copy_current_boot_grub_config() {
  echo -e "\n----[Copy current /boot/grub/grub.cfg to new EFI root]-----------------"

  # Copy /boot/grub/grub.cfg and /boot/grub modules dir to new EFI root
  cp    /boot/grub/grub.cfg   ${EFI_ROOT_GRUB_DIR}/
#  cp -r /boot/grub/x86_64-efi ${EFI_ROOT_GRUB_DIR}/
}

function create_bootstrap_efi_grub_config() {
  echo -e "\n----[Creat new GRUB EFI bootstrap config]-----------------"

#----------------------------------------------------------
# Current contents of /boot/efi/EFI/ubuntu/grub.cfg:
#----------------------------------------------------------
#   root@mmlenovo:/boot/grub# cat /boot/efi/EFI/ubuntu/grub.cfg 
#
#   cryptomount -u 456445a8131b4f5aa72319b4f26d3021
#   search.fs_uuid 6a973378-184a-4259-9cd3-df8c59e2cc71 root cryptouuid/456445a8131b4f5aa72319b4f26d3021 
#   set prefix=($root)'/grub'
#   configfile $prefix/grub.cfg

# Create "chain-loading" GRUB config file to boot real GRUB config file
# to replace the current above file:

cat > ${EFI_ROOT_GRUB_CFG} <<END
search.fs_uuid 12C0-AF1E root
set prefix=($root)'/EFI/ubuntu/grub'
configfile $prefix/grub.cfg
END
}

function create_new_efi_boot_entry() {
  echo -e "\n----[Creat new EFI boot entry]-----------------"

  efibootmgr -c -d /dev/nvme0n1 -p 1 -L $BOOTLOADER_ID -l \\EFI\\${BOOTLOADER_ID}\\shimx64.efi
}

copy_current_ubuntu_efi_executables
copy_current_boot_grub_config
create_bootstrap_efi_grub_config
create_new_efi_boot_entry

