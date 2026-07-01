#!/usr/bin/env bash

source non_sudo_check.sh

version_ge() {
    [ "$(printf '%s\n' "$2" "$1" | sort -V | head -n1)" = "$2" ]
}

LIBINPUT_VERSION=$(libinput --version 2>/dev/null || true)

if [[ $LIBINPUT_VERSION == 1.31.* ]]; then
    REQUIRED=1.31.3
else
    REQUIRED=1.30.4
fi

# https://github.com/asus-linux-drivers/asus-dialpad-driver/issues/40
if ! version_ge "$LIBINPUT_VERSION" "$REQUIRED"; then
    echo "WARNING: libinput $LIBINPUT_VERSION detected."
    echo "This version is affected by CVE-2026-50292 (https://github.com/advisories/GHSA-jcq8-v68h-2c44)."
    echo "This driver adds current user '${USER}' to the 'uinput' group, increasing the impact of this vulnerability."
    echo "Please update libinput before continuing, or proceed at your own risk."
    read -rp "Continue anyway? [y/N] " confirm
    [[ "$confirm" =~ ^[Yy]$ ]] || exit 1
fi