# Changelog

## 5.1.0 (30.3.2024)

### Feature

- Not wait for untouch to handle action of slide gestures and activation
- Decreased necessary distance of touchpads width for slide gestures to success from `0.3` (1/3) ratio to `0.2` (1/5)
- Log touchpad pointer press, unpress only during debugging to avoid log spam
- Added sending info about usage of offline suggestions (GA)
- Added sending info about usage of online suggestions (GA)
- Updated offline table for auto suggestions from gathered data (GA)

### Fixed

- Fixed sending info about suggested layout (GA)
- Fixed prioritizing rows with more events count in offline table for auto suggestions

## 5.0.0 (23.3.2024)

### Feature

- Gathering anonymous data from users via GA (public dashboard https://lookerstudio.google.com/reporting/2bf9a72c-c675-4ff8-a3c6-2e1e8c1167b9)
- Automatically suggest layout based on gathered data from users via GA
- Added few laptops manually for layout be automatically suggested

### Fixed

- Idling disabled by default
- Fixed auto suggestion when are found multiple devices (e.g. for UX582ZW returned ASUE, ELAN)
- Dmidecode replaced with raw file access (package was not required to install and does not have any other usage)

## 4.4.1 (10.2.2024)

### Feature

- Idling (by default is brightness decreased after 10s by 30%)
- Init `zypper` package manager support
- By default is NumberPad not disabled due inactivity (the same behaviour as the Windows official driver)

## 4.4.0 (20.1.2024)

### Feature

- Support for NumberPad backlight of these laptops ASUF1416, ASUF1205, ASUF1204
- Support for devices with vendor `ASUF`
- Autodetection for model ROG Strix G16 G614JVR_G614JVR

### Fixed

- Fixed the driver for installing with specific Python3 via `pyenv`
- Support for devices with vendor `ASUP`
- Eliminated overspamming log file when is NumberPad not activated
- `pip3` is upgraded before is used

## 4.3.0 (12.1.2024)

### Refactored

- Is created Python3 virtual environment for currently detected Python version specially for the driver

### Fixed

- Fixed problem with missing Python library `smbus` on Arch (by using pip package instead of distribution one inside Python3 virtual environment)
- Fixed disabling & enabling Touchpad tapping on KDE via xinput (gsettings can not be used, works only for gnome)

## 4.2.2 (10.1.2024)

### Fixed

- At the end of install script call (optionally) reboot with full path `/sbin/reboot` for case when `/sbin` is not in `$PATH`
- Added udev rule for sure `/dev/i2c-xy` is owned by `i2c` group and has right permissions
- Fixed `asyncore` dependency for who use Python version bigger or equal to 3.12.0

### Refactored

- Removed `sudo chown :uinput /dev/uinput` because the same effect has `udev` rule after applying

## 4.2.1 (8.1.2024)

### Fixed

- Reverted removing of package `i2c-tools` as it caused permissions error

## 4.2.0 (7.1.2024)

### Feature

- Trigger for udev rules when are changed to avoid reboot
- Support for devices with vendor `ASUP`
- Autodetection for model `Vivobook_ASUSLaptop X1404ZA_F1404ZA`

### Fixed

- Replaced `i2c-tools` with Python library `smbus2` (initiated by distro which does not have sbin in `$PATH`)
- Added enabling and auto-load `uinput` kernel module
- Uninstall udev rules
- Checking whether layout contains only key events
- Improved message when was not detected any supported calc app
- Removed file `requirements.txt` because pip is not used
- Grammar of multiple texts (John Rose)
- Usage of `#!/usr/bin/env` for `bash/sh` instead of hardcoded path

## 4.1.5 (10.12.2023)

### Fixed

- Missing space in newly created virtual NumberPad device name

## 4.1.4 (23.11.2023)

### Fixed

- Removing driver folder during uninstalling

## 4.1.3 (22.11.2023)

### New feature

- Autodetection for model `Zenbook UM3402YAR_UM3402YA`

### Fixed

- Fixed online autodetection
- Fixed endless cycle activating & inactivating of NumberPad when was NumberPad disabled by disabling touchpad

## 4.1.2 (21.11.2023)

### Fixed

- Install script for calculator toggling (no longer break another shorcuts)

## 4.1.1 (30.10.2023)

### Fixed

- Install script for calculator toggling

## 4.1.0 (22.10.2023)

### New feature

- Added possibility define array of key events inside layouts (e.g. `[EV_KEY.KEY_LEFTSHIFT, EV_KEY.KEY_KP5]]`)

### Fixed

- Added missing dependency `xmllint` for auto suggestion

## 4.0.0 (11.10.2023)

### New feature

- The driver run under current user only

### Fixed

- Systemctl service dbus session environment variable for both Wayland/X11

### Refactored

- Install and uninstall script divided into multiple scripts which can run separately
- To new name asus-numberpad-driver

## 3.0.1 (26.9.2023)

### Fixed

- Fixed issue during installing when was compared config file to not existing local one or compared to modified considered as default

## 3.0.0 (23.9.2023)

### New feature

- Unicode hotkey can be changed via gsettings (`dconf`)
- Numpad layout can be chosen from direct numeric keys (by default) or unicode variant

### Fixed

- Found fix for `Invalid MIT-MAGIC-COOKIE-1 key` mentioned in FAQ
- Disable Tap to click when is installed synaptics driver
- When is reached maximum allowed attempts xinput is not used
- Added support for yuml (dnf predecessor)
- Added curl as dependency


## 2.9.5 (21.8.2023)

### Fixed

- Shown warning and allow to specify whether autostart systemctl service even on Wayland beucase may occurs black screen during logging in etc.

## 2.9.4 (11.8.2023)

### Fixed

- Fixed installation when group i2c, uniput or input does not exist yet

## 2.9.3 (5.8.2023)

### Fixed

- Fixed recogniting which calculator is installed and should be toggled

## 2.9.2 (28.7.2023)

### Fixed

- Fixed recogniting which calculator is installed and should be toggled

## 2.9.1 (18.7.2023)

### Fixed

- Sometimes might not be backlight used because was not send another activation value `0x60`
- Fixed releasing exclusively using of touchpad device for config value `enabled_touchpad_pointer=1`

## 2.9.0 (15.7.2023)

### New feature

- Protection against sending NumberPad key when is pointer button clicked across all `enabled_touchpad_pointer` modes
- Autoclean up in install and uninstall script with purpose keep only 1 shortcut in gsettings with this driver origin
- Question which warns about enabling systemctl service after reboot because in some cases is still unresolved black screen after login
- Autodetection for model `Vivobook_ASUSLaptop M3401QC_M3401QC`
- Autodetection for model `GX501VIK`

### Fixed

- `apt` changed to `apt-get` as first mentioned is not well usable in scripts

## v2.8.0 (1.7.2023)

### Fixed

- Fixed bug when was on wayland send any key with unicode code including A-F
- Preset 0-9 number keys without KP so drivers's device has not to be reinitialized when using first time (avoiding 1s sleep)

### Refactored

- On X11 is every time used X11 library to get key reflecting current layout (not used anymore even 0-9 KP keys for numbers)

## v2.7.9 (30.6.2023)

### Fixed

- Fixed bug when was pressed key with dot (`.`) and was used comma (`,`) instead on Turkish keyboard layout
- Fixed driver X11 service because have not had succesfully assigned `DISPLAY` variable from install script (might end with black screen after reboot)

### Refactored

- All layout keys except `KEY_BACKSPACE`, `KEY_KPENTER`, `KEY_NUMLOCK` redefined to send via `<left_shift>+<left_ctrl>+<U>+<0-F>+<space>`

## v2.7.8 (29.6.2023)

### New feature

- Uninstall script is newly not interrupted during and removes everything what can be removed

### Fixed

- Fixed bug when missing `xinput` tool dropped driver
- Fixed installation script for distributions with dnf package manager

### Refactoring

- Replaced pip packages entirely with packages from current distribution package managers
