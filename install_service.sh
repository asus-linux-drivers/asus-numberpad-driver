#!/usr/bin/env bash

source non_sudo_check.sh

# ENV VARS
if [ -z "$CONFIG_FILE_DIR_PATH" ]; then
    CONFIG_FILE_DIR_PATH="/usr/share/asus-numberpad-driver"
fi
if [ -z "$LAYOUT_NAME" ]; then
    LAYOUT_NAME="up5401ea"
fi
if [ -z "$LOGS_DIR_PATH" ]; then
    LOGS_DIR_PATH="/var/log/asus-numberpad-driver"
fi
if [ -z "$SERVICE_INSTALL_DIR_PATH" ]; then
    SERVICE_INSTALL_DIR_PATH="$HOME/.config/systemd/user"
fi

echo "Systemctl service"
echo

read -r -p "Do you want install systemctl service? [y/N]" RESPONSE
case "$RESPONSE" in [yY][eE][sS]|[yY])

    # Check rpm-ostree FIRST before dnf/yum (for BazziteOS/Fedora Atomic/Silverblue)
    if [[ $(command -v rpm-ostree 2>/dev/null) ]] && grep -qi "ostree" /etc/os-release 2>/dev/null; then
        echo "Detected OSTree-based system"
        echo "Installing systemd packages via rpm-ostree..."
        sudo rpm-ostree install systemd-devel python3-systemd
        if [[ $? != 0 ]]; then
            echo "Warning: Failed to install systemd packages. They may already be installed."
            echo "If the service fails to start, run: rpm-ostree install systemd-devel python3-systemd"
        else
            echo "Systemd packages installed. A reboot may be required for changes to take effect."
        fi
    elif [[ $(command -v apt-get 2>/dev/null) ]]; then
        sudo apt-get -y install libsystemd-dev python3-systemd
    elif [[ $(command -v pacman 2>/dev/null) ]]; then
        sudo pacman --noconfirm --needed -S systemd python-systemd
    elif [[ $(command -v dnf 2>/dev/null) ]]; then
        sudo dnf -y install systemd-devel python3-systemd
    elif [[ $(command -v yum 2>/dev/null) ]]; then
        sudo yum -y install systemd-devel python3-systemd
    elif [[ $(command -v zypper 2>/dev/null) ]]; then
        sudo zypper --non-interactive install systemd-devel python3-systemd
    elif [[ $(command -v xbps-install 2>/dev/null) ]]; then
        sudo xbps-install -Suy systemd python3-systemd
    elif [[ $(command -v emerge 2>/dev/null) ]]; then
        sudo emerge sys-apps/systemd dev-python/python-systemd
    elif [[ $(command -v eopkg 2>/dev/null) ]]; then
        sudo eopkg install -y systemd-devel python-systemd
    else
        echo "Not detected package manager. Driver may not work properly because required packages have not been installed. Please create an issue (https://github.com/asus-linux-drivers/asus-numberpad-driver/issues)."
    fi

    pip3 install -r requirements.systemd.txt

    SERVICE=1

    SERVICE_WAYLAND_FILE_PATH=asus_numberpad_driver.wayland.service
    SERVICE_X11_FILE_PATH=asus_numberpad_driver.x11.service
    SERVICE_INSTALL_FILE_NAME="asus_numberpad_driver@.service"

    XDG_RUNTIME_DIR=$(echo $XDG_RUNTIME_DIR)
    DBUS_SESSION_BUS_ADDRESS=$(echo $DBUS_SESSION_BUS_ADDRESS)
    XAUTHORITY=$(echo $XAUTHORITY)
    DISPLAY=$(echo $DISPLAY)
    WAYLAND_DISPLAY=$(echo $WAYLAND_DISPLAY)
    XDG_SESSION_TYPE=$(echo $XDG_SESSION_TYPE)

    echo
    echo "LAYOUT_NAME: $LAYOUT_NAME"
    echo "CONFIG_FILE_DIR_PATH: $CONFIG_FILE_DIR_PATH"
    echo
    echo "env var DISPLAY: $DISPLAY"
    echo "env var WAYLAND_DISPLAY: $WAYLAND_DISPLAY"
    echo "env var AUTHORITY: $XAUTHORITY"
    echo "env var XDG_RUNTIME_DIR: $XDG_RUNTIME_DIR"
    echo "env var DBUS_SESSION_BUS_ADDRESS: $DBUS_SESSION_BUS_ADDRESS"
    echo "env var XDG_SESSION_TYPE: $XDG_SESSION_TYPE"

    # with no gdm is env var XDG_SESSION_TYPE tty - https://github.com/asus-linux-drivers/asus-numberpad-driver/issues/185
    if [ "$XDG_SESSION_TYPE" == "tty" ] || [ "$XDG_SESSION_TYPE" == "" ]; then

        echo
        echo "Env var XDG_SESSION_TYPE is: `$XDG_SESSION_TYPE`"
        echo
        echo "Please, select your display manager:"
        echo
        PS3="Please enter your choice "
        OPTIONS=("x11" "wayland" "Quit")
        select SELECTED_OPT in "${OPTIONS[@]}"; do
            if [ "$SELECTED_OPT" = "Quit" ]; then
                exit 0
            fi

            XDG_SESSION_TYPE=$SELECTED_OPT

            echo
            echo "(SET UP FOR DRIVER ONLY) env var XDG_SESSION_TYPE: $XDG_SESSION_TYPE"
            echo

            if [ -z "$LAYOUT_NAME" ]; then
                echo "invalid option $REPLY"
            else
                break
            fi
        done
    fi

    echo

    mkdir -p "$SERVICE_INSTALL_DIR_PATH"

    if [ "$XDG_SESSION_TYPE" == "x11" ]; then
        cat "$SERVICE_X11_FILE_PATH" | INSTALL_DIR_PATH=$INSTALL_DIR_PATH LAYOUT_NAME=$LAYOUT_NAME CONFIG_FILE_DIR_PATH="$CONFIG_FILE_DIR_PATH/" DISPLAY=$DISPLAY XAUTHORITY=$XAUTHORITY XDG_RUNTIME_DIR=$XDG_RUNTIME_DIR XDG_SESSION_TYPE=$XDG_SESSION_TYPE DBUS_SESSION_BUS_ADDRESS=$DBUS_SESSION_BUS_ADDRESS envsubst '$INSTALL_DIR_PATH $LAYOUT_NAME $CONFIG_FILE_DIR_PATH $DISPLAY $XAUTHORITY $XDG_RUNTIME_DIR $XDG_SESSION_TYPE $DBUS_SESSION_BUS_ADDRESS' | tee "$SERVICE_INSTALL_DIR_PATH/$SERVICE_INSTALL_FILE_NAME" >/dev/null
    else
        echo "Unfortunatelly you will not be able use feature: Disabling Touchpad (e.g. Fn+special key) disables NumberPad aswell, at this moment is supported only X11"
        # DISPLAY=$DISPLAY for Xwayland
        cat "$SERVICE_WAYLAND_FILE_PATH" | INSTALL_DIR_PATH=$INSTALL_DIR_PATH LAYOUT_NAME=$LAYOUT_NAME CONFIG_FILE_DIR_PATH="$CONFIG_FILE_DIR_PATH/" DISPLAY=$DISPLAY XDG_RUNTIME_DIR=$XDG_RUNTIME_DIR XDG_SESSION_TYPE=$XDG_SESSION_TYPE DBUS_SESSION_BUS_ADDRESS=$DBUS_SESSION_BUS_ADDRESS envsubst '$INSTALL_DIR_PATH $LAYOUT_NAME $CONFIG_FILE_DIR_PATH $DISPLAY $XDG_RUNTIME_DIR $XDG_SESSION_TYPE $DBUS_SESSION_BUS_ADDRESS' | tee "$SERVICE_INSTALL_DIR_PATH/$SERVICE_INSTALL_FILE_NAME" >/dev/null
    fi

    if [[ $? != 0 ]]; then
        echo "Something went wrong when moving the asus_numberpad_driver.service"
        exit 1
    else
        echo "Asus numberpad driver service placed"
    fi

    systemctl --user daemon-reload

    if [[ $? != 0 ]]; then
        echo "Something went wrong when was called systemctl daemon reload"
        exit 1
    else
        echo "Systemctl daemon reloaded"
    fi

    systemctl enable --user asus_numberpad_driver@$USER.service

    if [[ $? != 0 ]]; then
        echo "Something went wrong when enabling the asus_numberpad_driver.service"
        exit 1
    else
        echo "Asus numberpad driver service enabled"
    fi

    systemctl restart --user asus_numberpad_driver@$USER.service
    if [[ $? != 0 ]]; then
        echo "Something went wrong when starting the asus_numberpad_driver.service"
        exit 1
    else
        echo "Asus numberpad driver service started"
    fi
esac
