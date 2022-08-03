#!/bin/bash

# Checking if the script is runned as root (via sudo or other)
if [[ $(id -u) != 0 ]]; then
    echo "Please run the installation script as root (using sudo for example)"
    exit 1
fi

if [[ $(sudo apt install 2>/dev/null) ]]; then
    echo 'apt is here' && sudo apt -y install libevdev2 python3-libevdev i2c-tools git python3-pip xinput
elif [[ $(sudo pacman -h 2>/dev/null) ]]; then
    echo 'pacman is here' && sudo pacman --noconfirm --needed -S libevdev python-libevdev i2c-tools git python-pip xorg-xinput
elif [[ $(sudo dnf install 2>/dev/null) ]]; then
    echo 'dnf is here' && sudo dnf -y install libevdev python-libevdev i2c-tools git python-pip xinput
fi

pip3 install numpy evdev

# Checking if the pip3 is successfuly loaded
if [[ $? != 0 ]]; then
    echo "pip3 is not loaded correctly. Make sure you have installed python3-pip package"
    exit 1
fi

modprobe i2c-dev

# Checking if the i2c-dev module is successfuly loaded
if [[ $? != 0 ]]; then
    echo "i2c-dev module cannot be loaded correctly. Make sure you have installed i2c-tools package"
    exit 1
fi

interfaces=$(for i in $(i2cdetect -l | grep DesignWare | sed -r "s/^(i2c\-[0-9]+).*/\1/"); do echo $i; done)
if [ -z "$interfaces" ]; then
    echo "No i2c interface can be found. Make sure you have installed libevdev packages"
    exit 1
fi

touchpad_detected=false
for i in $interfaces; do
    echo -n "Testing interface $i : "
    number=$(echo -n $i | cut -d'-' -f2)
    offTouchpadCmd="i2ctransfer -f -y $number w13@0x15 0x05 0x00 0x3d 0x03 0x06 0x00 0x07 0x00 0x0d 0x14 0x03 0x00 0xad"
    i2c_test=$($offTouchpadCmd 2>&1)
    if [ -z "$i2c_test" ]; then
        echo "sucess"
        touchpad_detected=true
        break
    else
        echo "failed"
    fi
done

if [ "$touchpad_detected" = false ]; then
    echo 'The detection was not successful. Touchpad not found.'
    exit 1
fi

if [[ -d numpad_layouts/__pycache__ ]]; then
    rm -rf numpad_layouts/__pycache__
fi

laptop=$(dmidecode -s system-product-name | rev | cut -d ' ' -f1 | rev | cut -d "_" -f1)
laptop_full=$(dmidecode -s system-product-name)

echo "Detected laptop: $laptop_full"

detected_laptop_via_offline_table=$(cat laptop_numpad_layouts | grep $laptop | head -1 | cut -d'=' -f1)
detected_layout_via_offline_table=$(cat laptop_numpad_layouts | grep $laptop | head -1 | cut -d'=' -f2)

if [ -z "$detected_layout_via_offline_table" ]; then
    echo "Could not automatically detect numpad layout for your laptop. Please create an issue (https://github.com/asus-linux-drivers/asus-touchpad-numpad-driver/issues)."
else
    for option in $(ls numpad_layouts); do
        if [ "$option" = "$detected_layout_via_offline_table.py" ]; then   
            read -r -p "Automatically recommended numpad layout: $detected_layout_via_offline_table (associated to $detected_laptop_via_offline_table). If not you can specify numpad layout later by yourself and please create an issue (https://github.com/asus-linux-drivers/asus-touchpad-numpad-driver/issues). Is that correct? [y/N]" response
            case "$response" in [yY][eE][sS]|[yY])
                model=$detected_layout_via_offline_table
                ;;
            *)
                ;;
            esac
        fi
    done
fi

if [ -z "$model" ]; then
    echo
    echo "Select your model keypad layout:"
    PS3='Please enter your choice '
    options=($(ls numpad_layouts) "Quit")
    select selected_opt in "${options[@]}"; do
        if [ "$selected_opt" = "Quit" ]; then
            exit 0
        fi

        for option in $(ls numpad_layouts); do
            if [ "$option" = "$selected_opt" ]; then
                model=${selected_opt::-3}
                break
            fi
        done

        if [ -z "$model" ]; then
            echo "invalid option $REPLY"
        else
            break
        fi
    done
fi

echo "Selected key layout $model"

echo "Installing asus touchpad service to /etc/systemd/system/"

xauthority=$(/usr/bin/xauth info | grep Authority | awk '{print $3}')
cat asus_touchpad.service | LAYOUT=$model XAUTHORITY=$xauthority envsubst '$LAYOUT $XAUTHORITY' >/etc/systemd/system/asus_touchpad_numpad.service

mkdir -p /usr/share/asus_touchpad_numpad-driver/numpad_layouts
mkdir -p /var/log/asus_touchpad_numpad-driver
install asus_touchpad.py /usr/share/asus_touchpad_numpad-driver/
install -t /usr/share/asus_touchpad_numpad-driver/numpad_layouts numpad_layouts/*.py

echo "i2c-dev" | tee /etc/modules-load.d/i2c-dev.conf >/dev/null

systemctl enable asus_touchpad_numpad

if [[ $? != 0 ]]; then
    echo "Something went wrong when enabling the asus_touchpad_numpad.service"
    exit 1
else
    echo "Asus touchpad service enabled"
fi

systemctl restart asus_touchpad_numpad
if [[ $? != 0 ]]; then
    echo "Something went wrong when enabling the asus_touchpad_numpad.service"
    exit 1
else
    echo "Asus touchpad service started"
fi

exit 0