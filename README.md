# Asus touchpad NumberPad driver

[![License: GPL v2](https://img.shields.io/badge/License-GPLv2-blue.svg)](https://www.gnu.org/licenses/old-licenses/gpl-2.0.en.html)
![Maintainer](https://img.shields.io/badge/maintainer-ldrahnik-blue)
![Contributor](https://img.shields.io/badge/contributor-kamack33-blue)
[![All Contributors](https://img.shields.io/badge/all_contributors-3-orange.svg?style=flat-square)](https://github.com/asus-linux-drivers/asus-touchpad-numpad-driver/graphs/contributors)
[![GitHub Release](https://img.shields.io/github/release/asus-linux-drivers/asus-touchpad-numpad-driver.svg?style=flat)](https://github.com/asus-linux-drivers/asus-touchpad-numpad-driver/releases)
[![GitHub commits](https://img.shields.io/github/commits-since/asus-linux-drivers/asus-touchpad-numpad-driver/v2.4.1.svg)](https://GitHub.com/asus-linux-drivers/asus-touchpad-numpad-driver/commit/)
[![Arch package](https://repology.org/badge/version-for-repo/arch/asus-touchpad-numpad-driver-ux433fa-git.svg)](https://aur.archlinux.org/pkgbase/asus-touchpad-numpad-driver-git)
[![GitHub issues-closed](https://img.shields.io/github/issues-closed/asus-linux-drivers/asus-touchpad-numpad-driver.svg)](https://GitHub.com/asus-linux-drivers/asus-touchpad-numpad-driver/issues?q=is%3Aissue+is%3Aclosed)
[![GitHub pull-requests closed](https://img.shields.io/github/issues-pr-closed/asus-linux-drivers/asus-touchpad-numpad-driver.svg)](https://github.com/asus-linux-drivers/asus-touchpad-numpad-driver/compare)
[![Ask Me Anything !](https://img.shields.io/badge/Ask%20about-anything-1abc9c.svg)](https://github.com/asus-linux-drivers/asus-touchpad-numpad-driver/issues/new/choose)
[![PRs Welcome](https://img.shields.io/badge/PRs-welcome-brightgreen.svg?style=flat-square)](http://makeapullrequest.com)

The driver is written in python and runs as a systemctl service. Driver contains basic key layouts, you can pick up right one during install process. Default settings try to be most comfortable for the majority. All possible customizations can be found [here](#configuration).

If you find this project useful, do not forget to give it a [![GitHub stars](https://img.shields.io/github/stars/asus-linux-drivers/asus-touchpad-numpad-driver.svg?style=social&label=Star&maxAge=2592000)](https://github.com/asus-linux-drivers/asus-touchpad-numpad-driver/stargazers) People already did!

## Features

- Multiple pre-created [NumberPad layouts](https://github.com/asus-linux-drivers/asus-touchpad-numpad-driver#layouts) with possibility [create custom one or improve existing](https://github.com/asus-linux-drivers/asus-touchpad-numpad-driver#keyboard-layout) (keys, sizes, paddings..)
- Customization through 2-way sync [configuration file](https://github.com/asus-linux-drivers/asus-touchpad-numpad-driver#configuration-file) (when is run `sudo ./install.sh` changes done in config file may not be overwritten, the same when is run `sudo ./uninstall.sh` and when config file or part of does not exist is automatically created/completed with default values)
- Automatic NumberPad model detection via [list of used NumberPad layouts for laptops](https://github.com/asus-linux-drivers/asus-touchpad-numpad-driver/blob/master/laptop_numpad_layouts) and when is available a connection via finding all other laptops on [linux-hardware.org](https://linux-hardware.org) which use the same version of NumberPad to which might be already in mentioned list associated proper layout
- Activation/deactivation of NumberPad via holding top right icon or every spot with key `KEY_NUMLOCK` (activation time by default 1s)
- Fast activation/deactivation of NumberPad via slide gesture beginning on top right icon (by default is required end slide after at least 30% of touchpad width and height)
- When is NumberPad activated can be used customizable slide gesture beginning on top left (by default is send key `XF86Calculator` so it is prepared for bounding script with toggle functionality of preferred calculator app in your system keyboard shortcuts, [example of mine toggling script](https://github.com/ldrahnik/elementary-os-scripts/blob/master/toggle_calculator.sh) (`XF86Calculator` key press can be tested via `xdotool key XF86Calculator`), so first slide gesture activates calculator app and next closes calculator app, by default is also required end each slide after at least 30% of width and height)
- Support for various keyboard layouts (unicode characters (e.g. `"%"` in layouts `up5401ea, ux581l` or `"#"` in layout `gx701`) are sent via `<left_shift>+<left_ctrl>+<U>+<0-F>+<space>`)
- Smooth change of backlight levels (endless loop with customizable interval, default 1s)
- Customizable default level of backlight (by default is default level last used level - works even between reboots)
- NumberPad is automatically disabled due inactivity (default 1 min)
- Disabling sys NumLock from e.g. external keyboard disables NumberPad as well
- Enabling sys NumLock do not activate NumberPad (can be enabled)
- Disabling NumberPad by default disable sys Numlock as well (can be disabled which is useful when is connected external keyboard)
- Activated NumberPad allowes pointer moves (enabled by default)
- Activated NumberPad disables pointer clicks (can be enabled)
- Repeating the key, when is held (disabled by default)
- Multitouch up to 5 fingers (disabled by default)
- Is implemented protection against multitouching accidentally when is multitouch not enabled (printing NumberPad key and slide gestures from corners are cancelled when is second finger used)
- Driver supports laptop suspend
- Disabling Touchpad (e.g. Fn+special key) disables by default NumberPad as well (can be disabled, this functionality supports atm only `xinput` from `xorg`, no `wayland` support https://github.com/asus-linux-drivers/asus-touchpad-numpad-driver/issues/54)
- Is recognized when is connected external keyboard and automatically is changed [configuration](https://github.com/asus-linux-drivers/asus-touchpad-numpad-driver#external-keyboard-configuration)

## Layouts

| Model/Layout | Description                                                                                                  | Image                                                                                               |
| ------------ | ------------------------------------------------------------------------------------------------------------ | --------------------------------------------------------------------------------------------------- |
| ux433fa      | Without % = symbols<br><br>Without left icon                                                                 | ![without % = symbols](images/Asus-ZenBook-UX433FA.jpg)                                             |
| e210ma       | With % = symbols<br><br>Without left icon                                                                    | ![with % = symbols but left icon is missing](images/Asus-E210MA.jpg)                                |
| b7402        | With % = symbols<br><br>Without left icon<br><br>Rectangle style of backlight                                | ![with % = symbols, left icon is missing and rectangles style of backlight](images/Asus-B7402.png) |
| up5401ea     | With % = symbols                                                                                             | ![with % = symbols](images/Asus-ZenBook-UP5401EA.png) ![with % = symbols](images/Asus-ZenBook-UP5401EA_2.png)                                               |
| ux581l       | With % = symbols<br><br>Vertical model                                                                       | ![model ux581](images/Asus-ZenBook-UX581l.jpg)                                                      |
| g533         | With NumLock key                                                                                             | ![with numlock](images/Asus-ROG-Strix-Scar-15-g533.png)                                             |
| g513         | With NumLock key<br><br>With left, right key outside of NumberPad                                                                                             | ![with numlock and buttons outside](images/ASUS-G513.jpg)                                             |
| gx701        | With # symbol<br><br>With NumLock key outside of touchpad<br><br>With left, right key outside of NumberPad   | ![model gx701](images/ASUS-ROG-Zephyrus-S17-GX701.jpg)                                              |
| gx551        | Without % = symbols<br><br>With NumLock key on the top left<br><br>With left, right key outside of NumberPad | ![model gx551](images/Asus-GX551.jpg)                                                               |

## Installation

Install latest dev version using `git`

```bash
git clone https://github.com/asus-linux-drivers/asus-touchpad-numpad-driver
cd asus-touchpad-numpad-driver
sudo ./install.sh
```

or download latest release (stable version) from [release page](https://github.com/asus-linux-drivers/asus-touchpad-numpad-driver/releases), extract and run:

```bash
sudo ./install.sh
```

or is available package for arch on AUR [here](https://aur.archlinux.org/packages?O=0&SeB=nd&K=asus-touchpad-numpad-driver&outdated=&SB=p&SO=d&PP=50&submit=Go) (replace model with available models, e.g. `asus-touchpad-numpad-driver-ux433fa-git`)

```bash
paru -S asus-touchpad-numpad-driver-${model}-git
```

## Uninstallation

And to uninstall, just run:

```bash
sudo ./uninstall.sh
```

### Dependencies

**Everything is included in install script `sudo ./install.sh`**

- libevdev
- i2c-tools
- git
- xinput

#### Python dependencies

- libevdev
- numpy
- evdev

Then enable i2c

```bash
sudo modprobe i2c-dev
sudo i2cdetect -l
```

To see the exact commands for your package manager look [here](./install.sh) (for python dependencies take a look at [requirements.txt](./requirements.txt))

## Troubleshooting

- **Before debugging make sure you have disabled the asus_touchpad_numpad.service service**

```bash
sudo systemctl stop asus_touchpad_numpad.service
```

To show debug logs run this command in terminal (**Do not forget specify numpad layout and which config do you want to use**):

```bash
# LOG=DEBUG sudo -E ./asus_touchpad.py <REQUIRED:numpad layout file name without extension .py> <OPTIONAL:directory where is located config file with name: asus_touchpad_numpad_dev, by default is taken CWD - current working directory, not existing config file is created and filled with default values>

cd asus-touchpad-numpad-driver
LOG=DEBUG sudo -E ./asus_touchpad.py "up5401ea" "" # now driver use root of repository as directory for config file named asus_touchpad_numpad_dev

cd asus-touchpad-numpad-driver
LOG=DEBUG sudo -E ./asus_touchpad.py "up5401ea" "/usr/share/asus_touchpad_numpad-driver/" # now driver use installed config
```

- **Start point [x:0,y:0] of touchpad is on the left top!**

## Configuration

### Keyboard layout

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

Each key layout (`g533.py`, `gx701.py`, ..) chosen during the install process corresponds to the specific file. To change any layout depending settings you need to locally edit the selected layout file and change the value of the corresponding variable from the first table below.

Example: If you want to set the size of top right icon to bigger and you have chosen the layout `up5401ea.py` during the install process. You need to change the corresponding variables (`top_right_icon_width = 400`,`top_right_icon_height = 400`) in the layout file (`asus-touchpad-numpad-driver/numpad_layouts/up5401ea.py`) and install the layout again.

| Option                                        | Required | Default           | Description |
| --------------------------------------------- | -------- | ----------------- | ----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| **Key layout**                                |          |
| `keys`                                        | Required |                   | map of keys as array of arrays, dimension has to be atleast array of len 1 inside array<br><br>everything else what is not an event except `None` is sent as unicode character `<left_shift>+<left_ctrl>+<U>+<0-F>` (use apostrophes!, e.g. `"%"` in layouts `up5401ea, ux581l` or `"#"` in layout `gx701`). Is allowed use string of unicode characters e.g. `"±%"`)
| `keys_ignore_offset`                          |          | `[]`              | map of keys which should be touchable even on offset area<br><br>e.g. used in layout `gx551` with value `[0,0]` where is NumLock key on the top left and right icon as primary activation area for NumLock is not used     
**Top left icon**                             |          |                   | any function is disabled when is missing option `top_left_icon_height` or `top_left_icon_width` and icon has to be touchable (`0` dimensions) |
| `top_left_icon_width`                         |          |                   | width of the top left icon
| `top_left_icon_height`                        |          |                   | height of the top left icon
| `top_left_icon_slide_func_keys`               |          | `[EV_KEY.KEY_CALC]` | array of `InputEvent`
| **Top right icon**                            |          |                   | send `numlock` key and activate/deactivate numpad<br><br>activating/deactivating touch has to start over icon area declared by `top_right_icon_width` and `top_right_icon_height`
| `top_right_icon_width`                        |          |                   | width of the top right icon
| `top_right_icon_height`                       |          |                   | height of the top right icon
 **Paddings**                                   |          |                   | NumberPad has padding zones around where nothing happens when is touched except top icons
| `top_offset`                                  |          | `0` (px)            | top NumberPad offset
| `right_offset`                                |          | `0` (px)            | right NumberPad offset
| `left_offset`                                 |          | `0` (px)            | left NumberPad offset
| `bottom_offset`                               |          | `0` (px)            | bottom NumberPad offset
| **Backlight**                                 |          |                   |
| `backlight_levels`                            |          |                   | array of backlight levels in hexa format `0x00` for brightness change by `top_left_icon` (values for turn on (`0x01`) and turn off (`0x00`) are hardcoded)



### Configuration file

What is not depending on specific keyboard of Numpad is mentioned in table below and can be changed in config file `asus_touchpad_numpad_dev` (dev as device interface because is here saved even status enabled of NumberPad, latest used brightness) in installed driver location `/usr/share/asus_touchpad_numpad-driver/asus_touchpad_numpad_dev`. Example default one:

```
[main]
numpad_disables_sys_numlock = 0
disable_due_inactivity_time = 60
touchpad_disables_numpad = 1
key_repetitions = 0
multitouch = 0
one_touch_key_rotation = 0
activation_time = 1
sys_numlock_enables_numpad = 0
top_left_icon_activation_time = 1
top_left_icon_slide_func_activates_numpad = 1
top_left_icon_slide_func_deactivates_numpad = 1
top_left_icon_slide_func_activation_x_ratio = 0.3
top_left_icon_slide_func_activation_y_ratio = 0.3
top_right_icon_slide_func_activation_x_ratio = 0.3
top_right_icon_slide_func_activation_y_ratio = 0.3
enabled_touchpad_pointer = 3
press_key_when_is_done_untouch = 1
enabled = 0
default_backlight_level = 0x01
top_left_icon_brightness_func_disabled = 0
```

| Option                                        | Required | Default           | Description |
| --------------------------------------------- | -------- | ----------------- | ----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| **System**                                    |          |                   |
| `enabled`                                     |          | `0`               | NumberPad running status (enabled/disabled)
| `disable_due_inactivity_time`                 |          | `60.0` [s]            | NumberPad is automatically disabled when have not received any event for this interval<br><br>decimal places allowed
| `touchpad_disables_numpad`                    |          | `1`            | when is touchpad disabled is disabled NumberPad aswell, valid value is `1` or `0` (e.g. via Fn+special key)<br><br>status is taken from result of `xinput` - to toggle touchpad can be used [this script](https://github.com/ldrahnik/elementary-os-scripts/blob/master/toggle_touchpad.sh)
| `sys_numlock_enables_numpad`                  |          | `0`           | obtained via active `LED_NUML` of keyboard device<br><br>enable with `1`, by default NumberPad reflects only disabling system numlock (then is disabled)    
| `numpad_disables_sys_numlock`                  |          | `1`           | when is set to `1` is every time during inactivation of NumberPad sent `KEY_NUMLOCK`. Is useful do not send NumLock when is to laptop connected external keyboard and goal is only disable NumberPad on laptop but keep NumLock on external keyboard enabled    
| `enabled_touchpad_pointer`                  |          | `3`           | valid values are `0`, `1`, `2`, `3` <br><br>when is set to `1` touchpad pointer can be used to moving and for clicking and can be clicked pointer buttons left, right and middle when is NumberPad activated, `0` disable this usage and `2` allowes only pointer button clicks, `3` allowes only touchpad pointer moving without clicks
| **Key layout**                                |          |
| `activation_time`              |          | `1.0` [seconds]             | amount of time you have to touch `top_right_icon` or another spot with key `EV_KEY.KEY_NUMLOCK` for the NumberPad activation/deactivation<br><br>decimal places allowed
| `multitouch`                                  |          | `0`           | up to quint tap when enabled<br><br>Example 1: can be enabled NumberPad when second finger is touched on touchpad somewhere as well;<br><br>Example 2: brightness can be changed during using NumberPad for calculating)
| `one_touch_key_rotation`                      |          | `0`           | possibility of altering multiple keys during one-touch
| `key_repetitions`                             |          | `0`           | possible to enable with value `1` hold key for repeated pressing key like on a physical keyboard
| **Top left icon**                             |          |                   | custom function is used when is NumberPad on/off and is first touched `top_left_icon` and finger is slid to center and untouched atleast after ratio of touchpad width > `top_left_icon_slide_func_activation_x_ratio` and height > `top_left_icon_slide_func_activation_y_ratio` and array `top_left_icon_custom_keys` is not empty<br><br>brightness function is used only when is NumberPad activated, `top_left_icon_brightness_function_disabled` is not `1`, array `backlight_levels` is not empty and works like endless loop of incrementing brightness in interval `top_left_icon_activation_time`
| `top_left_icon_activation_time`               |          | `1.0` [s]             | amount of time for touch `top_left_icon`<br><br>decimal places allowed
| `top_left_icon_slide_func_activation_x_ratio` |          | `0.3` (30%)         | ratio of touchpad width of slide
| `top_left_icon_slide_func_activation_y_ratio` |          | `0.3` (30%)         | ratio of touchpad height of slide
| `top_left_icon_slide_func_activates_numpad`   |          | `1`            | valid value is `1` or `0`
| `top_left_icon_slide_func_deactivate_numpad`  |          | `1`            | valid value is `1` or `0`   
| `top_left_icon_brightness_func_disabled`      |          | `0`            | valid value is `0` or `1`, allow force disable brightness change function<br><br>brightness function is auto disabled when is empty array `backlight_levels` and when is not set `top_left_icon_width` or `top_left_icon_width`
`backlight_levels`
| **Top right icon**                            |          |                   | send `numlock` key and activate/deactivate numpad<br><br>activating/deactivating touch has to start over icon area declared by `top_right_icon_width` and `top_right_icon_height` for amout of time in `activation_time` or NumberPad is activated/deactivated with slide function from this icon to center and untouched atleast after ratio of touchpad width > `top_right_icon_slide_func_activation_x_ratio` and height > `top_right_icon_slide_func_activation_y_ratio` |                                           
| `top_right_icon_slide_func_activation_x_ratio`|          | `0.3` (30%)         | ratio of touchpad width of slide
| `top_right_icon_slide_func_activation_y_ratio`|          | `0.3` (30%)         | ratio of touchpad height of slide 
**Backlight**                                   |          |                   |
| `default_backlight_level`                     |          | `0x01`            | default backlight level in hexa format `0x00` (has to be the value from layout `backlight_levels` or value for disabled brightness `0x00` or value for usage of last used brightness `0x01`)

### External keyboard configuration

Is installed also `udev` rule `90-numberpad-external-keyboard` which run `.sh` scripts for NumberPad configuration change when is external keyboard connected or disconnected.

State connected external keyboard / adding external keyboard means these changes:

```
sys_numlock_enables_numpad=0
disabling_numpad_disable_sys_numlock=0
```

State without external keyboard / removing external keyboard means these changes:

```
sys_numlock_enables_numpad=1
disabling_numpad_disable_sys_numlock=1
```

## Credits

Thank you very much all the contributors of [asus-touchpad-numpad-driver](https://github.com/mohamed-badaoui/asus-touchpad-numpad-driver) for your work.

Thank you who-t for great post about multitouch [Understanding evdev](http://who-t.blogspot.com/2016/09/understanding-evdev.html).


## Existing similar projects

- [python service, first initialization] <https://gitlab.com/Thraen/gx735_touchpad_numpad>
- [python service] <https://github.com/danahynes/Asus_L410M_Numpad> inspired by [python service, first initialization] <https://gitlab.com/Thraen/gx735_touchpad_numpad>
- [python service, configurable, the most spread repository] <https://github.com/mohamed-badaoui/asus-touchpad-numpad-driver> inspired by [python service] <https://gitlab.com/Thraen/gx735_touchpad_numpad>
- [c++ and meson] <https://github.com/xytovl/asus-numpad> inspired by/rewritten version of [python service, configurable, the most spread repository] <https://github.com/mohamed-badaoui/asus-touchpad-numpad-driver>
- [rust] <https://github.com/iamkroot/asus-numpad> rewritten in rust the same python project which was starting point for this repository  <https://github.com/mohamed-badaoui/asus-touchpad-numpad-driver>
- [python service, configurable, the most up-to-date] **This project with continuing work based on** [python service, configurable, the most spread repository] <https://github.com/mohamed-badaoui/asus-touchpad-numpad-driver>
- [c++] <https://github.com/haronaut/asus_numberpad>

## Existing related projects

- [WIP, package for arch based open rc systems] <https://codeberg.org/BenWestcott/asus-numpad-driver-openrc> prepare for this driver PKGBUILD and other infrastructure needed for Arch-based OpenRC systems

## Existing related articles

- [Numpad linux driver — implementation of multitouch] <https://medium.com/@ldrahnik/numpad-linux-driver-implementation-of-multitouch-bd8ae76a8d6c>

**Why have been these projects created?** Because linux does not support NumberPad integration to touchpad ([reported issue for Ubuntu here](https://bugs.launchpad.net/ubuntu/+source/linux/+bug/1810183))

**Why was this project created?** Because compared to mentioned projects I implemented more features and fixed more found bugs and I have time keep driver up-to-date.

**Stargazers project history?**

[![Stargazers over time](https://starchart.cc/asus-linux-drivers/asus-touchpad-numpad-driver.svg)](https://starchart.cc/asus-linux-drivers/asus-touchpad-numpad-driver)

**Buy me a coffee**

Do you think my effort put into open source is useful for you / others? Put star on the GitHub repository. Every star makes me proud. The same as any contribution. Would you like to reward me more? Now exists the way. You can invite me for a coffee! I really appreciate that!

[![BuyMeACoffee](https://img.shields.io/badge/Buy%20to%20maintainer%20a%20coffee-ffdd00?style=for-the-badge&logo=buy-me-a-coffee&logoColor=black)](https://www.buymeacoffee.com/ldrahnik)

[![Buy me a coffee supporter](images/buymeacoffee.png)](https://www.buymeacoffee.com/ldrahnik)
