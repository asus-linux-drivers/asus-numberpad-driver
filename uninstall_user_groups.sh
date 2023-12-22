#!/usr/bin/env bash

source non_sudo_check.sh

sudo rm -f /etc/udev/rules.d/99-input.rules

if [[ $? != 0 ]]; then
    echo "Something went wrong when removing the input udev rule"
    exit 1
fi

sudo udevadm control --reload-rules

if [[ $? != 0 ]]; then
    echo "Something went wrong when reloading udev rules"
    exit 1
else
    echo "Udev rules reloaded"
fi