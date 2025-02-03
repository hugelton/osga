# src/koto/rotary.py
from RPi_GPIO_Rotary import rotary
import time


class KotoRotary:
    def __init__(self):
        # ロータリーエンコーダの初期化
        self.encoder = None
        self.count = 0
        self.button_state = False
        self.is_running = False
        self._init_encoder()

    def _init_encoder(self):
        """エンコーダーの初期化"""
        try:
            self.encoder = rotary.Rotary(17, 27, 22, 2)  # CLK, DT, SW, ticks
            self._setup_callbacks()
        except Exception as e:
            print(f"Rotary encoder initialization error: {e}")
            self.encoder = None

    def _setup_callbacks(self):
        """コールバックの設定"""
        if self.encoder:
            self.encoder.register(
                increment=self._on_cw,
                decrement=self._on_ccw,
                pressed=self._on_button,
                onchange=self._on_value_change,
            )

    def _on_cw(self):
        """時計回りの回転"""
        self.count += 1

    def _on_ccw(self):
        """反時計回りの回転"""
        self.count -= 1

    def _on_button(self):
        """ボタン押下"""
        self.button_state = not self.button_state

    def _on_value_change(self, value):
        """値の変更"""
        self.count = value

    def get_state(self):
        """現在の状態を取得"""
        return {"count": self.count, "button": self.button_state}

    def start(self):
        """モニタリング開始"""
        if self.encoder and not self.is_running:
            try:
                self.encoder.start()
                self.is_running = True
            except Exception as e:
                print(f"Failed to start rotary encoder: {e}")

    def stop(self):
        """モニタリング停止"""
        if self.encoder and self.is_running:
            try:
                # エンコーダーの状態をチェック
                if hasattr(self.encoder, "stop_event"):
                    self.encoder.stop()
                self.is_running = False
            except Exception as e:
                print(f"Error stopping rotary encoder: {e}")

    def __del__(self):
        """クリーンアップ"""
        try:
            if self.is_running:
                self.stop()
        except:
            pass  # 終了時のエラーは無視
