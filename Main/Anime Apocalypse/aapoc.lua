if game.GameId ~= 9073513091 then return end
repeat task.wait() until game:IsLoaded()

getgenv().Config = getgenv().Config or {}
getgenv().Config.Height = getgenv().Config.Height or 12

local player = game.Players.LocalPlayer
local remote = game:GetService("ReplicatedStorage"):WaitForChild("Assets"):WaitForChild("Remotes"):WaitForChild("Interact")

if game.PlaceId == 140409475718339 then
    local platform = workspace:WaitForChild("Platforms"):WaitForChild("Platform")
    local args = {
        "CreateMatch",
        platform,
        {
            IsTaken = true,
            Difficulty = getgenv().Config.Difficulty,
            Map = getgenv().Config.Map,
            Mode = getgenv().Config.Mode,
            FriendsOnly = false,
            MaxPlayers = 1
        }
    }
    remote:FireServer(unpack(args))
    return 
end

local character = player.Character or player.CharacterAdded:Wait()
local rootPart = character:WaitForChild("HumanoidRootPart")
local humanoid = character:WaitForChild("Humanoid")
local animate = character:FindFirstChild("Animate")
local zombiesFolder = workspace:WaitForChild("Zombies")

local function managePhysics(active)
    if not rootPart or not humanoid then return end
    local existingBV = rootPart:FindFirstChildOfClass("BodyVelocity")
    local existingBG = rootPart:FindFirstChildOfClass("BodyGyro")
    
    if active then
        humanoid.AutoRotate = false
        if animate then animate.Disabled = true end
        for _, track in pairs(humanoid:GetPlayingAnimationTracks()) do track:Stop() end
        humanoid:ChangeState(Enum.HumanoidStateType.Physics)
        
        if not existingBV then
            local bv = Instance.new("BodyVelocity")
            bv.MaxForce = Vector3.new(math.huge, math.huge, math.huge)
            bv.Parent = rootPart
        end
        if not existingBG then
            local bg = Instance.new("BodyGyro")
            bg.P = 9e4
            bg.MaxTorque = Vector3.new(math.huge, math.huge, math.huge)
            bg.CFrame = rootPart.CFrame 
            bg.Parent = rootPart
        end
    else
        humanoid.AutoRotate = true
        if animate then animate.Disabled = false end
        humanoid:ChangeState(Enum.HumanoidStateType.GettingUp)
        if existingBV then existingBV:Destroy() end
        if existingBG then existingBG:Destroy() end
    end
end

local function getTarget()
    local nearest, shortestDistance = nil, math.huge
    local currentZombies = workspace:FindFirstChild("Zombies") or zombiesFolder
    for _, zombie in pairs(currentZombies:GetChildren()) do
        if zombie:IsA("Model") and zombie:FindFirstChild("Config") and zombie.Config.Health.Value > 0 then
            local root = zombie:FindFirstChild("HumanoidRootPart")
            if root then
                local dist = (rootPart.Position - root.Position).Magnitude
                if dist < shortestDistance then
                    nearest, shortestDistance = zombie, dist
                end
            end
        end
    end
    return nearest
end

player.CharacterAdded:Connect(function(newChar)
    character = newChar
    rootPart = character:WaitForChild("HumanoidRootPart")
    humanoid = character:WaitForChild("Humanoid")
    animate = character:WaitForChild("Animate", 5)
    task.wait(0.1)
    if getgenv().Config.Enabled then
        managePhysics(true)
    end
end)

task.spawn(function()
    while getgenv().Config.Enabled do
        local target = getTarget()
        if target then
            remote:FireServer("M1", getgenv().Config.Class, os.time())
            for i = 1, 4 do
                local slot = i <= 4 and ("Slot" .. i) or nil
                remote:FireServer("Ability", i, slot, getgenv().Config.AbilityClass, "Began")
            end
        end
        task.wait(0.1)
    end
end)

task.spawn(function()
    managePhysics(true)
    while getgenv().Config.Enabled do
        local target = getTarget()
        local bv, bg = rootPart:FindFirstChildOfClass("BodyVelocity"), rootPart:FindFirstChildOfClass("BodyGyro")
        
        if target and bv and bg then
            local tp = target.PrimaryPart or target:FindFirstChild("HumanoidRootPart")
            rootPart.CFrame = CFrame.new(tp.Position + Vector3.new(0.1, getgenv().Config.Height, 0), tp.Position) * CFrame.Angles(math.rad(360), 0, 0)
            bg.CFrame, bv.Velocity = rootPart.CFrame, Vector3.new(0, 0, 0)
        else
            local obj = workspace:FindFirstChild("Entries", true)
            if obj then
                for _, entry in pairs(obj:GetChildren()) do
                    local prompt = entry:IsA("Model") and entry:FindFirstChildWhichIsA("ProximityPrompt", true)
                    if prompt then
                        rootPart.CFrame = entry:GetPivot() + Vector3.new(0, 5, 0)
                        task.wait(0.1)
                        if fireproximityprompt then fireproximityprompt(prompt) end
                        task.wait(10)
                        remote:FireServer("PlayAgain")
                        break 
                    end
                end
            end
            if bv then bv.Velocity = Vector3.new(0, 0, 0) end
        end
        task.wait()
    end
    managePhysics(false)
end)
