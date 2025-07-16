--// GaG 
--// Open Sauce
--// https://guns.lol/kidgrant
if game.PlaceId ~= 126884695634066 then return end

--// grant grant grant
if getgenv().uiUpd then
    getgenv().uiUpd:Unload()
end

--// Library and Config
local repo = "https://raw.githubusercontent.com/deividcomsono/Obsidian/main/"
local Library = loadstring(game:HttpGet(repo .. "Library.lua"))()
local ThemeManager = loadstring(game:HttpGet(repo .. "addons/ThemeManager.lua"))()
local http = game:GetService("HttpService")
local folder, path = "grangrant", "grant/config.json"

--// Defaults
local defaults = {
    AutoIdle = false,
    AutoIdleToggle = false,
    idleDrop = {},
    idleInput = 0,
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
    Footer = "please donate via GCash",
    MobileButtonsSide = "Left",
    NotifySide = "Right",
    Center = true,
    Size = Library.IsMobile and UDim2.fromOffset(450, 300) or UDim2.fromOffset(650, 500),
    ShowCustomCursor = false,
})

getgenv().uiUpd = Library 

--// Tabs
local Tabs = {
    Main = Window:AddTab("Main", "user"),
    ["UI Settings"] = Window:AddTab("UI Settings", "settings"),
}

--// Main Functionalities
local uiActive = true

--// Menu
local LeftGroupBox = Tabs.Main:AddLeftGroupbox("Idle")

LeftGroupBox:AddDropdown("IdleDropdown", {
    Values = { "Moon Cat", "Capybara" },
    Default = getgenv().idleDrop or {},
    Multi = true,
    Text = "Select Pet",
    Callback = function(selected)
        getgenv().idleDrop = selected
        config.idleDrop = selected
        save()
    end
})

LeftGroupBox:AddInput("IdleInput", {
    Text = "Cooldown in Seconds",
    Default = "80",
    Numeric = true,
    Finished = true,
    Placeholder = "Cooldown in Seconds",
    Callback = function(val)
        local num = tonumber(val)
        if num then
            getgenv().idleInput = num
            config.idleInput = num
            save()
        else
            getgenv().idleInput = nil  
        end
    end
})

LeftGroupBox:AddToggle("MoonCat", {
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

LeftGroupBox:AddDivider()

--// Auto Shovel
LeftGroupBox:AddButton("ShovelSprinkler", {
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
local Players = game:GetService("Players")
local LocalPlayer = Players.LocalPlayer

--// Modules & Remotes
local GetPetCooldown = ReplicatedStorage:WaitForChild("GameEvents"):WaitForChild("GetPetCooldown")
local IdleHandler = require(ReplicatedStorage.Modules.PetServices.PetActionUserInterfaceService.PetActionsHandlers.Idle)
local ActivePetsService = require(ReplicatedStorage.Modules.PetServices.ActivePetsService)

--// Capybara
task.spawn(function()
    while uiActive do
        if getgenv().AutoIdleToggle then
            for _, petPart in pairs(workspace.PetsPhysical:GetChildren()) do
                if petPart:IsA("BasePart") and petPart.Name == "PetMover" then
                    local uuid = petPart:GetAttribute("UUID")
                    local owner = petPart:GetAttribute("OWNER")

                    if owner == LocalPlayer.Name and uuid then
                        local petData = ActivePetsService:GetPetData(owner, uuid)
                        if petData and petData.PetType == "Capybara" then
                            task.spawn(IdleHandler.Activate, petPart)
                        end
                    end
                end
            end
        end
        task.wait(1)
    end
end)

--// Moon Cat
task.spawn(function()
    while uiActive do
        if getgenv().AutoIdle then
            for _, petPart in pairs(workspace.PetsPhysical:GetChildren()) do
                if petPart:IsA("BasePart") and petPart.Name == "PetMover" then
                    local uuid = petPart:GetAttribute("UUID")
                    local owner = petPart:GetAttribute("OWNER")

                    if owner == LocalPlayer.Name and uuid then
                        local petData = ActivePetsService:GetPetData(owner, uuid)
                        if petData and petData.PetType == "Moon Cat" then
                            task.spawn(IdleHandler.Activate, petPart)
                        end
                    end
                end
            end
        end
        task.wait()
    end
end)

--// Listener
task.spawn(function()
    while uiActive do
        if getgenv().AutoIdleToggle then 
            for _, mover in pairs(workspace.PetsPhysical:GetChildren()) do
                if mover:IsA("BasePart") and mover.Name == "PetMover" then
                    local uuid = mover:GetAttribute("UUID")
                    local owner = mover:GetAttribute("OWNER")

                    if uuid and owner == LocalPlayer.Name then
                        local petData = ActivePetsService:GetPetData(owner, uuid)
                        if petData and (petData.PetType == "Echo Frog" or petData.PetType == "Triceratops") then
                            local ok, cooldowns = pcall(GetPetCooldown.InvokeServer, GetPetCooldown, uuid)
                            if ok and typeof(cooldowns) == "table" then
                                for _, cd in pairs(cooldowns) do
                                    local time = tonumber(cd.Time)
                                    local targetTime = tonumber(getgenv().idleInput) or 80
                                    if time and time >= targetTime - 1 and time <= targetTime + 1 and not getgenv().AutoIdle then
                                        Library:Notify({
                                            Title = "Auto Idle",
                                            Description = petData.PetType .. " Enabled",
                                            Time = 3,
                                        })
                                        getgenv().AutoIdle = true
                                        task.delay(10, function()
                                            getgenv().AutoIdle = false
                                            Library:Notify({
                                                Title = "Auto Idle",
                                                Description = petData.PetType .. " Disabled",
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
            end
        else
            getgenv().AutoIdle = false
        end
        task.wait(1)
    end
end)

--// Menu
local MenuGroup = Tabs["UI Settings"]:AddLeftGroupbox("Menu")

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
ThemeManager:ApplyToTab(Tabs["UI Settings"])

Library:OnUnload(function()
    uiActive = false
    getgenv().uiUpd = nil
end)
