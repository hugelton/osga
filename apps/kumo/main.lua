-- apps/kumo/main.lua
local app = {}

app._meta = {
    name = "Kumo",
    slug = "kumo",
    author = "System",
    version = "1.0.0"
}


local installedApps = {}
local selectedIndex = 1
local GRID_COLS = 4
local GRID_ROWS = 3
local ICON_SIZE = 64
local PADDING = 20
local startX = 24 + (320 - (GRID_COLS * (ICON_SIZE + PADDING))) / 2
local startY = 24 + (240 - (GRID_ROWS * (ICON_SIZE + PADDING))) / 2
local defaultIcon = nil
local appLaunchRequested = false
local selectedApp = nil


local function getAbsolutePath(path)
    return osga.paths.root .. "/" .. path
end


local function readFile(path)
    local file = io.open(getAbsolutePath(path), "r")
    if not file then
        print("Failed to open file:", getAbsolutePath(path))
        return nil
    end
    local content = file:read("*all")
    file:close()
    return content
end


local function parseJSON(str)
    local orderedKeys = {}


    for key in str:gmatch('"([^"]+)"%s*:') do
        table.insert(orderedKeys, key)
    end


    str = str:gsub('"([^"]-)"%s*:%s*', "[%1]=")
    str = str:gsub('%[([^%]]-)%]', "['%1']")
    local chunk = load("return " .. str)
    if chunk then
        local data = chunk()

        return data, orderedKeys
    end
    return nil, nil
end


local function loadAppIcon(appPath)
    local iconPath = getAbsolutePath(appPath .. "/icon.png")
    print("Trying to load icon from:", iconPath)

    local file = io.open(iconPath, "rb")
    if file then
        print("File exists at:", iconPath)
        local data = file:read("*all")
        file:close()

        local success, fileData = pcall(love.filesystem.newFileData, data, "icon.png")
        if success then
            local success2, icon = pcall(love.graphics.newImage, fileData)
            if success2 then
                print("Successfully loaded icon:", iconPath)
                return icon
            end
        end
    end

    print("Failed to load icon:", iconPath, ". Using default icon.")
    return defaultIcon
end

function app.init()
    print("Initializing Kumo")


    local defaultIconPath = getAbsolutePath("osga-sim/assets/default_icon.png")
    local file = io.open(defaultIconPath, "rb")
    if file then
        local data = file:read("*all")
        file:close()
        local fileData = love.filesystem.newFileData(data, "default_icon.png")
        defaultIcon = love.graphics.newImage(fileData)
        print("Default icon loaded successfully")
    else
        print("Error: Could not load default icon from", defaultIconPath)
        return
    end


    local content = readFile("apps/installed.json")
    if not content then
        print("Error: Could not read installed.json")
        return
    end

    print("Read installed.json content:", content)


    local apps, orderedKeys = parseJSON(content)
    if not apps or not orderedKeys then
        print("Error: Could not parse installed.json")
        return
    end


    for _, shortcode in ipairs(orderedKeys) do
        if shortcode ~= "kumo" then
            local appPath = "apps/" .. shortcode
            local icon = loadAppIcon(appPath)
            table.insert(installedApps, {
                shortcode = shortcode,
                name = apps[shortcode],
                icon = icon,
                path = appPath
            })
            print("Loaded app:", shortcode)
        end
    end
end

function app.draw(koto)
    love.graphics.clear(0.1, 0.1, 0.1, 1)


    for i, app in ipairs(installedApps) do
        local row = math.floor((i - 1) / GRID_COLS)
        local col = (i - 1) % GRID_COLS
        local x = startX + col * (ICON_SIZE + 8)
        local y = startY + row * (ICON_SIZE + PADDING + 2)


        if i == selectedIndex then
            love.graphics.setColor(0.3, 0.3, 0.3)
            love.graphics.rectangle("fill",
                x - 4, y - 4,
                ICON_SIZE + 8, ICON_SIZE + 20
            )
        end


        love.graphics.setColor(1, 1, 1)
        if app.icon then
            love.graphics.draw(app.icon, x, y, 0,
                ICON_SIZE / app.icon:getWidth(),
                ICON_SIZE / app.icon:getHeight()
            )
        end


        love.graphics.printf(
            app.name,
            x - PADDING / 2,
            y + ICON_SIZE + 2,
            ICON_SIZE + PADDING,
            "center"
        )
    end


    if koto.rotaryInc then
        selectedIndex = selectedIndex + 1
        if selectedIndex > #installedApps then
            selectedIndex = 1
        end
    elseif koto.rotaryDec then
        selectedIndex = selectedIndex - 1
        if selectedIndex < 1 then
            selectedIndex = #installedApps
        end
    end


    if koto.swA and not appLaunchRequested then
        selectedApp = installedApps[selectedIndex]
        if selectedApp then
            print("Requesting app launch:", selectedApp.shortcode)
            appLaunchRequested = true
            return
        end
    end


    if appLaunchRequested and not koto.swA then
        print("Launching app:", selectedApp.shortcode)
        loadApp(selectedApp.path)
        appLaunchRequested = false
        selectedApp = nil
    end
end

function app.cleanup()
    for _, app in ipairs(installedApps) do
        if app.icon then
            app.icon:release()
        end
    end
    if defaultIcon then
        defaultIcon:release()
    end
end

return app
