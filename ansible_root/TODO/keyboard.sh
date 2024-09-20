#!/bin/bash


# Install dconf-editor - GUI view of dconf stuff
# sudo apt install dconf-editor


# Disable Alt+Click window drag (useful for CAD mouse usage)
#
# See: https://askubuntu.com/questions/521423/how-can-i-disable-altclick-window-dragging
#
# For Cinnamon, the first command below does NOT work.  YOu need to use the 2nd
# command which is the equivalent of opening "System Settings > Preferences.Window > Behavior"
# and changing the key there:
#
# Gnome:
# gsettings set org.gnome.desktop.wm.preferences mouse-button-modifier '<Alt>'

# Cinnamon:
gsettings set org.cinnamon.desktop.wm.preferences mouse-button-modifier '<Super>'
