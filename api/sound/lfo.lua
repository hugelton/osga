-- api/sound/lfo.lua
local lfo = {}


lfo.WAVEFORMS = {
    SINE = "sine",
    TRIANGLE = "triangle",
    SQUARE = "square",
    UP_RAMP = "up_ramp",
    DOWN_RAMP = "down_ramp",
    RANDOM = "random",
    RANDOM_STEP = "random_step"
}


function lfo.create(params)
    params = params or {}

    local obj = {

        waveform = params.waveform or lfo.WAVEFORMS.SINE,
        speed = params.speed or 1.0,
        intensity = params.intensity or 1.0,
        offset = params.offset or 0.0,


        phase = params.phase or 0.0,
        lastValue = 0.0,
        lastRandom = 0.0,
        sampleRate = 44100,
        phaseIncrement = 0.0
    }


    obj.phaseIncrement = obj.speed / obj.sampleRate


    local generators = {
        [lfo.WAVEFORMS.SINE] = function(phase)
            return math.sin(phase * 2 * math.pi)
        end,

        [lfo.WAVEFORMS.TRIANGLE] = function(phase)
            local value = phase * 4
            if phase < 0.25 then
                return value
            elseif phase < 0.75 then
                return 2 - value
            else
                return value - 4
            end
        end,

        [lfo.WAVEFORMS.SQUARE] = function(phase)
            return phase < 0.5 and 1 or -1
        end,

        [lfo.WAVEFORMS.UP_RAMP] = function(phase)
            return phase * 2 - 1
        end,

        [lfo.WAVEFORMS.DOWN_RAMP] = function(phase)
            return 1 - phase * 2
        end,

        [lfo.WAVEFORMS.RANDOM] = function(_, self)
            local newRandom = math.random() * 2 - 1
            local result = self.lastRandom + (newRandom - self.lastRandom) * self.phase

            if self.phase >= 1.0 then
                self.lastRandom = newRandom
            end

            return result
        end,

        [lfo.WAVEFORMS.RANDOM_STEP] = function(phase, self)
            if phase < self.phase then
                self.lastValue = math.random() * 2 - 1
            end
            return self.lastValue
        end
    }


    function obj:update(dt)
        self.phase = self.phase + dt * self.speed


        while self.phase >= 1.0 do
            self.phase = self.phase - 1.0
        end


        local rawValue = generators[self.waveform](self.phase, self)


        return rawValue * self.intensity + self.offset
    end

    function obj:getSample()
        self.phase = self.phase + self.phaseIncrement


        if self.phase >= 1.0 then
            self.phase = self.phase - 1.0
        end


        local rawValue = generators[self.waveform](self.phase, self)


        return rawValue * self.intensity + self.offset
    end

    function obj:setWaveform(waveform)
        if lfo.WAVEFORMS[waveform:upper()] then
            self.waveform = lfo.WAVEFORMS[waveform:upper()]
        else
            self.waveform = waveform
        end
    end

    function obj:setSpeed(hz)
        self.speed = hz
        self.phaseIncrement = self.speed / self.sampleRate
    end

    function obj:setIntensity(amount)
        self.intensity = math.max(0.0, math.min(1.0, amount))
    end

    function obj:setOffset(value)
        self.offset = math.max(-1.0, math.min(1.0, value))
    end

    function obj:reset()
        self.phase = 0.0
        self.lastValue = 0.0
        self.lastRandom = 0.0
    end

    function obj:asSource()
        local Source = require('api.sound.source')
        return Source.new(function()
            return self:getSample()
        end)
    end

    return obj
end

lfo.presets = {

    vibrato = function()
        return lfo.create({
            waveform = lfo.WAVEFORMS.SINE,
            speed = 5.0,
            intensity = 0.3,
            offset = 0.0
        })
    end,


    tremolo = function()
        return lfo.create({
            waveform = lfo.WAVEFORMS.SINE,
            speed = 4.0,
            intensity = 0.5,
            offset = 0.5
        })
    end,


    randomMod = function()
        return lfo.create({
            waveform = lfo.WAVEFORMS.RANDOM_STEP,
            speed = 8.0,
            intensity = 0.7,
            offset = 0.0
        })
    end,


    slowSweep = function()
        return lfo.create({
            waveform = lfo.WAVEFORMS.TRIANGLE,
            speed = 0.1,
            intensity = 1.0,
            offset = 0.0
        })
    end
}

return lfo
