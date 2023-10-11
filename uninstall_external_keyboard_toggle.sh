#!/bin/bash

source non_sudo_check.sh

# INHERIT VARS
INSTALL_DIR_PATH="/usr/share/asus-numberpad-driver"

sudo rm -f "$INSTALL_DIR_PATH/udev/external_keyboard_is_connected.sh"
sudo rm -f "$INSTALL_DIR_PATH/udev/external_keyboard_is_disconnected.sh"

sudo rm -f /usr/lib/udev/rules.d/90-numberpad-external-keyboard.rules
if [[ $? != 0 ]]
then
	echo "/usr/lib/udev/rules.d/90-numberpad-external-keyboard.rules cannot be removed"
else
    echo "Rule 90-numberpad-external-keyboard.rules removed"
fi