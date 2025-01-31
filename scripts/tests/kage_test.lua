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
    print("Cleared screen to black")

    -- 基本図形のテスト
    kage.setRGB(1.0, 1.0, 1.0)
    print("Set color to white")
    kage.fillRect(10, 10, 50, 50)
    print("Filled rectangle")
    kage.setRGB(1.0, 0.0, 0.0) -- 赤色
    print("Set RGB color to red")
    kage.drawCircle(160, 120, 40)
    print("Drawn circle")

    -- テキスト描画
    kage.setColor("white")
    print("Set color to white")
    kage.setFontSize(20)
    print("Set font size to 20")
    kage.drawText(80, 80, "OSGA Test")
    print("Drawn text")

    -- パレットカラーのテスト
    kage.setColor(2) -- インデックス2のカラー
    print("Set color to index 2")
    kage.fillCircle(250, 50, 30)
    print("Filled circle")


    kage.sendBuffer()
    print("Sent buffer to display")
end
