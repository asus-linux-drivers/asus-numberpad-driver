#!/bin/bash

# Checking if the script is runned as root (via sudo or other)
if [[ $(id -u) != 0 ]]; then
    echo "Please run the installation script as root (using sudo for example)"
    exit 1
fi

logout_requested=false

# "root" by default or when is used --user it is "current user"
RUN_UNDER_USER=$USER

if [ "$1" = "--user" ]; then
    groupadd "uinput"
    echo 'KERNEL=="uinput", GROUP="uinput", MODE:="0660"' | sudo tee /etc/udev/rules.d/99-input.rules
    RUN_UNDER_USER=$SUDO_USER
    usermod -a -G "i2c,input,uinput" $RUN_UNDER_USER
    logout_requested=true
fi

echo "driver will run under user $RUN_UNDER_USER"

parent_path=$( cd "$(dirname "${BASH_SOURCE[0]}")" ; pwd -P )

# this works because sudo sets the environment variable SUDO_USER to the original username
session_id=$(loginctl | grep $SUDO_USER | head -1 | awk '{print $1}')
wayland_or_x11=$(loginctl show-session $session_id -p Type --value)

if [[ $(apt install 2>/dev/null) ]]; then
    echo 'apt is here' && apt -y install ibus libevdev2 i2c-tools python3-dev python3-libevdev python3-numpy python3-xlib python3-pyinotify
    if [ "$wayland_or_x11" = "x11" ]; then
        apt -y install xinput
    fi
elif [[ $(pacman -h 2>/dev/null) ]]; then
    # arch does not have header packages (python3-dev), headers are shipped with base? python package should contains almost latest version python3.*
    echo 'pacman is here' && pacman --noconfirm --needed -S ibus libevdev i2c-tools python python-pip
    if [ "$wayland_or_x11" = "x11" ]; then
        pacman --noconfirm --needed -S xorg-xinput
    fi

    runuser -u $RUN_UNDER_USER -- python3 -m pip install -r requirements.txt

    if [[ $? != 0 ]]; then
        echo "pip dependencies via file requirements.txt cannot be loaded correctly."
        exit 1
    fi
elif [[ $(dnf install 2>/dev/null) ]]; then
    echo 'dnf is here' && dnf -y install ibus libevdev i2c-tools python3-devel python3-pip
    if [ "$wayland_or_x11" = "x11" ]; then
        dnf -y install xinput
    fi

    runuser -u $RUN_UNDER_USER -- python3 -m pip install -r requirements.txt

    if [[ $? != 0 ]]; then
        echo "pip dependencies via file requirements.txt cannot be loaded correctly."
        exit 1
    fi
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

# used below for recommendation of layout & for correct brightness levels
DEVICE_ID=$(cat /proc/bus/input/devices | grep ".*Touchpad\"$" | sort | cut -f 3 -d" " | cut -f 2 -d ":" | head -1)

if [[ -z "$detected_layout_via_offline_table" || "$detected_layout_via_offline_table" == "none" ]]; then

    #VENDOR_ID="04f3"
    VENDOR_ID=$(cat /proc/bus/input/devices | grep ".*Touchpad\"$" | sort | cut -f 3 -d" " | cut -f 1 -d ":" | head -1)
    #echo $VENDOR_ID
    #DEVICE_ID="31b9"

    # https://github.com/mohamed-badaoui/asus-touchpad-numpad-driver/issues/87
    # https://github.com/asus-linux-drivers/asus-numberpad-driver/issues/95
    # Should return DEVICE_ID: 3101 of 'ELAN1406:00'
    # N: Name="ELAN9009:00 04F3:2C23 Touchpad"
    # N: Name="ELAN1406:00 04F3:3101 Touchpad"

    #echo $DEVICE_ID
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
        echo "Could not automatically detect numpad layout for your laptop. Please create an issue (https://github.com/asus-linux-drivers/asus-numberpad-driver/issues)."
    fi
fi

for option in $(ls numpad_layouts); do
    if [ "$option" = "$detected_layout_via_offline_table.py" ]; then   
        read -r -p "Automatically recommended numpad layout: $detected_layout_via_offline_table (associated to $detected_laptop_via_offline_table). You can specify numpad layout later by yourself. When is recommended layout wrong please create an issue (https://github.com/asus-linux-drivers/asus-numberpad-driver/issues). Do you want use recommended numpad layout? [y/N]" response
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

