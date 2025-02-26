-- libs/json.lua
-- parse and encode json
-- by hugelton instruments 2025

local json = {}

-- Simplified JSON parser
function json.decode(str)
    -- Convert JSON string to Lua table using load()
    local f = load("return " .. str:gsub('("[^"]-"):', '[%1]='))
    if f then
        return f()
    end
    return nil
end

-- Simple JSON encoder
function json.encode(tbl)
    local function serialize(val)
        if type(val) == "table" then
            local res = "{"
            for k, v in pairs(val) do
                if type(k) == "string" then
                    res = res .. string.format('"%s":', k)
                else
                    res = res .. string.format("[%s]=", k)
                end
                res = res .. serialize(v) .. ","
            end
            return res:sub(1, -2) .. "}"
        elseif type(val) == "string" then
            return string.format('"%s"', val)
        else
            return tostring(val)
        end
    end
    return serialize(tbl)
end

return json
