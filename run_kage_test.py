# run_kage_test.py
import time
import sys
from src.kage import Kage
from src.kage.lua_binding import KageLuaEngine


def main():
    try:
        print("Initializing test environment...")
        kage = Kage()
        engine = KageLuaEngine(kage)

        # Luaスクリプトのロード
        engine.loadScript('scripts/tests/kage_test.lua')

        # initがあれば実行
        if 'init' in engine.lua.globals():
            engine.lua.globals().init()

        # メインループ (30 FPS)
        frame_time = 1.0 / 30.0
        last_time = time.time()

        try:
            while True:
                current_time = time.time()
                delta = current_time - last_time

                if delta >= frame_time:
                    # updateの実行
                    print("Globals:", engine.lua.globals())
                    if 'update' in engine.lua.globals():
                        print("Calling update function...")
                        try:
                            engine.lua.globals().update()
                        except Exception as e:
                            print(f"Error in update: {e}")
                    last_time = current_time

        except KeyboardInterrupt:
            print("\nTest terminated by user")

    except Exception as e:
        exception_type, exception_object, exception_traceback = sys.exc_info()
        filename = exception_traceback.tb_frame.f_code.co_filename
        line_no = exception_traceback.tb_lineno
        print(f"Test error: {filename} : {line_no} :: {e}")


if __name__ == "__main__":
    main()
