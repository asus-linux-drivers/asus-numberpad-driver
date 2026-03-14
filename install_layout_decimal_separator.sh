#!/usr/bin/env bash

source non_sudo_check.sh

SELECTED_LAYOUT="$INSTALL_DIR_PATH/layouts/$LAYOUT_NAME.py"

if grep -q '"period"' "$SELECTED_LAYOUT"; then

    echo
    echo "Your selected layout contains a field with '.' as decimal separator but sometimes you want to use ',' instead."
    echo

    read -r -p "Do you want to replace '.' with ',' on the NumberPad? [y/N] " RESPONSE

    case "$RESPONSE" in
        [yY][eE][sS]|[yY])

            sed -i 's/"period"/"comma"/g' "$SELECTED_LAYOUT"

            ;;
        *)
            ;;
    esac
fi