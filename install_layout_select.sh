#!/usr/bin/env bash

source non_sudo_check.sh

DEVICE_ID=$(cat /proc/bus/input/devices | grep ".*Touchpad\"$" | sort | cut -f 3 -d" " | cut -f 2 -d ":" | head -1)

if [ -z "$LAYOUT_NAME" ]; then
    echo
    echo "NumberPad layout"
    echo
    echo "2 variants of NumberPad layouts are predefined for each laptop:"
    echo " - Standard. All keys are sent directly except not found (are defined like percent, numbersign, period etc.), which is why the last unicode variant exists"
    echo " - The unicode variant sends all keys as unicode characters except for BACKSPACE and ENTER. This layout is the most resistant to overbinding of keys but sends multiple keys instead of just one, unnecessarily heavy if you do not need it."
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

if [[ "$DETECTED_LAYOUT_VIA_OFFLINE_TABLE" && "$DETECTED_LAYOUT_VIA_OFFLINE_TABLE" != "$LAYOUT_NAME" ]];
then
    LAYOUT_AUTO_SUGGESTED_DIFFER_FROM_USED=1
fi

SPECIFIC_BRIGHTNESS_VALUES="$LAYOUT_NAME-$DEVICE_ID"
if [ -f "layouts/$SPECIFIC_BRIGHTNESS_VALUES.py" ];
then
    LAYOUT_NAME=$SPECIFIC_BRIGHTNESS_VALUES
    echo "Selected key layout specified by touchpad ID: $DEVICE_ID"
fi

echo "Selected key layout: $LAYOUT_NAME"