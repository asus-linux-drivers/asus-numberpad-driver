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
import numpy as np
from libevdev import EV_ABS, EV_KEY, EV_LED, EV_MSC, EV_SYN, Device, InputEvent, const, device
from pyinotify import WatchManager, IN_CLOSE_WRITE, IN_IGNORED, IN_MOVED_TO, AsyncNotifier
import Xlib.display
import Xlib.X
import Xlib.XK
from xkbcommon import xkb
from pywayland.client import Display
from pywayland.protocol.wayland import WlSeat
import mmap
from smbus2 import SMBus, i2c_msg
import ast

xdg_session_type = os.environ.get('XDG_SESSION_TYPE')

display_var = os.environ.get('DISPLAY')
display_wayland_var = os.environ.get('WAYLAND_DISPLAY')

display_wayland = None
keyboard_state = None
display = None
keymap_loaded = False

logging.basicConfig(
    format='%(asctime)s %(levelname)s %(message)s',
    level=os.environ.get('LOG', 'INFO')
)
log = logging.getLogger('asus-numberpad-driver')

if not xdg_session_type:
  log.info("xdg session type can not be empty")
  sys.exit(1)

if xdg_session_type == "x11":

  while not display:
    try:
      display = Xlib.display.Display(display_var)
      log.info("X11 detected and connected succesfully to the display {}".format(display_var))
    except:
      log.info("X11 detected but not connected succesfully to the display {}. Exiting".format(display_var))
      sys.exit(1)

threads = []
stop_threads = False
enabled_evdev_keys = []

# only to avoid first - x11 only
gnome_current_layout = None
# only to avoid first - x11 even wayland (e.g. Ubuntu 22.04)
gnome_current_layout_index = None

def mod_name_to_specific_keysym_name(mod_name):
    global display_wayland

    mod_to_specific_keysym_name = {
        'Control': 'Control_L',
        'Shift': 'Shift_L',
        'Lock': 'Caps_Lock',
        'Mod1': 'Alt_L',
        'Mod2': 'Num_Lock',
        'Mod3': 'Caps_Lock',
        'Mod4': 'Meta_L',
        'Mod5': 'Scroll_Lock',
        'NumLock': 'Num_Lock',
        'Alt': 'Alt_L',
        'LevelThree': 'ISO_Level3_Shift',
        'LAlt': 'Alt_L',
        'RAlt': 'Alt_R',
        'RControl': 'Control_R',
        'LControl': 'Control_L',
        'ScrollLock': 'Scroll_Lock',
        'LevelFive': 'ISO_Level5_Shift',
        'AltGr': 'Alt_R',
        'Meta': 'Meta_L',
        'Super': 'Meta_L',
        'Hyper': 'Hyper_L'
    }

    mods_to_indexes_x11 = {
        "Shift": Xlib.X.ShiftMapIndex,
        "Lock": Xlib.X.LockMapIndex,
        "Control": Xlib.X.ControlMapIndex,
        "Mod1": Xlib.X.Mod1MapIndex,
        "Mod2": Xlib.X.Mod2MapIndex,
        "Mod3": Xlib.X.Mod3MapIndex,
        "Mod4": Xlib.X.Mod4MapIndex,
        "Mod5": Xlib.X.Mod5MapIndex
    }

    if display and mod_name in mods_to_indexes_x11:

      mods = display.get_modifier_mapping()
      first_keycode = mods[mods_to_indexes_x11[mod_name]][0]
      if first_keycode:
        key = EV_KEY.codes[int(first_keycode) - 8]
        keysym = display.keycode_to_keysym(first_keycode, 0)
        for key in Xlib.XK.__dict__:
          if key.startswith("XK") and Xlib.XK.__dict__[key] == keysym:
            return key[3:]
      else:
        return mod_to_specific_keysym_name[mod_name]
    elif display_wayland:

        keymap = keyboard_state.get_keymap()
        num_mods = keymap.num_mods()

        for keycode in keymap:
            keyboard_state_clean = keymap.state_new()
            key_state = keyboard_state_clean.update_key(keycode, xkb.KeyDirection.XKB_KEY_DOWN)

            num_layouts = keymap.num_layouts_for_key(keycode)
            for layout in range(0, num_layouts):

                if gnome_current_layout_index is not None and gnome_current_layout_index == layout:
                    layout_is_active = True
                else:
                    layout_is_active = keyboard_state_clean.layout_index_is_active(layout, xkb.StateComponent.XKB_STATE_LAYOUT_EFFECTIVE)

                if layout_is_active:
                    for mod_index in range(0, num_mods):

                        is_key_mod = key_state & xkb.StateComponent.XKB_STATE_MODS_DEPRESSED
                        if is_key_mod:

                            is_mod_active = keyboard_state_clean.mod_index_is_active(mod_index, xkb.StateComponent.XKB_STATE_MODS_DEPRESSED)
                            if is_mod_active:
                                if keymap.mod_get_name(mod_index) == mod_name:

                                    keysyms = keymap.key_get_syms_by_level(keycode, layout, 0)

                                    if len(keysyms) != 1:
                                        continue

                                    keysym_name = xkb.keysym_get_name(keysyms[0])
                                    #print(mod_name)
                                    #print(keycode)
                                    #print(keysym_name)
                                    return keysym_name

    else:
      return mod_to_specific_keysym_name[mod_name]


keysym_name_associated_to_evdev_key_reflecting_current_layout = None

# default are for unicode shortcuts + is loaded layout during start (BackSpace, Return - enter, asterisk, minus etc. can be found using xev)
def set_defaults_keysym_name_associated_to_evdev_key_reflecting_current_layout():
    global keysym_name_associated_to_evdev_key_reflecting_current_layout

    keysym_name_associated_to_evdev_key_reflecting_current_layout = {
        'Num_Lock': '',
         # unicode shortcut - for hex value
        '0': '',
        '1': '',
        '2': '',
        '3': '',
        '4': '',
        '5': '',
        '6': '',
        '7': '',
        '8': '',
        '9': '',
        'a': '',
        'b': '',
        'c': '',
        'd': '',
        'e': '',
        'f': '',
        # unicode shortcut - start sequence
        mod_name_to_specific_keysym_name('Shift'): '',
        mod_name_to_specific_keysym_name('Control'): '',
        'u': '',
        # unicode shortcut - end sequence
        'space': ''
    }


def get_keysym_name_associated_to_evdev_key_reflecting_current_layout():
    global keysym_name_associated_to_evdev_key_reflecting_current_layout

    # lazy initialization because of loading modifiers inside Shift & Control
    if not keysym_name_associated_to_evdev_key_reflecting_current_layout:
        set_defaults_keysym_name_associated_to_evdev_key_reflecting_current_layout()

    return keysym_name_associated_to_evdev_key_reflecting_current_layout


# necessary when are new keys enabled
def reset_udev_device():
    global dev, udev

    log.info("Old device at {} ({})".format(udev.devnode, udev.syspath))
    udev = dev.create_uinput_device()
    log.info("New device at {} ({})".format(udev.devnode, udev.syspath))

    # Sleep for a little bit so udev, libinput, Xorg, Wayland, ... all have had
    # a chance to see the device and initialize it. Otherwise the event
    # will be sent by the kernel but nothing is ready to listen to the
    # device yet
    sleep(1)


def enable_key(key_or_key_combination, reset_udev = False):
    global enabled_evdev_keys, dev, udev

    enabled_keys_count = len(enabled_evdev_keys)

    if isEvent(key_or_key_combination):
      if key_or_key_combination not in enabled_evdev_keys:
          enabled_evdev_keys.append(key_or_key_combination)
          dev.enable(key_or_key_combination)

    elif isEventList(key_or_key_combination):
      for key in key_or_key_combination:
        if key not in enabled_evdev_keys:
          enabled_evdev_keys.append(key)
          dev.enable(key)

    # one or more changed to something not enabled yet to send using udev device? -> udev device has to be re-created
    if len(enabled_evdev_keys) > enabled_keys_count and reset_udev:
      reset_udev_device()


def load_evdev_key_for_x11(char):
    global display, keysym_name_associated_to_evdev_key_reflecting_current_layout

    keysym = Xlib.XK.string_to_keysym(char)

    if keysym == 0:
      return

    keycode = display.keysym_to_keycode(keysym)
    key = EV_KEY.codes[int(keycode) - 8]

    # bare
    if display.keycode_to_keysym(keycode, 0) == keysym:
      pass
    # shift
    elif display.keycode_to_keysym(keycode, 1) == keysym:
      key = [load_evdev_key_for_x11(mod_name_to_specific_keysym_name('Shift')), key]
    # altgr
    elif display.keycode_to_keysym(keycode, 2) == keysym:
      key = [load_evdev_key_for_x11(mod_name_to_specific_keysym_name('AltGr')), key]
    # shift altgr
    elif display.keycode_to_keysym(keycode, 3) == keysym:
      key = [load_evdev_key_for_x11(mod_name_to_specific_keysym_name('Shift')), load_evdev_key_for_x11(mod_name_to_specific_keysym_name('AltGr')), key]

    set_evdev_key_for_char(char, key)

    enable_key(key)

    return key


def load_evdev_keys_for_x11(reset_udev = True):
  global enabled_evdev_keys, keymap_loaded

  enabled_keys_count = len(enabled_evdev_keys)

  for char in get_keysym_name_associated_to_evdev_key_reflecting_current_layout().copy():
    load_evdev_key_for_x11(char)

  # one or more changed to something not enabled yet to send using udev device? -> udev device has to be re-created
  if len(enabled_evdev_keys) > enabled_keys_count and reset_udev:
    reset_udev_device()

  keymap_loaded = True


