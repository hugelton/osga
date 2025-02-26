-- apps/yoru/main.lua
local app = {}
app._meta = {
    name = "Yoru",
    slug = "yoru",
    author = "OSGA Developer",
    version = "1.0.0"
}


local yoru = {
    parameters = {
        { name = "TIME",      value = 50, min = 0, max = 100, step = 1 },
        { name = "HUMIDITY",  value = 50, min = 0, max = 100, step = 1 },
        { name = "WIND",      value = 10, min = 0, max = 100, step = 1 },
        { name = "MOONLIGHT", value = 50, min = 0, max = 100, step = 5 }
    },
    manuals = {
        { icon = "A", rule = "OWL" },
        { icon = "B", rule = "FROG" },
        { icon = "R", rule = "SELECT" },
    },
    selected_parameter = 1,
    lastButtonStates = {
        swA = false,
        swB = false,
        swC = false,
        swR = false
    },
    soundSources = {
        owls = {},
        frogs = {},
        crickets = {},
    },
    channels = {
        owlChannel = nil,
        frogChannel = nil,
        cricketChannel = nil,
        windChannel = nil
    },
    activeOwls = {},
    activeFrogs = {},
    moonPhase = 0,
    stars = {},
    visualObjects = {},
    windParticles = {}
}


local NUM_STARS = 50
local SCREEN_WIDTH = 240
local SCREEN_HEIGHT = 240
local MAX_WIND_PARTICLES = 20
local MAX_VISUAL_OBJECTS = 15


local USE_SAMPLES = false


local function getFilePath(filename)
    return "apps/yoru/" .. filename
end


local function initializeSound()
    yoru.channels.owlChannel = osga.sound.channel.new()


    yoru.channels.frogChannel = osga.sound.channel.new()


    yoru.channels.cricketChannel = osga.sound.channel.new()


    yoru.channels.windChannel = osga.sound.channel.new()
    local windNoise = osga.sound.synth.newNoise('pink')
    local windFilter = osga.sound.filter.new("lowpass", {
        frequency = 300,
        q = 0.7
    })
    yoru.channels.windChannel:addSource(windNoise)
    yoru.channels.windChannel:addEffect(windFilter)


    if not USE_SAMPLES then
        local owlSource = osga.sound.synth.newOscillator('sine', 400)
        table.insert(yoru.soundSources.owls, owlSource)


        local frogSource = osga.sound.synth.newOscillator('square', 120)
        table.insert(yoru.soundSources.frogs, frogSource)


        local cricketSource = osga.sound.synth.newOscillator('triangle', 1200)
        table.insert(yoru.soundSources.crickets, cricketSource)
    end


    if #yoru.soundSources.crickets > 0 then
        yoru.channels.cricketChannel:addSource(yoru.soundSources.crickets[1])
    end


    osga.sound.addChannel(yoru.channels.owlChannel)
    osga.sound.addChannel(yoru.channels.frogChannel)
    osga.sound.addChannel(yoru.channels.cricketChannel)
    osga.sound.addChannel(yoru.channels.windChannel)


    yoru.channels.windChannel:play()


    yoru.channels.cricketChannel:play()
end


