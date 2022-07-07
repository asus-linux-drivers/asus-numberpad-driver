# Asus touchpad numpad driver

If you find the project useful, do not forget to give project a [![GitHub stars](https://img.shields.io/github/stars/asus-linux-drivers/asus-touchpad-numpad-driver.svg?style=flat-square)](https://github.com/asus-linux-drivers/asus-touchpad-numpad-driver/stargazers) People already did!

|                   Without % = symbols                   |                   With % = symbols                    | With % = symbols (but incompatible with the non-universal version) |                    With NumLock key                     | Without % = symbols (but incompatible with the non-universal version) |
| :-----------------------------------------------------: | :---------------------------------------------------: | :----------------------------------------------------------------: | :-----------------------------------------------------: | :-------------------------------------------------------------------: |
|                 Model/Layout = ux433fa                  |                Model/Layout = up5401ea                |                       Model/Layout = ux581l                        |                   Model/Layout = g533                   |                         Model/Layout = gx701                          |
| ![without % = symbols](images/Asus-ZenBook-UX433FA.jpg) | ![with % = symbols](images/Asus-ZenBook-UP5401EA.png) |           ![model ux581](images/Asus-ZenBook-UX581l.jpg)           | ![with numlock](images/Asus-ROG-Strix-Scar-15-g533.png) |        ![model gx701](images/ASUS-ROG-Zephyrus-S17-GX701.jpg)         |

## Features

- Multiple layouts
- Multi-touch support
- One-touch key rotation
- Multiple levels of backlight
- Customizable default level of backlight
- Numpad padding configuration
- Customizable numpad activation delay
- Customizable top left icon action

## Installation

The package is available to install from AUR

```bash
paru -S  asus-touchpad-numpad-driver-${model}-${layout}-git 
```

Replace model with available models and layout with `qwerty` or `azerty`
Example: `asus-touchpad-numpad-driver-ux433fa-qwerty-git`

or via GIT

```bash
git clone https://github.com/asus-linux-drivers/asus-touchpad-numpad-driver
cd asus-touchpad-numpad-driver
sudo ./install.sh
```

and to uninstall, just run:

```bash
sudo ./uninstall.sh
```

### Required packages

**Everything is included in install script ```sudo ./install.sh```**

- Debian / Ubuntu (22.04 is supported) / Linux Mint / Pop!\_OS / Zorin OS:

```bash
sudo apt install libevdev2 python3-libevdev i2c-tools git python3-pip
```

- Arch Linux / Manjaro:

```bash
sudo pacman -S libevdev python-libevdev i2c-tools git
```

- Fedora:

```bash
sudo dnf install libevdev python-libevdev i2c-tools git
```

NumPy python lib

```bash
pip3 install numpy
```

Then enable i2c

```bash
sudo modprobe i2c-dev
sudo i2cdetect -l
```

## Troubleshooting

To activate logger, do in a console:

```bash
LOG=DEBUG sudo -E ./asus_touchpad.py
```

For some operating systems with boot failure (Pop!OS, Mint, ElementaryOS, SolusOS), before installing, please uncomment in the asus_touchpad.service file, this following property and adjust its value:

```bash
# ExecStartPre=/bin/sleep 2
```

## Layout configuration

| Option                      | Required    | Default | Description                                                       |
| --------------------------- | ------------|---------|-------------------------------------------------------------------|
| **Device search**           |             |         | `/proc/bus/input/devices`
| `try_times`                 |             | 5       | how many times to try find a touchpad device in each service start attempt  
| `try_sleep`                 |             | 0.1     | time between tries
| **Layout**                  |             |
| `keys`                      | Required    |         | map of keys as array of arrays, dimension has to be atleast array of len 1 inside array
| **Top left icon**           |             |         | any function is disabled when is missing option `top_left_icon_height` or `top_left_icon_width` and when is icon not targetable (`0` dimension value)<br><br>custom function is used when is numpad deactivated and array `top_left_icon_custom_keys` not empty or numpad is activated and `top_left_icon_brightness_function_disabled` is True<br><br>when is array `top_left_icon_custom_keys` empty and array `backlight_levels` is not empty is function of icon increase brightness used in endless loop starting with next level after `default_backlight_level`
| `top_left_icon_width`       |             |         | width of the top left icon
| `top_left_icon_height`      |             |         | height of the top left icon
| `top_left_icon_custom_keys` |             |         | array of `EV_KEY` 
| `top_left_icon_brightness_function_disabled` | |    | valid value is only `True`
keys
| **Top right icon**          |             |         | send `numlock` key and activate/deactivate numpad<br><br>activating/deactivating touch has to start over icon area declared by `top_right_icon_width` and `top_right_icon_height`
| `top_right_icon_width`      | Required    |         | width of the top right icon
| `top_right_icon_height`     | Required    |         | height of the top right icon
| **Paddings**                |             |         | numpad has padding zones around where nothing happens when is touched except top icons
| `top_offset`                |             | 0       | top numpad offset   
| `right_offset`              |             | 0       | right numpad offset
| `left_offset`               |             | 0       | left numpad offset
| `bottom_offset`             |             | 0       | bottom numpad offset
| **Backlight**               |             |         |
| `backlight_levels`          |             |         | array of backlight levels in hexa format `0x00` for brightness change by `top_left_icon` (values for turn on (`0x01`) and turn off (`0x00`) are hardcoded) |
| `default_backlight_level`   |             | 0x01    | default backlight level in hexa format `0x00` (has to be the value from `backlight_levels` or value for disabled brightness `0x00` or value for usage of last used brightness `0x01`)


## Credits

Thank you very much [github.com/mohamed-badaoui](github.com/mohamed-badaoui) and all the contributors of [asus-touchpad-numpad-driver](https://github.com/mohamed-badaoui/asus-touchpad-numpad-driver) for your work.

Thank you who-t for great post about multitouch [Understanding evdev](http://who-t.blogspot.com/2016/09/understanding-evdev.html).

## Developing

- **During debugging remember to disable already installed service created by this driver**

```bash
sudo systemctl stop asus_touchpad_numpad.service
```

- **Start point [x:0,y:0] of touchpad is left top!**

## Existing similar projects

- [python service, first initialization] <https://gitlab.com/Thraen/gx735_touchpad_numpad>
- [python service] <https://github.com/danahynes/Asus_L410M_Numpad> inspired by [python service, first initialization] <https://gitlab.com/Thraen/gx735_touchpad_numpad>
- [python service, configurable, the most spread repository] <https://github.com/mohamed-badaoui/asus-touchpad-numpad-driver> inspired by [python service] <https://gitlab.com/Thraen/gx735_touchpad_numpad>
- [c++ and meson] <https://github.com/xytovl/asus-numpad> inspired by/rewritten version of [python service, configurable, the most spread repository] <https://github.com/mohamed-badaoui/asus-touchpad-numpad-driver>

- [python service] This project with continuing work based on [python service, configurable, the most spread repository] <https://github.com/mohamed-badaoui/asus-touchpad-numpad-driver>

Why have been these projects created? Because ubuntu does not support numpad integration to touchpad ([reported issue here](https://bugs.launchpad.net/ubuntu/+source/linux/+bug/1810183))\
Why was this project created? Because compared to mentioned projects I implemented more features and fixed more found bugs
