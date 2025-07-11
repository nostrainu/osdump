--// GaG 
--// Open Sauce
if game.PlaceId ~= 126884695634066 then return end

--// grant grant grant
if getgenv().uiUpd then
    getgenv().uiUpd:Unload()
end

--// Library and Config
local repo = "https://raw.githubusercontent.com/nostrainu/dumps/main/"
local Library = loadstring(game:HttpGet(repo .. "obsidiandeividadditions.lua"))()
local ThemeManager = loadstring(game:HttpGet(repo .. "addons/Thememanager.lua"))()
local http = game:GetService("HttpService")
local folder, path = "grangrant", "grant/config.json"

--// Defaults
local defaults = {
    AutoIdle = false,
    AutoIdleToggle = false,
}

--// Save/Load Functions
local function save()
    if not isfolder(folder) then makefolder(folder) end
    writefile(path, http:JSONEncode(config))
end

--// Load Config 
local config = isfile(path) and http:JSONDecode(readfile(path)) or {}

--// Apply Config 
for k, v in pairs(defaults) do
    config[k] = config[k] == nil and v or config[k]
    getgenv()[k] = config[k]
end

--// Runtime Reset 
getgenv().AutoIdle = false
getgenv().AutoIdleToggle = config.AutoIdleToggle or false

--// Store Config
getgenv().config = config

--// Library
Library.ForceCheckbox = false
Library.ShowToggleFrameInKeybinds = true

local Window = Library:CreateWindow({
    Title = "Grant",
    Footer = "v0.2",
    MobileButtonsSide = "Left",
    NotifySide = "Right",
    Center = true,
    Resizable = false,
    Size = Library.IsMobile and UDim2.fromOffset(450, 300) or UDim2.fromOffset(650, 500),
    ShowCustomCursor = false,
})

getgenv().uiUpd = Library 

--// Tabs
local Tabs = {
    Changelog = Window:AddTab("Changelog", "file-clock"),
    Vuln = Window:AddTab("Vuln", "focus"),
    ["Settings"] = Window:AddTab("Settings", "settings"),
}

--// uiActive
local uiActive = true

--// Changelog
local CGL = Tabs.Changelog:AddFullGroupbox("v0.1", "square-check-big")
local CGL1 = Tabs.Changelog:AddFullGroupbox("v0.2", "square-check-big")

CGL:AddLabel({
    Text = "▶ Added Moon Cat Idle",
    DoesWrap = true
})

CGL1:AddLabel({
    Text = "▶ Added Remove Sprinkler",
    DoesWrap = true
})

--// Vuln
local VLN = Tabs.Vuln:AddLeftGroupbox("Idle")

VLN:AddToggle("MoonCat", {
    Text = "Auto Idle",
    Default = getgenv().AutoIdleToggle,
    Callback = function(val)
        getgenv().AutoIdleToggle = val
        config.AutoIdleToggle = val
        save()
        if not val then
            getgenv().AutoIdle = false  
        end
    end
})

VLN:AddDivider()

--// Auto Shovel
VLN:AddButton("ShovelSprinkler", {
    Text = "Shovel Sprinkler",
    Func = function()
        local Players = game:GetService("Players")
        local ReplicatedStorage = game:GetService("ReplicatedStorage")
        local player = Players.LocalPlayer

        local character, backpack = player.Character or player.CharacterAdded:Wait(), player:WaitForChild("Backpack")
        local DeleteObject = ReplicatedStorage:WaitForChild("GameEvents"):WaitForChild("DeleteObject")

        local function EquipShovel()
            local equippedTool = character:FindFirstChildWhichIsA("Tool")
            if equippedTool and equippedTool.Name == "Shovel [Destroy Plants]" then
                return true
            end
            local shovel = character:FindFirstChild("Shovel [Destroy Plants]") or backpack:FindFirstChild("Shovel [Destroy Plants]")
            if shovel then
                shovel.Parent = character
                player.Character.Humanoid:EquipTool(shovel)
                return true
            end
            return false
        end

        local function UnequipShovel()
            local equippedTool = character:FindFirstChildWhichIsA("Tool")
            if equippedTool and equippedTool.Name == "Shovel [Destroy Plants]" then
                equippedTool.Parent = backpack
            end
        end

        local garden
        for _, plot in pairs(workspace.Farm:GetChildren()) do
            if plot:FindFirstChild("Important")
                and plot.Important:FindFirstChild("Data")
                and plot.Important.Data.Owner.Value == player.Name then
                garden = plot
                break
            end
        end
        if not garden then return end

        if not EquipShovel() then return end

        local objectsFolder = garden.Important:FindFirstChild("Objects_Physical")
        if not objectsFolder then return end

        for _, model in ipairs(objectsFolder:GetChildren()) do
            if model:IsA("Model") and string.find(model.Name, "Sprinkler") then
                DeleteObject:FireServer(model)
                task.wait(0.2)
            end
        end

        UnequipShovel()
    end,
    DoubleClick = false
})

