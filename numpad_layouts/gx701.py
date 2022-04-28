from libevdev import EV_KEY

# Number of tries to identify the interface number
try_times = 5
try_sleep = 0.1

cols = 4
rows = 5
# Subtract 0.3 (a third key) as the UX581L has about a third key space at the top
top_offset = 0

keys = [
    [EV_KEY.KEY_CALC, EV_KEY.KEY_KPSLASH, EV_KEY.KEY_KPASTERISK, EV_KEY.KEY_KPMINUS],
    [EV_KEY.KEY_KP7, EV_KEY.KEY_KP8, EV_KEY.KEY_KP9, EV_KEY.KEY_KPPLUS],
    [EV_KEY.KEY_KP4, EV_KEY.KEY_KP5, EV_KEY.KEY_KP6, EV_KEY.KEY_KPPLUS],
    [EV_KEY.KEY_KP1, EV_KEY.KEY_KP2, EV_KEY.KEY_KP3, EV_KEY.KEY_KPENTER],
    [EV_KEY.KEY_KP0, EV_KEY.KEY_KP0, EV_KEY.KEY_KPDOT, EV_KEY.KEY_KPENTER]
]
