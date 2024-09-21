#!/bin/bash

# SEE:
# https://askubuntu.com/questions/1419142/how-to-create-a-desktop-launcher-for-the-latest-freecad-appimage-in-ubuntu-20


# (1) Create ~/.apps if not exist
# (2)Download AppImage to ~/.apps
# ie - https://github.com/FreeCAD/FreeCAD/releases


ln -s ~/.apps/Free*.appimage ~/.local/bin/freecad
# mkdir ~/.local/share/icons/freecad/
curl https://raw.githubusercontent.com/FreeCAD/FreeCAD/0.21.2/src/Gui/Icons/freecad.svg \
    > ~/.local/share/icons/freecad.svg

cat <<EOF > ~/.local/share/applications/freecad.desktop
[Desktop Entry]
Version=0.21.2
Name=FreeCAD
Exec=freecad
Icon=freecad
Type=Application
Categories=Engineering;
Comment=Feature based Parametric Modeler
Terminal=false
StartupNotify=true
NoDisplay=false
MimeType=application/x-extension-fcstd;
EOF
