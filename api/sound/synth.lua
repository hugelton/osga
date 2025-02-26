-- api/sound/synth.lua
local denver = require('api.libs.denver')
local Source = require('api.sound.source')

local synth = {}


function synth.newNoise(type, params)
    params = params or {}


    return Source.new(function()
        if type == 'white' then
            return math.random() * 2 - 1
        elseif type == 'pink' then
            local white = math.random() * 2 - 1
            local b0 = 0
            local b1 = 0
            local b2 = 0
            local b3 = 0
            local b4 = 0
            local b5 = 0
            local b6 = 0


            b0 = 0.99886 * b0 + white * 0.0555179
            b1 = 0.99332 * b1 + white * 0.0750759
            b2 = 0.96900 * b2 + white * 0.1538520
            b3 = 0.86650 * b3 + white * 0.3104856
            b4 = 0.55000 * b4 + white * 0.5329522
            b5 = -0.7616 * b5 - white * 0.0168980
            local pink = b0 + b1 + b2 + b3 + b4 + b5 + b6 + white * 0.5362
            b6 = white * 0.115926

            return pink * 0.11
        end
        return 0
    end)
end

local function sineOscillator(frequency)
    local phase = 0
    local phaseIncrement = 2 * math.pi * frequency / 44100

    return function()
        phase = phase + phaseIncrement
        if phase >= 2 * math.pi then
            phase = phase - 2 * math.pi
        end
        return math.sin(phase)
    end
end

local function sawtoothOscillator(frequency)
    local phase = 0
    local phaseIncrement = frequency / 44100

    return function()
        phase = phase + phaseIncrement
        if phase >= 1.0 then
            phase = phase - 1.0
        end
        return 2.0 * phase - 1.0
    end
end

local function triangleOscillator(frequency)
    local phase = 0
    local phaseIncrement = frequency / 44100

    return function()
        phase = phase + phaseIncrement
        if phase >= 1.0 then
            phase = phase - 1.0
        end

        local value = 4.0 * math.abs(phase - 0.5) - 1.0
        return value
    end
end

local function squareOscillator(frequency, pulseWidth)
    pulseWidth = pulseWidth or 0.5
    local phase = 0
    local phaseIncrement = frequency / 44100

    return function()
        phase = phase + phaseIncrement
        if phase >= 1.0 then
            phase = phase - 1.0
        end
        return phase < pulseWidth and 1.0 or -1.0
    end
end


function synth.newOscillator(waveform, frequency)
    local generator
    frequency = frequency or 440

    print("Creating oscillator:", waveform, frequency)

    if waveform == 'sine' or waveform == 'sinus' then
        generator = sineOscillator(frequency)
    elseif waveform == 'sawtooth' then
        generator = sawtoothOscillator(frequency)
    elseif waveform == 'triangle' then
        generator = triangleOscillator(frequency)
    elseif waveform == 'square' then
        generator = squareOscillator(frequency)
    else
        print("Unknown waveform:", waveform)
        generator = sineOscillator(frequency)
    end

    return Source.new(generator)
end

return synth
