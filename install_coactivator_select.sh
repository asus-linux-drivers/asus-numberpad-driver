#!/usr/bin/env bash

source non_sudo_check.sh

# ENV VARS
if [ -z "$INSTALL_DIR_PATH" ]; then
    INSTALL_DIR_PATH="/usr/share/asus-numberpad-driver"
fi
if [ -z "$CONFIG_FILE_DIR_PATH" ]; then
    CONFIG_FILE_DIR_PATH="$INSTALL_DIR_PATH"
fi
if [ -z "$CONFIG_FILE_NAME" ]; then
    CONFIG_FILE_NAME="numberpad_dev"
fi
if [ -z "$CONFIG_FILE_PATH" ]; then
    CONFIG_FILE_PATH="$CONFIG_FILE_DIR_PATH/$CONFIG_FILE_NAME"
fi

echo
echo "Co-activator key for NumberPad activation"
echo
echo "A co-activator key requires you to hold a modifier key while touching"
echo "the Num_Lock area to activate the NumberPad. This helps"
echo "prevent accidental activation during touchpad use."
echo
echo "Select co-activator key:"
echo

if [ -z "$COACTIVATOR_KEY" ]; then
    PS3="Please enter your choice: "
    OPTIONS=("None" "Shift" "Control" "Alt" "Quit")
    select SELECTED_OPT in "${OPTIONS[@]}"; do
        case "$SELECTED_OPT" in
            "Quit")
                exit 0
                ;;
            "None"|"Shift"|"Control"|"Alt")
                COACTIVATOR_KEY="$SELECTED_OPT"
                break
                ;;
            *)
                echo "Invalid option $REPLY"
                ;;
        esac
    done
fi

echo
echo "Selected co-activator key: $COACTIVATOR_KEY"

if [ "$COACTIVATOR_KEY" != "None" ]; then
    LAYOUT_FILE="$INSTALL_DIR_PATH/layouts/$LAYOUT_NAME.py"

    if [ -f "$LAYOUT_FILE" ]; then

        # check if selected layout has Num_Lock in keys array
        if grep -q '"Num_Lock"' "$LAYOUT_FILE" || grep -q "'Num_Lock'" "$LAYOUT_FILE"; then
            echo "Selected layout uses Num_Lock key - updating layout file..."

            # replace any occurrence of "Num_Lock" in an array with ["Num_Lock", "<coactivator>"]
            sudo sed -i \
                "s/\"Num_Lock\"/[\"Num_Lock\", \"$COACTIVATOR_KEY\"]/g" \
                "$LAYOUT_FILE"
        fi
    fi

    echo "Applying co-activator key ($COACTIVATOR_KEY) to config file..."

    if [ ! -f "$CONFIG_FILE_PATH" ]; then
        echo "[main]" | sudo tee "$CONFIG_FILE_PATH" > /dev/null
    fi

    # check if the setting already exists
    if grep -q "top_right_icon_coactivator_key" "$CONFIG_FILE_PATH"; then
        sudo sed -i "s/top_right_icon_coactivator_key.*/top_right_icon_coactivator_key = $COACTIVATOR_KEY/" "$CONFIG_FILE_PATH"
    else
        # add new setting under [main] section
        sudo sed -i "/\[main\]/a top_right_icon_coactivator_key = $COACTIVATOR_KEY" "$CONFIG_FILE_PATH"
    fi
fi
