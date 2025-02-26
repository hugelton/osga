-- apps/amebako/main.lua
local app = {}
app._meta = {
    name = "Amebako",
    slug = "amebako",
    author = "Leo Kuroshita",
    version = "1.0.0"
}


local amebako = {
    parameters = {
        { name = "RAIN FALL", value = 50, min = 0, max = 100, step = 1 },
        { name = "RAIN INT.", value = 50, min = 0, max = 100, step = 1 },
        { name = "WIND",      value = 5,  min = 0, max = 100, step = 1 },
        { name = "THUNDER",   value = 0,  min = 0, max = 50,  step = 1 },
        { name = "RIPPLES",   value = 0,  min = 0, max = 50,  step = 1 }
    },
    manuals = {
        { icon = "A", rule = "THUNDER" },
    },
    field = {
        x = 0,
        y = 0,
        width = 240,
        height = 240
    },
    selected_parameter = 1,
    thunder_duration = 5,
    thunder_timer = 0,
    lastButtonStates = {
        swA = false,
        swB = false,
        swR = false
    },
    raindrops = {},
    ripples = {},
    sound = {},
    intervals = { 0, 2, 4, 5, 7, 9, 11, 12 },
    windVector = { dx = 0, dy = 0 },
    rainVector = { dx = 0, dy = 0 }
}

local max_raindrops = 40
local max_ripples = 10
local raindrop_length = 30


local function update_raindrop(raindrop)
    local x = raindrop[1]
    local y = raindrop[2]
    local speed = raindrop[3]
    local initial_x = raindrop[4]

    local rainIntensity = amebako.parameters[2].value / 100
    local adjustedSpeed = speed * (0.5 + rainIntensity)


    y = y + adjustedSpeed + amebako.rainVector.dy
    x = initial_x + amebako.rainVector.dx * (y / (adjustedSpeed + amebako.rainVector.dy))

    if y > amebako.field.height then
        y = -raindrop_length
        initial_x = math.random(0, amebako.field.width - 1)
        x = initial_x
    end
    return { x, y, speed, initial_x }
end


local function update_ripple(ripple)
    local x = ripple[1]
    local y = ripple[2]
    local radius_x = ripple[3]
    local radius_y = ripple[4]
    local speed = ripple[5]
    local is_new = ripple[6]

    radius_x = radius_x + speed
    radius_y = radius_y + speed * 5 / 12
    if radius_x > 60 or radius_y > 25 then
        return nil
    end
    return { x, y, radius_x, radius_y, speed, is_new }
end


local function initializeSound()
    amebako.sound.rainChannel = osga.sound.channel.new()
    amebako.sound.rainFilter = osga.sound.filter.new("lowpass", {
        frequency = 2000,
        q = 0.5
    })
    amebako.sound.rainNoise = osga.sound.synth.newNoise('white')
    amebako.sound.rainChannel:addSource(amebako.sound.rainNoise)
    amebako.sound.rainChannel:addEffect(amebako.sound.rainFilter)


    amebako.sound.windChannel = osga.sound.channel.new()
    amebako.sound.windFilter = osga.sound.filter.new("lowpass", {
        frequency = 800,
        q = 0.7
    })
    amebako.sound.windNoise = osga.sound.synth.newNoise('pink')
    amebako.sound.windChannel:addSource(amebako.sound.windNoise)
    amebako.sound.windChannel:addEffect(amebako.sound.windFilter)


    osga.sound.addChannel(amebako.sound.rainChannel)
    osga.sound.addChannel(amebako.sound.windChannel)
end


local function initializeRaindrops()
    amebako.raindrops = {}
    for _ = 1, max_raindrops do
        local x = math.random(0, amebako.field.width - 1)
        local y = math.random(-raindrop_length, 0)
        local speed = math.random(5, 15)
        table.insert(amebako.raindrops, { x, y, speed, x })
    end
end



local function thunderFlash()
    local thunderChannel = osga.sound.channel.new()


    local thunderNoise = osga.sound.synth.newNoise('pink')


    local thunderFilter = osga.sound.filter.new("lowpass", {
        frequency = 100,
        q = 2.0
    })


    thunderChannel:addSource(thunderNoise)
    thunderChannel:addEffect(thunderFilter)


    thunderChannel.duration = 0.8
    thunderChannel.startTime = love.timer.getTime()
    thunderChannel.volume = 0.8


    if not amebako.sound.activeThunders then
        amebako.sound.activeThunders = {}
    end
    table.insert(amebako.sound.activeThunders, thunderChannel)


    osga.sound.addChannel(thunderChannel)
    thunderChannel:play()


    amebako.thunder_timer = amebako.thunder_duration
