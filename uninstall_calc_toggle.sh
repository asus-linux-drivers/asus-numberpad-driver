#!/usr/bin/env bash

source non_sudo_check.sh

# ENV VARS
#
# None

existing_shortcut_string=$(gsettings get org.gnome.settings-daemon.plugins.media-keys custom-keybindings)

filtered_existing_shortcut_string="["
filtered_existing_shortcut_count=0

if [[ "$existing_shortcut_string" != "@as []" ]]; then
	IFS=', ' read -ra existing_shortcut_array <<< "$existing_shortcut_string"
    for shortcut_index in "${!existing_shortcut_array[@]}"; do
        shortcut="${existing_shortcut_array[$shortcut_index]}"
        shortcut_index=$( echo $shortcut | cut -d/ -f 8 | sed 's/[^0-9]//g')

        command=$(gsettings get org.gnome.settings-daemon.plugins.media-keys.custom-keybinding:/org/gnome/settings-daemon/plugins/media-keys/custom-keybindings/custom$shortcut_index/ 'command')
        if [[ "$command" = "'bash /usr/share/asus-numberpad-driver/scripts/calculator_toggle.sh'" ]]; then
			      ((filtered_existing_shortcut_count=filtered_existing_shortcut_count+1))
            echo "Removed shortcut added by installation of this driver for toggling calculator"
            gsettings reset-recursively org.gnome.settings-daemon.plugins.media-keys.custom-keybinding:/org/gnome/settings-daemon/plugins/media-keys/custom-keybindings/custom$shortcut_index/
        else
			      if [[ "$filtered_existing_shortcut_string" != "[" ]]; then
            	filtered_existing_shortcut_string="$filtered_existing_shortcut_string"", '/org/gnome/settings-daemon/plugins/media-keys/custom-keybindings/custom$shortcut_index/'"
            else
                filtered_existing_shortcut_string="$filtered_existing_shortcut_string""'/org/gnome/settings-daemon/plugins/media-keys/custom-keybindings/custom$shortcut_index/'"
            fi
		fi
    done

    filtered_existing_shortcut_string="$filtered_existing_shortcut_string"']'

	if [[ $filtered_existing_shortcut_count != 0 ]]; then
		gsettings set org.gnome.settings-daemon.plugins.media-keys custom-keybindings "${filtered_existing_shortcut_string}"
	fi
fi