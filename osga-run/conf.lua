-- osga-run/conf.lua
function love.conf(t)
    t.console = true
    t.window.title = "osga-run"
    t.window.icon = "src/icon.png"
    t.window.width = 320
    t.window.height = 240
    t.window.vsync = 1
    t.window.highdpi = false
    t.window.usedpiscale = false
    -- t.window.fullscreen = true
    t.window.borderless = true
end
