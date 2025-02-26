-- apps/densha/main.lua
local app = {}
app._meta = {
    name = "Densha",
    slug = "densha",
    author = "OSGA Developer",
    version = "1.0.0"
}


local densha = {
    parameters = {
        { name = "SPEED",      value = 50,  min = 0,   max = 100, step = 1 },
        { name = "VOLUME",     value = 80,  min = 0,   max = 100, step = 1 },
        { name = "HORN PITCH", value = 440, min = 220, max = 880, step = 5 },
        { name = "LANDSCAPE",  value = 1,   min = 1,   max = 3,   step = 1 }
    },
    manuals = {
        { icon = "A", rule = "HORN" },
        { icon = "B", rule = "START/STOP" },
        { icon = "R", rule = "SELECT" }
    },
    field = {
        x = 0,
        y = 0,
        width = 240,
        height = 240
    },
    selected_parameter = 1,
    lastButtonStates = {
        swA = false,
        swB = false,
        swC = false,
        swR = false
    },
    isMoving = false,
    trainShakeAmount = 0,
    trainShakeFrequency = 10,


    layers = {
        farSky = { x = 0, speed = 0.1 },
        mountains = { x = 0, speed = 0.3 },
        buildings = { x = 0, speed = 0.5 },
        foreground = { x = 0, speed = 1.0 }
    },
    stars = {},
    starTimer = 0,
    tunnelProgress = -1,
    tunnelLength = 240,
    passingTrain = {
        active = false,
        x = -100,
        speed = 0,
        width = 100,
        lights = {}
    },


    sounds = {
        channels = {},
        trainEngine = nil,
        wheels = nil,
        horn = nil,
        tunnel = nil,
        passingTrain = nil
    },


    events = {
        tunnelChance = 0.001,
        passingTrainChance = 0.0005,
        lastTunnelTime = 0,
        minTimeBetweenEvents = 5
    },


    frameCount = 0
}


densha.currentLandscape = 1
densha.landscapeFade = {
    active = false,
    progress = 0,
    targetLandscape = 1,
    duration = 2.0
}


densha.buildingLayouts = {

    {
        type = 1,
        buildings = {}
    },

    {
        type = 2,
        buildings = {}
    },

    {
        type = 3,
        buildings = {}
    }
}




local function generateBuildingLayouts()
    local cityBuildings = densha.buildingLayouts[1].buildings
    local x = 0
    while x < densha.field.width * 2 do
        local width = 15 + math.random(5, 25)
        local height = 30 + math.random(20, 70)

        table.insert(cityBuildings, {
            x = x,
            width = width,
            height = height,
            windows = {}
        })


        local windowsPerFloor = math.floor(width / 7)
        local floors = math.floor(height / 10)

        for floor = 1, floors do
            for window = 1, windowsPerFloor do
                if math.random() < 0.7 then
                    table.insert(cityBuildings[#cityBuildings].windows, {
                        x = (window - 1) * 7 + 3,
                        y = floor * 8,
                        lit = math.random() < 0.8
                    })
                end
            end
        end

        x = x + width
    end


    local suburbanBuildings = densha.buildingLayouts[2].buildings
    x = 0
    while x < densha.field.width * 2 do
        local width = 12 + math.random(5, 20)
        local height = 20 + math.random(10, 40)
        local gap = math.random(0, 15)

        table.insert(suburbanBuildings, {
            x = x + gap,
            width = width,
            height = height,
            windows = {}
        })


        local windowsPerFloor = math.floor(width / 8)
        local floors = math.floor(height / 10)

        for floor = 1, floors do
            for window = 1, windowsPerFloor do
                if math.random() < 0.5 then
                    table.insert(suburbanBuildings[#suburbanBuildings].windows, {
                        x = (window - 1) * 8 + 4,
                        y = floor * 9,
                        lit = math.random() < 0.6
                    })
                end
            end
        end

        x = x + width + gap
    end


    local ruralBuildings = densha.buildingLayouts[3].buildings
    x = 0
    while x < densha.field.width * 2 do
        local width = 10 + math.random(5, 15)
        local height = 15 + math.random(5, 25)
        local gap = math.random(10, 40)

        table.insert(ruralBuildings, {
            x = x + gap,
            width = width,
            height = height,
            windows = {}
        })


        local windowsPerFloor = math.floor(width / 10)
        local floors = math.floor(height / 12)

        for floor = 1, floors do
            for window = 1, windowsPerFloor do
                if math.random() < 0.4 then
                    table.insert(ruralBuildings[#ruralBuildings].windows, {
                        x = (window - 1) * 10 + 5,
                        y = floor * 10,
                        lit = math.random() < 0.4
                    })
                end
            end
        end

        x = x + width + gap
    end