SPECIFIC_BRIGHTNESS_VALUES="$model-$DEVICE_ID"
if [ -f "numpad_layouts/$SPECIFIC_BRIGHTNESS_VALUES.py" ];
then
    model=$SPECIFIC_BRIGHTNESS_VALUES

    echo "Selected key layout specified to $model by touchpad ID $DEVICE_ID"
fi

echo "Installing asus touchpad service to /etc/systemd/system/"

source remove_previous_implementation_of_service.sh

CONFIG_FILE_DIR="/usr/share/asus_touchpad_numpad-driver"
CONFIG_FILE_NAME="asus_touchpad_numpad_dev"
CONF_FILE="$CONFIG_FILE_DIR/$CONFIG_FILE_NAME"

if [ "$wayland_or_x11" = "x11" ]; then
    echo "X11 is detected"

    xauthority=$(/usr/bin/xauth info | grep Authority | awk '{print $3}')
    xdisplay=$(echo $DISPLAY)
    cat asus_touchpad.X11.service | CONFIG_FILE_DIR="$CONFIG_FILE_DIR/" USER=$RUN_UNDER_USER LAYOUT=$model XDISPLAY=$display XAUTHORITY=$xauthority envsubst '$LAYOUT $XAUTHORITY $CONFIG_FILE_DIR' > /etc/systemd/system/asus_touchpad_numpad@.service

elif [ "$wayland_or_x11" = "wayland" ]; then
    echo "Wayland is detected, unfortunatelly you will not be able use feature: `Disabling Touchpad (e.g. Fn+special key) disables NumberPad aswell`, at this moment is supported only X11"

    cat asus_touchpad.service | CONFIG_FILE_DIR="$CONFIG_FILE_DIR/" USER=$RUN_UNDER_USER LAYOUT=$model envsubst '$LAYOUT $CONFIG_FILE_DIR' > /etc/systemd/system/asus_touchpad_numpad@.service
else
    echo "Wayland or X11 is not detected"

    cat asus_touchpad.service | CONFIG_FILE_DIR="$CONFIG_FILE_DIR/" USER=$RUN_UNDER_USER LAYOUT=$model envsubst '$LAYOUT $CONFIG_FILE_DIR' > /etc/systemd/system/asus_touchpad_numpad@.service
fi


