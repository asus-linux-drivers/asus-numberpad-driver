#!/usr/bin/env bash

source non_sudo_check.sh

DEVICE_ID=$(cat /proc/bus/input/devices | grep ".*Touchpad\"$" | sort | cut -f 3 -d" " | cut -f 2 -d ":" | head -1)

if [ -z "$LAYOUT_NAME" ]; then
    echo
    echo "Is recommended layout wrong please? Please create an issue (https://github.com/asus-linux-drivers/asus-numberpad-driver/issues)."
    echo
    echo "NumberPad layout"
    echo
    echo "Are predefined 3 variants of numberpad layouts for each laptop:"
    echo " - Non unicode variant does not send any character via shortcut Ctrl+Shift+U. Uses numeric keys and key combinations (Shift + number) for percent and hashtag characters. Because of this is vulnerable to overbindings (custom overbindings any key which is used in layout or is enough change to other language keyboard layout e.g. French). Recommended when you use only lang layouts where can be percent, hashtag char printed via Shift+5/3 and you do not have overbinded any key used in layout (manual change overbinded key directly in layout can anyway make this layout usable)"
    echo " - Standard (without unicode and non-unicode postfix). The keys except percent and hashtag characters (these 2 uses unicode Ctrl+Shift+U shortcut) are send directly so is not vulnerable when is changed lang keyboard layout (to e.g. French) but layout at all is still not resistant to overbinding other keys to something else and that is reason why exist last variant"
    echo " - Last unicode variant send keys like unicode chars except backspace and enter using shortcut Ctrl+Shift+U+<sequence of number keys>. Is resistant to overbinding any key or lang layout change (to e.g. French) but sending multiple keys instead of one, max. 2 can be overkill if you do not need it."
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