#!/bin/bash

LIBINPUT_PATH=$(which libinput)

# Check if libinput was found
if [ -z "$LIBINPUT_PATH" ]; then
    echo "Error: libinput not found in the system path."
    exit 1
fi

COMMAND="$LIBINPUT_PATH list-devices"

# Sudoers file for the user inside /etc/sudoers.d/
SUDOERS_FILE="/etc/sudoers.d/$USER-numberpad-driver"

# Remove the sudoers file if it exists
if sudo test -f "$SUDOERS_FILE"; then
    echo "Removing existing $SUDOERS_FILE"
    sudo rm "$SUDOERS_FILE"
fi

# Create the sudoers file with the correct permissions
echo "Creating new $SUDOERS_FILE"
echo "$USER ALL=(ALL) NOPASSWD: $COMMAND" | sudo tee "$SUDOERS_FILE"

sudo chmod 0440 "$SUDOERS_FILE"
echo "$SUDOERS_FILE created and permissions set."
