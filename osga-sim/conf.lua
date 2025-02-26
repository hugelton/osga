-- osga-sim/conf.lua
function love.conf(t)
    t.console = true
    t.window.title = "osga-sim"
    t.window.icon = "src/icon.png"
    t.window.width = 640
    t.window.height = 520
    t.window.vsync = 1
    t.window.highdpi = true
    t.window.usedpiscale = true
end