def set_evdev_key_for_char(char, evdev_key):
    global keysym_name_associated_to_evdev_key_reflecting_current_layout

    # lazy initialization because of loading modifiers inside Shift & Control
    if not keysym_name_associated_to_evdev_key_reflecting_current_layout:
        set_defaults_keysym_name_associated_to_evdev_key_reflecting_current_layout()

    keysym_name_associated_to_evdev_key_reflecting_current_layout[char] = evdev_key


def get_evdev_key_for_char(char):
    keysym_name_associated_to_evdev_key_reflecting_current_layout = get_keysym_name_associated_to_evdev_key_reflecting_current_layout()

    return keysym_name_associated_to_evdev_key_reflecting_current_layout[char]


def isEvent(event):
    if hasattr(event, "name") and hasattr(EV_KEY, event.name):
        return True
    else:
        return False


def isEventList(events):
    if type(events) is list:
        for event in events:
            if not isEvent(event):
                return False
        return True
    else:
        return False


def load_evdev_key_for_wayland(char, keyboard_state):
    global gnome_current_layout_index

    keymap = keyboard_state.get_keymap()
    num_mods = keymap.num_mods()

    for keycode in keymap:

        keysym = xkb.keysym_from_name(char)

        num_layouts = keymap.num_layouts_for_key(keycode)
        for layout in range(0, num_layouts):

            num_levels = keymap.num_levels_for_key(keycode, layout)

            for level in range(0, num_levels):
                mod_masks_for_level = keymap.key_get_mods_for_level(keycode, layout, level)

                if len(mod_masks_for_level) < 1:
                    continue

                keysyms = keymap.key_get_syms_by_level(keycode, layout, level)

                if len(keysyms) != 1 or keysyms[0] != keysym:
                    continue

                for mod_mask_index in range(0, len(mod_masks_for_level)):

                    mod_evdev_keys = []
                    for mod_index in range(0, num_mods):

                        if (mod_masks_for_level[mod_mask_index] & (1 << mod_index) == 0):
                            continue

                        mod_name = keymap.mod_get_name(mod_index)

                        mod_as_evdev_key = load_evdev_key_for_wayland(mod_name_to_specific_keysym_name(mod_name), keyboard_state)
                        mod_evdev_keys.append(mod_as_evdev_key)

                        if not mod_as_evdev_key:
                            continue

                    if len(mod_evdev_keys) > 0:
                        key = mod_evdev_keys + [EV_KEY.codes[int(keycode - 8)]]
                    else:
                        key = EV_KEY.codes[int(keycode - 8)]


                    if gnome_current_layout_index is not None and gnome_current_layout_index == layout:
                        layout_is_active = True
                    else:
                        layout_is_active = keyboard_state.layout_index_is_active(layout, xkb.StateComponent.XKB_STATE_LAYOUT_EFFECTIVE)

                    if layout_is_active:
                        set_evdev_key_for_char(char, key)

                    enable_key(key)

                    return key


def wl_load_keymap_state():
    global keyboard_state, keymap_loaded

    enabled_keys = len(enabled_evdev_keys)

    for char in get_keysym_name_associated_to_evdev_key_reflecting_current_layout().copy():
        load_evdev_key_for_wayland(char, keyboard_state)

    # one or more changed to something not enabled yet to send using udev device? -> udev device has to be re-created
    if len(enabled_evdev_keys) > enabled_keys:
        reset_udev_device()

    keymap_loaded = True


def wl_keyboard_keymap_handler(keyboard, format_, fd, size):
    global keyboard_state

    keymap_data = mmap.mmap(
       fd, size, prot=mmap.PROT_READ, flags=mmap.MAP_PRIVATE
    )
    xkb_context = xkb.Context()
    keymap = xkb_context.keymap_new_from_buffer(keymap_data, length=size - 1)
    keymap_data.close()

    keyboard_state = keymap.state_new()

    wl_load_keymap_state()


def wl_registry_handler(registry, id_, interface, version):
  if interface == "wl_seat":
    seat = registry.bind(id_, WlSeat, version)
    keyboard = seat.get_keyboard()
    keyboard.dispatcher["keymap"] = wl_keyboard_keymap_handler


def load_keymap_listener_wayland():
    global stop_threads, display_wayland_var, display_wayland

    display_wayland = Display(display_wayland_var)
    display_wayland.connect()
    registry = display_wayland.get_registry()
    registry.dispatcher["global"] = wl_registry_handler
    display_wayland.dispatch(block=True)
    display_wayland.roundtrip()

    while not stop_threads and display_wayland.dispatch(block=True) != -1:
        pass


keymap_lock = threading.Lock()

def load_keymap_listener_x11():
    global stop_threads, display

    while not stop_threads:
      event = display.next_event()

      if event.type == Xlib.X.MappingNotify and event.count > 0 and event.request == Xlib.X.MappingKeyboard:

          keymap_lock.acquire()
          display.refresh_keyboard_mapping(event)
          load_evdev_keys_for_x11(True)
          log.debug(get_keysym_name_associated_to_evdev_key_reflecting_current_layout())
          keymap_lock.release()


EV_KEY_TOP_LEFT_ICON = "EV_KEY_TOP_LEFT_ICON"

numlock: bool = False

is_idled: bool = False

# Constants
try_times = 5
try_sleep = 0.1

gsettings_failure_count = 0
gsettings_max_failure_count = 3

getting_device_via_xinput_status_failure_count = 0
getting_device_via_xinput_status_max_failure_count = 3

getting_device_via_synclient_status_failure_count = 0
getting_device_via_synclient_status_max_failure_count = 3

# Numpad layout model
model = None
if len(sys.argv) > 1:
    model = sys.argv[1]
try:
    model_layout = importlib.import_module('layouts.' + model)
except:
    log.error("Numpad layout *.py from dir layouts is required as first argument. Re-run install script or add missing first argument (valid value is b7402, e210ma, g533, gx551, gx701, up5401ea, ..).")
    sys.exit(1)

# Config file dir
config_file_dir = ""
if len(sys.argv) > 2:
    config_file_dir = sys.argv[2]
# When is given config dir empty or is used default -> to ./ because inotify needs check folder (nor nothing = "")
if config_file_dir == "":
     config_file_dir = "./"

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

for row in keys:
    for field in row:
        if not isEvent(field) and not isEventList(field):
            set_evdev_key_for_char(field, '')
        if isEvent(field):
            enable_key(field)

keys_ignore_offset = getattr(model_layout, "keys_ignore_offset", [])
backlight_levels = getattr(model_layout, "backlight_levels", [])


# Config
CONFIG_FILE_NAME = "numberpad_dev"
CONFIG_SECTION = "main"
CONFIG_IDLED = "idled"
CONFIG_IDLED_DEFAULT = False
CONFIG_ENABLED = "enabled"
CONFIG_ENABLED_DEFAULT = False
CONFIG_LAST_BRIGHTNESS = "brightness"
CONFIG_IDLE_BRIGHTNESS = "idle_brightness"
CONFIG_IDLE_BRIGHTNESS_DEFAULT = 30
CONFIG_IDLE_ENABLED = "idle_enabled"
CONFIG_IDLE_ENABLED_DEFAULT = 0
CONFIG_IDLE_TIME = "idle_time"
CONFIG_IDLE_TIME_DEFAULT = 10
CONFIG_DEFAULT_BACKLIGHT_LEVEL = "default_backlight_level"
CONFIG_DEFAULT_BACKLIGHT_LEVEL_DEFAULT = "0x01"
CONFIG_LEFT_ICON_ACTIVATION_TIME = "top_left_icon_activation_time"
CONFIG_LEFT_ICON_ACTIVATION_TIME_DEFAULT = True
CONFIG_TOP_LEFT_ICON_BRIGHTNESS_FUNC_DISABLED = "top_left_icon_brightness_func_disabled"
CONFIG_TOP_LEFT_ICON_BRIGHTNESS_FUNC_DISABLED_DEFAULT = False
CONFIG_TOP_LEFT_ICON_SLIDE_FUNC_ACTIVATION_X_RATIO = "top_left_icon_slide_func_activation_x_ratio"
CONFIG_TOP_LEFT_ICON_SLIDE_FUNC_ACTIVATION_X_RATIO_DEFAULT = 0.2
CONFIG_TOP_LEFT_ICON_SLIDE_FUNC_ACTIVATION_Y_RATIO = "top_left_icon_slide_func_activation_y_ratio"
CONFIG_TOP_LEFT_ICON_SLIDE_FUNC_ACTIVATION_Y_RATIO_DEFAULT = 0.2
CONFIG_TOP_RIGHT_ICON_SLIDE_FUNC_ACTIVATION_X_RATIO = "top_right_icon_slide_func_activation_x_ratio"
CONFIG_TOP_RIGHT_ICON_SLIDE_FUNC_ACTIVATION_X_RATIO_DEFAULT = 0.2
CONFIG_TOP_RIGHT_ICON_SLIDE_FUNC_ACTIVATION_Y_RATIO = "top_right_icon_slide_func_activation_y_ratio"
CONFIG_TOP_RIGHT_ICON_SLIDE_FUNC_ACTIVATION_Y_RATIO_DEFAULT = 0.2
CONFIG_NUMPAD_DISABLES_SYS_NUMLOCK = "numpad_disables_sys_numlock"
CONFIG_NUMPAD_DISABLES_SYS_NUMLOCK_DEFAULT = True
CONFIG_DISABLE_DUE_INACTIVITY_TIME = "disable_due_inactivity_time"
CONFIG_DISABLE_DUE_INACTIVITY_TIME_DEFAULT = 0
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
CONFIG_NUMLOCK_ENABLES_NUMPAD_DEFAULT = True
CONFIG_ENABLED_TOUCHPAD_POINTER = "enabled_touchpad_pointer"
CONFIG_ENABLED_TOUCHPAD_POINTER_DEFAULT = 3
CONFIG_PRESS_KEY_WHEN_IS_DONE_UNTOUCH = "press_key_when_is_done_untouch"
CONFIG_PRESS_KEY_WHEN_IS_DONE_UNTOUCH_DEFAULT = True
CONFIG_DISTANCE_TO_MOVE_ONLY_POINTER = "distance_to_move_only_pointer"
CONFIG_DISTANCE_TO_MOVE_ONLY_POINTER_DEFAULT = False

