#!/bin/sh

set -e

install_kubectx() {
  # Install kubectx
  if [ ! -f ~/bin/kubectx -a ! -f ~/bin/kubens ]; then
    curl -L https://github.com/ahmetb/kubectx/releases/download/v0.9.4/kubectx_v0.9.4_linux_x86_64.tar.gz -o /tmp/kubectx-0.9.4.tar.gz
    curl -L https://github.com/ahmetb/kubectx/releases/download/v0.9.4/kubens_v0.9.4_linux_x86_64.tar.gz -o /tmp/kubens-0.9.4.tar.gz
    {
      cd ~/bin
      tar xzf /tmp/kubectx-0.9.4.tar.gz
      tar xzf /tmp/kubens-0.9.4.tar.gz
      rm LICENSE
    }
  fi
}

#-------------------------------#
# MAIN                          #
#-------------------------------#

# NOT for remote machines - TODO figure out how to flag when to run these
#./ssh/install.sh
