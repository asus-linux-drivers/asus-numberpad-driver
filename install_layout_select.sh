#!/bin/bash

source non_sudo_check.sh

DEVICE_ID=$(cat /proc/bus/input/devices | grep ".*Touchpad\"$" | sort | cut -f 3 -d" " | cut -f 2 -d ":" | head -1)

if [ -z "$LAYOUT_NAME" ]; then
    echo
    echo "Is recommended layout wrong please? Please create an issue (https://github.com/asus-linux-drivers/asus-numberpad-driver/issues)."
    echo
    echo "NumberPad layout"
    echo
    echo "Are predefined 2 variants of numberpad layouts for each laptop:"
    echo " - Standard is recommended to use, the keys except percent and hash tag are send directly but layout is not resistant to overbinding these keys to something else and that is reason why exist second version"
    echo " - Unicode send keys like unicode chars except backspace and enter using shortcut Ctrl+Shift+U+<sequence of number keys>."
    echo
    echo "Select layout:"
    echo
    PS3="Please enter your choice "
    OPTIONS=($(ls layouts) "Quit")
    select SELECTED_OPT in "${OPTIONS[@]}"; do
        if [ "$SELECTED_OPT" = "Quit" ]; then
            exit 0
        fi

        for OPTION in $(ls layouts); do
            if [ "$OPTION" = "$SELECTED_OPT" ]; then
                LAYOUT_NAME=${SELECTED_OPT::-3}
                break
            fi
        done

        if [ -z "$LAYOUT_NAME" ]; then
            echo "invalid option $REPLY"
        else
            break
        fi
    done
fi

echo

SPECIFIC_BRIGHTNESS_VALUES="$LAYOUT_NAME-$DEVICE_ID"
if [ -f "layouts/$SPECIFIC_BRIGHTNESS_VALUES.py" ];
then
    LAYOUT_NAME=$SPECIFIC_BRIGHTNESS_VALUES
    echo "Selected key layout specified by touchpad ID: $DEVICE_ID"
fi

echo "Selected key layout: $LAYOUT_NAME"