-- apps/buddha/main.lua
local app = {}
app._meta = {
    name = "Buddha",
    slug = "buddha",
    author = "Leo Kuroshita",
    version = "1.0.0"
}

local buddha = {
    parameters = {
        { name = "SUTRA",  value = 1,  min = 1, max = 3,   step = 1 },
        { name = "VOLUME", value = 50, min = 0, max = 100, step = 1 }
    },
    manuals = {
        { icon = "A", rule = "PLAY/STOP" },
    },
    field = {
        x = 0,
        y = 0,
        width = 240,
        height = 240
    },
    selected_parameter = 1,
    sound = {},
    patterns = {},
    lastButtonStates = {
        swA = false,
        swB = false,
        swR = false
    },
    isPlaying = false,
    currentSutra = 1
}


local function createPattern()
    return {
        segments = math.random(6, 12),
        radius = math.random(20, 80),
        innerRadius = math.random(10, 40),
        rotation = math.random() * math.pi * 2,
        speed = (math.random() - 0.5) * 0.02,
        alpha = 1.0,
        fadeSpeed = 0.002,
        points = math.random(3, 8)
    }
end


local function drawPattern(pattern)
    local cx = buddha.field.width / 2
    local cy = buddha.field.height / 2

    osga.gfx.push()
    osga.gfx.translate(cx, cy)
    osga.gfx.rotate(pattern.rotation)


    for r = pattern.innerRadius, pattern.radius, 10 do
        for i = 1, pattern.segments do
            local angle = (i - 1) * (2 * math.pi / pattern.segments)
            local nextAngle = i * (2 * math.pi / pattern.segments)


            local x1 = math.cos(angle) * r
            local y1 = math.sin(angle) * r
            local x2 = math.cos(nextAngle) * r
            local y2 = math.sin(nextAngle) * r

            osga.gfx.line(x1, y1, x2, y2)


            if r > pattern.innerRadius then
                local innerR = r - 10
                local ix1 = math.cos(angle) * innerR
                local iy1 = math.sin(angle) * innerR
                osga.gfx.line(x1, y1, ix1, iy1)
            end
        end
    end

    osga.gfx.pop()
end


local function initializeSound()
    buddha.sound.sutras = {}
    for i = 1, 3 do
        local path = string.format("apps/buddha/src/sounds/buddha%d.wav", i)
        print("Loading sutra:", path)
        local file = io.open(path, "rb")
        if file then
            local data = file:read("*all")
            file:close()
            local fileData = love.filesystem.newFileData(data, path)
            local soundData = love.sound.newSoundData(fileData)
            local source = love.audio.newSource(soundData)
            source:setLooping(true)
            table.insert(buddha.sound.sutras, source)
            print("Loaded sutra", i)
        else
            print("Failed to load sutra", i)
        end
    end
end


local function drawParameters()
    osga.gfx.color(0, 0, 0, 1)
    osga.gfx.rect(buddha.field.width, 0, 80, buddha.field.height)

    osga.gfx.color(1, 1, 1)


    for i, param in ipairs(buddha.parameters) do
        local y = 20 + (i - 1) * 30
        local x = buddha.field.width + 10

        if i == buddha.selected_parameter then
            osga.gfx.text(">", x - 10, y)
        end

        osga.gfx.text(param.name, x, y)
        osga.gfx.text(tostring(param.value), x + 10, y + 15)
    end


    local guideY = buddha.field.height - 60
    for i, manual in ipairs(buddha.manuals) do
        local y = guideY + (i - 1) * 20
        osga.gfx.text(manual.icon .. " " .. manual.rule, buddha.field.width + 10, y)
    end
end


function app.init()
    math.randomseed(os.time())
    initializeSound()


    for i = 1, 3 do
        table.insert(buddha.patterns, createPattern())
    end
end

function app.draw(koto)
    osga.gfx.clear(0, 0, 0)


    osga.gfx.color(1, 1, 1, 1)


    for i = #buddha.patterns, 1, -1 do
        local pattern = buddha.patterns[i]
        pattern.rotation = pattern.rotation + pattern.speed
        pattern.alpha = pattern.alpha - pattern.fadeSpeed

        if pattern.alpha <= 0 then
            table.remove(buddha.patterns, i)
        else
            osga.gfx.color(1, 1, 1, pattern.alpha)
            drawPattern(pattern)
        end
    end


    if #buddha.patterns < 5 and math.random() < 0.02 then
        table.insert(buddha.patterns, createPattern())
    end


    if koto.swA and not buddha.lastButtonStates.swA then
        buddha.isPlaying = not buddha.isPlaying
        if buddha.isPlaying then
            local currentSutra = buddha.sound.sutras[buddha.parameters[1].value]
            if currentSutra then
                osga.sound.playSource(currentSutra)
                osga.sound.setSourceVolume(currentSutra, buddha.parameters[2].value / 100)
            end
        else
            for _, sutra in ipairs(buddha.sound.sutras) do
                osga.sound.stopSource(sutra)
            end
        end
    end


    if koto.swR and not buddha.lastButtonStates.swR then
        buddha.selected_parameter = buddha.selected_parameter + 1
        if buddha.selected_parameter > #buddha.parameters then
            buddha.selected_parameter = 1
        end
    end


    if koto.rotaryInc or koto.rotaryDec then
        local param = buddha.parameters[buddha.selected_parameter]
        if koto.rotaryInc then
            param.value = math.min(param.value + param.step, param.max)
        else
            param.value = math.max(param.value - param.step, param.min)
        end


        if buddha.isPlaying then
            if buddha.selected_parameter == 1 then
                for _, sutra in ipairs(buddha.sound.sutras) do
                    osga.sound.stopSource(sutra)
                end

                local newSutra = buddha.sound.sutras[param.value]
                if newSutra then
                    osga.sound.playSource(newSutra)
                    osga.sound.setSourceVolume(newSutra, buddha.parameters[2].value / 100)
                end
            elseif buddha.selected_parameter == 2 then
                local currentSutra = buddha.sound.sutras[buddha.parameters[1].value]
                if currentSutra then
                    osga.sound.setSourceVolume(currentSutra, param.value / 100)
                end
            end
        end
    end


    drawParameters()


    buddha.lastButtonStates.swA = koto.swA
    buddha.lastButtonStates.swB = koto.swB
    buddha.lastButtonStates.swR = koto.swR
end

function app.cleanup()
    for _, sutra in ipairs(buddha.sound.sutras) do
        osga.sound.stopSource(sutra)
    end
end

return app
