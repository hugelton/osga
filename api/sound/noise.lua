-- api/sound/noise.lua

local noise = {}


noise._sampleRate = 44100
noise._bufferSize = 4410


noise._buffers = {}
noise._lastUpdate = {}


function noise.createWhiteNoise(duration)
    duration = duration or 1.0
    local numSamples = math.floor(noise._sampleRate * duration)
    local data = love.sound.newSoundData(numSamples, noise._sampleRate, 16, 1)


    for i = 0, numSamples - 1 do
        data:setSample(i, math.random() * 2 - 1)
    end

    local source = love.audio.newSource(data)
    return source
end

function noise.createStreamingNoise()
    local data = love.sound.newSoundData(noise._bufferSize, noise._sampleRate, 16, 1)


    local function fillBuffer()
        for i = 0, noise._bufferSize - 1 do
            data:setSample(i, math.random() * 2 - 1)
        end
    end


    fillBuffer()


    local source = love.audio.newSource(data)
    source:setLooping(true)


    local sourceId = tostring(source)
    noise._buffers[sourceId] = data
    noise._lastUpdate[sourceId] = love.timer.getTime()


    source.update = function()
        local currentTime = love.timer.getTime()
        if currentTime - noise._lastUpdate[sourceId] >= 0.05 then
            if source:isPlaying() then
                fillBuffer()
            end
            noise._lastUpdate[sourceId] = currentTime
        end
    end


    source.cleanup = function()
        noise._buffers[sourceId] = nil
        noise._lastUpdate[sourceId] = nil
    end

    return source
end

function noise.cleanup(source)
    if source and source.cleanup then
        source:cleanup()
    end
end

function noise.cleanupAll()
    noise._buffers = {}
    noise._lastUpdate = {}
end

return noise
