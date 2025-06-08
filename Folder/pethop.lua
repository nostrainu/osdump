if not game:IsLoaded() then game.Loaded:Wait() end
loadstring(game:HttpGet("https://raw.githubusercontent.com/uzu01/arise/refs/heads/main/global.lua"))()
_G.JxereasExistingHooks = { GuiDetectionBypass = true }

local rs = game:GetService("ReplicatedStorage")
local ds = require(rs.Modules.DataService)
local http = game:GetService("HttpService")
local tp = game:GetService("TeleportService")
local plr = game.Players.LocalPlayer
local gd

local imgs = {
    ["Queen Bee"] = "https://static.wikia.nocookie.net/growagarden/images/7/7a/Queen_bee.png",
    ["Dragonfly"] = "https://static.wikia.nocookie.net/growagarden/images/c/c9/DragonflyIcon.png",
    ["Disco Bee"] = "https://static.wikia.nocookie.net/growagarden/images/5/56/Bee.png",
    ["Raccoon"] = "https://static.wikia.nocookie.net/growagarden/images/5/54/Raccon_Better_Quality.png"
}

local function wh(url, name, w, c, ping)
    local eb = {
        title = name,
        color = imgs[name] and 0xff8800 or 0x00ffcc,
        thumbnail = { url = imgs[name] or "https://media.tenor.com/VLnaNrQmjMoAAAAi/transparent-anime.gif" },
        fields = {
            { name = "Weight", value = w and ("%.2f kg"):format(w) or "Unknown", inline = true },
            { name = "Chance", value = c and ("%.2f%%"):format(c) or "Unknown", inline = true }
        },
        footer = { text = "User: " .. plr.DisplayName }
    }

    pcall(function()
        request({
            Url = url,
            Method = "POST",
            Headers = { ["Content-Type"] = "application/json" },
            Body = http:JSONEncode({ content = ping or "", embeds = { eb } })
        })
    end)
end

task.wait(3)
for _, v in workspace.Farm:GetChildren() do
    if v:FindFirstChild("Important") and v.Important:FindFirstChild("Data") and v.Important.Data:FindFirstChild("Owner") then
        if v.Important.Data.Owner.Value == plr.Name then gd = v break end
    end
end

local function egg(uid)
    for _, v in gd.Important.Objects_Physical:GetChildren() do
        if v.Name:match("PetEgg") and v:GetAttribute("OBJECT_UUID") == uid then return v end
    end
end

local function n(s)
    return tostring(s):lower():gsub("^%s*(.-)%s*$", "%1")
end

local tgt = {}
for _, v in ipairs(getgenv().target_pets or {}) do tgt[n(v)] = true end

local fTpet = false

for uid, v in ds:GetData().SavedObjects do
    local d = v.Data
    if not d or not d.EggName or not d.RandomPetData then continue end
    local pn = d.RandomPetData.Name
    if not pn or not tgt[n(pn)] then continue end
    fTpet = true
    if getgenv().webhook_url then
        wh(getgenv().webhook_url, pn, d.RandomPetData.Weight, d.RandomPetData.Chance, getgenv().pingUser)
    end
    local e = egg(uid)
    if e then
        rs.GameEvents.PetEggService:FireServer("HatchPet", e)
        task.wait(10)
        tp:Teleport(game.PlaceId)
        break
    end
end

if not fTpet then tp:Teleport(game.PlaceId) end

queue_on_teleport('loadstring(game:HttpGet("https://raw.githubusercontent.com/nostrainu/osdump/refs/heads/main/Folder/pethop.lua"))()')
