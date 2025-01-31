import cairo
import time
import numpy as np


class CairoTest:
    def __init__(self):
        self.width = 320
        self.height = 240
        self.surface = cairo.ImageSurface(
            cairo.FORMAT_RGB24, self.width, self.height)
        self.ctx = cairo.Context(self.surface)

        try:
            self.fb = open('/dev/fb0', 'wb')
        except Exception as e:
            print(f"Failed to open framebuffer: {e}")
            return

    def send_to_fb(self):
        """RGB24 (32bit) のデータをフレームバッファに送る"""
        self.fb.seek(0)
        self.fb.write(self.surface.get_data())
        self.fb.flush()
        time.sleep(0.03)  # 30fps 制限

    def splash_animation(self):
        """円とスクロールするテキスト"""
        # 黒背景
        self.ctx.set_source_rgb(0, 0, 0)
        self.ctx.paint()
        self.send_to_fb()

        # 白い円のアニメーション
        for radius in range(0, 101, 5):
            self.ctx.set_source_rgb(0, 0, 0)
            self.ctx.paint()

            self.ctx.set_source_rgb(1, 1, 1)
            self.ctx.arc(160, 120, radius, 0, 2 * np.pi)
            self.ctx.fill()

            self.send_to_fb()

        # テキストを左からスクロール
        self.ctx.select_font_face("DejaVu Sans")
        self.ctx.set_font_size(40)

        for x in range(-160, 1, 5):  # -160 から 0 へ移動
            self.ctx.set_source_rgb(0, 0, 0)
            self.ctx.paint()

            self.ctx.set_source_rgb(1, 1, 1)
            self.ctx.arc(160, 120, 100, 0, 2 * np.pi)
            self.ctx.fill()

            self.ctx.set_source_rgb(0, 0, 0)
            self.ctx.move_to(160 + x, 130)  # テキストの位置調整
            self.ctx.show_text("osga")

            self.send_to_fb()

    def __del__(self):
        if hasattr(self, 'fb'):
            self.fb.close()


if __name__ == "__main__":
    test = CairoTest()
    test.splash_animation()
