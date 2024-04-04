#!/usr/bin/env bash

source non_sudo_check.sh

# INHERIT VARS
if [ -z "$CONFIG_FILE_DIR_PATH" ]; then
    CONFIG_FILE_DIR_PATH="/usr/share/asus-numberpad-driver"
fi
if [ -z "$LAYOUT_NAME" ]; then
    LAYOUT_NAME="up5401ea"
fi
if [ -z "$LOGS_DIR_PATH" ]; then
    LOGS_DIR_PATH="/var/log/asus-numberpad-driver"
fi

echo "Systemctl service"
echo

read -r -p "Do you want install systemctl service? [y/N]" RESPONSE
case "$RESPONSE" in [yY][eE][sS]|[yY])

    SERVICE=1

    SERVICE_FILE_PATH=asus_numberpad_driver.service
    SERVICE_WAYLAND_FILE_PATH=asus_numberpad_driver.wayland.service
    SERVICE_X11_FILE_PATH=asus_numberpad_driver.x11.service
    SERVICE_INSTALL_FILE_NAME="asus_numberpad_driver@.service"
    SERVICE_INSTALL_DIR_PATH="/usr/lib/systemd/user"

    XDG_RUNTIME_DIR=$(echo $XDG_RUNTIME_DIR)
    DBUS_SESSION_BUS_ADDRESS=$(echo $DBUS_SESSION_BUS_ADDRESS)
    XAUTHORITY=$(echo $XAUTHORITY)
    DISPLAY=$(echo $DISPLAY)
    WAYLAND_DISPLAY=$(echo $WAYLAND_DISPLAY)
    XDG_SESSION_TYPE=$(echo $XDG_SESSION_TYPE)
    ERROR_LOG_FILE_PATH="$LOGS_DIR_PATH/error.log"

    echo
    echo "LAYOUT_NAME: $LAYOUT_NAME"
    echo "CONFIG_FILE_DIR_PATH: $CONFIG_FILE_DIR_PATH"
    echo
    echo "env var DISPLAY: $DISPLAY"
    echo "env var WAYLAND_DISPLAY: $WAYLAND_DISPLAY"
    echo "env var AUTHORITY: $XAUTHORITY"
    echo "env var XDG_RUNTIME_DIR: $XDG_RUNTIME_DIR"
    echo "env var DBUS_SESSION_BUS_ADDRESS: $DBUS_SESSION_BUS_ADDRESS"
    echo "env var XDG_SESSION_TYPE: $XDG_SESSION_TYPE"
    echo
    echo "ERROR LOG FILE: $ERROR_LOG_FILE_PATH"
    echo

    if [ "$XDG_SESSION_TYPE" = "x11" ]; then
        cat "$SERVICE_X11_FILE_PATH" | LAYOUT_NAME=$LAYOUT_NAME CONFIG_FILE_DIR_PATH="$CONFIG_FILE_DIR_PATH/" DISPLAY=$DISPLAY XAUTHORITY=$XAUTHORITY XDG_RUNTIME_DIR=$XDG_RUNTIME_DIR DBUS_SESSION_BUS_ADDRESS=$DBUS_SESSION_BUS_ADDRESS ERROR_LOG_FILE_PATH=$ERROR_LOG_FILE_PATH envsubst '$LAYOUT_NAME $CONFIG_FILE_DIR_PATH $DISPLAY $XAUTHORITY $XDG_RUNTIME_DIR $DBUS_SESSION_BUS_ADDRESS $ERROR_LOG_FILE_PATH' | sudo tee "$SERVICE_INSTALL_DIR_PATH/$SERVICE_INSTALL_FILE_NAME" >/dev/null
    elif [ "$XDG_SESSION_TYPE" = "wayland" ]; then
        echo "Unfortunatelly you will not be able use feature: Disabling Touchpad (e.g. Fn+special key) disables NumberPad aswell, at this moment is supported only X11)"
        cat "$SERVICE_WAYLAND_FILE_PATH" | LAYOUT_NAME=$LAYOUT_NAME CONFIG_FILE_DIR_PATH="$CONFIG_FILE_DIR_PATH/" WAYLAND_DISPLAY=$WAYLAND_DISPLAY XDG_RUNTIME_DIR=$XDG_RUNTIME_DIR DBUS_SESSION_BUS_ADDRESS=$DBUS_SESSION_BUS_ADDRESS ERROR_LOG_FILE_PATH=$ERROR_LOG_FILE_PATH envsubst '$LAYOUT_NAME $CONFIG_FILE_DIR_PATH $WAYLAND_DISPLAY $XDG_RUNTIME_DIR $DBUS_SESSION_BUS_ADDRESS $ERROR_LOG_FILE_PATH' | sudo tee "$SERVICE_INSTALL_DIR_PATH/$SERVICE_INSTALL_FILE_NAME" >/dev/null
    else
        cat "$SERVICE_FILE_PATH" | LAYOUT_NAME=$LAYOUT_NAME CONFIG_FILE_DIR_PATH="$CONFIG_FILE_DIR_PATH/" DISPLAY=$DISPLAY XDG_RUNTIME_DIR=$XDG_RUNTIME_DIR DBUS_SESSION_BUS_ADDRESS=$DBUS_SESSION_BUS_ADDRESS ERROR_LOG_FILE_PATH=$ERROR_LOG_FILE_PATH envsubst '$LAYOUT_NAME $CONFIG_FILE_DIR_PATH $DISPLAY $XDG_RUNTIME_DIR $DBUS_SESSION_BUS_ADDRESS $ERROR_LOG_FILE_PATH' | sudo tee "$SERVICE_INSTALL_DIR_PATH/$SERVICE_INSTALL_FILE_NAME" >/dev/null
    fi

    if [[ $? != 0 ]]; then
        echo "Something went wrong when moving the asus_numberpad_driver.service"
        exit 1
    else
        echo "Asus numberpad driver service placed"
    fi

    systemctl --user daemon-reload

    if [[ $? != 0 ]]; then
        echo "Something went wrong when was called systemctl daemon reload"
        exit 1
    else
        echo "Systemctl daemon reloaded"
    fi

    systemctl enable --user asus_numberpad_driver@$USER.service

    if [[ $? != 0 ]]; then
        echo "Something went wrong when enabling the asus_numberpad_driver.service"
        exit 1
    else
        echo "Asus numberpad driver service enabled"
    fi

    systemctl restart --user asus_numberpad_driver@$USER.service
    if [[ $? != 0 ]]; then
        echo "Something went wrong when starting the asus_numberpad_driver.service"
        exit 1
    else
        echo "Asus numberpad driver service started"
    fi
esac