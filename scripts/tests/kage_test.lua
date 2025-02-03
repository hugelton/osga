-- kage_test.lua
-- 定数とキャッシュ
local PI = math.pi
local cos = math.cos
local sin = math.sin
local floor = math.floor
local random = math.random

-- 描画キャッシュ
local color_cache = nil
local angle = 0
local particles = {}
local NUM_PARTICLES = 25 -- パーティクル数を削減

-- 色の定数
local colors = {
    red = { 1.0, 0.0, 0.0 },
    blue = { 0.5, 0.8, 1.0 },
    white = { 1.0, 1.0, 1.0 },
    yellow = { 1.0, 1.0, 0.0 },
    gray = { 0.2, 0.2, 0.2 }
}

-- 初期化
function init()
    kage.setPalette("base")

    -- パーティクルの配列を事前生成
    for i = 1, NUM_PARTICLES do
        particles[i] = {
            x = random(0, 319),
            y = random(0, 239),
            dx = (random() - 0.5) * 3, -- 速度を少し遅く
            dy = (random() - 0.5) * 3,
            size = random(2, 6)        -- サイズを小さく
        }
    end
end

-- パーティクルの更新（最適化版）
function updateParticles()
    local p
    for i = 1, NUM_PARTICLES do
        p = particles[i]

        -- 位置の更新（境界チェックを最適化）
        p.x = p.x + p.dx
        p.y = p.y + p.dy

        -- 画面端での跳ね返り（条件判定を簡略化）
        if p.x < 0 or p.x > 319 then
            p.dx = -p.dx
            p.x = p.x < 0 and 0 or 319
        end

        if p.y < 0 or p.y > 239 then
            p.dy = -p.dy
            p.y = p.y < 0 and 0 or 239
        end
    end
end

-- 更新とテスト描画
function update()
    -- 画面クリア（黒）
    kage.clear("black")

    -- 回転する四角形
    angle = angle + 0.02
    local centerX, centerY = 160, 120
    local c = colors.red
    kage.setRGB(c[1], c[2], c[3])

    for i = 1, 2 do
        local size = 40 + i * 15
        local x = centerX + cos(angle + i * PI) * size
        local y = centerY + sin(angle + i * PI) * size
        kage.fillRect(x - 10, y - 10, 20, 20)
    end

    -- パーティクル描画（バッチ処理）
    updateParticles()
    c = colors.white
    kage.setRGB(c[1], c[2], c[3])
    for i = 1, NUM_PARTICLES do
        local p = particles[i]
        kage.fillCircle(p.x, p.y, p.size)
    end

    -- テキスト描画
    c = colors.white

    kage.setRGB(c[1], c[2], c[3])
    kage.drawText(10, 30, "osga:kage gfx test")

    -- FPSを右上に表示
    kage.drawFPS(240, 20)
    kage.sendBuffer()
end
