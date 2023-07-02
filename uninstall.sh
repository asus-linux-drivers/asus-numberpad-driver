#!/bin/bash

if [[ $(id -u) != 0 ]]
then
	echo "Please, run this script as root (using sudo for example)"
	exit 1
fi

# for `rm` exclude !(xy)
shopt -s extglob

logout_requested=false

# "root" by default or when is used --user it is "current user"
RUN_UNDER_USER=$USER

if [ "$1" = "--user" ]
then
    RUN_UNDER_USER=$SUDO_USER
fi

echo "Driver will be stopped and uninstalled for user"
echo $RUN_UNDER_USER

source remove_previous_implementation_of_service.sh

systemctl stop asus_touchpad_numpad@$RUN_UNDER_USER.service
if [[ $? != 0 ]]
then
	echo "asus_touchpad_numpad.service cannot be stopped correctly..."
fi

systemctl disable asus_touchpad_numpad@$RUN_UNDER_USER.service
if [[ $? != 0 ]]
then
	echo "asus_touchpad_numpad.service cannot be disabled correctly..."
fi

rm -f /etc/systemd/system/asus_touchpad_numpad@.service
if [[ $? != 0 ]]
then
	echo "/etc/systemd/system/asus_touchpad_numpad.service cannot be removed correctly..."
fi


NUMPAD_LAYOUTS_DIR="/usr/share/asus_touchpad_numpad-driver/numpad_layouts/"

NUMPAD_LAYOUTS_DIR_DIFF=""
if test -d "$NUMPAD_LAYOUTS_DIR"
then
    NUMPAD_LAYOUTS_DIR_DIFF=$(diff --exclude __pycache__ numpad_layouts $NUMPAD_LAYOUTS_DIR)
fi

if [ "$NUMPAD_LAYOUTS_DIR_DIFF" != "" ]
then
    read -r -p "Installed numpad layouts contain modifications compared to the default ones. Do you want remove them [y/N]" response
    case "$response" in [yY][eE][sS]|[yY])
		rm -rf "/usr/share/asus_touchpad_numpad-driver/"!(asus_touchpad_numpad_dev)
		if [[ $? != 0 ]]
		then
			echo "/usr/share/asus_touchpad_numpad-driver/ cannot be removed correctly..."
		fi
        ;;
    *)
		rm -rf "/usr/share/asus_touchpad_numpad-driver/"!(numpad_layouts|asus_touchpad_numpad_dev)
		if [[ $? != 0 ]]
		then
			echo "/usr/share/asus_touchpad_numpad-driver/ cannot be removed correctly..."
		fi
		echo "Numpad layouts in /usr/share/asus_touchpad_numpad-driver/conf/ have not been removed and remain in system:"
        ls /usr/share/asus_touchpad_numpad-driver/numpad_layouts
        ;;
    esac
else
	rm -rf "/usr/share/asus_touchpad_numpad-driver/"!(asus_touchpad_numpad_dev)
	if [[ $? != 0 ]]
	then
		echo "/usr/share/asus_touchpad_numpad-driver/ cannot be removed correctly..."
	fi
fi

CONF_FILE="/usr/share/asus_touchpad_numpad-driver/asus_touchpad_numpad_dev"

CONFIG_FILE_DIFF=""
if test -f "$CONF_FILE"
then
	CONFIG_FILE_DIFF=$(diff <(grep -v '^#' asus_touchpad_numpad_dev) <(grep -v '^#' $CONF_FILE))
fi

if [ "$CONFIG_FILE_DIFF" != "" ]
then
    read -r -p "Config file contains modifications compared to the default one. Do you want remove config file [y/N]" response
    case "$response" in [yY][eE][sS]|[yY])

		if test -d "$NUMPAD_LAYOUTS_DIR"
		then
			rm -f /usr/share/asus_touchpad_numpad-driver/asus_touchpad_numpad_dev
		else
			rm -rf /usr/share/asus_touchpad_numpad-driver
		fi

		if [[ $? != 0 ]]
		then
			echo "/usr/share/asus_touchpad_numpad-driver/asus_touchpad_numpad_dev cannot be removed correctly..."
		fi
        ;;
    *)
		echo "Config file have not been removed and remain in system:"
		echo "/usr/share/asus_touchpad_numpad-driver/asus_touchpad_numpad_dev"
        ;;
    esac
