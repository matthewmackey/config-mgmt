#!/bin/bash

set -e
set -o pipefail

mkdir -p ~/.local/kitty
cd ~/.local/kitty

if [ ! -f ~/downloads/srv/kitty-0.23.1-x86_64.txz ]; then
  curl -L https://github.com/kovidgoyal/kitty/releases/download/v0.23.1/kitty-0.23.1-x86_64.txz \
    -o ~/downloads/srv/kitty-0.23.1-x86_64.txz

  tar -xJf ~/downloads/srv/kitty-0.23.1-x86_64.txz
fi

# Create a symbolic link to add kitty to PATH (assuming ~/.local/bin is in
# your PATH)
test -L ~/.local/bin/kitty || ln -s ~/.local/kitty/bin/kitty ~/.local/bin/

# Place the kitty.desktop file somewhere it can be found by the OS
#
# NOT symlink b/c sed command edits the file and we don't want to edit the kitty
# source code
test -f ~/.local/share/applications/kitty.desktop || cp ~/.local/kitty/share/applications/kitty.desktop ~/.local/share/applications/

# Update the path to the kitty icon in the kitty.desktop file
sed -i "s|Icon=kitty|Icon=/home/$USER/.local/kitty/share/icons/hicolor/256x256/apps/kitty.png|g" ~/.local/share/applications/kitty.desktop
