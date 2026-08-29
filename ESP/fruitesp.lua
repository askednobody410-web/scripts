local getfruits = getgenv().AutoGetFruits or false

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local LocalPlayer = Players.LocalPlayer
local Camera = workspace.CurrentCamera

local plr = LocalPlayer
local char = workspace.Characters:FindFirstChild(plr.Name)

if not char then
    for _, v in pairs(workspace.Characters:GetChildren()) do
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

-- ===================== FRUIT NOTIFICATIONS =====================

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

-- ===================== FRUIT TRACERS =====================

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

    local beam = workspace:FindFirstChild("Tracer_" .. target.Name)
    if not beam then
        beam = Instance.new("Beam")
        beam.Parent = workspace
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

for _, v in pairs(workspace:GetChildren()) do
    checkFruit(v)
end

workspace.ChildAdded:Connect(function(v)
    checkFruit(v)
end)

workspace.ChildRemoved:Connect(function(v)
    if string.find(v.Name, "Fruit") then
        fruitModels[v] = nil
        local beam = workspace:FindFirstChild("Tracer_" .. v.Name)
        if beam then
            beam:Destroy()
        end
    end
end)

-- ===================== PLAYER ESP =====================

local PlayerESP = {}
local ESPEnabled = true
local AccentColor = Color3.fromRGB(0, 255, 255) -- cyan to match tracers

local ScreenGui = Instance.new("ScreenGui")
ScreenGui.Name = "PlayerESP"
ScreenGui.ResetOnSpawn = false
ScreenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
ScreenGui.Parent = game:GetService("CoreGui")

local function CreatePlayerESP(player)
    if player == LocalPlayer then return end
    if PlayerESP[player] then
        PlayerESP[player].Container:Destroy()
        PlayerESP[player] = nil
    end

    local character = player.Character
    if not character then return end

    local humanoid = character:FindFirstChildOfClass("Humanoid")
    local hrp = character:FindFirstChild("HumanoidRootPart")
    if not humanoid or not hrp then return end

    local container = Instance.new("Frame")
    container.Name = player.Name
    container.BackgroundTransparency = 1
    container.BorderSizePixel = 0
    container.Visible = false
    container.Parent = ScreenGui

    -- Bounding box (minimal)
    local box = Instance.new("Frame")
    box.Name = "Box"
    box.BackgroundTransparency = 0.85
    box.BackgroundColor3 = Color3.new(0, 0, 0)
    box.BorderSizePixel = 0
    box.Parent = container

    local stroke = Instance.new("UIStroke")
    stroke.Color = AccentColor
    stroke.Thickness = 1.2
    stroke.Transparency = 0.15
    stroke.Parent = box

    -- Name label (top)
    local nameLabel = Instance.new("TextLabel")
    nameLabel.Name = "Name"
    nameLabel.BackgroundTransparency = 1
    nameLabel.Size = UDim2.new(1, 0, 0, 16)
    nameLabel.Position = UDim2.new(0, 0, 0, -18)
    nameLabel.Font = Enum.Font.GothamMedium
    nameLabel.TextSize = 13
    nameLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
    nameLabel.TextStrokeTransparency = 0.4
    nameLabel.TextStrokeColor3 = Color3.new(0, 0, 0)
    nameLabel.Text = player.Name
    nameLabel.TextXAlignment = Enum.TextXAlignment.Center
    nameLabel.Parent = box

    -- Distance meter background (bottom)
    local distBg = Instance.new("Frame")
    distBg.Name = "DistBg"
    distBg.Size = UDim2.new(1, 0, 0, 4)
    distBg.Position = UDim2.new(0, 0, 1, 2)
    distBg.BackgroundColor3 = Color3.fromRGB(20, 20, 20)
    distBg.BackgroundTransparency = 0.3
    distBg.BorderSizePixel = 0
    distBg.Parent = box

    local distFill = Instance.new("Frame")
    distFill.Name = "DistFill"
    distFill.Size = UDim2.new(1, 0, 1, 0)
    distFill.BackgroundColor3 = AccentColor
    distFill.BorderSizePixel = 0
    distFill.Parent = distBg

    local distLabel = Instance.new("TextLabel")
    distLabel.Name = "DistLabel"
    distLabel.BackgroundTransparency = 1
    distLabel.Size = UDim2.new(1, 0, 0, 12)
    distLabel.Position = UDim2.new(0, 0, 1, 7)
    distLabel.Font = Enum.Font.Gotham
    distLabel.TextSize = 11
    distLabel.TextColor3 = Color3.fromRGB(200, 200, 200)
    distLabel.TextStrokeTransparency = 0.5
    distLabel.Text = ""
    distLabel.TextXAlignment = Enum.TextXAlignment.Center
    distLabel.Parent = box

    PlayerESP[player] = {
        Container = container,
        Box = box,
        Stroke = stroke,
        Name = nameLabel,
        DistBg = distBg,
        DistFill = distFill,
        DistLabel = distLabel,
        Humanoid = humanoid,
        HRP = hrp
    }
