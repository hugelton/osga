-- osga/api/font.lua

local font = {}

-- Character map for NADA font
local NADA_CHARS = "!\"#$%&'()*+,-./0123456789:;<=>? ABCDEFGHIJKLMNOPQRSTUVWXYZ[\\]^_`abcdefghijklmnopqrstuvwxyz{|}~"

-- Initialize fonts
function font.init()
    -- Default system font
    font.default = love.graphics.getFont()

    -- NADA font for OSGA - 絶対パスを使用
    local osRootPath = love.filesystem.getWorkingDirectory()
    local absolutePath = osRootPath .. "/api/fonts/nada.png"

    -- もし../が必要な場合（osga-sim/osga-runから実行）
    if not love.filesystem.getInfo("api/fonts/nada.png") then
        absolutePath = osRootPath .. "/../api/fonts/nada.png"
    end

    print("LOVE SourceDir:", love.filesystem.getSource())
    print("Working Dir:", love.filesystem.getWorkingDirectory())
    print("Absolute font path:", absolutePath)
    print("Current directory files:", love.filesystem.getDirectoryItems(""))
    print("File exists in current dir?", love.filesystem.getInfo("api/fonts/nada.png") ~= nil)
    print("File exists in parent dir?", love.filesystem.getInfo("../api/fonts/nada.png") ~= nil)

    -- ファイルを読み込み
    local imageData = nil
    local success = false

    -- まず、LÖVEのファイルシステムを使って読み込む
    if love.filesystem.getInfo("api/fonts/nada.png") then
        success, imageData = pcall(love.image.newImageData, "api/fonts/nada.png")
    elseif love.filesystem.getInfo("../api/fonts/nada.png") then
        success, imageData = pcall(love.image.newImageData, "../api/fonts/nada.png")
    else
        -- OSのファイルシステムから直接読み込む
        local fileData = nil
        success, fileData = pcall(function()
            local file = io.open(absolutePath, "rb")
            if not file then return nil end
            local data = file:read("*all")
            file:close()
            return love.filesystem.newFileData(data, "nada.png")
        end)

        if success and fileData then
            success, imageData = pcall(love.image.newImageData, fileData)
        end
    end

    -- フォント作成
    local nadaFont = nil
    if success and imageData then
        success, nadaFont = pcall(love.graphics.newImageFont, imageData, NADA_CHARS)
    end

    if success and nadaFont then
        nadaFont:setFilter("nearest", "nearest")
        font.nada = nadaFont
        print("NADA font loaded successfully")
    else
        print("Error loading NADA font:", nadaFont or "Could not load image data")
        font.nada = font.default
        -- フォールバックとして、固定サイズのフォントを使用
        font.nada = love.graphics.newFont(12)
    end
end

-- Get system default font
function font.getDefault()
    return font.default
end

-- Get NADA font
function font.getNada()
    return font.nada
end

-- 初期化を自動的に行う
font.init()

return font
