#!/bin/bash
set -e
set -o pipefail

while [ ! -d /target/etc/default/grub.d ]; do
  sleep 1;
done

echo "GRUB_ENABLE_CRYPTODISK=y" >> /target/etc/default/grub.d/local.cfg

echo "SUCCESS - GRUB config setup for installer"
