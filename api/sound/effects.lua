-- api/sound/effects.lua

local effects = {

    lfo = {
        create = function(params)
            params = params or {}
            local lfo = {
                rate = params.rate or 1.0,
                depth = params.depth or 1.0,
                center = params.center or 0.5,
                phase = 0,
                waveform = params.waveform or "sine",
            }

            function lfo:update(dt)
                self.phase = self.phase + (self.rate * dt * math.pi * 2)
                if self.phase >= math.pi * 2 then
                    self.phase = self.phase - math.pi * 2
                end

                local value = 0
                if self.waveform == "sine" then
                    value = math.sin(self.phase)
                elseif self.waveform == "triangle" then
                    value = 1 -
                        4 * math.abs(math.floor((self.phase / (math.pi * 2)) + 0.5) - (self.phase / (math.pi * 2)))
                elseif self.waveform == "square" then
                    value = self.phase < math.pi and 1 or -1
                end

                return self.center + (value * self.depth)
            end

            function lfo:setRate(rate)
                self.rate = rate
            end

            function lfo:setDepth(depth)
                self.depth = depth
            end

            function lfo:setCenter(center)
                self.center = center
            end

            return lfo
        end
    },


    delay = {
        create = function(params)
            params = params or {}
            local delay = {
                buffer = {},
                length = params.length or 0.2,
                mix = params.mix or 0.3,
                feedback = params.feedback or 0.4,
                bufferSize = math.floor((params.length or 0.2) * 44100),
                writePos = 1,
                sampleRate = 44100
            }


            for i = 1, delay.bufferSize do
                delay.buffer[i] = 0
            end

            function delay:process(input)
                self.buffer[self.writePos] = input + (self.buffer[self.writePos] * self.feedback)


                local readPos = self.writePos - math.floor(self.length * self.sampleRate)
                if readPos < 1 then readPos = readPos + self.bufferSize end


                local output = (input * (1 - self.mix)) + (self.buffer[readPos] * self.mix)


                self.writePos = self.writePos + 1
                if self.writePos > self.bufferSize then self.writePos = 1 end

                return output
            end

            function delay:setMix(mix)
                self.mix = math.max(0, math.min(1, mix))
            end

            function delay:setFeedback(feedback)
                self.feedback = math.max(0, math.min(0.99, feedback))
            end

            return delay
        end
    }
}

return effects
