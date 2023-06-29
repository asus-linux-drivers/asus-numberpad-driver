from libevdev import EV_KEY

top_left_icon_width = 250
top_left_icon_height = 250

top_right_icon_width = 1000
top_right_icon_height = 600

top_offset = 80
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
    ["7", "8", "9",
        "/"],
    ["4", "5", "6",
        "*", EV_KEY.KEY_BACKSPACE],
    ["1", "2", "3",
        "-", EV_KEY.KEY_KPENTER],
    ["0", "0", ".",
        "+", EV_KEY.KEY_KPENTER]
]