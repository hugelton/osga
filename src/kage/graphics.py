# graphics.py
import cairo
import numpy as np
import time
from collections import deque


class Kage:
    def __init__(self):
        self.width = 320
        self.height = 240
        self.bytes_per_pixel = 4

        # カラーシステムの初期化
        self.current_palette = {}
        self.color_indices = {}
        self.default_palette = "base"

        # メモリ上のバッファを作成
        self.surface = cairo.ImageSurface(cairo.FORMAT_RGB24, self.width, self.height)
        self.ctx = cairo.Context(self.surface)
        # デフォルトフォント
        self.ctx.select_font_face(
            "Inter Display", cairo.FONT_SLANT_NORMAL, cairo.FONT_WEIGHT_NORMAL
        )

        # ダイレクトアクセス用のバッファを確保
        self.line_length = 1280  # fbset から取得
        self.buffer = memoryview(self.surface.get_data())

        # プロファイリング用のカウンター
        self.frame_count = 0
        self.last_profile_time = time.time()
        self.profile_data = {"draw": 0, "buffer": 0}

        # FPS計測用の変数を追加
        self.frame_times = deque(maxlen=30)  # 30フレーム分の履歴
        self.last_frame_time = time.time()
        self.last_fps_update = time.time()
        self.current_fps = 0

        # フレームバッファの初期化
        try:
            import os

            self.fb = os.open("/dev/fb0", os.O_RDWR)  # low-level file descriptor
            print(f"Framebuffer initialized: {self.width}x{self.height}")
        except Exception as e:
            print(f"Failed to open framebuffer: {e}")
            self.fb = None

        # フォント初期化
        self.ctx.select_font_face(
            "Inter", cairo.FONT_SLANT_NORMAL, cairo.FONT_WEIGHT_NORMAL
        )
        self.ctx.set_font_size(16)

        # デフォルトパレットのロード
        self.loadPalette(self.default_palette)

    def loadPalette(self, name):
        """パレットファイルを読み込む"""
        try:
            path = f"src/kage/palettes/{name}.txt"
            with open(path, "r") as f:
                lines = f.readlines()
                self.current_palette = {}
                self.color_indices = {}
                for i, line in enumerate(lines, start=1):
                    if line.strip() and not line.startswith("#"):
                        parts = line.strip().split()
                        if len(parts) == 4:
                            r, g, b, color_name = parts
                            self.current_palette[color_name] = (
                                float(r),
                                float(g),
                                float(b),
                            )
                            self.color_indices[i] = color_name
        except Exception as e:
            print(f"Failed to load palette {name}: {e}")
            # デフォルトカラーを設定
            self.current_palette = {"black": (0.0, 0.0, 0.0), "white": (1.0, 1.0, 1.0)}
            self.color_indices = {1: "black", 2: "white"}
            print("Using default palette")

    def setPalette(self, name):
        """パレットを切り替える"""
        self.loadPalette(name)

    def setColor(self, name_or_index):
        if isinstance(name_or_index, (int, float)):
            if name_or_index in self.color_indices:
                name = self.color_indices[name_or_index]
                r, g, b = self.current_palette[name]
                self.ctx.set_source_rgb(r, g, b)
            else:
                self.ctx.set_source_rgb(0.0, 0.0, 0.0)
        else:
            if name_or_index in self.current_palette:
                r, g, b = self.current_palette[name_or_index]
                self.ctx.set_source_rgb(r, g, b)
            else:
                self.ctx.set_source_rgb(0.0, 0.0, 0.0)

    def setRGB(self, r, g, b):
        """最適化されたカラー設定"""
        self.ctx.set_source_rgb(r, g, b)

    def sendBuffer(self):
        """最適化されたバッファ送信"""
        try:
            if self.fb is None:
                return

            import os

            # 書き込みを一括で行う
            os.lseek(self.fb, 0, os.SEEK_SET)
            os.write(self.fb, self.buffer)

            # 明示的な同期
            os.fsync(self.fb)

        except Exception as e:
            print(f"Buffer send error: {e}")

    def optimize_buffer_alignment(self):
        """バッファアライメントの最適化"""
        # ページサイズにアライン
        PAGE_SIZE = 4096
        self.buffer = memoryview(bytearray(self.width * self.height * 4 + PAGE_SIZE))
        offset = (-ctypes.addressof(ctypes.c_char.from_buffer(self.buffer))) % PAGE_SIZE
        self.buffer = self.buffer[offset : offset + self.width * self.height * 4]

    def clear(self, color_name_or_index=0):
        """画面を指定色でクリア"""
        self.setColor(color_name_or_index)
        self.ctx.paint()

    def fillRect(self, x, y, w, h):
        """最適化された矩形描画"""
        self.ctx.rectangle(x, y, w, h)
        self.ctx.fill()

    def drawRect(self, x, y, w, h):
        self.ctx.rectangle(x, y, w, h)
        self.ctx.stroke()

    def fillCircle(self, x, y, r):
        """最適化された円描画"""
        if r <= 0:
            return
        self.ctx.arc(x, y, r, 0, np.pi * 2)
        self.ctx.fill()

    def drawCircle(self, x, y, r):
        if r <= 0:
            return
        self.ctx.arc(x, y, r, 0, np.pi * 2)
        self.ctx.stroke()

    def setFontSize(self, size):
        self.ctx.set_font_size(size)

    def drawText(self, x, y, text):
        self.ctx.move_to(x, y)
        self.ctx.show_text(str(text))

    def getTextSize(self, text):
        """テキストの大きさを取得"""
        return self.ctx.text_extents(str(text))

    def drawLine(self, x1, y1, x2, y2):
        """線を描画"""
        self.ctx.move_to(x1, y1)
        self.ctx.line_to(x2, y2)
        self.ctx.stroke()

    def drawPolygon(self, points):
        """多角形を描画"""
        if len(points) > 1:
            self.ctx.move_to(points[0][0], points[0][1])
            for x, y in points[1:]:
                self.ctx.line_to(x, y)
            self.ctx.close_path()
            self.ctx.stroke()

    def fillPolygon(self, points):
        """塗りつぶした多角形を描画"""
        if len(points) > 1:
            self.ctx.move_to(points[0][0], points[0][1])
            for x, y in points[1:]:
                self.ctx.line_to(x, y)
            self.ctx.close_path()
            self.ctx.fill()

    def updateFPS(self):
        """FPSの計算を更新"""
        current_time = time.time()
        frame_time = current_time - self.last_frame_time
        self.frame_times.append(frame_time)
        self.last_frame_time = current_time

        # 1秒に1回FPSを更新
        if current_time - self.last_fps_update >= 1.0:
            if len(self.frame_times) > 0:
                self.current_fps = len(self.frame_times) / sum(self.frame_times)
            self.last_fps_update = current_time

    def drawFPS(self, x, y):
        """指定位置にFPSを描画"""
        self.updateFPS()

        # 背景の描画（テキストの背景を黒くする）
        current_color = self.ctx.get_source()  # 現在の色を保存
        self.setRGB(0, 0, 0)  # 黒

        fps_text = f"FPS: {self.current_fps:.1f}"
        text_extents = self.ctx.text_extents(fps_text)
        self.fillRect(
            x, y - text_extents.height, text_extents.width + 4, text_extents.height + 4
        )

        # FPSテキストの描画
        self.setRGB(1, 1, 0)  # 黄色
        self.drawText(x + 2, y, fps_text)

        # パスをクリア
        self.ctx.new_path()

        # 色を元に戻す
        self.ctx.set_source(current_color)

    def __del__(self):
        """終了処理"""
        if hasattr(self, "fb") and self.fb is not None:
            import os

            os.close(self.fb)
