local getfruits = getgenv().AutoGetFruits

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

local fruitModels = {}
local running = true

local function notifyuser()
    local Event = game:GetService("ReplicatedStorage").Remotes.CommE
    firesignal(Event.OnClientEvent, 
        "Notify",
        "<Color=Green>Script loaded succesfully.<Color=/>"
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
    local root = char:FindFirstChild("HumanoidRootPart")
    if not root then
        warn("HumanoidRootPart is nil, skipping ESP for " .. tostring(target.Name))
        return false
    end
    local handle = target:FindFirstChild("Handle")
    if not handle then
        warn("No handle found! (Corrupted model OR target is not a fruit.) Skipping ESP for " .. tostring(target.Name))
        return false
    end
    if target:IsA("Tool") and getfruits then
        firetouchinterest(root, handle, 0)
        firetouchinterest(root, handle, 1)
    end
    local att0 = root:FindFirstChild("Attachment0")
    if not att0 then
        att0 = Instance.new("Attachment")
        att0.Name = "Attachment0"
        att0.Parent = root
    end
    local att1 = handle:FindFirstChild("Attachment1")
    if not att1 then
        att1 = Instance.new("Attachment")
        att1.Name = "Attachment1"
        att1.Parent = handle
    end

    local beam = game.Workspace:FindFirstChild("Tracer_" .. target.Name)
    if not beam then
        beam = Instance.new("Beam")
        beam.Parent = game.Workspace
        beam.Name = "Tracer_" .. target.Name
        beam.Attachment0 = att0
        beam.Attachment1 = att1
        beam.Width0 = 0.25
        beam.Width1 = 0.25
        beam.FaceCamera = true
    end

    return true
end

local function rainbowFruit(fruit)
    while running and fruit and fruit.Parent do
        local beam = game.Workspace:FindFirstChild("Tracer_" .. fruit.Name)
        if beam then
            local hue = tick() * 0.15 % 1
            beam.Color = ColorSequence.new(Color3.fromHSV(hue, 1, 1))
        end
        task.wait()
    end
end

local function checkFruit(v)
    if string.find(v.Name, "Fruit") and v:IsA("Model") and not fruitModels[v] then
        if esp(v) then
            sendnotif(v)
            fruitModels[v] = true
            coroutine.wrap(rainbowFruit)(v)
        end
    end
end

for _, v in pairs(game.Workspace:GetChildren()) do
    checkFruit(v)
end

game.Workspace.ChildAdded:Connect(function(v)
    checkFruit(v)
end)

game.Workspace.ChildRemoved:Connect(function(v)
    if string.find(v.Name, "Fruit") then
        fruitModels[v] = nil
        local beam = game.Workspace:FindFirstChild("Tracer_" .. v.Name)
        if beam then
            beam:Destroy()
        end
    end
end)

notifyuser()
