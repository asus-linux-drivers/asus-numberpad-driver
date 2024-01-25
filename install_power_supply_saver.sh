#!/usr/bin/env bash

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

echo "Power supply saver"

echo

echo "By default is idled only on battery mode after 10s. After 10s is decreased 30% of brightness."

echo

read -r -p "Do you want install the rule for idle functionality on battery mode? [y/N]" RESPONSE
case "$RESPONSE" in [yY][eE][sS]|[yY])

    echo

    cat "udev/80-numberpad-power-supply.rules" | INSTALL_DIR_PATH=$INSTALL_DIR_PATH envsubst '$INSTALL_DIR_PATH' | sudo tee "/usr/lib/udev/rules.d/80-numberpad-power-supply.rules" >/dev/null

    if [[ $? != 0 ]]; then
        echo "Something went wrong when applying 80-numberpad-power-supply"
        exit 1
    else
        echo "Rule 80-numberpad-power-supply applied"
    fi

    sudo mkdir -p "$INSTALL_DIR_PATH/udev"

    cat "udev/power_supply_is_bat.sh" | CONFIG_FILE_PATH=$CONFIG_FILE_PATH envsubst '$CONFIG_FILE_PATH' | sudo tee "$INSTALL_DIR_PATH/udev/power_supply_is_bat.sh" >/dev/null
    cat "udev/power_supply_is_ac.sh" | CONFIG_FILE_PATH=$CONFIG_FILE_PATH envsubst '$CONFIG_FILE_PATH' | sudo tee "$INSTALL_DIR_PATH/udev/power_supply_is_ac.sh" >/dev/null

    sudo chmod +x "$INSTALL_DIR_PATH/udev/power_supply_is_bat.sh"
    sudo chmod +x "$INSTALL_DIR_PATH/udev/power_supply_is_ac.sh"

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