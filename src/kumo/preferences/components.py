# src/kumo/preferences/components.py
from typing import Any, Callable


class Component:
    def __init__(self, title: str, value: str = None):
        self.title = title
        self.value = value
        self.focused = False
        self.active = False

    def draw(self, kage, x: int, y: int, width: int):
        pass

    def handle_click(self):
        pass

    def handle_rotate(self, delta: int):
        pass


class Label(Component):
    def __init__(self, title: str, value: str):
        super().__init__(title, value)

    def draw(self, kage, x: int, y: int, width: int):
        if self.focused:
            # フォーカス時は背景を暗いグレーに
            kage.setRGB(0.2, 0.2, 0.2)
            kage.fillRect(x, y, width, 24)

        # タイトルと値を描画
        kage.setRGB(1, 1, 1)
        kage.drawText(x + 4, y + 16, self.title)
        kage.drawText(x + width - 100, y + 16, str(self.value))


class Slider(Component):
    def __init__(
        self,
        title: str,
        min_value: int,
        max_value: int,
        current: int,
        on_change: Callable[[int], None],
    ):
        super().__init__(title, str(current))
        self.min_value = min_value
        self.max_value = max_value
        self.current = current
        self.on_change = on_change

    def draw(self, kage, x: int, y: int, width: int):
        if self.focused:
            # フォーカス時は背景を暗いグレーに
            kage.setRGB(0.2, 0.2, 0.2)
            kage.fillRect(x, y, width, 24)

        # タイトルを描画
        kage.setRGB(1, 1, 1)
        kage.drawText(x + 4, y + 16, self.title)

        # スライダーを描画
        slider_width = 100
        slider_x = x + width - slider_width - 30
        slider_y = y + 12

        # スライダーのベースライン
        kage.setRGB(0.5, 0.5, 0.5)
        kage.drawLine(slider_x, slider_y, slider_x + slider_width, slider_y)

        # ノブの位置を計算
        position = slider_x + (
            slider_width
            * (self.current - self.min_value)
            / (self.max_value - self.min_value)
        )

        # ノブを描画
        if self.active:
            kage.setRGB(1, 0, 0)  # アクティブ時は赤
        elif self.focused:
            kage.setRGB(1, 1, 0)  # フォーカス時は黄色
        else:
            kage.setRGB(1, 1, 1)  # 通常時は白
        kage.fillCircle(position, slider_y, 5)

        # 現在値を表示
        kage.setRGB(1, 1, 1)
        kage.drawText(x + width - 25, y + 16, str(self.current))

    def handle_rotate(self, delta: int):
        if self.active:
            self.current = max(
                self.min_value, min(self.max_value, self.current + delta)
            )

            self.value = str(self.current)
            if self.on_change:
                self.on_change(self.current)

    def handle_rotate(self, delta: int):
        if self.active:
            self.current = max(
                self.min_value, min(self.max_value, self.current + delta)
            )
            if self.on_change:
                self.on_change(self.current)


class Button(Component):
    def __init__(self, title: str, label: str, on_click: Callable[[], None]):
        super().__init__(title, label)
        self.on_click = on_click

    def draw(self, kage, x: int, y: int, width: int):
        if self.focused:
            # フォーカス時は背景を暗いグレーに
            kage.setRGB(0.2, 0.2, 0.2)
            kage.fillRect(x, y, width, 24)

        # タイトルを描画
        kage.setRGB(1, 1, 1)
        kage.drawText(x + 4, y + 16, self.title)

        # ボタンを描画
        button_width = 100
        button_x = x + width - button_width - 10
        button_y = y + 4

        if self.active:
            kage.setRGB(1, 0, 0)  # アクティブ時は赤
        elif self.focused:
            kage.setRGB(1, 1, 0)  # フォーカス時は黄色
        else:
            kage.setRGB(1, 1, 1)  # 通常時は白

        kage.drawRect(button_x, button_y, button_width, 20)

        # ボタンのラベルを描画
        text_width = kage.ctx.text_extents(self.value).width
        text_x = button_x + (button_width - text_width) / 2
        kage.drawText(text_x, y + 16, self.value)

    def handle_click(self):
        if self.focused and self.on_click:
            self.on_click()
