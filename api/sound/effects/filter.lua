-- api/sound/effects/filter.lua
local Filter = {}
Filter.__index = Filter

function Filter.new(type, params)
    local self = setmetatable({}, Filter)
    self.type = type or "lowpass"
    self.frequency = params.frequency or 1000
    self.q = params.q or 1


    self.b0 = 0
    self.b1 = 0
    self.b2 = 0
    self.b3 = 0
    self.b4 = 0


    self:updateCoefficients()

    return self
end

function Filter:updateCoefficients()
    local frequency = math.max(0.0, math.min(1.0, self.frequency / 44100 * 2))


    local resonance = math.max(0.0, math.min(1.0, (self.q - 0.5) / 10))


    self.q_val = 1.0 - frequency
    self.p_val = frequency + 0.8 * frequency * self.q_val
    self.f_val = self.p_val + self.p_val - 1.0
    self.q_val = resonance * (1.0 + 0.5 * self.q_val *
        (1.0 - self.q_val + 5.6 * self.q_val * self.q_val))
end

function Filter:process(input)
    input = math.max(-1.0, math.min(1.0, input))

    input = input - self.q_val * self.b4


    local t1 = self.b1
    self.b1 = (input + self.b0) * self.p_val - self.b1 * self.f_val

    local t2 = self.b2
    self.b2 = (self.b1 + t1) * self.p_val - self.b2 * self.f_val

    t1 = self.b3
    self.b3 = (self.b2 + t2) * self.p_val - self.b3 * self.f_val

    self.b4 = (self.b3 + t1) * self.p_val - self.b4 * self.f_val


    self.b4 = self.b4 - self.b4 * self.b4 * self.b4 * 0.166667


    self.b0 = input


    if self.type == "lowpass" then
        return self.b4
    elseif self.type == "highpass" then
        return input - self.b4
    elseif self.type == "bandpass" then
        return 3.0 * (self.b3 - self.b4)
    end

    return self.b4
end

return Filter
