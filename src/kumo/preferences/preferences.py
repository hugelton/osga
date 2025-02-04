# src/kumo/preferences/preferences.py
import json
import os
import time
from .components import Label, Slider, Button


class Preferences:
    def __init__(self, kage, koto):
        try:
            self.kage = kage
            self.koto = koto
            self.current_index = 0
            # 初期状態を取得して構造を確認
            initial_state = self.koto.get_state()
            print("Debug - Initial state:", initial_state)  # デバッグ用出力
            self.preferences_file = "preferences.json"

            # 設定の読み込み
            self.load_preferences()

            # コンポーネントの初期化
            self.components = [
                Label("Version", self.preferences.get("version", "v0.0.1")),
                Label("Device Name", self.preferences.get("device_name", "osga")),
                Slider(
                    "Brightness",
                    0,
                    100,
                    self.preferences.get("brightness", 100),
                    self.on_brightness_change,
                ),
                Button("System", "Restart", self.on_restart_click),
            ]

            # 最初のコンポーネントにフォーカス
            self.components[0].focused = True

            # 前回のボタン状態
            self.last_button_state = False

            # スクロール関連の追加
            self.scroll_y = 0
            self.item_height = 40  # 各アイテムの高さ
            self.visible_items = 5  # 一度に表示するアイテム数
            self.scroll_margin = 2  # スクロールを開始するマージン

            # 前回の状態を保存
            self.last_button_state = False
            self.last_count = 0
            self.active_component = False  # 値変更モードかどうか

        except Exception as e:
            raise Exception(f"Preferences initialization failed: {str(e)}")

    def load_preferences(self):
        """設定ファイルの読み込み"""
        try:
            with open(self.preferences_file, "r") as f:
                self.preferences = json.load(f)
        except (FileNotFoundError, json.JSONDecodeError):
            self.preferences = {
                "version": "v0.0.1",
                "device_name": "osga",
                "brightness": 100,
            }
            self.save_preferences()

    def save_preferences(self):
        """設定の保存"""
        with open(self.preferences_file, "w") as f:
            json.dump(self.preferences, f, indent=2)

    def on_brightness_change(self, value):
        """明るさ変更時のコールバック"""
        self.preferences["brightness"] = value
        self.save_preferences()
        # ここで実際の明るさを変更する処理を追加

    def on_restart_click(self):
        """再起動ボタンのコールバック"""
        # ここで実際の再起動処理を追加
        os.system("sudo reboot")

    def update(self):

        # 背景を完全にクリア
        self.kage.clear("black")
        self.kage.ctx.save()  # 描画状態を保存

        # ロータリーエンコーダの状態を取得
        state = self.koto.get_state()
        rotary_state = state.get("rotary", {})

        # クリック状態の変化を検出
        clicked = rotary_state.get("button", False) and not self.last_button_state
        released = not rotary_state.get("button", False) and self.last_button_state

        # 回転量の計算
        rotation_delta = rotary_state.get("count", 0) - self.last_count

        if rotary_state.get("button", False):
            if not self.active_component and clicked:
                # ボタンを押した瞬間にアクティブモードに
                self.active_component = True
                self.components[self.current_index].active = True
            if rotation_delta != 0:
                # 押しながら回転：値の変更
                self.components[self.current_index].handle_rotate(rotation_delta)
        else:
            if released:
                # ボタンを離した時にアクティブモードを解除
                self.active_component = False
                for comp in self.components:
                    comp.active = False

            if rotation_delta != 0:
                # 通常回転：フォーカス移動
                self.components[self.current_index].focused = False
                self.current_index = (self.current_index + rotation_delta) % len(
                    self.components
                )
                self.components[self.current_index].focused = True

                # スクロール位置の調整
                target_y = self.current_index * self.item_height
                visible_top = self.scroll_y
                visible_bottom = (
                    self.scroll_y + (self.visible_items - 1) * self.item_height
                )

                if target_y < visible_top + self.item_height * self.scroll_margin:
                    self.scroll_y = max(
                        0, target_y - self.item_height * self.scroll_margin
                    )
                elif target_y > visible_bottom - self.item_height * self.scroll_margin:
                    max_scroll = max(
                        0,
                        (len(self.components) - self.visible_items) * self.item_height,
                    )
                    self.scroll_y = min(
                        max_scroll,
                        target_y
                        - (self.visible_items - self.scroll_margin - 1)
                        * self.item_height,
                    )

        # クリック処理
        if clicked:
            self.components[self.current_index].handle_click()

        # タイトルを描画
        self.kage.setRGB(1, 1, 1)
        self.kage.setFontSize(20)
        self.kage.drawText(20, 30, "Preferences")
        self.kage.setFontSize(16)

        # コンポーネントの描画（スクロール位置を考慮）
        clip_top = 50  # 描画開始Y座標
        clip_bottom = clip_top + self.visible_items * self.item_height

        for i, component in enumerate(self.components):
            y = 50 + i * self.item_height - self.scroll_y
            if clip_top <= y <= clip_bottom:
                component.draw(self.kage, 20, y, 280)

        self.last_button_state = state.get("rotary", {}).get("button", False)
        self.last_count = state.get("rotary", {}).get("count", 0)

        self.kage.ctx.restore()  # 描画状態を復元

        # バッファの更新
        self.kage.sendBuffer()

    def run(self):
        """メインループ"""
        state = self.koto.get_state()
        self.last_count = state.get("rotary", {}).get("count", 0)
        try:
            while True:
                self.update()
                time.sleep(0.03)
        except KeyboardInterrupt:
            print("\nPreferences terminated")
