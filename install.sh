#!/usr/bin/env bash

source non_sudo_check.sh

LOGS_DIR_PATH="/var/log/asus-numberpad-driver"

source install_logs.sh

echo

# log output from every installing attempt aswell
LOGS_INSTALL_LOG_FILE_NAME=install-"$(date +"%d-%m-%Y-%H-%M-%S")".log
LOGS_INSTALL_LOG_FILE_PATH="$LOGS_DIR_PATH/$LOGS_INSTALL_LOG_FILE_NAME"


{
    # asyncore was removed in Python 3.12, but try the import instead of a
    # version check in case the compatibility package is installed.
    #
    # https://github.com/asus-linux-drivers/asus-numberpad-driver/issues/153
    PYTHON_VERSION="$(python3 --version | cut -d' ' -f2)"
    PYTHON_REQUIRED_VERSION_FOR_LIB_PYASYNCORE="3.12.0"

    if [[ $(sudo apt-get install 2>/dev/null) ]]; then
        sudo apt-get -y install ibus libevdev2 curl xinput python3-dev python3-libevdev python3-numpy python3-xlib python3-pyinotify libxml2-utils python3-smbus2
    elif [[ $(sudo pacman -h 2>/dev/null) ]]; then
        # arch does not have header packages (python3-dev), headers are shipped with base? python package should contains almost latest version python3.*
        sudo pacman --noconfirm --needed -S ibus libevdev curl xorg-xinput python python-libevdev python-numpy python-pyinotify python-xlib libxml2 python3-smbus2
    elif [[ $(sudo dnf help 2>/dev/null) ]]; then
        sudo dnf -y install ibus libevdev curl xinput python3-devel python3-libevdev python3-numpy python3-inotify python3-xlib libxml2 python3-smbus2
    elif [[ $(sudo yum help 2>/dev/null) ]]; then
        # yum was replaced with newer dnf above
        sudo yum --y install ibus libevdev curl xinput python3-devel python3-libevdev python3-numpy python3-inotify python3-xlib libxml2 python3-smbus2
    else
        echo "Not detected package manager. Driver may not work properly because required packages have not been installed. Please create an issue (https://github.com/asus-linux-drivers/asus-numberpad-driver/issues)."
    fi

    echo

    sudo modprobe i2c-dev

    # check if the i2c-dev module is successfully loaded
    if [[ $? != 0 ]]; then
        echo "i2c-dev module cannot be loaded"
        exit 1
    else
        echo "i2c-dev module loaded"
    fi

    echo "i2c-dev" | sudo tee /etc/modules-load.d/i2c-dev-asus-numberpad-driver.conf >/dev/null

    if [[ $? != 0 ]]; then
        echo "Something went wrong when adding i2c-dev module to auto loaded modules"
        exit 1
    else
        echo "i2c-dev module added to auto loaded modules"
    fi

    echo

    source install_device_check.sh

    echo

    source install_user_groups.sh

    echo

    # do not install __pycache__
    if [[ -d layouts/__pycache__ ]]; then
        rm -rf layouts/__pycache__
    fi

    INSTALL_DIR_PATH="/usr/share/asus-numberpad-driver"
    CONFIG_FILE_DIR_PATH="$INSTALL_DIR_PATH"
    CONFIG_FILE_NAME="numberpad_dev"
    CONFIG_FILE_PATH="$CONFIG_FILE_DIR_PATH/$CONFIG_FILE_NAME"

    sudo mkdir -p "$INSTALL_DIR_PATH/layouts"
    sudo chown -R $USER "$INSTALL_DIR_PATH"
    sudo install numberpad.py "$INSTALL_DIR_PATH"
    sudo install -t "$INSTALL_DIR_PATH/layouts" layouts/*.py

    if [[ -f "$CONFIG_FILE_PATH" ]]; then
        read -r -p "In system remains config file from previous installation. Do you want replace that config with default config? [y/N]" RESPONSE
        case "$RESPONSE" in [yY][eE][sS]|[yY])

            # default will be autocreated, that is why is removed
            sudo rm -f $CONFIG_FILE_PATH
            if [[ $? != 0 ]]; then
                echo "$CONFIG_FILE_PATH cannot be removed correctly..."
                exit 1
            fi
            ;;
        *)
            ;;
        esac
    else
        echo "Default config will be autocreated during the first run and available for futher modifications here:"
        echo "$CONFIG_FILE_PATH"
    fi

    echo

    source install_layout_auto_suggestion.sh

    echo

    if [ -z "$LAYOUT_NAME" ]; then

        source install_layout_select.sh

        echo
    fi

    source install_service.sh

    echo

    source install_external_keyboard_toggle.sh

    echo

    source install_calc_toggle.sh

    echo

    echo "Installation finished succesfully"

    echo

    read -r -p "Reboot is required. Do you want reboot now? [y/N]" response
    case "$response" in [yY][eE][sS]|[yY])
        reboot
        ;;
    *)
        ;;
    esac

    echo

    exit 0
} 2>&1 | sudo tee "$LOGS_INSTALL_LOG_FILE_PATH"