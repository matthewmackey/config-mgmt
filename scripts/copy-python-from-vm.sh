#!/bin/bash

HOST=$1
PYTHON_VERSION=$2

if [ -z "$HOST" -o -z "$PYTHON_VERSION" ]; then
  echo "You must supply: HOST PYTHON_VERSION"
  exit 1
fi

OS_FAMILY=ubuntu
OS_VERSION=22.04

REMOTE_PYTHONS_DIR=~/pythons
REMOTE_TAR_FILE=$REMOTE_PYTHONS_DIR/python-${PYTHON_VERSION}-${OS_FAMILY}-${OS_VERSION}.tar.gz

LOCAL_DEST_DIR=~/.personal/config-mgmt/ansible_root/files


ssh $HOST tar czf $REMOTE_TAR_FILE -C $REMOTE_PYTHONS_DIR $PYTHON_VERSION
scp $HOST:$REMOTE_TAR_FILE $LOCAL_DEST_DIR
