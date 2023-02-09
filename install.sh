#!/bin/bash

# Checking if the script is runned as root (via sudo or other)
if [[ $(id -u) != 0 ]]; then
    echo "Please run the installation script as root (using sudo for example)"
    exit 1
fi

parent_path=$( cd "$(dirname "${BASH_SOURCE[0]}")" ; pwd -P )

# this works because sudo sets the environment variable SUDO_USER to the original username
session_id=$(loginctl | grep $SUDO_USER | awk '{print $1}')
wayland_or_x11=$(loginctl show-session $session_id -p Type --value)

if [[ $(apt install 2>/dev/null) ]]; then
    echo 'apt is here' && apt -y install libevdev2 i2c-tools python3-dev python3-pip
    if [ "$wayland_or_x11" = "x11" ]; then
        apt -y install xinput
    fi
elif [[ $(pacman -h 2>/dev/null) ]]; then
    # arch does not have header packages (python3-dev), headers are shipped with base? python package should contains almost latest version python3.*
    echo 'pacman is here' && pacman --noconfirm --needed -S libevdev i2c-tools python python-pip
    if [ "$wayland_or_x11" = "x11" ]; then
        pacman --noconfirm --needed -S xorg-xinput
    fi
elif [[ $(dnf install 2>/dev/null) ]]; then
    echo 'dnf is here' && dnf -y install libevdev i2c-tools python3-devel python3-pip
    if [ "$wayland_or_x11" = "x11" ]; then
        dnf -y install xinput
    fi
fi
python3 -m pip install -r requirements.txt

# Checking if the pip dependencies are successfuly loaded
if [[ $? != 0 ]]; then
    echo "pip dependencies via file requirements.txt cannot be loaded correctly."
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

if [[ -z "$detected_layout_via_offline_table" || "$detected_layout_via_offline_table" == "none" ]]; then
    
    #VENDOR_ID="04f3"
    VENDOR_ID=$(cat /proc/bus/input/devices | grep ".*Touchpad\"$" | cut -f 3 -d" " | cut -f 1 -d ":")
    #DEVICE_ID="31b9"
    DEVICE_ID=$(cat /proc/bus/input/devices | grep ".*Touchpad\"$" | cut -f 3 -d" " | cut -f 2 -d ":")
    USER_AGENT="user-agent-name-here"
    DEVICE_LIST_CURL_URL="https://linux-hardware.org/?view=search&vendorid=$VENDOR_ID&deviceid=$DEVICE_ID&typeid=input%2Fkeyboard"
    #echo $CURL_URL
    DEVICE_LIST_CURL=$(curl --user-agent "$USER_AGENT" "$DEVICE_LIST_CURL_URL" )
    #echo $RESULT
    DEVICE_URL=$(echo $DEVICE_LIST_CURL | xmllint --html --xpath '//td[@class="device"]//a[1]/@href' 2>/dev/null - | cut -f2 -d"\"")
    #echo $DEVICE_URL_LIST
    LAPTOP_LIST_CURL_URL="https://linux-hardware.org$DEVICE_URL"
    #echo $LAPTOP_LIST_CURL_URL
    LAPTOP_LIST_CURL=$(curl --user-agent "$USER_AGENT" "$LAPTOP_LIST_CURL_URL" )
    #echo $LAPTOP_LIST_CURL
    LAPTOP_LIST=$(echo $LAPTOP_LIST_CURL | xmllint --html --xpath '//table[contains(@class, "computers_list")]//tr/td[3]/span/@title' 2>/dev/null -)
    #echo $LAPTOP_LIST

    # create laptop array
    #
    # [0] = Zenbook UX3402ZA_UX3402ZA
    # [1] = Zenbook UM5401QAB_UM5401QA
    # ...
    #
    IFS='\"' read -r -a array <<< $(echo $LAPTOP_LIST)
    for index in "${!array[@]}"
    do
        if [[ "${array[index]}" != " title=" && "${array[index]}" != "title=" ]]; then
            LAPTOP_NAME="${array[index]}"
            #echo $LAPTOP_NAME

            probe_laptop=$( echo $LAPTOP_NAME | rev | cut -d ' ' -f1 | rev | cut -d "_" -f1)
            #echo $probe_laptop
            detected_laptop_via_offline_table=$(cat laptop_numpad_layouts | grep $probe_laptop | head -1 | cut -d'=' -f1)
            detected_layout_via_offline_table=$(cat laptop_numpad_layouts | grep $probe_laptop | head -1 | cut -d'=' -f2)

            if [[ -z "$detected_layout_via_offline_table" || "$detected_layout_via_offline_table" == "none" ]]; then
                continue
            else
                break
            fi
        fi
    done

    if [[ -z "$detected_layout_via_offline_table" || "$detected_layout_via_offline_table" == "none" ]]; then
        echo "Could not automatically detect numpad layout for your laptop. Please create an issue (https://github.com/asus-linux-drivers/asus-touchpad-numpad-driver/issues)."
    fi
