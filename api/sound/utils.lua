-- api/sound/utils.lua
local utils = {}


utils.noteValues = {
    C = 0,
    D = 2,
    E = 4,
    F = 5,
    G = 7,
    A = 9,
    B = 11
}


function utils.noteToFrequency(noteStr)
    if not noteStr or type(noteStr) ~= 'string' then
        return 440
    end


    local note = noteStr:sub(1, 1)
    local octave = tonumber(noteStr:sub(2, 2))

    if not note or not octave then
        return 440
    end


    local baseFreq = 440.0
    local baseOctave = 4
    local baseNote = 9


    local noteValue = utils.noteValues[note]
    if not noteValue then
        return 440
    end


    local semitones = (octave - baseOctave) * 12 + (noteValue - baseNote)


    return baseFreq * math.pow(2, semitones / 12)
end

return utils
