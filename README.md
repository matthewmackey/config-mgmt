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
* Install pomodoro timer and fix sound w/ 'sudo apt install sox'
* Install Cinnamon
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

# HP Tower Notes
* On `mmhp` I did the following:
  - Installed Ubuntu updates offered by OS right after new install
  - Installed `openssh-server`

Installing the SSH server is a pre-req to getting ansible to configure the machine
the rest of the way.  The post-install, immediately available updates can probably
be done via ansible instead of directly on the machine.  I just did them via the GUI
that popped up right after the first boot into the system when I logged in for the
1st time to install the SSH server.
