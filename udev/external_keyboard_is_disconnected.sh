#!/bin/bash

sed -i 's/sys_numlock_enables_numpad.*/sys_numlock_enables_numpad = 1/g' $CONFIG_FILE_DIR/asus_touchpad_numpad_dev
sed -i 's/numpad_disables_sys_numlock.*/numpad_disables_sys_numlock = 1/g' $CONFIG_FILE_DIR/asus_touchpad_numpad_dev