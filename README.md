# Asus touchpad NumberPad driver

[![License: GPL v2](https://img.shields.io/badge/License-GPLv2-blue.svg)](https://www.gnu.org/licenses/old-licenses/gpl-2.0.en.html)
![Maintainer](https://img.shields.io/badge/maintainer-ldrahnik-blue)
![Contributor](https://img.shields.io/badge/contributor-kamack33-blue)
[![All Contributors](https://img.shields.io/badge/all_contributors-3-orange.svg?style=flat-square)](https://github.com/asus-linux-drivers/asus-numberpad-driver/graphs/contributors)
[![GitHub Release](https://img.shields.io/github/release/asus-linux-drivers/asus-numberpad-driver.svg?style=flat)](https://github.com/asus-linux-drivers/asus-numberpad-driver/releases)
[![GitHub commits](https://img.shields.io/github/commits-since/asus-linux-drivers/asus-numberpad-driver/v2.9.5.svg)](https://GitHub.com/asus-linux-drivers/asus-numberpad-driver/commit/)
[![Arch package](https://repology.org/badge/version-for-repo/arch/asus-numberpad-driver-ux433fa-git.svg)](https://aur.archlinux.org/pkgbase/asus-numberpad-driver-git)
[![GitHub issues-closed](https://img.shields.io/github/issues-closed/asus-linux-drivers/asus-numberpad-driver.svg)](https://GitHub.com/asus-linux-drivers/asus-numberpad-driver/issues?q=is%3Aissue+is%3Aclosed)
[![GitHub pull-requests closed](https://img.shields.io/github/issues-pr-closed/asus-linux-drivers/asus-numberpad-driver.svg)](https://github.com/asus-linux-drivers/asus-numberpad-driver/compare)
[![Ask Me Anything !](https://img.shields.io/badge/Ask%20about-anything-1abc9c.svg)](https://github.com/asus-linux-drivers/asus-numberpad-driver/issues/new/choose)
[![PRs Welcome](https://img.shields.io/badge/PRs-welcome-brightgreen.svg?style=flat-square)](http://makeapullrequest.com)
[![Hits](https://hits.seeyoufarm.com/api/count/incr/badge.svg?url=https%3A%2F%2Fgithub.com%2Fasus-linux-drivers%2Fasus-numberpad-driver&count_bg=%2379C83D&title_bg=%23555555&icon=&icon_color=%23E7E7E7&title=hits&edge_flat=false)](https://hits.seeyoufarm.com)                    

The driver is written in python and runs as a systemctl service. Driver contains basic key layouts, you can pick up right one during install process. Default settings try to be most comfortable for the majority. All possible customizations can be found [here](#configuration).

If you find this project useful, do not forget to give it a [![GitHub stars](https://img.shields.io/github/stars/asus-linux-drivers/asus-numberpad-driver.svg?style=social&label=Star&maxAge=2592000)](https://github.com/asus-linux-drivers/asus-numberpad-driver/stargazers) People already did!

## Changelog

[CHANGELOG.md](CHANGELOG.md)

## Features

- Multiple pre-created [NumberPad layouts](https://github.com/asus-linux-drivers/asus-numberpad-driver#layouts) with possibility [create custom one or improve existing](https://github.com/asus-linux-drivers/asus-numberpad-driver#keyboard-layout) (keys, sizes, paddings..)
- Customization through 2-way sync [configuration file](https://github.com/asus-linux-drivers/asus-numberpad-driver#configuration-file) (when is run `sudo bash ./install.sh` changes done in config file may not be overwritten, the same when is run `sudo bash ./uninstall.sh` and when config file or part of does not exist is automatically created/completed with default values)
- Automatic NumberPad model detection via [list of used NumberPad layouts for laptops](https://github.com/asus-linux-drivers/asus-numberpad-driver/blob/master/laptop_numpad_layouts) and when is available a connection via finding all other laptops on [linux-hardware.org](https://linux-hardware.org) which use the same version of NumberPad to which might be already in mentioned list associated proper layout
- Activation/deactivation of NumberPad via holding top right icon or every spot with key `KEY_NUMLOCK` (activation time by default 1s)
- Fast activation/deactivation of NumberPad via slide gesture beginning on top right icon (by default is required end slide after at least 30% of touchpad width and height)
- When is NumberPad activated can be used customizable slide gesture beginning on top left (by default is send key `EV_KEY.KEY_CALC` translated to `XF86Calculator` so it is prepared for bounding script with toggle functionality of preferred calculator app in your system keyboard shortcuts, [example of mine toggling script](https://github.com/asus-linux-drivers/asus-numberpad-driver/blob/master/scripts/io_elementary_calculator_toggle.sh), so first slide gesture activates calculator app and next closes calculator app, by default is also required end each slide after at least 30% of width and height)
- Support for various keyboard layouts (unicode characters (e.g. `"%"` in layouts `up5401ea, ux581l` or `"#"` in layout `gx701`) are sent via `<left_shift>+<left_ctrl>+<U>+<0-F>+<space>`)
- Smooth change of backlight levels (endless loop with customizable interval, default 1s)
- Customizable default level of backlight (by default is default level last used level - works even between reboots)
- NumberPad is automatically disabled due inactivity (default 1 min)
- NumberPad cooperation with system NumLock is configurable (activation/deactivation of NumberPad may also enable/disable system NumLock vice versa as well)
- Activated NumberPad allowes pointer moves and is configurable distance when do not use key during press and move only with pointer
- Activated NumberPad disables pointer taps (*this functionality supports atm only `xinput` from `xorg` and `gnome` via `gsettings`*, can be configured)
- Repeating the key, when is held (disabled by default)
- Multitouch up to 5 fingers (disabled by default)
- Is implemented protection against multitouching accidentally when is multitouch not enabled (printing NumberPad key and slide gestures from corners are cancelled when is second finger used)
- Is implemented protection against sending NumberPad key when is done pointer button click (left, right, middle one) when is set up config value `press_key_when_is_done_untouch` (by default)
- Disabling Touchpad (e.g. Fn+special key) disables by default NumberPad as well (*this functionality supports atm only `xinput` from `xorg` and `gnome` via `gsettings`*, can be disabled)
- Is recognized when is connected external keyboard and automatically is changed [configuration](https://github.com/asus-linux-drivers/asus-numberpad-driver#external-keyboard-configuration)

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

## Touchpad models 

**Do you own Touchpad for which is row in table below empty/wrong? Please, create an issue or make PR**

### Table data

Table is based on all unique Asus touchpad models from repository [Dmesg](https://github.com/linuxhw/Dmesg) (repository contains uploaded probes = scanned laptops via [https://linux-hardware.org/](https://linux-hardware.org/)). Table may contains touchpads without NumberPad. Used command:

```
$ git clone https://github.com/linuxhw/Dmesg
$ cd Dmesg
$ grep -hRP "(^|\s)(ELAN|ASUE).*04F3:.*Touchpad(?=\s|$)" Convertible/ASUSTek\ Computer/ Notebook/ASUSTek\ Computer/ | cut -b 23-43 | sort -u
```

### Table columns

- touchpad - from file `/proc/bus/input/devices` (e.g. via command `egrep -B1 -A5 "ASUE|ELAN" /proc/bus/input/devices | grep -B1 -A5 Touchpad` even for column described below)
- detected but not used touchpad - means touchpad to which does not work i2c commands, e.g.: [ZenBook Pro Duo UX582LR_UX582LR @mbrouillet](https://github.com/asus-linux-drivers/asus-numberpad-driver/issues/95), correct is `ELAN1406:00 04F3:3101`:
```
I: Bus=0018 Vendor=04f3 Product=2c23 Version=0100
N: Name="ELAN9009:00 04F3:2C23 Touchpad"
P: Phys=i2c-ELAN9009:00
S: Sysfs=/devices/pci0000:00/0000:00:15.3/i2c_designware.3/i2c-4/i2c-ELAN9009:00/0018:04F3:2C23.0003/input/input48
U: Uniq=
H: Handlers=mouse4 event27 
B: PROP=5
B: EV=1b
B: KEY=e520 10000 0 0 0 0
B: ABS=2e0800000000003
B: MSC=20

I: Bus=0018 Vendor=04f3 Product=3101 Version=0100
N: Name="ELAN1406:00 04F3:3101 Touchpad"
P: Phys=i2c-ELAN1406:00
S: Sysfs=/devices/pci0000:00/0000:00:15.1/i2c_designware.1/i2c-2/i2c-ELAN1406:00/0018:04F3:3101.0004/input/input51
U: Uniq=
H: Handlers=mouse6 event17 
B: PROP=5
B: EV=1b
B: KEY=e420 10000 0 0 0 0
B: ABS=2e0800000000003
B: MSC=20
```
- has NumberPad - select fit layout name from table above or use No - table may contains touchpads without NumberPad
- I2C values - for testing which value can control brightness of touchpad backlight can be used script `tests/test_brightness.py` which write in cycle gradually all possible values to reverse engineered i2c registr which is used for control of NumberPad (also mentioned in [FAQ](https://github.com/asus-linux-drivers/asus-numberpad-driver/blob/master/README.md#faq)), activation via `0x01` (by default) automatically set last used brightness (do not be confused)
- laptop model - series of laptop including specific model name from vendor/seller

**when column contains **?** is information not known*

**when is column empty is used default*

### Table

[Link](touchpad_product_id_info.md)

## Installation

Install latest dev version using `git`

```bash
git clone https://github.com/asus-linux-drivers/asus-numberpad-driver
cd asus-numberpad-driver
# install under current user (highly recommended)
sudo bash ./install.sh --user
# install as root
sudo bash ./install.sh
```

or download latest release (stable version) from [release page](https://github.com/asus-linux-drivers/asus-numberpad-driver/releases), extract and run:

```bash
# install as root
sudo bash ./install.sh
# install under current user (highly recommended)
sudo bash ./install.sh --user
```

or is available package for arch on AUR [here](https://aur.archlinux.org/packages?O=0&SeB=nd&K=asus-numberpad-driver&outdated=&SB=p&SO=d&PP=50&submit=Go) (replace model with available models, e.g. `asus-numberpad-driver-ux433fa-git`)

```bash
paru -S asus-numberpad-driver-${model}-git
```

## Uninstallation

And to uninstall, just run:

```bash
sudo bash ./uninstall.sh
# stop driver and uninstall for current user
sudo bash ./uninstall.sh --user
```

### Dependencies

**Everything is included in install script `sudo bash ./install.sh`**

To see the exact commands for your package manager look [here](./install.sh) (for python dependencies take a look at [requirements.txt](./requirements.txt))

## Troubleshooting

- **Start point [x:0,y:0] of touchpad is on the left top!**
- **Before debugging make sure you have disabled the asus_touchpad_numpad@.service service**

```bash
# when installed for running under root (`sudo bash ./install.sh`)
sudo systemctl stop asus_touchpad_numpad@root.service
# when installed for running under current user (`sudo bash ./install.sh --user`)
sudo systemctl stop asus_touchpad_numpad@<user>.service
```

- To show debug logs run this command in terminal (**Do not forget specify numpad layout and which config do you want to use**):

```bash
# LOG=DEBUG sudo -E ./asus_touchpad.py <REQUIRED:numpad layout file name without extension .py> <OPTIONAL:directory where is located config file with name: asus_touchpad_numpad_dev, by default is taken CWD - current working directory, not existing config file is created and filled with default values>

cd asus-numberpad-driver
LOG=DEBUG sudo -E ./asus_touchpad.py "up5401ea" "" # now driver use root of repository as directory for config file named asus_touchpad_numpad_dev

cd asus-numberpad-driver
LOG=DEBUG sudo -E ./asus_touchpad.py "up5401ea" "/usr/share/asus_touchpad_numpad-driver/" # now driver use installed config
```

- To show pressed keys:

```
sudo apt install libinput-tools
sudo libinput debug-events
```

- To simulate key press:

```
sudo apt install xdotool
xdotool key XF86Calculator
```

### FAQ ###

**How can be activated NumberPad via CLI?**

- is required have enabled in config `sys_numlock_enables_numpad = 1` (enabled by default), then will be NumberPad activated/disabled according to status of system numlock, source for pressing system numlock can be numlock physical key on the same laptop or external keyboard or simulated key via `xdotool key Num_Lock` or `numlockx on` and `numlockx off`

- directly just change `enabled` in appropriate config file:

```
# when is installed under current user (--user) sudo is not required

# enabling NumberPad via command line
sudo sed -i "s/enabled = 0/enabled = 1/g" asus_touchpad_numpad_dev
sudo sed -i "s/enabled = 0/enabled = 1/g" /usr/share/asus_touchpad_numpad-driver/asus_touchpad_numpad_dev
# disabling
sudo sed -i "s/enabled = 1/enabled = 0/g" asus_touchpad_numpad_dev
sudo sed -i "s/enabled = 1/enabled = 0/g" /usr/share/asus_touchpad_numpad-driver/asus_touchpad_numpad_dev
```

**Is any key from NumberPad not send properly?**

```
$ sudo evtest
No device specified, trying to scan all of /dev/input/event*
Available devices:
...
/dev/input/event12:	ASUE140D:00 04F3:31B9 Touchpad
/dev/input/event13:	ASUE140D:00 04F3:31B9 Keyboard
...
/dev/input/event22:	Asus Touchpad/Numpad
Select the device event number [0-22]: 22
Input driver version is 1.0.1
Input device ID: bus 0x0 vendor 0x0 product 0x0 version 0x0
Input device name: "Asus Touchpad/Numpad"
Supported events:
  Event type 0 (EV_SYN)
  Event type 1 (EV_KEY)
    Event code 14 (KEY_BACKSPACE)
    Event code 18 (KEY_E)
    Event code 22 (KEY_U)
    Event code 29 (KEY_LEFTCTRL)
    Event code 30 (KEY_A)
    Event code 31 (KEY_S)
    Event code 32 (KEY_D)
    Event code 33 (KEY_F)
    Event code 42 (KEY_LEFTSHIFT)
    Event code 46 (KEY_C)
    Event code 48 (KEY_B)
    Event code 55 (KEY_KPASTERISK)
    Event code 57 (KEY_SPACE)
    Event code 69 (KEY_NUMLOCK)
    Event code 71 (KEY_KP7)
    Event code 72 (KEY_KP8)
    Event code 73 (KEY_KP9)
    Event code 74 (KEY_KPMINUS)
    Event code 75 (KEY_KP4)
    Event code 76 (KEY_KP5)
    Event code 77 (KEY_KP6)
    Event code 78 (KEY_KPPLUS)
    Event code 79 (KEY_KP1)
    Event code 80 (KEY_KP2)
    Event code 81 (KEY_KP3)
    Event code 82 (KEY_KP0)
    Event code 83 (KEY_KPDOT)
    Event code 96 (KEY_KPENTER)
    Event code 98 (KEY_KPSLASH)
    Event code 117 (KEY_KPEQUAL)
    Event code 140 (KEY_CALC)
    Event code 272 (BTN_LEFT)
    Event code 273 (BTN_RIGHT)
    Event code 274 (BTN_MIDDLE)
Properties:
Testing ... (interrupt to exit)
Event: time 1679133719.799252, type 1 (EV_KEY), code 140 (KEY_CALC), value 1
Event: time 1679133719.799252, -------------- SYN_REPORT ------------
Event: time 1679133719.799295, type 1 (EV_KEY), code 140 (KEY_CALC), value 0
Event: time 1679133719.799295, -------------- SYN_REPORT ------------
```

**Toggling calculator app does not work**

- When is new keybindings added to list `custom-keybinings`, is necessary every time atleast log out. Otherwise newly added shortcut will not work.

- When using custom keybinding via `custom-keybindings` values `calculator` and `calculator-static` has to be empty:

```
$ sudo install dconf-editor
$ gsettings set org.gnome.settings-daemon.plugins.media-keys calculator [\'\']
$ gsettings set org.gnome.settings-daemon.plugins.media-keys calculator-static [\'\']
```
- Whether script works can be tested via `bash /usr/share/asus_touchpad_numpad-driver/scripts/calculator_toggle.sh`

- Whether keybinding works can be tested via slide gesture from NumberPad or via simulating `XF86Calculator` key `xdotool key XF86Calculator`


**Dconf permissions problem**

When is the driver installed under current user and this error occurs:

```
(process:393177): dconf-CRITICAL **: 14:12:44.964: unable to create file '/run/user/1000/dconf/user': Permission denied.  dconf will not work properly.
```

way how fix it is change owner and group to current user

```
ldrahnik@Zenbook-UP5401EA:/run/user/1000/dconf$ ls -la
total 4
drwx------  2 ldrahnik ldrahnik  60 Jun  3 21:57 .
drwx------ 16 ldrahnik ldrahnik 520 Jun  4 14:04 ..
-rw-------  1 root     root       2 Jun  3 22:52 user
```

to 

```
ldrahnik@Zenbook-UP5401EA:/run/user/1000/dconf$ ls -la
total 4
drwx------  2 ldrahnik ldrahnik  60 Jun  3 21:57 .
drwx------ 16 ldrahnik ldrahnik 520 Jun  4 14:04 ..
-rw-------  1 ldrahnik ldrahnik   2 Jun  4 14:14 user
```

using these commands:

```
# owner
sudo chown ldrahnik user
# group
sudo chown :ldrahnik user
```

**Invalid MIT-MAGIC-COOKIE-1 key**

When this happens on X11, try simply remove the currently used `.Xauthority` discovered via `xauth` command and then reboot because file will be auto-created:

```
$ xauth
Using authority file /home/ldrahnik/.Xauthority
xauth>^C
$ rm /home/ldrahnik/.Xauthority
$ reboot
```

## Configuration

### Keyboard layout

During the install process `sudo bash ./install.sh`, you're required to select your keyboard layout:

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

Example: If you want to set the size of top right icon to bigger and you have chosen the layout `up5401ea.py` during the install process. You need to change the corresponding variables (`top_right_icon_width = 400`,`top_right_icon_height = 400`) in the layout file (`asus-numberpad-driver/numpad_layouts/up5401ea.py`) and install the layout again.

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
numpad_disables_sys_numlock = 1
disable_due_inactivity_time = 60
touchpad_disables_numpad = 1
key_repetitions = 0
multitouch = 0
one_touch_key_rotation = 0
activation_time = 1
sys_numlock_enables_numpad = 1
top_left_icon_activation_time = 1
top_left_icon_slide_func_activation_x_ratio = 0.3
top_left_icon_slide_func_activation_y_ratio = 0.3
top_right_icon_slide_func_activation_x_ratio = 0.3
top_right_icon_slide_func_activation_y_ratio = 0.3
enabled_touchpad_pointer = 3
press_key_when_is_done_untouch = 1
enabled = 0
default_backlight_level = 0x01
top_left_icon_brightness_func_disabled = 0
distance_to_move_only_pointer = 250
```

| Option                                        | Required | Default           | Description |
| --------------------------------------------- | -------- | ----------------- | ----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| **System**                                    |          |                   |
| `enabled`                                     |          | `0`               | NumberPad running status (enabled/disabled)
| `disable_due_inactivity_time`                 |          | `60.0` [s]            | NumberPad is automatically disabled when have not received any event for this interval<br><br>decimal places allowed
| `touchpad_disables_numpad`                    |          | `1`            | when is touchpad disabled is disabled NumberPad aswell, valid value is `1` or `0` (e.g. via Fn+special key)<br><br>status is being attempted for the first time from `gsettings get org.gnome.desktop.peripherals.touchpad send-events`, tested can be via direct change `gsettings set org.gnome.desktop.peripherals.touchpad send-events 'enabled'` or simulation of Touchpad toggling via CLI `xdotool key XF86TouchpadToggle` or `xdotool key XF86TouchpadOn` and `xdotool key XF86TouchpadOff`, secondary is taken result of `xinput` - in this case can be for get this work used [this script](https://github.com/ldrahnik/elementary-os-scripts/blob/master/toggle_touchpad.sh) which has to be binded to Touchpad special key
| `sys_numlock_enables_numpad`                  |          | `1`           | obtained via active `LED_NUML` of keyboard device<br><br>so by default NumberPad reflects both: disabling NumberPad when is system numlock disabled even activating in the same moment as is system numlock activated<br><br>System numlock can be simulated `xdotool key Num_Lock`<br><br>`sys_numlock_enables_numpad` is set up to `1` automatically even when is in config file  read value `0` (overwritten) in case when is not defined in key layout on any position key `EV_KEY.KEY_NUMLOCK` and top right icon is not defined (size values `top_right_icon_width` and `top_right_icon_height`)
| `numpad_disables_sys_numlock`                  |          | `1`           | when is set to `1` is every time during inactivation of NumberPad sent `KEY_NUMLOCK`. Is useful do not send NumLock when is to laptop connected external keyboard and goal is only disable NumberPad on laptop but keep NumLock on external keyboard enabled    
| `enabled_touchpad_pointer`                  |          | `3`           | valid values are `0`, `1`, `2`, `3` <br><br>when is set to `1` touchpad pointer can be used to moving and for clicking and can be clicked pointer buttons left, right and middle when is NumberPad activated, `0` disable this usage and `2` allowes only pointer button clicks, `3` allowes only touchpad pointer moving without clicks (touchpad tap-to-click is disabled/enabled using `gnome` via `gsettings` and for `xinput` for `X11` with this order priority)
| **Key layout**                                |          |
| `activation_time`              |          | `1.0` [seconds]             | amount of time you have to touch `top_right_icon` or another spot with key `EV_KEY.KEY_NUMLOCK` for the NumberPad activation/deactivation<br><br>decimal places allowed
| `multitouch`                                  |          | `0`           | up to quint tap when enabled<br><br>Example 1: can be enabled NumberPad when second finger is touched on touchpad somewhere as well;<br><br>Example 2: brightness can be changed during using NumberPad for calculating)
| `one_touch_key_rotation`                      |          | `0`           | possibility of altering multiple keys during one-touch
| `key_repetitions`                             |          | `0`           | possible to enable with value `1` hold key for repeated pressing key like on a physical keyboard
| `distance_to_move_only_pointer`                             |          | `0` [px]           | when is set up `press_key_when_is_done_untouch = 1` (by default) and disabled `one_touch_key_rotation = 0` (by default) and is crossed with finger line of bordering key is implemented reset of current key so will not be printed, this option allows specify the same behaviour but inside key area with distance in px crossed to another key and is set up to enable with value `1` hold key for repeated pressing key like on a physical keyboard
| **Top left icon**                             |          |                   | custom function is used when is NumberPad activated and is first touched `top_left_icon` and finger is slid to center and untouched atleast after ratio of touchpad width > `top_left_icon_slide_func_activation_x_ratio` and height > `top_left_icon_slide_func_activation_y_ratio` and array `top_left_icon_custom_keys` is not empty<br><br>brightness function is used only when is NumberPad activated, `top_left_icon_brightness_function_disabled` is not `1`, array `backlight_levels` is not empty and works like endless loop of incrementing brightness in interval `top_left_icon_activation_time`
| `top_left_icon_activation_time`               |          | `1.0` [s]             | amount of time for touch `top_left_icon`<br><br>decimal places allowed
| `top_left_icon_slide_func_activation_x_ratio` |          | `0.3` (30%)         | ratio of touchpad width of slide
| `top_left_icon_slide_func_activation_y_ratio` |          | `0.3` (30%)         | ratio of touchpad height of slide   
| `top_left_icon_brightness_func_disabled`      |          | `0`            | valid value is `0` or `1`, allow force disable brightness change function<br><br>brightness function is auto disabled when is empty array `backlight_levels` and when is not set `top_left_icon_width` or `top_left_icon_width` `backlight_levels`
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
numpad_disables_sys_numlock=0
```

State without external keyboard / removing external keyboard means these changes:

```
sys_numlock_enables_numpad=1
numpad_disables_sys_numlock=1
```

## Credits

Thank you very much all the contributors of [asus-numberpad-driver](https://github.com/mohamed-badaoui/asus-numberpad-driver) for your work.

Thank you who-t for great post about multitouch [Understanding evdev](http://who-t.blogspot.com/2016/09/understanding-evdev.html).


## Existing similar projects

- [python service, first initialization] <https://gitlab.com/Thraen/gx735_touchpad_numpad>
- [python service] <https://github.com/danahynes/Asus_L410M_Numpad> inspired by [python service, first initialization] <https://gitlab.com/Thraen/gx735_touchpad_numpad>
- [python service, configurable, the most spread repository] <https://github.com/mohamed-badaoui/asus-numberpad-driver> inspired by [python service] <https://gitlab.com/Thraen/gx735_touchpad_numpad>
- [c++ and meson] <https://github.com/xytovl/asus-numpad> inspired by/rewritten version of [python service, configurable, the most spread repository] <https://github.com/mohamed-badaoui/asus-numberpad-driver>
- [rust] <https://github.com/iamkroot/asus-numpad> rewritten in rust the same python project which was starting point for this repository  <https://github.com/mohamed-badaoui/asus-numberpad-driver>
- [python service, configurable, the most up-to-date] **This project with continuing work based on** [python service, configurable, the most spread repository] <https://github.com/mohamed-badaoui/asus-numberpad-driver>
- [c++] <https://github.com/haronaut/asus_numberpad>

## Existing related projects

- [WIP, package for arch based open rc systems] <https://codeberg.org/BenWestcott/asus-numpad-driver-openrc> prepare for this driver PKGBUILD and other infrastructure needed for Arch-based OpenRC systems

## Existing related articles

- [Numpad linux driver — implementation of multitouch] <https://medium.com/@ldrahnik/numpad-linux-driver-implementation-of-multitouch-bd8ae76a8d6c>

**Why have been these projects created?** Because linux does not support NumberPad integration to touchpad ([reported issue for Ubuntu here](https://bugs.launchpad.net/ubuntu/+source/linux/+bug/1810183))

**Why was this project created?** Because compared to mentioned projects I implemented more features and fixed more found bugs and I have time keep driver up-to-date.

**Stargazers project history?**

[![Stargazers over time](https://starchart.cc/asus-linux-drivers/asus-numberpad-driver.svg)](https://starchart.cc/asus-linux-drivers/asus-numberpad-driver)

**Buy me a coffee** 

Do you think my effort put into open source is useful for you / others? Put star on the GitHub repository. Every star makes me proud. The same as any contribution. Would you like to reward me more? Now exists the way. You can invite me for a coffee! I really appreciate that!

Is preferred [ko-fi.com/ldrahnik](https://ko-fi.com/ldrahnik) instead of [buymeacoffee.com/ldrahnik](https://buymeacoffee.com/ldrahnik) because of zero commissions.

[![BuyMeACoffee](https://img.shields.io/badge/Buy%20to%20maintainer%20a%20coffee-ffdd00?style=for-the-badge&logo=buy-me-a-coffee&logoColor=black)](https://ko-fi.com/ldrahnik)

[![Ko-fi supporters](images/kofi.png)](https://ko-fi.com/ldrahnik)

[![Buy me a coffee supporters](images/buymeacoffee.png)](https://buymeacoffee.com/ldrahnik)
