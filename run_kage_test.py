# run_kage_test.py
import time
import sys
from src.kage import Kage
from src.kage.lua_binding import KageLuaEngine
from collections import deque


class FPSCounter:
    def __init__(self, window_size=30):
        self.frame_times = deque(maxlen=window_size)
        self.last_time = time.time()

    def update(self):
        current_time = time.time()
        delta = current_time - self.last_time
        self.frame_times.append(delta)
        self.last_time = current_time

    def get_fps(self):
        if not self.frame_times:
            return 0
        return len(self.frame_times) / sum(self.frame_times)


def main():
    try:
        print("Initializing test environment...")
        kage = Kage()
        engine = KageLuaEngine(kage)
        fps_counter = FPSCounter()

        # 目標フレームレート: 30fps

        target_frame_time = 1.0 / 30.0
        next_frame_time = time.time() + target_frame_time

        # Luaスクリプトのロード
        engine.loadScript("scripts/tests/kage_test.lua")

        if "init" in engine.lua.globals():
            engine.lua.globals().init()

        try:
            while True:
                current_time = time.time()

                # フレーム時間の調整
                sleep_time = next_frame_time - current_time
                if sleep_time > 0:
                    # 短い間隔で複数回スリープ
                    while time.time() < next_frame_time:
                        time.sleep(0.001)  # 1ms単位での微調整

                # フレーム更新
                if "update" in engine.lua.globals():
                    engine.lua.globals().update()

                # FPS計算と表示
                fps_counter.update()
                if int(time.time()) % 1 == 0:
                    print(f"\rFPS: {fps_counter.get_fps():.1f}", end="", flush=True)

                # 次のフレーム時刻を設定
                next_frame_time += target_frame_time

                # フレーム落ちが大きい場合はリセット
                if time.time() > next_frame_time + target_frame_time * 2:
                    next_frame_time = time.time() + target_frame_time

        except KeyboardInterrupt:
            print("\nTest terminated by user")

    except Exception as e:
        print(f"Test error: {e}")


if __name__ == "__main__":
    main()