--// Services
local ReplicatedStorage = game:GetService("ReplicatedStorage")

--// Modules & Remotes
local GetPetCooldown = ReplicatedStorage:WaitForChild("GameEvents"):WaitForChild("GetPetCooldown")
local IdleHandler = require(ReplicatedStorage.Modules.PetServices.PetActionUserInterfaceService.PetActionsHandlers.Idle)

--// Auto Idle
task.spawn(function()
    while uiActive do
        if getgenv().AutoIdle then
            for _, v in ipairs(workspace.PetsPhysical:GetChildren()) do
                if v:IsA("BasePart") and v.Name == "PetMover" then
                    local model = v:FindFirstChild(v:GetAttribute("UUID"))
                    if model and model:IsA("Model") and model:GetAttribute("CurrentSkin") == "Moon Cat" then
                        task.spawn(IdleHandler.Activate, v)
                    end
                end
            end
        end
        task.wait()
    end
end)

--// Echo Frog
task.spawn(function()
    while uiActive do
        if getgenv().AutoIdleToggle then 
            for _, v in ipairs(workspace.PetsPhysical:GetChildren()) do
                if v:IsA("BasePart") and v.Name == "PetMover" then
                    local uuid = v:GetAttribute("UUID")
                    local model = uuid and v:FindFirstChild(uuid)

                    if model and model:IsA("Model") and model:GetAttribute("CurrentSkin") == nil then
                        local ok, cooldowns = pcall(GetPetCooldown.InvokeServer, GetPetCooldown, uuid)
                        if ok and typeof(cooldowns) == "table" then
                            for _, cd in ipairs(cooldowns) do
                                local time = tonumber(cd.Time)
                                if time and time >= 79 and time <= 81 and not getgenv().AutoIdle then
                                    Library:Notify({
                                        Title = "Auto Idle",
                                        Description = "True",
                                        Time = 3,
                                    })
                                    getgenv().AutoIdle = true
                                    task.delay(10, function()
                                        getgenv().AutoIdle = false
                                        Library:Notify({
                                            Title = "Auto Idle",
                                            Description = "False",
                                            Time = 3,
                                        })
                                    end)
                                    break
                                end
                            end
                        end
                    end
                end
            end
        else
            getgenv().AutoIdle = false
        end
        task.wait(1)
    end
end)

--// Menu
local MenuGroup = Tabs["Settings"]:AddLeftGroupbox("Menu")

MenuGroup:AddDropdown("NotificationSide", {
    Values = { "Left", "Right" },
    Default = "Right",
    Text = "Notification Side",
    Callback = function(Value)
        Library:SetNotifySide(Value)
    end,
})

MenuGroup:AddDropdown("DPIDropdown", {
    Values = { "50%", "75%", "100%", "125%", "150%", "175%", "200%" },
    Default = "100%",
    Text = "DPI Scale",
    Callback = function(Value)
        Value = Value:gsub("%%", "")
        local DPI = tonumber(Value)
        Library:SetDPIScale(DPI)
    end,
})

MenuGroup:AddDivider()
MenuGroup:AddLabel("Menu bind")
    :AddKeyPicker("MenuKeybind", { Default = "LeftControl", NoUI = true, Text = "Menu keybind" })

MenuGroup:AddButton("Unload", function()
    uiActive = false
    Library:Unload()
end)

Library.ToggleKeybind = Library.Options.MenuKeybind

ThemeManager:SetLibrary(Library)
ThemeManager:SetFolder("hikochairs")
ThemeManager:ApplyToTab(Tabs["Settings"])

Library:OnUnload(function()
    uiActive = false
    getgenv().uiUpd = nil
end)
