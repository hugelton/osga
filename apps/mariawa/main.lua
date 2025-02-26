-- apps/mariawa/main.lua

local app = {}
app._meta = {
    name = "Mariawa",
    slug = "mariawa",
    author = "Leo Kuroshita",
    author_url = "https://hoge.com/",
    app_url = "https://github.com/hoge/hardtest/",
    version = "1.0.0"
}


local circles = {}
local maxCircles = 32
local selectedParameter = 1
local lastSwA = false
local lastSwB = false
local lastSwR = false
local field = {
    x = 0,
    y = 0,
    width = 240,
    height = 240
}


local colors = {
    background = { 0, 0, 0 },
    field = { 0.15, 0.15, 0.17 },
    circle = { 0.75, 0.75, 0.75 },
    highlight = { 1, 1, 1 },
    shadow = { 0.2, 0.2, 0.22 },
    text = { 1, 1, 1 },
    selected = { 0.9, 0.9, 0.3 }
}


local root = 100
local octave = 2
local gravity = 1.0
local selectedScale = 1
local scales = {
    { name = "Major", intervals = { 0, 2, 4, 5, 7, 9, 11, 12 } },
    { name = "Minor", intervals = { 0, 2, 3, 5, 7, 8, 10, 12 } }
}

local parameters = {
    { name = "ROOT",    value = 100, min = 110, max = 880, step = 10 },
    { name = "OCTAVE",  value = 2,   min = 1,   max = 6,   step = 1 },
    { name = "SCALE",   value = 1,   min = 1,   max = 2,   step = 1 },
    { name = "GRAVITY", value = 100, min = 10,  max = 200, step = 1 }
}


local Circle = {}
Circle.__index = Circle

function Circle:new(x, y, radius)
    local circle = {}
    setmetatable(circle, Circle)
    circle.x = x
    circle.y = y
    circle.vx = 0
    circle.vy = 0
    circle.radius = radius
    circle.lastCollisionTime = 0
    return circle
end

function Circle:update(ax, ay)
    if ax and ay then
        self.vx = self.vx + ax * 0.2
        self.vy = self.vy + ay * 0.2
    end

    self.vx = self.vx * 0.99
    self.vy = self.vy * 0.99

    self.x = self.x + self.vx
    self.y = self.y + self.vy
end

function Circle:draw()
    local shadowOffsetX = self.radius * 0.3
    local shadowOffsetY = self.radius * 0.3


    osga.gfx.color(colors.shadow[1], colors.shadow[2], colors.shadow[3], 0.5)
    osga.gfx.circle(self.x + shadowOffsetX, self.y + shadowOffsetY, self.radius)


    osga.gfx.color(unpack(colors.circle))
    osga.gfx.circle(self.x, self.y, self.radius)


    local highlightRadius = self.radius * 0.3
    local highlightOffsetX = -self.radius * 0.3
    local highlightOffsetY = -self.radius * 0.3

    osga.gfx.color(colors.highlight[1], colors.highlight[2], colors.highlight[3], 0.7)
    osga.gfx.circle(self.x + highlightOffsetX, self.y + highlightOffsetY, highlightRadius)
end

function Circle:playTone()
    local speed = math.sqrt(self.vx * self.vx + self.vy * self.vy)
    local currentTime = osga.system.getTime()

    if speed > 0.4 and currentTime - self.lastCollisionTime > 0.1 then
        local scaleIndex = math.floor(self.radius / 2) % #scales[selectedScale].intervals
        local intervalIndex = scales[selectedScale].intervals[scaleIndex + 1]
        local frequency = root * math.pow(2, (octave - 1) + intervalIndex / 12)


        local channel = osga.sound.channel.new()


        local osc = osga.sound.synth.newOscillator('triangle', frequency)


        channel:addSource(osc)


        channel.duration = 0.05 + self.radius * 0.005
        channel.startTime = currentTime
        channel.volume = math.min(speed * 0.5, 1.0)


        if not app.activeChannels then
            app.activeChannels = {}
        end
        table.insert(app.activeChannels, channel)


        osga.sound.addChannel(channel)
        channel:play()

        self.lastCollisionTime = currentTime
    end
end

local function updateSounds()
    if not app.activeChannels then return end

    local currentTime = osga.system.getTime()
    for i = #app.activeChannels, 1, -1 do
        local channel = app.activeChannels[i]
        if currentTime - channel.startTime > channel.duration then
            channel:stop()
            osga.sound.removeChannel(channel)
            table.remove(app.activeChannels, i)
        end
    end
end

function app.init()
    print("Mariawa initialized")

    osga.gfx.setFont(osga.gfx.getNada())

    app.activeChannels = {}
end

