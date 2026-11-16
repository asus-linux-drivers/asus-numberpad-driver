"""Test NumLock synchronization without starting the driver or opening devices.

Run: python -m unittest discover -s tests -p 'test_numlock_sync.py' -v
"""
import ast
from pathlib import Path
import threading
import unittest
from unittest.mock import Mock


SOURCE = Path(__file__).resolve().parents[1] / "numberpad.py"
FUNCTIONS = {node.name: node for node in ast.parse(SOURCE.read_text()).body
             if isinstance(node, ast.FunctionDef)}


def load(ns, *names):
    for name in names:
        exec(compile(ast.Module([FUNCTIONS[name]], type_ignores=[]),
                     str(SOURCE), "exec"), ns)


def driver(system_led, numlock=False, last_system_numlock=None, mode=1):
    state = {"led": system_led}
    ns = dict(numlock=numlock, last_system_numlock=last_system_numlock,
              sys_numlock_enables_numpad=mode, numpad_disables_sys_numlock=True,
              CONFIG_NUMLOCK_ENABLES_NUMPAD="sys_numlock_enables_numpad",
              coactivator_keys=[], touchpad_disables_numpad=False,
              touchpad_name="test touchpad", numlock_lock=threading.Lock(),
              get_system_numlock=lambda: state["led"],
              is_device_enabled=lambda _: True, are_modifier_keys_pressed=lambda _: True,
              send_numlock_key=Mock(), set_none_to_current_mt_slot=Mock(),
              activate_numpad=Mock(), deactivate_numpad=Mock(),
              config_set=Mock(), log=Mock())
    load(ns, "local_numlock_pressed", "check_system_numlock_vs_local",
         "check_touchpad_status")
    return ns, state


class NumlockSyncTests(unittest.TestCase):
    def test_local_off_ignores_unchanged_physical_led(self):
        ns, state = driver(True, numlock=True, last_system_numlock=True)
        ns["local_numlock_pressed"]()
        self.assertFalse(ns["numlock"])
        self.assertEqual(ns["send_numlock_key"].call_count, 2)
        for _ in range(3):
            ns["check_system_numlock_vs_local"]()
        self.assertFalse(ns["numlock"])
        ns["activate_numpad"].assert_not_called()
        state["led"] = False
        ns["check_system_numlock_vs_local"]()
        state["led"] = True
        ns["check_system_numlock_vs_local"]()
        self.assertTrue(ns["numlock"])
        ns["activate_numpad"].assert_called_once()

    def test_local_on_ignores_unchanged_physical_led(self):
        ns, state = driver(False, last_system_numlock=False)
        ns["local_numlock_pressed"]()
        ns["check_system_numlock_vs_local"]()
        self.assertTrue(ns["numlock"])
        ns["deactivate_numpad"].assert_not_called()
        state["led"] = True
        ns["check_system_numlock_vs_local"]()
        state["led"] = False
        ns["check_system_numlock_vs_local"]()
        self.assertFalse(ns["numlock"])
        ns["deactivate_numpad"].assert_called_once()

    def test_initial_led_still_activates_and_external_led_can_disable(self):
        ns, state = driver(True)
        ns["check_system_numlock_vs_local"]()
        self.assertTrue(ns["numlock"])
        state["led"] = False
        ns["check_system_numlock_vs_local"]()
        self.assertFalse(ns["numlock"])

    def test_disabled_system_numlock_does_not_activate(self):
        ns, state = driver(False, mode=0)
        ns["check_system_numlock_vs_local"]()
        state["led"] = True
        ns["check_system_numlock_vs_local"]()
        self.assertFalse(ns["numlock"])

    def test_external_keyboard_disconnect_mode_still_runs_without_led_edge(self):
        ns, _ = driver(False, last_system_numlock=False, mode=2)
        ns["check_system_numlock_vs_local"]()
        self.assertEqual(ns["sys_numlock_enables_numpad"], 1)
        ns["config_set"].assert_called_once()

    def test_touchpad_disable_does_not_reactivate_from_stale_led(self):
        ns, _ = driver(True, numlock=True, last_system_numlock=True)
        ns["is_device_enabled"] = lambda _: False
        ns["check_touchpad_status"]()
        ns["check_system_numlock_vs_local"]()
        self.assertFalse(ns["numlock"])
        ns["activate_numpad"].assert_not_called()


if __name__ == "__main__":
    unittest.main()
