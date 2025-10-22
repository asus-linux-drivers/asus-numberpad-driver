#!/usr/bin/env bash

# Check for non-sudo execution
source non_sudo_check.sh

START_TIME=${EPOCHREALTIME::-7}

# Set up logging
if [ -z "$LOGS_DIR_PATH" ]; then
    LOGS_DIR_PATH="/var/log/asus-numberpad-driver"
fi
source install_logs.sh
LOGS_INSTALL_LOG_FILE_NAME=install-"$(date +"%d-%m-%Y-%H-%M-%S")".log
LOGS_INSTALL_LOG_FILE_PATH="$LOGS_DIR_PATH/$LOGS_INSTALL_LOG_FILE_NAME"

# Determine Plasma version
if [ "$DESKTOP_SESSION" == "plasma" ] && command -v plasmashell >/dev/null 2>&1; then
    PLASMA_VER=$(plasmashell --version | grep -oE '[0-9]+' | head -1)
else
    PLASMA_VER=6  # Default to Plasma 6 for modern systems if plasmashell is missing
fi

# Function to detect package manager and set package lists
detect_package_manager() {
    if command -v apt-get >/dev/null 2>&1; then
        PACKAGE_MANAGER="apt"
        BASE_PKGS="ibus libevdev2 curl xinput i2c-tools python3-dev python3-virtualenv libxml2-utils libxkbcommon-dev gcc pkg-config libxcb-render0-dev libsystemd-dev apt-file"
        WAYLAND_PKG="libwayland-dev"
        UPDATE_CMD="sudo apt-get update"
        INSTALL_CMD="sudo apt-get -y install"
        QDBUS_QUERY="apt-file search --regexp '^/usr/bin/qdbus$' 2>/dev/null | head -n1 | awk '{print \$1}' | sed 's/:.*//'"
        QDBUS_FALLBACK="qdbus"
    elif command -v pacman >/dev/null 2>&1; then
        PACKAGE_MANAGER="pacman"
        BASE_PKGS="ibus libevdev curl xorg-xinput i2c-tools python python-virtualenv libxml2 libxkbcommon gcc pkgconf libxcb systemd"
        WAYLAND_PKG="wayland"
        UPDATE_CMD="sudo pacman -Syu --noconfirm"
        INSTALL_CMD="sudo pacman --noconfirm --needed -S"
        QDBUS_QUERY="pacman -Fy qdbus 2>/dev/null | grep \"qt$PLASMA_VER-tools\" | awk '{print \$1}'"
        QDBUS_FALLBACK="qt6-tools"
    elif command -v dnf >/dev/null 2>&1; then
        PACKAGE_MANAGER="dnf"
        BASE_PKGS="ibus libevdev curl xinput i2c-tools python3-devel python3-virtualenv libxml2 libxkbcommon-devel gcc pkg-config libxcb-devel systemd-devel"
        WAYLAND_PKG="wayland-devel"
        UPDATE_CMD="sudo dnf -y update"
        INSTALL_CMD="sudo dnf -y install"
        QDBUS_QUERY="dnf provides *qdbus 2>/dev/null | awk '/qt[56]-qttools.*'$(uname -m)'/ {print \$1; exit} /qt-.*'$(uname -m)'/ {print \$1; exit}' | head -n1"
        QDBUS_FALLBACK="qt6-qttools"
    elif command -v zypper >/dev/null 2>&1; then
        PACKAGE_MANAGER="zypper"
        BASE_PKGS="ibus libevdev2 curl xinput i2c-tools python3-devel python3-virtualenv libxml2 libxkbcommon-devel gcc pkg-config libxcb-devel systemd-devel"
        WAYLAND_PKG="wayland-devel"
        UPDATE_CMD="sudo zypper --non-interactive refresh"
        INSTALL_CMD="sudo zypper --non-interactive install"
        QDBUS_QUERY="zypper search --provides qdbus 2>/dev/null | grep -e '.*qt'$PLASMA_VER'.*qdbus.*' | awk '{print \$2}'"
        QDBUS_FALLBACK="qt6-tools-qdbus"
    elif command -v xbps-install >/dev/null 2>&1; then
        PACKAGE_MANAGER="xbps-install"
        BASE_PKGS="ibus-devel libevdev-devel curl xinput i2c-tools python3-devel python3-virtualenv libxml2 libxkbcommon-devel gcc pkg-config libxcb-devel systemd"
        WAYLAND_PKG="wayland-devel"
        UPDATE_CMD="sudo xbps-install -Suy"
        INSTALL_CMD="sudo xbps-install -Suy"
        QDBUS_QUERY="xbps-query -Rs \$(xbps-query -p provides -X /usr/bin/qdbus 2>/dev/null) 2>/dev/null | awk '{print \$1}' | head -n1 | sed 's/-[0-9].*//'"
        QDBUS_FALLBACK="qt6-tools"
    elif command -v emerge >/dev/null 2>&1; then
        PACKAGE_MANAGER="portage"
        BASE_PKGS="app-i18n/ibus dev-libs/libevdev net-misc/curl x11-apps/xinput sys-apps/i2c-tools dev-lang/python dev-python/virtualenv dev-libs/libxml2 x11-libs/libxkbcommon sys-devel/gcc virtual/pkgconfig x11-libs/libxcb sys-apps/systemd"
        WAYLAND_PKG="dev-libs/wayland"
        UPDATE_CMD="sudo emerge --sync"
        INSTALL_CMD="sudo emerge"
        QDBUS_QUERY="echo dev-qt/qdbus"  # Hardcoded, no direct provides query
        QDBUS_FALLBACK="dev-qt/qdbus"
    elif command -v rpm-ostree >/dev/null 2>&1; then
        PACKAGE_MANAGER="rpm-ostree"
        BASE_PKGS="xinput virtualenv python3-devel wayland-protocols-devel pkg-config libxcb-devel systemd-devel"
        WAYLAND_PKG="wayland-devel"
        UPDATE_CMD="sudo rpm-ostree upgrade"
        INSTALL_CMD="sudo rpm-ostree install"
        QDBUS_QUERY="rpm-ostree rpm-md --provides=/usr/bin/qdbus 2>/dev/null | grep -oP '(qt\\d+-qttools-[^-]+-[^-]+)' | head -n1"
        QDBUS_FALLBACK="qt6-qttools"
    elif command -v eopkg >/dev/null 2>&1; then
        PACKAGE_MANAGER="eopkg"
        BASE_PKGS="ibus libevdev curl xinput i2c-tools python3-devel python3-virtualenv libxml2-devel libxkbcommon-devel gcc pkg-config libxcb-devel systemd-devel"
        WAYLAND_PKG="wayland-devel"
        UPDATE_CMD="sudo eopkg upgrade -y"
        INSTALL_CMD="sudo eopkg install -y"
        QDBUS_QUERY="eopkg search --provides qdbus 2>/dev/null | awk '/Package/{print \$2}' | head -n1"
        QDBUS_FALLBACK="qt6-tools"
    else
        echo "Not detected package manager. Driver may not work properly because required packages have not been installed. Please create an issue (https://github.com/asus-linux-drivers/asus-numberpad-driver/issues)."
        exit 1
    fi
}