function app.draw(koto)
    osga.gfx.clear(unpack(colors.background))


    osga.gfx.color(unpack(colors.field))
    osga.gfx.rect(field.x, field.y, field.width, field.height, "fill")


    osga.gfx.color(unpack(colors.text))
    osga.gfx.rect(field.x, field.y, field.width, field.height, "line")


    drawParameters()


    updateSounds()


    for _, circle in ipairs(circles) do
        circle:update(koto.gyroX * gravity * 0.5, koto.gyroY * gravity * 0.5)
        circle:draw()
    end


    checkCollision()


    if koto.swA and lastSwA ~= koto.swA then
        addCircle()
    end
    if koto.swB and lastSwB ~= koto.swB then
        removeCircle()
    end
    lastSwA = koto.swA
    lastSwB = koto.swB


    if koto.swR and lastSwR ~= koto.swR then
        selectedParameter = selectedParameter + 1
        if selectedParameter > #parameters then
            selectedParameter = 1
        end
    end
    lastSwR = koto.swR


    if koto.rotaryInc then
        local param = parameters[selectedParameter]
        param.value = math.min(param.value + param.step, param.max)
    elseif koto.rotaryDec then
        local param = parameters[selectedParameter]
        param.value = math.max(param.value - param.step, param.min)
    end


    root = parameters[1].value
    octave = parameters[2].value
    selectedScale = parameters[3].value
    gravity = parameters[4].value * 0.01
end

function addCircle()
    if #circles < maxCircles then
        local x = math.random(field.x + 20, field.x + field.width - 20)
        local y = math.random(field.y + 20, field.y + field.height - 20)
        local radius = math.random(5, 15)
        table.insert(circles, Circle:new(x, y, radius))
    end
end

function removeCircle()
    if #circles > 0 then
        table.remove(circles)
    end
end

function checkCollision()
    for i = 1, #circles do
        local circle1 = circles[i]


        if circle1.x < field.x + circle1.radius then
            circle1.x = field.x + circle1.radius
            circle1.vx = -circle1.vx * 0.8
            circle1:playTone()
        elseif circle1.x > field.x + field.width - circle1.radius then
            circle1.x = field.x + field.width - circle1.radius
            circle1.vx = -circle1.vx * 0.8
            circle1:playTone()
        end

        if circle1.y < field.y + circle1.radius then
            circle1.y = field.y + circle1.radius
            circle1.vy = -circle1.vy * 0.8
            circle1:playTone()
        elseif circle1.y > field.y + field.height - circle1.radius then
            circle1.y = field.y + field.height - circle1.radius
            circle1.vy = -circle1.vy * 0.8
            circle1:playTone()
        end


        for j = i + 1, #circles do
            local circle2 = circles[j]
            local dx = circle1.x - circle2.x
            local dy = circle1.y - circle2.y
            local distance = math.sqrt(dx * dx + dy * dy)
            local minDistance = circle1.radius + circle2.radius

            if distance < minDistance then
                local angle = math.atan2(dy, dx)
                local overlap = minDistance - distance

                circle1.x = circle1.x + math.cos(angle) * overlap * 0.5
                circle1.y = circle1.y + math.sin(angle) * overlap * 0.5
                circle2.x = circle2.x - math.cos(angle) * overlap * 0.5
                circle2.y = circle2.y - math.sin(angle) * overlap * 0.5


                local tempVx = circle1.vx
                local tempVy = circle1.vy
                circle1.vx = circle2.vx
                circle1.vy = circle2.vy
                circle2.vx = tempVx
                circle2.vy = tempVy


                circle1:playTone()
                circle2:playTone()
            end
        end
    end
end

function drawParameters()
    for i, param in ipairs(parameters) do
        local y = 20 + (i - 1) * 30
        local x = field.width + 10
        local value = param.value


        if param.name == "SCALE" then
            value = scales[param.value].name
        elseif param.name == "GRAVITY" then
            value = tostring(param.value) .. "%"
        end


        if i == selectedParameter then
            osga.gfx.color(unpack(colors.selected))
            osga.gfx.text("> " .. param.name, x, y)
            osga.gfx.text(tostring(value), x + 10, y + 15)
        else
            osga.gfx.color(unpack(colors.text))
            osga.gfx.text(param.name, x + 10, y)
            osga.gfx.text(tostring(value), x + 10, y + 15)
        end
    end


    osga.gfx.color(unpack(colors.text))
    local guideY = field.height - 80
    osga.gfx.text("Controls:", field.width + 10, guideY)
    osga.gfx.text("A: Add", field.width + 10, guideY + 20)
    osga.gfx.text("B: Remove", field.width + 10, guideY + 40)
    osga.gfx.text("Space: Select", field.width + 10, guideY + 60)
end

function app.cleanup()
    if app.activeChannels then
        for _, channel in ipairs(app.activeChannels) do
            channel:stop()
            osga.sound.removeChannel(channel)
        end
        app.activeChannels = {}
    end
end

return app
