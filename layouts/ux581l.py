from libevdev import EV_KEY

top_left_icon_width = 200
top_left_icon_height = 200

top_right_icon_width = 200
top_right_icon_height = 200

top_offset = 200
right_offset = 80
left_offset = 80
bottom_offset = 80

# please create an issue in case values does not work
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
    ["equal", "percent", EV_KEY.KEY_BACKSPACE, EV_KEY.KEY_BACKSPACE],
    ["7", "8", "9", "slash"],
    ["4", "5", "6", "asterisk"],
    ["1", "2", "3", "mminus"],
    ["0", "period", EV_KEY.KEY_KPENTER, "plus"]
]