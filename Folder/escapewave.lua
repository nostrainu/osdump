--// Bai ka po?
--// grant grant grant

if game.PlaceId ~= 119579217517090 then return end

local Players = game:GetService("Players")
local LocalPlayer = Players.LocalPlayer
local wp = game.Workspace
local fd = wp:WaitForChild("Live"):WaitForChild("Friends")

getgenv().AutoFarm = true
getgenv().lbs = getgenv().lbs or nil

local returnPart = workspace:WaitForChild("NewMapFully")
    :WaitForChild("BaseGround")
    :WaitForChild("GroundSign")

local function tpfire(model)
    if not getgenv().AutoFarm then return false end

    local char = LocalPlayer.Character or LocalPlayer.CharacterAdded:Wait()
    local hrp = char:WaitForChild("HumanoidRootPart")

    local root = model:FindFirstChild("RootPart") or model:FindFirstChildWhichIsA("BasePart")
    if not root then return false end

    hrp.CFrame = root.CFrame * CFrame.new(0, 3, 0)
    task.wait(0.15)

    if not getgenv().AutoFarm then return false end

    for _, d in pairs(model:GetDescendants()) do
        if not getgenv().AutoFarm then return false end
        if d:IsA("ProximityPrompt") and d.Enabled then
            fireproximityprompt(d)
            break
        end
    end

    task.wait(0.15)
    if not getgenv().AutoFarm then return false end

    hrp.CFrame = returnPart.CFrame * CFrame.new(0, 3, 0)
    task.wait(0.15)

    return true
end

local function farmLoop()
    while getgenv().AutoFarm do
        if not getgenv().lbs then
            task.wait(0.5)
            continue
        end

        local anyFound = false

        for _, name in pairs(getgenv().lbs) do
            if not getgenv().AutoFarm then break end
            local collect = true

            while collect do
                if not getgenv().AutoFarm then break end
                collect = false

                for _, model in pairs(fd:GetChildren()) do
                    if not getgenv().AutoFarm then break end
                    if model:IsA("Model") and model.Name == name then
                        local success = tpfire(model)
                        if success then
                            collect = true
                            anyFound = true
                            break
                        end
                    end
                end

                task.wait(0.2)
            end
        end

        if not anyFound then
            task.wait(0.5)
        end
    end
end

task.spawn(farmLoop)
