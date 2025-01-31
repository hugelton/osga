# src/kage/lua_binding.py
from lupa import LuaRuntime
import time


class KageLuaEngine:
    def __init__(self, kageInstance):
        self.kage = kageInstance
        self.lua = LuaRuntime(unpack_returned_tuples=True)
        self.setupApi()

    def setupApi(self):
        g = self.lua.globals()

        # print関数を追加
        g.print = print

        # Kage APIテーブル
        kageApi = {
            # 基本操作
            'clear': self.kage.clear,
            'sendBuffer': self.kage.sendBuffer,

            # カラー管理
            'setPalette': self.kage.setPalette,
            'setColor': self.kage.setColor,
            'setRGB': self.kage.setRGB,

            # 図形描画
            'drawRect': self.kage.drawRect,
            'fillRect': self.kage.fillRect,
            'drawCircle': self.kage.drawCircle,
            'fillCircle': self.kage.fillCircle,
            'drawLine': self.kage.drawLine,
            'drawPolygon': self.kage.drawPolygon,
            'fillPolygon': self.kage.fillPolygon,

            # テキスト描画
            'setFontSize': self.kage.setFontSize,
            'drawText': self.kage.drawText,
            'getTextSize': self.kage.getTextSize,

            # 画像関連
            'loadImage': self.kage.loadImage,
            'drawImage': self.kage.drawImage,
            'drawImageEx': self.kage.drawImageEx,
        }
        g.kage = kageApi

    def loadScript(self, scriptPath):
        with open(scriptPath, 'r') as f:
            self.lua.execute(f.read())
