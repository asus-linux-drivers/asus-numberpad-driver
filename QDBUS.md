# Setting the tapToClick with qdbus on KDE Plasma Wayland

Find your touchpad's libinput device:

1. Run `sudo libinput list-devices`
2. Look for one with Touchpad in its name
3. Remember the number at the end of the `Kernel` property (e.g. `7` for `/dev/input/event7`)

Now replace the number with your own in the string `/org/kde/KWin/InputDevice/event7` (found in `numberpad.py`, in the `qdbusSetTouchpadTapToClick` function)

Reinstall, or do these edits directly in the `/usr/share/asus-numberpad-driver/numberpad.py` file. Restart the systemd service or just reboot, and you should be good to go!
