# src/kage/lua_binding.py
from lupa import LuaRuntime
from typing import Optional, Any
import os.path


class KageLuaEngine:
    def __init__(self, kage_instance):
        self.kage = kage_instance
        self.lua = LuaRuntime(unpack_returned_tuples=True)
        self._setup_api()

    def _setup_api(self):
        """Setup Kage API for Lua environment"""
        g = self.lua.globals()

        # Basic Lua functions
        g.print = print

        # Kage API table
        kage_api = {
            # Color management
            "setPalette": self.kage.setPalette,
            "setColor": self.kage.setColor,
            "setRGB": self.kage.setRGB,
            # Basic operations
            "clear": self.kage.clear,
            "sendBuffer": self.kage.sendBuffer,
            # Drawing operations
            "drawRect": self.kage.drawRect,
            "fillRect": self.kage.fillRect,
            "drawCircle": self.kage.drawCircle,
            "fillCircle": self.kage.fillCircle,
            "drawLine": self.kage.drawLine,
            "drawPolygon": self.kage.drawPolygon,
            "fillPolygon": self.kage.fillPolygon,
            # Text operations
            "setFontSize": self.kage.setFontSize,
            "drawText": self.kage.drawText,
            "getTextSize": self.kage.getTextSize,
            # Tools
            "drawFPS": self.kage.drawFPS,
        }

        g.kage = kage_api

    def loadScript(self, script_path: str) -> bool:
        """Load and execute Lua script"""
        try:
            if not os.path.exists(script_path):
                raise FileNotFoundError(f"Script not found: {script_path}")

            with open(script_path, "r") as f:
                script_content = f.read()

            self.lua.execute(script_content)
            return True

        except Exception as e:
            print(f"Error loading script: {e}")
            return False
