#!/usr/bin/env python3

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

from evdev import InputDevice
import libevdev.const
import numpy as np
from libevdev import EV_ABS, EV_KEY, EV_MSC, EV_SYN, Device, InputEvent

# Setup logging
# LOG=DEBUG sudo -E ./asus_touchpad.py  # all messages
# LOG=ERROR sudo -E ./asus_touchpad.py  # only error messages
logging.basicConfig()
log = logging.getLogger('Pad')
log.setLevel(os.environ.get('LOG', 'INFO'))

# Select model from command line
model = 'up5401ea'  # Model used in the derived script (with symbols)
if len(sys.argv) > 1:
    model = sys.argv[1]

model_layout = importlib.import_module('numpad_layouts.' + model)

percentage_key: libevdev.const = EV_KEY.KEY_5

touchpad_disables_numpad = getattr(model_layout, "touchpad_disables_numpad", True)
key_repetitions = getattr(model_layout, "key_repetitions", False)
multitouch = getattr(model_layout, "multitouch", False)
one_touch_key_rotation = getattr(model_layout, "one_touch_key_rotation", False)
top_right_icon_width = getattr(model_layout, "top_right_icon_width", 0)
top_right_icon_height = getattr(model_layout, "top_right_icon_height", 0)
top_right_icon_activation_time = getattr(model_layout, "top_right_icon_activation_time", 1)
sys_numlock_enables_numpad = getattr(model_layout, "sys_numlock_enables_numpad", False)

if not top_right_icon_width > 0 or not top_right_icon_height > 0:
    log.debug('top_right_icon width and height is required to set > 0.')
    sys.exit(1)

keys = getattr(model_layout, "keys", [])
if not len(keys) > 0 or not len(keys[0]) > 0:
    log.debug('keys is required to set, dimension has to be atleast array of len 1 inside array')
    sys.exit(1)

backlight_levels = getattr(model_layout, "backlight_levels", [])
default_backlight_level = getattr(model_layout, "default_backlight_level", "0x01")

top_left_icon_width = getattr(model_layout, "top_left_icon_width", 0)
top_left_icon_height = getattr(model_layout, "top_left_icon_height", 0)
top_left_icon_activation_time = getattr(model_layout, "top_left_icon_activation_time", 1)
top_left_icon_brightness_func_disabled = getattr(model_layout, "top_left_icon_brightness_func_disabled", None)
top_left_icon_slide_func_activate_numpad = getattr(model_layout, "top_left_icon_slide_func_activate_numpad", True)
top_left_icon_slide_func_activation_x_ratio = getattr(model_layout, "top_left_icon_slide_func_activation_x_ratio", 0.3)
top_left_icon_slide_func_activation_y_ratio = getattr(model_layout, "top_left_icon_slide_func_activation_y_ratio", 0.3)
top_left_icon_slide_func_keys = getattr(model_layout, "top_left_icon_slide_func_keys", [
    InputEvent(EV_KEY.KEY_CALC, 1),
    InputEvent(EV_SYN.SYN_REPORT, 0),
    InputEvent(EV_KEY.KEY_CALC, 0),
    InputEvent(EV_SYN.SYN_REPORT, 0)
])

try_times = getattr(model_layout, "try_times", 5)
try_sleep = getattr(model_layout, "try_sleep", 0.1)

left_offset = getattr(model_layout, "left_offset", 0)
right_offset = getattr(model_layout, "right_offset", 0)
top_offset = getattr(model_layout, "top_offset", 0)
bottom_offset = getattr(model_layout, "bottom_offset", 0)

if len(sys.argv) > 2:
    percentage_key = EV_KEY.codes[int(sys.argv[2])]

