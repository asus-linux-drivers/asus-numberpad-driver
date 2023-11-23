#!/bin/bash

source non_sudo_check.sh

LOGS_DIR_PATH="/var/log/asus-numberpad-driver"

# log output from every uninstalling attempt aswell
LOGS_UNINSTALL_LOG_FILE_NAME=uninstall-"$(date +"%d-%m-%Y-%H-%M-%S")".log
LOGS_UNINSTALL_LOG_FILE_PATH="$LOGS_DIR_PATH/$LOGS_UNINSTALL_LOG_FILE_NAME"
touch "$LOGS_UNINSTALL_LOG_FILE_PATH"

# for `rm` exclude !(xy)
shopt -s extglob

{
    INSTALL_DIR_PATH="/usr/share/asus-numberpad-driver"
    CONFIG_FILE_DIR_PATH="$INSTALL_DIR_PATH"
    CONFIG_FILE_NAME="numberpad_dev"
    CONFIG_FILE_PATH="$CONFIG_FILE_DIR_PATH/$CONFIG_FILE_NAME"

	NUMPAD_LAYOUTS_DIR="$INSTALL_DIR_PATH/numpad_layouts/"

	NUMPAD_LAYOUTS_DIR_DIFF=""
	if test -d "$NUMPAD_LAYOUTS_DIR"
	then
	    NUMPAD_LAYOUTS_DIR_DIFF=$(diff --exclude __pycache__ numpad_layouts $NUMPAD_LAYOUTS_DIR)
	fi

	if [ "$NUMPAD_LAYOUTS_DIR_DIFF" != "" ]
	then
	    read -r -p "Installed numpad layouts contain modifications compared to the default ones. Do you want remove them [y/N]" response
	    case "$response" in [yY][eE][sS]|[yY])
			rm -rf "$INSTALL_DIR_PATH/!($CONFIG_FILE_NAME)"
			if [[ $? != 0 ]]
			then
				echo "Something went wrong when removing files from the $INSTALL_DIR_PATH"
			fi
        	;;
    	*)
			rm -rf "$INSTALL_DIR_PATH/!(numpad_layouts|$CONFIG_FILE_NAME)"
			if [[ $? != 0 ]]
			then
				echo "Something went wrong when removing files from the $INSTALL_DIR_PATH"
			fi

			echo
			echo "Numpad layouts in $INSTALL_DIR_PATH/numpad_layouts have not been removed and remain in system:"
	        ls /$INSTALL_DIR_PATH/numpad_layouts
        	;;
    	esac
	else
		rm -rf "$INSTALL_DIR_PATH/!($CONFIG_FILE_NAME)"
		if [[ $? != 0 ]]
		then
			echo "Something went wrong when removing files from the $INSTALL_DIR_PATH"
		fi
	fi

	if [[ -f "$CONF_FILE" ]]; then

	    read -r -p "Do you want remove config file [y/N]" RESPONSE
	    case "$RESPONSE" in [yY][eE][sS]|[yY])

			if test -d "$NUMPAD_LAYOUTS_DIR"
			then
				rm -f "$CONFIG_FILE_PATH"
			else
				rm -rf "$INSTALL_DIR_PATH"
			fi

			if [[ $? != 0 ]]
			then
				echo "Something went wrong when removing files from the $INSTALL_DIR_PATH"
			fi
        	;;
    	*)
			echo "Config file have not been removed and remain in system:"
			echo "$CONFIG_FILE_PATH"
        	;;
    	esac
	else

		if test -d "$NUMPAD_LAYOUTS_DIR"
		then
			rm -f $CONFIG_FILE_PATH
		else
			rm -rf $INSTALL_DIR_PATH
		fi

		if [[ $? != 0 ]]
		then
			echo "Something went wrong when removing files from the $INSTALL_DIR_PATH"
		fi
	fi

	echo "Asus numberpad driver removed"

	echo

	source uninstall_user_groups.sh

	echo

	source uninstall_external_keyboard_toggle.sh

	echo

	source uninstall_calc_toggle.sh

	echo

	source uninstall_service.sh

	echo

	echo "Uninstallation finished succesfully"

	echo

	read -r -p "Reboot is required. Do you want reboot now? [y/N]" RESPONSE
    case "$RESPONSE" in [yY][eE][sS]|[yY])
        reboot
        ;;
    *)
        ;;
    esac

	exit 0
} 2>&1 | sudo tee "$LOGS_UNINSTALL_LOG_FILE_PATH"