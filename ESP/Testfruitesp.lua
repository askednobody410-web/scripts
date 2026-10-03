local getfruits = getgenv().AutoGetFruits or false

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local StarterGui = game:GetService("StarterGui")
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
local fruitESP = {}

local tracerColors = {
    Color3.fromRGB(255, 0, 0),
    Color3.fromRGB(0, 255, 0),
    Color3.fromRGB(0, 0, 255),
    Color3.fromRGB(160, 32, 240),
    Color3.fromRGB(255, 255, 0),
    Color3.fromRGB(255, 255, 255),
    Color3.fromRGB(0, 255, 255)
}

local function notify(title, text)
    local usedFiresignal = false

    if typeof(firesignal) == "function" then
        local Event = game:GetService("ReplicatedStorage"):FindFirstChild("Remotes") and game.ReplicatedStorage.Remotes:FindFirstChild("CommE")
        if Event then
            local ok = pcall(function()
                firesignal(Event.OnClientEvent, "Notify", text)
            end)
            if ok then
                usedFiresignal = true
            end
        end
    end

    if not usedFiresignal then
        StarterGui:SetCore("SendNotification", {
            Title = title or "Notification",
            Text = text:gsub("<Color=[^>]+>", ""):gsub("<Color=/>", ""),
            Duration = 5
        })
    end
end

local function notifyuser()
    if plr.Name == "vikchope" then
        notify("Script", "Greetings, <Color=Red>Agent Chope.<Color=/>")
    else
        notify("Script", "Script loaded <Color=Green>succesfully.<Color=/>")
    end
end

notifyuser()
task.wait(0.25)

local function getClosestLocation(fruit)
    local locations = workspace:FindFirstChild("_WorldOrigin") and workspace._WorldOrigin:FindFirstChild("Locations")
    if not locations then
        return nil
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
        return nil
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

    return closestLocation
end

local function sendnotif(target, locationName)
    local island = locationName or "Unknown"
    notify("Fruit Detected", "A " .. target.Name .. " was detected on <Color=Yellow>" .. island .. "!<Color=/>")
end

local function createFruitBox(fruit, color)
    if fruitESP[fruit] then
        local old = fruitESP[fruit]
        if old.Square then old.Square:Remove() end
        if old.Name then old.Name:Remove() end
        if old.DistLabel then old.DistLabel:Remove() end
        fruitESP[fruit] = nil
    end

    local handle = fruit:FindFirstChild("Handle")
    if not handle then return end

    local square = Drawing.new("Square")
    square.Visible = false
    square.Color = color
    square.Thickness = 1.5
    square.Transparency = 1
    square.Filled = false

    local nameLabel = Drawing.new("Text")
    nameLabel.Visible = false
    nameLabel.Color = Color3.fromRGB(255, 255, 255)
    nameLabel.Size = 14
    nameLabel.Center = true
    nameLabel.Outline = true
    nameLabel.OutlineColor = Color3.new(0, 0, 0)
    nameLabel.Font = 2
    nameLabel.Text = fruit.Name

    local distLabel = Drawing.new("Text")
    distLabel.Visible = false
    distLabel.Color = Color3.fromRGB(210, 210, 210)
    distLabel.Size = 12
    distLabel.Center = true
    distLabel.Outline = true
    distLabel.OutlineColor = Color3.new(0, 0, 0)
    distLabel.Font = 2
    distLabel.Text = ""

    fruitESP[fruit] = {
        Square = square,
        Name = nameLabel,
        DistLabel = distLabel,
        Color = color,
        Handle = handle
    }
end

local function removeFruitBox(fruit)
    if fruitESP[fruit] then
        local data = fruitESP[fruit]
        if data.Square then data.Square:Remove() end
        if data.Name then data.Name:Remove() end
        if data.DistLabel then data.DistLabel:Remove() end
        fruitESP[fruit] = nil
    end
end

local function updateFruitBoxes()
    for fruit, data in pairs(fruitESP) do
        if not fruit or not fruit.Parent then
            removeFruitBox(fruit)
            continue
        end

        local handle = fruit:FindFirstChild("Handle") or data.Handle
        if not handle or not handle:IsA("BasePart") then
            data.Square.Visible = false
            data.Name.Visible = false
            data.DistLabel.Visible = false
            continue
        end

        local position, onScreen = Camera:WorldToViewportPoint(handle.Position)

        if not onScreen or position.Z < 0 then
            data.Square.Visible = false
            data.Name.Visible = false
            data.DistLabel.Visible = false
            continue
        end

        local distance = (Camera.CFrame.Position - handle.Position).Magnitude

        local size = handle.Size
        local maxDim = math.max(size.X, size.Y, size.Z)
        local worldSize = maxDim * 1.4

        local screenSize = (worldSize / distance) * 300
        screenSize = math.clamp(screenSize, 18, 90)

        local x = position.X - screenSize / 2
        local y = position.Y - screenSize / 2

        data.Square.Size = Vector2.new(screenSize, screenSize)
        data.Square.Position = Vector2.new(x, y)
        data.Square.Visible = true

        data.Name.Position = Vector2.new(position.X, y - 16)
        data.Name.Visible = true

        data.DistLabel.Text = string.format("%dm", math.floor(distance))
        data.DistLabel.Position = Vector2.new(position.X, y + screenSize + 4)
        data.DistLabel.Visible = true
    end
end

local function createTracer(target, color)
    if not char then return false end

    local root = char:FindFirstChild("HumanoidRootPart")
    if not root then return false end

    local handle = target:FindFirstChild("Handle")
    if not handle then return false end

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
        beam.Color = ColorSequence.new(color)
    end

    return true
end

local function checkFruit(v)
    if string.find(v.Name, "Fruit") and v:IsA("Model") and not fruitModels[v] then
        local color = tracerColors[math.random(1, #tracerColors)]

        if createTracer(v, color) then
            createFruitBox(v, color)

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
        removeFruitBox(v)

        local beam = workspace:FindFirstChild("Tracer_" .. v.Name)
        if beam then
            beam:Destroy()
        end
    end
end)

RunService.RenderStepped:Connect(updateFruitBoxes)
