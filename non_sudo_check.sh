
#!/bin/bash

if [[ $(id -u) == 0 ]]; then
    echo "Please run the install and uninstallation scripts as current user"
    exit 1
fi