-- apps/shore/main.lua
local app = {}
app._meta = {
    name = "Shore",
    slug = "shore",
    author = "Leo Kuroshita",
    version = "1.0.0"
}


local shore = {
    parameters = {
        { name = "WAVE HEIGHT", value = 50,  min = 0,   max = 100, step = 1 },
        { name = "WAVE SPEED",  value = 20,  min = 1,   max = 60,  step = 1 },
        { name = "VOLUME",      value = 50,  min = 0,   max = 100, step = 1 },
        { name = "BOAT SIZE",   value = 3,   min = 1,   max = 3,   step = 1 },
        { name = "HORN ROOT",   value = 220, min = 100, max = 900, step = 1 },
    },
    manuals = {
        { icon = "A", rule = "BOAT HORN" },
    },
    field = {
        x = 0,
        y = 0,
        width = 240,
        height = 240
    },
    selected_parameter = 1,
    horizonY = 120,
    waveOffset = 0,
    waveSpeed = 1,
    wavesScrollY = 0,
    reflectionLines = nil,
    reflectionTimer = 0,
    seaLines = nil,
    seaLineTimer = 0,
    stars = nil,
    starTimer = 0,
    ships = {},
    sound = {},
    lastButtonStates = {
        swA = false,
        swB = false,
        swR = false
    },
    fps = 0,
    fpsUpdateTimer = 0
}

shore.sound.activeHorns = {}

local Ship = {}
Ship.__index = Ship

function Ship.new(size)
    local self = setmetatable({}, Ship)
    self.size = size
    local imagePath = "apps/shore/src/ship_" .. size .. ".png"
    self.image = osga.gfx.loadImage(imagePath)
    if not self.image then
        print("Could not load ship image:", imagePath)
    else
        print("Successfully loaded ship image:", imagePath)
    end
    self.x = -32
    self.y = 100
    self.speed = (10 - size) * 0.1
    self.isMoving = false
    return self
end

function Ship:update()
    if self.isMoving then
        self.x = self.x + self.speed
        if self.x > osga.system.width then
            self.isMoving = false
            self.x = -32
        end
    end
end

function Ship:draw()
    if self.x > -32 and self.x <= osga.system.width then
        osga.gfx.color(1, 1, 1)
        if self.image then
            osga.gfx.drawImage(self.image, self.x, self.y)
        else
            osga.gfx.rect(self.x, self.y, 32, 16)
        end
    end
end

local function initializeAnimations()
    shore.reflectionLines = {}
    local moonReflectionCount = 30
    for i = 1, moonReflectionCount do
        shore.reflectionLines[i] = {
            y = 140 + math.random(-10, 10),
            x = 120 + math.random(-10, 10),
            w = 20 + math.random(-2, 2)
        }
    end


    shore.seaLines = {}
    local seaLineCount = 50
    for i = 1, seaLineCount do
        shore.seaLines[i] = {
            y = shore.horizonY + math.random(0, shore.field.height - shore.horizonY),
            x = math.random(0, shore.field.width),
            w = 20 + math.random(-20, 20)
        }
    end


    shore.stars = {}
    local starCount = 40
    for i = 1, starCount do
        shore.stars[i] = {
            x = math.random(0, 240),
            y = math.random(0, 120)
        }
    end
end

local function initializeSound()
    shore.sound.waveLowChannel = osga.sound.channel.new()
    shore.sound.waveHighChannel = osga.sound.channel.new()
    shore.sound.hornChannel = osga.sound.channel.new()


    shore.sound.lowSynth = osga.sound.synth.newNoise('white')
    shore.sound.highSynth = osga.sound.synth.newNoise('white')


    shore.sound.lowFilter = osga.sound.filter.new('lowpass', {
        frequency = 200,
        q = 1.0
    })
    shore.sound.highFilter = osga.sound.filter.new('bandpass', {
        frequency = 1000,
        q = 2.0
    })


    shore.sound.waveLowChannel:addSource(shore.sound.lowSynth)
    shore.sound.waveLowChannel:addEffect(shore.sound.lowFilter)
    shore.sound.waveHighChannel:addSource(shore.sound.highSynth)
    shore.sound.waveHighChannel:addEffect(shore.sound.highFilter)


    osga.sound.addChannel(shore.sound.waveLowChannel)
    osga.sound.addChannel(shore.sound.waveHighChannel)
    osga.sound.addChannel(shore.sound.hornChannel)


    shore.sound.waveLowChannel:play()
    shore.sound.waveHighChannel:play()


    shore.sound.hornStartTime = 0
