"""Fault-inject overruns without opening devices or connecting to a display.

Run: python -m unittest discover -s tests -p 'test_input_recovery.py' -v
The AST loader avoids the daemon's setup at module import.
"""
import ast
from collections import defaultdict
import math
from pathlib import Path
import unittest
from unittest.mock import Mock, patch

import numpy as np
from libevdev import EV_ABS, EV_KEY, EV_MSC, EV_SYN, InputEvent, device

SOURCE = Path(__file__).resolve().parents[1] / "numberpad.py"
TREE = ast.parse(SOURCE.read_text())
FUNCTIONS = {node.name: node for node in TREE.body if isinstance(node, ast.FunctionDef)}
DROP = object()
ARRAYS = ("abs_mt_slot", "abs_mt_slot_x_init_values", "abs_mt_slot_x_values",
          "abs_mt_slot_x_previous_values", "abs_mt_slot_y_init_values",
          "abs_mt_slot_y_values", "abs_mt_slot_y_previous_values")
TIMERS = ("numlock_touch_start_time", "top_left_icon_touch_start_time",
          "top_right_icon_touch_start_time")


def load(ns, *names):
    for name in names:
        exec(compile(ast.Module([FUNCTIONS[name]], type_ignores=[]), str(SOURCE), "exec"), ns)


def ev(code, value=0):
    return InputEvent(code, value)


class FakeInput:
    """Update cached state while events and sync events are consumed."""

    def __init__(self, ns, batches, sync_states=(), sync_events=()):
        self.ns = ns
        self.batches = iter(batches)
        self.sync_states = iter(sync_states)
        self.sync_events = sync_events
        self.sync_count = 0
        self.value = defaultdict(lambda: None, {EV_KEY.BTN_TOUCH: 0, EV_KEY.BTN_TOOL_FINGER: 0})
        self.current_slot = 0
        self.num_slots = 5
        self.slots = [{EV_ABS.ABS_MT_TRACKING_ID: -1} for _ in range(5)]
        self.grab = Mock()
        self.ungrab = Mock()

    def apply(self, event):
        self.value[event.code] = event.value
        if event.matches(EV_ABS.ABS_MT_SLOT):
            self.current_slot = event.value
        elif event.matches(EV_ABS.ABS_MT_TRACKING_ID):
            self.slots[self.current_slot][event.code] = event.value

    def events(self):
        for event in next(self.batches, ()):
            if event is DROP:
                yield ev(EV_SYN.SYN_DROPPED)
                raise device.EventsDroppedException()
            if callable(event):
                event(self)
            else:
                self.apply(event)
                yield event
        self.ns["stop_threads"] = True

    def sync(self):
        self.sync_count += 1
        for event in self.sync_events:
            self.apply(event)
            yield event
        for code, value in next(self.sync_states, {}).items():
            self.apply(ev(code, value))


def namespace(touchpad=False):
    ns = dict(stop_threads=False, device=device, EV_SYN=EV_SYN, EV_KEY=EV_KEY,
              EV_ABS=EV_ABS, EV_MSC=EV_MSC, InputEvent=InputEvent,
              dev=Mock(), udev=Mock(), log=Mock())
    load(ns, "iter_input_events")
    if not touchpad:
        return ns
    ns.update(abs_mt_slot_value=0, support_for_maximum_abs_mt_slots=5,
              unsupported_abs_mt_slot=False, key_pointer_button_is_touched=False,
              enabled_touchpad_pointer=1, press_key_when_is_done_untouch=0,
              multitouch=False, is_idled=False, numlock=True, key_repetitions=True,
              distance_to_move_only_pointer=0, minx_numpad=0, miny_numpad=0,
              maxx_numpad=1000, maxy_numpad=1000, col_width=200, row_height=200,
              keys_ignore_offset=[], keys=[[EV_KEY.KEY_KP1]*5 for _ in range(5)],
              math=math, time=lambda: 10, sleep=lambda _: None,
              get_evdev_key_for_numpad_layout_key=lambda key: key,
              get_evdev_key_for_char=lambda key: EV_KEY.KEY_NUMLOCK,
              is_not_finger_moved_to_another_key=Mock(),
              get_touched_key=Mock(return_value=(EV_KEY.KEY_KP1, ["1"])),
              increase_brightness=Mock(), local_numlock_pressed=Mock(),
              use_bindings_for_touchpad_left_icon_slide_function=Mock())
    for name in ("is_slided_from_top_left_icon", "is_slided_from_top_right_icon",
                 "is_pressed_touchpad_top_right_icon", "is_pressed_touchpad_top_left_icon",
                 "takes_numlock_longer_then_set_up_activation_time"):
        ns[name] = Mock(return_value=False)
    ns.update({name: 0 for name in TIMERS})
    ns.update({name: np.full(5, -1, dtype=int) for name in ARRAYS})
    ns["abs_mt_slot_numpad_key"] = np.full(5, None, dtype=object)
    ns["abs_mt_slot_grab_status"] = np.zeros(5, dtype=int)
    load(ns, "touchpad_has_contacts", "reset_touchpad_state", "listen_touchpad_events",
         "isEvent", "isEventList", "is_key_pointer_button", "set_none_to_all_mt_slots",
         "reset_mt_slot", "set_none_to_current_mt_slot", "set_tracking_id",
         "pressed_numpad_key", "unpressed_numpad_key", "grab_current_slot",
         "ungrab_current_slot", "ungrab")
    return ns


