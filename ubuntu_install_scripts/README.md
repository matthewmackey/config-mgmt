# Setup Fresh Ubuntu System

Steps:

1. Create setup.env
2. Run `pre_os-setup_partitions.sh`
3. Run `pre_os-setup_installer.sh`

- This setups GRUB config so installer setups /boot correctly

5. Start Ubuntu GUI Installer and install OS
6. Run `post_os-setup_chroot.sh`

- Sets up chroot mounts
- Mounts 'inside_chroot' script and related files into the CHROOT_MNT
  directory so that the scripts can be run once we have entered the chroot

8. Run `post_os-inside_chroot.sh`

- Run steps inside the chroot environment that will finish setting up the
  full-disk encryption (ie - create LUKS key files, setup /etc/crypttab, etc.)
