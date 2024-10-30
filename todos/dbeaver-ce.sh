#!/bin/bash
# This https://dbeaver.io/files/dbeaver-ce_latest_amd64.deb redirects one or more times to a versioned URL like:
#   https://github.com/dbeaver/dbeaver/releases/download/24.2.1/dbeaver-ce_24.2.1_amd64.deb

URL=https://github.com/dbeaver/dbeaver/releases/download/24.2.1/dbeaver-ce_24.2.1_amd64.deb
FILE=~/downloads/debs/dbeaver-ce_24.2.1_amd64.deb

# Need the -k b/c curl does not accept the SSL cert from dbeaver.io (Chrome does though)
curl -Lk -o "$FILE" "$URL"
sudo dpkg -i "$FILE"
