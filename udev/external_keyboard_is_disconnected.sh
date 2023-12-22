#!/usr/bin/env bash

sed -i 's/sys_numlock_enables_numpad.*/sys_numlock_enables_numpad = 1/g' $CONFIG_FILE_PATH
sed -i 's/numpad_disables_sys_numlock.*/numpad_disables_sys_numlock = 1/g' $CONFIG_FILE_PATH