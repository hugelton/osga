from PIL import Image, ImageDraw, ImageFont
import math
import colorsys


class Kage:
    def __init__(self):
        self.width = 320
        self.height = 240
        self.fb = open('/dev/fb0', 'wb')
        self.buffer = Image.new('RGB', (self.width, self.height), 'black')
        self.draw = ImageDraw.Draw(self.buffer)

        # 描画属性
        self.current_color = 0
        self.current_rgb = None  # 追加
        self.alpha = 1.0
        self.line_width = 1
        self.font_size = 2
        self.font_style = "normal"

        # カラーパレット
        self.colors = {
            0: (0, 0, 0),        # 黒
            1: (255, 255, 255),  # ベースカラー（白）
            2: (255, 107, 71)    # プライマリーカラー（オレンジ赤）
        }

        # フォント関連の初期化
        self.font_sizes = {
            1: 8,    # 小
            2: 16,   # 標準
            3: 24    # 大
        }
        try:
            self.font = ImageFont.truetype("/usr/share/fonts/opentype/inter/InterDisplay-Regular.otf",
                                           self.font_sizes[self.font_size])
        except:
            self.font = ImageFont.load_default()

    def get_current_color(self):
        if self.current_rgb:  # 優先度: 直接指定 > パレット
            return self.current_rgb
        color = self.colors.get(self.current_color, (0, 0, 0))
        if self.alpha < 1.0:
            return (*color, int(255 * self.alpha))
        return color

    # 基本操作
    def clear(self, color=0):
        self.buffer.paste(self.colors[color], (0, 0, self.width, self.height))

    def send_buffer(self):
        if hasattr(self, 'fb'):
            data = self.buffer.tobytes()
            rgb565_data = self._convert_rgb888_to_rgb565(data)
            self.fb.seek(0)
            self.fb.write(rgb565_data)
            self.fb.flush()

    def get_size(self):
        return self.width, self.height

    # 描画色設定
    def set_color(self, c):
        self.current_color = c if c in self.colors else 0
        self.current_rgb = None  # パレット色使用時はRGBをリセット

    def set_color_rgb(self, r, g, b):
        self.current_rgb = (r, g, b)  # 直接RGB値を保持

    def set_alpha(self, a):
        self.alpha = max(0.0, min(1.0, a))

    # 図形描画
    def draw_pixel(self, x, y):
        self.draw.point((x, y), fill=self.get_current_color())

    def draw_line(self, x1, y1, x2, y2, stroke=None):
        width = stroke if stroke is not None else self.line_width
        self.draw.line((x1, y1, x2, y2),
                       fill=self.get_current_color(),
                       width=width)

    def draw_rect(self, x, y, w, h):
        self.draw.rectangle([x, y, x + w - 1, y + h - 1],
                            outline=self.get_current_color(),
                            width=self.line_width)

    def fill_rect(self, x, y, w, h):
        self.draw.rectangle([x, y, x + w - 1, y + h - 1],
                            fill=self.get_current_color())

    def draw_circle(self, x, y, r):
        self.draw.ellipse([x - r, y - r, x + r, y + r],
                          outline=self.get_current_color(),
                          width=self.line_width)

    def fill_circle(self, x, y, r):
        self.draw.ellipse([x - r, y - r, x + r, y + r],
                          fill=self.get_current_color())

    # 三角形描画

    def draw_triangle(self, x1, y1, x2, y2, x3, y3):
        points = [(x1, y1), (x2, y2), (x3, y3), (x1, y1)]
        self.draw.line(points,
                       fill=self.get_current_color(),
                       width=self.line_width)

    def fill_triangle(self, x1, y1, x2, y2, x3, y3):
        points = [(x1, y1), (x2, y2), (x3, y3)]
        self.draw.polygon(points, fill=self.get_current_color())

    # ポリゴン描画
    def draw_polygon(self, points):
        if len(points) > 1:
            # 最後の点を最初の点につなぐ
            points_list = [(p[0], p[1]) for p in points]
            points_list.append(points_list[0])
            self.draw.line(points_list,
                           fill=self.get_current_color(),
                           width=self.line_width)

    # テキスト描画関連
    def set_font_size(self, size):
        if size in self.font_sizes:
            self.font_size = size
            try:
                self.font = ImageFont.truetype("/usr/share/fonts/opentype/inter/InterDisplay-Regular.otf",
                                               self.font_sizes[self.font_size])
            except:
                self.font = ImageFont.load_default()

    def set_font_style(self, style):
        self.font_style = style  # 現在は使用していない

    def draw_text(self, x, y, text):
        self.draw.text((x, y), str(text),
                       font=self.font,
                       fill=self.get_current_color())

    def text_size(self, text):
        bbox = self.draw.textbbox((0, 0), str(text), font=self.font)
        return bbox[2] - bbox[0], bbox[3] - bbox[1]

    # 高度な描画機能
    def draw_arc(self, x, y, r, start, stop):
        # 角度を度からラジアンに変換
        start_deg = math.degrees(start)
        stop_deg = math.degrees(stop)
        bbox = [x - r, y - r, x + r, y + r]
        self.draw.arc(bbox, start_deg, stop_deg,
                      fill=self.get_current_color(),
                      width=self.line_width)

    def draw_ellipse(self, x, y, rx, ry):
        bbox = [x - rx, y - ry, x + rx, y + ry]
        self.draw.ellipse(bbox,
                          outline=self.get_current_color(),
                          width=self.line_width)

    # 描画属性
    def set_line_width(self, width):
        self.line_width = max(1, int(width))

    # 画像変換用のヘルパーメソッド
    def _convert_rgb888_to_rgb565(self, data):
        rgb565_data = bytearray(len(data) // 3 * 2)
        for i in range(0, len(data), 3):
            g = data[i]
            b = data[i+1]
            r = data[i+2]
            # ハードウェアがRGB順を期待している場合の修正
            rgb = ((r & 0xF8) << 8) | ((g & 0xFC) << 3) | (b >> 3)  # RGB順
            rgb565_data[i//3*2] = rgb >> 8
            rgb565_data[i//3*2+1] = rgb & 0xFF
        return rgb565_data