config_file_path = config_file_dir + CONFIG_FILE_NAME
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


def send_value_to_touchpad_via_i2c(value):
    global device_id, device_addr

    try:
        with SMBus(int(device_id)) as bus:
            data = [0x05, 0x00, 0x3d, 0x03, 0x06, 0x00, 0x07, 0x00, 0x0d, 0x14, 0x03, int(value, 16), 0xad]
            msg = i2c_msg.write(device_addr, data)
            bus.i2c_rdwr(msg)
    except Exception as e:
        log.error('Error during sending via i2c: \"%s\"', e)


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
    global config_file_dir, config_file_path

    try:
        with open(config_file_path, 'w') as configFile:
            config.write(configFile)
            log.debug('Writting to config file: \"%s\"', configFile)
    except:
        log.error('Error during writting to config file: \"%s\"', config_file_path)
        pass


def config_set(key, value, no_save=False, already_has_lock=False):
    global config, config_file_dir, config_lock

    if not already_has_lock:
        #log.debug("config_set: config_lock.acquire will be called")
        config_lock.acquire()
        #log.debug("config_set: config_lock.acquire called succesfully")

    config.set(CONFIG_SECTION, key, parse_value_to_config(value))
    log.info('Setting up for config file key: \"%s\" with value: \"%s\"', key, value)

    if not no_save:
        config_save()

    if not already_has_lock:
        # because inotify (deadlock)
        sleep(0.1)
        config_lock.release()

    return value


def gsettingsSet(path, name, value):
    global gsettings_failure_count, gsettings_max_failure_count

    if gsettings_failure_count < gsettings_max_failure_count:
        try:
            sudo_user = os.environ.get('SUDO_USER')
            if sudo_user is not None:
                cmd = ['runuser', '-u', sudo_user, 'gsettings', 'set', path, name, str(value)]
            else:
                cmd = ['gsettings', 'set', path, name, str(value)]

            log.debug(cmd)
            subprocess.call(cmd)
        except:
            log.exception('gsettings set failed')
            gsettings_failure_count+=1
    else:
        log.debug('Gsettings failed more then: \"%s\" so is not try anymore', gsettings_max_failure_count)


def gsettingsGet(path, name):
    global gsettings_failure_count, gsettings_max_failure_count

    if gsettings_failure_count < gsettings_max_failure_count:
        try:
            cmd = ['gsettings', 'get', path, name]
            result = subprocess.check_output(cmd).rstrip()
            return result
        except:
            log.exception('gsettings get failed')
            gsettings_failure_count+=1
    else:
        log.debug('Gsettings failed more then: \"%s\" so is not try anymore', gsettings_max_failure_count)


def gsettingsGetTouchpadSendEvents():
    return gsettingsGet('org.gnome.desktop.peripherals.touchpad', 'send-events').decode().rstrip()

def gsettingsSetTouchpadTapToClick(value):
    gsettingsSet('org.gnome.desktop.peripherals.touchpad', 'tap-to-click', str(bool(value)).lower())

def gsettingsGetUnicodeHotkey():
    return gsettingsGet('org.freedesktop.ibus.panel.emoji', 'unicode-hotkey').decode().rstrip()


def get_compose_key_start_events_for_unicode_string(reset_udev = True):
    global gsettings_failure_count, gsettings_max_failure_count, mods_to_evdev_keys

    string_with_unicode_hotkey = gsettingsGetUnicodeHotkey()

    keys = []

    if string_with_unicode_hotkey is not None:

        string_with_unicode_hotkey = string_with_unicode_hotkey.split("'")[1]
        key_modifiers = re.findall("<(.*?)>", string_with_unicode_hotkey)

        for key_modifier in key_modifiers:
            try:
                key_evdev = get_evdev_key_for_char(mod_name_to_specific_keysym_name(key_modifier))
                keys.append(key_evdev)
                enable_key(key_evdev, reset_udev)
            except:
                log.error("Error during trying to find key for modifier of found compose shortcut {}".format(key_modifier))
                pass

        try:
            first_number_index = string_with_unicode_hotkey.rfind('>') + 1
            key_evdev = get_evdev_key_for_char(string_with_unicode_hotkey[first_number_index])
            keys.append(key_evdev)
            enable_key(key_evdev)
        except:
            pass
    else:

        control_key = get_evdev_key_for_char(mod_name_to_specific_keysym_name('Control'))
        keys.append(control_key)
        enable_key(control_key, reset_udev)

        shift_key = get_evdev_key_for_char(mod_name_to_specific_keysym_name('Shift'))
        keys.append(shift_key)
        enable_key(shift_key, reset_udev)

        u_key = get_evdev_key_for_char("u")
        keys.append(u_key)
        enable_key(u_key, reset_udev)


    events = []

    for key in keys:
        inputEvent = InputEvent(key, 1)
        events.append(InputEvent(EV_MSC.MSC_SCAN, inputEvent.code.value))
        events.append(inputEvent)

    for key in keys:
        inputEvent = InputEvent(key, 0)
        events.append(InputEvent(EV_MSC.MSC_SCAN, inputEvent.code.value))
        events.append(inputEvent)

    return events


# Figure out devices from devices file
touchpad: Optional[str] = None
touchpad_name: Optional[str] = None
keyboard: Optional[str] = None
d_k = None
fd_k = None
numlock_lock = threading.Lock()
idle_lock = threading.Lock()
device_id: Optional[str] = None
device_addr: Optional[int] = None

# Look into the devices file #
while try_times > 0:

    touchpad_detected = 0
    keyboard_detected = 0

    with open('/proc/bus/input/devices', 'r') as f:
        lines = f.readlines()
        for line in lines:
            # Look for the touchpad #

            # https://github.com/mohamed-badaoui/asus-touchpad-numpad-driver/issues/87
            # https://github.com/asus-linux-drivers/asus-numberpad-driver/issues/95
            # https://github.com/asus-linux-drivers/asus-numberpad-driver/issues/110
            # https://github.com/asus-linux-drivers/asus-numberpad-driver/issues/161
            if (touchpad_detected == 0 and ("Name=\"ASUE" in line or "Name=\"ELAN" in line or "Name=\"ASUP" or "Name=\"ASUF" in line) and "Touchpad" in line) or \
                (("Name=\"ASUE" in line or "Name=\"ELAN" in line or "Name=\"ASUP" in line or "Name=\"ASUF" in line) and ("1406" in line or "4F3:3101" in line) and "Touchpad" in line):

                touchpad_detected = 1
                log.info('Detecting touchpad from string: \"%s\"', line.strip())
                touchpad_name = line.split("\"")[1]

                # https://github.com/asus-linux-drivers/asus-numberpad-driver/issues/161
                if ("ASUF1416" in line or "ASUF1205" in line or "ASUF1204" in line):
                  device_addr = 0x38
                else:
                  device_addr = 0x15

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
            if keyboard_detected == 0 and ("Name=\"AT Translated Set 2 keyboard" in line or (("Name=\"ASUE" in line or "Name=\"Asus" in line or "Name=\"ASUP" in line or "Name=\"ASUF" in line) and "Keyboard" in line)):
                keyboard_detected = 1
                log.info(
                    'Detecting keyboard from string: \"%s\"', line.strip())

            # We look for keyboard with numlock, scrollock, capslock inputs
            if keyboard_detected == 1 and "H: " in line:
                keyboard = line.split("event")[1]
                keyboard = keyboard.split(" ")[0]

                with open('/dev/input/event' + str(keyboard), 'rb') as fd_k:
                    d_k = Device(fd_k)

                    if d_k.has(EV_LED.LED_NUML):
                        keyboard_detected = 2
                        log.info('Set keyboard %s from %s', keyboard, line.strip())
                    else:
                        keyboard_detected = 0
                        keyboard = None

                    d_k = None

            # Do not stop looking if touchpad and keyboard have been found
            # because more drivers can be installed
            # https://github.com/mohamed-badaoui/asus-touchpad-numpad-driver/issues/87
            # https://github.com/asus-linux-drivers/asus-numberpad-driver/issues/95
            #if touchpad_detected == 2 and keyboard_detected == 2:
            #    break

    if touchpad_detected != 2 or keyboard_detected != 2:
        try_times -= 1
        if try_times == 0:
            with open('/proc/bus/input/devices', 'r') as f:
                lines = f.readlines()
                for line in lines:
                    log.error(line)
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

# Open a handle to "/dev/i2c-x", representing the I2C bus
try:
    bus = SMBus()
    bus.open(int(device_id))
    bus.close()
except:
    log.error("Can't open the I2C bus connection (id: %s)", device_id)
    sys.exit(1)

# Start monitoring the touchpad
fd_t = open('/dev/input/event' + str(touchpad), 'rb')
d_t = Device(fd_t)

# Retrieve touchpad dimensions
ai = d_t.absinfo[EV_ABS.ABS_X]
minx, maxx = (ai.minimum, ai.maximum)
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
dev.name = touchpad_name.split(" ")[0] + " " + touchpad_name.split(" ")[1] + " NumberPad"
enable_key(EV_MSC.MSC_SCAN)
enable_key(EV_KEY.BTN_LEFT)
enable_key(EV_KEY.BTN_RIGHT)
enable_key(EV_KEY.BTN_MIDDLE)

# for x11 pre-enable keys for current keyboard layout (wayland have only handler for keymap)
if xdg_session_type == "x11" and display:
  log.info("X11 will try to load keymap")
  load_evdev_keys_for_x11(False)
  log.info("X11 loaded keymap succesfully")

