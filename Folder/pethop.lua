if not game:IsLoaded() then game.Loaded:Wait() end
loadstring(game:HttpGet("https://raw.githubusercontent.com/uzu01/arise/refs/heads/main/global.lua"))()

_G.JxereasExistingHooks  = {GuiDetectionBypass  = true}

local replicated_storage = game:GetService("ReplicatedStorage")
local data_service = require(replicated_storage.Modules.DataService)
local http_service = game:GetService("HttpService")
local teleport_service = game:GetService("TeleportService")
local player = game.Players.LocalPlayer
local garden

local petImages = {
    ["Queen Bee"] = "https://static.wikia.nocookie.net/growagarden/images/7/7a/Queen_bee.png",
    ["Dragonfly"] = "https://static.wikia.nocookie.net/growagarden/images/c/c9/DragonflyIcon.png",
    ["Disco Bee"] = "https://static.wikia.nocookie.net/growagarden/images/5/56/Bee.png",
    ["Raccoon"] = "https://static.wikia.nocookie.net/growagarden/images/5/54/Raccon_Better_Quality.png"
}

function send_webhook(url, petName, weight, chance)
    local imageUrl = petImages[petName]
    local playerName = game:GetService("Players").LocalPlayer.DisplayName

    local description = ""

    if weight and type(weight) == "number" then
        description = description .. string.format("**Weight:** %.2f kg", weight)
    else
        description = description .. "**Weight:** Unknown"
    end

    if chance and type(chance) == "number" then
        description = description .. string.format("\n**Chance:** %.2f%%", chance)
    else
        description = description .. "\n**Chance:** Unknown"
    end

    local embed = {
        title = petName,
        color = 0xffc800,
        description = description,
        thumbnail = {
            url = imageUrl or "https://cdn-icons-png.flaticon.com/512/616/616408.png"
        },
        footer = {
            text = "User: " .. playerName
        }
    }

    local payload = {
        content = "",
        embeds = { embed }
    }

    request({
        Url = url,
        Method = "POST",
        Headers = { ["Content-Type"] = "application/json" },
        Body = game:GetService("HttpService"):JSONEncode(payload)
    })
end

task.wait(3)

for _, v in workspace.Farm:GetChildren() do
    if v:FindFirstChild("Important") and v.Important:FindFirstChild("Data") and v.Important.Data:FindFirstChild("Owner") then
        if v.Important.Data.Owner.Value == player.Name then
            garden = v
            break
        end
    end
end

function get_egg(uid)
    for _, v in garden.Important.Objects_Physical:GetChildren() do
        if v.Name:match("PetEgg") and v:GetAttribute("OBJECT_UUID") == uid then
            return v
        end
    end
    return nil
end

local function normalize(s)
    return (tostring(s):lower():gsub("^%s*(.-)%s*$", "%1"))
end

local normalizedTargets = {}
for _, name in ipairs(getgenv().target_pets or {}) do
    normalizedTargets[normalize(name)] = true
end

local foundTargetPet = false

for uid, v in data_service:GetData().SavedObjects do
    local data = v.Data
    if not data or not data.EggName or not data.RandomPetData then continue end

    local petName = data.Type
    if not petName or not normalizedTargets[normalize(petName)] then continue end

    foundTargetPet = true

    if getgenv().webhook_url then
        send_webhook(getgenv().webhook_url, petName, data.RandomPetData.Weight, getgenv().pingUser)
    end

    local egg = get_egg(uid)
    if egg then
        replicated_storage.GameEvents.PetEggService:FireServer("HatchPet", egg)
        task.wait(10)
        teleport_service:Teleport(game.PlaceId)
        break
    end
end

if not foundTargetPet then
    teleport_service:Teleport(game.PlaceId)
end

queue_on_teleport('loadstring(game:HttpGet("https://pastebin.com/raw/BE36f3z8"))()')
