#!/usr/bin/env bash

source non_sudo_check.sh

START_TIME=${EPOCHREALTIME::-7}

# ENV VARS
if [ -z "$LOGS_DIR_PATH" ]; then
    LOGS_DIR_PATH="/var/log/asus-numberpad-driver"
fi

source install_logs.sh

echo

# log output from every installing attempt aswell
LOGS_INSTALL_LOG_FILE_NAME=install-"$(date +"%d-%m-%Y-%H-%M-%S")".log
LOGS_INSTALL_LOG_FILE_PATH="$LOGS_DIR_PATH/$LOGS_INSTALL_LOG_FILE_NAME"


{
    # pip pywayland requires gcc
    if [[ $(command -v apt-get 2>/dev/null) ]]; then
        PACKAGE_MANAGER="apt"
        sudo apt-get -y install ibus libevdev2 curl xinput i2c-tools python3-dev python3-virtualenv libxml2-utils libxkbcommon-dev gcc pkg-config
        sudo apt-get -y install libsystemd-dev
        if [ "$XDG_SESSION_TYPE" == "wayland" ]; then
            sudo apt-get -y install libwayland-dev
        fi

    elif [[ $(command -v pacman 2>/dev/null) ]]; then
        PACKAGE_MANAGER="pacman"
        sudo pacman --noconfirm --needed -S ibus libevdev curl xorg-xinput i2c-tools python python-virtualenv libxml2 libxkbcommon gcc pkgconf
        sudo pacman --noconfirm --needed -S systemd
        if [ "$XDG_SESSION_TYPE" == "wayland" ]; then
            sudo pacman --noconfirm --needed -S wayland
        fi

    elif [[ $(command -v dnf 2>/dev/null) ]]; then
        PACKAGE_MANAGER="dnf"
        sudo dnf -y install ibus libevdev curl xinput i2c-tools python3-devel python3-virtualenv libxml2 libxkbcommon-devel gcc pkg-config
        sudo dnf -y install systemd-devel
        if [ "$XDG_SESSION_TYPE" == "wayland" ]; then
            sudo dnf -y install wayland-devel
        fi

    elif [[ $(command -v yum 2>/dev/null) ]]; then
        PACKAGE_MANAGER="yum"
        sudo yum -y install ibus libevdev curl xinput i2c-tools python3-devel python3-virtualenv libxml2 libxkbcommon-devel gcc pkg-config
        sudo yum -y install systemd-devel
        if [ "$XDG_SESSION_TYPE" == "wayland" ]; then
            sudo yum -y install wayland-devel
        fi

    elif [[ $(command -v zypper 2>/dev/null) ]]; then
        PACKAGE_MANAGER="zypper"
        sudo zypper --non-interactive install ibus libevdev2 curl xinput i2c-tools python3-devel python3-virtualenv libxml2 libxkbcommon-devel gcc pkg-config
        sudo zypper --non-interactive install systemd-devel
        if [ "$XDG_SESSION_TYPE" == "wayland" ]; then
            sudo zypper --non-interactive install wayland-devel
        fi

    elif [[ $(command -v xbps-install 2>/dev/null) ]]; then
        PACKAGE_MANAGER="xbps-install"
        sudo xbps-install -Suy ibus-devel libevdev-devel curl xinput i2c-tools python3-devel python3-virtualenv libxml2 libxkbcommon-devel gcc pkg-config
        sudo xbps-install -Suy systemd
        if [ "$XDG_SESSION_TYPE" == "wayland" ]; then
            sudo xbps-install -Suy wayland-devel
        fi

    elif [[ $(command -v emerge 2>/dev/null) ]]; then
        PACKAGE_MANAGER="portage"
        sudo emerge app-i18n/ibus dev-libs/libevdev net-misc/curl x11-apps/xinput sys-apps/i2c-tools dev-lang/python dev-python/virtualenv dev-libs/libxml2 x11-libs/libxkbcommon sys-devel/gcc virtual/pkgconfig
        sudo emerge sys-apps/systemd
        if [ "$XDG_SESSION_TYPE" == "wayland" ]; then
            sudo emerge dev-libs/wayland
        fi

    elif [[ $(command -v rpm-ostree 2>/dev/null) ]]; then
        PACKAGE_MANAGER="rpm-ostree"
        sudo rpm-ostree install xinput virtualenv python3-devel wayland-protocols-devel pkg-config
        sudo rpm-ostree install systemd-devel
        if [ "$XDG_SESSION_TYPE" == "wayland" ]; then
            sudo rpm-ostree install wayland-devel
        fi

    elif [[ $(command -v eopkg 2>/dev/null) ]]; then
        PACKAGE_MANAGER="eopkg"
        sudo eopkg install -y ibus libevdev curl xinput i2c-tools python3-devel python3-virtualenv libxml2-devel libxkbcommon-devel gcc pkg-config
        sudo eopkg install -y systemd-devel
        if [ "$XDG_SESSION_TYPE" == "wayland" ]; then
            sudo eopkg install -y wayland-devel
        fi

    else
        echo "Not detected package manager. Driver may not work properly because required packages have not been installed. Please create an issue (https://github.com/asus-linux-drivers/asus-numberpad-driver/issues)."
    fi

    if [[ $? != 0 ]]; then
        echo "Something went wrong when installing packages"
        source install_begin_send_anonymous_report.sh
        exit 1
    else
        source install_begin_send_anonymous_report.sh
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
            source install_config_send_anonymous_report.sh
            ;;
        esac
    else
        echo "Default config will be autocreated during the first run and available for futher modifications here:"
        echo "$CONFIG_FILE_PATH"
    fi

    echo

    # create Python3 virtual environment
    virtualenv --python=$(command -v python3) $INSTALL_DIR_PATH/.env
    source $INSTALL_DIR_PATH/.env/bin/activate
    pip3 install --upgrade pip
    pip3 install --upgrade setuptools
    pip3 install -r requirements.txt
    if [ "$XDG_SESSION_TYPE" == "wayland" ]; then
        pip3 install -r requirements.wayland.txt
    fi

    echo

    if [ -z "$LAYOUT_NAME" ]; then

      source install_layout_auto_suggestion.sh

      echo

      if [ -z "$LAYOUT_NAME" ]; then

        source install_layout_select.sh

        echo
      fi
    fi

    source install_service.sh

    echo

    source install_external_keyboard_toggle.sh

    echo

    source install_calc_toggle.sh

    echo

    source install_power_supply_saver.sh

    echo

    END_TIME=${EPOCHREALTIME::-7}
    source install_finished_send_anonymous_report.sh

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
