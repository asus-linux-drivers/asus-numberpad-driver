# Asus touchpad numpad driver

**Tested only on laptop Asus ZenBook UP5401EA** with type of numpad layout **m433ia** and **backglight without levels** (only enable/disable) and system Elementary OS 6.1 Loki.

| Without % = symbols             |  With % = symbols       |  With % = symbols (but incompatible with the non-universal version) |
|:-------------------------:|:-------------------------:|:-------------------------:|
| Model/Layout = ux433fa          | Model/Layout = m433ia   | Model/Layout = ux581l |
| ![without % = symbols](https://github.com/ldrahnik/asus-touchpad-numpad-driver/blob/master/images/Asus-ZenBook-UX433FA.jpg)  |  ![with % = symbols](https://github.com/ldrahnik/asus-touchpad-numpad-driver/blob/master/images/Asus-ZenBook-UP5401EA.png) | ![model ux581](https://github.com/ldrahnik/asus-touchpad-numpad-driver/blob/master/images/Asus-ZenBook-UX581l.jpg) |


## TODO:

- [x] (Enable/disable backglight of numpad with activation)
- [x] (Multi tap support up to quint tap)
- [x] (Configurable support of all levels of backlight)
- [ ] (Pinch in/out as zooming in/out, [libinput-gestures](https://github.com/bulletmark/libinput-gestures) supports configurable reaction when is gesture done, no fluent zooming like on touchscreen possible)
- [ ] (Special keys with Alt key)
- [x] (Configurable support of touchpad left button - useful when has device no levels of backlight)

<br/>

Install required packages

- Debian / Ubuntu / Linux Mint / Pop!_OS / Zorin OS:
```
sudo apt install libevdev2 python3-libevdev i2c-tools git
```

- Arch Linux / Manjaro:
```
sudo pacman -S libevdev python-libevdev i2c-tools git
```

- Fedora:
```
sudo dnf install libevdev python-libevdev i2c-tools git
```


Then enable i2c
```
sudo modprobe i2c-dev
sudo i2cdetect -l
```

Now you can get the latest ASUS Touchpad Numpad Driver for Linux from Git and install it using the following commands.
```
git clone https://github.com/ldrahnik/asus-touchpad-numpad-driver
cd asus-touchpad-numpad-driver
sudo ./install.sh
```

To turn on/off numpad, tap top right corner touchpad area.
To adjust numpad brightness, tap top left corner touchpad area.

To uninstall, just run:
```
sudo ./uninstall.sh
```

**Troubleshooting**

To activate logger, do in a console:
```
LOG=DEBUG sudo -E ./asus_touchpad.py
```

For some operating systems with boot failure (Pop!OS, Mint, ElementaryOS, SolusOS), before installing, please uncomment in the asus_touchpad.service file, this following property and adjust its value:
```
# ExecStartPre=/bin/sleep 2
```

## Credits

Thank you very much [github.com/mohamed-badaoui](github.com/mohamed-badaoui) and all the contributors of [asus-touchpad-numpad-driver](https://github.com/mohamed-badaoui/asus-touchpad-numpad-driver) for your work.

Thank you who-t for great post about multitouch [Understanding evdev](http://who-t.blogspot.com/2016/09/understanding-evdev.html).

## Developing

**During debugging rebember to disable service / uninstall already installed version of driver**

## Existing similar projects

- [python service, first initialization] https://gitlab.com/Thraen/gx735_touchpad_numpad
- [python service] https://github.com/danahynes/Asus_L410M_Numpad inspired by [python service, first initialization] https://gitlab.com/Thraen/gx735_touchpad_numpad
- [python service, configurable, the most spread repository] https://github.com/mohamed-badaoui/asus-touchpad-numpad-driver inspired by [python service] https://gitlab.com/Thraen/gx735_touchpad_numpad
- [c++ and meson] https://github.com/xytovl/asus-numpad inspired by/rewritten version of [python service, configurable, the most spread repository] https://github.com/mohamed-badaoui/asus-touchpad-numpad-driver

- [python service] This project with continuing work based on [python service, configurable, the most spread repository] https://github.com/mohamed-badaoui/asus-touchpad-numpad-driver

Why was this project created? As repository where i can implement ```Configurable support of all levels of backlight``` and ```Multi tap support up to quint tap```.