fi

for option in $(ls numpad_layouts); do
    if [ "$option" = "$detected_layout_via_offline_table.py" ]; then   
        read -r -p "Automatically recommended numpad layout: $detected_layout_via_offline_table (associated to $detected_laptop_via_offline_table). You can specify numpad layout later by yourself. When is recommended layout wrong please create an issue (https://github.com/asus-linux-drivers/asus-touchpad-numpad-driver/issues). Do you want use recommended numpad layout? [y/N]" response
        case "$response" in [yY][eE][sS]|[yY])
            model=$detected_layout_via_offline_table
            ;;
        *)
            ;;
        esac
    fi
done

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

if [ "$wayland_or_x11" = "x11" ]; then
    echo "X11 is detected"

    xauthority=$(/usr/bin/xauth info | grep Authority | awk '{print $3}')
    cat asus_touchpad.X11.service | LAYOUT=$model CONFIG_FILE_DIR="/usr/share/asus_touchpad_numpad-driver/" XAUTHORITY=$xauthority envsubst '$LAYOUT $XAUTHORITY $CONFIG_FILE_DIR' > /etc/systemd/system/asus_touchpad_numpad.service

elif [ "$wayland_or_x11" = "wayland" ]; then
    echo "Wayland is detected, unfortunatelly you will not be able use feature: `Disabling Touchpad (e.g. Fn+special key) disables NumberPad aswell`, at this moment is supported only X11"

    cat asus_touchpad.service | LAYOUT=$model CONFIG_FILE_DIR="/usr/share/asus_touchpad_numpad-driver/" envsubst '$LAYOUT $CONFIG_FILE_DIR' > /etc/systemd/system/asus_touchpad_numpad.service
else
    echo "Wayland or X11 is not detected"

    cat asus_touchpad.service | LAYOUT=$model CONFIG_FILE_DIR="/usr/share/asus_touchpad_numpad-driver/" envsubst '$LAYOUT $CONFIG_FILE_DIR' > /etc/systemd/system/asus_touchpad_numpad.service
fi


