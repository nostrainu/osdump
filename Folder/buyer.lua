local hp = game:GetService("HttpService")
local rs = game:GetService("ReplicatedStorage")
local plrs = game:GetService("Players")
local plr = plrs.LocalPlayer
local name = plr.DisplayName
local url = _G.webhookUrl or ""
local uid = _G.userId or ""
local bl = _G.blacklist or {}
local evt = rs:WaitForChild("GameEvents"):WaitForChild("BuyEventShopStock")

local req = syn and syn.request or http_request or request

local function wh(t, f, c)
    if not req or url == "" then return end
    local body = {
        embeds = {{
            title = t,
            color = c or 0x00FF00,
            fields = f,
            timestamp = os.date("!%Y-%m-%dT%H:%M:%SZ"),
        }}
    }
    pcall(function()
        req({
            Url = url,
            Method = "POST",
            Headers = {
                ["Content-Type"] = "application/json",
                ["User-Agent"] = "Roblox-Script"
            },
            Body = hp:JSONEncode(body),
        })
    end)
end

local function buy()
    print("buy")
    local d = require(rs.Modules.DataService):GetData()
    local s = d.EventShopStock.Stocks
    local got = {}

    for i, _ in pairs(s) do
        if bl[i] then continue end
        evt:FireServer(i)
        print("Purchased:", i)
        table.insert(got, i)
    end

    if #got > 0 then
        local list = "• " .. table.concat(got, "\n• ")
        local ping = (table.find(got, "Candy Blossom") and uid ~= "") and "<@" .. uid .. ">" or "No ping"

        wh("Stock Purchased", {
            { name = "Info", value = ping },
            { name = "Stocks", value = list },
            { name = "User:", value = name }
        }, 0x00FF00)
    end
end

workspace:GetAttributeChangedSignal("NightEvent"):Connect(function()
    if workspace:GetAttribute("NightEvent") then
        wh("Night Event Started", {
            { name = "From:", value = name }
        }, 0x0000FF)
    end
end)

if workspace:GetAttribute("NightEvent") then
    wh("Night Event Started", {
        { name = "From:", value = name }
    }, 0x0000FF)
end

workspace:GetAttributeChangedSignal("BloodMoonEvent"):Connect(function()
    if workspace:GetAttribute("BloodMoonEvent") then
        wh("BloodMoon Event Started", {
            { name = "From:", value = name }
        }, 0xFF0000)
        buy()
    end
end)

if workspace:GetAttribute("BloodMoonEvent") then
    wh("BloodMoon Event Started", {
        { name = "From:", value = name }
    }, 0xFF0000)
    buy()
end

wh("Script Started", {
    { name = "User:", value = name }
}, 0xFFFFFF)

print("Loaded. Waiting for NightEvent / BloodMoonEvent...")