end


local function startLandscapeTransition(targetLandscape)
    if targetLandscape == densha.currentLandscape then
        return
    end

    densha.landscapeFade.active = true
    densha.landscapeFade.progress = 0
    densha.landscapeFade.targetLandscape = targetLandscape
end


local function updateLandscapeFade(dt)
    if not densha.landscapeFade.active then
        return
    end


    densha.landscapeFade.progress = densha.landscapeFade.progress + dt / densha.landscapeFade.duration


    if densha.landscapeFade.progress >= 1.0 then
        densha.currentLandscape = densha.landscapeFade.targetLandscape
        densha.landscapeFade.active = false
        densha.landscapeFade.progress = 0
    end
end


local function initializeSound()
    densha.sounds.channels.engine = osga.sound.channel.new()
    densha.sounds.channels.wheels = osga.sound.channel.new()
    densha.sounds.channels.horn = osga.sound.channel.new()
    densha.sounds.channels.effects = osga.sound.channel.new()



    densha.sounds.trainEngine = osga.sound.synth.newNoise('pink')
    local engineFilter = osga.sound.filter.new('lowpass', {
        frequency = 200,
        q = 0.5
    })
    densha.sounds.channels.engine:addSource(densha.sounds.trainEngine)
    densha.sounds.channels.engine:addEffect(engineFilter)


    densha.sounds.wheels = osga.sound.synth.newNoise('white')
    local wheelsFilter = osga.sound.filter.new('bandpass', {
        frequency = 800,
        q = 2.0
    })
    densha.sounds.channels.wheels:addSource(densha.sounds.wheels)
    densha.sounds.channels.wheels:addEffect(wheelsFilter)


    densha.sounds.horn = osga.sound.synth.newOscillator('sine', 440)
    densha.sounds.hornOctave = osga.sound.synth.newOscillator('sine', 220)
    densha.sounds.hornFifth = osga.sound.synth.newOscillator('sine', 660)
    densha.sounds.channels.horn:addSource(densha.sounds.horn)
    densha.sounds.channels.horn:addSource(densha.sounds.hornOctave)
    densha.sounds.channels.horn:addSource(densha.sounds.hornFifth)


    densha.sounds.tunnel = osga.sound.synth.newNoise('white')
    local tunnelFilter = osga.sound.filter.new('bandpass', {
        frequency = 300,
        q = 5.0
    })
    densha.sounds.channels.effects:addSource(densha.sounds.tunnel)
    densha.sounds.channels.effects:addEffect(tunnelFilter)


    densha.sounds.passingTrain = osga.sound.synth.newNoise('white')
    local passingTrainFilter = osga.sound.filter.new('highpass', {
        frequency = 1000,
        q = 0.8
    })


    osga.sound.addChannel(densha.sounds.channels.engine)
    osga.sound.addChannel(densha.sounds.channels.wheels)
    osga.sound.addChannel(densha.sounds.channels.horn)
    osga.sound.addChannel(densha.sounds.channels.effects)
end


local function initializeStars()
    densha.stars = {}
    for i = 1, 50 do
        table.insert(densha.stars, {
            x = math.random(0, densha.field.width),
            y = math.random(0, 100),
            size = math.random() > 0.7 and 2 or 1,
            brightness = 0.3 + math.random() * 0.7,
            twinkleRate = 0.2 + math.random() * 0.5
        })
    end
