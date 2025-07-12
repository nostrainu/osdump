--// GaG
--// Open Sauce
if game.PlaceId ~= 126884695634066 then return end

--// grant grant grant
if getgenv().uiUpd then
    getgenv().uiUpd:Unload()
end

--// Library and Config (USING THE LIBRARY FROM V0.1)
local repo = "https://raw.githubusercontent.com/deividcomsono/Obsidian/main/"
local Library = loadstring(game:HttpGet(repo .. "Library.lua"))()
local ThemeManager = loadstring(game:HttpGet(repo .. "addons/ThemeManager.lua"))()
local http = game:GetService("HttpService")
local folder, path = "grangrant", "grant/config.json"

--// Defaults
local defaults = {
    AutoIdle = false,
    AutoIdleToggle = false,
    selectedPets = {},
    PetKgInput = 0,
    autoSellEnabled = false,
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
    Size = Library.IsMobile and UDim2.fromOffset(450, 300) or UDim2.fromOffset(650, 500),
    ShowCustomCursor = false,
})

getgenv().uiUpd = Library

--// Tabs
local Tabs = {
    Changelog = Window:AddTab("Changelog", "file-clock"),
    Misc = Window:AddTab("Misc", "notebook-pen"),
    Vuln = Window:AddTab("Vuln", "focus"),
    ["Settings"] = Window:AddTab("Settings", "settings"),
}

--// uiActive
local uiActive = true

--// Services & Setup
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local player = Players.LocalPlayer
local backpack = player:WaitForChild("Backpack")
local character = player.Character or player.CharacterAdded:Wait()
local humanoid = character:WaitForChild("Humanoid")

-- Handle character respawning
player.CharacterAdded:Connect(function(newChar)
    character = newChar
    humanoid = character:WaitForChild("Humanoid")
    backpack = player:WaitForChild("Backpack")
end)

--// Changelog
local CGL = Tabs.Changelog:AddLeftGroupbox("v0.1")
local CGL1 = Tabs.Changelog:AddLeftGroupbox("v0.2")

CGL:AddLabel("• Added Moon Cat Idle")
CGL:AddLabel("• Added Remove Sprinkler")

CGL1:AddLabel("• Added Miscellaneous Tab")
CGL1:AddLabel("  ▶ Added Sell Pets")
CGL1:AddLabel("  ▶ Added Weight Input")
CGL1:AddLabel("")
CGL1:AddLabel("• Added Vulnerabilities Tab")
CGL1:AddLabel("  ▶ Moved Moon Cat Idle to Vuln")
CGL1:AddLabel("  ▶ Moved Remove Sprinkler to Vuln")

--// Pet Functions
local function getUniquePetNames()
    local names = {}
    local seen = {}
    
    for _, container in ipairs({backpack, character}) do
        for _, tool in ipairs(container:GetChildren()) do
            if tool:IsA("Tool") and tool.Name:find("Age") then
                local base = tool.Name:match("^(.-) %[%d") or tool.Name
                if not seen[base] then
                    seen[base] = true
                    table.insert(names, base)
                end
            end
        end
    end
    
    table.sort(names)
    return names
end

--// Misc Tab
local MSC = Tabs.Misc:AddLeftGroupbox("Sell Pets")

local petDropdown = MSC:AddDropdown("SellPet", {
    Values = getUniquePetNames(),
    Default = {},
    Multi = true,
    Text = "Select Pets to Sell",
    Callback = function(selected)
        print("Pets selected:", selected)
        getgenv().selectedPets = selected
        config.selectedPets = selected
        save()
    end
})

MSC:AddInput("PetKgInput", {
    Text = "Weight Threshold (KG)",
    Default = tostring(getgenv().PetKgInput or 0),
    Numeric = true,
    Finished = true,
    Placeholder = "Enter minimum weight to sell",
    Callback = function(value)
        print("Weight threshold set to:", value)
        getgenv().PetKgInput = tonumber(value) or 0
        config.PetKgInput = getgenv().PetKgInput
        save()
    end
})

