#!/usr/bin/env bash

source non_sudo_check.sh

sudo groupadd "input"
sudo groupadd "i2c"
sudo groupadd "uinput"

sudo usermod -a -G "i2c,input,uinput,numberpad" $USER

if [[ $? != 0 ]]; then
    echo "Something went wrong when adding the groups to current user"
    exit 1
else
    echo "Added groups input, i2c, uinput, numberpad to current user"
fi

sudo modprobe uinput

# check if the uinput module is successfully loaded
if [[ $? != 0 ]]; then
    echo "uinput module cannot be loaded"
    exit 1
else
    echo "uinput module loaded"
fi

sudo modprobe i2c-dev

# check if the i2c-dev module is successfully loaded
if [[ $? != 0 ]]; then
    echo "i2c-dev module cannot be loaded. Make sure you have installed i2c-tools package"
    exit 1
else
    echo "i2c-dev module loaded"
fi

echo 'KERNEL=="uinput", GROUP="uinput", MODE="0660"' | sudo tee /usr/lib/udev/rules.d/99-asus-numberpad-driver-uinput.rules >/dev/null
echo 'uinput' | sudo tee /etc/modules-load.d/uinput-asus-numberpad-driver.conf >/dev/null
echo 'SUBSYSTEM=="i2c-dev", GROUP="i2c", MODE="0660"' | sudo tee /usr/lib/udev/rules.d/99-asus-numberpad-driver-i2c-dev.rules >/dev/null
echo "i2c-dev" | sudo tee /etc/modules-load.d/i2c-dev-asus-numberpad-driver.conf >/dev/null

if [[ $? != 0 ]]; then
    echo "Something went wrong when adding uinput module to auto loaded modules"
    exit 1
else
    echo "uinput module added to auto loaded modules"
fi

sudo udevadm control --reload-rules && sudo udevadm trigger --sysname-match=uinput && sudo udevadm trigger --attr-match=subsystem=i2c-dev

if [[ $? != 0 ]]; then
    echo "Something went wrong when reloading or triggering uinput udev rules"
else
    echo "Udev rules reloaded and triggered"
fi