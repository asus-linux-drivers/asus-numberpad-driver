#!/usr/bin/env python3

import configparser
import importlib
import logging
import math
import os
import re
import subprocess
import sys
import threading
from time import sleep, time
from typing import Optional

import libevdev.const
import numpy as np
from evdev import InputDevice, ecodes as ecodess
from libevdev import EV_ABS, EV_KEY, EV_MSC, EV_SYN, Device, InputEvent


EV_KEY_TOP_LEFT_ICON = "EV_KEY_TOP_LEFT_ICON"


numlock: bool = False

# Setup logging
# LOG=DEBUG sudo -E ./asus_touchpad.py  # all messages
# LOG=ERROR sudo -E ./asus_touchpad.py  # only error messages
logging.basicConfig()
log = logging.getLogger('Pad')
log.setLevel(os.environ.get('LOG', 'INFO'))


# Constants
try_times = 5
try_sleep = 0.1


# Numpad layout model
model = None
if len(sys.argv) > 1:
    model = sys.argv[1]
try:
    model_layout = importlib.import_module('numpad_layouts.' + model)
except:
    log.error("Numpad layout *.py from dir numpad_layouts is required as first argument. Re-run install script or add missing first argument (valid value is b7402, e210ma, g533, gx551, gx701, up5401, ..).")
    sys.exit(1)

# Config file dir
config_file_dir = ""
if len(sys.argv) > 2:
    config_file_dir = sys.argv[2]


# Layout
left_offset = getattr(model_layout, "left_offset", 0)
right_offset = getattr(model_layout, "right_offset", 0)
top_offset = getattr(model_layout, "top_offset", 0)
bottom_offset = getattr(model_layout, "bottom_offset", 0)
top_left_icon_width = getattr(model_layout, "top_left_icon_width", 0)
top_left_icon_height = getattr(model_layout, "top_left_icon_height", 0)
top_right_icon_width = getattr(model_layout, "top_right_icon_width", 0)
top_right_icon_height = getattr(model_layout, "top_right_icon_height", 0)
top_left_icon_slide_func_keys = getattr(model_layout, "top_left_icon_slide_func_keys", [
    EV_KEY.KEY_CALC
])
keys = getattr(model_layout, "keys", [])
if not len(keys) > 0 or not len(keys[0]) > 0:
    log.error('keys is required to set, dimension has to be atleast array of len 1 inside array')
    sys.exit(1)
keys_ignore_offset = getattr(model_layout, "keys_ignore_offset", [])
touchpad_physical_buttons_are_inside_numpad = getattr(model_layout, "touchpad_physical_buttons_are_inside_numpad", True)
backlight_levels = getattr(model_layout, "backlight_levels", [])


# Config
CONFIG_FILE_NAME = "asus_touchpad_numpad_dev"
CONFIG_SECTION = "main"
CONFIG_ENABLED = "enabled"
CONFIG_ENABLED_DEFAULT = False
CONFIG_LAST_BRIGHTNESS = "brightness"
CONFIG_DEFAULT_BACKLIGHT_LEVEL = "default_backlight_level"
CONFIG_DEFAULT_BACKLIGHT_LEVEL_DEFAULT = "0x01"
CONFIG_LEFT_ICON_ACTIVATION_TIME = "top_left_icon_activation_time"
CONFIG_LEFT_ICON_ACTIVATION_TIME_DEFAULT = True
CONFIG_TOP_LEFT_ICON_BRIGHTNESS_FUNC_DISABLED = "top_left_icon_brightness_func_disabled"
CONFIG_TOP_LEFT_ICON_BRIGHTNESS_FUNC_DISABLED_DEFAULT = False
CONFIG_TOP_LEFT_ICON_SLIDE_FUNC_ACTIVATE_NUMPAD = "top_left_icon_slide_func_activates_numpad"
CONFIG_TOP_LEFT_ICON_SLIDE_FUNC_ACTIVATE_NUMPAD_DEFAULT = True
CONFIG_TOP_LEFT_ICON_SLIDE_FUNC_DEACTIVATE_NUMPAD = "top_left_icon_slide_func_deactivates_numpad"
CONFIG_TOP_LEFT_ICON_SLIDE_FUNC_DEACTIVATE_NUMPAD_DEFAULT = True
CONFIG_TOP_LEFT_ICON_SLIDE_FUNC_ACTIVATION_X_RATIO = "top_left_icon_slide_func_activation_x_ratio"
CONFIG_TOP_LEFT_ICON_SLIDE_FUNC_ACTIVATION_X_RATIO_DEFAULT = 0.3
CONFIG_TOP_LEFT_ICON_SLIDE_FUNC_ACTIVATION_Y_RATIO = "top_left_icon_slide_func_activation_y_ratio"
CONFIG_TOP_LEFT_ICON_SLIDE_FUNC_ACTIVATION_Y_RATIO_DEFAULT = 0.3
CONFIG_TOP_RIGHT_ICON_SLIDE_FUNC_ACTIVATION_X_RATIO = "top_right_icon_slide_func_activation_x_ratio"
CONFIG_TOP_RIGHT_ICON_SLIDE_FUNC_ACTIVATION_X_RATIO_DEFAULT = 0.3
CONFIG_TOP_RIGHT_ICON_SLIDE_FUNC_ACTIVATION_Y_RATIO = "top_right_icon_slide_func_activation_y_ratio"
CONFIG_TOP_RIGHT_ICON_SLIDE_FUNC_ACTIVATION_Y_RATIO_DEFAULT = 0.3
CONFIG_NUMPAD_DISABLES_SYS_NUMLOCK = "numpad_disables_sys_numlock"
CONFIG_NUMPAD_DISABLES_SYS_NUMLOCK_DEFAULT = 0
CONFIG_DISABLE_DUE_INACTIVITY_TIME = "disable_due_inactivity_time"
CONFIG_DISABLE_DUE_INACTIVITY_TIME_DEFAULT = 60
CONFIG_TOUCHPAD_DISABLES_NUMPAD = "touchpad_disables_numpad"
CONFIG_TOUCHPAD_DISABLES_NUMPAD_DEFAULT = True
CONFIG_KEY_REPETITIONS = "key_repetitions"
CONFIG_KEY_REPETITIONS_DEFAULT = False
CONFIG_MULTITOUCH = "multitouch"
CONFIG_MULTITOUCH_DEFAULT = False
CONFIG_ONE_TOUCH_KEY_ROTATION = "one_touch_key_rotation"
CONFIG_ONE_TOUCH_KEY_ROTATION_DEFAULT = False
CONFIG_ACTIVATION_TIME = "activation_time"
CONFIG_ACTIVATION_TIME_DEFAULT = True
CONFIG_NUMLOCK_ENABLES_NUMPAD = "sys_numlock_enables_numpad"
CONFIG_NUMLOCK_ENABLES_NUMPAD_DEFAULT = False

