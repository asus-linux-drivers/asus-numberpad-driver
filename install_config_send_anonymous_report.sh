#!/usr/bin/env bash

# INHERIT VARS
if [ -z "$INSTALL_DIR_PATH" ]; then
    INSTALL_DIR_PATH="/usr/share/asus-numberpad-driver"
fi
if [ -z "$CONFIG_FILE_DIR_PATH" ]; then
    CONFIG_FILE_DIR_PATH="$INSTALL_DIR_PATH"
fi
if [ -z "$CONFIG_FILE_NAME" ]; then
    CONFIG_FILE_NAME="numberpad_dev"
fi
if [ -z "$CONFIG_FILE_PATH" ]; then
    CONFIG_FILE_PATH="$CONFIG_FILE_DIR_PATH/$CONFIG_FILE_NAME"
fi

G_ID="G-R95GXWFECL"
API_SECRET="1FTfPGoRTDCmK4Outb-4nQ"
CLIENT_ID="365831413.1708860375"
LAPTOP_ID=$(sudo cat /sys/class/dmi/id/product_uuid)
EVENT_NAME="install_config"

NUMPAD_DISABLES_SYS_NUMLOCK=$(cat $CONFIG_FILE_PATH | grep numpad_disables_sys_numlock | cut -d '=' -f2 | head -n 1 | xargs)
DISABLE_DUE_INACTIVITY_TIME=$(cat $CONFIG_FILE_PATH | grep disable_due_inactivity_time | cut -d '=' -f2 | head -n 1 | xargs)
TOUCHPAD_DISABLES_NUMPAD=$(cat $CONFIG_FILE_PATH | grep touchpad_disables_numpad | cut -d '=' -f2 | head -n 1 | xargs)
KEY_REPETITIONS=$(cat $CONFIG_FILE_PATH | grep key_repetitions | cut -d '=' -f2 | head -n 1 | xargs)
MULTITOUCH=$(cat $CONFIG_FILE_PATH | grep multitouch | cut -d '=' -f2 | head -n 1 | xargs)
ONE_TOUCH_KEY_ROTATION=$(cat $CONFIG_FILE_PATH | grep one_touch_key_rotation | cut -d '=' -f2 | head -n 1 |  xargs)
ACTIVATION_TIME=$(cat $CONFIG_FILE_PATH | grep activation_time | cut -d '=' -f2 | head -n 1 |  xargs)
SYS_NUMLOCK_ENABLES_NUMPAD=$(cat $CONFIG_FILE_PATH | grep sys_numlock_enables_numpad | cut -d '=' -f2 | head -n 1 | xargs)
TOP_LEFT_ICON_ACTIVATION_TIME=$(cat $CONFIG_FILE_PATH | grep top_left_icon_activation_time | cut -d '=' -f2 | head -n 1 | xargs)
TOP_LEFT_ICON_SLIDE_FUNC_ACTIVATION_X_RATIO=$(cat $CONFIG_FILE_PATH | grep top_left_icon_slide_func_activation_x_ratio | cut -d '=' -f2 | head -n 1 | xargs)
TOP_LEFT_ICON_SLIDE_FUNC_ACTIVATION_Y_RATIO=$(cat $CONFIG_FILE_PATH | grep top_left_icon_slide_func_activation_y_ratio | cut -d '=' -f2 | head -n 1 | xargs)
TOP_RIGHT_ICON_SLIDE_FUNC_ACTIVATION_X_RATIO=$(cat $CONFIG_FILE_PATH | grep top_right_icon_slide_func_activation_x_ratio | cut -d '=' -f2 | head -n 1 | xargs)
TOP_RIGHT_ICON_SLIDE_FUNC_ACTIVATION_Y_RATIO=$(cat $CONFIG_FILE_PATH | grep top_right_icon_slide_func_activation_y_ratio | cut -d '=' -f2 | head -n 1 | xargs)
ENABLED_TOUCHPAD_POINTER=$(cat $CONFIG_FILE_PATH | grep enabled_touchpad_pointer | cut -d '=' -f2 | head -n 1 | xargs)
PRESS_KEY_WHEN_IS_DONE_UNTOUCH=$(cat $CONFIG_FILE_PATH | grep press_key_when_is_done_untouch | cut -d '=' -f2 | head -n 1 | xargs)
DEFAULT_BACKLIGHT_LEVEL=$(cat $CONFIG_FILE_PATH | grep default_backlight_level | cut -d '=' -f2 | head -n 1 | xargs)
BRIGHTNESS=$(cat $CONFIG_FILE_PATH | grep brightness | cut -d '=' -f2 | head -n 1 | xargs)
TOP_LEFT_ICON_BRIGHTNESS_FUNC_DISABLED=$(cat $CONFIG_FILE_PATH | grep top_left_icon_brightness_func_disabled | cut -d '=' -f2 | head -n 1 | xargs)
DISTANCE_TO_MOVE_ONLY_POINTER=$(cat $CONFIG_FILE_PATH | grep distance_to_move_only_pointer | cut -d '=' -f2 | head -n 1 | xargs)
IDLE_BRIGHTNESS=$(cat $CONFIG_FILE_PATH | grep idle_brightness | cut -d '=' -f2 | head -n 1 | xargs)
IDLE_ENABLED=$(cat $CONFIG_FILE_PATH | grep idle_enabled | cut -d '=' -f2 | head -n 1 |  xargs)
IDLE_TIME=$(cat $CONFIG_FILE_PATH | grep idle_time | cut -d '=' -f2 | head -n 1 | xargs)
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
                "numpad_disables_sys_numlock": "'${NUMPAD_DISABLES_SYS_NUMLOCK}'",
                "disable_due_inactivity_time": "'${DISABLE_DUE_INACTIVITY_TIME}'",
                "touchpad_disables_numpad": "'${TOUCHPAD_DISABLES_NUMPAD}'",
                "key_repetitions": "'${KEY_REPETITIONS}'",
                "multitouch": "'${MULTITOUCH}'",
                "one_touch_key_rotation": "'${ONE_TOUCH_KEY_ROTATION}'",
                "activation_time": "'${ACTIVATION_TIME}'",
                "sys_numlock_enables_numpad": "'${SYS_NUMLOCK_ENABLES_NUMPAD}'",
                "top_left_icon_activation_time": "'${TOP_LEFT_ICON_ACTIVATION_TIME}'",
                "top_left_icon_slide_func_activation_x_ratio": "'${TOP_LEFT_ICON_SLIDE_FUNC_ACTIVATION_X_RATIO}'",
                "top_left_icon_slide_func_activation_y_ratio": "'${TOP_LEFT_ICON_SLIDE_FUNC_ACTIVATION_Y_RATIO}'",
                "top_right_icon_slide_func_activation_x_ratio": "'${TOP_RIGHT_ICON_SLIDE_FUNC_ACTIVATION_X_RATIO}'",
                "top_right_icon_slide_func_activation_y_ratio": "'${TOP_RIGHT_ICON_SLIDE_FUNC_ACTIVATION_Y_RATIO}'",
                "enabled_touchpad_pointer": "'${ENABLED_TOUCHPAD_POINTER}'",
                "press_key_when_is_done_untouch": "'${PRESS_KEY_WHEN_IS_DONE_UNTOUCH}'",
                "default_backlight_level": "'${DEFAULT_BACKLIGHT_LEVEL}'",
                "brightness": "'${BRIGHTNESS}'",
                "top_left_icon_brightness_func_disabled": "'${TOP_LEFT_ICON_BRIGHTNESS_FUNC_DISABLED}'",
                "distance_to_move_only_pointer": "'${DISTANCE_TO_MOVE_ONLY_POINTER}'",
                "idle_brightness": "'${IDLE_BRIGHTNESS}'",
                "idle_enabled": "'${IDLE_ENABLED}'",
                "idle_time": "'${IDLE_TIME}'",
                "version": "'${DRIVER_VERSION}'"
            }
        }
    ]
}'
CURL_URL="https://www.google-analytics.com/mp/collect?&measurement_id=$G_ID&api_secret=$API_SECRET"

#echo $CURL_PAYLOAD
$(curl -d "$CURL_PAYLOAD" -H "Content-Type: application/json" -X POST -s --max-time 2 "$CURL_URL")