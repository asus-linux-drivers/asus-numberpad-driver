# Changelog

## 6.8.5 (27.1.2026)

### Fixed

- Dependency for wayland only only `pywayland` outside of `requirements.wayland.txt`

## 6.8.4 (23.1.2026)

### Fixed

- Previously added `i2c` group as not a system by recreating

## 6.8.3 (16.1.2026)

### Fixed

- Added collecting of device_addresses (`0x38` or `0x15`) for kernel driver development purpose

## 6.8.2 (12.1.2026)

### Fixed

- Co-activator key selection for NumberPad activation
- Do not exit when is buffer overloaded because restart by parent layer (systemd) is not guaranteed
- Missing bad evaluation of the returned code from each `subprocess.call`

## 6.8.1 (3.1.2026)

### Fixed

- Co-activator key selection for NumberPad activation 
- Running not under systemd service (when optional `systemd-python` pip package is not installed)
- When xauthority has in `tmp` folder multiple files

## 6.8.0 (2.1.2026)

### Fixed

- Detection of plasma environment (e.g. `plasmawayland` or `plasma-x11`)
- Missing support for `qdbus6`
- Plasma version detection using `kinfo`

### Feature

- Added toggling of default calculator app KCalc on KDE

## 6.7.1 (22.12.2025)

### Fixed

- Co-activator key selection for NumberPad activation

## 6.7.0 (16.12.2025)

### Fixed

- Missing auto-installation of `qdbus` in supported distributions when using KDE Plasma (credits @g3nsvrv)
- The package `smbus2` was replaced by `python-periphery` because has missing support for `python3.14` (yet) and `i2ctransfer` was added as alternative for `i2c` communication
- Nix `system` has been changed to `stdenv.hostPlatform.system` (credits @SamueleFacenda)
- Sending driver's version to GA
- `uinput`, `i2c`, `input` changed to a system groups (@vitaminace33)
- Setting up appropriate (not a static) `KERNEL` and `SUBSYSTEM` for `i2c` and `uinput` udev rules

### Feature

- Added co-activator key selection for NumberPad activation (credits @s-badran)
- Updated offline table for auto suggestions from gathered data (GA)

## 6.6.0 (8.10.2025)

### Fixed

- Default value of `GNOME_GLIB_AVAILABLE`
- Installing `pip` package `pywayland` when is not required
- Added missing `python3` dependency when using `systemd`

### Feature

- Attempt to enhance used `xlib` not shipping `xkb` module with `xcffib`
- Added check whether is python atleast in version 3.10 because `xcffib` requirements
- By default NumberPad automatically disable after 2 mins

## 6.5.1 (16.6.2025)

### Fixed

- Updated offline table for auto suggestions from gathered data (GA)
- Reduced maximum allowed number of failures (gsettings, qdbus, xinput)
- Installation without systemd (lib package for `systemd` moved on separate line as it can throw error)
- Different runtime `WAYLAND_DISPLAY` (credits @scientiac)
- Device check (option of `sed` for GNU only to POSIX-compliant)
- NixOS module (credits @scientiac)
- Delay when is layout changed on gnome (re-implemented using `GLib`)
- Support for `eopkg` package manager

## 6.5.0 (22.02.2025)

### Fixed

- Updated offline table for auto suggestions from gathered data (GA)

### Feature

- Added support for `eopkg` package manager
- Added possibility to disable top left icon slide function separately for activated and not activated NumberPad via `top_left_icon_slide_func_disabled`

## 6.4.1 (12.12.2024)

### Fixed

- The `i2c` tools search under `/usr/sbin`
- Missing `apt` dependencies `pkg-config` and `libsystemd-dev` for `pip` package `systemd-python`
- Missing `wayland-dev` package
- Missing info about installing toggling script for not supported calculator

### Feature

- Init package manager `rpm-ostree`

## 6.4.0 (4.10.2024)

### Fixed

- Updated offline table for auto suggestions from gathered data (GA)
- Touchpad detection by just filtering out touchpads with `9009` that have only duo laptops
- Detection of `dnf` for v5
- Filtering out repeating value 2 of event `BTN_TOOL_*`
- Log level of failures of commands for another distros (from `error` to `debug`)
- Internal modifier keys (add delay `0.005s` for composed keys only, credits @benj3578)
- Releasing list of keys in reverse order so modifiers wrap up other keys
- Uninstalling power supply mode
- Unification of install path under `INSTALL_DIR_PATH`
- Propagating env variables thought install/uninstall scripts
- Slot ending when doing slide gesture from top icons

