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
        sudo apt-get -y install ibus libevdev2 curl xinput i2c-tools python3-dev python3-virtualenv libxml2-utils libxkbcommon-dev gcc pkg-config libxcb-render0-dev
        sudo apt-get -y install libsystemd-dev
        if [ "$XDG_SESSION_TYPE" == "wayland" ]; then
            sudo apt-get -y install libwayland-dev
        fi

    elif [[ $(command -v pacman 2>/dev/null) ]]; then
        PACKAGE_MANAGER="pacman"
        sudo pacman --noconfirm --needed -S ibus libevdev curl xorg-xinput i2c-tools python python-virtualenv libxml2 libxkbcommon gcc pkgconf libxcb
        sudo pacman --noconfirm --needed -S systemd
        if [ "$XDG_SESSION_TYPE" == "wayland" ]; then
            sudo pacman --noconfirm --needed -S wayland
        fi

    elif [[ $(command -v dnf 2>/dev/null) ]]; then
        PACKAGE_MANAGER="dnf"
        sudo dnf -y install ibus libevdev curl xinput i2c-tools python3-devel python3-virtualenv libxml2 libxkbcommon-devel gcc pkg-config libxcb-devel
        sudo dnf -y install systemd-devel
        if [ "$XDG_SESSION_TYPE" == "wayland" ]; then
            sudo dnf -y install wayland-devel
        fi

    elif [[ $(command -v yum 2>/dev/null) ]]; then
        PACKAGE_MANAGER="yum"
        sudo yum -y install ibus libevdev curl xinput i2c-tools python3-devel python3-virtualenv libxml2 libxkbcommon-devel gcc pkg-config libxcb-devel
        sudo yum -y install systemd-devel
        if [ "$XDG_SESSION_TYPE" == "wayland" ]; then
            sudo yum -y install wayland-devel
        fi

    elif [[ $(command -v zypper 2>/dev/null) ]]; then
        PACKAGE_MANAGER="zypper"
        sudo zypper --non-interactive install ibus libevdev2 curl xinput i2c-tools python3-devel python3-virtualenv libxml2 libxkbcommon-devel gcc pkg-config libxcb-devel
        sudo zypper --non-interactive install systemd-devel
        if [ "$XDG_SESSION_TYPE" == "wayland" ]; then
            sudo zypper --non-interactive install wayland-devel
        fi

    elif [[ $(command -v xbps-install 2>/dev/null) ]]; then
        PACKAGE_MANAGER="xbps-install"
        sudo xbps-install -Suy ibus-devel libevdev-devel curl xinput i2c-tools python3-devel python3-virtualenv libxml2 libxkbcommon-devel gcc pkg-config libxcb-devel
        sudo xbps-install -Suy systemd
        if [ "$XDG_SESSION_TYPE" == "wayland" ]; then
            sudo xbps-install -Suy wayland-devel
        fi

    elif [[ $(command -v emerge 2>/dev/null) ]]; then
        PACKAGE_MANAGER="portage"
        sudo emerge app-i18n/ibus dev-libs/libevdev net-misc/curl x11-apps/xinput sys-apps/i2c-tools dev-lang/python dev-python/virtualenv dev-libs/libxml2 x11-libs/libxkbcommon sys-devel/gcc virtual/pkgconfig x11-libs/libxcb
        sudo emerge sys-apps/systemd
        if [ "$XDG_SESSION_TYPE" == "wayland" ]; then
            sudo emerge dev-libs/wayland
        fi

    elif [[ $(command -v rpm-ostree 2>/dev/null) ]]; then
        PACKAGE_MANAGER="rpm-ostree"
        sudo rpm-ostree install xinput virtualenv python3-devel wayland-protocols-devel pkg-config libxcb-devel
        sudo rpm-ostree install systemd-devel
        if [ "$XDG_SESSION_TYPE" == "wayland" ]; then
            sudo rpm-ostree install wayland-devel
        fi

    elif [[ $(command -v eopkg 2>/dev/null) ]]; then
        PACKAGE_MANAGER="eopkg"
        sudo eopkg install -y ibus libevdev curl xinput i2c-tools python3-devel python3-virtualenv libxml2-devel libxkbcommon-devel gcc pkg-config libxcb-devel
        sudo eopkg install -y systemd-devel
        if [ "$XDG_SESSION_TYPE" == "wayland" ]; then
            sudo eopkg install -y wayland-devel
        fi
    else
        echo "Not detected package manager. Driver may not work properly because required packages have not been installed. Please create an issue (https://github.com/asus-linux-drivers/asus-numberpad-driver/issues)."
    fi

    echo "------------------"
    echo "Using $PACKAGE_MANAGER"
    echo "------------------"

    # https://github.com/asus-linux-drivers/asus-numberpad-driver/issues/258
    if [ "$DESKTOP_SESSION" == "plasma" ]
    then
        case $PACKAGE_MANAGER in
            "apt")
                QDBUS_PKG=$(apt-file search --regexp '^/usr/bin/qdbus$' 2>/dev/null | head -n1 | awk '{print $1}' | sed 's/:.*//')
                [ -n "$QDBUS_PKG" ] && sudo apt-get -y install "$QDBUS_PKG"
                ;;
            "pacman")
                QDBUS_PKG=$(pacman -Fy /usr/bin/qdbus 2>/dev/null | awk '/extra\// {print $1}' | head -n1)
                [ -n "$QDBUS_PKG" ] && sudo pacman --noconfirm --needed -S "$QDBUS_PKG"
                ;;
            "dnf")
                QDBUS_PKG=$(dnf provides /usr/bin/qdbus 2>/dev/null | grep -oP '(qt\d+-qttools-[^-]+-[^-]+)' | head -n1)
                [ -n "$QDBUS_PKG" ] && sudo dnf -y install "$QDBUS_PKG"
                ;;
            "yum")
                QDBUS_PKG=$(yum provides /usr/bin/qdbus 2>/dev/null | grep -oP '(qt\d+-qttools-[^-]+-[^-]+)' | head -n1)
                [ -n "$QDBUS_PKG" ] && sudo yum -y install "$QDBUS_PKG"
                ;;
            "zypper")
                QDBUS_PKG=$(zypper search --provides qdbus 2>/dev/null | awk 'NR>8 && $2 ~ /qt/ {print $2; exit}')
                [ -n "$QDBUS_PKG" ] && sudo zypper --non-interactive install "$QDBUS_PKG"
                ;;
            "xbps-install")
                QDBUS_PKG=$(xbps-query -Rs $(xbps-query -p provides -X /usr/bin/qdbus 2>/dev/null) 2>/dev/null | awk '{print $1}' | head -n1 | sed 's/-[0-9].*//')
                [ -n "$QDBUS_PKG" ] && sudo xbps-install -Suy "$QDBUS_PKG"
                ;;
            "portage")
                QDBUS_PKG="dev-qt/qdbus"  # Emerge doesn't have a direct "provides" query; hardcoded but reliable
                sudo emerge "$QDBUS_PKG"
                ;;
            "rpm-ostree")
                QDBUS_PKG=$(rpm-ostree rpm-md --provides=/usr/bin/qdbus 2>/dev/null | grep -oP '(qt\d+-qttools-[^-]+-[^-]+)' | head -n1)
                [ -n "$QDBUS_PKG" ] && sudo rpm-ostree install "$QDBUS_PKG"
                ;;
            "eopkg")
                QDBUS_PKG=$(eopkg search --provides qdbus 2>/dev/null | awk '/Package/{print $2}' | head -n1)
                [ -n "$QDBUS_PKG" ] && sudo eopkg install -y "$QDBUS_PKG"
                ;;
        esac
        # Optional: Verify installation
        if command -v qdbus >/dev/null 2>&1; then
            echo "------------------"
            echo "qdbus installed successfully."
            echo "------------------"
        else
            echo "Warning: qdbus not available after install. Manual intervention needed."
        fi
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

    PYTHON=$(command -v python3)
    if [ -z "$PYTHON" ]; then
        echo "Python3 not found in PATH."
        exit 1
    fi

    # xcffib (https://pypi.org/project/xcffib/) requires python >=3.10
    if ! $PYTHON -c "import sys; sys.exit(0 if sys.version_info >= (3,10) else 1)"; then
        PYTHON_VERSION=$($PYTHON -c "import sys; print('.'.join(map(str, sys.version_info[:2])))")
        echo "Python >= 3.10 is required (found $PYTHON_VERSION)."
        echo "Please install Python 3.10 or higher before continuing."
        exit 1
    fi

    # create Python3 virtual environment
    virtualenv --python="$PYTHON" $INSTALL_DIR_PATH/.env
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
