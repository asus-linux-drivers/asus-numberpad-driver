#!/usr/bin/env bash

REPO="asus-linux-drivers/asus-dsdt-tables"
SCRIPT_NAME="dsdt_probe.sh"
SCRIPT_URL="https://raw.githubusercontent.com/${REPO}/refs/heads/main/${SCRIPT_NAME}"

INSTALL_DIR="scripts"
LOCAL_PATH="${INSTALL_DIR}/${SCRIPT_NAME}"

echo "DSDT table collection"
echo
echo "DSDT stands for Differentiated System Description Table."
echo "It describes how your operating system communicates with hardware components such as keyboard and input devices."
echo "Sharing this data helps improve Linux support and enables device-specific fixes for ASUS laptops."
echo "No personal files are accessed or transmitted."
echo
echo "Only firmware-level data is shared (and anonymously):"
echo " - DSDT table"
echo " - registered input devices"
echo " - laptop model"
echo
echo "All previously shared tables and the script used to collect them are publicly available at:"
echo
echo "https://github.com/asus-linux-drivers/asus-dsdt-tables"
echo

read -r -p "Do you want to share your DSDT table? [y/N] " RESPONSE

case "$RESPONSE" in
    [yY][eE][sS]|[yY])

        mkdir -p "$INSTALL_DIR"

        curl -fsSL "$SCRIPT_URL" -o "$LOCAL_PATH"

        chmod +x "$LOCAL_PATH"

        echo

        SOURCE="asus-linux-drivers/asus-numberpad-driver" bash "$LOCAL_PATH"

        sudo rm -f "$LOCAL_PATH"
        ;;

    *)
        exit 0
        ;;
esac