config = configparser.ConfigParser()
config_lock = threading.Lock()


# methods for read & write from config file
def config_get(key, key_default):
    try:
        value = config.get(CONFIG_SECTION, key)
        parsed_value = parse_value_from_config(value)
        return parsed_value
    except:
        config.set(CONFIG_SECTION, key, parse_value_to_config(key_default))
        return key_default


def parse_value_from_config(value):
    if value == '0':
        return False
    elif value == '1':
        return True
    else:
        return value


def parse_value_to_config(value):
    if value == True:
        return '1'
    elif value == False:
        return '0'
    else:
        return str(value)


def config_save():
    global config_file_dir

    config_file_path = config_file_dir + CONFIG_FILE_NAME
    try:
        with open(config_file_path, 'w') as configFile:
            config.write(configFile)

        log.info('Saving config file: \"%s\"', config_file_path)
    except:
        log.error('Error during writting to config file: \"%s\"', config_file_path)
        pass


def config_set(key, value, no_save=False, already_has_lock=False):
    global config, config_file_dir, config_lock

    if not already_has_lock:
        config_lock.acquire()

    config.set(CONFIG_SECTION, key, parse_value_to_config(value))

    if not no_save:
        config_save()

    if not already_has_lock:
        config_lock.release()

    return value


# Figure out devices from devices file
touchpad: Optional[str] = None
touchpad_name: Optional[str] = None
keyboard: Optional[str] = None
dev_k = None
numlock_lock = threading.Lock()
device_id: Optional[str] = None

# Look into the devices file #
while try_times > 0:

    touchpad_detected = 0
    keyboard_detected = 0

    with open('/proc/bus/input/devices', 'r') as f:
        lines = f.readlines()
        for line in lines:
            # Look for the touchpad #
            if touchpad_detected == 0 and ("Name=\"ASUE" in line or "Name=\"ELAN" in line) and "Touchpad" in line:
                touchpad_detected = 1
                log.info('Detecting touchpad from string: \"%s\"', line.strip())
                touchpad_name = line.split("\"")[1]

            if touchpad_detected == 1:
                if "S: " in line:
                    # search device id
                    device_id = re.sub(r".*i2c-(\d+)/.*$",
                                       r'\1', line).replace("\n", "")
                    log.info('Set touchpad device id %s from %s',
                              device_id, line.strip())

                if "H: " in line:
                    touchpad = line.split("event")[1]
                    touchpad = touchpad.split(" ")[0]
                    touchpad_detected = 2
                    log.info('Set touchpad id %s from %s',
                              touchpad, line.strip())

            # Look for the keyboard
            if keyboard_detected == 0 and ("Name=\"AT Translated Set 2 keyboard" in line or (("Name=\"ASUE" in line or "Name=\"Asus" in line) and "Keyboard" in line)):
                keyboard_detected = 1
                log.info(
                    'Detecting keyboard from string: \"%s\"', line.strip())

            # We look for keyboard with numlock, scrollock, capslock inputs
            if keyboard_detected == 1 and "H: " in line:
                keyboard = line.split("event")[1]
                keyboard = keyboard.split(" ")[0]

                dev_k = InputDevice('/dev/input/event' + str(keyboard))
                k_capabilities = dev_k.capabilities(verbose=True)

                if "LED_NUML" in k_capabilities.values().__str__():
                    keyboard_detected = 2
                    log.info('Set keyboard %s from %s', keyboard, line.strip())
                else:
                    keyboard_detected = 0
                    dev_k = None
                    keyboard = None

            # Stop looking if touchpad and keyboard have been found
            if touchpad_detected == 2 and keyboard_detected == 2:
                break

    if touchpad_detected != 2 or keyboard_detected != 2:
        try_times -= 1
        if try_times == 0:
            if keyboard_detected != 2:
                log.error("Can't find keyboard (code: %s)", keyboard_detected)
                # keyboard is optional, no sys.exit(1)!
            if touchpad_detected != 2:
                log.error("Can't find touchpad (code: %s)", touchpad_detected)
                sys.exit(1)
            if touchpad_detected == 2 and not device_id.isnumeric():
                log.error("Can't find device id")
                sys.exit(1)
    else:
        break

    sleep(try_sleep)

# Start monitoring the touchpad
fd_t = open('/dev/input/event' + str(touchpad), 'rb')
d_t = Device(fd_t)

# Retrieve touchpad dimensions
ai = d_t.absinfo[EV_ABS.ABS_X]
(minx, maxx) = (ai.minimum, ai.maximum)
minx_numpad = minx + left_offset
maxx_numpad = maxx - right_offset
ai = d_t.absinfo[EV_ABS.ABS_Y]
(miny, maxy) = (ai.minimum, ai.maximum)
miny_numpad = miny + top_offset
maxy_numpad = maxy - bottom_offset
log.info('Touchpad min-max: x %d-%d, y %d-%d', minx, maxx, miny, maxy)
log.info('Numpad min-max: x %d-%d, y %d-%d', minx_numpad,
          maxx_numpad, miny_numpad, maxy_numpad)

# Detect col, row count from map of keys
col_count = len(max(keys, key=len))
row_count = len(keys)
col_width = (maxx_numpad - minx_numpad) / col_count
row_height = (maxy_numpad - miny_numpad) / row_count

