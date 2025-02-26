-- osga-run/main.lua
-- Osga Runtime
-- by Leo Kuroshita from Hugelton Instruments. 2025
package.path = "../?.lua;../?/init.lua;" .. package.path


require('api/init')


osga.configurePaths()

local canvas = nil
local currentApp = nil
local isLoading = false
local loadingDots = 0
local loadingTimer = 0


local width = love.graphics.getWidth()
local height = love.graphics.getHeight()
print("Window size: " .. width .. "x" .. height)
love.mouse.setVisible(false)

koto = {
    swA = false,
    swB = false,
    swC = false,
    swR = false,
    rotaryValue = 0,
    rotaryInc = false,
    rotaryDec = false,
    rotaryTicks = 0,
    gyroX = 0,
    gyroY = 0,
    gyroZ = 0.5,
    button = {
        back = false
    }
}


local rotaryState = {
    value = 0,
    ticks = 0,
    lastProcessedTick = 0,
    needsReset = false
}




function loadApp(appPath)
    isLoading = true
    print("Loading app from:", appPath)


    love.graphics.setCanvas(canvas)
    love.graphics.clear()
    love.graphics.setColor(1, 1, 1)
    local dots = string.rep(".", loadingDots)
    love.graphics.print("Loading" .. dots, osga.system.width / 2 - 30, osga.system.height / 2)
    love.graphics.setCanvas()


    love.graphics.draw(canvas, 0, 20)
    love.graphics.present()

    if currentApp and currentApp.cleanup then
        currentApp.cleanup()
    end


    local mainPath = appPath
    if not mainPath:match("%.lua$") then
        mainPath = appPath .. "/main.lua"
    end

    local fullPath = osga.paths.root .. "/" .. mainPath
    print("Loading from full path:", fullPath)


    local file = io.open(fullPath, "r")
    if not file then
        print("Error: Cannot read main.lua at " .. fullPath)
        isLoading = false
        return false
    end
    local content = file:read("*all")
    file:close()



    local chunk, err = load(content, fullPath, "t")
    if not chunk then
        print("Failed to load app:", err)
        isLoading = false
        return false
    end


    local ok, app = pcall(chunk)
    if not ok then
        print("Failed to run app:", app)
        isLoading = false
        return false
    end


    if type(app) ~= "table" or not app._meta then
        print("Invalid app structure: missing _meta")
        isLoading = false
        return false
    end


    currentApp = app
    if currentApp.init then
        local ok, err = pcall(currentApp.init)
        if not ok then
            print("Failed to initialize app:", err)
            isLoading = false
            return false
        end
    end


    isLoading = false
    return true
end

function love.load(args)
    love.graphics.setBackgroundColor(20 / 255, 20 / 255, 20 / 255)
    canvas = love.graphics.newCanvas(osga.system.width, osga.system.height)
    love.graphics.setDefaultFilter('nearest', 'nearest')


    if args[1] then
        loadApp(args[1])
    else
        loadApp("apps/kumo")
    end
end

function love.update(dt)
    if love.timer then love.timer.sleep(0.006) end

    if isLoading then
        loadingTimer = loadingTimer + 1
        if loadingTimer > 10 then
            loadingTimer = 0
            loadingDots = (loadingDots + 1) % 4
        end
    end
    osga.sound.update()

    local mx, my = love.mouse.getPosition()


    if mx >= 0 and mx <= osga.system.width and my >= 80 and my <= 320 then
        koto.gyroX = ((mx / (osga.system.width / 2)) - 1) * 2
        koto.gyroY = (((my - 80) / 120) - 1) * 2
        koto.gyroX = math.max(-2.0, math.min(2.0, koto.gyroX))
        koto.gyroY = math.max(-2.0, math.min(2.0, koto.gyroY))
    end







    if rotaryState.ticks ~= rotaryState.lastProcessedTick then
        if rotaryState.ticks > rotaryState.lastProcessedTick then
            koto.rotaryInc = true
            koto.rotaryDec = false
            koto.rotaryTicks = 1
        else
            koto.rotaryInc = false
            koto.rotaryDec = true
            koto.rotaryTicks = -1
        end
        rotaryState.needsReset = true
        rotaryState.lastProcessedTick = rotaryState.ticks
    elseif rotaryState.needsReset then
        koto.rotaryInc = false
        koto.rotaryDec = false
        koto.rotaryTicks = 0
        rotaryState.needsReset = false
    end


    if koto.button.back then
        if currentApp and currentApp._meta.slug ~= "kumo" then
            loadApp("apps/kumo")
        end
    end
end

function love.draw()
    if isLoading then
        love.graphics.setCanvas(canvas)
        love.graphics.clear()
        love.graphics.setColor(1, 1, 1)



        local dots = string.rep(".", loadingDots)
        love.graphics.print(
            "Loading" .. dots,
            osga.system.width / 2 - (30),
            osga.system.height / 2,
            0,
            1, 1
        )
        love.graphics.setCanvas()


        love.graphics.push()
        love.graphics.scale(1, 1)

        love.graphics.draw(canvas, 0, 0)
        love.graphics.pop()
        return
    end






    love.graphics.setColor(1, 1, 1)
    love.graphics.setCanvas(canvas)
    love.graphics.clear()
    love.graphics.setFont(osga.font.getNada())


    if currentApp and currentApp.draw then
        local ok, err = pcall(currentApp.draw, koto)
        if not ok then
            love.graphics.setColor(1, 0, 0)
            love.graphics.printf("Error in app.draw: " .. err, 10, 10, 300, "left")
            print("Error in app.draw: " .. err)
        end
    else
        love.graphics.setColor(1, 1, 1)
        love.graphics.printf(
            "No app loaded\nUsage: love sim path/to/app",
            0, 100, osga.system.width, "center"
        )
    end


    love.graphics.setCanvas()
    love.graphics.push()
    love.graphics.scale(1, 1)


    love.graphics.draw(canvas, 0, 0)

    love.graphics.pop()
    love.graphics.setFont(osga.font.getNada())
end

function love.keypressed(key)
    if key == 'a' then
        koto.swA = true
    elseif key == 's' then
        koto.swB = true
    elseif key == 'd' then
        koto.swC = true
    elseif key == 'space' then
        koto.swR = true
    elseif key == 'escape' then
        koto.button.back = true
    end
end

function love.keyreleased(key)
    if key == 'a' then
        koto.swA = false
    elseif key == 's' then
        koto.swB = false
    elseif key == 'd' then
        koto.swC = false
    elseif key == 'space' then
        koto.swR = false
    elseif key == 'escape' then
        koto.button.back = false
    elseif key == 'left' then
        rotaryState.ticks = rotaryState.ticks - 1
    elseif key == 'right' then
        rotaryState.ticks = rotaryState.ticks + 1
    end
end

function love.wheelmoved(x, y)
    rotaryState.value = (rotaryState.value + y) % 360
    if rotaryState.value < 0 then
        rotaryState.value = rotaryState.value + 360
    end
    koto.rotaryValue = rotaryState.value

    if y > 0 then
        rotaryState.ticks = rotaryState.ticks + 1
    elseif y < 0 then
        rotaryState.ticks = rotaryState.ticks - 1
    end
end

function love.quit()
    if currentApp and currentApp.cleanup then
        currentApp.cleanup()
    end
end