end


local function initializePassingTrainLights()
    densha.passingTrain.lights = {}
    local lightCount = 6
    local trainHeight = 50
    local minY = 120 - trainHeight / 2
    local maxY = 120 + trainHeight / 2

    for i = 1, lightCount do
        table.insert(densha.passingTrain.lights, {
            x = math.random(0, densha.passingTrain.width),
            y = math.random(minY, maxY),
            size = math.random(2, 4),
            color = math.random() > 0.7 and { 0.9, 0.6, 0.1 } or { 0.9, 0.9, 0.9 }
        })
    end
end


local function startTrain()
    if not densha.isMoving then
        densha.isMoving = true
        densha.sounds.channels.engine:play()
        densha.sounds.channels.wheels:play()
    end
end


local function stopTrain()
    if densha.isMoving then
        densha.isMoving = false
        densha.sounds.channels.engine:stop()
        densha.sounds.channels.wheels:stop()
    end
end


local function playHorn()
    local hornPitch = densha.parameters[3].value


    densha.sounds.horn = osga.sound.synth.newOscillator('sine', hornPitch)
    densha.sounds.hornOctave = osga.sound.synth.newOscillator('sine', hornPitch / 2)
    densha.sounds.hornFifth = osga.sound.synth.newOscillator('sine', hornPitch * 1.5)


    densha.sounds.channels.horn = osga.sound.channel.new()
    densha.sounds.channels.horn:addSource(densha.sounds.horn)
    densha.sounds.channels.horn:addSource(densha.sounds.hornOctave)
    densha.sounds.channels.horn:addSource(densha.sounds.hornFifth)

    osga.sound.addChannel(densha.sounds.channels.horn)
    densha.sounds.channels.horn:play()


    local hornDuration = 1.0
    local currentTime = osga.system.getTime()


    densha.sounds.hornStartTime = currentTime
    densha.sounds.hornDuration = hornDuration
end


local function updateSounds()
    local volume = densha.parameters[2].value / 100
    local speed = densha.parameters[1].value / 100

    if densha.isMoving then
        if densha.sounds.channels.engine then
            densha.sounds.channels.engine.volume = volume * 0.8 * speed

            for _, effect in pairs(densha.sounds.channels.engine.effects) do
                if effect.frequency then
                    effect.frequency = 150 + speed * 150
                    effect:updateCoefficients()
                end
            end
        end


        if densha.sounds.channels.wheels then
            densha.sounds.channels.wheels.volume = volume * 0.6 * speed


            local wheelCycleLength = math.floor(30 / speed)
            if wheelCycleLength < 1 then wheelCycleLength = 1 end

            if densha.frameCount % wheelCycleLength == 0 then
                for _, effect in pairs(densha.sounds.channels.wheels.effects) do
                    if effect.frequency then
                        effect.frequency = 700 + math.random() * 300
                        effect.q = 3.0 + math.random() * 2.0
                        effect:updateCoefficients()
                    end
                end
            end
        end


        if densha.sounds.hornStartTime then
            local elapsed = osga.system.getTime() - densha.sounds.hornStartTime
            if elapsed > densha.sounds.hornDuration then
                densha.sounds.channels.horn:stop()
                densha.sounds.hornStartTime = nil
            end
        end


        if densha.tunnelProgress >= 0 and densha.tunnelProgress < densha.tunnelLength then
            if not densha.sounds.inTunnel then
                densha.sounds.inTunnel = true
                densha.sounds.channels.effects:play()
            end
            densha.sounds.channels.effects.volume = volume * 0.4
        else
            if densha.sounds.inTunnel then
                densha.sounds.inTunnel = false
                densha.sounds.channels.effects:stop()
            end
        end


        if densha.passingTrain.active then
            local distanceToCenter = math.abs(densha.passingTrain.x + densha.passingTrain.width / 2 -
                densha.field.width / 2)
            local maxDistance = densha.field.width / 2 + densha.passingTrain.width / 2
            local passingVolume = (1 - distanceToCenter / maxDistance) * volume

            if not densha.sounds.passingTrainActive then
                densha.sounds.passingTrainActive = true
                densha.sounds.channels.effects:play()
            end
            densha.sounds.channels.effects.volume = passingVolume * 0.7
        else
            if densha.sounds.passingTrainActive and not densha.sounds.inTunnel then
                densha.sounds.passingTrainActive = false
                densha.sounds.channels.effects:stop()
            end
        end
    end
