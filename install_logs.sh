#!/usr/bin/env bash

source non_sudo_check.sh

# INHERIT
if [ -z "$LOGS_DIR_PATH" ]; then
    LOGS_DIR_PATH="/var/log/asus-numberpad-driver"
fi

sudo groupadd "numberpad"

sudo usermod -a -G "numberpad" $USER

if [[ $? != 0 ]]; then
    echo "Something went wrong when adding the group numberpad to current user"
    exit 1
else
    echo "Added group numberpad to current user"
fi

sudo mkdir -p "$LOGS_DIR_PATH"
sudo chown -R :numberpad "$LOGS_DIR_PATH"
sudo chmod -R g+w "$LOGS_DIR_PATH"