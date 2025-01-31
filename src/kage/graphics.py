from PIL import Image, ImageDraw, ImageFont
import math
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
            self.fb = open('/dev/fb1', 'wb')
        except Exception as e:
            print(f"Warning: Could not open framebuffer: {e}")

        self.buffer = bytearray(self.width * self.height * 2)  # RGB565 buffer
        self.current_color = 0

        # パレットの読み込み
        self.palette = self._load_palette('src/kage/base_palette.txt')

        # フォント設定
        self.font_sizes = {1: 8, 2: 16, 3: 24}
        try:
            self.font = ImageFont.truetype("/usr/share/fonts/truetype/dejavu/DejaVuSans.ttf",
                                           self.font_sizes[2])
        except:
            self.font = ImageFont.load_default()

    def _load_palette(self, palette_file):
        palette = []
        try:
            with open(palette_file, 'r') as f:
                lines = f.readlines()
                for line in lines[1:]:  # 1行目はコメントなのでスキップ
                    if line.strip() and not line.startswith('#'):
                        color_hex = line.split()[0]
                        # RGB565の16進数文字列をバイト値に変換
                        color_bytes = bytes.fromhex(color_hex)
                        palette.append(color_bytes)
            return palette
        except Exception as e:
            print(f"Error loading palette: {e}")
            # デフォルトパレット（黒と白のみ）
            return [bytes([0x00, 0x00]), bytes([0xFF, 0xFF])]

    @measure_time
    def clear(self, color_index=0):
        """指定した色でバッファをクリア"""
        if 0 <= color_index < len(self.palette):
            color_bytes = self.palette[color_index]
            for i in range(0, len(self.buffer), 2):
                self.buffer[i] = color_bytes[0]
                self.buffer[i+1] = color_bytes[1]
        self.send_buffer()

    @measure_time
    def send_buffer(self):
        if hasattr(self, 'fb'):
            self.fb.seek(0)
            self.fb.write(self.buffer)
            self.fb.flush()

    def set_color(self, color_index):
        if 0 <= color_index < len(self.palette):
            self.current_color = color_index

    @measure_time
    def fill_circle(self, x, y, r):
        # 描画用の一時的なPILイメージを作成
        temp_img = Image.new('1', (self.width, self.height))
        draw = ImageDraw.Draw(temp_img)
        draw.ellipse([x - r, y - r, x + r, y + r], fill=1)

        # PILイメージをバッファに反映
        color_bytes = self.palette[self.current_color]
        for y in range(self.height):
            for x in range(self.width):
                if temp_img.getpixel((x, y)):
                    idx = (y * self.width + x) * 2
                    self.buffer[idx] = color_bytes[0]
                    self.buffer[idx + 1] = color_bytes[1]

        self.send_buffer()

    def set_font_size(self, size):
        if size in self.font_sizes:
            try:
                self.font = ImageFont.truetype("/usr/share/fonts/truetype/dejavu/DejaVuSans.ttf",
                                               self.font_sizes[size])
            except:
                self.font = ImageFont.load_default()

    @measure_time
    def draw_text(self, x, y, text):
        temp_img = Image.new('1', (self.width, self.height))
        draw = ImageDraw.Draw(temp_img)
        draw.text((x, y), str(text), font=self.font, fill=1)

        color_bytes = self.palette[self.current_color]
        for y in range(self.height):
            for x in range(self.width):
                if temp_img.getpixel((x, y)):
                    idx = (y * self.width + x) * 2
                    self.buffer[idx] = color_bytes[0]
                    self.buffer[idx + 1] = color_bytes[1]

        self.send_buffer()

    def __del__(self):
        if hasattr(self, 'fb'):
            self.fb.close()