# Figure out devices from devices file
touchpad: Optional[str] = None
touchpad_name: Optional[str] = None
keyboard: Optional[str] = None
dev_k = None
numlock: bool = False
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
                log.debug('Detect touchpad from %s', line.strip())
                touchpad_name = line.split("\"")[1]

            if touchpad_detected == 1:
                if "S: " in line:
                    # search device id
                    device_id = re.sub(r".*i2c-(\d+)/.*$",
                                       r'\1', line).replace("\n", "")
                    log.debug('Set touchpad device id %s from %s',
                              device_id, line.strip())

                if "H: " in line:
                    touchpad = line.split("event")[1]
                    touchpad = touchpad.split(" ")[0]
                    touchpad_detected = 2
                    log.debug('Set touchpad id %s from %s',
                              touchpad, line.strip())

            # Look for the keyboard
            if keyboard_detected == 0 and ("Name=\"AT Translated Set 2 keyboard" in line or ("Name=\"ASUE" in line and "Keyboard" in line)):
                keyboard_detected = 1
                log.debug('Detect keyboard from %s', line.strip())

            # We look for keyboard with numlock, scrollock, capslock inputs
            if keyboard_detected == 1 and "H: " in line:
                keyboard = line.split("event")[1]
                keyboard = keyboard.split(" ")[0]

                dev_k = InputDevice('/dev/input/event' + str(keyboard))
                k_capabilities = dev_k.capabilities(verbose=True)

                if "LED_NUML" in k_capabilities.values().__str__():
                    keyboard_detected = 2
                    log.debug('Set keyboard %s from %s', keyboard, line.strip())
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
log.debug('Touchpad min-max: x %d-%d, y %d-%d', minx, maxx, miny, maxy)
log.debug('Numpad min-max: x %d-%d, y %d-%d', minx_numpad,
          maxx_numpad, miny_numpad, maxy_numpad)

# Detect col, row count from map of keys
col_count = len(max(keys, key=len))
row_count = len(keys)
col_width = (maxx_numpad - minx_numpad) / col_count
row_height = (maxy_numpad - miny_numpad) / row_count

# Create a new keyboard device to send numpad events
# KEY_5:6
# KEY_APOSTROPHE:40
# [...]
percentage_key = EV_KEY.KEY_5

if len(sys.argv) > 2:
    percentage_key = EV_KEY.codes[int(sys.argv[2])]

dev = Device()
dev.name = "Asus Touchpad/Numpad"
dev.enable(EV_KEY.KEY_LEFTSHIFT)
dev.enable(EV_KEY.KEY_NUMLOCK)
for key_to_enable in top_left_icon_slide_func_keys:
    dev.enable(key_to_enable)

for col in keys:
    for key in col:
        dev.enable(key)

if percentage_key != EV_KEY.KEY_5:
    dev.enable(percentage_key)

udev = dev.create_uinput_device()


def use_bindings_for_touchpad_left_key():
    global numlock

    key_events = []
    for custom_key in top_left_icon_slide_func_keys:
        key_events.append(custom_key)

    try:
        udev.send_events(key_events)

        if top_left_icon_slide_func_activate_numpad is True and not numlock:
            sys_numlock = get_system_numlock()
            local_numlock_pressed(sys_numlock)

        log.info("Used bindings for touchpad left_icon slide function")

    except OSError as e:
        log.error("Cannot send event, %s", e)


def is_pressed_touchpad_top_right_icon():
    global top_right_icon_width, top_right_icon_height, abs_mt_slot_x_values, abs_mt_slot_y_values, abs_mt_slot_value

    if abs_mt_slot_x_values[abs_mt_slot_value] >= maxx - top_right_icon_width and\
        abs_mt_slot_y_values[abs_mt_slot_value] <= top_right_icon_height:
            return True
    else:
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
        log.info("Touched top_left_icon in time:")
        log.info(time())
        abs_mt_slot_numpad_key[abs_mt_slot_value] = EV_KEY.KEY_CALC
    else:
        set_none_to_current_mt_slot()


def increase_brightness():
    global brightness, backlight_levels

    if (brightness + 1) >= len(backlight_levels):
        brightness = 0
    else:
        brightness += 1

    log.info("Increased brightness of backlight to")
    log.info(brightness)

    numpad_cmd = "i2ctransfer -f -y " + device_id + " w13@0x15 0x05 0x00 0x3d 0x03 0x06 0x00 0x07 0x00 0x0d 0x14 0x03 " + \
        backlight_levels[brightness] + " 0xad"
    subprocess.call(numpad_cmd, shell=True)


