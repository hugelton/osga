-- osga/osga-sim/api/gfx.lua

local gfx = {
    -- Basic drawing functions
    clear = function(r, g, b)
        if type(r) == "table" then
            love.graphics.clear(r[1] or 0, r[2] or 0, r[3] or 0, r[4] or 1)
        else
            love.graphics.clear(r or 0, g or 0, b or 0, 1)
        end
    end,

    -- Shape drawing
    rect = function(x, y, w, h, mode)
        love.graphics.rectangle(mode or "fill", x, y, w, h)
    end,

    circle = function(x, y, radius, mode)
        love.graphics.circle(mode or "fill", x, y, radius)
    end,
    ellipse = function(x, y, width, height, mode)
        love.graphics.ellipse(mode or "line", x, y, width / 2, height / 2)
    end,
    line = function(x1, y1, x2, y2)
        love.graphics.line(x1, y1, x2, y2)
    end,

    polygon = function(points, mode)
        love.graphics.polygon(mode or "fill", points)
    end,

    -- Color management
    color = function(r, g, b, a)
        if type(r) == "table" then
            love.graphics.setColor(r[1] or 0, r[2] or 0, r[3] or 0, r[4] or 1)
        else
            love.graphics.setColor(r or 0, g or 0, b or 0, a or 1)
        end
    end,

    -- Line styles
    lineWidth = function(width)
        love.graphics.setLineWidth(width)
    end,

    -- Transform operations
    push = function()
        love.graphics.push()
    end,

    pop = function()
        love.graphics.pop()
    end,

    translate = function(x, y)
        love.graphics.translate(x, y)
    end,

    rotate = function(angle)
        love.graphics.rotate(angle)
    end,

    scale = function(sx, sy)
        love.graphics.scale(sx, sy)
    end,

    -- Font operations
    setFont = function(font)
        love.graphics.setFont(font or fonts.getNada())
    end,

    getFont = function()
        return love.graphics.getFont()
    end,

    getNada = function()
        return fonts.getNada()
    end,

    getDefault = function()
        return fonts.getDefault()
    end,

    -- Text drawing
    text = function(text, x, y)
        love.graphics.print(text, x, y, 0, 1, 1, 0, 0)
    end,

    -- Image loading and drawing
    loadImage = function(path)
        local fullPath = osga.paths.root .. "/" .. path
        print("Trying to load image from:", fullPath) -- デバッグ用

        local file = io.open(fullPath, "rb")
        if file then
            local data = file:read("*all")
            file:close()

            local success, fileData = pcall(love.filesystem.newFileData, data, path)
            if success then
                local success2, image = pcall(love.graphics.newImage, fileData)
                if success2 then
                    print("Successfully loaded image:", path)
                    return image
                end
            end
        end
        print("Failed to load image:", path)
        return nil
    end,

    drawImage = function(image, x, y)
        if image then
            love.graphics.draw(image, x, y)
        end
    end
}

return gfx
