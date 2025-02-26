-- api/sound/init.lua
local Channel = require('api.sound.channel')
local Filter = require('api.sound.effects.filter')
local synth = require('api.sound.synth')
local utils = require('api.sound.utils')
local sampler = require('api.sound.sampler')
local lfo = require('api.sound.lfo')

local sound = {
    channel = Channel,
    filter = Filter,
    synth = synth,
    utils = utils,
    sampler = sampler,
    lfo = lfo,
    activeChannels = {}
}

function sound.addChannel(channel)
    table.insert(sound.activeChannels, channel)
end

function sound.removeChannel(channel)
    for i, ch in ipairs(sound.activeChannels) do
        if ch == channel then
            table.remove(sound.activeChannels, i)
            break
        end
    end
end

function sound.update()
    for _, channel in ipairs(sound.activeChannels) do
        channel:update()
    end
end

return sound
