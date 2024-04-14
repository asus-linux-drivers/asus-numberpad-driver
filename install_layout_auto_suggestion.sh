#!/usr/bin/env bash

source non_sudo_check.sh

LAPTOP_NAME_FULL=$(cat /sys/devices/virtual/dmi/id/product_name)
# LAPTOP_NAME_FULL="ROG Zephyrus Duo 15 SE GX551QR_GX551QR"
LAPTOP_NAME=$(echo $LAPTOP_NAME_FULL | rev | cut -d ' ' -f1 | rev | cut -d "_" -f1)
DEVICE_ID=$(cat /proc/bus/input/devices | grep ".*Touchpad\"$" | sort | cut -f 3 -d" " | cut -f 2 -d ":" | head -1)
# DEVICE_ID="3145"
VENDOR_ID=$(cat /proc/bus/input/devices | grep ".*Touchpad\"$" | sort | cut -f 3 -d" " | cut -f 1 -d ":" | head -1)
# VENDOR_ID="04F3"

# the base was provided by cz asus support and manually fixed + manually extended about missing laptops gathered from users by github issues and via GA
SUGGESTED_LAYOUT=$(cat laptop_numberpad_layouts | grep "$LAPTOP_NAME" | head -1 | cut -d'=' -f2)

# gathered from users via GA
if [[ -z "$SUGGESTED_LAYOUT" ]]; then
  SUGGESTED_LAYOUT=$(cat laptop_touchpad_numberpad_layouts.csv | grep "$LAPTOP_NAME_FULL" | sort -t , -k 6 -r | head -1 | cut -d',' -f4)
else
  LAYOUT_AUTO_SUGGESTION_OFFLINE_FOUND_BY_LAPTOP_NAME=1
fi
if [[ -z "$SUGGESTED_LAYOUT" ]]; then
  SUGGESTED_LAYOUT=$(cat laptop_touchpad_numberpad_layouts.csv | grep "$VENDOR_ID" | grep "$DEVICE_ID" | sort -t , -k 6 -r | head -1 | cut -d',' -f4)
else
  LAYOUT_AUTO_SUGGESTION_OFFLINE_FOUND_BY_LAPTOP_NAME_FULL=1
fi

if [[ -z "$SUGGESTED_LAYOUT" || "$SUGGESTED_LAYOUT" == "none" ]]; then

    LAYOUT_AUTO_SUGGESTION_ONLINE=1

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

    # Probes identified by touchpad's VENDOR_ID & PRODUCT_ID may return probes grouped under multiple devices:
    #
    # e.g. returned ELAN, ASUE: https://linux-hardware.org/?view=search&vendorid=04F3&deviceid=3101&typeid=input%2Fkeyboard
    #
    # /?id=ps/2:04f3-3101-elan1406-00-04f3-3101-keyboard
    # /?id=ps/2:04f3-3101-asue1406-00-04f3-3101-keyboard
    DEVICE_URL_LIST=$(echo $DEVICE_LIST_CURL | xmllint --html --xpath '//td[@class="device"]//a[1]/@href' 2>/dev/null -)

    IFS='\"' read -r -a array <<< $(echo $DEVICE_URL_LIST)
    for INDEX in "${!array[@]}"
    do
      if [[ "${array[INDEX]}" != " href=" && "${array[INDEX]}" != "href=" ]]; then

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
            PROBE_LAPTOP_NAME_FULL="${array[INDEX]}"
            PROBE_LAPTOP_NAME=$( echo $PROBE_LAPTOP_NAME_FULL | rev | cut -d ' ' -f1 | rev | cut -d "_" -f1)

            SUGGESTED_LAYOUT=$(cat laptop_numberpad_layouts | grep "$PROBE_LAPTOP_NAME" | head -1 | cut -d'=' -f2)
            if [[ -z "$SUGGESTED_LAYOUT" ]]; then
              SUGGESTED_LAYOUT=$(cat laptop_touchpad_numberpad_layouts.csv | grep "$PROBE_LAPTOP_NAME_FULL" | head -1 | cut -d',' -f4)
            else
              LAYOUT_AUTO_SUGGESTION_ONLINE_FOUND_BY_LAPTOP_NAME=1
            fi
            if [[ -z "$SUGGESTED_LAYOUT" || "$SUGGESTED_LAYOUT" == "none" ]]; then
              continue
            else
              LAYOUT_AUTO_SUGGESTION_ONLINE_FOUND_BY_LAPTOP_NAME_FULL=1
              break
            fi
          fi
        done
      fi
    done

    if [[ -z "$SUGGESTED_LAYOUT" || "$SUGGESTED_LAYOUT" == "none" ]]; then
        echo
        echo "Could not automatically detect NumberPad layout for your laptop."
    else
        LAYOUT_AUTO_SUGGESTION_ONLINE_FOUND=1
    fi
else
  LAYOUT_AUTO_SUGGESTION_OFFLINE_FOUND=1
  LAYOUT_AUTO_SUGGESTION_OFFLINE_FOUND_BY_VENDOR_DEVICE_ID=1
fi

for OPTION in $(ls layouts); do
    if [ "$OPTION" = "$SUGGESTED_LAYOUT.py" ]; then
        echo
        echo "NumberPad layout"
        echo
        read -r -p "Automatically recommended NumberPad layout for laptop $LAPTOP_NAME_FULL is $SUGGESTED_LAYOUT. Do you want to use $SUGGESTED_LAYOUT? (photo of recommended NumberPad layout can be found here https://github.com/asus-linux-drivers/asus-numberpad-driver#$SUGGESTED_LAYOUT) [y/N]" RESPONSE
        case "$RESPONSE" in [yY][eE][sS]|[yY])

            echo

            LAYOUT_AUTO_SUGGESTION=1

            LAYOUT_NAME=$SUGGESTED_LAYOUT

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