# Function to install packages
install_packages() {
    echo "------------------"
    echo "Using $PACKAGE_MANAGER"
    echo "------------------"
    $UPDATE_CMD
    $INSTALL_CMD $BASE_PKGS
    if [ "$XDG_SESSION_TYPE" == "wayland" ]; then
        $INSTALL_CMD $WAYLAND_PKG
    fi
    if [ "$DESKTOP_SESSION" == "plasma" ]; then
        QDBUS_PKG=$(eval "$QDBUS_QUERY")
        [ -n "$QDBUS_PKG" ] && $INSTALL_CMD "$QDBUS_PKG"
        echo "------------------"
        if command -v qdbus >/dev/null 2>&1; then
            echo "qdbus installed successfully."
        else
            echo "Warning: qdbus not available after install. Manual intervention needed."
        fi
        echo "------------------"
    fi
    if [[ $? != 0 ]]; then
        echo "Something went wrong when installing packages"
        source install_begin_send_anonymous_report.sh
        exit 1
    fi
}

# Main execution block, redirect all output to log file
{
    detect_package_manager
    install_packages
    source install_begin_send_anonymous_report.sh
    echo

    source install_user_groups.sh
    echo

    source install_device_check.sh
    echo

    # Remove __pycache__ directory if it exists
    if [[ -d layouts/__pycache__ ]]; then
        rm -rf layouts/__pycache__
    fi

    # Set up installation and config paths
    : "${INSTALL_DIR_PATH:=/usr/share/asus-numberpad-driver}"
    : "${CONFIG_FILE_DIR_PATH:=$INSTALL_DIR_PATH}"
    : "${CONFIG_FILE_NAME:=numberpad_dev}"
    CONFIG_FILE_PATH="$CONFIG_FILE_DIR_PATH/$CONFIG_FILE_NAME"

    sudo mkdir -p "$INSTALL_DIR_PATH/layouts"
    sudo chown -R "$USER" "$INSTALL_DIR_PATH"
    sudo install numberpad.py "$INSTALL_DIR_PATH"
    sudo install -t "$INSTALL_DIR_PATH/layouts" layouts/*.py

    if [[ -f "$CONFIG_FILE_PATH" ]]; then
        read -r -p "In system remains config file from previous installation. Do you want replace that config with default config? [y/N] " RESPONSE
        case "$RESPONSE" in [yY][eE][sS]|[yY])
            sudo rm -f "$CONFIG_FILE_PATH"
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
        echo "Default config will be autocreated during the first run and available for further modifications here:"
        echo "$CONFIG_FILE_PATH"
    fi
    echo

    # Verify Python version
    PYTHON=$(command -v python3)
    if [ -z "$PYTHON" ]; then
        echo "Python3 not found in PATH."
        exit 1
    fi
    if ! $PYTHON -c "import sys; sys.exit(0 if sys.version_info >= (3,10) else 1)"; then
        PYTHON_VERSION=$($PYTHON -c "import sys; print('.'.join(map(str, sys.version_info[:2])))")
        echo "Python >= 3.10 is required (found $PYTHON_VERSION)."
        echo "Please install Python 3.10 or higher before continuing."
        exit 1
    fi

    # Set up Python virtual environment
    virtualenv --python="$PYTHON" "$INSTALL_DIR_PATH/.env"
    source "$INSTALL_DIR_PATH/.env/bin/activate"
    pip3 install --upgrade pip
    pip3 install --upgrade setuptools
    pip3 install -r requirements.txt
    if [ "$XDG_SESSION_TYPE" == "wayland" ]; then
        pip3 install -r requirements.wayland.txt
    fi
    echo

    # Handle layout selection
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

    echo "Installation finished successfully"
    echo

    read -r -p "Reboot is required. Do you want reboot now? [y/N] " response
    case "$response" in [yY][eE][sS]|[yY])
        sudo /sbin/reboot
        ;;
    esac

    echo
    exit 0
} 2>&1 | sudo tee "$LOGS_INSTALL_LOG_FILE_PATH"