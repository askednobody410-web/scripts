if getgenv().FruitESPLoaded then
    if typeof(getgenv().FruitESPUnload) == "function" then
        getgenv().FruitESPUnload()
    end
end

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local StarterGui = game:GetService("StarterGui")
local LocalPlayer = Players.LocalPlayer
local Camera = workspace.CurrentCamera

if typeof(Drawing) ~= "table" and typeof(Drawing) ~= "userdata" then
    warn("[FruitESP] Drawing library not available")
    return
end

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

local fruitModels = {}
local fruitESP = {}
local connections = {}

local GOLDEN = Color3.fromRGB(255, 215, 0)

local tracerColors = {
    Color3.fromRGB(255, 0, 0),
    Color3.fromRGB(0, 255, 0),
    Color3.fromRGB(0, 0, 255),
    Color3.fromRGB(160, 32, 240),
    Color3.fromRGB(0, 255, 255),
    Color3.fromRGB(255, 255, 255),
    Color3.fromRGB(255, 105, 180),
    Color3.fromRGB(255, 140, 0),
    Color3.fromRGB(50, 255, 50),
    Color3.fromRGB(0, 191, 255),
    Color3.fromRGB(255, 20, 147),
}

local function notify(title, text)
    local usedFiresignal = false

    if typeof(firesignal) == "function" then
        local Event = game:GetService("ReplicatedStorage"):FindFirstChild("Remotes")
            and game.ReplicatedStorage.Remotes:FindFirstChild("CommE")
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
        local clean = text
            :gsub("<Color=[^>]+>", "")
            :gsub("<Color=/>", "")
            :gsub("</Color>", "")
        local ok, err = pcall(function()
            StarterGui:SetCore("SendNotification", {
                Title = title or "Notification",
                Text = clean,
                Duration = 5
            })
        end)
        if not ok then
            warn("[FruitESP] SetCore notify failed:", err)
        end
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

local function refreshChar()
    char = workspace.Characters:FindFirstChild(plr.Name)
    if not char then
        for _, v in pairs(workspace.Characters:GetChildren()) do
            if v.Name == plr.Name then
                char = v
                break
            end
        end
    end
    return char
end

local function getLocalRoot()
    if not char or not char.Parent then
        refreshChar()
    end
    if not char then return nil end
    return char:FindFirstChild("Head") or char:FindFirstChild("HumanoidRootPart")
end

local function tryCollect(fruit, handle)
    if not getgenv().AutoGetFruits then return end
    if not fruit:IsA("Tool") then return end

    if not char or not char.Parent then
        refreshChar()
    end
    local hrp = char and char:FindFirstChild("HumanoidRootPart")
    if not hrp or not handle then return end

    if typeof(firetouchinterest) == "function" then
        pcall(function()
            firetouchinterest(hrp, handle, 0)
            firetouchinterest(hrp, handle, 1)
        end)
    end
end

local function removeFruitESP(fruit)
    local data = fruitESP[fruit]
    if not data then return end

    if data.Square then pcall(function() data.Square:Destroy() end) end
    if data.Name then pcall(function() data.Name:Destroy() end) end
    if data.DistLabel then pcall(function() data.DistLabel:Destroy() end) end
    if data.Tracer then pcall(function() data.Tracer:Destroy() end) end
    fruitESP[fruit] = nil
end

local function createFruitESP(fruit, color)
    removeFruitESP(fruit)

    local handle = fruit:FindFirstChild("Handle")
    if not handle then return false end

    local root = getLocalRoot()
    if not root then return false end

    tryCollect(fruit, handle)

    local isGenericFruit = (fruit.Name == "Fruit")
    local lineColor = isGenericFruit and GOLDEN or color
    local lineThickness = isGenericFruit and 3 or 1.5

    local ok, square = pcall(function()
        local s = Drawing.new("Square")
        s.Visible = false
        s.Color = lineColor
        s.Thickness = 1.5
        s.Transparency = 1
        s.Filled = false
        return s
    end)
    if not ok or not square then return false end

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

    local tracer = Drawing.new("Line")
    tracer.Visible = false
    tracer.Color = lineColor
    tracer.Thickness = lineThickness
    tracer.Transparency = 1

    fruitESP[fruit] = {
        Square = square,
        Name = nameLabel,
        DistLabel = distLabel,
        Tracer = tracer,
        Color = lineColor,
        Handle = handle
    }

    return true
end

local function updateFruitESP()
    local root = getLocalRoot()
    local tracerOrigin = nil
    local rootOnScreen = false

    if root then
        local rootPos, rootVisible = Camera:WorldToViewportPoint(root.Position)
        if rootVisible and rootPos.Z > 0 then
            tracerOrigin = Vector2.new(rootPos.X, rootPos.Y)
            rootOnScreen = true
        end
    end

    for fruit, data in pairs(fruitESP) do
        if not fruit or not fruit.Parent then
            removeFruitESP(fruit)
            continue
        end

        local handle = fruit:FindFirstChild("Handle") or data.Handle
        if not handle or not handle:IsA("BasePart") then
            data.Square.Visible = false
            data.Name.Visible = false
            data.DistLabel.Visible = false
            data.Tracer.Visible = false
            continue
        end

        local position, onScreen = Camera:WorldToViewportPoint(handle.Position)

        if not onScreen or position.Z < 0 then
            data.Square.Visible = false
            data.Name.Visible = false
            data.DistLabel.Visible = false
            data.Tracer.Visible = false
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
        local center = Vector2.new(position.X, position.Y)

        data.Square.Size = Vector2.new(screenSize, screenSize)
        data.Square.Position = Vector2.new(x, y)
        data.Square.Visible = true

        data.Name.Position = Vector2.new(position.X, y - 16)
        data.Name.Visible = true

        data.DistLabel.Text = string.format("%dm", math.floor(distance))
        data.DistLabel.Position = Vector2.new(position.X, y + screenSize + 4)
        data.DistLabel.Visible = true

        if rootOnScreen and tracerOrigin then
            data.Tracer.From = tracerOrigin
            data.Tracer.To = center
            data.Tracer.Visible = true
        else
            data.Tracer.Visible = false
        end
    end
end

local function checkFruit(v)
    if string.find(v.Name, "Fruit") and v:IsA("Model") and not fruitModels[v] then
        local color = tracerColors[math.random(1, #tracerColors)]

        if createFruitESP(v, color) then
            local closestLocation = getClosestLocation(v)
            local locationName = closestLocation and closestLocation.Name or "Unknown"
            sendnotif(v, locationName)

            fruitModels[v] = true
        end
    end
end

local function unload()
    for fruit in pairs(fruitESP) do
        removeFruitESP(fruit)
    end
    table.clear(fruitModels)
    table.clear(fruitESP)

    for _, conn in ipairs(connections) do
        if conn and conn.Connected then
            conn:Disconnect()
        end
    end
    table.clear(connections)

    getgenv().FruitESPLoaded = false
    getgenv().FruitESPUnload = nil
end

getgenv().FruitESPUnload = unload
getgenv().FruitESPLoaded = true

for _, v in pairs(workspace:GetChildren()) do
    checkFruit(v)
end

table.insert(connections, workspace.ChildAdded:Connect(checkFruit))

table.insert(connections, workspace.ChildRemoved:Connect(function(v)
    if string.find(v.Name, "Fruit") then
        fruitModels[v] = nil
        removeFruitESP(v)
    end
end))

table.insert(connections, RunService.RenderStepped:Connect(updateFruitESP))
