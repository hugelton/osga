-- osga/api/init.lua

-- パス設定 (前もって設定されていなければ)
if not package.path:match("../?.lua") then
    package.path = "../?.lua;../?/init.lua;" .. package.path
end

-- Import modules
local system = require('api.system')
local gfx = require('api.gfx')
local sound = require('api.sound.init') -- 明示的にinit.luaを指定
local font = require('api.font')        -- 自動的に初期化される

-- Create global OSGA API
osga = {
    -- System information and utilities
    system = system,

    -- Graphics API
    gfx = gfx,

    -- Sound API
    sound = sound,

    -- Font API
    font = font,

    -- Path configuration (will be set during initialization)
    paths = {
        root = nil,
        runtime = nil,
        sim = nil
    },

    -- Initialize the OSGA system
    configurePaths = function()
        -- Get the source directory
        local sourceDir = love.filesystem.getSource()

        -- Determine which environment we're in
        if sourceDir:match("osga%-run$") then
            -- We're in osga-run folder
            osga.paths.runtime = sourceDir
            -- Go up one level to get root
            osga.paths.root = sourceDir:match("(.+)/osga%-run$")
        elseif sourceDir:match("osga%-sim$") then
            -- We're in osga-sim folder
            osga.paths.sim = sourceDir
            -- Go up one level to get root
            osga.paths.root = sourceDir:match("(.+)/osga%-sim$")
        else
            -- If we can't determine, use current directory
            osga.paths.root = sourceDir
            print("Warning: Could not determine OSGA root path, using current directory")
        end

        -- デバッグ出力
        print("OSGA paths configured:")
        print("Root:", osga.paths.root)
        if osga.paths.sim then print("Sim:", osga.paths.sim) end
        if osga.paths.runtime then print("Runtime:", osga.paths.runtime) end
    end
}

return osga