for key_to_enable in top_left_icon_slide_func_keys:
  enable_key(key_to_enable)

def check_gnome_layout():
    global stop_threads, gnome_current_layout, gnome_current_layout_index, keyboard_state, display_wayland_var

    while not stop_threads:

        mru_sources = gsettingsGet('org.gnome.desktop.input-sources', 'mru-sources')
        try:
          mru_sources_evaluated = ast.literal_eval(mru_sources.decode())
        except:
          mru_sources_evaluated = []

        sources = gsettingsGet('org.gnome.desktop.input-sources', 'sources')
        try:
          sources_evaluated = ast.literal_eval(sources.decode())
        except:
          sources_evaluated = []

        if len(mru_sources_evaluated) > 0:

            mru_layout_index = sources_evaluated.index(mru_sources_evaluated[0])
            mru_layout = mru_sources_evaluated[0][1].split("+")[0]

            # first run, would be unnecessary duplicated loading wayland / x11 keymap
            if gnome_current_layout_index == None:
                gnome_current_layout_index = mru_layout_index
                gnome_current_layout = mru_layout

            elif display_wayland_var:
                if keyboard_state:
                    layout_is_active = keyboard_state.layout_index_is_active(mru_layout_index, xkb.StateComponent.XKB_STATE_LAYOUT_EFFECTIVE)

                    if not layout_is_active and gnome_current_layout_index is not mru_layout_index:
                        gnome_current_layout_index =  mru_layout_index
                        gnome_current_layout = mru_layout
                        wl_load_keymap_state()

            elif gnome_current_layout != mru_layout:

                    try:
                        cmd = ['setxkbmap', mru_layout, '-display', display_var]

                        log.debug(cmd)
                        subprocess.call(cmd)

                        gnome_current_layout = mru_layout
                    except:
                        log.exception('setxkbmap set failed')

        else:

            current = gsettingsGet('org.gnome.desktop.input-sources', 'current')

            current_evaluated = None
            try:
              current_evaluated = ast.literal_eval(current.decode().split(" ")[1])
            except:
              pass

            if current_evaluated and current_evaluated < len(sources_evaluated):
                layout = sources_evaluated[current_evaluated][1].split("+")[0]

                # first run, would be unnecessary duplicated loading x11 keymap because X.org server notify all clients at start about Mapping and setxkbmap would trigger new second notify
                if gnome_current_layout == None:
                    gnome_current_layout = layout

                elif gnome_current_layout != layout:

                    try:
                        cmd = ['setxkbmap', layout, '-display', display_var]

                        log.debug(cmd)
                        subprocess.call(cmd)

                        gnome_current_layout = layout
                    except:
                        log.exception('setxkbmap set failed')

        sleep(1)


def is_device_enabled(device_name):
    global gsettings_failure_count, gsettings_max_failure_count, getting_device_via_xinput_status_failure_count, getting_device_via_xinput_status_max_failure_count

    if gsettings_failure_count < gsettings_max_failure_count:
        value = gsettingsGetTouchpadSendEvents()
        if value:
            if 'enabled' in value:
                return True
            elif 'disabled' in value:
                return False

    if getting_device_via_xinput_status_failure_count > getting_device_via_xinput_status_max_failure_count:
        log.debug('Getting Device Enabled via xinput failed more then: \"%s\" so is not try anymore, returned Touchpad enabled', getting_device_via_xinput_status_max_failure_count)
        return True

    try:
        cmd = ['xinput', '--list-props', device_name]
        propData = subprocess.check_output(cmd)
        propData = propData.decode()

        for line in propData.splitlines():
            if 'Device Enabled' in line:
                line = line.strip()
                if line[-1] == '1':
                    return True
                else:
                    return False

        log.error('Getting Device Enabled via xinput failed because was not found Device Enabled for Touchpad.')

        getting_device_via_xinput_status_failure_count += 1
        return True
    except:
        getting_device_via_xinput_status_failure_count += 1

        log.exception('Getting Device Enabled via xinput failed')
        return True

# Sleep for a bit so udev, libinput, Xorg, Wayland, ... all have had
# a chance to see the device and initialize it. Otherwise the event
# will be sent by the kernel but nothing is ready to listen to the
# device yet
udev = dev.create_uinput_device()
sleep(1)


def use_bindings_for_touchpad_left_icon_slide_function():
    global udev, top_left_icon_slide_func_keys

    key_events = []
    for custom_key in top_left_icon_slide_func_keys:
        key_events.append(InputEvent(custom_key, 1))
        key_events.append(InputEvent(EV_SYN.SYN_REPORT, 0))
        key_events.append(InputEvent(custom_key, 0))
        key_events.append(InputEvent(EV_SYN.SYN_REPORT, 0))

    try:
        udev.send_events(key_events)
        log.info("Used bindings for touchpad left_icon slide function")
    except OSError as e:
        log.error("Cannot send event, %s", e)


def is_pressed_touchpad_top_right_icon():
    global top_right_icon_width, top_right_icon_height, abs_mt_slot_x_values, abs_mt_slot_y_values, abs_mt_slot_value, maxx

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


def reset_mt_slot(index):
    abs_mt_slot_numpad_key[index] = None
    abs_mt_slot_x_init_values[index] = -1
    abs_mt_slot_x_values[index] = -1
    abs_mt_slot_y_init_values[index] = -1
    abs_mt_slot_y_values[index] = -1


def set_none_to_current_mt_slot():
    global abs_mt_slot_value

    reset_mt_slot(abs_mt_slot_value)


def set_none_to_all_mt_slots():
    global abs_mt_slot_numpad_key,\
        abs_mt_slot_x_values, abs_mt_slot_y_values

    abs_mt_slot_numpad_key[:] = None
    abs_mt_slot_x_init_values[:] = -1
    abs_mt_slot_x_values[:] = -1
    abs_mt_slot_y_init_values[:] = -1
    abs_mt_slot_y_values[:] = -1


def pressed_touchpad_top_left_icon(e):
    global top_left_icon_touch_start_time, abs_mt_slot_numpad_key, abs_mt_slot_value

    if e.value == 1:
        top_left_icon_touch_start_time = time()
        log.info("Touched top_left_icon area in time: %s", time())
        abs_mt_slot_numpad_key[abs_mt_slot_value] = EV_KEY_TOP_LEFT_ICON
    else:
        top_left_icon_touch_start_time = 0
        log.info("Un-touched top_left_icon area in time: %s", time())
        set_none_to_current_mt_slot()


# rotating in cycle - overflow means start from first brightness again
def increase_brightness():
    global brightness, backlight_levels, config

    if (brightness + 1) >= len(backlight_levels):
        brightness = 0
    else:
        brightness += 1

    log.info("Increased brightness of backlight to")
    log.info(brightness)

    config_set(CONFIG_LAST_BRIGHTNESS, backlight_levels[brightness])

    send_value_to_touchpad_via_i2c(backlight_levels[brightness])


def send_numlock_key(value):
    global udev

    numlock_key = get_evdev_key_for_char('Num_Lock')

    events = [
        InputEvent(EV_MSC.MSC_SCAN, 70053),
        InputEvent(numlock_key, value),
        InputEvent(EV_SYN.SYN_REPORT, 0)
    ]

    try:
        udev.send_events(events)
    except OSError as e:
        log.error("Cannot send event, %s", e)


def grab_current_slot():
    global d_t

    try:
        log.info("grab current slot")
        d_t.grab()
        abs_mt_slot_grab_status[abs_mt_slot_value] = 1

    except device.DeviceGrabError as e:
        log.error("Error of grabbing, %s", e)


def set_touchpad_prop_tap_to_click(value):
    global touchpad_name, gsettings_failure_count, gsettings_max_failure_count, getting_device_via_xinput_status_failure_count, getting_device_via_xinput_status_max_failure_count, getting_device_via_synclient_status_failure_count, getting_device_via_synclient_status_max_failure_count

    # 1. priority - gsettings
    if gsettings_failure_count < gsettings_max_failure_count:
        gsettingsSetTouchpadTapToClick(value)
        # why is return commented? and is always run also xinput below? Because on KDE is allowed set up without any error but nothing happens
        # return

    # 2. priority - xinput
    if getting_device_via_xinput_status_failure_count > getting_device_via_xinput_status_max_failure_count:
        log.debug('Setting libinput Tapping EnabledDevice via xinput failed more then: \"%s\" times so is not try anymore', getting_device_via_xinput_status_max_failure_count)
    else:
        try:
            cmd = ["xinput", "set-prop", touchpad_name, 'libinput Tapping Enabled', str(value)]
            log.debug(cmd)
            subprocess.call(cmd)
            return
        except:
            getting_device_via_xinput_status_failure_count+=1
            log.error('Setting libinput Tapping EnabledDevice via xinput failed')

    # 3. priority - synclient
    if getting_device_via_synclient_status_failure_count > getting_device_via_synclient_status_max_failure_count:
        log.debug('Setting libinput Tapping EnabledDevice via xinput failed more then: \"%s\" times so is not try anymore', getting_device_via_xinput_status_max_failure_count)
    try:
        cmd = ["synclient", "TapButton1=" + str(value)]
        log.debug(cmd)
        subprocess.call(cmd)
        return
    except:
        getting_device_via_synclient_status_failure_count+=1


def grab():
    global d_t

    try:
        log.info("grab")
        d_t.grab()

    except device.DeviceGrabError as e:
        log.error("Error of grabbing, %s", e)


