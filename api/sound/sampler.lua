-- api/sound/sampler.lua
local Source = require('api.sound.source')

local sampler = {}


sampler._cache = {}


function sampler.load(filepath)
    if sampler._cache[filepath] then
        return sampler._cache[filepath]
    end


    local success, soundData = pcall(love.sound.newSoundData, filepath)

    if not success then
        print("Error loading sample: " .. filepath)
        print(soundData)
        return nil
    end


    sampler._cache[filepath] = soundData
    return soundData
end

function sampler.newSampleSource(filepath, options)
    options = options or {}


    local sampleData = sampler.load(filepath)
    if not sampleData then
        return nil
    end


    local sampleRate = sampleData:getSampleRate()
    local sampleCount = sampleData:getSampleCount()
    local channels = sampleData:getChannels()


    local loop = options.loop or false
    local startPos = options.startPos or 0
    local endPos = options.endPos or sampleCount - 1
    local speed = options.speed or 1.0


    local currentPos = startPos
    local isPlaying = true


    local source = Source.new(function()
        if not isPlaying then
            return 0
        end


        if currentPos > endPos then
            if loop then
                currentPos = startPos
            else
                isPlaying = false
                return 0
            end
        end


        local sample = 0
        if channels == 1 then
            sample = sampleData:getSample(math.floor(currentPos))
        else
            local leftIndex = math.floor(currentPos) * 2
            local rightIndex = leftIndex + 1
            if rightIndex < sampleCount * 2 then
                sample = (sampleData:getSample(leftIndex) + sampleData:getSample(rightIndex)) * 0.5
            else
                sample = sampleData:getSample(leftIndex)
            end
        end


        currentPos = currentPos + speed

        return sample
    end)


    source.setSpeed = function(self, newSpeed)
        speed = newSpeed
    end

    source.setLoop = function(self, shouldLoop)
        loop = shouldLoop
    end

    source.setRange = function(self, newStart, newEnd)
        startPos = newStart or startPos
        endPos = newEnd or endPos
        currentPos = startPos
    end

    source.isFinished = function(self)
        return not isPlaying
    end

    source.restart = function(self)
        currentPos = startPos
        isPlaying = true
    end

    source.stop = function(self)
        isPlaying = false
    end

    source.start = function(self)
        isPlaying = true
    end

    return source
end

function sampler.clearCache()
    sampler._cache = {}
end

return sampler
