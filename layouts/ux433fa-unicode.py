from libevdev import EV_KEY

top_right_icon_width = 200
top_right_icon_height = 250

top_left_icon_width = 200
top_left_icon_height = 200

top_offset = 80
right_offset = 40
left_offset = 40
bottom_offset = 80

keys = [
    ["equal", "percent", EV_KEY.KEY_BACKSPACE, EV_KEY.KEY_BACKSPACE],
    ["7", "8", "9", "slash"],
    ["4", "5", "6", "asterisk"],
    ["1", "2", "3", "mminus"],
    ["0", "period", EV_KEY.KEY_KPENTER, "plus"]
]