def cancel_idle_numpad():
    global brightness, backlight_levels

    # set up previous brightness
    try:
      brightness_value = backlight_levels[brightness]
      send_value_to_touchpad_via_i2c(brightness_value)
    # may be not found! That means the driver was clearly installed and
    # config file does not contains `brightness` key - because was not used increment
    # or decrement function yet or even model does not support this functionality
    # or config log was deleted
    except:
      send_value_to_touchpad_via_i2c("0x01")
      pass

    config_set(CONFIG_IDLED, False)

    log.info("Cancelled numpad idle")


def idle_numpad():
    global brightness, idle_brightness, idle, backlight_levels

    # step is: CONFIG_IDLE_BRIGHTNESS_DEFAULT / (100 / 8 = 12.5) =
    if len(backlight_levels):
      idle_brightness_level_index = int(idle_brightness / (100 / len(backlight_levels)))

      # because index of array starts with zero
      if idle_brightness_level_index > 0:
        send_value_to_touchpad_via_i2c(backlight_levels[idle_brightness_level_index - 1])
      else:
        send_value_to_touchpad_via_i2c("0x00")
    else:
      # brightness function is not supported then temporary disable entire brightness by `0x00`
      send_value_to_touchpad_via_i2c("0x00")

    config_set(CONFIG_IDLED, True)


def activate_numpad():
    global brightness, default_backlight_level, enabled_touchpad_pointer, top_left_icon_brightness_func_disabled

    if enabled_touchpad_pointer == 0 or enabled_touchpad_pointer == 2:
        grab()
    elif enabled_touchpad_pointer == 3:
        set_touchpad_prop_tap_to_click(0)

    # https://github.com/asus-linux-drivers/asus-numberpad-driver/issues/132
    # both values are required to send for succesfull activation (brightness up)
    #
    # unlock NumberPad (toggle settings lock/unlock NumberPad inside MyAsus app on Windows)
    send_value_to_touchpad_via_i2c("0x60")
    # activate NumberPad
    send_value_to_touchpad_via_i2c("0x01")

    if default_backlight_level != "0x01" and not top_left_icon_brightness_func_disabled:
         send_value_to_touchpad_via_i2c(default_backlight_level)

    try:
        brightness = backlight_levels.index(default_backlight_level)
    except ValueError:
        # so after start and then click on icon for increasing brightness
        # will be used first indexed value in given array with index 0 (0 = -1 + 1)
        # (if exists)
        # TODO: atm do not care what last value is now displayed and which one (nearest higher) should be next (default 0x01 means turn leds on with last used level of brightness)
        brightness = -1

    config_set(CONFIG_ENABLED, True)


def deactivate_numpad():
    global brightness, enabled_touchpad_pointer

    if enabled_touchpad_pointer == 0 or enabled_touchpad_pointer == 2:
        ungrab()
    elif enabled_touchpad_pointer == 1:
        ungrab_current_slot()
    elif enabled_touchpad_pointer == 3:
        set_touchpad_prop_tap_to_click(1)

    # inactivation can be doubled with another value 0x61 - that means lock NumberPad (toggle settings lock/unlock NumberPad inside MyAsus app on Windows)
    # https://github.com/asus-linux-drivers/asus-numberpad-driver/issues/132
    send_value_to_touchpad_via_i2c("0x00")
    brightness = 0

    config_set(CONFIG_ENABLED, False)


def get_system_numlock():
    global keyboard

    if not keyboard:
        return None

    with open('/dev/input/event' + str(keyboard), 'rb') as fd_k:
        d_k = Device(fd_k)
        state = d_k.value[EV_LED.LED_NUML]
        d_k = None

        return bool(state)


def local_numlock_pressed():
    global brightness, numlock

    #log.debug("local_numlock_pressed: numlock_lock.acquire will be called")
    numlock_lock.acquire()
    #log.debug("local_numlock_pressed: numlock_lock.acquire called succesfully")

    is_touchpad_enabled = is_device_enabled(touchpad_name)
    if not ((not touchpad_disables_numpad and not is_touchpad_enabled) or is_touchpad_enabled):
        return

    sys_numlock = get_system_numlock()

    set_none_to_current_mt_slot()

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

    numlock_lock.release()


def read_config_file():
    global config, config_file_path

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
    global top_left_icon_slide_func_activation_x_ratio
    global top_left_icon_slide_func_activation_y_ratio
    global top_right_icon_slide_func_activation_x_ratio
    global top_right_icon_slide_func_activation_y_ratio
    global numlock
    global default_backlight_level
    global top_left_icon_brightness_func_disabled
    global support_for_maximum_abs_mt_slots
    global config_lock
    global enabled_touchpad_pointer
    global press_key_when_is_done_untouch
    global distance_to_move_only_pointer
    global idle_brightness
    global idle_enabled
    global idle_time

    #log.debug("load_all_config_values: config_lock.acquire will be called")
    config_lock.acquire()
    #log.debug("load_all_config_values: config_lock.acquire called succesfully")

    read_config_file()

    numpad_disables_sys_numlock = config_get(CONFIG_NUMPAD_DISABLES_SYS_NUMLOCK, CONFIG_NUMPAD_DISABLES_SYS_NUMLOCK_DEFAULT)
    disable_due_inactivity_time = float(config_get(CONFIG_DISABLE_DUE_INACTIVITY_TIME, CONFIG_DISABLE_DUE_INACTIVITY_TIME_DEFAULT))
    touchpad_disables_numpad = config_get(CONFIG_TOUCHPAD_DISABLES_NUMPAD, CONFIG_TOUCHPAD_DISABLES_NUMPAD_DEFAULT)
    key_repetitions = config_get(CONFIG_KEY_REPETITIONS, CONFIG_KEY_REPETITIONS_DEFAULT)
    multitouch = config_get(CONFIG_MULTITOUCH, CONFIG_MULTITOUCH_DEFAULT)
    one_touch_key_rotation = config_get(CONFIG_ONE_TOUCH_KEY_ROTATION, CONFIG_ONE_TOUCH_KEY_ROTATION_DEFAULT)
    activation_time = float(config_get(CONFIG_ACTIVATION_TIME, CONFIG_ACTIVATION_TIME_DEFAULT))
    sys_numlock_enables_numpad = config_get(CONFIG_NUMLOCK_ENABLES_NUMPAD, CONFIG_NUMLOCK_ENABLES_NUMPAD_DEFAULT)

    key_numlock_is_used = any(get_evdev_key_for_char('Num_Lock') in x for x in keys)
    if (not top_right_icon_height > 0 or not top_right_icon_width > 0) and not key_numlock_is_used:
        sys_numlock_enables_numpad_new = True
        if sys_numlock_enables_numpad is not sys_numlock_enables_numpad_new:
            config_set(CONFIG_NUMLOCK_ENABLES_NUMPAD, sys_numlock_enables_numpad_new, True, True)

    top_left_icon_activation_time = float(config_get(CONFIG_LEFT_ICON_ACTIVATION_TIME, CONFIG_LEFT_ICON_ACTIVATION_TIME_DEFAULT))
    top_left_icon_slide_func_activation_x_ratio = float(config_get(CONFIG_TOP_LEFT_ICON_SLIDE_FUNC_ACTIVATION_X_RATIO, CONFIG_TOP_LEFT_ICON_SLIDE_FUNC_ACTIVATION_X_RATIO_DEFAULT))
    top_left_icon_slide_func_activation_y_ratio = float(config_get(CONFIG_TOP_LEFT_ICON_SLIDE_FUNC_ACTIVATION_Y_RATIO, CONFIG_TOP_LEFT_ICON_SLIDE_FUNC_ACTIVATION_Y_RATIO_DEFAULT))
    top_right_icon_slide_func_activation_x_ratio = float(config_get(CONFIG_TOP_RIGHT_ICON_SLIDE_FUNC_ACTIVATION_X_RATIO, CONFIG_TOP_RIGHT_ICON_SLIDE_FUNC_ACTIVATION_X_RATIO_DEFAULT))
    top_right_icon_slide_func_activation_y_ratio = float(config_get(CONFIG_TOP_RIGHT_ICON_SLIDE_FUNC_ACTIVATION_Y_RATIO, CONFIG_TOP_RIGHT_ICON_SLIDE_FUNC_ACTIVATION_Y_RATIO_DEFAULT))
    enabled_touchpad_pointer = int(config_get(CONFIG_ENABLED_TOUCHPAD_POINTER, CONFIG_ENABLED_TOUCHPAD_POINTER_DEFAULT))
    press_key_when_is_done_untouch = int(config_get(CONFIG_PRESS_KEY_WHEN_IS_DONE_UNTOUCH, CONFIG_PRESS_KEY_WHEN_IS_DONE_UNTOUCH_DEFAULT))
    enabled = config_get(CONFIG_ENABLED, CONFIG_ENABLED_DEFAULT)

    default_backlight_level = config_get(CONFIG_DEFAULT_BACKLIGHT_LEVEL, CONFIG_DEFAULT_BACKLIGHT_LEVEL_DEFAULT)
    if default_backlight_level == "0x01":
        try:
            default_backlight_level = config.get(CONFIG_SECTION, CONFIG_LAST_BRIGHTNESS)
        except:
            # idle functionality needs (if possible) to set up previous state of brightness and because I do not know at this moment how to read current brightness,
            # we know only how to set up that so is necessary set default value to config if does not exist (and brightness levels are supported!!)
            #
            if len(backlight_levels) > 0:
              config_set(CONFIG_LAST_BRIGHTNESS, backlight_levels[len(backlight_levels) - 1], True, True)

    top_left_icon_brightness_func_disabled = config_get(CONFIG_TOP_LEFT_ICON_BRIGHTNESS_FUNC_DISABLED, CONFIG_TOP_LEFT_ICON_BRIGHTNESS_FUNC_DISABLED_DEFAULT)
    if not backlight_levels or not top_left_icon_height or not top_left_icon_width:
        top_left_icon_brightness_func_disabled_new = True
        if top_left_icon_brightness_func_disabled is not top_left_icon_brightness_func_disabled_new:
            config_set(CONFIG_TOP_LEFT_ICON_BRIGHTNESS_FUNC_DISABLED, top_left_icon_brightness_func_disabled_new, True, True)

    if multitouch:
        support_for_maximum_abs_mt_slots = 5
    else:
        support_for_maximum_abs_mt_slots = 1

    distance_to_move_only_pointer = float(config_get(CONFIG_DISTANCE_TO_MOVE_ONLY_POINTER, CONFIG_DISTANCE_TO_MOVE_ONLY_POINTER_DEFAULT))

    idled = config_get(CONFIG_IDLED, CONFIG_IDLED_DEFAULT)
    idle_brightness = float(config_get(CONFIG_IDLE_BRIGHTNESS, CONFIG_IDLE_BRIGHTNESS_DEFAULT))
    idle_enabled = config_get(CONFIG_IDLE_ENABLED, CONFIG_IDLE_ENABLED_DEFAULT)
    idle_time = int(config_get(CONFIG_IDLE_TIME, CONFIG_IDLE_TIME_DEFAULT))

    config_lock.release()

    if enabled is not numlock:
        local_numlock_pressed()