### Feature

- Removed `which` as unnecessary dependency
- Simplified detection of package managers using `command`
- Added config value that allows to limit backlight levels defined in layout file rotated by top left icon func to 2 levels only (min/max, windows official driver behaviour) (credits @scientiac)
- Init `flake` for NixOS (credits @scientiac)
- Send runtime logs to the journal
- Not allow lowering x or y axis during movement

## 6.3.4 (19.9.2024)

### Fixed

- Updated offline table for auto suggestions from gathered data (GA)
- Touchpad detection by just filtering out touchpad with 9009 that have only duo laptops
- Missing releasing lock for numlock after attempt of activating NumberPad when is touchpad disabled (credits @sleddev)
- Obtaining touchpad status enabled/disabled using `qdbus` for `kde` (credits @sleddev)
- Toggling tap-to-click using `qdbus` for `kde` (credits @sleddev)

## 6.3.3 (7.9.2024)

### Fixed

- Updated offline table for auto suggestions from gathered data (GA)
- Support for `gnome-calculator` installed via `flatpak` (credits @encrustace)
- Support for `io.elementary.calculator`
- Xauthority file in `/temp` folder with different name for each boot
- When `i2c-tools` require `sudo`
- Not prioritizing layout from source `mru-sources` and not reloading keymap
- Missing `sudo` when uninstalling (credits @Triw-12)
- Activation when is `brightness` not defined yet

## 6.3.2 (1.8.2024)

### Fixed

- Updated offline table for auto suggestions from gathered data (GA)
- Missing check whether is installed `i2ctransfer` tool
- Accepting `-1` as starting x or y axis for touch

## 6.3.1 (20.7.2024)

### Fixed

- Updated offline table for auto suggestions from gathered data (GA)
- Fixed version of `libxkcommon` to be lower than `1.1`
- Fixed empty env var `XDG_SESSION_TYPE` or filled with `tty`
- Fixed too short default slide activation radius (set up `1200px`)

### 6.3.0 (16.6.2024)

### Feature

- Slide gestures activation treshold x AND y changed to radius
- Allowed to activate NumberPad with slide gesture with beginning on the top left icon (together with calc app)
- Updated offline table for auto suggestions from gathered data (GA)

## 6.2.0 (13.6.2024)

### Feature

- Support for package manager `portage` of gentoo linux (credits @v0llk)

### Fixed

- Fixed setting up the last brightness when is NumberPad started in response to activated numlock key

## 6.1.0 (1.6.2024)

### Feature

- Support for package manager `xbps-install` of void linux (credits @vazw)
- Updated offline table for auto suggestions from gathered data (GA)

### Fixed

- Fixed clean up of watch manager
- Not using latest brightness (was used last loaded brightness from config)
- Missing commas when was added the shortcut for toggling calculator script at the end of already existing shortcuts
- Evaluating `input-sources` on gnome
- Throwing away `current` layout index with value 0 on gnome
- Not continuing when is x11 client not successfully connected to the server or xdg session type is empty
- Replaced `git` as method used for obtaining reported version to GA (useful when is driver downloaded from the released page)
- Checking when supported device is not detected
- Using keymap thought wayland (was printing `/slash`, `-minus`, `+plus` etc.)
- Loading keymap thought wayland (fixed not correct cancelling searching for keysym when was found keycode but not for active layout so key was not associated (empty string))
- Starting systemd service on wayland (forced sync device when is `EventsDroppedException` thrown out)
- Unnecessary udev reset during starting for wayland
- Loading keymap on x11 twice during the start

## 6.0.0 (3.5.2024)

### Feature

- Updated offline table for auto suggestions from gathered data (GA)
- Decreased activation treshold of y for slide functions from both corners to 0.2 ratio

### Fixed

- Wayland support
- Removed unnecessary `bc` dependency
- Fixed finding interpret for `virtualenv` using path instead of version
- Fixed activation treshold of y axis for top_right_icon (NumLock)
- Fixed removing other shortcuts during first installation


## 5.1.1 (4.4.2024)

### Fixed

- Fixed sending info about suggested layout
- Fixed calculating duration of installation (decimal point was not removed before substracting)

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
