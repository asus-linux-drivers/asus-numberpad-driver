from libevdev import EV_KEY

top_offset = 80
right_offset = 0
left_offset = 0
bottom_offset = 0

keys = [
    ["#", "/", "*", "-"],
    ["7", "8", "9", "+"],
    ["4", "5", "6", "+"],
    ["1", "2", "3", EV_KEY.KEY_KPENTER],
    ["0", "0", ".", EV_KEY.KEY_KPENTER]
]