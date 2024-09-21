#!/bin/sh

set -o e
asfda
sudo apt-get install \
  python3-cffi        \
  xserver-xorg        \
  python3-xcffib      \
  libwlroots-dev      \
  python3-cairocffi   \
  libpangocairo-1.0-0

sudo pip install --no-cache-dir cairocffi
sudo pip install qtile
