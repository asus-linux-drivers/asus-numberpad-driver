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
    ["7", "8", "9", "/", EV_KEY.KEY_BACKSPACE],
    ["4", "5", "6", "*", EV_KEY.KEY_BACKSPACE],
    ["1", "2", "3", "-", "%"],
    ["0", ".", EV_KEY.KEY_KPENTER, "+", "="]
]