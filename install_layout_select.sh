#!/usr/bin/env bash

source non_sudo_check.sh

DEVICE_ID=$(cat /proc/bus/input/devices | grep ".*Touchpad\"$" | sort | cut -f 3 -d" " | cut -f 2 -d ":" | head -1)

if [ -z "$LAYOUT_NAME" ]; then
    echo
    echo "NumberPad layout"
    echo
    echo "2 variants of NumberPad layouts are predefined for each laptop:"
    echo " - Standard. For all fields of NumberPad layout will try to found appropriate keys that are in success sent. Key modifiers are supported. Is required to have bound used special characters (%, *, #, ., -, +, /) with usual keysym names (percent, asterisk, numbersign, period, minus, plus, slash). When is appropriate key not found than field will be sent using the unicode shortcut (usually Ctrl+Shift+U+<0-F>)."
    echo " - The unicode variant sends special characters (%, #, ., -, +, *, /) using the unicode shortcut (usually Ctrl+Shift+U+<0-F>). This layout allows to have not bound special characters with usual keysyms like percent, asterisk, plus, minus, slash, numbersign. Unnecessarily heavy (number of events sent) if you do not need it."
    echo
    echo "Select layout (photos of NumberPad layouts can be found here https://github.com/asus-linux-drivers/asus-numberpad-driver#layouts):"
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