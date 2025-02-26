-- apps/acidtest/main.lua
local app = {}
app._meta = {
    name = "Acid Test",
    slug = "acidtest",
    author = "Leo Kuroshita",
    version = "1.0.0"
}


local acid = {
    parameters = {
        { name = "TEMPO",  value = 120, min = 60, max = 200,  step = 1 },
        { name = "CUTOFF", value = 500, min = 20, max = 2000, step = 10 },
        { name = "Q",      value = 50,  min = 1,  max = 100,  step = 1 },
        { name = "DECAY",  value = 50,  min = 1,  max = 100,  step = 1 }
    },
    manuals = {
        { icon = "A", rule = "PLAY" },
        { icon = "B", rule = "RANDOM" }
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
        swR = false
    },
    is_playing = false,
    step = 1,
    last_step_time = 0,
    sequence = {
        notes = {},
        slides = {},
        accents = {}
    },
    notes = {
        "C2", "D2", "E2", "F2", "G2", "A2", "B2",
        "C3", "D3", "E3", "F3", "G3", "A3", "B3"
    },

    filter_envelope_start = 0,
    current_frequency = 440,
    target_frequency = 440
}


local function randomizeSequence()
    acid.sequence.notes = {}
    acid.sequence.slides = {}
    acid.sequence.accents = {}

    for i = 1, 16 do
        acid.sequence.notes[i] = acid.notes[math.random(1, #acid.notes)]
        acid.sequence.slides[i] = math.random() < 0.3
        acid.sequence.accents[i] = math.random() < 0.2
        print(acid.sequence.notes[i])
    end
end


local function initializeSound()
    acid.channel = osga.sound.channel.new()


    local initialFreq = osga.sound.utils.noteToFrequency("C2")
    acid.oscillator = osga.sound.synth.newOscillator('sawtooth', initialFreq)
    acid.current_frequency = initialFreq
    acid.target_frequency = initialFreq


    acid.filter = osga.sound.filter.new('lowpass', {
        frequency = acid.parameters[2].value,
        q = acid.parameters[3].value / 10
    })


    acid.channel:addSource(acid.oscillator)
    acid.channel:addEffect(acid.filter)


    osga.sound.addChannel(acid.channel)
end


function app.init()
    randomizeSequence()
    initializeSound()
    acid.filter_envelope_start = osga.system.getTime()
end

local function drawGrid()
    local cellWidth = 30
    local cellHeight = 40
    local startX = 0
    local startY = 50

    osga.gfx.color(1, 1, 1)


    for row = 0, 1 do
        for col = 0, 7 do
            local x = startX + col * cellWidth
            local y = startY + row * cellHeight
            local index = row * 8 + col + 1


            osga.gfx.rect(x, y, cellWidth, cellHeight, "line")

            if acid.sequence.notes[index] then
                osga.gfx.text(tostring(acid.sequence.notes[index]), x + 2, y + 2)


                if acid.sequence.slides[index] then
                    osga.gfx.line(x, y + cellHeight - 2, x + cellWidth, y + cellHeight - 2)
                end


                if acid.sequence.accents[index] then
                    osga.gfx.text("*", x + cellWidth - 8, y + 2)
                end
            end


            if acid.is_playing and index == acid.step then
                osga.gfx.color(1, 1, 1, 0.3)
                osga.gfx.rect(x, y, cellWidth, cellHeight)
                osga.gfx.color(1, 1, 1, 1)
            end
        end
    end
end


local function drawParameters()
    osga.gfx.color(0, 0, 0, 1)
    osga.gfx.rect(acid.field.width, 0, 80, acid.field.height)

    osga.gfx.color(1, 1, 1)


    for i, param in ipairs(acid.parameters) do
        local y = 20 + (i - 1) * 30
        local x = acid.field.width + 10

        if i == acid.selected_parameter then
            osga.gfx.text(">", x - 10, y)
        end

        osga.gfx.text(param.name, x, y)
        osga.gfx.text(tostring(param.value), x + 10, y + 15)
    end


    local guideY = acid.field.height - 60
    for i, manual in ipairs(acid.manuals) do
        local y = guideY + (i - 1) * 20
        osga.gfx.text(manual.icon .. " " .. manual.rule, acid.field.width + 10, y)
    end
end


local function updateSequence()
    if not acid.is_playing then return end

    local currentTime = osga.system.getTime()
    local stepTime = (60 / acid.parameters[1].value) / 4


    local slide_speed = 0.1
    if math.abs(acid.current_frequency - acid.target_frequency) > 0.1 then
        acid.current_frequency = acid.current_frequency +
            (acid.target_frequency - acid.current_frequency) * slide_speed


        acid.oscillator = osga.sound.synth.newOscillator('sawtooth', acid.current_frequency)
        acid.channel.sources = {}
        acid.channel:addSource(acid.oscillator)
    end

    if currentTime - acid.last_step_time >= stepTime then
        acid.step = acid.step + 1
        if acid.step > 16 then acid.step = 1 end


        local noteStr = acid.sequence.notes[acid.step]
        local newFreq = osga.sound.utils.noteToFrequency(noteStr)


        if acid.sequence.slides[acid.step] then
            acid.target_frequency = newFreq
        else
            acid.target_frequency = newFreq
            acid.current_frequency = newFreq

            acid.oscillator = osga.sound.synth.newOscillator('sawtooth', newFreq)
            acid.channel.sources = {}
            acid.channel:addSource(acid.oscillator)
        end


        acid.filter_envelope_start = currentTime

        acid.last_step_time = currentTime
    end


    local elapsed = currentTime - acid.filter_envelope_start
    local decay = acid.parameters[4].value / 100.0
    local decayTime = decay * 0.5


    local decayFactor = math.max(0, 1.0 - (elapsed / decayTime))


    local baseCutoff = acid.parameters[2].value
    local modAmount = 1000
    local currentCutoff = baseCutoff + (modAmount * decayFactor)


    if acid.sequence.accents[acid.step] then
        currentCutoff = currentCutoff * 1.5
    end


    acid.filter.frequency = math.min(2000, currentCutoff)
    acid.filter.q = acid.parameters[3].value / 10
    acid.filter:updateCoefficients()
end


function app.draw(koto)
    osga.gfx.clear(0, 0, 0)


    if koto.swA and not acid.lastButtonStates.swA then
        acid.is_playing = not acid.is_playing
        if acid.is_playing then
            acid.channel:play()
        else
            acid.channel:stop()
        end
    end


    if koto.swB and not acid.lastButtonStates.swB then
        randomizeSequence()
    end


    if koto.swR and not acid.lastButtonStates.swR then
        acid.selected_parameter = acid.selected_parameter + 1
        if acid.selected_parameter > #acid.parameters then
            acid.selected_parameter = 1
        end
    end


    if koto.rotaryInc or koto.rotaryDec then
        local param = acid.parameters[acid.selected_parameter]
        if koto.rotaryInc then
            param.value = math.min(param.value + param.step, param.max)
        else
            param.value = math.max(param.value - param.step, param.min)
        end
    end


    updateSequence()


    drawGrid()
    drawParameters()


    acid.lastButtonStates.swA = koto.swA
    acid.lastButtonStates.swB = koto.swB
    acid.lastButtonStates.swR = koto.swR
end

function app.cleanup()
    if acid.channel then
        acid.channel:stop()
        osga.sound.removeChannel(acid.channel)
    end
end

return app