MSC:AddToggle("SellPetToggle", {
    Text = "Enable Auto Sell",
    Default = getgenv().autoSellEnabled or false,
    Callback = function(val)
        print("Auto Sell toggled:", val)
        getgenv().autoSellEnabled = val
        config.autoSellEnabled = val
        save()
    end
})

--// Auto Sell Logic
task.spawn(function()
    while uiActive do
        task.wait(1)
        
        if not getgenv().autoSellEnabled or not getgenv().selectedPets then 
            continue 
        end
        
        local weightThreshold = tonumber(getgenv().PetKgInput) or 0
        if weightThreshold <= 0 then continue end
        
        for petName, isSelected in pairs(getgenv().selectedPets) do
            if isSelected then
                for _, tool in ipairs(backpack:GetChildren()) do
                    if tool:IsA("Tool") and tool.Name:find("^" .. petName) then
                        local weightStr = tool.Name:match("%[(%d+%.?%d*) KG%]")
                        local weight = tonumber(weightStr or "0")
                        
                        if weight and weight >= weightThreshold then
                            pcall(function()
                                print("Selling pet:", tool.Name, "Weight:", weight)
                                tool.Parent = character
                                humanoid:EquipTool(tool)
                                task.wait(0.1)
                                ReplicatedStorage.GameEvents.SellPet_RE:FireServer(tool)
                                task.wait(0.5) -- Prevent spam
                            end)
                        end
                    end
                end
            end
        end
    end
end)

--// Pet List Updater
task.spawn(function()
    while uiActive do
        task.wait(5)
        local updatedList = getUniquePetNames()
        local preserved = {}
        
        if getgenv().selectedPets then
            for _, name in ipairs(updatedList) do
                if getgenv().selectedPets[name] then
                    preserved[name] = true
                end
            end
        end
        
        if petDropdown then
            petDropdown:SetValues(updatedList)
            petDropdown:SetValue(preserved)
        end
        
        getgenv().selectedPets = preserved
    end
end)

--// Vuln Tab
local VLN = Tabs.Vuln:AddLeftGroupbox("Idle")

VLN:AddToggle("MoonCat", {
    Text = "Auto Idle",
    Default = getgenv().AutoIdleToggle,
    Callback = function(val)
        print("Auto Idle Toggle:", val)
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
        print("Shovel Sprinkler button clicked")
        
        local DeleteObject = ReplicatedStorage:WaitForChild("GameEvents"):WaitForChild("DeleteObject")
        
        local function EquipShovel()
            local equippedTool = character:FindFirstChildWhichIsA("Tool")
            if equippedTool and equippedTool.Name == "Shovel [Destroy Plants]" then
                return true
            end
            local shovel = character:FindFirstChild("Shovel [Destroy Plants]") or backpack:FindFirstChild("Shovel [Destroy Plants]")
            if shovel then
                shovel.Parent = character
                humanoid:EquipTool(shovel)
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
        if not garden then 
            print("No garden found!")
            return 
        end
        
        if not EquipShovel() then 
            print("Failed to equip shovel!")
            return 
        end
        
        local objectsFolder = garden.Important:FindFirstChild("Objects_Physical")
        if not objectsFolder then 
            print("No objects folder found!")
            return 
        end
        
        local sprinklersRemoved = 0
        for _, model in ipairs(objectsFolder:GetChildren()) do
            if model:IsA("Model") and string.find(model.Name, "Sprinkler") then
                DeleteObject:FireServer(model)
                sprinklersRemoved = sprinklersRemoved + 1
                task.wait(0.2)
            end
        end
        
        UnequipShovel()
        print("Removed", sprinklersRemoved, "sprinklers")
        
        Library:Notify({
            Title = "Shovel Sprinkler",
            Description = "Removed " .. sprinklersRemoved .. " sprinklers",
            Time = 3,
        })
    end,
    DoubleClick = false
})

--// Services & Modules 
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

--// Echo Frog Logic 
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
MenuGroup:AddLabel("Menu bind"):AddKeyPicker("MenuKeybind", { 
    Default = "LeftControl", 
    NoUI = true, 
    Text = "Menu keybind" 
})

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