end


local function playHornSound(pitch, shipSize)
    local currentTime = osga.system.getTime()


    local pitchMultiplier = 1.0
    local decayTime = 1.0


    if shipSize == 1 then
        pitchMultiplier = 1.5
        decayTime = 0.6
    elseif shipSize == 2 then
        pitchMultiplier = 1.0
        decayTime = 0.8
    elseif shipSize == 3 then
        pitchMultiplier = 0.7
        decayTime = 1.2
    end


    local adjustedPitch = pitch * pitchMultiplier


    local hornChannel = osga.sound.channel.new()


    local hornMain = osga.sound.synth.newOscillator('sine', adjustedPitch)
    local hornSub = osga.sound.synth.newOscillator('sine', adjustedPitch * 0.5)


    local hornFilter = osga.sound.filter.new('lowpass', {
        frequency = adjustedPitch * 2,
        q = 4.0
    })


    hornChannel:addSource(hornMain)
    hornChannel:addSource(hornSub)
    hornChannel:addEffect(hornFilter)


    table.insert(shore.sound.activeHorns, {
        channel = hornChannel,
        startTime = currentTime,
        decayTime = decayTime,
        releaseStart = decayTime * 0.7
    })


    osga.sound.addChannel(hornChannel)
    hornChannel:play()
end


local function updateHornSound()
    local currentTime = osga.system.getTime()


    for i = #shore.sound.activeHorns, 1, -1 do
        local horn = shore.sound.activeHorns[i]
        local elapsed = currentTime - horn.startTime

        if elapsed > horn.decayTime then
            horn.channel:stop()
            osga.sound.removeChannel(horn.channel)
            table.remove(shore.sound.activeHorns, i)
        else
            local volume = 1.0
            if elapsed < 0.1 then
                volume = elapsed * 10
            elseif elapsed > horn.releaseStart then
                local releasePhase = (elapsed - horn.releaseStart) / (horn.decayTime - horn.releaseStart)
                volume = 1.0 - releasePhase
            end
            horn.channel.volume = volume
        end
    end
end


local function updateWaveSound(waveHeight, waveSpeed)
    if shore.sound.lowFilter then
        shore.sound.lowFilter.frequency = 100 + waveHeight * 2
        shore.sound.lowFilter:updateCoefficients()


        shore.sound.highFilter.frequency = 800 + waveSpeed * 10
        shore.sound.highFilter:updateCoefficients()
    end
end

local function updateAnimations()
    if shore.reflectionTimer >= 1 then
        shore.reflectionTimer = 0
        for i, line in ipairs(shore.reflectionLines) do
            if math.random() < 0.1 then
                line.y = 140 + math.random(-10, 10)
                line.x = 120 + math.random(-10, 10)
                line.w = 20 + math.random(-2, 2)
            end
        end
    end
    shore.reflectionTimer = shore.reflectionTimer + 1


    if shore.seaLineTimer >= 2 then
        shore.seaLineTimer = 0
        for i, line in ipairs(shore.seaLines) do
            if math.random() < 0.05 then
                line.y = shore.horizonY + math.random(0, shore.field.height - shore.horizonY)
                line.x = math.random(0, shore.field.width)
                line.w = 20 + math.random(-20, 20)
            end
        end
    end
    shore.seaLineTimer = shore.seaLineTimer + 1


    if shore.starTimer >= 30 then
        shore.starTimer = 0
        for i, star in ipairs(shore.stars) do
            if math.random() < 0.1 then
                star.x = math.random(0, 240)
                star.y = math.random(0, 120)
            end
        end
    end
    shore.starTimer = shore.starTimer + 1
end

