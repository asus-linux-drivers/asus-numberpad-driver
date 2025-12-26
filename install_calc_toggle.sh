#!/usr/bin/env bash

source non_sudo_check.sh

# ENV VARS
if [ -z "$INSTALL_DIR_PATH" ]; then
    INSTALL_DIR_PATH="/usr/share/asus-numberpad-driver"
fi

echo "Calculator app"
echo

read -r -p "Do you want try to install toggling script for XF86Calculator key? [y/N] " response
case "$response" in
    [yY][eE][sS]|[yY])
        ;;
    *)
        exit 0
        ;;
esac

echo

if (command -v kquitapp5 >/dev/null 2>&1 || command -v kquitapp6 >/dev/null 2>&1) && command -v kcalc >/dev/null 2>&1; then

    echo "Detected kcalc"

    SCRIPT_DIR="$INSTALL_DIR_PATH/scripts"
    DESKTOP_DIR="$HOME/.local/share/applications"
    DESKTOP_FILE_NAME="kcalc-toggle.desktop"
    DESKTOP_FILE="$DESKTOP_DIR/$DESKTOP_FILE_NAME"
    SHORTCUTS_FILE="$HOME/.config/kglobalshortcutsrc"

    sudo mkdir -p "$SCRIPT_DIR"
    mkdir -p "$DESKTOP_DIR"

    sudo cp scripts/kcalc_calculator_toggle.sh "$SCRIPT_DIR/calculator_toggle.sh"
    sudo chmod +x "$SCRIPT_DIR/calculator_toggle.sh"

    cat > "$DESKTOP_FILE" <<EOF
[Desktop Entry]
Type=Application
Name=KCalc Toggle
Exec=$SCRIPT_DIR/calculator_toggle.sh
NoDisplay=true
X-KDE-StartupNotify=false
EOF

    chmod 644 "$DESKTOP_FILE"
    update-desktop-database "$DESKTOP_DIR" >/dev/null 2>&1

    if ! grep -q "^\[$DESKTOP_FILE_NAME\]" "$SHORTCUTS_FILE" 2>/dev/null; then
        cat >> "$SHORTCUTS_FILE" <<EOF

[$DESKTOP_FILE_NAME]
_launch=XF86Calculator,none,Toggle KCalc calculator
EOF
    fi

    echo "Toggling script for calculator app KCalc has been installed."
    

