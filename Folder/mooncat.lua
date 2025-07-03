--// GaG 
--// Open Sauce
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
    Footer = "please donate via GCash :<",
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

--// Modules and Services
local ReplicatedStorage = game:GetService("ReplicatedStorage")
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