# Create a new keyboard device to send numpad events
dev = Device()
dev.name = "Asus Touchpad/Numpad"
dev.enable(EV_KEY.KEY_NUMLOCK)
# predefined for all possible unicode characters <leftshift>+<leftctrl>+<U>+<0-F>
dev.enable(EV_KEY.KEY_LEFTSHIFT)
dev.enable(EV_KEY.KEY_LEFTCTRL)
dev.enable(EV_KEY.KEY_U)
dev.enable(EV_KEY.KEY_0)
dev.enable(EV_KEY.KEY_1)
dev.enable(EV_KEY.KEY_2)
dev.enable(EV_KEY.KEY_3)
dev.enable(EV_KEY.KEY_4)
dev.enable(EV_KEY.KEY_5)
dev.enable(EV_KEY.KEY_6)
dev.enable(EV_KEY.KEY_7)
dev.enable(EV_KEY.KEY_8)
dev.enable(EV_KEY.KEY_9)
dev.enable(EV_KEY.KEY_A)
dev.enable(EV_KEY.KEY_B)
dev.enable(EV_KEY.KEY_C)
dev.enable(EV_KEY.KEY_D)
dev.enable(EV_KEY.KEY_E)
dev.enable(EV_KEY.KEY_F)
dev.enable(EV_KEY.KEY_SPACE)
for key_to_enable in top_left_icon_slide_func_keys:
    dev.enable(key_to_enable)

def isEvent(event):
    if getattr(event, "name", None) is not None and\
            getattr(ecodess, event.name):
        return True
    else:
        return False

def is_device_enabled(device_name):
    global getting_device_status_failure_count
    try:
        getting_device_status_failure_count = 0

        propData = subprocess.check_output(['xinput', '--list-props', device_name])
        propData = propData.decode()

        for line in propData.splitlines():
            if 'Device Enabled' in line:
                line = line.strip()
                if line[-1] == '1':
                    return True
                else:
                    return False

        getting_device_status_failure_count += 1
        return False
    except:
        getting_device_status_failure_count += 1

        log.info('Getting Device Enabled via xinput failed')
        return True


for col in keys:
    for key in col:
        if getattr(key, "name", None) is not None and\
            getattr(ecodess, key.name):
            dev.enable(key)

udev = dev.create_uinput_device()


def use_slide_func_for_top_right_icon():
    global numlock

    local_numlock_pressed()

    log.info("Func for touchpad right_icon slide function")


def use_bindings_for_touchpad_left_icon_slide_function():

    global numlock, top_left_icon_slide_func_deactivates_numpad, top_left_icon_slide_func_activates_numpad, top_left_icon_slide_func_keys

    key_events = []
    for custom_key in top_left_icon_slide_func_keys:
        key_events.append(InputEvent(custom_key, 1))
        key_events.append(InputEvent(EV_SYN.SYN_REPORT, 0))
        key_events.append(InputEvent(custom_key, 0))
        key_events.append(InputEvent(EV_SYN.SYN_REPORT, 0))

    try:
        udev.send_events(key_events)

        if top_left_icon_slide_func_activates_numpad is True and not numlock:
            local_numlock_pressed()
        elif top_left_icon_slide_func_deactivates_numpad is True and numlock:
            local_numlock_pressed()

        log.info("Used bindings for touchpad left_icon slide function")

    except OSError as e:
        log.error("Cannot send event, %s", e)


def is_pressed_touchpad_top_right_icon():
    global top_right_icon_width, top_right_icon_height, abs_mt_slot_x_values, abs_mt_slot_y_values, abs_mt_slot_value

    if abs_mt_slot_x_values[abs_mt_slot_value] >= maxx - top_right_icon_width and\
        abs_mt_slot_y_values[abs_mt_slot_value] <= top_right_icon_height:
            return True
  
    return False


def is_pressed_touchpad_top_left_icon():
    global top_left_icon_width, top_left_icon_height, abs_mt_slot_x_values, abs_mt_slot_y_values, abs_mt_slot_value

    if not top_left_icon_width > 0 or \
       not top_left_icon_height > 0:
        return False

    if abs_mt_slot_x_values[abs_mt_slot_value] <= top_left_icon_width and\
        abs_mt_slot_y_values[abs_mt_slot_value] <= top_left_icon_height:
        return True
    else:
        return False


def set_none_to_current_mt_slot():
    global abs_mt_slot_numpad_key,\
        abs_mt_slot_x_values, abs_mt_slot_y_values

    abs_mt_slot_numpad_key[abs_mt_slot_value] = None
    abs_mt_slot_x_values[abs_mt_slot_value] = 0
    abs_mt_slot_y_values[abs_mt_slot_value] = 0


def pressed_touchpad_top_left_icon(e):
    global top_left_icon_touch_start_time, abs_mt_slot_numpad_key, abs_mt_slot_value

    if e.value == 1:
        top_left_icon_touch_start_time = time()
        log.info("Touched top_left_icon in time: %s", time())
        abs_mt_slot_numpad_key[abs_mt_slot_value] = EV_KEY_TOP_LEFT_ICON
    else:
        set_none_to_current_mt_slot()


def increase_brightness():
    global brightness, backlight_levels, config

    if (brightness + 1) >= len(backlight_levels):
        brightness = 0
    else:
        brightness += 1

    log.info("Increased brightness of backlight to")
    log.info(brightness)

    config_set(CONFIG_LAST_BRIGHTNESS, backlight_levels[brightness])

    numpad_cmd = "i2ctransfer -f -y " + device_id + " w13@0x15 0x05 0x00 0x3d 0x03 0x06 0x00 0x07 0x00 0x0d 0x14 0x03 " + \
            backlight_levels[brightness] + " 0xad"

    try:
        subprocess.call(numpad_cmd, shell=True)
    except:
        pass


