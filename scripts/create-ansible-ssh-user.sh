#!/bin/bash

# Bootstrap VMs instead of this script by using vagrant cloud_init
#
# See: https://github.com/matthewmackey/vmtools/tree/main/vagrant
NEW_USER=cm
sudo adduser \
  --disabled-password \
  --gecos "Config Management" \
  --home /home/$NEW_USER \
  --shell /bin/zsh \
 $NEW_USER
