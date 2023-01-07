#!/bin/bash

NEW_USER=cm
sudo adduser \
  --disabled-password \
  --gecos "Config Management" \
  --home /home/$NEW_USER \
  --shell /bin/zsh \
 $NEW_USER