elif command -v gsettings >/dev/null 2>&1; then

    CALC_TOGGLE=1

    EXISTING_SHORTCUT_STRING=$(gsettings get org.gnome.settings-daemon.plugins.media-keys custom-keybindings)

    NEW_SHORTCUT_INDEX=0
    filtered_existing_shortcut_string="["

    if [[ "$EXISTING_SHORTCUT_STRING" != "@as []" ]]; then
        IFS=', ' read -ra existing_shortcut_array <<< "$EXISTING_SHORTCUT_STRING"
        for shortcut_index in "${!existing_shortcut_array[@]}"; do
            shortcut="${existing_shortcut_array[$shortcut_index]}"
            shortcut_index=$( echo $shortcut | cut -d/ -f 8 | sed 's/[^0-9]//g')

            # looking for first free highest index (gaps will not be used for sure)
            if [[ "$shortcut_index" -gt "$NEW_SHORTCUT_INDEX" ]]; then
                NEW_SHORTCUT_INDEX=$shortcut_index
            fi

            # filter out already added the same shortcuts by this driver (can be caused by running install script multiple times so clean and then add only 1 new - we want no duplicates)
            command=$(gsettings get org.gnome.settings-daemon.plugins.media-keys.custom-keybinding:/org/gnome/settings-daemon/plugins/media-keys/custom-keybindings/custom$shortcut_index/ 'command')
            if [[ "$command" != "'bash $INSTALL_DIR_PATH/scripts/calculator_toggle.sh'" ]]; then
                if [[ "$filtered_existing_shortcut_string" != "[" ]]; then
                    filtered_existing_shortcut_string="$filtered_existing_shortcut_string"", '/org/gnome/settings-daemon/plugins/media-keys/custom-keybindings/custom$shortcut_index/'"
                else
                    filtered_existing_shortcut_string="$filtered_existing_shortcut_string""'/org/gnome/settings-daemon/plugins/media-keys/custom-keybindings/custom$shortcut_index/'"
                fi
            else
                echo "Found already existing duplicated shortcut for toggling calculator, will be removed"
                gsettings reset-recursively org.gnome.settings-daemon.plugins.media-keys.custom-keybinding:/org/gnome/settings-daemon/plugins/media-keys/custom-keybindings/custom$shortcut_index/
            fi
        done
        ((NEW_SHORTCUT_INDEX=NEW_SHORTCUT_INDEX+1))

        filtered_existing_shortcut_string="$filtered_existing_shortcut_string"']'

        if [[ "$filtered_existing_shortcut_string" != "[" ]]; then
            new_shortcut_string=${filtered_existing_shortcut_string::-2}"', '/org/gnome/settings-daemon/plugins/media-keys/custom-keybindings/custom$NEW_SHORTCUT_INDEX/']"
        else
            # after filtering duplicated shortcuts array of shortcuts is completely empty
            new_shortcut_string=" ['/org/gnome/settings-daemon/plugins/media-keys/custom-keybindings/custom0/']"
        fi
    else
        # array of shortcuts is completely empty
        new_shortcut_string=" ['/org/gnome/settings-daemon/plugins/media-keys/custom-keybindings/custom0/']"
    fi

    IS_INSTALLED_ELEMENTARY_OS_CALCULATOR=$((type io.elementary.calculator || flatpak list | grep io.elementary.calculator) &>/dev/null ; echo $?)
    if [ $IS_INSTALLED_ELEMENTARY_OS_CALCULATOR == "0" ]; then
        CALC_TOGGLE_SUPPORTED_CALC=1
        echo "Detected io.elementary.calculator"
    fi

    IS_INSTALLED_GNOME_OS_CALCULATOR=$((type gnome-calculator || flatpak list | grep org.gnome.Calculator) &>/dev/null ; echo $?)
    if [ $IS_INSTALLED_GNOME_OS_CALCULATOR == "0" ]; then
        CALC_TOGGLE_SUPPORTED_CALC=1
        echo "Detected gnome-calculator"
    fi

    if [ $IS_INSTALLED_GNOME_OS_CALCULATOR == "1" ] && [ $IS_INSTALLED_ELEMENTARY_OS_CALCULATOR == "1" ]; then
        echo "Automatic installing of toggling script for XF86Calculator key failed. Was not detected any supported calculator (gnome-calculator && io.elementary.calculator). You must associate the toggling script with the key EV_KEY.KEY_CALC by your own for this feature."
        echo
        echo "Example of the script for ElementaryOS calculator:"
        echo
        echo "\`\`\`"
        cat scripts/io_elementary_calculator_toggle.sh
        echo
        echo "\`\`\`"
        echo
        echo "or Gnome calculator:"
        echo
        echo "\`\`\`"
        cat scripts/gnome_calculator_toggle.sh
        echo
        echo "\`\`\`"
    elif [[ $IS_INSTALLED_ELEMENTARY_OS_CALCULATOR -eq 0 ]]; then
        echo "Setting up for io.elementary.calculator"

        sudo mkdir -p $INSTALL_DIR_PATH/scripts
        sudo cp scripts/io_elementary_calculator_toggle.sh $INSTALL_DIR_PATH/scripts/calculator_toggle.sh
        sudo chmod +x $INSTALL_DIR_PATH/scripts/calculator_toggle.sh

        # this has to be empty (no doubled XF86Calculator)
        gsettings set org.gnome.settings-daemon.plugins.media-keys calculator [\'\']
        gsettings set org.gnome.settings-daemon.plugins.media-keys calculator-static [\'\']

        gsettings set org.gnome.settings-daemon.plugins.media-keys custom-keybindings "${new_shortcut_string}"
        gsettings set org.gnome.settings-daemon.plugins.media-keys.custom-keybinding:/org/gnome/settings-daemon/plugins/media-keys/custom-keybindings/custom$NEW_SHORTCUT_INDEX/ "name" "Calculator"
        gsettings set org.gnome.settings-daemon.plugins.media-keys.custom-keybinding:/org/gnome/settings-daemon/plugins/media-keys/custom-keybindings/custom$NEW_SHORTCUT_INDEX/ "command" "bash $INSTALL_DIR_PATH/scripts/calculator_toggle.sh"
        gsettings set org.gnome.settings-daemon.plugins.media-keys.custom-keybinding:/org/gnome/settings-daemon/plugins/media-keys/custom-keybindings/custom$NEW_SHORTCUT_INDEX/ "binding" "XF86Calculator"

        EXISTING_SHORTCUT_STRING=$(gsettings get org.gnome.settings-daemon.plugins.media-keys custom-keybindings)

        echo "Toggling script for calculator app io.elementary.calculator has been installed."

    elif [[ $IS_INSTALLED_GNOME_OS_CALCULATOR -eq 0 ]]; then
        echo "Setting up for gnome-calculator"

        sudo mkdir -p $INSTALL_DIR_PATH/scripts
        sudo cp scripts/gnome_calculator_toggle.sh $INSTALL_DIR_PATH/scripts/calculator_toggle.sh
        sudo chmod +x $INSTALL_DIR_PATH/scripts/calculator_toggle.sh

        # this has to be empty (no doubled XF86Calculator)
        gsettings set org.gnome.settings-daemon.plugins.media-keys calculator [\'\']
        gsettings set org.gnome.settings-daemon.plugins.media-keys calculator-static [\'\']

        gsettings set org.gnome.settings-daemon.plugins.media-keys custom-keybindings "${new_shortcut_string}"
        gsettings set org.gnome.settings-daemon.plugins.media-keys.custom-keybinding:/org/gnome/settings-daemon/plugins/media-keys/custom-keybindings/custom$NEW_SHORTCUT_INDEX/ "name" "Calculator"
        gsettings set org.gnome.settings-daemon.plugins.media-keys.custom-keybinding:/org/gnome/settings-daemon/plugins/media-keys/custom-keybindings/custom$NEW_SHORTCUT_INDEX/ "command" "bash $INSTALL_DIR_PATH/scripts/calculator_toggle.sh"
        gsettings set org.gnome.settings-daemon.plugins.media-keys.custom-keybinding:/org/gnome/settings-daemon/plugins/media-keys/custom-keybindings/custom$NEW_SHORTCUT_INDEX/ "binding" "XF86Calculator"

        EXISTING_SHORTCUT_STRING=$(gsettings get org.gnome.settings-daemon.plugins.media-keys custom-keybindings)

        echo "Toggling script for calculator app gnome-calculator has been installed."
    fi

else
    echo "Automatic installing of toggling script for XF86Calculator key failed. You must associate the toggling script with the key EV_KEY.KEY_CALC by your own for this feature."
    echo
    echo "Example of the script for ElementaryOS calculator:"
    echo
    echo "\`\`\`"
    cat scripts/io_elementary_calculator_toggle.sh
    echo
    echo "\`\`\`"
    echo
    echo "or Gnome calculator:"
    echo
    echo "\`\`\`"
    cat scripts/gnome_calculator_toggle.sh
    echo
    echo "\`\`\`"
fi