from libevdev import EV_KEY

top_right_icon_width = 600
top_right_icon_height = 300

top_offset = 320
right_offset = 80
left_offset = 80
bottom_offset = 200

# please create an issue in case values do not work
# https://github.com/asus-linux-drivers/asus-numberpad-driver/issues/308
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
    ["7", "8", "9", "slash", "BackSpace"],
    ["4", "5", "6", "asterisk", "BackSpace"],
    ["1", "2", "3", "minus", "Return"],
    ["0", "0", "period", "plus", "Return"]
]