local function drawSeaAnimation()
    osga.gfx.clear(0, 0, 0)


    osga.gfx.color(1, 1, 1)
    for _, star in ipairs(shore.stars) do
        osga.gfx.rect(star.x, star.y, 1, 1)
    end


    osga.gfx.color(1, 1, 1)
    osga.gfx.circle(120, 50, 15)
    osga.gfx.color(0, 0, 0)
    osga.gfx.circle(127, 45, 13)


    osga.gfx.color(1, 1, 1)
    osga.gfx.line(0, 115, 240, 115)


    osga.gfx.color(1, 1, 1)
    for _, line in ipairs(shore.reflectionLines) do
        osga.gfx.line(
            line.x - line.w / 2, line.y,
            line.x + line.w / 2, line.y
        )
    end


    for i, line in ipairs(shore.seaLines) do
        osga.gfx.color(1, 1, 1, 0.3)
        osga.gfx.line(
            line.x - line.w / 2, line.y,
            line.x + line.w / 2, line.y
        )
    end


    for i = 1, 5 do
        osga.gfx.color(1, 1, 1, 1 - 0.1 * i)
        local waveY = 120 + (130 + i * 2 + shore.wavesScrollY) % shore.field.height

        if waveY > 120 and waveY <= shore.field.height then
            osga.gfx.line(0, waveY, 240, waveY)
        end
    end
end


local function updateFPS()
    shore.fpsUpdateTimer = shore.fpsUpdateTimer + osga.system.getDelta()
    if shore.fpsUpdateTimer >= 0.5 then
        shore.fps = math.floor(osga.system.getFPS() + 0.5)
        shore.fpsUpdateTimer = 0
    end
end


local function drawParameters()
    osga.gfx.color(0, 0, 0, 1)
    osga.gfx.rect(shore.field.width, 0, 80, shore.field.height)


    osga.gfx.color(1, 1, 1)


    for i, param in ipairs(shore.parameters) do
        local y = 20 + (i - 1) * 30
        local x = shore.field.width + 10


        if i == shore.selected_parameter then
            osga.gfx.text(">", x - 10, y)
        end


        osga.gfx.text(param.name, x, y)
        osga.gfx.text(tostring(param.value), x + 10, y + 15)
    end


    local fpsY = 20 + (#shore.parameters) * 30 + 30
    osga.gfx.text("FPS: " .. tostring(shore.fps), shore.field.width + 10, fpsY)


    local guideY = shore.field.height - 60
    for i, manual in ipairs(shore.manuals) do
        local y = guideY + (i - 1) * 20
        osga.gfx.text(manual.icon .. " " .. manual.rule, shore.field.width + 10, y)
    end
end



function app.init()
    initializeAnimations()
    initializeSound()


    for i = 1, 3 do
        table.insert(shore.ships, Ship.new(i))
    end
end

function app.draw(koto)
    updateFPS()


    if koto.swR and not shore.lastButtonStates.swR then
        shore.selected_parameter = shore.selected_parameter + 1
        if shore.selected_parameter > #shore.parameters then
            shore.selected_parameter = 1
        end
    end


    if koto.rotaryInc then
        local param = shore.parameters[shore.selected_parameter]
        param.value = math.min(param.value + param.step, param.max)
    elseif koto.rotaryDec then
        local param = shore.parameters[shore.selected_parameter]
        param.value = math.max(param.value - param.step, param.min)
    end


    local waveHeight = shore.parameters[1].value
    local waveSpeed = shore.parameters[2].value / 20
    local volume = shore.parameters[3].value / 100


    updateWaveSound(waveHeight, waveSpeed)
    if shore.sound.waveLowChannel then
        shore.sound.waveLowChannel.volume = volume * 0.7
        shore.sound.waveHighChannel.volume = volume * 0.3
    end

    updateHornSound()

    if koto.swA and not shore.lastButtonStates.swA then
        local shipSize = shore.parameters[4].value
        local hornPitch = shore.parameters[5].value
        playHornSound(hornPitch, shipSize)
        shore.ships[shipSize].isMoving = true
    end


    shore.wavesScrollY = shore.wavesScrollY + waveSpeed


    updateAnimations()


    drawSeaAnimation()


    for _, ship in ipairs(shore.ships) do
        ship:update()
        ship:draw()
    end

    drawParameters()


    shore.lastButtonStates.swA = koto.swA
    shore.lastButtonStates.swB = koto.swB
    shore.lastButtonStates.swR = koto.swR
end

function app.cleanup()
    if shore.sound.waveLowChannel then
        shore.sound.waveLowChannel:stop()
        osga.sound.removeChannel(shore.sound.waveLowChannel)
    end
    if shore.sound.waveHighChannel then
        shore.sound.waveHighChannel:stop()
        osga.sound.removeChannel(shore.sound.waveHighChannel)
    end


    for _, horn in ipairs(shore.sound.activeHorns) do
        horn.channel:stop()
        osga.sound.removeChannel(horn.channel)
    end
    shore.sound.activeHorns = {}
end

return app