mkdir -p /usr/share/asus_touchpad_numpad-driver/numpad_layouts
mkdir -p /var/log/asus_touchpad_numpad-driver
install asus_touchpad.py /usr/share/asus_touchpad_numpad-driver/
install -t /usr/share/asus_touchpad_numpad-driver/numpad_layouts numpad_layouts/*.py

echo "Installing udev rules to /usr/lib/udev/rules.d/"

cp udev/90-numberpad-external-keyboard.rules /usr/lib/udev/rules.d/

echo "Added 90-numberpad-external-keyboard.rules"
mkdir -p /usr/share/asus_touchpad_numpad-driver/udev
cat udev/external_keyboard_is_connected.sh | CONFIG_FILE_DIR="/usr/share/asus_touchpad_numpad-driver/" envsubst '$CONFIG_FILE_DIR' > /usr/share/asus_touchpad_numpad-driver/udev/external_keyboard_is_connected.sh
cat udev/external_keyboard_is_disconnected.sh | CONFIG_FILE_DIR="/usr/share/asus_touchpad_numpad-driver/" envsubst '$CONFIG_FILE_DIR' > /usr/share/asus_touchpad_numpad-driver/udev/external_keyboard_is_disconnected.sh
chmod +x /usr/share/asus_touchpad_numpad-driver/udev/external_keyboard_is_connected.sh
chmod +x /usr/share/asus_touchpad_numpad-driver/udev/external_keyboard_is_disconnected.sh

udevadm control --reload-rules

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

if [[ $(type gsettings 2>/dev/null) ]]; then
    echo "gsettings is here"
    read -r -p "Do you want automatically try install toggling script for XF86Calculator key? Slide from top left icon will then invoke/close detected calculator app. [y/N]" response
    case "$response" in [yY][eE][sS]|[yY])

        # credits (https://unix.stackexchange.com/questions/323160/gnome3-adding-keyboard-custom-shortcuts-using-dconf-without-need-of-logging)
        existing_shortcut_string=$(runuser -u $SUDO_USER gsettings get org.gnome.settings-daemon.plugins.media-keys custom-keybindings)
        #echo $existing_shortcut_string
        exst_str_len=$((${#existing_shortcut_string}))
        IFS=', ' read -ra existing_shortcut_array <<< "$existing_shortcut_string"
        existing_shortcut_count="${#existing_shortcut_array[@]}"
        #echo $existing_shortcut_count
        new_shortcut_index=$(("$existing_shortcut_count"))
        #echo $new_shortcut_index
        declaration_string=' ['
        for (( i=0; i<="$existing_shortcut_count"; i++ )); do
            if (( $i == 0 ))
            then
                declaration_string="$declaration_string""'/org/gnome/settings-daemon/plugins/media-keys/custom-keybindings/custom$i/'"
            else
                declaration_string="$declaration_string"", '/org/gnome/settings-daemon/plugins/media-keys/custom-keybindings/custom$i/'"
            fi
        done
        declaration_string="$declaration_string"']'

        #echo $declaration_string

        if [[ $(type flatpak 2>/dev/null && flatpak list | grep io.elementary.calculator 2>/dev/null) ]]; then
            echo "io.elementary.calculator here"

            mkdir -p /usr/share/asus_touchpad_numpad-driver/scripts
            install -t /usr/share/asus_touchpad_numpad-driver/scripts scripts/calculator_toggle.sh
            chmod +x /usr/share/asus_touchpad_numpad-driver/scripts scripts/calculator_toggle.sh

            runuser -u $SUDO_USER gsettings set org.gnome.settings-daemon.plugins.media-keys custom-keybindings "${declaration_string}"
            runuser -u $SUDO_USER gsettings set org.gnome.settings-daemon.plugins.media-keys.custom-keybinding:/org/gnome/settings-daemon/plugins/media-keys/custom-keybindings/custom$new_shortcut_index/ "name" "Calculator"
            runuser -u $SUDO_USER gsettings set org.gnome.settings-daemon.plugins.media-keys.custom-keybinding:/org/gnome/settings-daemon/plugins/media-keys/custom-keybindings/custom$new_shortcut_index/ "command" "bash /usr/share/asus_touchpad_numpad-driver/scripts/calculator_toggle.sh"
            runuser -u $SUDO_USER gsettings set org.gnome.settings-daemon.plugins.media-keys.custom-keybinding:/org/gnome/settings-daemon/plugins/media-keys/custom-keybindings/custom$new_shortcut_index/ "binding" "XF86Calculator"

            existing_shortcut_string=$(runuser -u $SUDO_USER gsettings get org.gnome.settings-daemon.plugins.media-keys custom-keybindings)
            #echo $existing_shortcut_string
            read -r -p "Toggling script for calculator app io.elementary.calculator has been installed. For it is functionality is required reboot. Reboot now? [y/N]" response
            case "$response" in [yY][eE][sS]|[yY])
                reboot
                ;;
            *)
                ;;
            esac
        else
           echo "Automatic installing of toggling script for XF86Calculator key failed. Please create an issue (https://github.com/asus-linux-drivers/asus-touchpad-numpad-driver/issues)."
        fi
        ;;
    *)
        ;;
    esac
else
    echo "Automatic installing of toggling script for XF86Calculator key failed. Please create an issue (https://github.com/asus-linux-drivers/asus-touchpad-numpad-driver/issues)."
fi

echo "Install finished"

exit 0