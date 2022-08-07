# Asus touchpad NumberPad driver

The driver is written in python and runs as a systemctl service. Driver contains basic key layouts, you can pick up right one during install process. Default settings try to be most comfortable for the majority. All possible customizations can be found [here](#configuration).

If you find this project useful, do not forget to give it a [![GitHub stars](https://img.shields.io/github/stars/asus-linux-drivers/asus-touchpad-numpad-driver.svg?style=flat-square)](https://github.com/asus-linux-drivers/asus-touchpad-numpad-driver/stargazers) People already did!

| Model/Layout | Description                                                                                                  | Image                                                                                               |
| ------------ | ------------------------------------------------------------------------------------------------------------ | --------------------------------------------------------------------------------------------------- |
| ux433fa      | Without % = symbols<br><br>Without left icon                                                                 | ![without % = symbols](images/Asus-ZenBook-UX433FA.jpg)                                             |
| e210ma       | With % = symbols<br><br>Without left icon                                                                    | ![with % = symbols but left icon is missing](images/Asus-E210MA.jpg)                                |
| b7402        | With % = symbols<br><br>Without left icon<br><br>Rectangle style of backlight                                | ![with % = symbols, left icon is missing and rectangles style of backlight](images/Asus-B7402.jpeg) |
| up5401ea     | With % = symbols                                                                                             | ![with % = symbols](images/Asus-ZenBook-UP5401EA.png)                                               |
| ux581l       | With % = symbols<br><br>Vertical model                                                                       | ![model ux581](images/Asus-ZenBook-UX581l.jpg)                                                      |
| g533         | With NumLock key                                                                                             | ![with numlock](images/Asus-ROG-Strix-Scar-15-g533.png)                                             |
| gx701        | With # symbol<br><br>With NumLock key outside of touchpad<br><br>With left, right key outside of NumberPad   | ![model gx701](images/ASUS-ROG-Zephyrus-S17-GX701.jpg)                                              |
| gx551        | Without % = symbols<br><br>With NumLock key on the top left<br><br>With left, right key outside of NumberPad | ![model gx551](images/Asus-GX551.jpg)                                                               |

## Features

- Multiple NumberPad layouts (keys, paddings)
- Automatic NumberPad model detection
- Customizable activation time (default 1s)
- Unicode characters sending support (e.g. `"%"` in layouts `up5401ea, ux581l` or `"#"` in layout `gx701` via `<left_shift>+<left_ctrl>+<U>+<0-F>`)
- Smooth change of backlight levels (endless loop with customizable interval, default 1s)
- Customizable slide gesture beginning on top left (default action is calculator with NumberPad activation and a requirement is end slide after at least 0.3 of width and height)
- Customizable default level of backlight (default is last used level - works even between reboots)
- NumberPad is automatically disabled due inactivity (default 1 min)
- Disabling Touchpad (e.g. Fn+special key) disables NumberPad aswell
- Numlock state corresponds to the system numlock state (disabling sys numlock from e.g. external keyboard disables NumberPad as well, reflect enabling sys numlock is optional)
- Touchpad physical buttons (left, right and middle) are ignored when is NumberPad on (unless they are outside the NumberPad area like in layout `gx701`)
- Repeating the key, when it is held (optional)
- Multitouch with up to 5 fingers support (optional)

## Installation

The package is [available](https://aur.archlinux.org/packages?O=0&SeB=nd&K=asus-touchpad-numpad-driver&outdated=&SB=p&SO=d&PP=50&submit=Go) to install from AUR

```bash
paru -S asus-touchpad-numpad-driver-${model}-git
```

Replace model with available models.
Example: `asus-touchpad-numpad-driver-ux433fa-git`

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

**Everything is included in install script `sudo ./install.sh`**

- Debian / Ubuntu (22.04 is supported) / Linux Mint / Pop!\_OS / Zorin OS:

```bash
sudo apt install libevdev2 python3-libevdev i2c-tools git python3-pip xinput
```

- Arch Linux / Manjaro:

```bash
sudo pacman -S libevdev python-libevdev i2c-tools git python-pip xorg-xinput
```

- Fedora:

```bash
sudo dnf install libevdev python-libevdev i2c-tools git python-pip xinput
```

Python lib NumPy, evdev

```bash
pip3 install numpy evdev
```

Then enable i2c

```bash
sudo modprobe i2c-dev
sudo i2cdetect -l
```

## Troubleshooting

To show debug logs run:

```bash
LOG=DEBUG sudo -E ./asus_touchpad.py
```

## Configuration

During the install process `sudo ./install.sh`, you're required to select your keyboard layout:

```
Select models keypad layout:
1) b7402.py
2) e210ma.py
3) g533.py
4) gx551.py
5) gx701.py
6) up5401ea.py
7) ux433fa.py
8) ux581l.py
9) Quit
Please enter your choice
```

Each key layout (`g533.py`, `gx701.py`, ..) chosen during the install process corresponds to the specific file. To change any settings you need to locally edit the selected layout file and change the value of the corresponding variable from the table below.

Example: If you want to set the activation time to 2 seconds and you have chosen the layout `up5401ea.py` during the install process. You need to change the corresponding variable to 2 seconds (`top_right_icon_activation_time = 2`) in the layout file (`asus-touchpad-numpad-driver/numpad_layouts/up5401ea.py`) and install the layout again.

| Option                                        | Required | Default           | Description                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                       |
| --------------------------------------------- | -------- | ----------------- | ----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| **System**                                    |          |                   |
| `disable_due_inactivity_time`                 |          | 60 [s]            | NumberPad is automatically disabled when have not received any event for this interval                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                            |
| `touchpad_disables_numpad`                    |          | `True`            | when is touchpad disabled is disabled NumberPad aswell, valid value is `True` or `False` (e.g. via Fn+special key)<br><br>status is taken from result of `xinput` - to toggle touchpad can be used [this script](https://github.com/ldrahnik/elementary-os-scripts/blob/master/toggle_touchpad.sh)                                                                                                                                                                                                                                                                                                                                                                                                                                                                |
| `sys_numlock_enables_numpad`                  |          | `False`           | obtained via active `LED_NUML` of keyboard device<br><br>enable with `True`, by default NumberPad reflects only disabling system numlock (then is disabled)                                                                                                   | `numpad_disables_sys_numlock`                  |          | `True`           | disabling system NumLock when is NumberPad disabled may be unwanted when is external keyboard connected                                                                                                                                                                                                                                                                                                                                                                                                                                                                                    |
| **Device search**                             |          |                   | `/proc/bus/input/devices`                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                         |
| `try_times`                                   |          | 5                 | how many times to try find a touchpad device in each service start attempt                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                        |
| `try_sleep`                                   |          | 0.1 [s]           | time between tries                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                |
| **Key layout**                                |          |
| `keys`                                        | Required |                   | map of keys as array of arrays, dimension has to be atleast array of len 1 inside array<br><br>everything else what is not an event except `None` is sent as unicode `<left_shift>+<left_ctrl>+<U>+<0-F>` (use apostrophes!, e.g. `"%"` in layouts `up5401ea, ux581l` or `"#"` in layout `gx701`)                                                                                                                                                                                                                                                                                                                                                                                                                                                                 |
| `multitouch`                                  |          | `False`           | up to quint tap when enabled<br><br>Example 1: can be enabled NumberPad when second finger is touched on touchpad somewhere as well;<br><br>Example 2: brightness can be changed during using NumberPad for calculating)                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                          |
| `one_touch_key_rotation`                      |          | `False`           | possibility of altering multiple keys during one-touch                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                            |
| `key_repetitions`                             |          | `False`           | possible to enable with value `True` hold key for repeated pressing key like on a physical keyboard                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                               |
| `touchpad_physical_buttons_are_inside_numpad` |          | `True`            | valid value is `True` or `False`                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                  |
| **Top left icon**                             |          |                   | any function is disabled when is missing option `top_left_icon_height` or `top_left_icon_width` and icon has to be touchable (`0` dimensions)<br><br>custom function is used when is NumberPad on/off and is first touched `top_left_icon` and finger is slid to center and untouched atleast after ratio of touchpad width > `top_left_icon_slide_func_activation_x_ratio` and height > `top_left_icon_slide_func_activation_y_ratio` and array `top_left_icon_custom_keys` is not empty<br><br>brightness function is used only when is NumberPad activated, `top_left_icon_brightness_function_disabled` is not True, array `backlight_levels` is not empty and works like endless loop of incrementing brightness in interval `top_left_icon_activation_time` |
| `top_left_icon_width`                         |          |                   | width of the top left icon                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                        |
| `top_left_icon_height`                        |          |                   | height of the top left icon                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                       |
| `top_left_icon_activation_time`               |          | 1 [s]             | amount of time for touch `top_left_icon`                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                          |
| `top_left_icon_slide_func_keys`               |          | `EV_KEY.KEY_CALC` | array of `InputEvent`                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                             |
| `top_left_icon_slide_func_activation_x_ratio` |          | 0.3               | ratio of touchpad width of slide                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                  |
| `top_left_icon_slide_func_activation_y_ratio` |          | 0.3               | ratio of touchpad height of slide                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                 |
| `top_left_icon_slide_func_activate_numpad`    |          | `True`            | valid value is `True` or `False`                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                  |
| `top_left_icon_brightness_func_disabled`      |          |                   | valid value is only `True`                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                        |
| **Top right icon**                            |          |                   | send `numlock` key and activate/deactivate numpad<br><br>activating/deactivating touch has to start over icon area declared by `top_right_icon_width` and `top_right_icon_height`                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                 |
| `top_right_icon_width`                        | Required |                   | width of the top right icon                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                       |
| `top_right_icon_height`                       | Required |                   | height of the top right icon                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                      |
| `top_right_icon_activation_time`              |          | 1 [s]             | amount of time you have to touch `top_right_icon` for the NumberPad activation/deactivation                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                       |
| `top_right_icon_is_on_top_left`               |          | `False`           | valid value is `False` or `True`                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                  |
| **Paddings**                                  |          |                   | NumberPad has padding zones around where nothing happens when is touched except top icons                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                         |
| `top_offset`                                  |          | 0                 | top NumberPad offset                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                              |
| `right_offset`                                |          | 0                 | right NumberPad offset                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                            |
| `left_offset`                                 |          | 0                 | left NumberPad offset                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                             |
| `bottom_offset`                               |          | 0                 | bottom NumberPad offset                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                           |
| **Backlight**                                 |          |                   |
| `backlight_levels`                            |          |                   | array of backlight levels in hexa format `0x00` for brightness change by `top_left_icon` (values for turn on (`0x01`) and turn off (`0x00`) are hardcoded)                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                        |
| `default_backlight_level`                     |          | `0x01`            | default backlight level in hexa format `0x00` (has to be the value from `backlight_levels` or value for disabled brightness `0x00` or value for usage of last used brightness `0x01`)                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                             |

## Credits

Thank you very much [github.com/mohamed-badaoui](github.com/mohamed-badaoui) and all the contributors of [asus-touchpad-numpad-driver](https://github.com/mohamed-badaoui/asus-touchpad-numpad-driver) for your work.

Thank you who-t for great post about multitouch [Understanding evdev](http://who-t.blogspot.com/2016/09/understanding-evdev.html).

## Developing

- **Before debugging make sure you have disabled the asus_touchpad_numpad.service service**

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

**Why have been these projects created?** Because linux does not support NumberPad integration to touchpad ([reported issue for Ubuntu here](https://bugs.launchpad.net/ubuntu/+source/linux/+bug/1810183))

**Why was this project created?** Because compared to mentioned projects I implemented more features and fixed more found bugs and I have time keep driver up-to-date.
