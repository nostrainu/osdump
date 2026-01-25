--// Bai ka po ba?
--// grant grant grant

if game.PlaceId ~= 119579217517090 then return end

local Players = game:GetService("Players")
local LocalPlayer = Players.LocalPlayer
local wp = game.Workspace
local fd = wp:WaitForChild("Live"):WaitForChild("Friends")

getgenv().AutoFarm = false 
getgenv().lbs = getgenv().lbs or {"Exclusive Lucky Block"} 

local returnPart = workspace:WaitForChild("NewMapFully")
    :WaitForChild("BaseGround")
    :WaitForChild("GroundSign")

local function teleportAndFire(model)
    local char = LocalPlayer.Character or LocalPlayer.CharacterAdded:Wait()
    local hrp = char:WaitForChild("HumanoidRootPart")

    local root = model:FindFirstChild("RootPart") or model:FindFirstChildWhichIsA("BasePart")
    if not root then return false end

    hrp.CFrame = root.CFrame * CFrame.new(0, 3, 0)
    task.wait(0.15)

    for _, d in pairs(model:GetDescendants()) do
        if d:IsA("ProximityPrompt") and d.Enabled then
            fireproximityprompt(d)
            break
        end
    end

    task.wait(0.15)
    hrp.CFrame = returnPart.CFrame * CFrame.new(0, 3, 0)
    task.wait(0.15)

    return true
end

task.spawn(function()
    while true do
        if getgenv().AutoFarm and getgenv().lbs then
            local anyFound = false

            for _, name in ipairs(getgenv().lbs) do
                for _, model in pairs(fd:GetChildren()) do
                    if model:IsA("Model") and model.Name == name then
                        local success = teleportAndFire(model)
                        if success then
                            anyFound = true
                            task.wait(0.2)
                        end
                    end
                end
            end

            if not anyFound then
                task.wait(0.5)
            end
        else
            task.wait(0.5)
        end
    end
end)
