Setup Fresh Ubuntu System
===========================

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

7. Run `post_os-inside_chroot.sh`

- Run steps inside the chroot environment that will finish setting up the
  full-disk encryption (ie - create LUKS key files, setup /etc/crypttab, etc.)


`autoinstall.yml`
-----------------

This was something that I never got working because it doesn't seem that
Autoinstall has the ability to format the /boot partition as LUKS v1 which is
required for GRUB due to its compatibility issues with LUKS v2.  More reserach
is needed.


OS Versions
===========

Ubuntu 24.04 Issue
------------------

As of 9/19/2024, we cannot use these install scripts with Ubuntu 24.04 because
the new installer that comes with 24.04 (Subiquity) does not show the LVM
partitions in the Manual configuration part of the install where we specify what
mount points go where.  The last LTS release that used the old installer (Ubiquity)
that allowed this behavior was 22.04, so for now we can only install 22.04 with
these installer scripts until either:

  - Subiquity is updated with this feature
  - Autoinstall.yml can allow this (and also allow a fix for the GRUB LUKS v1 problem)


Systems
=======

Dell Precision Tower 5810
-------------------------

We cannot enable Secure Boot in the BIOS b/c the video card we have seems to
require the 'Enable Legacy ROMs' option in the BIOS which you cannot enable
with Secure Boot. This was found out b/c if we do not check the 'Enable Legacy ROMs'
option, then the computer monitor flickers constantly like a strobe light.