end


local function updateThunders()
    if amebako.sound.activeThunders then
        local currentTime = love.timer.getTime()
        for i = #amebako.sound.activeThunders, 1, -1 do
            local thunder = amebako.sound.activeThunders[i]
            if currentTime - thunder.startTime > thunder.duration then
                thunder:stop()
                osga.sound.removeChannel(thunder)
                table.remove(amebako.sound.activeThunders, i)
            end
        end
    end
end


local function createRippleSound(frequency)
    local rippleChannel = osga.sound.channel.new()
    local rippleOsc = osga.sound.synth.newOscillator('sinus', frequency)


    local rippleFilter = osga.sound.filter.new("lowpass", {
        frequency = 2000,
        q = 1.0
    })

    rippleChannel:addSource(rippleOsc)
    rippleChannel:addEffect(rippleFilter)


    rippleChannel.duration = 0.4
    rippleChannel.startTime = love.timer.getTime()


    if not amebako.sound.activeRipples then
        amebako.sound.activeRipples = {}
    end
    table.insert(amebako.sound.activeRipples, rippleChannel)


    osga.sound.addChannel(rippleChannel)
    rippleChannel:play()
end


local function updateSounds()
    local currentTime = love.timer.getTime()


    if amebako.sound.activeThunders then
        for i = #amebako.sound.activeThunders, 1, -1 do
            local thunder = amebako.sound.activeThunders[i]
            if currentTime - thunder.startTime > thunder.duration then
                thunder:stop()
                osga.sound.removeChannel(thunder)
                table.remove(amebako.sound.activeThunders, i)
            end
        end
    end


    if amebako.sound.activeRipples then
        for i = #amebako.sound.activeRipples, 1, -1 do
            local ripple = amebako.sound.activeRipples[i]
            if currentTime - ripple.startTime > ripple.duration then
                ripple:stop()
                osga.sound.removeChannel(ripple)
                table.remove(amebako.sound.activeRipples, i)
            end
        end
    end
end


local function drawParameters()
    osga.gfx.color(0, 0, 0, 1)
    osga.gfx.rect(amebako.field.width, 0, 80, amebako.field.height)

    osga.gfx.color(1, 1, 1)


    for i, param in ipairs(amebako.parameters) do
        local y = 20 + (i - 1) * 30
        local x = amebako.field.width + 10

        if i == amebako.selected_parameter then
            osga.gfx.text(">", x - 10, y)
        end

        osga.gfx.text(param.name, x, y)
        osga.gfx.text(tostring(param.value), x + 10, y + 15)
    end


    local guideY = amebako.field.height - 60
    for i, manual in ipairs(amebako.manuals) do
        local y = guideY + (i - 1) * 20
        osga.gfx.text(manual.icon .. " " .. manual.rule, amebako.field.width + 10, y)
    end
end


function app.init()
    initializeSound()
    initializeRaindrops()


    amebako.sound.rainChannel:play()
    amebako.sound.windChannel:play()
end

