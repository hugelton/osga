# src/kumo/clock/clock.py
import time
import math
import cairo
from src.kage import Kage


class Clock:
    def __init__(self, kage, koto):
        self.kage = kage
        self.koto = koto

        # 画面の中心を計算
        self.center_x = self.kage.width // 2
        self.center_y = self.kage.height // 2

        # 針の長さ（画面サイズに応じて調整）
        self.radius = min(self.center_x, self.center_y) - 20
        self.hour_hand_length = self.radius * 0.5
        self.minute_hand_length = self.radius * 0.8

        # 針の太さ
        self.hour_hand_width = 4
        self.minute_hand_width = 2

        # ステータスバーの位置
        self.status_x = 320  # 右端の位置

    def draw_hand(self, angle, length, width):
        """針を描画（rounded caps付き）"""
        ctx = self.kage.ctx

        # 線のスタイル設定
        ctx.set_line_width(width)
        ctx.set_line_cap(cairo.LINE_CAP_ROUND)

        # 針の座標を計算
        end_x = self.center_x + length * math.sin(angle)
        end_y = self.center_y - length * math.cos(angle)

        # 針を描画
        ctx.move_to(self.center_x, self.center_y)
        ctx.line_to(end_x, end_y)
        ctx.stroke()

    def update(self):
        """時計の更新"""
        # 背景クリア
        self.kage.clear("black")

        # 現在時刻の取得
        current_time = time.localtime()
        hours = current_time.tm_hour % 12
        minutes = current_time.tm_min

        # 時針の角度計算（12時間で360度、分も考慮）
        hour_angle = 2 * math.pi * (hours / 12.0 + minutes / 720.0)

        # 分針の角度計算（60分で360度）
        minute_angle = 2 * math.pi * minutes / 60.0

        # 針の描画
        self.kage.ctx.set_source_rgb(1, 1, 1)  # 白色

        # 時針の描画
        self.draw_hand(hour_angle, self.hour_hand_length, self.hour_hand_width)

        # 分針の描画
        self.draw_hand(minute_angle, self.minute_hand_length, self.minute_hand_width)

        # バッファの更新
        self.kage.sendBuffer()

    def run(self):
        """メインループ"""
        try:
            while True:
                # ロータリーエンコーダの状態を取得
                state = self.koto.get_state()
                buttons = state.get("buttons", {})

                # Xボタンで終了
                if buttons.get("x", {}).get("pressed", False):
                    break

                self.update()
                time.sleep(0.1)  # 更新頻度を抑える（1秒の1/10）

        except KeyboardInterrupt:
            print("\nClock terminated")
