#!/usr/bin/env bash

source non_sudo_check.sh

# Co-activator key selection for NumberPad activation
# This allows users to require holding a modifier key (like Alt, Ctrl, Shift)
# along with touching the Num_Lock area to activate the NumberPad.
# This prevents accidental activation while using the touchpad normally.

echo
echo "Co-activator key for NumberPad activation"
echo
echo "A co-activator key requires you to hold a modifier key while touching"
echo "the Num_Lock area to activate/deactivate the NumberPad. This helps"
echo "prevent accidental activation during normal touchpad use."
echo
echo "Select co-activator key:"
echo

if [ -z "$COACTIVATOR_KEY" ]; then
    PS3="Please enter your choice: "
    OPTIONS=("None" "Shift" "Ctrl" "RAlt" "LAlt" "Quit")
    select SELECTED_OPT in "${OPTIONS[@]}"; do
        case "$SELECTED_OPT" in
            "Quit")
                exit 0
                ;;
            "None"|"Shift"|"Ctrl"|"RAlt"|"LAlt")
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

# For layouts with Num_Lock in keys array, update the layout file now
# For layouts with top-right icon (no Num_Lock in keys), config will be updated
# by install_coactivator_apply.sh after the service creates the config file
if [ "$COACTIVATOR_KEY" != "None" ] && [ -n "$LAYOUT_NAME" ]; then
    LAYOUT_FILE="$INSTALL_DIR_PATH/layouts/$LAYOUT_NAME.py"

    if [ -f "$LAYOUT_FILE" ]; then
        # Check if layout has Num_Lock in keys array
        if grep -q '"Num_Lock"' "$LAYOUT_FILE" || grep -q "'Num_Lock'" "$LAYOUT_FILE"; then
            echo "Layout uses Num_Lock key - updating layout file..."
            
            # Use Python to update the layout file with the co-activator key
            python3 << EOF
import re

layout_file = "$LAYOUT_FILE"
coactivator = "$COACTIVATOR_KEY"

with open(layout_file, 'r') as f:
    content = f.read()

# Check if there's already a co-activator array pattern
if '["Num_Lock",' in content or "['Num_Lock'," in content:
    # Already has co-activator format, update it
    pattern = r'\[\s*["\']Num_Lock["\']\s*,\s*["\'][^"\']+["\']\s*\]'
    replacement = f'["Num_Lock", "{coactivator}"]'
    content = re.sub(pattern, replacement, content)
else:
    # Replace standalone "Num_Lock" with array format
    pattern = r'(?<=[,\[])\s*"Num_Lock"\s*(?=[,\]])'
    replacement = f'["Num_Lock", "{coactivator}"]'
    content = re.sub(pattern, replacement, content)

with open(layout_file, 'w') as f:
    f.write(content)

print(f"Layout file updated: {layout_file}")
EOF
        else
            echo "Layout uses top-right icon activation."
            echo "Co-activator will be applied after service starts."
        fi
    fi
fi

# Export for use in analytics and install_coactivator_apply.sh
export COACTIVATOR_KEY
