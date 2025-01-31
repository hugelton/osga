# scripts/system/splash.py
import time


class Splash:
    def __init__(self, kage):
        self.kage = kage

    def show(self):
        try:
            # 画面を黒でクリア
            self.kage.clear(0)  # インデックス0=黒

            # 白丸を画面中央から拡大して表示
            self.kage.set_color(1)  # インデックス1=白
            for radius in range(0, 101, 5):
                self.kage.clear(0)
                self.kage.fill_circle(160, 120, radius)

            # テキストを左端からスクロールして表示
            self.kage.set_font_size(3)
            self.kage.set_color(0)  # 黒
            for x in range(-100, 101, 5):
                self.kage.clear(0)
                self.kage.set_color(1)  # 白
                self.kage.fill_circle(160, 120, 100)
                self.kage.set_color(0)  # 黒
                self.kage.draw_text(160 + x, 100, "osga")

            time.sleep(0.5)

            self.kage.clear(0)
            self.kage.set_color(1)
            self.kage.fill_circle(160, 120, 100)

            for radius in range(100, 241, 5):
                self.kage.clear(0)
                self.kage.fill_circle(160, 120, radius)

        except Exception as e:
            print(f"Error in Splash: {e}")
