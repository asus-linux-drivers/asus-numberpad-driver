#!/usr/bin/env bash

source non_sudo_check.sh

SERVICE_INSTALL_FILE_NAME="asus_numberpad_driver@.service"
SERVICE_INSTANCE_FILE_NAME="asus_numberpad_driver@$USER.service"

systemctl --user stop "$SERVICE_INSTANCE_FILE_NAME"
if [[ $? != 0 ]]
then
    echo "Something went wrong when stopping the $SERVICE_INSTANCE_FILE_NAME"
else
    echo "Asus numberpad driver service $SERVICE_INSTANCE_FILE_NAME stopped"
fi

systemctl --user disable "$SERVICE_INSTANCE_FILE_NAME"
if [[ $? != 0 ]]
then
    echo "Something went wrong when disabling the $SERVICE_INSTANCE_FILE_NAME"
else
    echo "Asus numberpad driver service $SERVICE_INSTANCE_FILE_NAME disabled"
fi

sudo rm -f "/usr/lib/systemd/user/$SERVICE_INSTALL_FILE_NAME"
if [[ $? != 0 ]]
then
    echo "Something went wrong when removing the $SERVICE_INSTALL_FILE_NAME"
else
    echo "Asus numberpad driver service removed"
fi

systemctl --user daemon-reload

if [[ $? != 0 ]]; then
    echo "Something went wrong when was called systemctl daemon reload"
else
    echo "Systemctl daemon reloaded"
fi