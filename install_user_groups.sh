#!/bin/bash

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

echo 'KERNEL=="uinput", GROUP="uinput", MODE:="0660"' | sudo tee /etc/udev/rules.d/99-input.rules >/dev/null

sudo udevadm control --reload-rules

if [[ $? != 0 ]]; then
    echo "Something went wrong when reloading udev rules"
fi