end

local function RemovePlayerESP(player)
    if PlayerESP[player] then
        PlayerESP[player].Container:Destroy()
        PlayerESP[player] = nil
    end
end

local function UpdatePlayerESP()
    for player, data in pairs(PlayerESP) do
        if not ESPEnabled then
            data.Container.Visible = false
            continue
        end

        local character = player.Character
        if not character then
            data.Container.Visible = false
            continue
        end

        local humanoid = character:FindFirstChildOfClass("Humanoid")
        local hrp = character:FindFirstChild("HumanoidRootPart")

        if not humanoid or not hrp or humanoid.Health <= 0 then
            data.Container.Visible = false
            continue
        end

        local position, onScreen = Camera:WorldToScreenPoint(hrp.Position)

        if not onScreen then
            data.Container.Visible = false
            continue
        end

        local distance = (Camera.CFrame.Position - hrp.Position).Magnitude
        local scale = math.clamp(450 / distance, 28, 75)
        local boxHeight = scale
        local boxWidth = scale * 0.42

        data.Box.Size = UDim2.new(0, boxWidth, 0, boxHeight)
        data.Box.Position = UDim2.new(0, position.X - boxWidth / 2, 0, position.Y - boxHeight / 2)
        data.Container.Visible = true

        -- Distance meter (fills based on proximity, closer = fuller)
        local maxDist = 800
        local fill = math.clamp(1 - (distance / maxDist), 0.08, 1)
        data.DistFill.Size = UDim2.new(fill, 0, 1, 0)

        -- Color shifts slightly with distance (still cyan family)
        local intensity = math.clamp(1 - (distance / 600), 0.4, 1)
        data.Stroke.Color = Color3.fromRGB(0, 200 + 55 * intensity, 255)
        data.DistFill.BackgroundColor3 = data.Stroke.Color

        data.DistLabel.Text = string.format("%dm", math.floor(distance))

        data.Humanoid = humanoid
        data.HRP = hrp
    end
end

local function OnPlayerAdded(player)
    task.defer(function()
        CreatePlayerESP(player)
    end)

    player.CharacterAdded:Connect(function()
        task.wait(0.3)
        CreatePlayerESP(player)
    end)
end

for _, player in ipairs(Players:GetPlayers()) do
    OnPlayerAdded(player)
end

Players.PlayerAdded:Connect(OnPlayerAdded)
Players.PlayerRemoving:Connect(RemovePlayerESP)

RunService.RenderStepped:Connect(UpdatePlayerESP)

UserInputService.InputBegan:Connect(function(input, gameProcessed)
    if gameProcessed then return end
    if input.KeyCode == Enum.KeyCode.F then
        ESPEnabled = not ESPEnabled
        print(ESPEnabled and "[ESP] ON" or "[ESP] OFF")
    end
end)

print("[ESP] Loaded | Press F to toggle player ESP")
