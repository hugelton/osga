from PIL import Image  # 画像読み込み用
import cairo
import time
import os


class Kage:
    def __init__(self):
        self.width = 320
        self.height = 240
        self.surface = cairo.ImageSurface(
            cairo.FORMAT_RGB24, self.width, self.height)
        self.ctx = cairo.Context(self.surface)

        # フレームバッファの初期化
        try:
            self.fb = open('/dev/fb0', 'wb')
        except Exception as e:
            print(f"Failed to open framebuffer: {e}")
            return

        # カラーシステムの初期化
        self.current_palette = {}  # 名前→RGB値のマッピング
        self.color_indices = {}    # インデックス→名前のマッピング
        self.default_palette = "base"
        self.loadPalette(self.default_palette)

        # フォント初期化
        self.ctx.select_font_face("Inter Display",
                                  cairo.FONT_SLANT_NORMAL,
                                  cairo.FONT_WEIGHT_NORMAL)
        self.ctx.set_font_size(16)  # デフォルトサイズ

    def loadPalette(self, name):
        """パレットファイルを読み込む"""
        try:
            path = f"src/kage/palettes/{name}.txt"
            with open(path, 'r') as f:
                lines = f.readlines()
                self.current_palette.clear()
                self.color_indices.clear()

                for i, line in enumerate(lines):
                    if line.strip() and not line.startswith('#'):
                        r, g, b, color_name = line.strip().split()
                        self.current_palette[color_name] = (
                            float(r), float(g), float(b))
                        self.color_indices[i] = color_name
        except Exception as e:
            print(f"Failed to load palette {name}: {e}")
            # デフォルトカラー（黒と白）を設定
            self.current_palette = {
                "black": (0.0, 0.0, 0.0),
                "white": (1.0, 1.0, 1.0)
            }
            self.color_indices = {0: "black", 1: "white"}

    def setPalette(self, name):
        """パレットを切り替える"""
        self.loadPalette(name)

    def setColor(self, name_or_index):
        """色を設定（名前またはインデックスで）"""
        if isinstance(name_or_index, int):
            if name_or_index in self.color_indices:
                name = self.color_indices[name_or_index]
                r, g, b = self.current_palette[name]
                self.ctx.set_source_rgb(r, g, b)
        else:
            if name_or_index in self.current_palette:
                r, g, b = self.current_palette[name_or_index]
                self.ctx.set_source_rgb(r, g, b)

    def setRGB(self, r, g, b):
        """RGB値で直接色を設定"""
        self.ctx.set_source_rgb(r, g, b)

    def clear(self, color_name_or_index=0):
        """画面を指定色でクリア"""
        self.setColor(color_name_or_index)
        self.ctx.paint()
        self.sendBuffer()

    def sendBuffer(self):
        """バッファをフレームバッファに送信"""
        self.fb.seek(0)
        self.fb.write(self.surface.get_data())
        self.fb.flush()

    # 基本図形描画
    def drawRect(self, x, y, w, h):
        self.ctx.rectangle(x, y, w, h)
        self.ctx.stroke()

    def fillRect(self, x, y, w, h):
        self.ctx.rectangle(x, y, w, h)
        self.ctx.fill()

    def drawCircle(self, x, y, r):
        self.ctx.arc(x, y, r, 0, 2 * 3.14159)
        self.ctx.stroke()

    def fillCircle(self, x, y, r):
        self.ctx.arc(x, y, r, 0, 2 * 3.14159)
        self.ctx.fill()

    def drawLine(self, x1, y1, x2, y2):
        self.ctx.move_to(x1, y1)
        self.ctx.line_to(x2, y2)
        self.ctx.stroke()

    def drawPolygon(self, points):
        if len(points) > 1:
            self.ctx.move_to(points[0][0], points[0][1])
            for x, y in points[1:]:
                self.ctx.line_to(x, y)
            self.ctx.close_path()
            self.ctx.stroke()

    def fillPolygon(self, points):
        if len(points) > 1:
            self.ctx.move_to(points[0][0], points[0][1])
            for x, y in points[1:]:
                self.ctx.line_to(x, y)
            self.ctx.close_path()
            self.ctx.fill()

    # テキスト描画
    def setFontSize(self, size):
        self.ctx.set_font_size(size)

    def drawText(self, x, y, text):
        self.ctx.move_to(x, y)
        self.ctx.show_text(str(text))

    def getTextSize(self, text):
        return self.ctx.text_extents(str(text))

    # 画像関連
    def loadImage(self, path):
        """画像をロード"""
        try:
            image = Image.open(path)
            # RGB形式に変換
            if image.mode != 'RGB':
                image = image.convert('RGB')
            return image
        except Exception as e:
            print(f"Failed to load image {path}: {e}")
            return None

    def drawImage(self, image, x, y):
        """画像を描画"""
        if image is None:
            return

        # PILイメージからCairoサーフェスに変換
        img_data = bytes(image.tobytes())
        img_surface = cairo.ImageSurface.create_for_data(
            img_data,
            cairo.FORMAT_RGB24,
            image.width,
            image.height
        )

        # 画像を描画
        self.ctx.save()
        self.ctx.translate(x, y)
        self.ctx.set_source_surface(img_surface, 0, 0)
        self.ctx.paint()
        self.ctx.restore()

    def drawImageEx(self, image, x, y, scale=1.0, rotation=0.0):
        """拡大縮小と回転付きで画像を描画"""
        if image is None:
            return

        img_data = bytes(image.tobytes())
        img_surface = cairo.ImageSurface.create_for_data(
            img_data,
            cairo.FORMAT_RGB24,
            image.width,
            image.height
        )

        self.ctx.save()
        self.ctx.translate(x, y)
        self.ctx.rotate(rotation)
        self.ctx.scale(scale, scale)
        self.ctx.set_source_surface(img_surface, 0, 0)
        self.ctx.paint()
        self.ctx.restore()

    def __del__(self):
        """終了処理"""
        if hasattr(self, 'fb'):
            self.fb.close()
