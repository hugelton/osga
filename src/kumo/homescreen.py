# src/kumo/homescreen.py
import importlib
import time
import math
import os
from PIL import Image, ImageDraw
import cairo
from src.kage import Kage
from src.koto import KotoRotary
from src.kage.lua_binding import KageLuaEngine
from .dialog import Dialog


class HomeScreen:
    def __init__(self):
        self.kage = Kage()
        self.koto = KotoRotary()
        self.current_app = 0

        # システムアプリの定義
        self.system_apps = [
            {
                "name": "clock",
                "title": "Clock",
                "module": "src.kumo.clock",
                "class": "Clock",
                "system": True,
            },
            {
                "name": "preferences",
                "title": "Settings",
                "module": "src.kumo.preferences",
                "class": "Preferences",
                "system": True,  # システムアプリフラグ
            },
        ]

        # アプリ定義
        self.user_apps = [
            {
                "name": "kage_test",
                "title": "KageTest",
                "script": "scripts/tests/kage_test.lua",
            },
            {
                "name": "koto_test",
                "title": "KotoTest",
                "script": "scripts/tests/koto_test.lua",
            },
            {
                "name": "nami_test",
                "title": "NamiTest",
                "script": "scripts/tests/nami_test.lua",
            },
        ]

        self.apps = self.user_apps + self.system_apps

        # レイアウト設定を更新
        self.grid_width = 4
        self.grid_height = 3
        self.icon_size = 64
        self.grid_padding_x = 8
        self.grid_padding_y = 16
        self.icon_padding = 8
        self.text_padding = 4  # アイコンとテキストの間のパディング
        self.label_height = 16  # テキストの高さ

        # フォントサイズ設定
        self.label_font_size = 12

        # アイコンの読み込み
        self.load_icons()

        # ステータスバーの位置
        self.status_x = 320  # 右端の位置

        # Luaエンジンの初期化
        self.kage_engine = KageLuaEngine(self.kage)

        # ダイアログシステムの初期化
        self.dialog = Dialog(self.kage)

        # ロータリーエンコーダの開始
        self.koto.start()

        self.last_button_state = False  # ボタンの前回の状態

    def draw_truncated_text(self, x, y, text, max_width):
        """省略付きテキストの描画"""
        self.kage.ctx.save()
        self.kage.ctx.set_font_size(self.label_font_size)

        # テキストの幅を計算
        text_extents = self.kage.ctx.text_extents(text)
        if text_extents.width > max_width:
            # テキストが長すぎる場合は省略
            ellipsis = "..."
            while text and text_extents.width > max_width:
                text = text[:-1]
                text_extents = self.kage.ctx.text_extents(text + ellipsis)
            text = text + ellipsis

        # テキストを中央揃えで描画
        text_extents = self.kage.ctx.text_extents(text)
        text_x = x + (self.icon_size - text_extents.width) / 2
        self.kage.ctx.move_to(text_x, y)
        self.kage.ctx.show_text(text)
        self.kage.ctx.new_path()
        self.kage.ctx.restore()

    def draw_vertical_text(self, x, y, text):
        """90度回転したテキストを描画"""
        self.kage.ctx.save()
        self.kage.ctx.translate(x, y)
        self.kage.ctx.rotate(-math.pi / 2)  # 90度回転
        self.kage.ctx.show_text(text)
        self.kage.ctx.new_path()  # パスをクリア
        self.kage.ctx.restore()

    def load_icons(self):
        """アイコン画像の読み込み"""
        self.icons = {}
        for app in self.apps:
            if app.get("system", False):
                # システムアプリのアイコンパス
                icon_path = f"src/kumo/icons/{app['name']}.png"
            else:
                # ユーザーアプリのアイコンパス
                icon_path = f"scripts/tests/{app['name']}.png"

            try:
                image = Image.open(icon_path)
                if image.size != (self.icon_size, self.icon_size):
                    image = image.resize((self.icon_size, self.icon_size))
                if image.mode != "RGB":
                    image = image.convert("RGB")
                self.icons[app["name"]] = image
                print(f"Loaded icon for {app['name']}")
            except Exception as e:
                print(f"Failed to load icon for {app['name']}: {e}")
                # デフォルトアイコンを作成
                default_icon = Image.new(
                    "RGB", (self.icon_size, self.icon_size), (128, 128, 128)
                )
                self.icons[app["name"]] = default_icon
                print(f"Created default icon for {app['name']}")

    def draw_icon(self, x, y, app_name, selected=False):
        """アイコンの描画（マスク処理修正版）"""
        if app_name in self.icons:
            image = self.icons[app_name]

            # 画像データの準備
            img_array = bytearray(self.icon_size * self.icon_size * 4)
            img_data = image.tobytes("raw", "RGB")

            # RGBからBGRAへの変換
            for i in range(0, len(img_data), 3):
                idx = (i // 3) * 4
                img_array[idx] = img_data[i + 2]  # B
                img_array[idx + 1] = img_data[i + 1]  # G
                img_array[idx + 2] = img_data[i]  # R
                img_array[idx + 3] = 255  # A

            # Cairoサーフェスの作成
            img_surface = cairo.ImageSurface.create_for_data(
                img_array,
                cairo.FORMAT_ARGB32,
                self.icon_size,
                self.icon_size,
                self.icon_size * 4,
            )

            self.kage.ctx.save()

            # クリッピングパスの設定
            self.kage.ctx.new_path()
            self.kage.ctx.arc(
                x + self.icon_size / 2,
                y + self.icon_size / 2,
                self.icon_size / 2,
                0,
                2 * math.pi,
            )
            self.kage.ctx.clip()

            # 画像の描画
            self.kage.ctx.set_source_surface(img_surface, x, y)
            self.kage.ctx.paint()

            # クリッピングをリセット
            self.kage.ctx.reset_clip()

            # 白い枠線の描画部分を条件分岐
            if not selected:  # 非選択時のみ枠線を描画
                self.kage.ctx.set_operator(cairo.OPERATOR_OVER)
                self.kage.ctx.set_line_width(1)
                self.kage.ctx.set_source_rgb(1, 1, 1)
                self.kage.ctx.arc(
                    x + self.icon_size / 2,
                    y + self.icon_size / 2,
                    self.icon_size / 2,
                    0,
                    2 * math.pi,
                )
                self.kage.ctx.stroke()

            if selected:
                # 選択時は反転のみ
                self.kage.ctx.set_operator(cairo.OPERATOR_DIFFERENCE)
                self.kage.ctx.set_source_rgb(1, 1, 1)
                self.kage.ctx.arc(
                    x + self.icon_size / 2,
                    y + self.icon_size / 2,
                    self.icon_size / 2,
                    0,
                    2 * math.pi,
                )
                self.kage.ctx.fill()

            self.kage.ctx.restore()
            self.kage.ctx.new_path()

    def draw_app_grid(self):
        for i, app in enumerate(self.apps):
            row = i // self.grid_width
            col = i % self.grid_width

            x = self.grid_padding_x + col * (self.icon_size + self.icon_padding)
            y = self.grid_padding_y + row * (
                self.icon_size + self.label_height + self.icon_padding
            )

            # アイコンの描画
            self.draw_icon(x, y, app["name"], i == self.current_app)

            # アプリ名の描画
            label_y = y + self.icon_size + self.text_padding + self.label_font_size
            self.kage.setRGB(1, 1, 1)  # テキストは白色
            self.draw_truncated_text(x, label_y, app["title"], self.icon_size)

    def draw_status_bar(self):
        """右端のステータスバーを描画"""
        self.kage.setRGB(1, 1, 1)
        self.kage.setFontSize(16)

        # バッテリープレースホルダー
        self.draw_vertical_text(self.status_x, 10, "X")

        # OS時刻
        current_time = time.strftime("%H:%M")
        self.draw_vertical_text(self.status_x, 240, current_time)

    def launch_app(self, app_index):
        """アプリの起動"""
        if 0 <= app_index < len(self.apps):
            app = self.apps[app_index]
            try:
                if app.get("system", False):
                    # システムアプリの起動
                    module = importlib.import_module(app["module"])
                    app_class = getattr(module, app["class"])
                    app_instance = app_class(self.kage, self.koto)
                    app_instance.run()
                else:
                    # Luaアプリの起動
                    self.kage_engine.loadScript(app["script"])
                    if "init" in self.kage_engine.lua.globals():
                        self.kage_engine.lua.globals().init()
                    while True:
                        if "update" in self.kage_engine.lua.globals():
                            self.kage_engine.lua.globals().update()
                        time.sleep(0.03)
            except Exception as e:
                error_message = f"App failed to start: {app['name']}\nError: {str(e)}"
                print(error_message)
                self.dialog.show_error("App Launch Error", error_message)

    def update(self):
        """画面の更新（ダイアログ含む）"""
        # 背景をクリア
        self.kage.clear("black")

        # ロータリーエンコーダの状態を取得
        state = self.koto.get_state()
        rotary_state = state.get("rotary", {})  # 安全に取得

        # カウントの取得と更新
        self.current_app = abs(rotary_state.get("count", 0)) % len(self.apps)

        # ボタン押下の検出とアプリ起動
        current_button_state = rotary_state.get("button", False)
        if current_button_state and not self.last_button_state:
            self.launch_app(self.current_app)
        self.last_button_state = current_button_state

        # アプリグリッドの描画
        self.draw_app_grid()

        # ステータスバーの描画
        self.draw_status_bar()

        # ダイアログの更新と描画
        self.dialog.update()
        self.dialog.draw()

        # バッファの更新
        self.kage.sendBuffer()

    def run(self):
        """メインループ"""
        try:
            while True:
                self.update()
                time.sleep(0.03)
        except KeyboardInterrupt:
            print("\nHome screen terminated")
            self.koto.stop()