abs_mt_slot_value: int = 0
# -1 inactive, > 0 active
abs_mt_slot = np.array([-1, -1, -1, -1, -1], int)
abs_mt_slot_numpad_key = np.array([None, None, None, None, None], dtype=const.EventCode)
abs_mt_slot_x_init_values = np.array([-1, -1, -1, -1, -1], int)
abs_mt_slot_x_values = np.array([-1, -1, -1, -1, -1], int)
abs_mt_slot_y_init_values = np.array([-1, -1, -1, -1, -1], int)
abs_mt_slot_y_values = np.array([-1, -1, -1, -1, -1], int)
abs_mt_slot_grab_status = np.array([-1, -1, -1, -1, -1], int)
# equal to multi finger maximum
support_for_maximum_abs_mt_slots: int = 1
unsupported_abs_mt_slot: bool = False
numlock_touch_start_time = 0
top_left_icon_touch_start_time = 0
top_right_icon_touch_start_time = 0
last_event_time = 0
key_pointer_button_is_touched = None

def set_tracking_id(value):
    try:

        if value > 0:
            log.debug("Started new slot")
            # not know yet
            # log.info(abs_mt_slot_numpad_key[abs_mt_slot_value])
        else:
            log.debug("Ended existing slot")
            # can be misunderstanding when is touched padding (is printed previous key)
            # log.info(abs_mt_slot_numpad_key[abs_mt_slot_value])

        abs_mt_slot[abs_mt_slot_value] = value
    except IndexError as e:
        log.error(e)


def get_compose_key_end_events_for_unicode_string():

    space_key = get_evdev_key_for_char('space')

    space_pressed = InputEvent(space_key, 1)
    space_unpressed = InputEvent(space_key, 0)

    events = [
        InputEvent(EV_MSC.MSC_SCAN, space_pressed.code.value),
        space_pressed,
        InputEvent(EV_SYN.SYN_REPORT, 0),
        InputEvent(EV_MSC.MSC_SCAN, space_unpressed.code.value),
        space_unpressed,
        InputEvent(EV_SYN.SYN_REPORT, 0)
    ]

    return events


def get_events_for_unicode_char(hex_digits):

    key_events = []

    for hex_digit in hex_digits.lower():

        key = get_evdev_key_for_char(hex_digit)

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
    global udev, abs_mt_slot_numpad_key, abs_mt_slot_value

    log.info("Pressed numpad key")
    log.info(abs_mt_slot_numpad_key[abs_mt_slot_value])

    events = []

    if isEventList(abs_mt_slot_numpad_key[abs_mt_slot_value]):

        for event in abs_mt_slot_numpad_key[abs_mt_slot_value]:
            events.append(InputEvent(event, 1))
            events.append(InputEvent(EV_SYN.SYN_REPORT, 0))

        try:
          if enabled_touchpad_pointer == 1:
            grab_current_slot()

          udev.send_events(events)
        except OSError as e:
          log.warning("Cannot send press event, %s", e)

    elif isEvent(abs_mt_slot_numpad_key[abs_mt_slot_value]):
        events = [
            InputEvent(abs_mt_slot_numpad_key[abs_mt_slot_value], 1),
            InputEvent(EV_SYN.SYN_REPORT, 0)
        ]

        try:
          if enabled_touchpad_pointer == 1:
            grab_current_slot()

          udev.send_events(events)
        except OSError as e:
          log.warning("Cannot send press event, %s", e)
    else:
        field_value = abs_mt_slot_numpad_key[abs_mt_slot_value]
        keysym = xkb.keysym_from_name(field_value)

        if keysym != 0:
          unicode_char_hex_digits = hex(keysym)[2:]
          log.debug(unicode_char_hex_digits)
          events = events + get_events_for_unicode_char(unicode_char_hex_digits)

          try:
            if enabled_touchpad_pointer == 1:
              grab_current_slot()

            udev.send_events(events)
          except OSError as e:
            log.warning("Cannot send press event, %s", e)

        else:
          for unicode_char in field_value:
            unicode_char_hex_digits = '%X' % ord(unicode_char)
            events = get_events_for_unicode_char(unicode_char_hex_digits)

            try:
              if enabled_touchpad_pointer == 1:
                grab_current_slot()
              udev.send_events(events)
            except OSError as e:
              log.warning("Cannot send press event, %s", e)


def replaced_numpad_key(touched_key_now):
    if press_key_when_is_done_untouch == 1:
        pressed_numpad_key()
        unpressed_numpad_key(touched_key_now)
    else:
        unpressed_numpad_key(touched_key_now)

    pressed_numpad_key()


def ungrab():
    global d_t

    try:
        log.info("un-grab")
        d_t.ungrab()

    except device.DeviceGrabError as e:
        log.error("Error of un-grabbing, %s", e)


def ungrab_current_slot():
    global d_t, abs_mt_slot_grab_status, abs_mt_slot_value

    if not multitouch:
        is_grabbed = abs_mt_slot_grab_status[abs_mt_slot_value]
        if is_grabbed:
            abs_mt_slot_grab_status[abs_mt_slot_value] = 0

            try:
                log.info("un-grab current slot")
                d_t.ungrab()
            except device.DeviceGrabError as e:
                log.error("Error of un-grabbing current slot during pressed key, %s", e)


def unpressed_numpad_key(replaced_by_key=None):
    global udev

    log.info("Unpressed numpad key")
    log.info(abs_mt_slot_numpad_key[abs_mt_slot_value])

    events = []

    if isEventList(abs_mt_slot_numpad_key[abs_mt_slot_value]):

        for event in abs_mt_slot_numpad_key[abs_mt_slot_value]:
            events.append(InputEvent(event, 0))
            events.append(InputEvent(EV_SYN.SYN_REPORT, 0))

    elif isEvent(abs_mt_slot_numpad_key[abs_mt_slot_value]):

        events = [
            InputEvent(abs_mt_slot_numpad_key[abs_mt_slot_value], 0),
            InputEvent(EV_SYN.SYN_REPORT, 0)
        ]

    if events:
        try:
            udev.send_events(events)
        except OSError as e:
            log.warning("Cannot send press event, %s", e)

    if replaced_by_key:
        abs_mt_slot_numpad_key[abs_mt_slot_value] = replaced_by_key
    else:
        set_none_to_current_mt_slot()

        if enabled_touchpad_pointer == 1:
            ungrab_current_slot()


def get_evdev_key_for_numpad_layout_key(numpad_layout_key):
    global keysym_name_associated_to_evdev_key_reflecting_current_layout

    if isEvent(numpad_layout_key) or isEventList(numpad_layout_key):
        return numpad_layout_key
    elif numpad_layout_key in keysym_name_associated_to_evdev_key_reflecting_current_layout:
        if get_evdev_key_for_char(numpad_layout_key):
            return get_evdev_key_for_char(numpad_layout_key)
        # else will be sent via unicode shortcut
        else:
            return numpad_layout_key


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

        return get_evdev_key_for_numpad_layout_key(keys[row][col])

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
    elif touched_key_when_pressed == get_evdev_key_for_char('Num_Lock'):
        pass
    elif numlock:
        if touched_key_now != touched_key_when_pressed:

            if one_touch_key_rotation and touched_key_when_pressed != None and touched_key_now != None:
                replaced_numpad_key(touched_key_now)

            elif touched_key_when_pressed != None:

                if press_key_when_is_done_untouch == 0:
                    unpressed_numpad_key()
                else:
                    # mark key as none when is one_touch_key_rotation
                    # not allowed and are crossed init key borders so end of pointer moving will end with
                    # written number or character
                    abs_mt_slot_numpad_key[abs_mt_slot_value] = None

            elif one_touch_key_rotation and touched_key_now != None:
                abs_mt_slot_numpad_key[abs_mt_slot_value] = touched_key_now

                if press_key_when_is_done_untouch == 0:
                    pressed_numpad_key()


def check_system_numlock_vs_local():
    global brightness, numlock

    #log.debug("check_system_numlock_vs_local: numlock_lock.acquire will be called")
    numlock_lock.acquire()
    #log.debug("check_system_numlock_vs_local: numlock_lock.acquire called succesfully")

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
        log.info("Touched numlock key (not top_right_icon) in time: %s", time())
        abs_mt_slot_numpad_key[abs_mt_slot_value] = get_evdev_key_for_char('Num_Lock')
    else:
        numlock_touch_start_time = 0

        set_none_to_current_mt_slot()

        log.info("Un-touched numlock key (not top_right_icon) in time: %s", time())


