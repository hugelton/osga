-- api/sound/channel.lua
local Channel = {}
Channel.__index = Channel

function Channel.new()
    local self = setmetatable({}, Channel)
    self.sources = {}
    self.effects = {}
    self.output = love.audio.newQueueableSource(44100, 16, 1, 4)
    self.bufferSize = 1024
    self.running = false
    self.volume = 1.0
    return self
end

function Channel:addSource(source)
    table.insert(self.sources, source)
end

function Channel:addEffect(effect)
    table.insert(self.effects, effect)
end

function Channel:update()
    if not self.running then
        return
    end


    if self.output:getFreeBufferCount() > 0 then
        local buffer = love.sound.newSoundData(self.bufferSize, 44100, 16, 1)


        for i = 0, buffer:getSampleCount() - 1 do
            local mixed = 0
            for _, source in ipairs(self.sources) do
                mixed = mixed + source:getSample()
            end


            local original = mixed
            for _, effect in ipairs(self.effects) do
                mixed = effect:process(mixed)
            end



            mixed = mixed * self.volume


            mixed = math.max(-1.0, math.min(1.0, mixed))
            buffer:setSample(i, mixed)
        end


        self.output:queue(buffer)
        self.output:play()
    end
end

function Channel:play()
    self.running = true

    self.output:play()
end

function Channel:stop()
    self.running = false
    self.output:stop()
end

return Channel