end


local function updateVisuals()
    local speed = densha.parameters[1].value / 100
    local dt = osga.system.getDelta()


    local landscapeParam = densha.parameters[4].value
    if landscapeParam ~= densha.currentLandscape and not densha.landscapeFade.active then
        startLandscapeTransition(landscapeParam)
    end


    updateLandscapeFade(dt)


    if densha.isMoving then
        for name, layer in pairs(densha.layers) do
            layer.x = layer.x - (layer.speed * speed)


            while layer.x < -densha.field.width do
                layer.x = layer.x + densha.field.width
            end
        end


        densha.trainShakeAmount = speed * 2


        if densha.passingTrain.active then
            densha.passingTrain.x = densha.passingTrain.x + densha.passingTrain.speed
            if densha.passingTrain.x > densha.field.width + 100 then
                densha.passingTrain.active = false
            end
        end
    end


    densha.starTimer = densha.starTimer + 1
    if densha.starTimer >= 30 then
        densha.starTimer = 0
        for i, star in ipairs(densha.stars) do
            if math.random() < 0.1 then
                star.brightness = 0.3 + math.random() * 0.7
            end
        end
    end


    densha.frameCount = densha.frameCount + 1
end


local function checkEvents()
    if not densha.isMoving then
        return
    end

    local currentTime = osga.system.getTime()
    local timeSinceLastEvent = currentTime - densha.events.lastTunnelTime


    if timeSinceLastEvent < densha.events.minTimeBetweenEvents then
        return
    end


    if not densha.passingTrain.active and math.random() < densha.events.passingTrainChance then
        densha.passingTrain.active = true
        densha.passingTrain.x = -densha.passingTrain.width
        densha.passingTrain.speed = 3 + math.random() * 3
        initializePassingTrainLights()
        densha.events.lastTunnelTime = currentTime
    end
end


local function drawSky()
    for y = 0, 120 do
        local ratio = y / 120
        local r = 0.05 * (1 - ratio)
        local g = 0.05 * (1 - ratio)
        local b = 0.15 * (1 - ratio)

        osga.gfx.color(r, g, b)
        osga.gfx.line(0, y, densha.field.width, y)
    end


    for _, star in ipairs(densha.stars) do
        local twinkle = math.abs(math.sin(osga.system.getTime() * star.twinkleRate)) * 0.3 + 0.7
        local brightness = star.brightness * twinkle

        osga.gfx.color(brightness, brightness, brightness)
        if star.size == 1 then
            osga.gfx.circle(star.x, star.y, 1)
        else
            osga.gfx.circle(star.x, star.y, 1.5)
        end
    end


    osga.gfx.color(0.9, 0.9, 0.8)
    osga.gfx.circle(180, 40, 15)


    osga.gfx.color(0.05, 0.05, 0.15)
    osga.gfx.circle(188, 40, 14)
end


