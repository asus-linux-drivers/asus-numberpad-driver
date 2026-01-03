#!/usr/bin/env bash

G_ID="G-R95GXWFECL"
API_SECRET="1FTfPGoRTDCmK4Outb-4nQ"
CLIENT_ID="365831413.1708860375"
USER_ID=$(sudo cat /sys/class/dmi/id/product_uuid)
EVENT_NAME="install_finished"
LAPTOP_ID=$(sudo cat /sys/class/dmi/id/product_uuid)

# finished
INSTALL_DURATION=$(($END_TIME - $START_TIME))

# $SUGGESTED_LAYOUT
# $LAYOUT_NAME
# $CALC_TOGGLE
# $CALC_TOGGLE_SUPPORTED_CALC
# $COACTIVATOR_KEY
# $POWER_SUPPLY_SAVER
# $EXTERNAL_KEYBOARD_TOGGLE
# $SERVICE
# $LAYOUT_AUTO_SUGGESTION
# $LAYOUT_AUTO_SUGGESTED_DIFFER_FROM_USED
# $LAYOUT_AUTO_SUGGESTION_ONLINE
# $LAYOUT_AUTO_SUGGESTION_ONLINE_FOUND
# $LAYOUT_AUTO_SUGGESTION_OFFLINE_FOUND
# $LAYOUT_AUTO_SUGGESTION_BY_LAPTOP_PRODUCT
# $LAYOUT_AUTO_SUGGESTION_BY_LAPTOP_NAME
# $LAYOUT_AUTO_SUGGESTION_BY_VENDOR_DEVICE

LAPTOP=$(cat /sys/devices/virtual/dmi/id/product_name)
TOUCHPAD=$(cat /proc/bus/input/devices | grep ".*Touchpad\"$" | sort | cut -f 2 -d'"' | head -1)
DRIVER_VERSION=$(cat CHANGELOG.md | grep -Po '(?<=## )[^ ]*' | head -1)

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
                "coactivator_key": "'${COACTIVATOR_KEY}'",
                "install_duration_seconds": "'${INSTALL_DURATION}'",
                "touchpad": "'${TOUCHPAD}'",
                "laptop": "'${LAPTOP}'",
                "version": "'${DRIVER_VERSION}'",
                "layout_auto_suggestion_online": "'${LAYOUT_AUTO_SUGGESTION_ONLINE}'",
                "layout_auto_suggestion_online_found": "'${LAYOUT_AUTO_SUGGESTION_ONLINE_FOUND}'",
                "layout_auto_suggestion_offline_found": "'${LAYOUT_AUTO_SUGGESTION_OFFLINE_FOUND}'",
                "layout_auto_suggestion_by_laptop_product": "'${LAYOUT_AUTO_SUGGESTION_BY_LAPTOP_PRODUCT}'",
                "layout_auto_suggestion_by_laptop_name": "'${LAYOUT_AUTO_SUGGESTION_BY_LAPTOP_NAME}'",
                "layout_auto_suggestion_by_vendor_device": "'${LAYOUT_AUTO_SUGGESTION_BY_VENDOR_DEVICE}'"
            }
        }
    ]
}'
CURL_URL="https://www.google-analytics.com/mp/collect?&measurement_id=$G_ID&api_secret=$API_SECRET"

#echo $CURL_PAYLOAD
$(curl -d "$CURL_PAYLOAD" -H "Content-Type: application/json" -X POST -s --max-time 2 "$CURL_URL")