def activate_numpad():
    global brightness, default_backlight_level

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
    global brightness

    try:
        d_t.ungrab()

        numpad_cmd = "i2ctransfer -f -y " + device_id + \
            " w13@0x15 0x05 0x00 0x3d 0x03 0x06 0x00 0x07 0x00 0x0d 0x14 0x03 0x00 0xad"
        subprocess.call(numpad_cmd, shell=True)

        brightness = 0
    except (OSError, libevdev.device.DeviceGrabError):
        pass


abs_mt_slot_value: int = 0
# -1 inactive, > 0 active
abs_mt_slot = np.array([-1, -1, -1, -1, -1], int)
abs_mt_slot_numpad_key = np.array([None, None, None, None, None], dtype=libevdev.const.EventCode)
abs_mt_slot_x_values = np.array([-1, -1, -1, -1, -1], int)
abs_mt_slot_y_values = np.array([-1, -1, -1, -1, -1], int)
# equal to multi finger maximum
support_for_maximum_abs_mt_slots: int = 1
if multitouch:
    support_for_maximum_abs_mt_slots = 5
unsupported_abs_mt_slot: bool = False
top_right_icon_touch_start_time = 0
top_left_icon_touch_start_time = 0
brightness: int = 0

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


def pressed_numpad_key():
    log.info("Pressed numpad key")
    log.info(abs_mt_slot_numpad_key[abs_mt_slot_value])

    if abs_mt_slot_numpad_key[abs_mt_slot_value] == percentage_key:
        events = [
            InputEvent(EV_KEY.KEY_LEFTSHIFT, 1),
            InputEvent(EV_SYN.SYN_REPORT, 0),
            InputEvent(abs_mt_slot_numpad_key[abs_mt_slot_value], 1),
            InputEvent(EV_SYN.SYN_REPORT, 0)
        ]
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

    if abs_mt_slot_numpad_key[abs_mt_slot_value] == percentage_key:
        events = [
            InputEvent(EV_KEY.KEY_LEFTSHIFT, 0),
            InputEvent(EV_SYN.SYN_REPORT, 0),
            InputEvent(abs_mt_slot_numpad_key[abs_mt_slot_value], 0),
            InputEvent(EV_SYN.SYN_REPORT, 0)
        ]
    else:
        events = [
            InputEvent(abs_mt_slot_numpad_key[abs_mt_slot_value], 0),
            InputEvent(EV_SYN.SYN_REPORT, 0)
        ]
   
    if replaced_by_key:
        abs_mt_slot_numpad_key[abs_mt_slot_value] = replaced_by_key
    else:
        set_none_to_current_mt_slot()

    try:
        udev.send_events(events)

    except OSError as e:
        log.warning("Cannot send press event, %s", e)


def get_touched_key():
    global abs_mt_slot_x_values, abs_mt_slot_y_values

    try:
        col = math.floor((abs_mt_slot_x_values[abs_mt_slot_value] - minx_numpad) / col_width)
        row = math.floor((abs_mt_slot_y_values[abs_mt_slot_value] - miny_numpad) / row_height)

        if row < 0 or col < 0:
            return None

        return keys[row][col]
    except IndexError:
        return None


def is_not_finger_moved_to_another_key():
    global abs_mt_slot_numpad_key, abs_mt_slot_x_values, abs_mt_slot_y_values,\
        top_left_icon_touch_start_time, top_right_icon_touch_start_time

    touched_key_when_pressed = abs_mt_slot_numpad_key[abs_mt_slot_value]

    if touched_key_when_pressed is None:
        return

    if touched_key_when_pressed == EV_KEY.KEY_CALC:
        pass
    elif touched_key_when_pressed == EV_KEY.KEY_NUMLOCK:
        if top_right_icon_touch_start_time != 0 and\
            not is_pressed_touchpad_top_right_icon():
                log.info("Finger moved away from defined area for numlock / right_icon")
                log.info("Unpressed numlock key")
                top_right_icon_touch_start_time = 0

    elif numlock:
        touched_key_now = get_touched_key()
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

    sys_numlock = get_system_numlock()

    if not sys_numlock and numlock:
        numlock = False
        deactivate_numpad()
        log.info("Numpad deactivated")
    elif sys_numlock and sys_numlock_enables_numpad and not numlock:
        numlock = True
        activate_numpad()
        log.info("Numpad activated")