def send_numlock_key(value):

    events = [
        InputEvent(EV_MSC.MSC_SCAN, 70053),
        InputEvent(EV_KEY.KEY_NUMLOCK, value),
        InputEvent(EV_SYN.SYN_REPORT, 0)
    ]

    try:
        udev.send_events(events)
    except OSError as e:
        log.error("Cannot send event, %s", e)


def activate_numpad():
    global brightness, device_id, default_backlight_level

    config_set(CONFIG_ENABLED, True)

    try:
        d_t.grab()

        subprocess.call("i2ctransfer -f -y " + device_id +
            " w13@0x15 0x05 0x00 0x3d 0x03 0x06 0x00 0x07 0x00 0x0d 0x14 0x03 0x01 0xad", shell=True)
        if default_backlight_level != "0x01":
            subprocess.call("i2ctransfer -f -y " + device_id + " w13@0x15 0x05 0x00 0x3d 0x03 0x06 0x00 0x07 0x00 0x0d 0x14 0x03 " +
                default_backlight_level + " 0xad", shell=True)

        try:
            brightness = backlight_levels.index(default_backlight_level)
        except ValueError:
            # so after start and then click on icon for increasing brightness
            # will be used first indexed value in given array with index 0 (0 = -1 + 1) 
            # (if exists)
            # TODO: atm do not care what last value is now displayed and which one (nearest higher) should be next (default 0x01 means turn leds on with last used level of brightness)
            brightness = -1
    except (OSError, libevdev.device.DeviceGrabError):
        pass


def deactivate_numpad():
    global brightness, device_id

    config_set(CONFIG_ENABLED, False)

    numpad_cmd = "i2ctransfer -f -y " + device_id + \
            " w13@0x15 0x05 0x00 0x3d 0x03 0x06 0x00 0x07 0x00 0x0d 0x14 0x03 0x00 0xad"    

    try:
        d_t.ungrab()
        subprocess.call(numpad_cmd, shell=True)
        brightness = 0
    except (OSError, libevdev.device.DeviceGrabError):
        pass


def get_system_numlock():
    global dev_k

    if not dev_k:
        return None

    leds_k = dev_k.leds(verbose=True)

    led_numl_list = list(filter(lambda x: 'LED_NUML' in x, leds_k))

    if len(led_numl_list):
        return True
    else:
        return False


def local_numlock_pressed():
    global brightness, numlock

    is_touchpad_enabled = is_device_enabled(touchpad_name)                
    if not ((not touchpad_disables_numpad and not is_touchpad_enabled) or is_touchpad_enabled):
        return

    sys_numlock = get_system_numlock()

    numlock_lock.acquire()

    # Activating
    if not numlock:

        numlock = True
        if not sys_numlock:
            send_numlock_key(1)
            send_numlock_key(0)
            log.info("System numlock activated")

        log.info("Numpad activated")
        activate_numpad()

    # Inactivating
    else:

        numlock = False
        if sys_numlock and numpad_disables_sys_numlock:
            send_numlock_key(1)
            send_numlock_key(0)
            log.info("System numlock deactivated")

        log.info("Numpad deactivated")
        deactivate_numpad()

    set_none_to_current_mt_slot()

    numlock_lock.release()


def read_config_file():
    global config, config_file_dir

    config_file_path = config_file_dir + CONFIG_FILE_NAME

    try:
        if not config.has_section(CONFIG_SECTION):
            config.add_section(CONFIG_SECTION)

        config.read(config_file_path)
    except:
        pass

