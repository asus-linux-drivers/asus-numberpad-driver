# Changelog

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
