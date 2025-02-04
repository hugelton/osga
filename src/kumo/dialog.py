# src/kumo/dialog.py
import cairo
import time


class Dialog:
    def __init__(self, kage):
        self.kage = kage
        self.messages = []  # メッセージキュー
        self.message_lifetime = 3.0  # メッセージ表示時間（秒）
        self.padding = 8  # パディング
        self.border_width = 2  # ボーダー幅
        self.font_size = 12  # フォントサイズ

    def show_error(self, main_text, sub_text=None):
        """エラーメッセージを表示キューに追加"""
        self.messages.append(
            {"main_text": main_text, "sub_text": sub_text, "start_time": time.time()}
        )

    def update(self):
        """メッセージの更新とクリーンアップ"""
        current_time = time.time()
        # 期限切れのメッセージを削除
        self.messages = [
            msg
            for msg in self.messages
            if current_time - msg["start_time"] < self.message_lifetime
        ]

    def draw(self):
        """メッセージの描画"""
        if not self.messages:
            return

        # 最新のメッセージを取得
        message = self.messages[-1]
        main_text = message["main_text"]
        sub_text = message["sub_text"]

        # フォントの設定
        self.kage.ctx.save()
        self.kage.ctx.set_font_size(self.font_size)

        # テキストサイズの計算
        main_extents = self.kage.ctx.text_extents(main_text)
        sub_extents = self.kage.ctx.text_extents(sub_text) if sub_text else None

        # ボックスのサイズ計算
        box_width = (
            max(main_extents.width, sub_extents.width if sub_extents else 0)
            + self.padding * 4
        )

        box_height = main_extents.height + self.padding * 2
        if sub_text:
            box_height += sub_extents.height + self.padding

        # 画面右下の位置を計算
        x = self.kage.width - box_width - self.padding * 2
        y = self.kage.height - box_height - self.padding * 2

        # 背景の黒い長方形を描画
        self.kage.ctx.set_source_rgb(0, 0, 0)
        self.kage.ctx.rectangle(x, y, box_width, box_height)
        self.kage.ctx.fill()

        # 赤いボーダーを描画
        self.kage.ctx.set_source_rgb(1, 0, 0)
        self.kage.ctx.set_line_width(self.border_width)
        self.kage.ctx.rectangle(x, y, box_width, box_height)
        self.kage.ctx.stroke()

        # メインテキストを描画（白）
        self.kage.ctx.set_source_rgb(1, 1, 1)
        self.kage.ctx.move_to(
            x + self.padding * 2, y + self.padding + main_extents.height
        )
        self.kage.ctx.show_text(main_text)

        # サブテキストを描画（白、存在する場合）
        if sub_text:
            self.kage.ctx.move_to(
                x + self.padding * 3,  # インデント付き
                y + main_extents.height + self.padding * 2 + sub_extents.height,
            )
            self.kage.ctx.show_text(sub_text)

        # 描画状態を復元
        self.kage.ctx.restore()
        self.kage.ctx.new_path()
