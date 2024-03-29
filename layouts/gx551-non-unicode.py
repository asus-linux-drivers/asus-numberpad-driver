from libevdev import EV_KEY

left_offset = 20
right_offset = 20

keys = [
    [EV_KEY.KEY_NUMLOCK, EV_KEY.KEY_KPSLASH, EV_KEY.KEY_KPASTERISK, EV_KEY.KEY_KPMINUS],
    [EV_KEY.KEY_KP7, EV_KEY.KEY_KP8, EV_KEY.KEY_KP9, EV_KEY.KEY_KPPLUS],
    [EV_KEY.KEY_KP4, EV_KEY.KEY_KP5, EV_KEY.KEY_KP6, EV_KEY.KEY_KPPLUS],
    [EV_KEY.KEY_KP1, EV_KEY.KEY_KP2, EV_KEY.KEY_KP3, EV_KEY.KEY_KPENTER],
    [EV_KEY.KEY_KP0, EV_KEY.KEY_KP0, EV_KEY.KEY_KPDOT, EV_KEY.KEY_KPENTER]
]

keys_ignore_offset = [
    [0, 0]
]