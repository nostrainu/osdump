if not game:IsLoaded() then game.Loaded:Wait() end
loadstring(game:HttpGet("https://raw.githubusercontent.com/uzu01/arise/refs/heads/main/global.lua"))()

_G.JxereasExistingHooks  = {GuiDetectionBypass  = true}

local notification = loadstring(game:HttpGet("https://raw.githubusercontent.com/Jxereas/UI-Libraries/main/notification_gui_library.lua", true))()
local replicated_storage = game:GetService("ReplicatedStorage")
local data_service = require(replicated_storage.Modules.DataService)
local garden
local http_service = game:GetService("HttpService")

local imgs = {
    ["Queen Bee"] = "https://static.wikia.nocookie.net/growagarden/images/7/7a/Queen_bee.png",
    ["Dragonfly"] = "https://static.wikia.nocookie.net/growagarden/images/c/c9/DragonflyIcon.png",
    ["Disco Bee"] = "https://static.wikia.nocookie.net/growagarden/images/5/56/Bee.png",
    ["Raccoon"] = "https://static.wikia.nocookie.net/growagarden/images/5/54/Raccon_Better_Quality.png"
}

function send_webhook(url, petName, pingUser)
    local embed = {
        title = "Found pet: **" .. petName .. "** (Hatching now!)",
        color = 0xff8800,
        thumbnail = { url = imgs[petName] or "https://media.tenor.com/VLnaNrQmjMoAAAAi/transparent-anime.gif" },
        footer = { text = "User: " .. game.Players.LocalPlayer.DisplayName }
    }

    local body = {
        content = pingUser or "",
        embeds = { embed }
    }

    local req = request or (syn and syn.request) or http_request
    if req then
        local success, err = pcall(function()
            req({
                Url = url .. "?wait=true",
                Method = "POST",
                Headers = { ["Content-Type"] = "application/json" },
                Body = http_service:JSONEncode(body)
            })
        end)
        if not success then
            warn("Webhook send failed:", err)
        end
    else
        warn("No request function available for webhook")
    end
end

task.wait(3)

local player = game.Players.LocalPlayer

for i, v in workspace.Farm:GetChildren() do
    if v.Important.Data.Owner.Value == player.Name then
        garden = v
        break
    end
end

function get_egg(uid)
    for i, v in garden.Important.Objects_Physical:GetChildren() do
        if v.Name:match("PetEgg") and v:GetAttribute("OBJECT_UUID") == uid then
            return v
        end
    end
    return nil
end

local foundTargetPet = false

for i, v in data_service:GetData().SavedObjects do
    local data = v.Data
    local egg = data and data.EggName

    if not egg then continue end
    if not data.RandomPetData then continue end

    local petName = data.Type

    if not (getgenv().target_pets and table.find(getgenv().target_pets, petName)) then
        continue
    end

    foundTargetPet = true

    if getgenv().webhook_url then
        send_webhook(getgenv().webhook_url, petName, getgenv().pingUser)
    end

    replicated_storage.GameEvents.PetEggService:FireServer("HatchPet", get_egg(i))
    task.wait(10)
    game:GetService("TeleportService"):Teleport(game.PlaceId)
    break
end

if not foundTargetPet then
    game:GetService("TeleportService"):Teleport(game.PlaceId)
end

queue_on_teleport('loadstring(game:HttpGet("https://pastebin.com/raw/JBSyuV4f"))()')