def pressed_touchpad_top_right_icon(value):
    global top_right_icon_touch_start_time, numlock_touch_start_time, abs_mt_slot_numpad_key

    if value == 1:
        log.info("Touched top_right_icon area (numlock) in time: %s", time())

        # is used for slide (that is why duplicated location for saving time())
        top_right_icon_touch_start_time = time()
        numlock_touch_start_time = time()

        abs_mt_slot_numpad_key[abs_mt_slot_value] = get_evdev_key_for_char('Num_Lock')
    else:
        top_right_icon_touch_start_time = 0
        numlock_touch_start_time = 0

        set_none_to_current_mt_slot()

        log.info("Un-touched top_right_icon area (representing numlock key) in time: %s", time())


def is_slided_from_top_right_icon(e):
    global top_right_icon_touch_start_time, abs_mt_slot_numpad_key, abs_mt_slot_x_values, abs_mt_slot_y_values, numlock_touch_start_time, maxx, maxy

    if top_right_icon_touch_start_time == 0:
        return

    activation_threshold_x = maxx - top_right_icon_slide_func_activation_x_ratio * maxx
    activation_threshold_y = top_right_icon_slide_func_activation_y_ratio * maxy

    if abs_mt_slot_numpad_key[abs_mt_slot_value] == get_evdev_key_for_char('Num_Lock') and\
        abs_mt_slot_x_values[abs_mt_slot_value] < maxx - top_right_icon_slide_func_activation_x_ratio * maxx and\
        abs_mt_slot_y_values[abs_mt_slot_value] > maxy - top_right_icon_slide_func_activation_y_ratio * maxy:

        log.info("Slide from top_right_icon exceeded the activation threshold for x and y.")
        log.info("Activation x %.2f (top left corner is 0; required < %.2f / %.2f)", abs_mt_slot_x_values[abs_mt_slot_value], activation_threshold_x, maxx)
        log.info("Activation y %.2f (top left corner is 0; required > %.2f / %.2f)", abs_mt_slot_y_values[abs_mt_slot_value], activation_threshold_y, maxy)

        top_right_icon_touch_start_time = 0
        numlock_touch_start_time = 0
        set_none_to_current_mt_slot()

        return True
    else:
        return False


def is_slided_from_top_left_icon(e):
    global top_left_icon_touch_start_time, abs_mt_slot_numpad_key, abs_mt_slot_x_values, abs_mt_slot_y_values

    if top_left_icon_touch_start_time == 0:
        return

    activation_threshold_x = top_left_icon_slide_func_activation_x_ratio * maxx
    activation_threshold_y = top_left_icon_slide_func_activation_y_ratio * maxy

    if abs_mt_slot_numpad_key[abs_mt_slot_value] == EV_KEY_TOP_LEFT_ICON and\
        abs_mt_slot_x_values[abs_mt_slot_value] > activation_threshold_x and\
        abs_mt_slot_y_values[abs_mt_slot_value] > activation_threshold_y:

        log.info("Slide from top_left_icon exceeded the activation threshold for x and y.")
        log.info("Activation x %.2f (top left corner is 0; required > %.2f / %.2f)", abs_mt_slot_x_values[abs_mt_slot_value], activation_threshold_x, maxx)
        log.info("Activation y %.2f (top left corner is 0; required > %.2f / %.2f)", abs_mt_slot_y_values[abs_mt_slot_value], activation_threshold_y, maxy)

        top_left_icon_touch_start_time = 0
        set_none_to_current_mt_slot()

        return True
    else:
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
    global activation_time, numlock_touch_start_time, top_right_icon_touch_start_time

    if numlock_touch_start_time == 0:
        return

    press_duration = time() - numlock_touch_start_time

    if (abs_mt_slot_numpad_key[abs_mt_slot_value] == get_evdev_key_for_char('Num_Lock') and\
        press_duration > activation_time):

        log.info("The numpad numlock was pressed longer than the activation time and will be activated: %s",
                 time() - numlock_touch_start_time)
        log.info("Activation time: %s", activation_time)

        numlock_touch_start_time = 0
        top_right_icon_touch_start_time = 0

        return True
    else:
        return False


def stop_top_left_right_icon_slide_gestures():
    global top_left_icon_touch_start_time, top_right_icon_touch_start_time

    top_left_icon_touch_start_time = 0
    top_right_icon_touch_start_time = 0


def pressed_pointer_button(key, msc, value):
    global udev

    events = [
        InputEvent(EV_MSC.MSC_SCAN, msc),
        InputEvent(key, value),
        InputEvent(EV_SYN.SYN_REPORT, 0)
    ]

    try:
        udev.send_events(events)
    except OSError as e:
        log.error("Cannot send event, %s", e)

    if value == 1:
        abs_mt_slot_numpad_key[abs_mt_slot_value] = key
    else:
        abs_mt_slot_numpad_key[abs_mt_slot_value] = None


def is_key_pointer_button(key):
    return key == EV_KEY.BTN_LEFT or key == EV_KEY.BTN_RIGHT or key == EV_KEY.BTN_MIDDLE


def current_position_is_more_distant_than_distance_to_move_only_pointer():
    global abs_mt_slot_value, abs_mt_slot_x_values, abs_mt_slot_y_values, abs_mt_slot_x_init_values, abs_mt_slot_y_init_values, distance_to_move_only_pointer

    if abs_mt_slot_x_values[abs_mt_slot_value] == -1 or \
        abs_mt_slot_y_values[abs_mt_slot_value] == -1 or \
        abs_mt_slot_x_init_values[abs_mt_slot_value] == -1 or \
        abs_mt_slot_y_init_values[abs_mt_slot_value] == -1:

        return False

    distance = math.dist([
        abs_mt_slot_x_init_values[abs_mt_slot_value], abs_mt_slot_y_init_values[abs_mt_slot_value]
    ],
    [
        abs_mt_slot_x_values[abs_mt_slot_value], abs_mt_slot_y_values[abs_mt_slot_value]
    ])

    if distance > distance_to_move_only_pointer:
        return True
    else:
        return False


