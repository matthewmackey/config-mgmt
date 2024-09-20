#!/bin/bash

set -e
set -o pipefail

if [ "$EUID" -ne 0 ]; then
  echo "Please run as root"
  exit
fi

echo "Waiting for Installer to mount filesystem at /target..."

while [ ! -d /target/etc/default/grub.d ]; do
  sleep 1;
done

echo "GRUB_ENABLE_CRYPTODISK=y" >> /target/etc/default/grub.d/local.cfg

echo "SUCCESS - GRUB config setup for Installer"