else

	if test -d "$NUMPAD_LAYOUTS_DIR"
	then
		rm -f /usr/share/asus_touchpad_numpad-driver/asus_touchpad_numpad_dev
	else
		rm -rf /usr/share/asus_touchpad_numpad-driver
	fi

	if [[ $? != 0 ]]
	then
		echo "/usr/share/asus_touchpad_numpad-driver/asus_touchpad_numpad_dev cannot be removed correctly..."
	fi
fi

rm -rf /var/log/asus_touchpad_numpad-driver
if [[ $? != 0 ]]
then
	echo "/var/log/asus_touchpad_numpad-driver cannot be removed correctly..."
fi

rm -f /usr/lib/udev/rules.d/90-numberpad-external-keyboard.rules
if [[ $? != 0 ]]
then
	echo "/usr/lib/udev/rules.d/90-numberpad-external-keyboard.rules cannot be removed correctly..."
fi

systemctl daemon-reload

if [[ $? != 0 ]]; then
    echo "Something went wrong when was called systemctl daemon reload"
else
    echo "Systemctl daemon realod called succesfully"
fi

# remove shortcuts for toggling calculator added by driver

existing_shortcut_string=$(runuser -u $SUDO_USER gsettings get org.gnome.settings-daemon.plugins.media-keys custom-keybindings)
#echo $existing_shortcut_string

filtered_existing_shortcut_string="["
filtered_existing_shortcut_count=0

if [[ "$existing_shortcut_string" != "@as []" ]]; then
	IFS=', ' read -ra existing_shortcut_array <<< "$existing_shortcut_string"
    for shortcut_index in "${!existing_shortcut_array[@]}"; do
        shortcut="${existing_shortcut_array[$shortcut_index]}"
        shortcut_index=$( echo $shortcut | cut -d/ -f 8 | sed 's/[^0-9]//g')

        command=$(runuser -u $SUDO_USER gsettings get org.gnome.settings-daemon.plugins.media-keys.custom-keybinding:/org/gnome/settings-daemon/plugins/media-keys/custom-keybindings/custom$shortcut_index/ 'command')
        #echo $command
        if [[ "$command" = "'bash /usr/share/asus_touchpad_numpad-driver/scripts/calculator_toggle.sh'" ]]; then
			((filtered_existing_shortcut_count=filtered_existing_shortcut_count+1))
            echo "Removed shortcut added by installation of this driver for toggling calculator"
            runuser -u $SUDO_USER gsettings reset-recursively org.gnome.settings-daemon.plugins.media-keys.custom-keybinding:/org/gnome/settings-daemon/plugins/media-keys/custom-keybindings/custom$shortcut_index/
        else
			#echo "Found something else on index $shortcut_index"
			if [[ "$filtered_existing_shortcut_string" != "[" ]]; then
            	filtered_existing_shortcut_string="$filtered_existing_shortcut_string"", '/org/gnome/settings-daemon/plugins/media-keys/custom-keybindings/custom$shortcut_index/'"
            else
                filtered_existing_shortcut_string="$filtered_existing_shortcut_string""'/org/gnome/settings-daemon/plugins/media-keys/custom-keybindings/custom$shortcut_index/'"
            fi
		fi
    done

    filtered_existing_shortcut_string="$filtered_existing_shortcut_string"']'
    #echo $filtered_existing_shortcut_string
    #echo $filtered_existing_shortcut_count

	if [[ $filtered_existing_shortcut_count != 0 ]]; then
		runuser -u $SUDO_USER gsettings set org.gnome.settings-daemon.plugins.media-keys custom-keybindings "${filtered_existing_shortcut_string}"
		logout_requested=true
	fi
fi

if [[ "$logout_requested" = true ]]
then

    echo "Uninstall process requested to succesfull finish atleast log out or reboot"
    echo "Without that reverted changes might not be done"

    read -r -p "Do you want reboot now? [y/N]" response
    case "$response" in [yY][eE][sS]|[yY])
        reboot
        ;;
    *)
        ;;
    esac
fi

echo "Uninstall finished"
exit 0