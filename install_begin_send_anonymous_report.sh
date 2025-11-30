#!/usr/bin/env bash

G_ID="G-R95GXWFECL"
API_SECRET="1FTfPGoRTDCmK4Outb-4nQ"
CLIENT_ID="365831413.1708860375"
LAPTOP_ID=$(sudo cat /sys/class/dmi/id/product_uuid)
EVENT_NAME="install_begin"

# begin
source /etc/os-release
# $PRETTY_NAME

# $PACKAGE_MANAGER
LAPTOP=$(cat /sys/devices/virtual/dmi/id/product_name)
TOUCHPAD=$(cat /proc/bus/input/devices | grep ".*Touchpad\"$" | sort | cut -f 2 -d'"' | head -1)
XDG_SESSION_TYPE=$(echo $XDG_SESSION_TYPE)
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
                "laptop": "'${LAPTOP}'",
                "distribution": "'${PRETTY_NAME}'",
                "package_manager": "'${PACKAGE_MANAGER}'",
                "xdg_session_type": "'${XDG_SESSION_TYPE}'",
                "touchpad": "'${TOUCHPAD}'",
                "version": "'${DRIVER_VERSION}'"
            }
        }
    ]
}'
CURL_URL="https://www.google-analytics.com/mp/collect?&measurement_id=$G_ID&api_secret=$API_SECRET"

#echo $CURL_PAYLOAD
$(curl -d "$CURL_PAYLOAD" -H "Content-Type: application/json" -X POST -s --max-time 2 "$CURL_URL")