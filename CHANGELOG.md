# Changelog

## v2.7.9 (30.6.2023)

### Fixed

- Fixed bug when was pressed key with dot (`.`) and was used comma (`,`) instead on Turkish keyboard layout
- Fixed driver X11 service because have not had succesfully assigned `DISPLAY` variable from install script (might end with black screen after reboot)

## Refactored

- All layout keys except `KEY_BACKSPACE`, `KEY_KPENTER`, `KEY_NUMLOCK` redefined to send via `<left_shift>+<left_ctrl>+<U>+<0-F>+<space>`

## v2.7.8 (29.6.2023)

### New feature

- Uninstall script is newly not interrupted during and removes everything what can be removed

### Fixed

- Fixed bug when missing `xinput` tool dropped driver
- Fixed installation script for distributions with dnf package manager

### Refactoring

- Replaced pip packages entirely with packages from current distribution package managers
