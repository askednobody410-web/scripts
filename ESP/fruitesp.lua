local getfruits = getgenv().AutoGetFruits or false
local viewfruits = getgenv().DebugFruitViewer or false

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local LocalPlayer = Players.LocalPlayer
local Camera = workspace.CurrentCamera

local plr = LocalPlayer
local plrgui = plr:WaitForChild("PlayerGui")
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

local ScreenGui = Instance.new("ScreenGui")
ScreenGui.Name = "FruitESP"
ScreenGui.ResetOnSpawn = false
ScreenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
ScreenGui.Parent = game:GetService("CoreGui")

local function notify(text)
    local Event = game:GetService("ReplicatedStorage"):FindFirstChild("Remotes") and game.ReplicatedStorage.Remotes:FindFirstChild("CommE")
    if Event then
        firesignal(Event.OnClientEvent, "Notify", text)
    end
end

local function notifyuser()
    if plr.Name == "vikchope" then
        notify("Greetings, <Color=Red>Agent Chope.<Color=/>")
    else
        notify("Script loaded <Color=Green>succesfully.<Color=/>")
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
    notify("A " .. target.Name .. " was detected on <Color=Yellow>" .. island .. "!<Color=/>")
end

local function createFruitBox(fruit, color)
    if fruitESP[fruit] then
        fruitESP[fruit].Container:Destroy()
        fruitESP[fruit] = nil
    end

    local handle = fruit:FindFirstChild("Handle")
    if not handle then return end

    local container = Instance.new("Frame")
    container.Name = fruit.Name
    container.BackgroundTransparency = 1
    container.BorderSizePixel = 0
    container.Visible = false
    container.Parent = ScreenGui

    local box = Instance.new("Frame")
    box.Name = "Box"
    box.BackgroundTransparency = 0.88
    box.BackgroundColor3 = Color3.new(0, 0, 0)
    box.BorderSizePixel = 0
    box.Parent = container

    local stroke = Instance.new("UIStroke")
    stroke.Color = color
    stroke.Thickness = 1.4
    stroke.Transparency = 0.1
    stroke.Parent = box

    local nameLabel = Instance.new("TextLabel")
    nameLabel.Name = "Name"
    nameLabel.BackgroundTransparency = 1
    nameLabel.Size = UDim2.new(1, 0, 0, 15)
    nameLabel.Position = UDim2.new(0, 0, 0, -17)
    nameLabel.Font = Enum.Font.GothamMedium
    nameLabel.TextSize = 12
    nameLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
    nameLabel.TextStrokeTransparency = 0.35
    nameLabel.TextStrokeColor3 = Color3.new(0, 0, 0)
    nameLabel.Text = fruit.Name
    nameLabel.TextXAlignment = Enum.TextXAlignment.Center
    nameLabel.Parent = box

    local distLabel = Instance.new("TextLabel")
    distLabel.Name = "DistLabel"
    distLabel.BackgroundTransparency = 1
    distLabel.Size = UDim2.new(1, 0, 0, 12)
    distLabel.Position = UDim2.new(0, 0, 1, 3)
    distLabel.Font = Enum.Font.Gotham
    distLabel.TextSize = 11
    distLabel.TextColor3 = Color3.fromRGB(210, 210, 210)
    distLabel.TextStrokeTransparency = 0.45
    distLabel.Text = ""
    distLabel.TextXAlignment = Enum.TextXAlignment.Center
    distLabel.Parent = box

    fruitESP[fruit] = {
        Container = container,
        Box = box,
        Stroke = stroke,
        Name = nameLabel,
        DistLabel = distLabel,
        Color = color,
        Handle = handle
    }
end

local function removeFruitBox(fruit)
    if fruitESP[fruit] then
        fruitESP[fruit].Container:Destroy()
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
            data.Container.Visible = false
            continue
        end

        local position, onScreen = Camera:WorldToScreenPoint(handle.Position)

        if not onScreen then
            data.Container.Visible = false
            continue
        end

        local distance = (Camera.CFrame.Position - handle.Position).Magnitude

        local size = handle.Size
        local maxDim = math.max(size.X, size.Y, size.Z)
        local worldSize = maxDim * 1.4

        local screenSize = (worldSize / distance) * 300
        screenSize = math.clamp(screenSize, 18, 90)

        data.Box.Size = UDim2.new(0, screenSize, 0, screenSize)
        data.Box.Position = UDim2.new(0, position.X - screenSize / 2, 0, position.Y - screenSize / 2)
        data.Container.Visible = true

        data.DistLabel.Text = string.format("%dm", math.floor(distance))
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