local function drawMountains()
    local horizonY = 120
    local mountainColor = { 0.08, 0.08, 0.12 }


    local ranges = {
        { height = 40, detail = 5,  color = { 0.1, 0.1, 0.15 },   layer = densha.layers.farSky },
        { height = 30, detail = 8,  color = { 0.08, 0.08, 0.12 }, layer = densha.layers.mountains },
        { height = 20, detail = 10, color = { 0.06, 0.06, 0.09 }, layer = densha.layers.mountains }
    }

    for _, range in ipairs(ranges) do
        osga.gfx.color(range.color[1], range.color[2], range.color[3])


        local x = range.layer.x % densha.field.width
        local segmentWidth = range.detail
        local numSegments = densha.field.width / segmentWidth + 1

        for i = 0, numSegments do
            local segX = x + (i * segmentWidth)
            if segX > densha.field.width then
                segX = segX - densha.field.width
            end


            local seedValue = i + (range.layer.x / segmentWidth)
            local heightVariation =
                math.sin(seedValue * 0.3) * 0.5 +
                math.sin(seedValue * 0.7) * 0.3 +
                math.sin(seedValue * 1.1) * 0.2

            local peakHeight = horizonY - range.height * (0.5 + heightVariation * 0.5)


            for y = peakHeight, horizonY do
                osga.gfx.line(segX, y, segX, y)
            end
        end
    end
end


local function drawBuildingSet(buildings, layer, horizonY, alpha)
    local offsetX = layer.x % densha.field.width

    for _, building in ipairs(buildings) do
        local x = (building.x - offsetX) % (densha.field.width * 2)


        if x < densha.field.width + building.width and x + building.width > 0 then
            osga.gfx.color(0.05, 0.05, 0.08, alpha)
            osga.gfx.rect(x, horizonY - building.height, building.width, building.height)


            for _, window in ipairs(building.windows) do
                if window.lit then
                    osga.gfx.color(0.9, 0.9, 0.5, alpha * 0.7)
                    osga.gfx.rect(x + window.x, horizonY - building.height + window.y, 2, 3)
                end
            end
        end
    end
end


local function drawBuildings()
    local horizonY = 120
    local currentLayouts = densha.buildingLayouts[densha.currentLandscape].buildings
    local buildingLayer = densha.layers.buildings


    if densha.landscapeFade.active then
        local fadeAlpha = densha.landscapeFade.progress
        local targetLayouts = densha.buildingLayouts[densha.landscapeFade.targetLandscape].buildings


        drawBuildingSet(currentLayouts, buildingLayer, horizonY, 1.0 - fadeAlpha)


        drawBuildingSet(targetLayouts, buildingLayer, horizonY, fadeAlpha)
    else
        drawBuildingSet(currentLayouts, buildingLayer, horizonY, 1.0)
    end
end




local function drawForeground()
    local horizonY = 120
    local groundColor = { 0.03, 0.03, 0.06 }
    local railColor = { 0.2, 0.2, 0.25 }


    osga.gfx.color(groundColor[1], groundColor[2], groundColor[3])
    osga.gfx.rect(0, horizonY, densha.field.width, densha.field.height - horizonY)


    osga.gfx.color(railColor[1], railColor[2], railColor[3])


    osga.gfx.line(0, horizonY + 30, densha.field.width, horizonY + 30)
    osga.gfx.line(0, horizonY + 35, densha.field.width, horizonY + 35)


    local sleeperOffset = densha.layers.foreground.x % 15
    for i = 0, math.ceil(densha.field.width / 15) do
        local x = (i * 15) - sleeperOffset
        if x >= 0 and x < densha.field.width then
            osga.gfx.line(x, horizonY + 28, x, horizonY + 37)
        end
    end


    local fenceOffset = densha.layers.foreground.x % 30
    for i = 0, math.ceil(densha.field.width / 30) do
        local x = (i * 30) - fenceOffset
        if x >= 0 and x < densha.field.width then
            osga.gfx.line(x, horizonY + 15, x, horizonY + 30)
        end
    end
end


local function drawTrainInterior()
    osga.gfx.color(0, 0, 0)
    osga.gfx.rect(0, 0, densha.field.width, 10)
    osga.gfx.rect(0, 0, 10, densha.field.height)
    osga.gfx.rect(densha.field.width - 10, 0, 10, densha.field.height)
    osga.gfx.rect(0, densha.field.height - 50, densha.field.width, 50)


    local shakeOffset = 0
    if densha.isMoving then
        shakeOffset = math.sin(osga.system.getTime() * densha.trainShakeFrequency) * densha.trainShakeAmount
    end


    osga.gfx.rect(densha.field.width / 2 - 5 + shakeOffset, 0, 10, densha.field.height - 50)