def listen_touchpad_events():
    global brightness, d_t, abs_mt_slot_value, abs_mt_slot, abs_mt_slot_numpad_key,\
        abs_mt_slot_x_values, abs_mt_slot_y_values, support_for_maximum_abs_mt_slots,\
        unsupported_abs_mt_slot, numlock_touch_start_time, touchpad_name, last_event_time,\
        keys_ignore_offset, enabled_touchpad_pointer, abs_mt_slot_x_init_values, abs_mt_slot_y_init_values,\
        key_pointer_button_is_touched, is_idled, minx_numpad, miny_numpad, col_width, row_height, maxy_numpad, maxx_numpad

    for e in d_t.events():

        last_event_time = time()

        if is_idled:
          is_idled = False
          cancel_idle_numpad()

        current_slot_x = abs_mt_slot_x_values[abs_mt_slot_value]
        current_slot_y = abs_mt_slot_y_values[abs_mt_slot_value]

        current_slot_key = abs_mt_slot_numpad_key[abs_mt_slot_value]


        # POINTER_BUTTON own handling instead of touchpad driver starts
        #
        # can not be excluded situation
        # when is send number or character together
        # with POINTER_BUTTON because can be send in slot firstly!
        #
        # for each EV_KEY.BTN_LEFT, EV_KEY.BTN_RIGHT, EV_KEY.BTN_MIDDLE
        # if is send always only BTN_LEFT
        # supply touchpad driver role and divides by position between LEFT, MIDDLE, RIGHT
        #
        # enabled_touchpad_pointer value 0 is filtered out here
        if is_key_pointer_button(e.code) and enabled_touchpad_pointer == 0:
            continue

        # protection against situations when is clicked pointer button (LEFT, RIGHT, MIDDLE) and in config is set up send key when is released finger
        # then this code cancel sending all key events unless is finger released
        if is_key_pointer_button(e.code) and press_key_when_is_done_untouch == 1:

            if e.value == 0:
                log.debug("Released touchpad pointer button")
                key_pointer_button_is_touched = False
                set_none_to_all_mt_slots()

                if enabled_touchpad_pointer == 1:
                    ungrab_current_slot()

                continue
            else:
                log.debug("Pressed touchpad pointer button")
                key_pointer_button_is_touched = True

        # enabled_touchpad_pointer value 2 only! is processed
        if numlock and enabled_touchpad_pointer == 2:
            if e.matches(EV_KEY.BTN_LEFT):
                if(current_slot_x <= (maxx / 100) * 35):
                    pressed_pointer_button(EV_KEY.BTN_LEFT, 272, e.value)
                elif(current_slot_x > (maxx / 100) * 35 and current_slot_x < (maxx / 100) * 65):
                    pressed_pointer_button(EV_KEY.BTN_MIDDLE, 274, e.value)
                else:
                    pressed_pointer_button(EV_KEY.BTN_RIGHT, 273, e.value)

            if is_key_pointer_button(current_slot_key):
            #    #log.info("skipping because current slot is pointer button")
                continue
        # enabled_touchpad_pointer value 1 only! is processed futher
        # POINTER_BUTTON own handling instead of touchpad driver ends


        if key_pointer_button_is_touched:
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

            if not multitouch:

                # protection against multitouching when is multitouch not enable: when is used another finger on activated NumberPad and multitouch is not enabled (is allowed only 1 finger), slot is reseted
                set_none_to_current_mt_slot()

            continue

        if e.matches(EV_MSC.MSC_TIMESTAMP):

            # top right icon (numlock) activation
            touched_key = get_touched_key()
            top_right_icon = is_pressed_touchpad_top_right_icon()
            if (top_right_icon or touched_key == get_evdev_key_for_char('Num_Lock')) and takes_numlock_longer_then_set_up_activation_time():

              local_numlock_pressed()
              continue

            # top left icon (brightness change) activation
            if numlock and is_pressed_touchpad_top_left_icon() and\
                takes_top_left_icon_touch_longer_then_set_up_activation_time() and\
                not top_left_icon_brightness_func_disabled:

                increase_brightness()
                continue

        if e.matches(EV_ABS.ABS_MT_POSITION_X):
            abs_mt_slot_x_values[abs_mt_slot_value] = e.value
            if distance_to_move_only_pointer and \
                top_right_icon_touch_start_time == 0 and \
                top_left_icon_touch_start_time == 0:

                if abs_mt_slot_x_init_values[abs_mt_slot_value] == -1:
                    abs_mt_slot_x_init_values[abs_mt_slot_value] = e.value
                if abs_mt_slot_numpad_key[abs_mt_slot_value] is not None and \
                    current_position_is_more_distant_than_distance_to_move_only_pointer():

                    set_none_to_current_mt_slot()

                    # current slot was cleaned, useless continue and call is_not_finger_moved_to_another_key()
                    continue

            is_not_finger_moved_to_another_key()

            if numlock and is_slided_from_top_left_icon(e):
                use_bindings_for_touchpad_left_icon_slide_function()
                continue
            elif is_slided_from_top_right_icon(e):
                local_numlock_pressed()
                continue

        if e.matches(EV_ABS.ABS_MT_POSITION_Y):
            abs_mt_slot_y_values[abs_mt_slot_value] = e.value
            if distance_to_move_only_pointer and \
                top_right_icon_touch_start_time == 0 and \
                top_left_icon_touch_start_time == 0:

                if abs_mt_slot_y_init_values[abs_mt_slot_value] == -1:
                    abs_mt_slot_y_init_values[abs_mt_slot_value] = e.value
                if abs_mt_slot_numpad_key[abs_mt_slot_value] is not None and \
                    current_position_is_more_distant_than_distance_to_move_only_pointer():

                    set_none_to_current_mt_slot()

                    # current slot was cleaned, useless continue and call is_not_finger_moved_to_another_key()
                    continue

            is_not_finger_moved_to_another_key()

            if is_slided_from_top_right_icon(e):
                local_numlock_pressed()
                continue

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
            elif numlock and is_pressed_touchpad_top_left_icon():
                pressed_touchpad_top_left_icon(e)
                continue

            col = math.floor(
                (current_slot_x - minx_numpad) / col_width)
            row = math.floor(
                (current_slot_y - miny_numpad) / row_height)

            if([max(row, 0), max(col, 0)] in keys_ignore_offset):
                row = max(row, 0)
                col = max(col, 0)
            elif (
                    current_slot_x > minx_numpad and
                    current_slot_x < maxx_numpad and
                    current_slot_y > miny_numpad and
                    current_slot_y < maxy_numpad
                ):
                if (row < 0 or col < 0):
                    continue
            else:
                # offset area
                continue

            if abs_mt_slot_numpad_key[abs_mt_slot_value] == None and e.value == 0:
                log.debug('key unpress was already handled because slot is empty')
                continue

            try:

                key_layout = keys[row][col]
                key = get_evdev_key_for_numpad_layout_key(key_layout)

                # Numpad is not activated
                if not numlock and key != get_evdev_key_for_char('Num_Lock'):
                    continue

                if key is None:
                    continue

                if key == get_evdev_key_for_char('Num_Lock'):
                    pressed_numlock_key(e.value)
                    continue
                else:
                    abs_mt_slot_numpad_key[abs_mt_slot_value] = key

            except IndexError:
                log.error('Unhandled col/row %d/%d for position %d-%d',
                          col,
                          row,
                          current_slot_x,
                          current_slot_y
                          )
                continue

            if e.value == 1 and press_key_when_is_done_untouch == 0:
                if key_repetitions:
                    pressed_numpad_key()
                else:
                    pressed_numpad_key()
                    unpressed_numpad_key()
            elif e.value == 0 and press_key_when_is_done_untouch == 1:
                # key repetitions is not possible do in this case (press_key_when_is_done_untouch = 1)
                pressed_numpad_key()
                unpressed_numpad_key()
            elif e.value == 0 and press_key_when_is_done_untouch == 0:
                unpressed_numpad_key()


def check_touchpad_status():
    global touchpad_name, numlock, touchpad_disables_numpad

    #log.debug("check_touchpad_status: numlock_lock.acquire will be called")
    numlock_lock.acquire()
    #log.debug("check_touchpad_status: numlock_lock.acquire called succesfully")

    is_touchpad_enabled = is_device_enabled(touchpad_name)

    if not is_touchpad_enabled:
        numlock = False

        sys_numlock = get_system_numlock()
        if sys_numlock and numpad_disables_sys_numlock:
            send_numlock_key(1)
            send_numlock_key(0)
            log.info("System numlock deactivated")

        deactivate_numpad()
        log.info("Numpad deactivated")

    numlock_lock.release()


def check_system_numlock_status():
    global stop_threads

    while not stop_threads:
        check_system_numlock_vs_local()
        sleep(0.5)


def check_touchpad_status_endless_cycle():
    global getting_device_via_xinput_status_failure_count, getting_device_via_xinput_status_max_failure_count, stop_threads

    while not stop_threads and getting_device_via_xinput_status_failure_count < getting_device_via_xinput_status_max_failure_count:
        if touchpad_disables_numpad and numlock:
            check_touchpad_status()
        sleep(0.5)

    if not stop_threads:
        log.info('Getting Device Enabled via xinput disabled because failed more then: \"%s\" times in row', getting_device_via_xinput_status_failure_count)


def check_numpad_automatical_disable_or_idle_due_inactivity():
    global is_idled, disable_due_inactivity_time, numpad_disables_sys_numlock, last_event_time, numlock, stop_threads, idled, idle_time, idle_enabled

    while not stop_threads:

        #log.debug("check_numpad_automatical_disable_or_idle_due_inactivity: numlock_lock.acquire will be called")
        numlock_lock.acquire()
        #log.debug("check_numpad_automatical_disable_or_idle_due_inactivity: numlock_lock.acquire called succesfully")

        #log.debug("check_numpad_automatical_disable_or_idle_due_inactivity: numlock_lock.acquire will be called")
        idle_lock.acquire()
        #log.debug("check_numpad_automatical_disable_or_idle_due_inactivity: numlock_lock.acquire called succesfully")

        if\
            numlock and\
            idle_enabled and\
            idle_time and\
            not is_idled and\
            last_event_time != 0 and\
            time() > idle_time + last_event_time:

            is_idled = True
            idle_numpad()
            log.info("Numpad idled")

        if\
            disable_due_inactivity_time and\
            numlock and\
            last_event_time != 0 and\
            time() > disable_due_inactivity_time + last_event_time:

            sys_numlock = get_system_numlock()
            if sys_numlock and numpad_disables_sys_numlock:
                send_numlock_key(1)
                send_numlock_key(0)
                log.info("System numlock deactivated")

            numlock = False
            deactivate_numpad()
            log.info("Numpad deactivated")

        numlock_lock.release()
        idle_lock.release()

        sleep(1)


def check_config_values_changes():
    global config_lock, stop_threads

    watch_manager = WatchManager()

    path = os.path.abspath(config_file_dir)
    mask = IN_CLOSE_WRITE | IN_IGNORED | IN_MOVED_TO
    watch_manager.add_watch(path, mask)

    event_notifier = AsyncNotifier(watch_manager)

    while not stop_threads:
        try:
            event_notifier.process_events()
            if event_notifier.check_events():
                event_notifier.read_events()

                if not config_lock.locked():
                    log.info("check_config_values_changes: detected external change of config file -> loading changes")
                    # because file might be read so fast that changes will not be there yet
                    sleep(0.1)
                    load_all_config_values()
                else:
                    log.info("check_config_values_changes: detected internal change of config file -> do nothing -> would be deadlock")

        except KeyboardInterrupt:
            break

    event_notifier.stop()
    watch_manager.del_watch(path)

    log.info("check_config_values_changes: inotify watching config file ended")


if xdg_session_type == "wayland":
  t = threading.Thread(target=load_keymap_listener_wayland)
  threads.append(t)
  t.start()

if xdg_session_type == "x11" and display:
  t = threading.Thread(target=load_keymap_listener_x11)
  threads.append(t)
  t.start()

# wait until is keymap loaded
while not keymap_loaded:
  pass

load_all_config_values()
config_lock.acquire()
config_save()
config_lock.release()
# because inotify (deadlock)
sleep(0.1)

# if keyboard with numlock indicator was found
# thread for listening change of system numlock
if keyboard:
    t = threading.Thread(target=check_system_numlock_status)
    threads.append(t)
    t.start()

# if disabling touchpad disables numpad aswell
if d_t and touchpad_name:
    t = threading.Thread(target=check_touchpad_status_endless_cycle)
    threads.append(t)
    t.start()

t = threading.Thread(target=check_numpad_automatical_disable_or_idle_due_inactivity)
threads.append(t)
t.start()

# check changes in config values
t = threading.Thread(target=check_config_values_changes)
threads.append(t)
t.start()

t = threading.Thread(target=check_gnome_layout)
threads.append(t)
t.start()

try:
    listen_touchpad_events()
except:
    logging.exception("Listening touchpad events unexpectedly failed")
finally:

    # try deactivate first
    numlock_lock.acquire()
    if numlock:
        sys_numlock = get_system_numlock()
        if sys_numlock and numpad_disables_sys_numlock:
            send_numlock_key(1)
            send_numlock_key(0)
            log.info("System numlock deactivated")

        is_idled = False
        cancel_idle_numpad()
        log.info("Cancelled idle")

        numlock = False
        deactivate_numpad()
        log.info("Numpad deactivated")
    numlock_lock.release()

    # then clean up
    stop_threads=True
    fd_t.close()

    if display_wayland:
        display_wayland.disconnect()

    if display:
        display.close()

    for thread in threads:
        thread.join()

    sys.exit(1)