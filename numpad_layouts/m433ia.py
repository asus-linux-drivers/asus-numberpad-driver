from libevdev import EV_KEY

# Number of tries to identify the interface number
try_times = 10
try_sleep = 0.1

cols = 5
rows = 4
top_offset = 0.3

# Including off (first value of array) and full brightness (last value of array)
backlight_levels = [
    "0x00",
    "0x01"
]
# Testing array on device with no levels of backglight
#backlight_levels = [
#    "0x00",
#    "0x01",
#    "0x00",
#    "0x01",
#    "0x00"
#]

keys = [
    [EV_KEY.KEY_KP7, EV_KEY.KEY_KP8, EV_KEY.KEY_KP9, EV_KEY.KEY_KPSLASH, EV_KEY.KEY_BACKSPACE],
    [EV_KEY.KEY_KP4, EV_KEY.KEY_KP5, EV_KEY.KEY_KP6, EV_KEY.KEY_KPASTERISK, EV_KEY.KEY_BACKSPACE],
    [EV_KEY.KEY_KP1, EV_KEY.KEY_KP2, EV_KEY.KEY_KP3, EV_KEY.KEY_KPMINUS, EV_KEY.KEY_5],
    [EV_KEY.KEY_KP0, EV_KEY.KEY_KPDOT, EV_KEY.KEY_KPENTER, EV_KEY.KEY_KPPLUS, EV_KEY.KEY_KPEQUAL]
]
