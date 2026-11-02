import pathlib
import re
import unittest

from lupa import LuaRuntime


SOURCE = pathlib.Path(__file__).parents[1].joinpath("BuyEmAll.lua").read_text()
HANDLER = re.search(
    r"local function eventHandler\(self, event, \.\.\.\).*?\nend",
    SOURCE,
    re.DOTALL,
)


class ConfirmSettingTests(unittest.TestCase):
    def test_addon_loaded_preserves_saved_setting(self):
        self.assertIsNotNone(HANDLER, "could not find Lua ADDON_LOADED handler")
        lua = LuaRuntime()
        lua.execute(HANDLER.group(0).replace("local function eventHandler", "function eventHandler", 1))
        handler = lua.eval("eventHandler")

        for saved, expected in ((False, False), (0, False), (True, True), (None, True)):
            with self.subTest(saved=saved):
                lua.globals().BEAConfirmToggle = saved
                handler(None, "ADDON_LOADED", "BuyEmAll")
                self.assertIs(lua.globals().BEAConfirmToggle, expected)


if __name__ == "__main__":
    unittest.main()
