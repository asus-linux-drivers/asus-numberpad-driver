#!/usr/bin/env bash

source non_sudo_check.sh

# ENV VARS
if [ -z "$INSTALL_UDEV_DIR_PATH" ]; then
    INSTALL_UDEV_DIR_PATH="/usr/lib/udev"
fi

UINPUT_GID=$(getent group "uinput" | cut -d: -f3)

# https://github.com/asus-linux-drivers/asus-dialpad-driver/issues/19#issuecomment-3625958498
if [ -n "$UINPUT_GID" ] && [ "$UINPUT_GID" -ge 1000 ]; then
    echo "The group 'uinput' was not system (GID=$UINPUT_GID), removing..."
    sudo groupdel "uinput"
fi

I2C_GID=$(getent group "i2c" | cut -d: -f3)

# https://github.com/asus-linux-drivers/asus-dialpad-driver/issues/19#issuecomment-3625958498
if [ -n "$I2C_GID" ] && [ "$I2C_GID" -ge 1000 ]; then
    echo "The group 'i2c' was not system (GID=$I2C_GID), removing..."
    sudo groupdel "i2c"
fi

sudo groupadd --system "input"
sudo groupadd --system "i2c"
sudo groupadd --system "uinput"

sudo usermod -a -G "i2c,input,uinput,numberpad" $USER

if [[ $? != 0 ]]; then
    echo "Something went wrong when adding the groups to current user"
    exit 1
else
    echo "Added groups input, i2c, uinput, numberpad to current user"
fi

sudo modprobe uinput

# check if the uinput module is successfully loaded
if [[ $? != 0 ]]; then
    echo "uinput module cannot be loaded"
    exit 1
else
    echo "uinput module loaded"
fi

sudo modprobe i2c-dev

# check if the i2c-dev module is successfully loaded
if [[ $? != 0 ]]; then
    echo "i2c-dev module cannot be loaded. Make sure you have installed i2c-tools package"
    exit 1
else
    echo "i2c-dev module loaded"
fi

# https://github.com/asus-linux-drivers/asus-numberpad-driver/issues/231
sudo mkdir -p /etc/modules-load.d

# autodetects KERNEL and SUBSYSTEM values for /dev/uinput
read UINPUT_KERNEL UINPUT_SUBSYSTEM < <(
    udevadm info --attribute-walk --name=/dev/uinput \
    | awk -F '==' '
        /KERNEL==/ && !k { gsub(/"/,"",$2); k=$2 }
        /SUBSYSTEM==/ && !s { gsub(/"/,"",$2); s=$2 }
        k && s { print k, s; exit }
    '
)

# autodetects SUBSYSTEM for /dev/i2c-0
I2C_SUBSYSTEM=$(
    udevadm info --attribute-walk --name=/dev/i2c-0 \
    | awk -F '==' '
        /SUBSYSTEM==/ { gsub(/"/,"",$2); print $2; exit }
    '
)

echo "Udevadm detected values:"
echo "  uinput: KERNEL=$UINPUT_KERNEL  SUBSYSTEM=$UINPUT_SUBSYSTEM"
echo "  i2c:    SUBSYSTEM=$I2C_SUBSYSTEM"

# create uinput udev rule
echo 'SUBSYSTEM=="'"$UINPUT_SUBSYSTEM"'", KERNEL=="'"$UINPUT_KERNEL"'", GROUP="uinput", MODE="0660"' \
  | sudo tee "$INSTALL_UDEV_DIR_PATH"/rules.d/99-asus-numberpad-driver-uinput.rules >/dev/null
echo 'uinput' | sudo tee /etc/modules-load.d/uinput-asus-numberpad-driver.conf >/dev/null

# create i2c udev rule
echo 'KERNEL=="i2c-[0-9]*", SUBSYSTEM=="'"$I2C_SUBSYSTEM"'", GROUP="i2c", MODE="0660"' \
  | sudo tee "$INSTALL_UDEV_DIR_PATH"/rules.d/99-asus-numberpad-driver-i2c-dev.rules >/dev/null
echo "i2c-dev" | sudo tee /etc/modules-load.d/i2c-dev-asus-numberpad-driver.conf >/dev/null

if [[ $? != 0 ]]; then
    echo "Something went wrong when adding uinput module to auto loaded modules"
    exit 1
else
    echo "uinput module added to auto loaded modules"
fi

sudo udevadm control --reload-rules && sudo udevadm trigger --sysname-match=uinput && sudo udevadm trigger --attr-match=subsystem=i2c-dev

if [[ $? != 0 ]]; then
    echo "Something went wrong when reloading or triggering uinput udev rules"
else
    echo "Udev rules reloaded and triggered"
fi