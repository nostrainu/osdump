if game.PlaceId == 126884695634066 and not game:IsLoaded() then
    game.Loaded:Wait()
end
 
local replicated_storage = game:GetService("ReplicatedStorage")
local data_service = require(replicated_storage.Modules.DataService)
local http_service = game:GetService("HttpService")
local teleport_service = game:GetService("TeleportService")
local player = game.Players.LocalPlayer
 
local imgs = {
    ["Queen Bee"] = "https://static.wikia.nocookie.net/growagarden/images/7/7a/Queen_bee.png",
    ["Dragonfly"] = "https://static.wikia.nocookie.net/growagarden/images/c/c9/DragonflyIcon.png",
    ["Disco Bee"] = "https://static.wikia.nocookie.net/growagarden/images/5/56/Bee.png",
    ["Raccoon"] = "https://static.wikia.nocookie.net/growagarden/images/5/54/Raccon_Better_Quality.png"
}
 
local default_thumbnail = getgenv().default_thumbnail or "https://media.tenor.com/VLnaNrQmjMoAAAAi/transparent-anime.gif"
 
function send_webhook(url, petName, weight, chance, pingUser)
    local embed = {
        title = petName,
        color = 0xff8800,
        description = string.format("> Weight: **%.2f kg**\n> Chance: **%s**", weight, chance),
        thumbnail = { url = imgs[petName] or default_thumbnail },
        footer = { text = "User: " .. player.DisplayName },
        timestamp = os.date("!%Y-%m-%dT%H:%M:%SZ", os.time())
    }
 
    local body = {
        content = pingUser or "",
        embeds = { embed }
    }
 
    local req = request or (syn and syn.request) or http_request
    if req then
        pcall(function()
            req({
                Url = url .. "?wait=true",
                Method = "POST",
                Headers = { ["Content-Type"] = "application/json" },
                Body = http_service:JSONEncode(body)
            })
        end)
    end
end
 
local function isTargetPet(petName)
    local targets = getgenv().target_pets or {}
    for _, target in ipairs(targets) do
        if target == petName then
            return true
        end
    end
    return false
end
 
local garden
for _, v in workspace.Farm:GetChildren() do
    if v.Important.Data.Owner.Value == player.Name then
        garden = v
        break
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
 
task.wait(5)
 
local savedData = data_service:GetData()
local foundTargetPet = false
 
for uid, v in pairs(savedData.SavedObjects) do
    local data = v.Data
    local egg = data and data.EggName
    if not egg or not data.RandomPetData then continue end
 
    local petName = data.Type
    local weight = data.BaseWeight or 0
    local chanceRaw = data.RandomPetData.ItemOdd or 0
 
    local chancePercent
    if type(chanceRaw) == "number" then
        if chanceRaw > 1 then
            chancePercent = string.format("%.1f%%", chanceRaw)
        else
            chancePercent = string.format("%.1f%%", chanceRaw * 100)
        end
    else
        chancePercent = "N/A"
    end
 
    if getgenv().webhook_url then
        local pingUser = isTargetPet(petName) and (getgenv().pingUser or "") or ""
        send_webhook(getgenv().webhook_url, petName, weight, chancePercent, pingUser)
    end
 
local eggsToHatch = {}

for uid, v in pairs(savedData.SavedObjects) do
    local data = v.Data
    local egg = data and data.EggName
    if not egg or not data.RandomPetData then continue end

    local petName = data.Type
    if isTargetPet(petName) then
        local eggInstance = get_egg(uid)
        if eggInstance then
            table.insert(eggsToHatch, eggInstance)
        end
    end
end

if #eggsToHatch > 0 then
    for _, eggInstance in ipairs(eggsToHatch) do
        pcall(function()
            replicated_storage.GameEvents.PetEggService:FireServer("HatchPet", eggInstance)
        end)
        task.wait(0.5)
    end

    queue_on_teleport('loadstring(game:HttpGet("https://pastebin.com/raw/JBSyuV4f"))()')
    task.wait(3)
    teleport_service:Teleport(game.PlaceId)
else
    local tpCD = string.format([[
        getgenv().webhook_url = %q
        getgenv().target_pets = %s
        getgenv().pingUser = %q
        loadstring(game:HttpGet("https://raw.githubusercontent.com/nostrainu/osdump/refs/heads/main/Folder/pethop.lua"))()
    ]], getgenv().webhook_url or "", http_service:JSONEncode(getgenv().target_pets or {}), getgenv().pingUser or "")

    queue_on_teleport(tpCD)
    teleport_service:Teleport(game.PlaceId)
end
