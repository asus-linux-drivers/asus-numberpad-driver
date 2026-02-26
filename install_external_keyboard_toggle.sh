#!/usr/bin/env bash

source non_sudo_check.sh

# ENV VARS
if [ -z "$INSTALL_DIR_PATH" ]; then
    INSTALL_DIR_PATH="/usr/share/asus-numberpad-driver"
fi
if [ -z "$CONFIG_FILE_DIR_PATH" ]; then
    CONFIG_FILE_DIR_PATH="$INSTALL_DIR_PATH"
fi
if [ -z "$CONFIG_FILE_NAME" ]; then
    CONFIG_FILE_NAME="numberpad_dev"
fi
if [ -z "$INSTALL_UDEV_DIR_PATH" ]; then
    INSTALL_UDEV_DIR_PATH="/usr/lib/udev"
fi

CONFIG_FILE_PATH="$CONFIG_FILE_DIR_PATH/$CONFIG_FILE_NAME"

echo "External keyboard"
echo
echo "This is a predefined udev rule for changing the configuration when an external keyboard is connected/disconnected."
echo
echo "The application of this rule results in the following changes if an external keyboard is connected:"
echo
echo " - Numlock key does not activate NumberPad (config value is set to sys_numlock_enables_numpad=0)"
echo " - Numberpad disactivation does not disable Numlock (config value is set to numpad_disables_sys_numlock=0)"
echo
echo "In summary when an external keyboard is connected then NumberPad activation is not linked to Numlock state and vice versa."

echo

read -r -p "Do you want install the udev rule for external keyboard? [y/N]" RESPONSE
case "$RESPONSE" in [yY][eE][sS]|[yY])

    EXTERNAL_KEYBOARD_TOGGLE=1

    echo

    # Create rules.d directory if it doesn't exist (for immutable systems)
    sudo mkdir -p "$INSTALL_UDEV_DIR_PATH/rules.d"

    cat "udev/90-numberpad-external-keyboard.rules" | INSTALL_DIR_PATH=$INSTALL_DIR_PATH envsubst '$INSTALL_DIR_PATH' | sudo tee "$INSTALL_UDEV_DIR_PATH/rules.d/90-numberpad-external-keyboard.rules" >/dev/null

    if [[ $? != 0 ]]; then
        echo "Something went wrong when applying 90-numberpad-external-keyboard.rules"
        exit 1
    else
        echo "Rule 90-numberpad-external-keyboard.rules applied"
    fi

    sudo mkdir -p "$INSTALL_DIR_PATH/udev"

    cat "udev/external_keyboard_is_connected.sh" | CONFIG_FILE_PATH=$CONFIG_FILE_PATH envsubst '$CONFIG_FILE_PATH' | sudo tee "$INSTALL_DIR_PATH/udev/external_keyboard_is_connected.sh" >/dev/null
    cat "udev/external_keyboard_is_disconnected.sh" | CONFIG_FILE_PATH=$CONFIG_FILE_PATH envsubst '$CONFIG_FILE_PATH' | sudo tee "$INSTALL_DIR_PATH/udev/external_keyboard_is_disconnected.sh" >/dev/null

    sudo chmod +x "$INSTALL_DIR_PATH/udev/external_keyboard_is_connected.sh"
    sudo chmod +x "$INSTALL_DIR_PATH/udev/external_keyboard_is_disconnected.sh"

    sudo udevadm control --reload-rules && sudo udevadm trigger

    if [[ $? != 0 ]]; then
        echo "Something went wrong when reloading or triggering udev rules"
        exit 1
    else
        echo "Udev rules reloaded and triggered"
    fi
    ;;
*)
    ;;
esac