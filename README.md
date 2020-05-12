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