mkdir -p /usr/share/asus_touchpad_numpad-driver/numpad_layouts
chown -R $RUN_UNDER_USER /usr/share/asus_touchpad_numpad-driver
mkdir -p /var/log/asus_touchpad_numpad-driver
install asus_touchpad.py /usr/share/asus_touchpad_numpad-driver/
install -t /usr/share/asus_touchpad_numpad-driver/numpad_layouts numpad_layouts/*.py

echo "Installing udev rules to /usr/lib/udev/rules.d/"

cp udev/90-numberpad-external-keyboard.rules /usr/lib/udev/rules.d/

echo "Added 90-numberpad-external-keyboard.rules"
mkdir -p /usr/share/asus_touchpad_numpad-driver/udev

cat udev/external_keyboard_is_connected.sh | CONFIG_FILE_DIR=$CONFIG_FILE_DIR envsubst '$CONFIG_FILE_DIR' > /usr/share/asus_touchpad_numpad-driver/udev/external_keyboard_is_connected.sh
cat udev/external_keyboard_is_disconnected.sh | CONFIG_FILE_DIR=$CONFIG_FILE_DIR envsubst '$CONFIG_FILE_DIR' > /usr/share/asus_touchpad_numpad-driver/udev/external_keyboard_is_disconnected.sh
chmod +x /usr/share/asus_touchpad_numpad-driver/udev/external_keyboard_is_connected.sh
chmod +x /usr/share/asus_touchpad_numpad-driver/udev/external_keyboard_is_disconnected.sh

udevadm control --reload-rules

echo "i2c-dev" | tee /etc/modules-load.d/i2c-dev.conf >/dev/null


CONFIG_FILE_DIFF=""
if test -f "$CONF_FILE"; then
	CONFIG_FILE_DIFF=$(diff <(grep -v '^#' $CONFIG_FILE_NAME) <(grep -v '^#' $CONF_FILE))
fi

if [ "$CONFIG_FILE_DIFF" != "" ]
then
    read -r -p "In system remains config file from previous installation. Do you want replace this with default config file [y/N]" response
    case "$response" in [yY][eE][sS]|[yY])
        # default will be autocreated, so that is why remove
		rm -f $CONF_FILE
		if [[ $? != 0 ]]
		then
			echo "$CONF_FILE cannot be removed correctly..."
			exit 1
		fi
        ;;
    *)
        ;;
    esac
else
	echo "Installed default config which can be futher modified here:"
    echo "$CONF_FILE"
fi


if [[ $(type gsettings 2>/dev/null) ]]; then
    echo "gsettings is here"
    read -r -p "Do you want automatically try install toggling script for XF86Calculator key? Slide from top left icon will then invoke/close detected calculator app. [y/N]" response
    case "$response" in [yY][eE][sS]|[yY])

        existing_shortcut_string=$(runuser -u $SUDO_USER gsettings get org.gnome.settings-daemon.plugins.media-keys custom-keybindings)
        #echo $existing_shortcut_string

        existing_shortcut_count=0
        if [[ "$existing_shortcut_string" != "@as []" ]]
        then
            IFS=', ' read -ra existing_shortcut_array <<< "$existing_shortcut_string"
            existing_shortcut_count="${#existing_shortcut_array[@]}"    
        fi

        new_shortcut_index=0
        if [[ $existing_shortcut_count != 0 ]]
        then
            for shortcut_index in "${!existing_shortcut_array[@]}"; do
                shortcut="${existing_shortcut_array[$shortcut_index]}"
                shortcut_index=$( echo $shortcut | cut -d/ -f 8 | sed 's/[^0-9]//g')
                if [[ "$shortcut_index" -gt "$new_shortcut_index" ]]; then
                    new_shortcut_index=$shortcut_index
                    #echo $shortcut_index
                fi
            done
            ((new_shortcut_index=new_shortcut_index+1))
            #echo $new_shortcut_index
            new_shortcut_string=${existing_shortcut_string::-2}", /org/gnome/settings-daemon/plugins/media-keys/custom-keybindings/custom$new_shortcut_index']"
        else
          new_shortcut_string=" ['/org/gnome/settings-daemon/plugins/media-keys/custom-keybindings/custom0']"  
        fi

        #echo $new_shortcut_index
        #echo $new_shortcut_string

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

        if [[ $(type flatpak 2>/dev/null && flatpak list | grep io.elementary.calculator 2>/dev/null) ]]; then
            echo "io.elementary.calculator here"

            mkdir -p /usr/share/asus_touchpad_numpad-driver/scripts
            cp scripts/io_elementary_calculator_toggle.sh /usr/share/asus_touchpad_numpad-driver/scripts/calculator_toggle.sh
            chmod +x /usr/share/asus_touchpad_numpad-driver/scripts/calculator_toggle.sh

            # this has to be empty (no doubled XF86Calculator)
            runuser -u $SUDO_USER gsettings set org.gnome.settings-daemon.plugins.media-keys calculator [\'\']
            runuser -u $SUDO_USER gsettings set org.gnome.settings-daemon.plugins.media-keys calculator-static [\'\']

            runuser -u $SUDO_USER gsettings set org.gnome.settings-daemon.plugins.media-keys custom-keybindings "${new_shortcut_string}"
            runuser -u $SUDO_USER gsettings set org.gnome.settings-daemon.plugins.media-keys.custom-keybinding:/org/gnome/settings-daemon/plugins/media-keys/custom-keybindings/custom$new_shortcut_index/ "name" "Calculator"
            runuser -u $SUDO_USER gsettings set org.gnome.settings-daemon.plugins.media-keys.custom-keybinding:/org/gnome/settings-daemon/plugins/media-keys/custom-keybindings/custom$new_shortcut_index/ "command" "bash /usr/share/asus_touchpad_numpad-driver/scripts/calculator_toggle.sh"
            runuser -u $SUDO_USER gsettings set org.gnome.settings-daemon.plugins.media-keys.custom-keybinding:/org/gnome/settings-daemon/plugins/media-keys/custom-keybindings/custom$new_shortcut_index/ "binding" "XF86Calculator"

            existing_shortcut_string=$(runuser -u $SUDO_USER gsettings get org.gnome.settings-daemon.plugins.media-keys custom-keybindings)
            #echo $existing_shortcut_string
            echo "Toggling script for calculator app io.elementary.calculator has been installed."

            logout_requested=true
        elif [[ $(type gnome-calculator 2>/dev/null) ]]; then
            echo "gnome-calculator here"

            mkdir -p /usr/share/asus_touchpad_numpad-driver/scripts
            cp scripts/gnome_calculator_toggle.sh /usr/share/asus_touchpad_numpad-driver/scripts/calculator_toggle.sh
            chmod +x /usr/share/asus_touchpad_numpad-driver/scripts/calculator_toggle.sh

            # this has to be empty (no doubled XF86Calculator)
            runuser -u $SUDO_USER gsettings set org.gnome.settings-daemon.plugins.media-keys calculator [\'\']
            runuser -u $SUDO_USER gsettings set org.gnome.settings-daemon.plugins.media-keys calculator-static [\'\']

            runuser -u $SUDO_USER gsettings set org.gnome.settings-daemon.plugins.media-keys custom-keybindings "${new_shortcut_string}"
            runuser -u $SUDO_USER gsettings set org.gnome.settings-daemon.plugins.media-keys.custom-keybinding:/org/gnome/settings-daemon/plugins/media-keys/custom-keybindings/custom$new_shortcut_index/ "name" "Calculator"
            runuser -u $SUDO_USER gsettings set org.gnome.settings-daemon.plugins.media-keys.custom-keybinding:/org/gnome/settings-daemon/plugins/media-keys/custom-keybindings/custom$new_shortcut_index/ "command" "bash /usr/share/asus_touchpad_numpad-driver/scripts/calculator_toggle.sh"
            runuser -u $SUDO_USER gsettings set org.gnome.settings-daemon.plugins.media-keys.custom-keybinding:/org/gnome/settings-daemon/plugins/media-keys/custom-keybindings/custom$new_shortcut_index/ "binding" "XF86Calculator"

            existing_shortcut_string=$(runuser -u $SUDO_USER gsettings get org.gnome.settings-daemon.plugins.media-keys custom-keybindings)
            #echo $existing_shortcut_string
            echo "Toggling script for calculator app gnome-calculator has been installed."

            logout_requested=true
        else
           echo "Automatic installing of toggling script for XF86Calculator key failed. Please create an issue (https://github.com/asus-linux-drivers/asus-numberpad-driver/issues)."
        fi
        ;;
    *)
        ;;
    esac
else
    echo "Automatic installing of toggling script for XF86Calculator key failed. Please create an issue (https://github.com/asus-linux-drivers/asus-numberpad-driver/issues)."
fi

systemctl daemon-reload

if [[ $? != 0 ]]; then
    echo "Something went wrong when was called systemctl daemon reload"
    exit 1
else
    echo "Systemctl daemon realod called succesfully"
fi

systemctl enable asus_touchpad_numpad@$RUN_UNDER_USER.service

if [[ $? != 0 ]]; then
    echo "Something went wrong when enabling the asus_touchpad_numpad.service"
    exit 1
else
    echo "Asus touchpad numpad service enabled"
fi

systemctl restart asus_touchpad_numpad@$RUN_UNDER_USER.service
if [[ $? != 0 ]]; then
    echo "Something went wrong when enabling the asus_touchpad_numpad.service"
    exit 1
else
    echo "Asus touchpad numpad service started"
fi

if [[ "$logout_requested" = true ]]
then

    echo "Install process requested to succesfull finish atleast log out or reboot"
    echo "Without that driver might not work properly"

    read -r -p "Do you want automatically reboot? [y/N]" response
    case "$response" in [yY][eE][sS]|[yY])
        reboot
        ;;
    *)
        ;;
    esac
fi

echo "Install finished"

exit 0