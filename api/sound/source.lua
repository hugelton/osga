-- api/sound/source.lua
local Source = {}
Source.__index = Source

function Source.new(generator)
    local self = setmetatable({}, Source)
    self.generator = generator
    self.position = 0
    return self
end

function Source:getSample()
    local sample = self.generator(self.position)
    self.position = self.position + 1
    return sample
end

return Source
