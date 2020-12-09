# About
This repo is for automating the configuration of my Desktop PC
and other machines.

# Bootstrapping a Fresh Install
In order to get a new machine with a fresh Ubuntu install bootstrapped,
all you need to do is execute the following the new machine:

```
sudo apt-get update
sudo apt-get install git
cd ~
git clone https://github.com/matthewmackey/pc-setup.git
cd pc-setup
./bootstrap_ansible.sh
```

# TODO
* Configure Parcellite options
* Configure Cinnamon applet panel size/height & calendar applet settings
* Configure Nemo (file explorer) to "show hidden files" by default
* Configure Nemo "Favorites"
* Install vim plugins
* Install pomodoro timer and fix sound w/ 'sudo apt install sox'
  * Install sounds located at:
    * ~/.local/share/cinnamon/applets/pomodoro@gregfreeman.org/po/pomodoro@gregfreeman.org.pot
* Install JDK's from DEBs
  - create JAVA_HOME
  - create /usr/lib/jvm/DEFAULT symlink
  - add "default" JAVA_HOME/bin to PATH
* Install Android Studio
* Install IntelliJ Ultimate
* Configure date/time appearance in title bar
* Setup Chrome profiles for 3x emails
* Setup SSH keys for github
* Apply any printer configuration possible
* Setup .desktop shortcuts, including:
  - System sound
  - System display
* Setup keyboard shortcuts, including:
  - move windows to display
  - adjust size of windows
* Fix touchpad & scrolling w/ mouse issues
  - "Mouse & Touchpad" cinnamon options GUI in 18.04 now allows this;
    figure out how to do in config files
* Fix mouse wheel scrolling speed and/or disable mouse wheel
* Fix hibernate/suspend issues
* Install Visual Studio Code
  - add/configure plugins
* Install .NET Core SDK (Used by C# VS Code plugin??)
  - https://docs.microsoft.com/en-us/dotnet/core/install/linux-package-manager-ubuntu-1804
* Authorizing thunderbolt 3 dock
  - Set BIOS Thunderbolt 3 Security Level -> "Secure Connect" (not None, User, or DisplayPort and USB)
* Setup Electron versions of things like Trello, Todoist, etc.
* Install Slack - `sudo snap install slack --classic`
* Create method to run "Fullscreen" video on only half the monitor (ie - for YouTube)
* Fix tmux prompt
* Fix lpass `make` tasks that always trigger "changed"

# HP Tower Notes

## Bios/UEFI Notes

The SSD in the HP Tower was formatted with a GPT partition table, however, it
was booted in BIOS mode.  When I took the SSD and put it in the Dell Tower and
put the Dell Tower in Legacy Bios mode, the SSD would not boot.  It had a message
like "No bootable devices found".  When I did some research I found the following
site:

  * http://www.rodsbooks.com/gdisk/bios.html#bios

There he explained that some systems have difficulties, particularly UEFI systems
that boot in Legacy Bios mode, with booting GPT drives in Bios mode.  I solved
the problem I was having using option #1b in that section (setting the `disk
toggle pmbr_boot` flag for the `/dev/sda` drive).  Once I did that the firmware
recognized the 2MB Bios boot partion at `/dev/sda1` and the system booted.

See here for more on what a Bios Boot Partition is:

  * https://en.wikipedia.org/wiki/BIOS_boot_partition

### HP / Dell Tower SSD Drive Layout

```
mmachaj@mmhp:~$ date
Tue 08 Dec 2020 09:53:08 PM EST

mmachaj@mmhp:~$ sudo parted /dev/sda
GNU Parted 3.3
Using /dev/sda
Welcome to GNU Parted! Type 'help' to view a list of commands.
(parted) print
Model: ATA SanDisk SDSSDA24 (scsi)
Disk /dev/sda: 240GB
Sector size (logical/physical): 512B/512B
Partition Table: gpt
Disk Flags: pmbr_boot

Number  Start   End     Size    File system  Name    Flags
 1      1049kB  3146kB  2097kB               GRUB    bios_grub
 2      3146kB  808MB   805MB                /boot
 3      808MB   240GB   239GB                rootfs

mmachaj@mmhp:~$ sudo sgdisk -p /dev/sda
Disk /dev/sda: 468862128 sectors, 223.6 GiB
Model: SanDisk SDSSDA24
Sector size (logical/physical): 512/512 bytes
Disk identifier (GUID): 6E5749D4-A15B-456F-9891-CCA6603807FB
Partition table holds up to 128 entries
Main partition table begins at sector 2 and ends at sector 33
First usable sector is 34, last usable sector is 468862094
Partitions will be aligned on 2048-sector boundaries
Total free space is 2014 sectors (1007.0 KiB)

Number  Start (sector)    End (sector)  Size       Code  Name
   1            2048            6143   2.0 MiB     EF02  GRUB
   2            6144         1579007   768.0 MiB   8301  /boot
   3         1579008       468862094   222.8 GiB   8301  rootfs

mmachaj@mmhp:~$ lsblk /dev/sda
NAME                  MAJ:MIN RM   SIZE RO TYPE  MOUNTPOINT
sda                     8:0    0 223.6G  0 disk
├─sda1                  8:1    0     2M  0 part
├─sda2                  8:2    0   768M  0 part
│ └─boot_crypt        253:4    0   766M  0 crypt /boot
└─sda3                  8:3    0 222.8G  0 part
  └─rootfs_crypt      253:0    0 222.8G  0 crypt
    ├─ubuntu--vg-swap 253:1    0    12G  0 lvm   [SWAP]
    ├─ubuntu--vg-root 253:2    0    40G  0 lvm   /
    └─ubuntu--vg-home 253:3    0    60G  0 lvm   /home
```

## Post-Install - Originally
* On `mmhp` I did the following:
  - Installed Ubuntu updates offered by OS right after new install
  - Installed `openssh-server`

Installing the SSH server is a pre-req to getting ansible to configure the machine
the rest of the way.  The post-install, immediately available updates can probably
be done via ansible instead of directly on the machine.  I just did them via the GUI
that popped up right after the first boot into the system when I logged in for the
1st time to install the SSH server.
