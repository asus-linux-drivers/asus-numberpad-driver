from libevdev import EV_KEY

top_left_icon_width = 200
top_left_icon_height = 200

top_right_icon_width = 200
top_right_icon_height = 200

top_offset = 200
right_offset = 80
left_offset = 80
bottom_offset = 80

backlight_levels = [
    "0x41",
    "0x42",
    "0x43",
    "0x44",
    "0x45",
    "0x46",
    "0x47",
    "0x48"
]

keys = [
    [EV_KEY.KEY_KPEQUAL, "%", EV_KEY.KEY_BACKSPACE, EV_KEY.KEY_BACKSPACE],
    [EV_KEY.KEY_KP7, EV_KEY.KEY_KP8, EV_KEY.KEY_KP9, EV_KEY.KEY_KPSLASH],
    [EV_KEY.KEY_KP4, EV_KEY.KEY_KP5, EV_KEY.KEY_KP6, EV_KEY.KEY_KPASTERISK],
    [EV_KEY.KEY_KP1, EV_KEY.KEY_KP2, EV_KEY.KEY_KP3, EV_KEY.KEY_KPMINUS],
    [EV_KEY.KEY_KP0, EV_KEY.KEY_KPDOT, EV_KEY.KEY_KPENTER, EV_KEY.KEY_KPPLUS]
]