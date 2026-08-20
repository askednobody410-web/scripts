local plr = game:GetService("Players").LocalPlayer
local char = game.Workspace.Characters:FindFirstChild(plr.Name)

if not char then
    for _, v in pairs(game.Workspace.Characters:GetChildren()) do
        if v.Name == plr.Name then
            char = v
            break
        end
    end
end

if not char then
    warn("Character not found!")
end

local function notifyuser()
    local Event = game:GetService("ReplicatedStorage").Remotes.CommE
    firesignal(Event.OnClientEvent, 
        "Notify",
        "<Color=Red>Script loaded succesfully.<Color=/>"
    )
end

local function sendnotif(target)
    local Event = game:GetService("ReplicatedStorage").Remotes.CommE
    firesignal(Event.OnClientEvent, 
        "Notify",
        "A " .. target.Name .. " was <Color=Red>detected!<Color=/>"
    )
end

local function esp(target)
    if not char then
        warn("Character is nil, skipping ESP for " .. tostring(target.Name))
        return false
    end
    local hrp = char:FindFirstChild("HumanoidRootPart")
    if not hrp then
        warn("HumanoidRootPart is nil, skipping ESP for " .. tostring(target.Name))
        return false
    end
    local handle = target:FindFirstChild("Handle")
    if not handle then
        warn("No handle found! (Corrupted model OR target is not a fruit.) Skipping ESP for " .. tostring(target.Name))
        return false
    end
    local a0 = hrp:FindFirstChild("Attachment0")
    if not a0 then
        a0 = Instance.new("Attachment")
        a0.Name = "Attachment0"
        a0.Parent = hrp
    end
    local a1 = handle:FindFirstChild("Attachment1")
    if not a1 then
        a1 = Instance.new("Attachment")
        a1.Name = "Attachment1"
        a1.Parent = handle
    end
    local tracer = game.Workspace:FindFirstChild("Tracer_" .. target.Name)
    if not tracer then
        tracer = Instance.new("Beam")
        tracer.Parent = game.Workspace
        tracer.Name = "Tracer_" .. target.Name
        tracer.Attachment0 = a0
        tracer.Attachment1 = a1
        tracer.Width0 = 0.25
        tracer.Width1 = 0.25
        tracer.FaceCamera = true
        if target:IsA("Tool") then
            tracer.Color = ColorSequence.new(Color3.fromRGB(255, 175, 0))
        end
        if target:IsA("Model") then
            tracer.Color = ColorSequence.new(Color3.fromRGB(0, 19, 255))
        end
    end
    return true
end

for _, v in pairs(game.Workspace:GetChildren()) do
    if string.find(v.Name, "Fruit") then
        if esp(v) then
            sendnotif(v)
        end
    end
end

game.Workspace.ChildAdded:Connect(function(v)
    if string.find(v.Name, "Fruit") then
        if esp(v) then
            sendnotif(v)
        end
    end
end)

game.Workspace.ChildRemoved:Connect(function(v)
    if string.find(v.Name, "Fruit") then
        local tracer = game.Workspace:FindFirstChild("Tracer_" .. v.Name)
        tracer:Destroy()
    end
end)

notifyuser()
