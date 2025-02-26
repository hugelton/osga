-- osga-sim/topbar.lua
local topbar = {
    hdpi = false,
    scale = 2,
    gyroEnabled = true,
    hoveredButton = nil,
    gyroX = 0,
    gyroY = 0
}

function topbar.init()
    topbar.updateButtonPositions()
    topbar.appInfo = nil


    love.window.setMode(640, 520, { highdpi = false })
end

function topbar.updateButtonPositions()
    if topbar.scale == 1 then
        topbar.buttons = {
            hdpi = { x = 10, y = 40, w = 60, h = 20 },
            scale = { x = 80, y = 40, w = 60, h = 20 },
            gyro = { x = 150, y = 40, w = 60, h = 20 }
        }
    else
        topbar.buttons = {
            hdpi = { x = 260, y = 20 / 2, w = 60, h = 20 },
            scale = { x = 330, y = 20 / 2, w = 60, h = 20 },
            gyro = { x = 400, y = 20 / 2, w = 60, h = 20 }
        }
    end
end

function topbar.setAppInfo(info)
    topbar.appInfo = info
    if info and info.name then
        love.window.setTitle(string.format("osga-sim - %s", info.name))
    else
        love.window.setTitle("osga-sim")
    end
end

function topbar.mousemoved(x, y)
    local sx = x
    local sy = y




    topbar.hoveredButton = nil
    for name, btn in pairs(topbar.buttons) do
        if sx >= btn.x and sx <= btn.x + btn.w and
            sy >= btn.y and sy <= btn.y + btn.h then
            topbar.hoveredButton = name
            break
        end
    end
end

function topbar.mousepressed(x, y, button)
    local sx = x
    local sy = y

    for name, btn in pairs(topbar.buttons) do
        if sx >= btn.x and sx <= btn.x + btn.w and
            sy >= btn.y and sy <= btn.y + btn.h then
            if name == "hdpi" then
                topbar.hdpi = not topbar.hdpi
                love.window.setMode(topbar.scale == 1 and 320 or 640,
                    topbar.scale == 1 and 320 or 520,
                    { highdpi = topbar.hdpi })
            elseif name == "gyro" then
                topbar.gyroEnabled = not topbar.gyroEnabled
            elseif name == "scale" then
                topbar.scale = topbar.scale == 1 and 2 or 1
                topbar.updateButtonPositions()
                love.window.setMode(topbar.scale == 1 and 320 or 640,
                    topbar.scale == 1 and 320 or 520,
                    { highdpi = topbar.hdpi })
            end
            break
        end
    end
end

function topbar.draw()
    love.graphics.push()
    love.graphics.origin()


    love.graphics.setColor(20 / 255, 20 / 255, 20 / 255)
    local topbarHeight = topbar.scale == 1 and 50 or 40
    love.graphics.rectangle("fill", 0, 0, love.graphics.getWidth(), topbarHeight)





    love.graphics.setColor(1, 1, 1)
    local stats = string.format("FPS: %d", love.timer.getFPS())
    if topbar.appInfo and topbar.appInfo.name then
        stats = stats .. string.format(" | %s", topbar.appInfo.name)
    end
    love.graphics.print(stats, 10, 10)


    local function drawButton(btn, text, active)
        local isHovered = topbar.hoveredButton == btn
        local color = active and 1 or 0.5
        love.graphics.setColor(isHovered and 0.7 or color, isHovered and 0.7 or color, isHovered and 0.7 or color)
        love.graphics.rectangle("line",
            topbar.buttons[btn].x,
            topbar.buttons[btn].y,
            topbar.buttons[btn].w,
            topbar.buttons[btn].h)
        love.graphics.print(text,
            topbar.buttons[btn].x + 5,
            topbar.buttons[btn].y + 2)
    end

    drawButton("hdpi", "HDPI " .. (topbar.hdpi and "on" or "off"), topbar.hdpi)
    drawButton("gyro", "Gyro " .. (topbar.gyroEnabled and "on" or "off"), topbar.gyroEnabled)
    drawButton("scale", "x" .. topbar.scale, topbar.scale == 2)


    love.graphics.setColor(1, 1, 1)
    love.graphics.print(
        string.format("X:%.2f Y:%.2f", topbar.gyroX, topbar.gyroY),
        topbar.buttons.gyro.x + topbar.buttons.gyro.w + 10,
        topbar.buttons.gyro.y + 2
    )

    love.graphics.pop()
end

function topbar.getScale()
    return topbar.scale
end

function topbar.isGyroEnabled()
    return topbar.gyroEnabled
end

function topbar.getHeight()
    return topbar.scale == 1 and 50 or 40
end

function topbar.setGyroValues(x, y)
    topbar.gyroX = x
    topbar.gyroY = y
end

return topbar
