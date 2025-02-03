# src/koto/lua_binding.py

from lupa import LuaRuntime


class KotoLuaEngine:
    def __init__(self, koto_instance):
        self.koto = koto_instance
        self.lua = LuaRuntime(unpack_returned_tuples=True)
        self._setup_api()

    def _setup_api(self):
        """Koto APIのセットアップ"""
        g = self.lua.globals()

        koto_api = {
            "getState": self.koto.get_state,
            "start": self.koto.start,
            "stop": self.koto.stop,
        }

        g.koto = koto_api
