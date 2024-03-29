#!/usr/bin/env bash

G_ID="G-R95GXWFECL"
API_SECRET="1FTfPGoRTDCmK4Outb-4nQ"
CLIENT_ID="365831413.1708860375"
USER_ID=$(sudo cat /sys/class/dmi/id/product_uuid)
EVENT_NAME="install_finished"
LAPTOP_ID=$(sudo cat /sys/class/dmi/id/product_uuid)

# finished
INSTALL_DURATION=$(bc -l <<<"($END_TIME - $START_TIME)")

# $SUGGESTED_LAYOUT
# $LAYOUT_NAME
# $CALC_TOGGLE
# $CALC_TOGGLE_SUPPORTED_CALC
# $POWER_SUPPLY_SAVER
# $EXTERNAL_KEYBOARD_TOGGLE
# $SERVICE
# $LAYOUT_AUTO_SUGGESTION
# $LAYOUT_AUTO_SUGGESTED_DIFFER_FROM_USED
# $LAYOUT_AUTO_SUGGESTION_ONLINE
# $LAYOUT_AUTO_SUGGESTION_ONLINE_FOUND
LAPTOP=$(cat /sys/devices/virtual/dmi/id/product_name)
TOUCHPAD=$(cat /proc/bus/input/devices | grep ".*Touchpad\"$" | sort | cut -f 2 -d'"' | head -1)
DRIVER_VERSION=$(git fetch --tags && git describe --tags --abbrev=0)

CURL_PAYLOAD='{
    "client_id": "'${CLIENT_ID}'",
    "user_id": "'${LAPTOP_ID}'",
    "non_personalized_ads": true,
    "events": [
        {
            "name": "'${EVENT_NAME}'",
            "params": {
                "laptop_id": "'${LAPTOP_ID}'",
                "layout_recommended": "'${SUGGESTED_LAYOUT}'",
                "layout_recommended_installed": "'${LAYOUT_AUTO_SUGGESTION}'",
                "layout_recommended_but_installed_another": "'${LAYOUT_AUTO_SUGGESTED_DIFFER_FROM_USED}'",
                "layout": "'${LAYOUT_NAME}'",
                "calc_toggl_wanted": "'${CALC_TOGGLE}'",
                "calc_toggl_installed": "'${CALC_TOGGLE_SUPPORTED_CALC}'",
                "systemctl_service_installed": "'${SERVICE}'",
                "external_keyboard_toggle_installed": "'${EXTERNAL_KEYBOARD_TOGGLE}'",
                "power_supply_saver_installed": "'${POWER_SUPPLY_SAVER}'",
                "install_duration_seconds": "'${INSTALL_DURATION}'",
                "touchpad": "'${TOUCHPAD}'",
                "laptop": "'${LAPTOP}'",
                "version": "'${DRIVER_VERSION}'",
                "layout_auto_suggestion_online": "'${LAYOUT_AUTO_SUGGESTION_ONLINE}'",
                "layout_auto_suggestion_online_found": "'${LAYOUT_AUTO_SUGGESTION_ONLINE_FOUND}'"
            }
        }
    ]
}'
CURL_URL="https://www.google-analytics.com/mp/collect?&measurement_id=$G_ID&api_secret=$API_SECRET"

#echo $CURL_PAYLOAD
$(curl -d "$CURL_PAYLOAD" -H "Content-Type: application/json" -X POST -s --max-time 2 "$CURL_URL")