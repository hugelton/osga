-- kage_test.lua
-- 初期化
function init()
    -- パレットとカラーの設定
    kage.setPalette("base")
    print("Initial setup complete")
end

-- 更新とテスト描画
function update()
    -- 画面クリア
    kage.clear("black")

    -- 基本図形のテスト
    kage.setRGB(1.0, 1.0, 1.0)
    kage.fillRect(10, 10, 50, 50)
    kage.setRGB(1.0, 0.0, 0.0) -- 赤色
    kage.drawCircle(160, 120, 40)

    -- テキスト描画
    kage.setColor("white")
    kage.setFontSize(20)
    kage.drawText(80, 80, "OSGA Test")

    -- パレットカラーのテスト
    kage.setColor(2) -- インデックス2のカラー
    kage.fillCircle(250, 50, 30)


    kage.sendBuffer()
end