def keys_sent(ns):
    return [(event.code, event.value) for call in ns["udev"].send_events.call_args_list
            for event in call.args[0] if event.type == EV_KEY]


def gesture():
    return [ev(EV_ABS.ABS_MT_SLOT), ev(EV_ABS.ABS_MT_TRACKING_ID, 42),
            ev(EV_ABS.ABS_MT_POSITION_X, 100), ev(EV_ABS.ABS_MT_POSITION_Y, 100),
            ev(EV_KEY.BTN_TOUCH, 1), ev(EV_KEY.BTN_TOOL_FINGER, 1), ev(EV_SYN.SYN_REPORT),
            ev(EV_ABS.ABS_MT_TRACKING_ID, -1), ev(EV_KEY.BTN_TOUCH),
            ev(EV_KEY.BTN_TOOL_FINGER), ev(EV_SYN.SYN_REPORT)]


class InputRecoveryTests(unittest.TestCase):
    def run_touchpad(self, ns, batches, **kwargs):
        ns["d_t"] = physical = FakeInput(ns, batches, **kwargs)
        ns["listen_touchpad_events"]()
        ns["log"].exception.assert_not_called()
        ns["dev"].sync.assert_not_called()
        return physical

    def assert_one_key(self, ns):
        self.assertEqual(keys_sent(ns), [(EV_KEY.KEY_KP1, 1), (EV_KEY.KEY_KP1, 0)])

    def test_only_one_shared_iterator(self):
        self.assertEqual(sum(isinstance(node, ast.FunctionDef) and node.name == "iter_input_events"
                             for node in TREE.body), 1)

    def test_many_overruns_sync_physical_device_without_recursion(self):
        ns = namespace()
        physical = FakeInput(ns, [[DROP]]*1500 + [[ev(EV_KEY.KEY_A, 1)]])
        events = list(ns["iter_input_events"](physical))
        self.assertEqual(physical.sync_count, 1500)
        self.assertEqual(len(events), 1501)
        self.assertTrue(all(event.matches(EV_SYN.SYN_DROPPED) for event in events[:-1]))
        self.assertTrue(events[-1].matches(EV_KEY.KEY_A))
        ns["dev"].sync.assert_not_called()

    def test_sync_events_are_not_replayed_as_shortcuts(self):
        ns = namespace()
        physical = FakeInput(ns, [[DROP], [ev(EV_KEY.KEY_A, 1)]],
                             sync_events=[ev(EV_KEY.KEY_NUMLOCK, 1), ev(EV_KEY.KEY_LEFTSHIFT)])
        events = list(ns["iter_input_events"](physical))
        self.assertEqual([(event.code, event.value) for event in events],
                         [(EV_SYN.SYN_DROPPED, 0), (EV_KEY.KEY_A, 1)])

    def test_keyboard_restores_modifiers_and_keeps_listening(self):
        ns = namespace()
        ns.update(keyboard="9", active_modifiers={EV_KEY.KEY_LEFTSHIFT},
                  coactivator_modifiers={EV_KEY.KEY_LEFTSHIFT, EV_KEY.KEY_LEFTALT})
        seen = []
        physical = FakeInput(ns, [[DROP], [lambda _: seen.append(set(ns["active_modifiers"])),
                                          ev(EV_KEY.KEY_LEFTALT), ev(EV_KEY.KEY_LEFTSHIFT, 1)]],
                             sync_states=[{EV_KEY.KEY_LEFTSHIFT: 0, EV_KEY.KEY_LEFTALT: 1}])
        ns["Device"] = lambda _: physical
        load(ns, "listen_keyboard_events")
        with patch("builtins.open", return_value=Mock()):
            ns["listen_keyboard_events"]()
        self.assertEqual(seen, [{EV_KEY.KEY_LEFTALT}])
        self.assertEqual(ns["active_modifiers"], {EV_KEY.KEY_LEFTSHIFT})
        self.assertEqual(physical.sync_count, 1)
        ns["dev"].sync.assert_not_called()
        ns["log"].error.assert_not_called()

    def test_ordinary_touchpad_gesture_still_types(self):
        for on_release in (0, 1):
            with self.subTest(on_release=on_release):
                ns = namespace(True)
                ns["press_key_when_is_done_untouch"] = on_release
                self.run_touchpad(ns, [gesture()])
                self.assert_one_key(ns)

    def test_overrun_releases_held_key_and_accepts_next_gesture(self):
        ns = namespace(True)
        physical = self.run_touchpad(ns, [gesture()[:7] + [DROP], gesture()[7:] + gesture()])
        self.assertEqual(keys_sent(ns), [(EV_KEY.KEY_KP1, 1), (EV_KEY.KEY_KP1, 0)]*2)
        self.assertEqual(physical.ungrab.call_count, 2)
        ns["local_numlock_pressed"].assert_not_called()
        ns["increase_brightness"].assert_not_called()

    def test_all_slots_keys_chords_coordinates_and_timers_are_cleared(self):
        ns = namespace(True)
        ns["abs_mt_slot_numpad_key"][:] = [EV_KEY.KEY_KP1,
            [EV_KEY.KEY_LEFTCTRL, EV_KEY.KEY_C], "EV_KEY_TOP_LEFT_ICON", "unicode", None]
        for name in ARRAYS:
            ns[name][:] = 123
        ns["abs_mt_slot_grab_status"][:] = [1, 1, 0, 0, 0]
        ns.update({name: 5 for name in TIMERS})
        ns.update(key_pointer_button_is_touched=True, unsupported_abs_mt_slot=True)
        physical = self.run_touchpad(ns, [[DROP], []])
        self.assertEqual(keys_sent(ns), [(EV_KEY.KEY_KP1, 0), (EV_KEY.KEY_C, 0),
                                        (EV_KEY.KEY_LEFTCTRL, 0)])
        self.assertTrue(all(key is None for key in ns["abs_mt_slot_numpad_key"]))
        for name in ARRAYS:
            self.assertEqual(list(ns[name]), [-1]*5, name)
        self.assertEqual(list(ns["abs_mt_slot_grab_status"]), [0]*5)
        for name in TIMERS:
            self.assertEqual(ns[name], 0, name)
        self.assertFalse(ns["key_pointer_button_is_touched"])
        self.assertFalse(ns["unsupported_abs_mt_slot"])
        physical.ungrab.assert_called_once()

    def test_pending_press_on_release_is_cancelled_without_typing(self):
        ns = namespace(True)
        ns["press_key_when_is_done_untouch"] = 1
        self.run_touchpad(ns, [gesture()[:7] + [DROP], gesture()[7:]])
        self.assertEqual(keys_sent(ns), [])
        self.assertTrue(all(key is None for key in ns["abs_mt_slot_numpad_key"]))

    def test_release_write_failure_still_clears_gestures_and_restores_pointer(self):
        ns = namespace(True)
        ns["abs_mt_slot_numpad_key"][0] = EV_KEY.KEY_KP1
        ns["abs_mt_slot_grab_status"][0] = 1
        ns["udev"].send_events.side_effect = OSError("device unavailable")
        physical = self.run_touchpad(ns, [[DROP], []])
        ns["log"].warning.assert_called_once()
        physical.ungrab.assert_called_once()
        self.assertTrue(all(key is None for key in ns["abs_mt_slot_numpad_key"]))

    def test_recovery_without_btn_touch_waits_for_final_tracking_id_release(self):
        ns = namespace(True)
        self.run_touchpad(ns, [[DROP],
            [ev(EV_ABS.ABS_MT_POSITION_X, 500), ev(EV_ABS.ABS_MT_POSITION_Y, 500),
             ev(EV_SYN.SYN_REPORT), ev(EV_ABS.ABS_MT_TRACKING_ID, -1),
             ev(EV_SYN.SYN_REPORT)] + gesture()],
            sync_states=[{EV_KEY.BTN_TOUCH: None, EV_KEY.BTN_TOOL_FINGER: 0,
                          EV_ABS.ABS_MT_TRACKING_ID: 0}])
        self.assert_one_key(ns)

    def test_pointer_modes_preserve_persistent_grabs_and_release_pointer_buttons(self):
        for mode in (0, 1, 2, 3):
            with self.subTest(mode=mode):
                ns = namespace(True)
                ns.update(enabled_touchpad_pointer=mode, press_key_when_is_done_untouch=1)
                ns["abs_mt_slot_numpad_key"][:] = [EV_KEY.BTN_LEFT, EV_KEY.KEY_KP1,
                    [EV_KEY.KEY_LEFTCTRL, EV_KEY.KEY_C], None, None]
                ns["abs_mt_slot_grab_status"][0] = 1
                physical = self.run_touchpad(ns, [[DROP], []])
                self.assertEqual(keys_sent(ns), [(EV_KEY.BTN_LEFT, 0)])
                self.assertEqual(physical.ungrab.call_count, int(mode == 1))

    def test_multifinger_recovery_waits_for_all_contacts_and_entire_release_frame(self):
        ns = namespace(True)
        self.run_touchpad(ns, [[DROP],
            [ev(EV_KEY.BTN_TOOL_FINGER), ev(EV_SYN.SYN_REPORT),
             ev(EV_ABS.ABS_MT_POSITION_X, 500), ev(EV_ABS.ABS_MT_POSITION_Y, 500),
             ev(EV_KEY.BTN_TOOL_DOUBLETAP), ev(EV_KEY.BTN_TOOL_FINGER, 1),
             ev(EV_MSC.MSC_TIMESTAMP, 500), ev(EV_KEY.BTN_TOUCH),
             ev(EV_KEY.BTN_TOOL_FINGER), ev(EV_SYN.SYN_REPORT)] + gesture()],
            sync_states=[{EV_KEY.BTN_TOUCH: 1, EV_KEY.BTN_TOOL_FINGER: 0,
                          EV_KEY.BTN_TOOL_DOUBLETAP: 1}])
        self.assert_one_key(ns)
        ns["local_numlock_pressed"].assert_not_called()
        ns["increase_brightness"].assert_not_called()

    def test_no_contacts_after_sync_accepts_next_gesture_immediately(self):
        ns = namespace(True)
        self.run_touchpad(ns, [[DROP], gesture()])
        self.assert_one_key(ns)

    def test_slot_selector_is_restored_after_sync_and_quarantined_release(self):
        for wait in (False, True):
            with self.subTest(wait=wait):
                ns = namespace(True)
                tail = [ev(EV_ABS.ABS_MT_SLOT, 3), ev(EV_KEY.BTN_TOUCH),
                        ev(EV_SYN.SYN_REPORT)] if wait else []
                # No new ABS_MT_SLOT for the next gesture.
                self.run_touchpad(ns, [[DROP], tail + gesture()[1:]],
                    sync_states=[{EV_ABS.ABS_MT_SLOT: 2, EV_KEY.BTN_TOUCH: int(wait)}])
                self.assertEqual(ns["abs_mt_slot_value"], 3 if wait else 2)
                self.assert_one_key(ns)

    def test_unsupported_slot_after_sync_is_ignored_until_supported_slot(self):
        ns = namespace(True)
        ns["support_for_maximum_abs_mt_slots"] = 1
        self.run_touchpad(ns, [[DROP], gesture()[1:] + gesture()],
                          sync_states=[{EV_ABS.ABS_MT_SLOT: 4}])
        self.assert_one_key(ns)

    def test_contact_detection_without_btn_touch_includes_tracking_id_zero(self):
        ns = namespace(True)
        ns["d_t"] = physical = FakeInput(ns, [])
        physical.value[EV_KEY.BTN_TOUCH] = None
        for code in (EV_KEY.BTN_TOOL_FINGER, EV_KEY.BTN_TOOL_DOUBLETAP,
                     EV_KEY.BTN_TOOL_TRIPLETAP, EV_KEY.BTN_TOOL_QUADTAP, EV_KEY.BTN_TOOL_QUINTTAP):
            physical.value[code] = 1
            self.assertTrue(ns["touchpad_has_contacts"]())
            physical.value[code] = 0
        physical.slots[4][EV_ABS.ABS_MT_TRACKING_ID] = 0
        self.assertTrue(ns["touchpad_has_contacts"]())
        physical.slots[4][EV_ABS.ABS_MT_TRACKING_ID] = -1
        self.assertFalse(ns["touchpad_has_contacts"]())
        physical.num_slots = None
        self.assertFalse(ns["touchpad_has_contacts"]())

    def test_repeated_overrun_while_waiting_does_not_type_or_recurse(self):
        ns = namespace(True)
        physical = self.run_touchpad(ns, [[DROP]]*1500 + [gesture()],
            sync_states=[{EV_KEY.BTN_TOUCH: 1}]*1499 + [{EV_KEY.BTN_TOUCH: 0}])
        self.assertEqual(physical.sync_count, 1500)
        self.assert_one_key(ns)


if __name__ == "__main__":
    unittest.main()