def local_numlock_pressed(sys_numlock):
    global brightness, numlock

    # Activating
    if not numlock:

        # has to close as possible to send_numlock (because threads checking diff between these)
        numlock = True
        if not sys_numlock:
            send_numlock_key(1)
            send_numlock_key(0)
            log.info("System numlock activated")

        log.info("Numpad activated")
        activate_numpad()

    # Inactivating
    else:

        # has to close as possible to send_numlock (because threads checking diff between these
        numlock = False
        if sys_numlock:
            send_numlock_key(1)
            send_numlock_key(0)
            log.info("System numlock deactivated")

        log.info("Numpad deactivated")
        deactivate_numpad()

    set_none_to_current_mt_slot()

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


def pressed_touchpad_top_right_icon(value):
    global top_right_icon_touch_start_time, abs_mt_slot_numpad_key

    if value == 1:
        top_right_icon_touch_start_time = time()
        log.info("Touched numlock in time:")
        log.info(time())
        abs_mt_slot_numpad_key[abs_mt_slot_value] = EV_KEY.KEY_NUMLOCK


def is_slided_from_top_left_icon(e):
    global top_left_icon_touch_start_time, abs_mt_slot_numpad_key, abs_mt_slot_x_values, abs_mt_slot_y_values

    if e.value != 0:
        return

    if top_left_icon_touch_start_time == 0:
        return

    activation_min_x = top_left_icon_slide_func_activation_x_ratio * maxx
    activation_min_y = top_left_icon_slide_func_activation_x_ratio * maxy

    if abs_mt_slot_numpad_key[abs_mt_slot_value] == EV_KEY.KEY_CALC and\
        abs_mt_slot_x_values[abs_mt_slot_value] > top_left_icon_slide_func_activation_x_ratio * maxx and\
        abs_mt_slot_y_values[abs_mt_slot_value] > top_left_icon_slide_func_activation_x_ratio * maxy:

        log.info("Slided from top_left_icon taken longer then is required. X, y:")
        log.info(abs_mt_slot_x_values[abs_mt_slot_value])
        log.info(abs_mt_slot_y_values[abs_mt_slot_value])
        log.info("Required is min x, y:")
        log.info(activation_min_x)
        log.info(activation_min_y)

        top_left_icon_touch_start_time = 0

        return True
    else:
        return False


def takes_top_left_icon_touch_longer_then_set_up_activation_time():
    global top_left_icon_activation_time,\
        top_left_icon_touch_start_time

    if top_left_icon_touch_start_time == 0:
        return

    press_duration = time() - top_left_icon_touch_start_time

    if (abs_mt_slot_numpad_key[abs_mt_slot_value] == EV_KEY.KEY_CALC and\
        press_duration > top_left_icon_activation_time):

        log.info("Press top_left_icon taken longer then is required activation time:")
        log.info(time() - top_left_icon_touch_start_time)
        log.info("Activation time is:")
        log.info(top_left_icon_activation_time)

        # start cycle again (smooth change of brightness)
        top_left_icon_touch_start_time = time()

        return True
    else:
        return False


def takes_top_right_icon_touch_longer_then_set_up_activation_time():
    global top_right_icon_activation_time, top_right_icon_touch_start_time

    if top_right_icon_touch_start_time == 0:
        return

    press_duration = time() - top_right_icon_touch_start_time

    if (abs_mt_slot_numpad_key[abs_mt_slot_value] == EV_KEY.KEY_NUMLOCK and\
        press_duration > top_right_icon_activation_time):

        log.info("Press top_right_icon taken longer then is required activation time:")
        log.info(time() - top_right_icon_touch_start_time)
        log.info("Activation time is:")
        log.info(top_right_icon_activation_time)

        top_right_icon_touch_start_time = 0

        return True
    else:
        return False


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


