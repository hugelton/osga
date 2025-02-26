-- osga/osga-sim/api/system.lua

local system = {
    -- Display constants
    width = 320,
    height = 240,

    -- System info
    name = "OSGA",
    version = "1.0.0",
    model = "simulator",
    fps = 60,

    -- System utilities
    getTime = function()
        return love.timer.getTime()
    end,

    sleep = function(s)
        love.timer.sleep(s)
    end,

    getFPS = function()
        return love.timer.getFPS()
    end,

    getDelta = function()
        return love.timer.getDelta()
    end
}

return system