function app.draw(koto)
    osga.gfx.clear(0, 0, 0)
    updateSounds()


    local windStrength = amebako.parameters[3].value / 100
    amebako.windVector.dx = (raindrop_length * windStrength) +
        10 * math.cos(-windStrength + 1.5708)
    amebako.windVector.dy = (raindrop_length * windStrength) +
        10 * math.sin(-windStrength + 1.5708)




    local gyroFactor = 20
    amebako.rainVector.dx = koto.gyroX * gyroFactor
    amebako.rainVector.dy = raindrop_length



    local currentMaxRaindrops = math.floor(max_raindrops * amebako.parameters[1].value / 100)


    local rainIntensity = amebako.parameters[2].value / 100
    local currentRaindropLength = raindrop_length * rainIntensity

    for i, raindrop in ipairs(amebako.raindrops) do
        if i <= currentMaxRaindrops then
            local updated_raindrop = update_raindrop(raindrop)
            amebako.raindrops[i] = updated_raindrop
            local x, y = updated_raindrop[1], updated_raindrop[2]
            osga.gfx.color(1, 1, 1)

            osga.gfx.line(x, y, x + amebako.rainVector.dx * rainIntensity, y + currentRaindropLength)
        end
    end


    for i = #amebako.ripples, 1, -1 do
        local updated_ripple = update_ripple(amebako.ripples[i])
        if updated_ripple then
            amebako.ripples[i] = updated_ripple
            local x = updated_ripple[1]
            local y = updated_ripple[2]
            local radius_x = updated_ripple[3]
            local radius_y = updated_ripple[4]
            osga.gfx.color(1, 1, 1)

            osga.gfx.ellipse(x, y, radius_x * 2, radius_y * 2, "line")
        else
            table.remove(amebako.ripples, i)
        end
    end


    if #amebako.ripples < amebako.parameters[5].value and math.random() < 0.2 then
        local x = math.random(0, amebako.field.width - 1)
        local y = math.random(math.floor(amebako.field.height * 0.8), amebako.field.height - 1)
        local radius_x = 3
        local radius_y = radius_x * 3 / 12
        local speed = math.random(1, 3)
        table.insert(amebako.ripples, { x, y, radius_x, radius_y, speed, true })


        local randomInterval = amebako.intervals[math.random(1, #amebako.intervals)]
        local frequency = 440 * math.pow(2, randomInterval / 12)
        createRippleSound(frequency)
    end


    updateThunders()


    if koto.swA and not amebako.lastButtonStates.swA then
        thunderFlash()
    end


    if math.random() < amebako.parameters[4].value / 1000 then
        thunderFlash()
    end


    if amebako.thunder_timer > 0 then
        if math.random(0, 1) == 1 then
            osga.gfx.color(1, 1, 1)
            osga.gfx.rect(0, 0, amebako.field.width, amebako.field.height)
        end
        amebako.thunder_timer = amebako.thunder_timer - 1
    end


    if koto.swR and not amebako.lastButtonStates.swR then
        amebako.selected_parameter = amebako.selected_parameter + 1
        if amebako.selected_parameter > #amebako.parameters then
            amebako.selected_parameter = 1
        end
    end


    if koto.rotaryInc then
        local param = amebako.parameters[amebako.selected_parameter]
        param.value = math.min(param.value + param.step, param.max)
    elseif koto.rotaryDec then
        local param = amebako.parameters[amebako.selected_parameter]
        param.value = math.max(param.value - param.step, param.min)
    end


    if amebako.sound.rainChannel then
        amebako.sound.rainChannel.volume = amebako.parameters[1].value / 100


        local rainIntensity = amebako.parameters[2].value / 100

        amebako.sound.rainFilter.frequency = 1000 + (rainIntensity * 3000)

        amebako.sound.rainFilter.q = 0.5 + (rainIntensity * 0.5)
        amebako.sound.rainFilter:updateCoefficients()
    end

    if amebako.sound.windChannel then
        amebako.sound.windChannel.volume = amebako.parameters[3].value / 100


        local windStrength = amebako.parameters[3].value / 100
        amebako.sound.windFilter.frequency = 800 + (math.sin(love.timer.getTime() * windStrength) * 400)
        amebako.sound.windFilter.q = 0.7 + (windStrength * 0.5)
        amebako.sound.windFilter:updateCoefficients()
    end


    drawParameters()


    amebako.lastButtonStates.swA = koto.swA
    amebako.lastButtonStates.swR = koto.swR
end

function app.cleanup()
    if amebako.sound.rainChannel then
        amebako.sound.rainChannel:stop()
        osga.sound.removeChannel(amebako.sound.rainChannel)
    end
    if amebako.sound.windChannel then
        amebako.sound.windChannel:stop()
        osga.sound.removeChannel(amebako.sound.windChannel)
    end


    if amebako.sound.activeThunders then
        for _, thunder in ipairs(amebako.sound.activeThunders) do
            thunder:stop()
            osga.sound.removeChannel(thunder)
        end
        amebako.sound.activeThunders = {}
    end


    if amebako.sound.activeRipples then
        for _, ripple in ipairs(amebako.sound.activeRipples) do
            ripple:stop()
            osga.sound.removeChannel(ripple)
        end
        amebako.sound.activeRipples = {}
    end
end

return app
