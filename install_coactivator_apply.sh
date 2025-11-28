#!/usr/bin/env bash

# Apply the co-activator key setting to the config file
# This runs AFTER the service has started and created the config file

if [ "$COACTIVATOR_KEY" != "None" ] && [ -n "$COACTIVATOR_KEY" ]; then
    CONFIG_FILE="$CONFIG_FILE_PATH"

    # Wait a moment for the service to create the config file
    sleep 2

    if [ -f "$CONFIG_FILE" ]; then
        echo "Applying co-activator key ($COACTIVATOR_KEY) to config file..."

        # Check if the setting already exists
        if grep -q "top_right_icon_coactivator_key" "$CONFIG_FILE"; then
            # Update existing setting
            sudo sed -i "s/top_right_icon_coactivator_key.*/top_right_icon_coactivator_key = $COACTIVATOR_KEY/" "$CONFIG_FILE"
        else
            # Add new setting under [main] section
            sudo sed -i "/\[main\]/a top_right_icon_coactivator_key = $COACTIVATOR_KEY" "$CONFIG_FILE"
        fi

        echo "Co-activator key set to: $COACTIVATOR_KEY"

        # Restart the service to apply the new setting
        echo "Restarting service to apply co-activator setting..."
        systemctl --user restart asus_numberpad_driver@$USER.service 2>/dev/null || true
    else
        echo "Warning: Config file not found at $CONFIG_FILE"
        echo "Co-activator key will need to be set manually."
    fi
fi
