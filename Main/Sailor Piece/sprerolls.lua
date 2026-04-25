-- Power
getgenv().AutoReroll = true

local p = game:GetService("Players").LocalPlayer
local rs = game:GetService("ReplicatedStorage")
local remote = rs:WaitForChild("RemoteEvents"):WaitForChild("PowerReroll")

local trait = p.PlayerGui.PowerRerollUI.MainFrame.Frame.Content.TraitPage.TraitGottenFrame.Trait.TraitGotten
local confirm = p.PlayerGui.PowerRerollUI.MainFrame.Frame.Content.AreYouSureYouWantToRerollFrame.Buttons.Accept

local function click(b)
    for _, v in pairs(getconnections(b.MouseButton1Click)) do v:Fire() end
end

while getgenv().AutoReroll do
    local txt = trait.Text
    local d = tonumber(txt:match("Damage ([%d%.]+)%%")) or 0
    local l = tonumber(txt:match("Luck ([%d%.]+)")) or 0

    if txt:find("Subjugator") and d >= 30 and l >= 17 then
        getgenv().AutoReroll = false
        break
    end

    remote:FireServer()
    
    local timeout = 0
    while not (confirm.Visible or confirm.Parent.Parent.Visible) and timeout < 20 do
        task.wait(0.1)
        timeout = timeout + 1
    end
    
    if confirm.Visible or confirm.Parent.Parent.Visible then
        click(confirm)
    end

    task.wait(0.5)
end



-- Spec
local weaponName = "Strongest In History"
getgenv().AutoSpec = true

local p = game:GetService("Players").LocalPlayer
local rs = game:GetService("ReplicatedStorage")
local remote = rs:WaitForChild("RemoteEvents"):WaitForChild("SpecPassiveReroll")

local main = p.PlayerGui.SpecPassiveUI.MainFrame.Frame.Content
local trait = main.SpecInfoFrame.SwordUsedTrait.BackgroundTxt.SpecPassiveGotten
local confirm = main.AreYouSureYouWantToRerollFrame.Holder.Buttons.Accept

local function click(b)
    for _, v in pairs(getconnections(b.MouseButton1Click)) do v:Fire() end
end

while getgenv().AutoSpec do
    local txt = trait.Text
    local c = tonumber(txt:match("([%d%.]+)%% Chance")) or 0
    local l = tonumber(txt:match("Luck ([%d%.]+)")) or 0

    if txt:find("Fortune Chosen") and c >= 25 and l >= 9 then
        getgenv().AutoSpec = false
        break
    end

    remote:FireServer(weaponName)

    local timeout = 0
    while not (confirm.Visible or confirm.Parent.Parent.Visible) and timeout < 20 do
        task.wait(0.1)
        timeout = timeout + 1
    end

    if confirm.Visible or confirm.Parent.Parent.Visible then
        click(confirm)
    end

    task.wait(0.5)
end



-- Trait 
getgenv().AutoReroll = true
local w = "Genesis"

local p = game:GetService("Players").LocalPlayer
local rs = game:GetService("ReplicatedStorage")
local remote = rs:WaitForChild("RemoteEvents"):WaitForChild("TraitReroll")

local main = p.PlayerGui.TraitRerollUI.MainFrame.Frame.Content
local trait = main.TraitPage.TraitGottenFrame.Holder.Trait.TraitGotten
local confirm = main.AreYouSureYouWantToRerollFrame.Buttons.Accept

local function click(b)
    for _, v in pairs(getconnections(b.MouseButton1Click)) do 
        v:Fire() 
    end
end

while getgenv().AutoReroll do
    if trait.Text == w then
        getgenv().AutoReroll = false
        break
    end

    remote:FireServer()

    local timeout = 0
    while not (confirm.Visible or confirm.Parent.Parent.Visible) and timeout < 5 do
        task.wait()
        timeout = timeout + 1
        if trait.Text == w then break end
    end

    if (confirm.Visible or confirm.Parent.Parent.Visible) and trait.Text ~= w then
        click(confirm)
    end

    task.wait()
end
