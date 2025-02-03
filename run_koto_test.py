# run_koto_test.py
import time
import sys
from src.kage import Kage
from src.kage.lua_binding import KageLuaEngine
from src.koto import KotoRotary
from src.koto.lua_binding import KotoLuaEngine
from lupa import LuaRuntime


def main():
    try:
        print("Initializing test environment...")
        # 共有のLua実行環境を作成
        lua = LuaRuntime(unpack_returned_tuples=True)

        # Kageの初期化
        kage = Kage()
        koto = KotoRotary()

        # APIをLuaに登録
        g = lua.globals()

        # Kage API
        kage_api = {
            "clear": kage.clear,
            "setRGB": kage.setRGB,
            "drawCircle": kage.drawCircle,
            "fillCircle": kage.fillCircle,
            "drawText": kage.drawText,
            "setFontSize": kage.setFontSize,
            "drawFPS": kage.drawFPS,
            "sendBuffer": kage.sendBuffer,
        }
        g.kage = kage_api

        # Koto API
        koto_api = {
            "getState": koto.get_state,
            "start": koto.start,
            "stop": koto.stop,
        }
        g.koto = koto_api

        # Luaスクリプトのロード
        with open("scripts/tests/koto_test.lua", "r") as f:
            lua.execute(f.read())

        # 初期化
        if "init" in g:
            g.init()

        # メインループ
        try:
            while True:
                if "update" in g:
                    g.update()
                time.sleep(0.03)  # ≈30 FPS

        except KeyboardInterrupt:
            print("\nTest terminated by user")
            if "cleanup" in g:
                g.cleanup()

    except Exception as e:
        print(f"Test error: {e}")
        import traceback

        traceback.print_exc()


if __name__ == "__main__":
    main()