local function playOwlSound()
    if #yoru.soundSources.owls == 0 then
        return
    end


    local randomOwlIndex = math.random(#yoru.soundSources.owls)
    local owlSource = yoru.soundSources.owls[randomOwlIndex]


    yoru.channels.owlChannel = osga.sound.channel.new()
    yoru.channels.owlChannel:addSource(owlSource)
    osga.sound.addChannel(yoru.channels.owlChannel)


    local timeOfDay = yoru.parameters[1].value / 100
    yoru.channels.owlChannel.volume = 0.8 + (timeOfDay * 0.2)


    yoru.channels.owlChannel:play()


    local x = math.random(50, SCREEN_WIDTH - 50)
    local y = math.random(30, 80)
    table.insert(yoru.visualObjects, {
        type = "owl",
        x = x,
        y = y,
        size = math.random(3, 6),
        alpha = 1.0,
        fadeRate = 0.01,
        duration = 100
    })
end


local function playFrogSound()
    if #yoru.soundSources.frogs == 0 then
        return
    end


    local randomFrogIndex = math.random(#yoru.soundSources.frogs)
    local frogSource = yoru.soundSources.frogs[randomFrogIndex]


    yoru.channels.frogChannel = osga.sound.channel.new()
    yoru.channels.frogChannel:addSource(frogSource)
    osga.sound.addChannel(yoru.channels.frogChannel)


    local humidity = yoru.parameters[2].value / 100
    yoru.channels.frogChannel.volume = humidity


    yoru.channels.frogChannel:play()


    local x = math.random(20, SCREEN_WIDTH - 20)
    local y = math.random(SCREEN_HEIGHT - 60, SCREEN_HEIGHT - 20)
    table.insert(yoru.visualObjects, {
        type = "grass",
        x = x,
        y = y,
        width = math.random(10, 20),
        height = math.random(5, 15),
        alpha = 0.8,
        fadeRate = 0.02,
        duration = 30
    })
end


local function initializeStars()
    yoru.stars = {}
    for i = 1, NUM_STARS do
        table.insert(yoru.stars, {
            x = math.random(0, SCREEN_WIDTH),
            y = math.random(0, 100),
            size = math.random() > 0.8 and 2 or 1,
            brightness = 0.3 + math.random() * 0.7,
            twinkleRate = 0.2 + math.random() * 0.5
        })
    end
end


local function initializeWindParticles()
    yoru.windParticles = {}
    for i = 1, MAX_WIND_PARTICLES do
        table.insert(yoru.windParticles, {
            x = math.random(0, SCREEN_WIDTH),
            y = math.random(100, SCREEN_HEIGHT - 50),
            length = math.random(5, 15),
            speed = 1 + math.random() * 3,
            alpha = 0.1 + math.random() * 0.3
        })
    end
end


local function updateVisualObjects()
    for i = #yoru.visualObjects, 1, -1 do
        local obj = yoru.visualObjects[i]

        if obj.type == "grass" then
            obj.duration = obj.duration - 1
            obj.alpha = obj.alpha - obj.fadeRate


            if obj.duration <= 0 or obj.alpha <= 0 then
                table.remove(yoru.visualObjects, i)
            end
        elseif obj.type == "owl" then
            obj.duration = obj.duration - 1
            if obj.duration % 30 < 15 then
                obj.alpha = 0.8
            else
                obj.alpha = 0.4
            end


            if obj.duration <= 0 then
                table.remove(yoru.visualObjects, i)
            end
        end
    end


    local timeOfDay = yoru.parameters[1].value / 100
    local humidity = yoru.parameters[2].value / 100


    if timeOfDay > 0.3 and math.random() < 0.001 * timeOfDay * 5 then
        playOwlSound()
    end


    if humidity > 0.2 and math.random() < 0.001 * humidity * 5 then
        playFrogSound()
    end
end


local function updateWindParticles()
    local windStrength = yoru.parameters[3].value / 100

    for i, particle in ipairs(yoru.windParticles) do
        particle.x = particle.x + particle.speed * windStrength


        if particle.x > SCREEN_WIDTH + particle.length then
            particle.x = -particle.length
            particle.y = math.random(100, SCREEN_HEIGHT - 50)
        end
    end


    if yoru.channels.windChannel then
        yoru.channels.windChannel.volume = windStrength * 0.8
    end
end


local function drawNightScene()
    local timeOfDay = yoru.parameters[1].value / 100
    local skyColorTop = { 0.05, 0.05, 0.15 }
    local skyColorBottom


    if timeOfDay < 0.3 then
        skyColorBottom = { 0.2, 0.1, 0.2 }
    elseif timeOfDay > 0.7 then
        skyColorBottom = { 0.15, 0.1, 0.2 }
    else
        skyColorBottom = { 0.1, 0.1, 0.2 }
    end


    for y = 0, 100 do
        local ratio = y / 100
        local r = skyColorTop[1] * (1 - ratio) + skyColorBottom[1] * ratio
        local g = skyColorTop[2] * (1 - ratio) + skyColorBottom[2] * ratio
        local b = skyColorTop[3] * (1 - ratio) + skyColorBottom[3] * ratio

        osga.gfx.color(r, g, b)
        osga.gfx.line(0, y, SCREEN_WIDTH, y)
    end


    for _, star in ipairs(yoru.stars) do
        local moonLight = yoru.parameters[4].value / 100
        local brightnessFactor = 1.0 - (moonLight * 0.5)
        local twinkle = math.abs(math.sin(osga.system.getTime() * star.twinkleRate)) * 0.3 + 0.7
        local finalBrightness = star.brightness * brightnessFactor * twinkle

        osga.gfx.color(0.9, 0.9, 1.0, finalBrightness)
        if star.size == 1 then
            osga.gfx.circle(star.x, star.y, 1)
        else
            osga.gfx.circle(star.x, star.y, 1.5)
        end
    end


    local moonLight = yoru.parameters[4].value / 100
    yoru.moonPhase = (yoru.moonPhase + 0.0001) % (math.pi * 2)
    local moonX = 180
    local moonY = 50
    local moonRadius = 15
    local moonVisibility = 0.5 + moonLight * 0.5


    osga.gfx.color(0.9, 0.9, 0.8, moonVisibility)
    osga.gfx.circle(moonX, moonY, moonRadius)


    osga.gfx.color(0.05, 0.05, 0.15)
    osga.gfx.circle(moonX + 8, moonY, moonRadius - 1)


    local horizonY = 120


    local mountains = {
        { color = { 0.1, 0.1, 0.12 },   height = 40, detail = 5 },
        { color = { 0.08, 0.08, 0.1 },  height = 30, detail = 8 },
        { color = { 0.06, 0.06, 0.08 }, height = 20, detail = 10 }
    }

    for _, mountain in ipairs(mountains) do
        osga.gfx.color(mountain.color[1], mountain.color[2], mountain.color[3])


        local points = {}
        local numSegments = SCREEN_WIDTH / mountain.detail

        for i = 0, numSegments do
            local x = i * mountain.detail

            local heightVariation = math.sin(i * 0.3) * 0.5 +
                math.sin(i * 0.7) * 0.3 +
                math.sin(i * 1.1) * 0.2
            local y = horizonY - mountain.height * (0.5 + heightVariation * 0.5)
            table.insert(points, { x = x, y = y })
        end


        for i = 1, #points - 1 do
            osga.gfx.line(points[i].x, points[i].y, points[i + 1].x, points[i + 1].y)


            for y = points[i].y, horizonY do
                osga.gfx.line(points[i].x, y, points[i].x, y)
            end
        end
    end


    osga.gfx.color(0.04, 0.04, 0.06)
    osga.gfx.rect(0, horizonY, SCREEN_WIDTH, SCREEN_HEIGHT - horizonY)


    local windStrength = yoru.parameters[3].value / 100
    osga.gfx.color(0.9, 0.9, 1.0, 0.3 * windStrength)
    for _, particle in ipairs(yoru.windParticles) do
        osga.gfx.line(particle.x, particle.y,
            particle.x + particle.length * windStrength, particle.y)
    end


    for _, obj in ipairs(yoru.visualObjects) do
        if obj.type == "grass" then
            osga.gfx.color(0.2, 0.3, 0.1, obj.alpha)
            for i = 0, obj.width, 2 do
                local height = obj.height * math.sin((i + osga.system.getTime() * 50) * 0.2) * 0.3 + obj.height
                osga.gfx.line(obj.x + i, obj.y, obj.x + i, obj.y - height)
            end
        elseif obj.type == "owl" then
            osga.gfx.color(0.9, 0.8, 0.2, obj.alpha)
            local eyeSpacing = obj.size * 2
            osga.gfx.circle(obj.x - eyeSpacing, obj.y, obj.size)
            osga.gfx.circle(obj.x + eyeSpacing, obj.y, obj.size)
        end
    end


    osga.gfx.color(0.05, 0.1, 0.05)
    for i = 0, SCREEN_WIDTH, 3 do
        local height = 5 + 10 * math.sin(i * 0.1) * math.sin(i * 0.05 + osga.system.getTime())
        osga.gfx.line(i, SCREEN_HEIGHT, i, SCREEN_HEIGHT - height)
    end
end


local function drawParameters()
    osga.gfx.color(0, 0, 0, 0.7)
    osga.gfx.rect(SCREEN_WIDTH, 0, 80, SCREEN_HEIGHT)

    osga.gfx.color(1, 1, 1)


    for i, param in ipairs(yoru.parameters) do
        local y = 20 + (i - 1) * 30
        local x = SCREEN_WIDTH + 5

        if i == yoru.selected_parameter then
            osga.gfx.text(">", x - 5, y)
        end

        osga.gfx.text(param.name, x, y)
        osga.gfx.text(tostring(param.value), x + 10, y + 15)
    end


    local guideY = SCREEN_HEIGHT - 80
    for i, manual in ipairs(yoru.manuals) do
        local y = guideY + (i - 1) * 20
        osga.gfx.text(manual.icon .. " " .. manual.rule, SCREEN_WIDTH + 5, y)
    end
end


function app.init()
    print("Initializing Yoru application...")


    initializeStars()
    initializeWindParticles()
    initializeSound()
end

function app.draw(koto)
    osga.gfx.clear(0, 0, 0)


    updateVisualObjects()
    updateWindParticles()


    drawNightScene()


    if koto.swA and not yoru.lastButtonStates.swA then
        playOwlSound()
    end

    if koto.swB and not yoru.lastButtonStates.swB then
        playFrogSound()
    end


    if koto.swR and not yoru.lastButtonStates.swR then
        yoru.selected_parameter = yoru.selected_parameter + 1
        if yoru.selected_parameter > #yoru.parameters then
            yoru.selected_parameter = 1
        end
    end


    if koto.rotaryInc then
        local param = yoru.parameters[yoru.selected_parameter]
        param.value = math.min(param.value + param.step, param.max)
    elseif koto.rotaryDec then
        local param = yoru.parameters[yoru.selected_parameter]
        param.value = math.max(param.value - param.step, param.min)
    end


    local timeOfDay = yoru.parameters[1].value / 100
    if yoru.channels.cricketChannel then
        yoru.channels.cricketChannel.volume = 0.2 + (timeOfDay * 0.6)
    end


    drawParameters()


    yoru.lastButtonStates.swA = koto.swA
    yoru.lastButtonStates.swB = koto.swB
    yoru.lastButtonStates.swR = koto.swR
end

function app.cleanup()
    for _, channel in pairs(yoru.channels) do
        if channel then
            channel:stop()
            osga.sound.removeChannel(channel)
        end
    end

    print("Yoru application cleaned up")
end

return app
