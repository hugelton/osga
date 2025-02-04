-- scripts/tests/nami_test.lua

print("Starting NAMI test script...")

-- Debug function to print available globals
local function print_globals()
    local globals = {}
    for k, v in pairs(_G) do
        table.insert(globals, k)
    end
    print("Available globals: " .. table.concat(globals, ", "))
end

print("Before init - checking globals:")
print_globals()

function init()
    print("Initializing NAMI test...")
    print("Checking globals in init:")
    print_globals()

    if not nami then
        print("Error: 'nami' global not found!")
        return
    end

    -- Create synthesizers
    synth = nami.createSynth()
    if not synth then
        print("Error: Failed to create synth!")
        return
    end

    synth:setWaveform("sine")
    synth:setAttack(0.1)
    synth:setDecay(0.2)
    synth:setSustain(0.7)
    synth:setRelease(0.3)

    -- Create mixer channel
    channel = nami.createChannel()
    if not channel then
        print("Error: Failed to create channel!")
        return
    end

    -- Connect synth to channel
    if not nami.connectToChannel(synth.id, channel) then
        print("Error: Failed to connect synth to channel!")
        return
    end

    print("NAMI test initialized successfully")
end

function update()
    -- Update test sequence
end

function cleanup()
    print("Cleaning up NAMI test...")
end
