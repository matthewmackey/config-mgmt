#!/bin/bash

set -e
set -o pipefail

if [ "$EUID" -ne 0 ]; then
  echo "Please run as root"
  exit
fi


#-----------------------------------------------------------------------
# Constants
#-----------------------------------------------------------------------
CONSTANTS_ENV_FILE=constants.env

if [ ! -e "$CONSTANTS_ENV_FILE" ]; then
  echo "A \"$CONSTANTS_ENV_FILE\" must be in the same directory as this script"
  exit 1
fi

source $CONSTANTS_ENV_FILE


#-----------------------------------------------------------------------
# MAIN()
#-----------------------------------------------------------------------
ENV_FILE=$1

if [ ! -f "$ENV_FILE" ]; then
  echo "You must provide an ENV_FILE"
  exit 1
fi

# source $ENV_FILE

mount $ROOT_LVM_VOL $CHROOT_MNT

for n in proc sys dev etc/resolv.conf; do
  mount --rbind /$n $CHROOT_MNT/$n
done

# Copy files into the chroot that are needed to finish crypt setup steps
cp $CONSTANTS_ENV_FILE $CHROOT_MNT/tmp/constants.env
cp $ENV_FILE $CHROOT_MNT/tmp/setup.env
cp post_os-inside_chroot.sh $CHROOT_MNT/tmp/post_os-inside_chroot.sh

cat <<-END
  Run the following to enter & finish setting up the chroot environment:

  sudo chroot $CHROOT_MNT
  mount -a

END
