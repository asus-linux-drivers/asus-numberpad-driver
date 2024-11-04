#!/usr/bin/env bash

source non_sudo_check.sh

echo $INSTALL_UDEV_DIR_PATH

sudo rm -f $INSTALL_UDEV_DIR_PATH/rules.d/99-asus-numberpad-driver-uinput.rules

if [[ $? != 0 ]]; then
    echo "Something went wrong when removing the uinput udev rule"
fi

sudo rm -f $INSTALL_UDEV_DIR_PATH/rules.d/99-asus-numberpad-driver-i2c-dev.rules
if [[ $? != 0 ]]; then
    echo "Something went wrong when removing the i2c-dev udev rule"
fi

sudo rm -f /etc/modules-load.d/uinput-asus-numberpad-driver.conf
if [[ $? != 0 ]]; then
    echo "Something went wrong when removing the uinput conf"
fi

sudo udevadm control --reload-rules && sudo udevadm trigger --sysname-match=uinput

if [[ $? != 0 ]]; then
    echo "Something went wrong when reloading or triggering uinput udev rules"
else
    echo "Udev rules reloaded and triggered"
fi