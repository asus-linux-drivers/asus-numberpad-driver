from libevdev import EV_KEY

top_left_icon_width = 250
top_left_icon_height = 250

top_right_icon_width = 250
top_right_icon_height = 250

top_offset = 200
right_offset = 200
left_offset = 200
bottom_offset = 80

# please create an issue in case values does not work
backlight_levels = [
    "0x2f",
    "0x2e",
    "0x2d",
    "0x2c",
    "0x2b",
    "0x2a",
    "0x29",
    "0x28",
    "0x27",
    "0x26",
    "0x25",
    "0x24",
    "0x23",
    "0x22",
    "0x21",
    "0x20"
]

keys = [
    [EV_KEY.KEY_KP7, EV_KEY.KEY_KP8, EV_KEY.KEY_KP9, EV_KEY.KEY_KPSLASH, EV_KEY.KEY_BACKSPACE],
    [EV_KEY.KEY_KP4, EV_KEY.KEY_KP5, EV_KEY.KEY_KP6, EV_KEY.KEY_KPASTERISK, EV_KEY.KEY_BACKSPACE],
    [EV_KEY.KEY_KP1, EV_KEY.KEY_KP2, EV_KEY.KEY_KP3, EV_KEY.KEY_KPMINUS, [EV_KEY.KEY_LEFTSHIFT, EV_KEY.KEY_KP5]],
    [EV_KEY.KEY_KP0, EV_KEY.KEY_KPDOT, EV_KEY.KEY_KPENTER, EV_KEY.KEY_KPPLUS, EV_KEY.KEY_KPEQUAL]
]