def load_all_config_values():
    global config
    global keys
    global top_right_icon_height
    global top_right_icon_width
    global numpad_disables_sys_numlock
    global disable_due_inactivity_time
    global touchpad_disables_numpad
    global key_repetitions
    global multitouch
    global one_touch_key_rotation
    global activation_time
    global sys_numlock_enables_numpad
    global top_left_icon_activation_time
    global top_left_icon_slide_func_activates_numpad
    global top_left_icon_slide_func_deactivates_numpad
    global top_left_icon_slide_func_activation_x_ratio
    global top_left_icon_slide_func_activation_y_ratio
    global top_right_icon_slide_func_activation_x_ratio
    global top_right_icon_slide_func_activation_y_ratio
    global numlock
    global default_backlight_level
    global top_left_icon_brightness_func_disabled
    global support_for_maximum_abs_mt_slots
    global config_lock

    config_lock.acquire()

    read_config_file()

    numpad_disables_sys_numlock = config_get(CONFIG_NUMPAD_DISABLES_SYS_NUMLOCK, CONFIG_NUMPAD_DISABLES_SYS_NUMLOCK_DEFAULT)
    disable_due_inactivity_time = int(config_get(CONFIG_DISABLE_DUE_INACTIVITY_TIME, CONFIG_DISABLE_DUE_INACTIVITY_TIME_DEFAULT))
    touchpad_disables_numpad = config_get(CONFIG_TOUCHPAD_DISABLES_NUMPAD, CONFIG_TOUCHPAD_DISABLES_NUMPAD_DEFAULT)
    key_repetitions = config_get(CONFIG_KEY_REPETITIONS, CONFIG_KEY_REPETITIONS_DEFAULT)
    multitouch = config_get(CONFIG_MULTITOUCH, CONFIG_MULTITOUCH_DEFAULT)
    one_touch_key_rotation = config_get(CONFIG_ONE_TOUCH_KEY_ROTATION, CONFIG_ONE_TOUCH_KEY_ROTATION_DEFAULT)
    activation_time = int(config_get(CONFIG_ACTIVATION_TIME, CONFIG_ACTIVATION_TIME_DEFAULT))
    sys_numlock_enables_numpad = config_get(CONFIG_NUMLOCK_ENABLES_NUMPAD, CONFIG_NUMLOCK_ENABLES_NUMPAD_DEFAULT)
    key_numlock_is_used = any(EV_KEY.KEY_NUMLOCK in x for x in keys)
    if (not top_right_icon_height > 0 or not top_right_icon_width > 0) and not key_numlock_is_used:
        sys_numlock_enables_numpad = True
    config_set(CONFIG_NUMLOCK_ENABLES_NUMPAD, sys_numlock_enables_numpad, True, True)
    top_left_icon_activation_time = int(config_get(CONFIG_LEFT_ICON_ACTIVATION_TIME, CONFIG_LEFT_ICON_ACTIVATION_TIME_DEFAULT))
    top_left_icon_slide_func_activates_numpad = config_get(CONFIG_TOP_LEFT_ICON_SLIDE_FUNC_ACTIVATE_NUMPAD, CONFIG_TOP_LEFT_ICON_SLIDE_FUNC_ACTIVATE_NUMPAD_DEFAULT)
    top_left_icon_slide_func_deactivates_numpad = config_get(CONFIG_TOP_LEFT_ICON_SLIDE_FUNC_DEACTIVATE_NUMPAD, CONFIG_TOP_LEFT_ICON_SLIDE_FUNC_DEACTIVATE_NUMPAD_DEFAULT)
    top_left_icon_slide_func_activation_x_ratio = float(config_get(CONFIG_TOP_LEFT_ICON_SLIDE_FUNC_ACTIVATION_X_RATIO, CONFIG_TOP_LEFT_ICON_SLIDE_FUNC_ACTIVATION_X_RATIO_DEFAULT))
    top_left_icon_slide_func_activation_y_ratio = float(config_get(CONFIG_TOP_LEFT_ICON_SLIDE_FUNC_ACTIVATION_Y_RATIO, CONFIG_TOP_LEFT_ICON_SLIDE_FUNC_ACTIVATION_Y_RATIO_DEFAULT))
    top_right_icon_slide_func_activation_x_ratio = float(config_get(CONFIG_TOP_RIGHT_ICON_SLIDE_FUNC_ACTIVATION_X_RATIO, CONFIG_TOP_RIGHT_ICON_SLIDE_FUNC_ACTIVATION_X_RATIO_DEFAULT))
    top_right_icon_slide_func_activation_y_ratio = float(config_get(CONFIG_TOP_RIGHT_ICON_SLIDE_FUNC_ACTIVATION_Y_RATIO, CONFIG_TOP_RIGHT_ICON_SLIDE_FUNC_ACTIVATION_Y_RATIO_DEFAULT))


    default_backlight_level = config_get(CONFIG_DEFAULT_BACKLIGHT_LEVEL, CONFIG_DEFAULT_BACKLIGHT_LEVEL_DEFAULT)
    if default_backlight_level == "0x01":
        try:
            default_backlight_level = config.get(CONFIG_SECTION, CONFIG_LAST_BRIGHTNESS)
        except:
            pass

    enabled = config_get(CONFIG_ENABLED, CONFIG_ENABLED_DEFAULT)

    top_left_icon_brightness_func_disabled = config_get(CONFIG_TOP_LEFT_ICON_BRIGHTNESS_FUNC_DISABLED, CONFIG_TOP_LEFT_ICON_BRIGHTNESS_FUNC_DISABLED_DEFAULT)
    if not backlight_levels:
        top_left_icon_brightness_func_disabled = True

    if multitouch:
        support_for_maximum_abs_mt_slots = 5
    else:
        support_for_maximum_abs_mt_slots = 1

    config_save()

    config_lock.release()

    if enabled and not numlock:
        local_numlock_pressed()



abs_mt_slot_value: int = 0
# -1 inactive, > 0 active
abs_mt_slot = np.array([-1, -1, -1, -1, -1], int)
abs_mt_slot_numpad_key = np.array([None, None, None, None, None], dtype=libevdev.const.EventCode)
abs_mt_slot_x_values = np.array([-1, -1, -1, -1, -1], int)
abs_mt_slot_y_values = np.array([-1, -1, -1, -1, -1], int)
# equal to multi finger maximum
support_for_maximum_abs_mt_slots: int = 1
unsupported_abs_mt_slot: bool = False
numlock_touch_start_time = 0
top_left_icon_touch_start_time = 0
top_right_icon_touch_start_time = 0
last_event_time = 0

config = configparser.ConfigParser()
load_all_config_values()

def set_tracking_id(value):
    try:

        if value > 0:
            log.info("Started new slot")
            # not know yet
            # log.info(abs_mt_slot_numpad_key[abs_mt_slot_value])
        else:
            log.info("Ended existing slot")
            # can be misunderstanding when is touched padding (is printed previous key)
            # log.info(abs_mt_slot_numpad_key[abs_mt_slot_value])

        abs_mt_slot[abs_mt_slot_value] = value
    except IndexError as e:
        log.error(e)


def get_compose_key_end_events_for_unicode_string():

    enter_pressed = InputEvent(EV_KEY.KEY_SPACE, 1)
    enter_unpressed = InputEvent(EV_KEY.KEY_SPACE, 0)

    events = [
        InputEvent(EV_MSC.MSC_SCAN, enter_pressed.code.value),
        enter_pressed,
        InputEvent(EV_SYN.SYN_REPORT, 0),
        InputEvent(EV_MSC.MSC_SCAN, enter_unpressed.code.value),
        enter_unpressed,
        InputEvent(EV_SYN.SYN_REPORT, 0)
    ]

    return events


def get_compose_key_start_events_for_unicode_string():

    left_shift_pressed = InputEvent(EV_KEY.KEY_LEFTSHIFT, 1)
    left_shift_unpressed = InputEvent(EV_KEY.KEY_LEFTSHIFT, 0)
    left_ctrl_pressed = InputEvent(EV_KEY.KEY_LEFTCTRL, 1)
    left_ctrl_unpressed = InputEvent(EV_KEY.KEY_LEFTCTRL, 0)
    key_U_pressed = InputEvent(EV_KEY.KEY_U, 1)
    key_U_unpressed = InputEvent(EV_KEY.KEY_U, 0)

    events = [
        InputEvent(EV_MSC.MSC_SCAN, left_ctrl_pressed.code.value),
        left_ctrl_pressed,
        InputEvent(EV_SYN.SYN_REPORT, 0),
        InputEvent(EV_MSC.MSC_SCAN, left_shift_pressed.code.value),
        left_shift_pressed,
        InputEvent(EV_SYN.SYN_REPORT, 0),
        InputEvent(EV_MSC.MSC_SCAN, key_U_pressed.code.value),
        key_U_pressed,
        InputEvent(EV_SYN.SYN_REPORT, 0),
        InputEvent(EV_MSC.MSC_SCAN, left_shift_unpressed.code.value),
        left_shift_unpressed,
        InputEvent(EV_SYN.SYN_REPORT, 0),
        InputEvent(EV_MSC.MSC_SCAN, key_U_unpressed.code.value),
        key_U_unpressed,
        InputEvent(EV_SYN.SYN_REPORT, 0),
        InputEvent(EV_MSC.MSC_SCAN, left_ctrl_unpressed.code.value),
        left_ctrl_unpressed,
        InputEvent(EV_SYN.SYN_REPORT, 0),
    ]

    return events


