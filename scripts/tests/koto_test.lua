-- scripts/tests/koto_test.lua

-- グローバル変数
local angle = 0

-- 初期化
function init()
    koto.start() -- ロータリーエンコーダのモニタリング開始
    print("Koto test initialized")
end

-- 更新とテスト描画
function update()
    -- 画面クリア
    kage.clear("black")

    -- 状態取得
    local state = koto.getState()
    local count = state.count
    local button = state.button

    -- 回転インジケータの描画（大きな円と回転する点）
    local centerX, centerY = 160, 120
    local radius = 60

    -- 外側の円（白）
    kage.setRGB(1, 1, 1)
    kage.drawCircle(centerX, centerY, radius)

    -- 回転する点（countに基づいて位置を計算）
    angle = count * (math.pi / 8) -- 16ステップで一周
    local dotX = centerX + math.cos(angle) * radius
    local dotY = centerY + math.sin(angle) * radius

    -- ボタンの状態に応じて色を変更（押されていたら赤、そうでなければ白）
    if button then
        kage.setRGB(1, 0, 0) -- 赤
    else
        kage.setRGB(1, 1, 1) -- 白
    end
    kage.fillCircle(dotX, dotY, 5)

    -- カウント値の表示
    kage.setRGB(1, 1, 1)
    kage.setFontSize(20)
    kage.drawText(140, 200, "Count: " .. count)

    -- FPS表示
    kage.drawFPS(10, 20)

    kage.sendBuffer()
end

-- 終了処理
function cleanup()
    koto.stop()
end
