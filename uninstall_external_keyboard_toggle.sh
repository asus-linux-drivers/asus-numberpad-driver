#!/usr/bin/env bash

source non_sudo_check.sh

# ENV VARS
if [ -z "$INSTALL_DIR_PATH" ]; then
    INSTALL_DIR_PATH="/usr/share/asus-numberpad-driver"
fi
if [ -z "$INSTALL_UDEV_DIR_PATH" ]; then
    INSTALL_UDEV_DIR_PATH="/usr/lib/udev"
fi

sudo rm -f "$INSTALL_DIR_PATH/udev/external_keyboard_is_connected.sh"
sudo rm -f "$INSTALL_DIR_PATH/udev/external_keyboard_is_disconnected.sh"

sudo rm -f $INSTALL_UDEV_DIR_PATH/rules.d/90-numberpad-external-keyboard.rules
if [[ $? != 0 ]]
then
	echo "$INSTALL_UDEV_DIR_PATH/rules.d/90-numberpad-external-keyboard.rules cannot be removed"
else
    echo "Rule 90-numberpad-external-keyboard.rules removed"
fi

sudo udevadm control --reload-rules && sudo udevadm trigger

if [[ $? != 0 ]]; then
    echo "Something went wrong when reloading or triggering udev rules"
    exit 1
else
    echo "Udev rules reloaded and triggered"
fi