def get_events_for_unicode_string(string):

    for c in string:

        key_events = []

        for hex_digit in '%X' % ord(c):

            key_code = getattr(ecodess, 'KEY_%s' % hex_digit)
            key = EV_KEY.codes[int(key_code)]
            key_event_press = InputEvent(key, 1)
            key_event_unpress = InputEvent(key, 0)

            key_events = key_events + [
                InputEvent(EV_MSC.MSC_SCAN, key_event_press.code.value),
                key_event_press,
                InputEvent(EV_SYN.SYN_REPORT, 0),
                InputEvent(EV_MSC.MSC_SCAN, key_event_unpress.code.value),
                key_event_unpress,
                InputEvent(EV_SYN.SYN_REPORT, 0)
            ]

        start_events = get_compose_key_start_events_for_unicode_string()
        end_events = get_compose_key_end_events_for_unicode_string()
        return start_events + key_events + end_events


def pressed_numpad_key():

    log.info("Pressed numpad key")
    log.info(abs_mt_slot_numpad_key[abs_mt_slot_value])

    if not isEvent(abs_mt_slot_numpad_key[abs_mt_slot_value]):

        unicode_string = abs_mt_slot_numpad_key[abs_mt_slot_value]
        events = get_events_for_unicode_string(unicode_string)

    else:
        events = [
            InputEvent(abs_mt_slot_numpad_key[abs_mt_slot_value], 1),
            InputEvent(EV_SYN.SYN_REPORT, 0)
        ]

    try:
        udev.send_events(events)
    except OSError as e:
        log.warning("Cannot send press event, %s", e)


def replaced_numpad_key(touched_key_now):
    unpressed_numpad_key(touched_key_now)
    pressed_numpad_key()


def unpressed_numpad_key(replaced_by_key=None):


    log.info("Unpressed numpad key")
    log.info(abs_mt_slot_numpad_key[abs_mt_slot_value])

    if isEvent(abs_mt_slot_numpad_key[abs_mt_slot_value]):

        events = [
            InputEvent(abs_mt_slot_numpad_key[abs_mt_slot_value], 0),
            InputEvent(EV_SYN.SYN_REPORT, 0)
        ]

        try:
            udev.send_events(events)

        except OSError as e:
            log.warning("Cannot send press event, %s", e)


    if replaced_by_key:
        abs_mt_slot_numpad_key[abs_mt_slot_value] = replaced_by_key
    else:
        set_none_to_current_mt_slot()


def get_touched_key():
    global abs_mt_slot_x_values, abs_mt_slot_y_values, keys_ignore_offset

    try:
        col = math.floor((abs_mt_slot_x_values[abs_mt_slot_value] - minx_numpad) / col_width)
        row = math.floor((abs_mt_slot_y_values[abs_mt_slot_value] - miny_numpad) / row_height)

        if([max(row, 0), max(col, 0)] in keys_ignore_offset):
            row = max(row, 0)
            col = max(col, 0)

        if row < 0 or col < 0:
            return None

        return keys[row][col]
    except IndexError:
        return None


def is_not_finger_moved_to_another_key():
    global abs_mt_slot_numpad_key, abs_mt_slot_x_values,\
        abs_mt_slot_y_values, numlock_touch_start_time

    touched_key_when_pressed = abs_mt_slot_numpad_key[abs_mt_slot_value]
    touched_key_now = get_touched_key()

    if touched_key_when_pressed is None:
        return

    if touched_key_when_pressed == EV_KEY_TOP_LEFT_ICON:
        pass
    elif touched_key_when_pressed == EV_KEY.KEY_NUMLOCK:
        pass
    elif numlock:
        if touched_key_now != touched_key_when_pressed:

            if one_touch_key_rotation and touched_key_when_pressed != None and touched_key_now != None:
                replaced_numpad_key(touched_key_now)

            elif touched_key_when_pressed != None:
                unpressed_numpad_key()

            elif one_touch_key_rotation and touched_key_now != None:
                abs_mt_slot_numpad_key[abs_mt_slot_value] = touched_key_now
                pressed_numpad_key()


def check_system_numlock_vs_local():
    global brightness, numlock

    numlock_lock.acquire()

    sys_numlock = get_system_numlock()

    if not sys_numlock and numlock:
        numlock = False
        deactivate_numpad()
        log.info("Numpad deactivated")
    elif sys_numlock and sys_numlock_enables_numpad and not numlock:
        numlock = True
        activate_numpad()
        log.info("Numpad activated")

    numlock_lock.release()


def pressed_numlock_key(value):
    global numlock_touch_start_time, abs_mt_slot_numpad_key

    if value == 1:
        numlock_touch_start_time = time()
        log.info("Touched numlock in time: %s", time())
        abs_mt_slot_numpad_key[abs_mt_slot_value] = EV_KEY.KEY_NUMLOCK


def pressed_touchpad_top_right_icon(value):
    global top_right_icon_touch_start_time, numlock_touch_start_time, abs_mt_slot_numpad_key

    if value == 1:
        top_right_icon_touch_start_time = time()
        numlock_touch_start_time = time()
        log.info("Touched numlock in time: %s", time())
        abs_mt_slot_numpad_key[abs_mt_slot_value] = EV_KEY.KEY_NUMLOCK