def listen_touchpad_events():
    global brightness, d_t, abs_mt_slot_value, abs_mt_slot, abs_mt_slot_numpad_key,\
        abs_mt_slot_x_values, abs_mt_slot_y_values, support_for_maximum_abs_mt_slots,\
        unsupported_abs_mt_slot, top_right_icon_touch_start_time, touchpad_name

    for e in d_t.events():

        # ignore POINTER_BUTTON when is numpad on
        if numlock:
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
            continue

        if e.matches(EV_MSC.MSC_TIMESTAMP):

            # top right icon (numlock) activation
            sys_numlock = get_system_numlock()
            is_touchpad_enabled = is_device_enabled(touchpad_name)
            if is_pressed_touchpad_top_right_icon() and\
                takes_top_right_icon_touch_longer_then_set_up_activation_time() and\
                    (
                        (is_touchpad_enabled and touchpad_disables_numpad) or\
                        not touchpad_disables_numpad
                    ):
                local_numlock_pressed(sys_numlock)

            # top left icon (brightness change) activation
            if numlock and is_pressed_touchpad_top_left_icon() and\
                takes_top_left_icon_touch_longer_then_set_up_activation_time() and\
                len(backlight_levels) > 0 and top_left_icon_brightness_func_disabled is not True:

                    increase_brightness()

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

            log.debug('finger down at x %d y %d', abs_mt_slot_x_values[abs_mt_slot_value], (
                abs_mt_slot_y_values[abs_mt_slot_value]))

            if is_pressed_touchpad_top_right_icon():
                pressed_touchpad_top_right_icon(e.value)
                continue
            elif is_pressed_touchpad_top_left_icon():
                pressed_touchpad_top_left_icon(e)
                continue
            elif is_slided_from_top_left_icon(e):
                use_bindings_for_touchpad_left_key()
                continue

            # Numpad is not activated
            if not numlock:
                continue

            if(
                abs_mt_slot_x_values[abs_mt_slot_value] < minx_numpad or
                abs_mt_slot_x_values[abs_mt_slot_value] > maxx_numpad or
                abs_mt_slot_y_values[abs_mt_slot_value] < miny_numpad or
                abs_mt_slot_y_values[abs_mt_slot_value] > maxy_numpad
            ):
                continue

            col = math.floor(
                (abs_mt_slot_x_values[abs_mt_slot_value] - minx_numpad) / col_width)
            row = math.floor(
                (abs_mt_slot_y_values[abs_mt_slot_value] - miny_numpad) / row_height)

            if row < 0 or col < 0:
                continue

            if abs_mt_slot_numpad_key[abs_mt_slot_value] == None and e.value == 0:
                continue

            try:
                abs_mt_slot_numpad_key[abs_mt_slot_value] = keys[row][col]
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


# Gets the enable device property for the device Id  
def is_device_enabled(device_name):
    propData = subprocess.check_output(['xinput', '--list-props', device_name])
    propData = propData.decode()

    for line in propData.splitlines():
        if 'Device Enabled' in line:
            line = line.strip()
            if line[-1] == '1':
                return True
            else:
                return False

    return False


def check_touchpad_status():
    global touchpad_name, numlock, touchpad_disables_numpad

    is_touchpad_enabled = is_device_enabled(touchpad_name)

    if not is_touchpad_enabled and touchpad_disables_numpad and numlock:
        numlock = False
        deactivate_numpad()
        log.info("Numpad deactivated")


def check_system_numlock_status():
    while True:
        check_system_numlock_vs_local()
        sleep(0.5)


def check_touchpad_status_endless_cycle():
    while True:
        check_touchpad_status()
        sleep(0.5)


threads = []
# if keyboard with numlock indicator was found
# thread for listening change of system numlock
if dev_k:
    t = threading.Thread(target=check_system_numlock_status)
    threads.append(t)
    t.start()

# if disabling touchpad disables numpad aswell
if d_t and touchpad_name and touchpad_disables_numpad:
    t = threading.Thread(target=check_touchpad_status_endless_cycle)
    threads.append(t)
    t.start()

listen_touchpad_events()