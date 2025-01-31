from PIL import Image, ImageDraw, ImageFont
import math
import colorsys
import time


def measure_time(func):
    def wrapper(*args, **kwargs):
        start = time.time()
        result = func(*args, **kwargs)
        end = time.time()
        print(f"{func.__name__}: {(end - start) * 1000:.2f}ms")
        return result
    return wrapper


class Kage:
    def __init__(self):
        self.width = 320
        self.height = 240
        try:
            self.fb = open('/dev/fb0', 'wb')  # fb0に変更してテスト
        except Exception as e:
            print(f"Warning: Could not open framebuffer: {e}")

        self.buffer = Image.new('RGB', (self.width, self.height), 'black')
        self.draw = ImageDraw.Draw(self.buffer)
        self.current_color = 0
        self.current_rgb = None
        self.alpha = 1.0
        self.line_width = 1
        self.font_size = 2
        self.font_style = "normal"

        # カラーパレット
        self.colors = {
            0: (0, 0, 0),        # 黒
            1: (255, 255, 255),  # ベースカラー（白）
            2: (255, 107, 71)    # プライマリーカラー
        }

        # フォント関連
        self.font_sizes = {
            1: 8,    # 小
            2: 16,   # 標準
            3: 24    # 大
        }
        try:
            self.font = ImageFont.truetype("/usr/share/fonts/truetype/dejavu/DejaVuSans.ttf",
                                           self.font_sizes[self.font_size])
        except:
            self.font = ImageFont.load_default()

    @measure_time
    def get_current_color(self):
        if self.current_rgb:
            return self.current_rgb
        color = self.colors.get(self.current_color, (0, 0, 0))
        if self.alpha < 1.0:
            return (*color, int(255 * self.alpha))
        return color

    @measure_time
    def clear(self, color=0):
        self.buffer.paste(self.colors[color], (0, 0, self.width, self.height))
        self.send_buffer()

    @measure_time
    def set_color(self, c):
        self.current_color = c if c in self.colors else 0
        self.current_rgb = None

    @measure_time
    def set_color_rgb(self, r, g, b):
        self.current_rgb = (r, g, b)

    @measure_time
    def set_alpha(self, a):
        self.alpha = max(0.0, min(1.0, a))

    @measure_time
    def set_font_size(self, size):
        if size in self.font_sizes:
            self.font_size = size
            try:
                self.font = ImageFont.truetype("/usr/share/fonts/truetype/dejavu/DejaVuSans.ttf",
                                               self.font_sizes[self.font_size])
            except:
                self.font = ImageFont.load_default()

    @measure_time
    def set_font_style(self, style):
        self.font_style = style

    @measure_time
    def draw_pixel(self, x, y):
        self.draw.point((x, y), fill=self.get_current_color())
        self.send_buffer()

    @measure_time
    def draw_line(self, x1, y1, x2, y2, stroke=None):
        width = stroke if stroke is not None else self.line_width
        self.draw.line((x1, y1, x2, y2),
                       fill=self.get_current_color(),
                       width=width)
        self.send_buffer()

    @measure_time
    def _convert_rgb888_to_rgb565(self, data):
        rgb565_data = bytearray(len(data) // 3 * 2)
        for i in range(0, len(data), 3):
            r = data[i]
            g = data[i+1]
            b = data[i+2]
            rgb = ((r & 0xF8) << 8) | ((g & 0xFC) << 3) | (b >> 3)
            rgb565_data[i//3*2] = rgb >> 8
            rgb565_data[i//3*2+1] = rgb & 0xFF
        return rgb565_data

    @measure_time
    def send_buffer(self):
        if hasattr(self, 'fb'):
            data = self.buffer.tobytes()
            rgb565_data = self._convert_rgb888_to_rgb565(data)
            self.fb.seek(0)
            self.fb.write(rgb565_data)
            self.fb.flush()

    def get_size(self):
        return self.width, self.height

    @measure_time
    def draw_rect(self, x, y, w, h):
        self.draw.rectangle([x, y, x + w - 1, y + h - 1],
                            outline=self.get_current_color(),
                            width=self.line_width)

    @measure_time
    def fill_rect(self, x, y, w, h):
        self.draw.rectangle([x, y, x + w - 1, y + h - 1],
                            fill=self.get_current_color())
        self.send_buffer()

    @measure_time
    def draw_circle(self, x, y, r):
        self.draw.ellipse([x - r, y - r, x + r, y + r],
                          outline=self.get_current_color(),
                          width=self.line_width)

    @measure_time
    def fill_circle(self, x, y, r):
        self.draw.ellipse([x - r, y - r, x + r, y + r],
                          fill=self.get_current_color())
        self.send_buffer()

    @measure_time
    def draw_text(self, x, y, text):
        self.draw.text((x, y), str(text),
                       font=self.font,
                       fill=self.get_current_color())
        self.send_buffer()

    def __del__(self):
        if hasattr(self, 'fb'):
            self.fb.close()
