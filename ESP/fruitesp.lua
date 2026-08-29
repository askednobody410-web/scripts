local getfruits = getgenv().AutoGetFruits or false

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

local tracerColors = {
    Color3.fromRGB(255, 0, 0),     -- red
    Color3.fromRGB(0, 255, 0),     -- green
    Color3.fromRGB(0, 0, 255),     -- blue
    Color3.fromRGB(160, 32, 240),  -- purple
    Color3.fromRGB(255, 255, 0),   -- yellow
    Color3.fromRGB(255, 255, 255), -- white
    Color3.fromRGB(0, 255, 255)    -- cyan
}

local function notifyuser()
    local Event = game:GetService("ReplicatedStorage").Remotes.CommE
    if plr.Name == "vikchope" then
    firesignal(Event.OnClientEvent,
        "Notify",
        "Greetings, <Color=Red>Agent Chope.<Color=/>"
    )
    else
    firesignal(Event.OnClientEvent, 
        "Notify",
        "Script loaded <Color=Green>succesfully.<Color=/>"
    )
    end
end

notifyuser()
task.wait(2)

local function getClosestLocation(fruit)
    local locations = workspace:FindFirstChild("_WorldOrigin") and workspace._WorldOrigin:FindFirstChild("Locations")
    if not locations then
        return nil, nil
    end

    local fruitPosition
    local handle = fruit:FindFirstChild("Handle")
    if handle and handle:IsA("BasePart") then
        fruitPosition = handle.Position
    elseif fruit.PrimaryPart then
        fruitPosition = fruit.PrimaryPart.Position
    else
        for _, part in ipairs(fruit:GetChildren()) do
            if part:IsA("BasePart") then
                fruitPosition = part.Position
                break
            end
        end
    end

    if not fruitPosition then
        warn("Could not find position for fruit: " .. fruit.Name)
        return nil, nil
    end

    local closestLocation = nil
    local closestDistance = math.huge

    for _, locationPart in ipairs(locations:GetChildren()) do
        if locationPart:IsA("BasePart") then
            local distance = (fruitPosition - locationPart.Position).Magnitude
            if distance < closestDistance then
                closestDistance = distance
                closestLocation = locationPart
            end
        end
    end

    return closestLocation, closestDistance
end

local function sendnotif(target, locationName)
    local Event = game:GetService("ReplicatedStorage").Remotes.CommE
    local island = locationName or "Unknown"
    firesignal(Event.OnClientEvent, 
        "Notify",
        "A " .. target.Name .. " was detected on <Color=Yellow>" .. island .. "!<Color=/>"
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

        local color = tracerColors[math.random(1, #tracerColors)]
        beam.Color = ColorSequence.new(color)
    end

    return true
end

local function checkFruit(v)
    if string.find(v.Name, "Fruit") and v:IsA("Model") and not fruitModels[v] then
        if esp(v) then
            local closestLocation = getClosestLocation(v)
            local locationName = closestLocation and closestLocation.Name or "Unknown"
            sendnotif(v, locationName)
            fruitModels[v] = true
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
