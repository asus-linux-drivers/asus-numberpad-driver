#!/usr/bin/env bash

source non_sudo_check.sh

LOGS_DIR_PATH="/var/log/asus-numberpad-driver"

source install_logs.sh

echo

# log output from every installing attempt aswell
LOGS_INSTALL_LOG_FILE_NAME=install-"$(date +"%d-%m-%Y-%H-%M-%S")".log
LOGS_INSTALL_LOG_FILE_PATH="$LOGS_DIR_PATH/$LOGS_INSTALL_LOG_FILE_NAME"


{
    if [[ $(sudo apt-get install 2>/dev/null) ]]; then
        sudo apt-get -y install ibus libevdev2 curl xinput i2c-tools python3-dev python3-pip python3-setuptools python3-virtualenv libxml2-utils
    elif [[ $(sudo pacman -h 2>/dev/null) ]]; then
        # arch does not have header packages (python3-dev), headers are shipped with base? python package should contains almost latest version python3.*
        sudo pacman --noconfirm --needed -S ibus libevdev curl xorg-xinput i2c-tools python python-virtualenv libxml2
    elif [[ $(sudo dnf help 2>/dev/null) ]]; then
        sudo dnf -y install ibus libevdev curl xinput i2c-tools python3-devel python3-virtualenv libxml2
    elif [[ $(sudo yum help 2>/dev/null) ]]; then
        # yum was replaced with newer dnf above
        sudo yum --y install ibus libevdev curl xinput i2c-tools python3-devel python3-virtualenv libxml2
    else
        echo "Not detected package manager. Driver may not work properly because required packages have not been installed. Please create an issue (https://github.com/asus-linux-drivers/asus-numberpad-driver/issues)."
    fi

    if [[ $? != 0 ]]; then
        echo "Something went wrong when installing packages"
        exit 1
    fi

    echo

    source install_user_groups.sh

    echo

    source install_device_check.sh

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

    # create Python3 virtual environment
    virtualenv --python=$(python3 --version | cut -d" " -f2) /usr/share/asus-numberpad-driver/.env
    # because problem with this is venv is package which has to be installed e.g. on Ubuntu22.04 via python3.10-venv - specific version of Python in name - no way to automatize?
    # why not this?
    #
    # python3 -m venv /usr/share/asus-numberpad-driver/.venv
    #
    source /usr/share/asus-numberpad-driver/.env/bin/activate
    pip install -r requirements.txt
    deactivate

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
        sudo /sbin/reboot
        ;;
    *)
        ;;
    esac

    echo

    exit 0
} 2>&1 | sudo tee "$LOGS_INSTALL_LOG_FILE_PATH"