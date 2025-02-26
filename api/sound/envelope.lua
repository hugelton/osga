-- api/sound/envelope.lua


local envelope = {}


envelope.STATE = {
    IDLE = 0,
    ATTACK = 1,
    DECAY = 2,
    SUSTAIN = 3,
    RELEASE = 4
}


envelope.create = function(params)
    params = params or {}

    local env = {
        attack = params.attack or 0.1,
        decay = params.decay or 0.2,
        sustain = params.sustain or 0.7,
        release = params.release or 0.3,

        state = envelope.STATE.IDLE,
        value = 0,
        startTime = 0,
        source = nil,
        baseVolume = 1
    }


    function env:trigger()
        self.state = envelope.STATE.ATTACK
        self.startTime = osga.system.getTime()
        self.value = 0
        return self
    end

    function env:release()
        if self.state ~= envelope.STATE.IDLE then
            self.state = envelope.STATE.RELEASE
            self.startTime = osga.system.getTime()
        end
        return self
    end

    function env:update()
        if self.state == envelope.STATE.IDLE then
            return self.value
        end

        local currentTime = osga.system.getTime()
        local deltaTime = currentTime - self.startTime


        if self.state == envelope.STATE.ATTACK then
            if deltaTime < self.attack then
                self.value = (deltaTime / self.attack)
            else
                self.state = envelope.STATE.DECAY
                self.startTime = currentTime
                self.value = 1
            end
        elseif self.state == envelope.STATE.DECAY then
            if deltaTime < self.decay then
                self.value = 1 - ((1 - self.sustain) * (deltaTime / self.decay))
            else
                self.state = envelope.STATE.SUSTAIN
                self.value = self.sustain
            end
        elseif self.state == envelope.STATE.RELEASE then
            if deltaTime < self.release then
                self.value = self.sustain * (1 - (deltaTime / self.release))
            else
                self.state = envelope.STATE.IDLE
                self.value = 0
            end
        end


        if self.source then
            self.source:setVolume(self.value * self.baseVolume)
        end

        return self.value
    end

    function env:attach(source, baseVolume)
        self.source = source
        self.baseVolume = baseVolume or 1
        return self
    end

    return env
end


envelope.presets = {

    perc = function()
        return envelope.create({
            attack = 0.01,
            decay = 0.1,
            sustain = 0,
            release = 0.1
        })
    end,


    pad = function()
        return envelope.create({
            attack = 0.5,
            decay = 0.3,
            sustain = 0.8,
            release = 1.0
        })
    end,


    pluck = function()
        return envelope.create({
            attack = 0.05,
            decay = 0.1,
            sustain = 0.3,
            release = 0.2
        })
    end
}

return envelope