def is_slided_from_top_right_icon(e):
    global top_right_icon_touch_start_time, abs_mt_slot_numpad_key, abs_mt_slot_x_values, abs_mt_slot_y_values

    if e.value != 0:
        return

    if top_right_icon_touch_start_time == 0:
        return

    activation_min_x = top_right_icon_slide_func_activation_x_ratio * maxx
    activation_min_y = top_right_icon_slide_func_activation_y_ratio * maxy

    if abs_mt_slot_numpad_key[abs_mt_slot_value] == EV_KEY.KEY_NUMLOCK and\
        abs_mt_slot_x_values[abs_mt_slot_value] < maxx - top_right_icon_slide_func_activation_x_ratio * maxx and\
        abs_mt_slot_y_values[abs_mt_slot_value] < maxy - top_right_icon_slide_func_activation_y_ratio * maxy:

        log.info("Slided from top_right_icon taken longer then is required. X, y:")
        log.info(abs_mt_slot_x_values[abs_mt_slot_value])
        log.info(abs_mt_slot_y_values[abs_mt_slot_value])
        log.info("Required is min x, y:")
        log.info(activation_min_x)
        log.info(activation_min_y)

        top_right_icon_touch_start_time = 0
        numlock_touch_start_time = 0

        return True
    else:
        return False


def is_slided_from_top_left_icon(e):
    global top_left_icon_touch_start_time, abs_mt_slot_numpad_key, abs_mt_slot_x_values, abs_mt_slot_y_values

    if e.value != 0:
        return False

    if top_left_icon_touch_start_time == 0:
        return False

    activation_min_x = top_left_icon_slide_func_activation_x_ratio * maxx
    activation_min_y = top_left_icon_slide_func_activation_y_ratio * maxy

    if abs_mt_slot_numpad_key[abs_mt_slot_value] == EV_KEY_TOP_LEFT_ICON and\
        abs_mt_slot_x_values[abs_mt_slot_value] > top_left_icon_slide_func_activation_x_ratio * maxx and\
        abs_mt_slot_y_values[abs_mt_slot_value] > top_left_icon_slide_func_activation_y_ratio * maxy:

        log.info("Slided from top_left_icon taken longer then is required. X, y:")
        log.info(abs_mt_slot_x_values[abs_mt_slot_value])
        log.info(abs_mt_slot_y_values[abs_mt_slot_value])
        log.info("Required is min x, y:")
        log.info(activation_min_x)
        log.info(activation_min_y)

        top_left_icon_touch_start_time = 0
        set_none_to_current_mt_slot()

        return True
    else:
        top_left_icon_touch_start_time = 0
        set_none_to_current_mt_slot()

        return False


def takes_top_left_icon_touch_longer_then_set_up_activation_time():
    global top_left_icon_activation_time,\
        top_left_icon_touch_start_time

    if top_left_icon_touch_start_time == 0:
        return False

    press_duration = time() - top_left_icon_touch_start_time

    if (abs_mt_slot_numpad_key[abs_mt_slot_value] == EV_KEY_TOP_LEFT_ICON and\
        press_duration > top_left_icon_activation_time):

        log.info("The top_left_icon was pressed longer than the activation time: %s",
                 time() - top_left_icon_touch_start_time)
        log.info("Activation time: %s", top_left_icon_activation_time)

        # start cycle again (smooth change of brightness)
        top_left_icon_touch_start_time = time()

        return True
    else:
        return False


def takes_numlock_longer_then_set_up_activation_time():
    global activation_time, numlock_touch_start_time

    if numlock_touch_start_time == 0:
        return

    press_duration = time() - numlock_touch_start_time

    if (abs_mt_slot_numpad_key[abs_mt_slot_value] == EV_KEY.KEY_NUMLOCK and\
        press_duration > activation_time):

        log.info("The numpad numlock was pressed longer than the activation time: %s",
                 time() - numlock_touch_start_time)
        log.info("Activation time: %s", activation_time)

        numlock_touch_start_time = 0

        return True
    else:
        return False


def stop_top_left_right_icon_slide_gestures():
    global top_left_icon_touch_start_time, top_right_icon_touch_start_time
    
    top_left_icon_touch_start_time = 0
    top_right_icon_touch_start_time = 0


