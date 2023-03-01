#!/bin/bash

if [[ $(id -u) != 0 ]]
then
	echo "Please, run this script as root (using sudo for example)"
	exit 1
fi

# "root" by default or when is used --user it is "current user"
RUN_UNDER_USER=$USER

if [ "$1" = "--user" ]; then
    RUN_UNDER_USER=$SUDO_USER
fi

echo "driver will be stopped and uninstalled for user"
echo $RUN_UNDER_USER

systemctl stop asus_touchpad_numpad@$RUN_UNDER_USER.service
if [[ $? != 0 ]]
then
	echo "asus_touchpad_numpad.service cannot be stopped correctly..."
	exit 1
fi

# for removing "old" variant of systemd service of this driver (when was not used user template with @)
rm -f /lib/systemd/system/asus_touchpad_numpad.service
if [[ $? != 0 ]]
then
	echo "/lib/systemd/system/asus_touchpad_numpad.service cannot be removed correctly..."
fi

systemctl disable asus_touchpad_numpad@$RUN_UNDER_USER.service
if [[ $? != 0 ]]
then
	echo "asus_touchpad_numpad.service cannot be disabled correctly..."
	exit 1
fi

rm -f /etc/systemd/system/asus_touchpad_numpad@.service
if [[ $? != 0 ]]
then
	echo "/lib/systemd/system/asus_touchpad_numpad.service cannot be removed correctly..."
	exit 1
fi

# for `rm` exclude !(xy)
shopt -s extglob

NUMPAD_LAYOUTS_DIR="/usr/share/asus_touchpad_numpad-driver/numpad_layouts/"

NUMPAD_LAYOUTS_DIR_DIFF=""
if test -d "$NUMPAD_LAYOUTS_DIR"; then
    NUMPAD_LAYOUTS_DIR_DIFF=$(diff --exclude __pycache__ numpad_layouts $NUMPAD_LAYOUTS_DIR)
fi

if [ "$NUMPAD_LAYOUTS_DIR_DIFF" != "" ]
then
    read -r -p "Installed numpad layouts contain modifications compared to the default ones. Do you want remove them [y/N]" response
    case "$response" in [yY][eE][sS]|[yY])
		rm -rf /usr/share/asus_touchpad_numpad-driver/!(asus_touchpad_numpad_dev)
		if [[ $? != 0 ]]
		then
			echo "/usr/share/asus_touchpad_numpad-driver/ cannot be removed correctly..."
			exit 1
		fi
        ;;
    *)
		rm -rf /usr/share/asus_touchpad_numpad-driver/!(numpad_layouts|asus_touchpad_numpad_dev)
		if [[ $? != 0 ]]
		then
			echo "/usr/share/asus_touchpad_numpad-driver/ cannot be removed correctly..."
			exit 1
		fi
		echo "Numpad layouts in /usr/share/asus_touchpad_numpad-driver/conf/ have not been removed and remain in system:"
        ls /usr/share/asus_touchpad_numpad-driver/numpad_layouts
        ;;
    esac
else
	rm -rf /usr/share/asus_touchpad_numpad-driver/!(asus_touchpad_numpad_dev)
	if [[ $? != 0 ]]
	then
		echo "/usr/share/asus_touchpad_numpad-driver/ cannot be removed correctly..."
		exit 1
	fi
fi

CONF_FILE="/usr/share/asus_touchpad_numpad-driver/asus_touchpad_numpad_dev"

CONFIG_FILE_DIFF=""
if test -f "$CONF_FILE"; then
	CONFIG_FILE_DIFF=$(diff <(grep -v '^#' asus_touchpad_numpad_dev) <(grep -v '^#' $CONF_FILE))
fi

if [ "$CONFIG_FILE_DIFF" != "" ]
then
    read -r -p "Config file contains modifications compared to the default one. Do you want remove config file [y/N]" response
    case "$response" in [yY][eE][sS]|[yY])
		rm -f /usr/share/asus_touchpad_numpad-driver/asus_touchpad_numpad_dev
		if [[ $? != 0 ]]
		then
			echo "/usr/share/asus_touchpad_numpad-driver/asus_touchpad_numpad_dev cannot be removed correctly..."
			exit 1
		fi
        ;;
    *)
		echo "Config file have not been removed and remain in system:"
		echo "/usr/share/asus_touchpad_numpad-driver/asus_touchpad_numpad_dev"
        ;;
    esac
else
	rm -f /usr/share/asus_touchpad_numpad-driver/asus_touchpad_numpad_dev
	if [[ $? != 0 ]]
	then
		echo "/usr/share/asus_touchpad_numpad-driver/asus_touchpad_numpad_dev cannot be removed correctly..."
		exit 1
	fi
fi

rm -rf /var/log/asus_touchpad_numpad-driver
if [[ $? != 0 ]]
then
	echo "/var/log/asus_touchpad_numpad-driver cannot be removed correctly..."
	exit 1
fi

rm -f /usr/lib/udev/rules.d/90-numberpad-external-keyboard.rules
if [[ $? != 0 ]]
then
	echo "/usr/lib/udev/rules.d/90-numberpad-external-keyboard.rules cannot be removed correctly..."
	exit 1
fi

echo "Uninstall finished"
exit 0
