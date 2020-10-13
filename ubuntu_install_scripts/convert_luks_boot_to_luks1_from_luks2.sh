#------------------------------------------------------------------------------
# This is if you accidentally make the boot drive LUKS2 instead of LUKS1.
# GRUB can only read LUKS1
#------------------------------------------------------------------------------

# root@ubuntu:~/pc-setup# cryptsetup luksDump /dev/nvme0n1p5|grep PBKDF
#        PBKDF:      argon2i
#        PBKDF:      argon2i

# Convert key with passphrase
cryptsetup luksConvertKey --pbkdf=pbkdf2 /dev/nvme0n1p5

# root@ubuntu:~/pc-setup# cryptsetup luksDump /dev/nvme0n1p5|grep PBKDF
#        PBKDF:      pbkdf2
#        PBKDF:      argon2i

# Convert key with keyfile
cryptsetup luksConvertKey  --pbkdf=pbkdf2 --key-file /target/etc/luks/boot_os.keyfile /dev/nvme0n1p5
# root@ubuntu:~/pc-setup# cryptsetup luksDump /dev/nvme0n1p5|grep PBKDF
#        PBKDF:      pbkdf2
#        PBKDF:      pbkdf2


umount /target/boot/efi
umount /target/boot
cryptsetup close /dev/mapper/boot_crypt
cryptsetup convert --type=luks1 /dev/nvme0n1p5

# Verify key w/ passphrase still works
cryptsetup open --test-passphrase /dev/nvme0n1p5 boot_crypt
echo $?

# Verify key w/ keyfile still works
cryptsetup open --test-passphrase --key-file /target/etc/luks/boot_os.keyfile /dev/nvme0n1p5 boot_crypt
echo $?
