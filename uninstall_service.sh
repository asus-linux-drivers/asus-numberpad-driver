#!/usr/bin/env bash

source non_sudo_check.sh

# ENV VARS
if [ -z "$SERVICE_INSTALL_DIR_PATH" ]; then
    SERVICE_INSTALL_DIR_PATH="/usr/lib/systemd/user"
fi

SERVICE_INSTALL_FILE_NAME="asus_numberpad_driver@.service"
SERVICE_INSTANCE_FILE_NAME="asus_numberpad_driver@$USER.service"

systemctl --user stop "$SERVICE_INSTANCE_FILE_NAME"
if [[ $? != 0 ]]
then
    echo "Something went wrong when stopping the $SERVICE_INSTANCE_FILE_NAME"
else
    echo "Service $SERVICE_INSTANCE_FILE_NAME stopped"
fi

systemctl --user disable "$SERVICE_INSTANCE_FILE_NAME"
if [[ $? != 0 ]]
then
    echo "Something went wrong when disabling the $SERVICE_INSTANCE_FILE_NAME"
else
    echo "Service $SERVICE_INSTANCE_FILE_NAME disabled"
fi

sudo rm -f "$SERVICE_INSTALL_DIR_PATH/$SERVICE_INSTALL_FILE_NAME"
if [[ $? != 0 ]]
then
    echo "Something went wrong when removing the $SERVICE_INSTALL_FILE_NAME"
else
    echo "Service $SERVICE_INSTANCE_FILE_NAME removed"
fi

systemctl --user daemon-reload

if [[ $? != 0 ]]; then
    echo "Something went wrong when was called systemctl daemon reload"
else
    echo "Systemctl daemon reloaded"
fi