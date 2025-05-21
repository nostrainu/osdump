------------------------------
-- Services & Variables
------------------------------
local HttpService = game:GetService("HttpService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")

local plr = Players.LocalPlayer
local displayName = plr.DisplayName

local wU = _G.webhookUrl or ""
local userId = _G.userId or ""

local nightEvent = ReplicatedStorage:WaitForChild("NightEvent", 10)
local BuyEventShopStock = ReplicatedStorage:WaitForChild("GameEvents"):WaitForChild("BuyEventShopStock")

------------------------------
-- Webhook Sender
------------------------------
local function sendWebhook(title, fields, color)
    local req = (syn and syn.request) or http_request or request
    if not req or wU == "" then return end

    local body = {
        embeds = {{
            title = title,
            color = color or 0x00FF00,
            fields = fields,
            timestamp = os.date("!%Y-%m-%dT%H:%M:%SZ"),
        }}
    }

    local success, err = pcall(function()
        req({
            Url = wU,
            Method = "POST",
            Headers = {
                ["Content-Type"] = "application/json",
                ["User-Agent"] = "Roblox-Script"
            },
            Body = HttpService:JSONEncode(body),
        })
    end)

    if not success then
        warn("Webhook error:", err)
    end
end

------------------------------
-- Buy Stock Logic
------------------------------
local function buyStocks()
    local data = require(ReplicatedStorage.Modules.DataService):GetData()
    local stocks = data.EventShopStock.Stocks

    local purchased = {}

    for stockName, _ in pairs(stocks) do
        if _G.blacklist and _G.blacklist[stockName] then
            continue
        end

        BuyEventShopStock:FireServer(stockName)
        print("Purchased stock:", stockName)
        table.insert(purchased, stockName)
    end

    if #purchased > 0 then
        local stockList = "• " .. table.concat(purchased, "\n• ")
        local ping = (table.find(purchased, "Candy Blossom") and userId ~= "") and ("<@" .. userId .. ">") or "No ping"

        sendWebhook(
            "Stock Purchased",
            {
                { name = "Info", value = ping, inline = false },
                { name = "Stocks", value = stockList, inline = false },
                { name = "Run by", value = displayName, inline = false }
            },
            0x00FF00
        )
    end
end

------------------------------
-- NightEvent Trigger
------------------------------
if nightEvent then
    nightEvent.Event:Connect(function()
        local isBloodMoon = workspace:GetAttribute("BloodMoonEvent")

        if isBloodMoon then
            sendWebhook(
                "Night Event Started - BloodMoon Active",
                {
                    { name = "Run by", value = displayName, inline = false }
                },
                0x0000FF
            )
            buyStocks()
        else
            sendWebhook(
                "Night Event Started - BloodMoon NOT Active",
                {
                    { name = "Run by", value = displayName, inline = false },
                    { name = "Info", value = "Skipped buying because BloodMoonEvent is inactive", inline = false }
                },
                0xAAAAAA
            )
        end
    end)
else
    warn("NightEvent not found!")
end

------------------------------
-- BloodMoonEvent Attribute Hook
------------------------------
workspace:GetAttributeChangedSignal("BloodMoonEvent"):Connect(function()
    local state = workspace:GetAttribute("BloodMoonEvent")
    print("[HOOK] BloodMoonEvent changed:", state)

    if state then
        sendWebhook(
            "BloodMoon Event Activated",
            {
                { name = "Run by", value = displayName, inline = false }
            },
            0xFF0000
        )
        buyStocks()
    end
end)

------------------------------
-- Initial Startup Webhook
------------------------------
sendWebhook(
    "Script Started",
    {
        { name = "Run by", value = displayName, inline = false }
    },
    0xFFFFFF
)

print("Script loaded. Waiting for NightEvent and BloodMoonEvent...")
