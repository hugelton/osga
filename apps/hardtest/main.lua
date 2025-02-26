-- apps/hardtest/main.lua

-- osga hardware check test app
-- gyro : rotate cube x,y
-- rotary : rotate cube z
-- a/b/c button : play sound
-- rotary click : cube wire frame / fill change

local app = {}

app._meta = {
    name = "Hardware Test",
    slug = "hardtest",
    author = "Leo Kuroshita",
    author_url = "https://hoge.com/",
    app_url = "https://github.com/hoge/hardtest/",
    version = "1.0.0"
}


local rotaryZ = 0
local sounds = {
    a = nil,
    b = nil,
    c = nil
}
local recentRotaryTicks = 0
local fillMode = false


local faces = {


    { vertices = { 1, 2, 3, 4 }, normal = { 0, 0, 1 } },
    { vertices = { 5, 6, 7, 8 }, normal = { 0, 0, -1 } },
    { vertices = { 1, 2, 6, 5 }, normal = { 0, -1, 0 } },
    { vertices = { 3, 4, 8, 7 }, normal = { 0, 1, 0 } },
    { vertices = { 1, 4, 8, 5 }, normal = { -1, 0, 0 } },
    { vertices = { 2, 3, 7, 6 }, normal = { 1, 0, 0 } }
}


local function rotatePoint(point, angleX, angleY, angleZ)
    local cos, sin = math.cos, math.sin
    local x, y, z = point[1], point[2], point[3]

    y, z = y * cos(angleX) - z * sin(angleX), y * sin(angleX) + z * cos(angleX)
    x, z = x * cos(angleY) + z * sin(angleY), -x * sin(angleY) + z * cos(angleY)
    x, y = x * cos(angleZ) - y * sin(angleZ), x * sin(angleZ) + y * cos(angleZ)

    return { x, y, z }
end

local function project(point, width, height)
    local scale = 50
    local x = point[1] * scale + width / 2
    local y = point[2] * scale + height / 2
    return { x, y }
end

local function calculateNormal(face, rotatedVertices)
    local v1 = rotatedVertices[face.vertices[1]]
    local v2 = rotatedVertices[face.vertices[2]]
    local v3 = rotatedVertices[face.vertices[3]]

    local ax = v2[1] - v1[1]
    local ay = v2[2] - v1[2]
    local az = v2[3] - v1[3]
    local bx = v3[1] - v1[1]
    local by = v3[2] - v1[2]
    local bz = v3[3] - v1[3]

    local nx = ay * bz - az * by
    local ny = az * bx - ax * bz
    local nz = ax * by - ay * bx

    local length = math.sqrt(nx * nx + ny * ny + nz * nz)
    return { nx / length, ny / length, nz / length }
end

function app.init()
    print("App initialized")


    sounds.a = osga.sound.synth.newSquare('C4')
    sounds.b = osga.sound.synth.newSquare('E4')
    sounds.c = osga.sound.synth.newSawtooth('G4')


    osga.sound.filter.presets.muffled(sounds.a)
    osga.sound.filter.presets.tinny(sounds.b)
    osga.sound.filter.presets.telephone(sounds.c)

    print("Sounds initialized")
end

function app.draw(koto)
    osga.gfx.clear(0, 0, 0)
    osga.gfx.color(1, 1, 1)


    if koto.swR and not prevSwR then
        fillMode = not fillMode
    end
    prevSwR = koto.swR

    local width = osga.system.width
    local height = osga.system.height


    rotaryZ = (koto.rotaryValue / 180 - 1) * math.pi


    local angleX = koto.gyroY * math.pi / 2
    local angleY = koto.gyroX * math.pi / 2
    local angleZ = rotaryZ


    local vertices = {
        { -1, -1, 1 }, { 1, -1, 1 }, { 1, 1, 1 }, { -1, 1, 1 },
        { -1, -1, -1 }, { 1, -1, -1 }, { 1, 1, -1 }, { -1, 1, -1 }
    }


    local rotatedVertices = {}
    for _, vertex in ipairs(vertices) do
        table.insert(rotatedVertices, rotatePoint(vertex, angleX, angleY, angleZ))
    end


    local baseColor = { 1, 1, 1 }
    if koto.swA then
        baseColor = { 1, 0, 0 }
        if not osga.sound.isSourcePlaying(sounds.a) then
            osga.sound.playSource(sounds.a)
        end
    elseif koto.swB then
        baseColor = { 0, 1, 0 }
        if not osga.sound.isSourcePlaying(sounds.b) then
            osga.sound.playSource(sounds.b)
        end
    elseif koto.swC then
        baseColor = { 0, 0, 1 }
        if not osga.sound.isSourcePlaying(sounds.c) then
            osga.sound.playSource(sounds.c)
        end
    else
        osga.sound.stopSource(sounds.a)
        osga.sound.stopSource(sounds.b)
        osga.sound.stopSource(sounds.c)
    end

    if fillMode then
        local facesWithDepth = {}
        for i, face in ipairs(faces) do
            local centerZ = 0
            for _, vIdx in ipairs(face.vertices) do
                centerZ = centerZ + rotatedVertices[vIdx][3]
            end
            centerZ = centerZ / #face.vertices
            table.insert(facesWithDepth, { face = face, depth = centerZ, index = i })
        end
        table.sort(facesWithDepth, function(a, b) return a.depth < b.depth end)


        for _, faceData in ipairs(facesWithDepth) do
            local face = faceData.face
            local normal = calculateNormal(face, rotatedVertices)
            local lightIntensity = math.abs(normal[3]) * 0.8 + 0.2

            osga.gfx.color(
                baseColor[1] * lightIntensity,
                baseColor[2] * lightIntensity,
                baseColor[3] * lightIntensity
            )

            local points = {}
            for _, vIdx in ipairs(face.vertices) do
                local projected = project(rotatedVertices[vIdx], width, height)
                table.insert(points, projected[1])
                table.insert(points, projected[2])
            end
            osga.gfx.polygon(points, "fill")
        end
    else
        osga.gfx.color(baseColor)
        local edges = {
            { 1, 2 }, { 2, 3 }, { 3, 4 }, { 4, 1 },
            { 5, 6 }, { 6, 7 }, { 7, 8 }, { 8, 5 },
            { 1, 5 }, { 2, 6 }, { 3, 7 }, { 4, 8 }
        }

        osga.gfx.lineWidth(2)
        for _, edge in ipairs(edges) do
            local start = project(rotatedVertices[edge[1]], width, height)
            local finish = project(rotatedVertices[edge[2]], width, height)
            osga.gfx.line(start[1], start[2], finish[1], finish[2])
        end
    end


    osga.gfx.color(1, 1, 1)
    osga.gfx.text(string.format("gyroX = %.1f", koto.gyroX), 10, 10)
    osga.gfx.text(string.format("gyroY = %.1f", koto.gyroY), 10, 30)
    osga.gfx.text(string.format("rotary = %.1f", rotaryZ), 10, 50)
    osga.gfx.text("mode = " .. (fillMode and "fill" or "wire"), 10, 70)


    if koto.swA then osga.gfx.text("A button", 10, 120) end
    if koto.swB then osga.gfx.text("B button", 10, 140) end
    if koto.swC then osga.gfx.text("C button", 10, 160) end
    if koto.swR then osga.gfx.text("R button", 10, 180) end
end

function app.cleanup()
    for _, sound in pairs(sounds) do
        if sound then
            osga.sound.stopSource(sound)
        end
    end
end

return app
