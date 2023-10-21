
#!/bin/bash

source non_sudo_check.sh

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

echo "External keyboard"
echo
echo "Is predefined rule for change configuration when is external keyboard connected/disconnected."
echo
echo "State connected of external keyboard means these changes:"
echo
echo " - Numlock key does not activate numberpad (config value is sys_numlock_enables_numpad=0)"
echo " - Numberpad does not disable numlock (config value is numpad_disables_sys_numlock=0)"
echo
echo "In summary when is external keyboard connected then is numberpad not linked to numlock state in both ways. Not connected state is the opposite."

echo

read -r -p "Do you want install rule for external keyboard? [y/N]" RESPONSE
case "$RESPONSE" in [yY][eE][sS]|[yY])

    echo

    cat "udev/90-numberpad-external-keyboard.rules" | INSTALL_DIR_PATH=$INSTALL_DIR_PATH envsubst '$INSTALL_DIR_PATH' | sudo tee "/usr/lib/udev/rules.d/90-numberpad-external-keyboard.rules" >/dev/null

    if [[ $? != 0 ]]; then
        echo "Something went wrong when moving 90-numberpad-external-keyboard.rules"
        exit 1
    else
        echo "Rule 90-numberpad-external-keyboard.rules placed"
    fi

    sudo mkdir -p "$INSTALL_DIR_PATH/udev"

    cat "udev/external_keyboard_is_connected.sh" | CONFIG_FILE_PATH=$CONFIG_FILE_PATH envsubst '$CONFIG_FILE_PATH' | sudo tee "$INSTALL_DIR_PATH/udev/external_keyboard_is_connected.sh" >/dev/null
    cat "udev/external_keyboard_is_disconnected.sh" | CONFIG_FILE_PATH=$CONFIG_FILE_PATH envsubst '$CONFIG_FILE_PATH' | sudo tee "$INSTALL_DIR_PATH/udev/external_keyboard_is_disconnected.sh" >/dev/null

    sudo chmod +x "$INSTALL_DIR_PATH/udev/external_keyboard_is_connected.sh"
    sudo chmod +x "$INSTALL_DIR_PATH/udev/external_keyboard_is_disconnected.sh"

    sudo udevadm control --reload-rules

    if [[ $? != 0 ]]; then
        echo "Something went wrong when reloading udev rules"
        exit 1
    else
        echo "Udev rules reloaded"
    fi
    ;;
*)
    ;;
esac