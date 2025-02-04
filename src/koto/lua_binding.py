# src/koto/lua_binding.py
from lupa import LuaRuntime


class KotoLuaEngine:
    def __init__(self, koto_instance):
        self.koto = koto_instance
        self.lua = LuaRuntime(unpack_returned_tuples=True)
        self._setup_api()

    def _setup_api(self):
        """Setup Koto API for Lua environment"""
        g = self.lua.globals()

        # Basic print function
        g.print = print

        # Koto API table
        koto_api = {
            # Core functions
            "getState": self.koto.get_state,
            "start": self.koto.start,
            "stop": self.koto.stop,
            # Display control
            "setBacklight": self.koto.set_backlight,
            "getBacklight": self.koto.get_backlight,
            # Helper functions
            "isPressed": self._is_pressed,
            "isLongPressed": self._is_long_pressed,
            "getRotaryCount": self._get_rotary_count,
            "isRotaryPressed": self._is_rotary_pressed,
        }

        g.koto = koto_api

    # Helper methods for simpler Lua access
    def _is_pressed(self, button_name):
        """Check if a button is currently pressed"""
        state = self.koto.get_state()
        return state["buttons"].get(button_name, {}).get("pressed", False)

    def _is_long_pressed(self, button_name):
        """Check if a button is long pressed"""
        state = self.koto.get_state()
        return state["buttons"].get(button_name, {}).get("long_press", False)

    def _get_rotary_count(self):
        """Get rotary encoder count"""
        state = self.koto.get_state()
        return state["rotary"]["count"]

    def _is_rotary_pressed(self):
        """Check if rotary encoder button is pressed"""
        state = self.koto.get_state()
        return state["rotary"]["button"]

    def loadScript(self, script_path: str) -> bool:
        """Load and execute Lua script"""
        try:
            with open(script_path, "r") as f:
                script_content = f.read()
            self.lua.execute(script_content)
            return True
        except Exception as e:
            print(f"Error loading script: {e}")
            return False