def listen_touchpad_events():
    global brightness, d_t, abs_mt_slot_value, abs_mt_slot, abs_mt_slot_numpad_key,\
        abs_mt_slot_x_values, abs_mt_slot_y_values, support_for_maximum_abs_mt_slots,\
        unsupported_abs_mt_slot, numlock_touch_start_time, touchpad_name, last_event_time,\
        keys_ignore_offset

    for e in d_t.events():

        last_event_time = time()

        # ignore POINTER_BUTTON when is numpad on and buttons are not outside of numpad area
        if numlock and touchpad_physical_buttons_are_inside_numpad:
            if e.matches(EV_KEY.BTN_LEFT):
                continue
            elif e.matches(EV_KEY.BTN_RIGHT):
                continue
            elif e.matches(EV_KEY.BTN_MIDDLE):
                continue

        if e.matches(EV_ABS.ABS_MT_SLOT):
            if(e.value < support_for_maximum_abs_mt_slots):
                abs_mt_slot_value = e.value
                unsupported_abs_mt_slot = False
            else:
                unsupported_abs_mt_slot = True

        if unsupported_abs_mt_slot == True:
            # slide gestures with multitouch True: second finger stops slide gesture
            # slide gestures with multitouch False: finger out of capacity (6th) is ignored but GESTURE IS NOT STOPPED 
            if multitouch:
                stop_top_left_right_icon_slide_gestures()
            continue

        if e.matches(EV_MSC.MSC_TIMESTAMP):

            # top right icon (numlock) activation
            touched_key = get_touched_key()
            top_right_icon = is_pressed_touchpad_top_right_icon()
            if (top_right_icon or touched_key == EV_KEY.KEY_NUMLOCK) and takes_numlock_longer_then_set_up_activation_time():

                local_numlock_pressed()
                continue

            # top left icon (brightness change) activation
            if numlock and is_pressed_touchpad_top_left_icon() and\
                takes_top_left_icon_touch_longer_then_set_up_activation_time() and\
                len(backlight_levels) > 0 and top_left_icon_brightness_func_disabled is not True:

                increase_brightness()
                continue

        if e.matches(EV_ABS.ABS_MT_POSITION_X):
            abs_mt_slot_x_values[abs_mt_slot_value] = e.value
            is_not_finger_moved_to_another_key()

        if e.matches(EV_ABS.ABS_MT_POSITION_Y):
            abs_mt_slot_y_values[abs_mt_slot_value] = e.value
            is_not_finger_moved_to_another_key()

        if e.matches(EV_ABS.ABS_MT_TRACKING_ID):
            set_tracking_id(e.value)

        if e.matches(EV_KEY.BTN_TOOL_FINGER) or \
           e.matches(EV_KEY.BTN_TOOL_DOUBLETAP) or \
           e.matches(EV_KEY.BTN_TOOL_TRIPLETAP) or \
           e.matches(EV_KEY.BTN_TOOL_QUADTAP) or \
           e.matches(EV_KEY.BTN_TOOL_QUINTTAP):

            log.info('finger down at x %d y %d', abs_mt_slot_x_values[abs_mt_slot_value], (
                abs_mt_slot_y_values[abs_mt_slot_value]))

            if is_pressed_touchpad_top_right_icon():
                pressed_touchpad_top_right_icon(e.value)
                continue
            elif is_pressed_touchpad_top_left_icon():
                pressed_touchpad_top_left_icon(e)
                continue
            elif is_slided_from_top_left_icon(e):
                use_bindings_for_touchpad_left_icon_slide_function()
                continue
            elif is_slided_from_top_right_icon(e):
                use_slide_func_for_top_right_icon()
                continue

            col = math.floor(
                (abs_mt_slot_x_values[abs_mt_slot_value] - minx_numpad) / col_width)
            row = math.floor(
                (abs_mt_slot_y_values[abs_mt_slot_value] - miny_numpad) / row_height)

            if([max(row, 0), max(col, 0)] in keys_ignore_offset):
                row = max(row, 0)
                col = max(col, 0)
            elif (
                    abs_mt_slot_x_values[abs_mt_slot_value] > minx_numpad and
                    abs_mt_slot_x_values[abs_mt_slot_value] < maxx_numpad and
                    abs_mt_slot_y_values[abs_mt_slot_value] > miny_numpad and
                    abs_mt_slot_y_values[abs_mt_slot_value] < maxy_numpad
                ):
                if (row < 0 or col < 0):
                    continue
            else:
                continue

            if abs_mt_slot_numpad_key[abs_mt_slot_value] == None and e.value == 0:
                continue

            try:

                key = keys[row][col]

                # Numpad is not activated
                if not numlock and key != EV_KEY.KEY_NUMLOCK:
                    continue

                if key is None:
                    continue

                if key == EV_KEY.KEY_NUMLOCK:
                    pressed_numlock_key(e.value)
                    continue
                else:
                    abs_mt_slot_numpad_key[abs_mt_slot_value] = key

            except IndexError:
                log.error('Unhandled col/row %d/%d for position %d-%d',
                          col,
                          row,
                          abs_mt_slot_x_values[abs_mt_slot_value],
                          abs_mt_slot_y_values[abs_mt_slot_value]
                          )
                continue

            if e.value == 1:
                if key_repetitions:
                    pressed_numpad_key()
                else:
                    pressed_numpad_key()
                    unpressed_numpad_key()
            else:
                unpressed_numpad_key()

# auto ended thread for checking touchpad status (activated/deactivated)
# via xinput when is for example used wayland
getting_device_status_failure_count = 0

def check_touchpad_status():
    global touchpad_name, numlock, touchpad_disables_numpad

    numlock_lock.acquire()

    is_touchpad_enabled = is_device_enabled(touchpad_name)

    if not is_touchpad_enabled and touchpad_disables_numpad and numlock:
        numlock = False        
        deactivate_numpad()
        log.info("Numpad deactivated")

    numlock_lock.release()


def check_system_numlock_status():
    while True:
        check_system_numlock_vs_local()
        sleep(0.5)


def check_touchpad_status_endless_cycle():
    while True and getting_device_status_failure_count < 9:
        check_touchpad_status()
        sleep(0.5)

    log.info('Getting Device Enabled via xinput disabled because failed more then: \"%s\" times in row', getting_device_status_failure_count)


def check_numpad_automatical_disable_due_inactivity():
    global disable_due_inactivity_time, numpad_disables_sys_numlock, last_event_time, numlock

    while True:
        if\
            disable_due_inactivity_time and\
            numlock and\
            last_event_time != 0 and\
            time() > int(disable_due_inactivity_time) + last_event_time:

            numlock_lock.acquire()

            sys_numlock = get_system_numlock()
            if sys_numlock and numpad_disables_sys_numlock:
                send_numlock_key(1)
                send_numlock_key(0)
                log.info("System numlock deactivated")

            numlock = False
            deactivate_numpad()
            log.info("Numpad deactivated")
            numlock_lock.release()
        sleep(1)


def check_config_values_changes():
    while True:
        load_all_config_values()
        sleep(1)


threads = []
# if keyboard with numlock indicator was found
# thread for listening change of system numlock
if dev_k:
    t = threading.Thread(target=check_system_numlock_status)
    threads.append(t)
    t.start()

# if disabling touchpad disables numpad aswell
if d_t and touchpad_name:
    t = threading.Thread(target=check_touchpad_status_endless_cycle)
    threads.append(t)
    t.start()

t = threading.Thread(target=check_numpad_automatical_disable_due_inactivity)
threads.append(t)
t.start()

# check changes in config values
t = threading.Thread(target=check_config_values_changes)
threads.append(t)
t.start()

try:
    listen_touchpad_events()
except:
    log.error("Listening touchpad events unexpectedly failed")
    sys.exit(1)