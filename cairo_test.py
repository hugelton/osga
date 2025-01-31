# cairo_test.py
import cairo
import time
import numpy as np


class CairoTest:
    def __init__(self):
        self.width = 320
        self.height = 240
        # RGB16_565フォーマットではなく、RGB24で作成（変換が必要）
        self.surface = cairo.ImageSurface(cairo.FORMAT_RGB24,
                                          self.width, self.height)
        self.ctx = cairo.Context(self.surface)

        try:
            self.fb = open('/dev/fb1', 'wb')
        except Exception as e:
            print(f"Failed to open framebuffer: {e}")
            return

    def _convert_to_rgb565(self):
        # RGB24からデータを取得
        buf = self.surface.get_data()
        array = np.frombuffer(buf, dtype=np.uint8).reshape(
            self.height, self.width, 4)

        # RGB565に変換
        r = (array[:, :, 2] & 0xF8) << 8
        g = (array[:, :, 1] & 0xFC) << 3
        b = array[:, :, 0] >> 3
        rgb565 = r | g | b

        # バイトオーダー調整
        return rgb565.astype(np.uint16).tobytes()

    def send_to_fb(self):
        data = self._convert_to_rgb565()
        self.fb.seek(0)
        self.fb.write(data)
        self.fb.flush()

    def splash_animation(self):
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
            time.sleep(0.01)

        # テキストアニメーション
        self.ctx.select_font_face("DejaVu Sans")
        self.ctx.set_font_size(40)

        for x in range(-100, 101, 5):
            self.ctx.set_source_rgb(0, 0, 0)
            self.ctx.paint()

            self.ctx.set_source_rgb(1, 1, 1)
            self.ctx.arc(160, 120, 100, 0, 2 * np.pi)
            self.ctx.fill()

            self.ctx.set_source_rgb(0, 0, 0)
            self.ctx.move_to(160 + x, 120)
            self.ctx.show_text("osga")

            self.send_to_fb()
            time.sleep(0.01)

    def __del__(self):
        if hasattr(self, 'fb'):
            self.fb.close()


if __name__ == "__main__":
    test = CairoTest()
    test.splash_animation()
