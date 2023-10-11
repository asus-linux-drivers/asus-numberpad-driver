#!/bin/bash

source non_sudo_check.sh

LAPTOP_NAME=$(sudo dmidecode -s system-product-name | rev | cut -d ' ' -f1 | rev | cut -d "_" -f1)
LAPTOP_NAME_FULL=$(sudo dmidecode -s system-product-name)

DETECTED_LAPTOP_VIA_OFFLINE_TABLE=$(cat laptop_numberpad_layouts | grep $LAPTOP_NAME | head -1 | cut -d'=' -f1)
DETECTED_LAYOUT_VIA_OFFLINE_TABLE=$(cat laptop_numberpad_layouts | grep $LAPTOP_NAME | head -1 | cut -d'=' -f2)

DEVICE_ID=$(cat /proc/bus/input/devices | grep ".*Touchpad\"$" | sort | cut -f 3 -d" " | cut -f 2 -d ":" | head -1)

if [[ -z "$DETECTED_LAYOUT_VIA_OFFLINE_TABLE" || "$DETECTED_LAYOUT_VIA_OFFLINE_TABLE" == "none" ]]; then

    VENDOR_ID=$(cat /proc/bus/input/devices | grep ".*Touchpad\"$" | sort | cut -f 3 -d" " | cut -f 1 -d ":" | head -1)

    # When exist device 9009:00 should return other DEVICE_ID: 3101 of 'ELAN1406:00'
    #
    # https://github.com/mohamed-badaoui/asus-touchpad-numpad-driver/issues/87
    # https://github.com/asus-linux-drivers/asus-numberpad-driver/issues/95
    #
    # N: Name="ELAN9009:00 04F3:2C23 Touchpad"
    # N: Name="ELAN1406:00 04F3:3101 Touchpad"

    USER_AGENT="user-agent-name-here"
    DEVICE_LIST_CURL_URL="https://linux-hardware.org/?view=search&vendorid=$VENDOR_ID&deviceid=$DEVICE_ID&typeid=input%2Fkeyboard"
    DEVICE_LIST_CURL=$(curl --user-agent "$USER_AGENT" "$DEVICE_LIST_CURL_URL" )
    DEVICE_URL=$(echo $DEVICE_LIST_CURL | xmllint --html --xpath '//td[@class="device"]//a[1]/@href' 2>/dev/null - | cut -f2 -d"\"")
    LAPTOP_LIST_CURL_URL="https://linux-hardware.org$DEVICE_URL"
    LAPTOP_LIST_CURL=$(curl --user-agent "$USER_AGENT" "$LAPTOP_LIST_CURL_URL" )
    LAPTOP_LIST=$(echo $LAPTOP_LIST_CURL | xmllint --html --xpath '//table[contains(@class, "computers_list")]//tr/td[3]/span/@title' 2>/dev/null -)

    # create laptop array
    #
    # [0] = Zenbook UX3402ZA_UX3402ZA
    # [1] = Zenbook UM5401QAB_UM5401QA
    # ...
    #
    IFS='\"' read -r -a array <<< $(echo $LAPTOP_LIST)
    for INDEX in "${!array[@]}"
    do
        if [[ "${array[INDEX]}" != " title=" && "${array[INDEX]}" != "title=" ]]; then
            LAPTOP_NAME="${array[INDEX]}"

            PROBE_LAPTOP=$( echo $LAPTOP_NAME | rev | cut -d ' ' -f1 | rev | cut -d "_" -f1)

            DETECTED_LAPTOP_VIA_OFFLINE_TABLE=$(cat laptop_numberpad_layouts | grep $PROBE_LAPTOP | head -1 | cut -d'=' -f1)
            DETECTED_LAYOUT_VIA_OFFLINE_TABLE=$(cat laptop_numberpad__layouts | grep $PROBE_LAPTOP | head -1 | cut -d'=' -f2)

            if [[ -z "$DETECTED_LAYOUT_VIA_OFFLINE_TABLE" || "$DETECTED_LAYOUT_VIA_OFFLINE_TABLE" == "none" ]]; then
                continue
            else
                break
            fi
        fi
    done

    if [[ -z "$DETECTED_LAYOUT_VIA_OFFLINE_TABLE" || "$DETECTED_LAYOUT_VIA_OFFLINE_TABLE" == "none" ]]; then
        echo "Could not automatically detect numberpad layout for your laptop. Please create an issue (https://github.com/asus-linux-drivers/asus-numberpad-driver/issues)."
    fi
fi

for OPTION in $(ls layouts); do
    if [ "$OPTION" = "$DETECTED_LAYOUT_VIA_OFFLINE_TABLE.py" ]; then   
        echo "NumberPad layout"
        echo
        echo "Are predefined 2 variants of numberpad layouts for each laptop:"
        echo " - Standard is recommended to use, the keys except percent and hash tag are send directly but layout is not resistant to overbinding these keys to something else and that is reason why exist second version"
        echo " - Unicode send keys like unicode chars except backspace and enter using shortcut Ctrl+Shift+U+<sequence of number keys>."
        echo
        read -r -p "Automatically recommended numberpad layout for detected laptop: $LAPTOP_NAME_FULL is standard: $DETECTED_LAYOUT_VIA_OFFLINE_TABLE (associated to $DETECTED_LAPTOP_VIA_OFFLINE_TABLE). Do you want to use? [y/N]" RESPONSE
        case "$RESPONSE" in [yY][eE][sS]|[yY])

            echo

            LAYOUT_NAME=$DETECTED_LAYOUT_VIA_OFFLINE_TABLE

            SPECIFIC_BRIGHTNESS_VALUES="$LAYOUT_NAME-$DEVICE_ID"
            if [ -f "layouts/$SPECIFIC_BRIGHTNESS_VALUES.py" ];
            then
                LAYOUT_NAME=$SPECIFIC_BRIGHTNESS_VALUES
                echo "Selected key layout specified by touchpad ID: $DEVICE_ID"
            fi

            echo "Selected key layout: $LAYOUT_NAME"
            ;;
        *)
            ;;
        esac
    fi
done