from libevdev import EV_KEY

top_left_icon_width = 250
top_left_icon_height = 250

top_right_icon_width = 1000
top_right_icon_height = 600

top_offset = 200
right_offset = 200
left_offset = 200
bottom_offset = 80

keys = [
    ["7", "8", "9", "slash"],
    ["4", "5", "6", "asterisk", EV_KEY.KEY_BACKSPACE],
    ["1", "2", "3", "minus", EV_KEY.KEY_KPENTER],
    ["0", "0", "period", "plus", EV_KEY.KEY_KPENTER]
]