local ORBIT_RADIUS = 10
local ORBIT_ANGLE = 45
local ORBIT_SPEED = 0.3
local CONTAINER_SIZE = UDim2.new(0, 400, 0, 400)
local PANEL_PADDING = 4
local activeCameras = {}
local panels = {}

local function makeDraggable(frame, dragHandle)
    dragHandle = dragHandle or frame
    local dragging = false
    local dragStart, startPos

    dragHandle.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
            dragging = true
            dragStart = input.Position
            startPos = frame.Position
            input.Changed:Connect(function()
                if input.UserInputState == Enum.UserInputState.End then
                    dragging = false
                end
            end)
        end
    end)

    dragHandle.InputChanged:Connect(function(input)
        if dragging and (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then
            local delta = input.Position - dragStart
            frame.Position = UDim2.new(
                startPos.X.Scale, startPos.X.Offset + delta.X,
                startPos.Y.Scale, startPos.Y.Offset + delta.Y
            )
        end
    end)
end

local function getOrCreateViewerGui()
    local screengui = plrgui:FindFirstChild("ScreenGUI1")
    if not screengui then
        screengui = Instance.new("ScreenGui")
        screengui.Name = "ScreenGUI1"
        screengui.ResetOnSpawn = false
        screengui.Parent = plrgui
    end
    return screengui
end

local function getOrCreateContainer()
    local screengui = getOrCreateViewerGui()
    local container = screengui:FindFirstChild("ESPContainer")
    if not container then
        container = Instance.new("Frame")
        container.Name = "ESPContainer"
        container.Parent = screengui
        container.Position = UDim2.new(0.8, 0, 0.75, 0)
        container.Size = CONTAINER_SIZE
        container.BackgroundColor3 = Color3.new(0, 0, 0)
        container.BackgroundTransparency = 0.5
        container.Active = true

        local dragBar = Instance.new("Frame")
        dragBar.Name = "DragBar"
        dragBar.Parent = container
        dragBar.Size = UDim2.new(1, 0, 0, 20)
        dragBar.Position = UDim2.new(0, 0, 0, 0)
        dragBar.BackgroundColor3 = Color3.new(0.15, 0.15, 0.15)
        dragBar.BackgroundTransparency = 0.2
        dragBar.Active = true
        dragBar.ZIndex = 2

        local label = Instance.new("TextLabel")
        label.Name = "Title"
        label.Parent = dragBar
        label.Size = UDim2.new(1, 0, 1, 0)
        label.BackgroundTransparency = 1
        label.Text = "ESP"
        label.TextColor3 = Color3.new(1, 1, 1)
        label.Font = Enum.Font.SourceSansBold
        label.TextSize = 14
        label.ZIndex = 2

        makeDraggable(container, dragBar)

        local grid = Instance.new("Frame")
        grid.Name = "PanelGrid"
        grid.Parent = container
        grid.Position = UDim2.new(0, 0, 0, 20)
        grid.Size = UDim2.new(1, 0, 1, -20)
        grid.BackgroundTransparency = 1

        local layout = Instance.new("UIGridLayout")
        layout.Name = "GridLayout"
        layout.Parent = grid
        layout.SortOrder = Enum.SortOrder.LayoutOrder
        layout.CellPadding = UDim2.new(0, PANEL_PADDING, 0, PANEL_PADDING)
    end
    return container
end

local function relayoutGrid()
    local screengui = plrgui:FindFirstChild("ScreenGUI1")
    if not screengui then return end
    local container = screengui:FindFirstChild("ESPContainer")
    if not container then return end
    local grid = container:FindFirstChild("PanelGrid")
    if not grid then return end
    local layout = grid:FindFirstChild("GridLayout")
    if not layout then return end

    local count = 0
    for _ in pairs(panels) do count += 1 end
    if count == 0 then return end

    local columns = math.max(1, math.ceil(math.sqrt(count)))
    local rows = math.max(1, math.ceil(count / columns))
    local gridAbsSize = grid.AbsoluteSize
    local cellWidth = (gridAbsSize.X - (columns - 1) * PANEL_PADDING) / columns
    local cellHeight = (gridAbsSize.Y - (rows - 1) * PANEL_PADDING) / rows
    layout.CellSize = UDim2.new(0, math.max(cellWidth, 10), 0, math.max(cellHeight, 10))
end

local function createFruitViewer(target)
    if not viewfruits then return end

    local handle = target:FindFirstChild("Handle")
    if not handle then return end

    local container = getOrCreateContainer()
    local grid = container:FindFirstChild("PanelGrid")
    if not grid then return end

    local panelName = "Panel_" .. target.Name
    local oldPanel = grid:FindFirstChild(panelName)
    if oldPanel then oldPanel:Destroy() end

    local panel = Instance.new("Frame")
    panel.Name = panelName
    panel.Parent = grid
    panel.BackgroundTransparency = 1
    panels[target.Name] = panel

    local viewportframe = Instance.new("ViewportFrame")
    viewportframe.Name = "VPFrame"
    viewportframe.Parent = panel
    viewportframe.Size = UDim2.new(1, 0, 1, 0)
    viewportframe.BackgroundTransparency = 1

    local clone = target:Clone()
    clone.Name = target.Name .. "_Clone"
    clone.Parent = viewportframe

    local ok = pcall(function()
        clone:PivotTo(CFrame.new(0, 0, 0))
    end)
    if not ok then
        clone:Destroy()
        panel:Destroy()
        panels[target.Name] = nil
        return
    end

    local viewportcamera = Instance.new("Camera")
    viewportcamera.Name = "VPCam"
    viewportcamera.Parent = viewportframe
    viewportcamera.FieldOfView = 50

    local angleRad = math.rad(ORBIT_ANGLE)
    local horizDist = ORBIT_RADIUS * math.cos(angleRad)
    local height = ORBIT_RADIUS * math.sin(angleRad)
    pcall(function()
        viewportcamera.CFrame = CFrame.new(Vector3.new(horizDist, height, 0), Vector3.new(0, 0, 0))
    end)

    viewportframe.CurrentCamera = viewportcamera
    activeCameras[viewportcamera] = 0

    viewportcamera.AncestryChanged:Connect(function(_, parent)
        if not parent then
            activeCameras[viewportcamera] = nil
        end
    end)

    relayoutGrid()
end

local function cleanupFruitViewer(name)
    if panels[name] then
        panels[name]:Destroy()
        panels[name] = nil
    end
    relayoutGrid()
end

if viewfruits then
    RunService.Heartbeat:Connect(function(dt)
        local angleRad = math.rad(ORBIT_ANGLE)
        local horizRadius = ORBIT_RADIUS * math.cos(angleRad)
        local height = ORBIT_RADIUS * math.sin(angleRad)

        for cam, progress in pairs(activeCameras) do
            if cam and cam.Parent then
                progress = progress + dt * ORBIT_SPEED
                activeCameras[cam] = progress
                local x = horizRadius * math.cos(progress)
                local z = horizRadius * math.sin(progress)
                local ok = pcall(function()
                    cam.CFrame = CFrame.new(Vector3.new(x, height, z), Vector3.new(0, 0, 0))
                end)
                if not ok then
                    activeCameras[cam] = nil
                end
            else
                activeCameras[cam] = nil
            end
        end
    end)
end

local function checkFruit(v)
    if string.find(v.Name, "Fruit") and v:IsA("Model") and not fruitModels[v] then
        local color = tracerColors[math.random(1, #tracerColors)]

        if createTracer(v, color) then
            createFruitBox(v, color)
            createFruitViewer(v)

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
        cleanupFruitViewer(v.Name)

        local beam = workspace:FindFirstChild("Tracer_" .. v.Name)
        if beam then
            beam:Destroy()
        end
    end
end)

RunService.RenderStepped:Connect(updateFruitBoxes)
