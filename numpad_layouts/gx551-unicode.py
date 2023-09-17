from libevdev import EV_KEY

left_offset = 20
right_offset = 20

keys = [
    [EV_KEY.KEY_NUMLOCK, "/", "*", "-"],
    ["7", "8", "9", "+"],
    ["4", "5", "6", "+"],
    ["1", "2", "3", EV_KEY.KEY_KPENTER],
    ["0", "0", ".", EV_KEY.KEY_KPENTER]
]

keys_ignore_offset = [
    [0, 0]
]