end


local function drawPassingTrain()
    if not densha.passingTrain.active then
        return
    end


    osga.gfx.color(0.1, 0.1, 0.15)
    osga.gfx.rect(densha.passingTrain.x, 100, densha.passingTrain.width, 40)


    osga.gfx.color(0.9, 0.9, 0.7, 0.8)
    for i = 1, 5 do
        local windowX = densha.passingTrain.x + 10 + (i - 1) * 20
        if windowX > 0 and windowX < densha.field.width then
            osga.gfx.rect(windowX, 110, 15, 10)
        end
    end


    for _, light in ipairs(densha.passingTrain.lights) do
        local lightX = densha.passingTrain.x + light.x
        if lightX > 0 and lightX < densha.field.width then
            osga.gfx.color(light.color[1], light.color[2], light.color[3])
            osga.gfx.circle(lightX, light.y, light.size)
        end
    end
end


local function drawParameters()
    osga.gfx.color(0, 0, 0)
    osga.gfx.rect(densha.field.width, 0, 80, densha.field.height)

    osga.gfx.color(1, 1, 1)


    for i, param in ipairs(densha.parameters) do
        local y = 20 + (i - 1) * 30
        local x = densha.field.width + 10

        if i == densha.selected_parameter then
            osga.gfx.text(">", x - 10, y)
        end

        osga.gfx.text(param.name, x, y)
        osga.gfx.text(tostring(param.value), x + 10, y + 15)
    end


    local guideY = densha.field.height - 80
    for i, manual in ipairs(densha.manuals) do
        local y = guideY + (i - 1) * 20
        osga.gfx.text(manual.icon .. " " .. manual.rule, densha.field.width + 10, y)
    end


    local statusY = densha.field.height - 120
    osga.gfx.text("STATUS:", densha.field.width + 10, statusY)
    osga.gfx.text(densha.isMoving and "RUNNING" or "STOPPED", densha.field.width + 10, statusY + 15)
end


function app.init()
    initializeSound()


    initializeStars()
    generateBuildingLayouts()


    densha.isMoving = false
    densha.frameCount = 0
    densha.currentLandscape = densha.parameters[4].value
    densha.events.lastTunnelTime = osga.system.getTime()
end

function app.draw(koto)
    osga.gfx.clear(0, 0, 0)



    if koto.swB and not densha.lastButtonStates.swB then
        if densha.isMoving then
            stopTrain()
        else
            startTrain()
        end
    end


    if koto.swA and not densha.lastButtonStates.swA then
        playHorn()
    end


    if koto.swR and not densha.lastButtonStates.swR then
        densha.selected_parameter = densha.selected_parameter + 1
        if densha.selected_parameter > #densha.parameters then
            densha.selected_parameter = 1
        end
    end


    if koto.rotaryInc then
        local param = densha.parameters[densha.selected_parameter]
        param.value = math.min(param.value + param.step, param.max)
    elseif koto.rotaryDec then
        local param = densha.parameters[densha.selected_parameter]
        param.value = math.max(param.value - param.step, param.min)
    end


    updateVisuals()
    updateSounds()
    checkEvents()


    drawSky()
    drawMountains()
    drawBuildings()
    drawForeground()
    drawPassingTrain()
    drawTrainInterior()


    drawParameters()


    densha.lastButtonStates.swA = koto.swA
    densha.lastButtonStates.swB = koto.swB
    densha.lastButtonStates.swR = koto.swR
end

function app.cleanup()
    for _, channel in pairs(densha.sounds.channels) do
        if channel then
            channel:stop()
            osga.sound.removeChannel(channel)
        end
    end


    densha.isMoving = false
    densha.tunnelProgress = -1
    densha.passingTrain.active = false

    print("Densha application cleaned up")
end

return app
