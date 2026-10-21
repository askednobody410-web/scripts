if getgenv().ItemsESPLoaded then
    if typeof(getgenv().ItemsESPUnload) == "function" then
        getgenv().ItemsESPUnload()
    end
end

local Players = game:GetService("Players")
local Workspace = game:GetService("Workspace")
local RunService = game:GetService("RunService")

local LocalPlayer = Players.LocalPlayer
local Camera = Workspace.CurrentCamera

if typeof(Drawing) ~= "table" and typeof(Drawing) ~= "userdata" then
    warn("[ItemsESP] Drawing library not available")
    return
end

local itemSpawns = Workspace:WaitForChild("Item_Spawns", 10)
if not itemSpawns then
    warn("[ItemsESP] Item_Spawns not found")
    return
end

local ItemsFolder = itemSpawns:WaitForChild("Items", 10)
if not ItemsFolder then
    warn("[ItemsESP] Items folder not found")
    return
end

local tracked = {}
local connections = {}

local COLORS = {
    Common   = Color3.fromRGB(128, 128, 128),
    Uncommon = Color3.fromRGB(0, 200, 0),
    Epic     = Color3.fromRGB(150, 0, 200),
}
local DEFAULT_COLOR = Color3.fromRGB(255, 215, 0)

local function getColor(rarity)
    return COLORS[rarity] or DEFAULT_COLOR
end

local function getHead(instance)
    if not instance or not instance.Parent then return nil end
    if instance:IsA("Model") then
        return instance:FindFirstChild("Head") or instance.PrimaryPart
    elseif instance:IsA("BasePart") then
        return instance
    end
    return nil
end

local function startTracking(instance)
    if tracked[instance] then return end

    local head = getHead(instance)
    if not head then return end

    local ok, line = pcall(function()
        local l = Drawing.new("Line")
        l.Thickness = 1
        l.Color = getColor(instance:GetAttribute("Rarity"))
        l.Transparency = 1
        l.Visible = false
        return l
    end)
    if not ok or not line then return end

    tracked[instance] = { line = line }
end

local function stopTracking(instance)
    local data = tracked[instance]
    if not data then return end
    if data.line then
        pcall(function() data.line:Destroy() end)
    end
    tracked[instance] = nil
end

local function updateAll()
    local char = LocalPlayer.Character
    local root = char and char:FindFirstChild("HumanoidRootPart")
    if not root then
        for _, data in pairs(tracked) do
            if data.line then data.line.Visible = false end
        end
        return
    end

    local rootPos, rootVisible = Camera:WorldToViewportPoint(root.Position)
    local rootOn = rootVisible and rootPos.Z > 0
    local to = Vector2.new(rootPos.X, rootPos.Y)

    for instance, data in pairs(tracked) do
        if not instance or not instance.Parent then
            stopTracking(instance)
            continue
        end

        local head = getHead(instance)
        if not head then
            data.line.Visible = false
            continue
        end

        local sp, onScreen = Camera:WorldToViewportPoint(head.Position)
        local fromOn = onScreen and sp.Z > 0

        if fromOn and rootOn then
            data.line.From = Vector2.new(sp.X, sp.Y)
            data.line.To = to
            data.line.Visible = true
        else
            data.line.Visible = false
        end
    end
end

local function unload()
    for instance in pairs(tracked) do
        stopTracking(instance)
    end
    table.clear(tracked)

    for _, conn in ipairs(connections) do
        if conn and conn.Connected then
            conn:Disconnect()
        end
    end
    table.clear(connections)

    getgenv().ItemsESPLoaded = false
    getgenv().ItemsESPUnload = nil
end

getgenv().ItemsESPUnload = unload
getgenv().ItemsESPLoaded = true

for _, v in ipairs(ItemsFolder:GetChildren()) do
    startTracking(v)
end

table.insert(connections, ItemsFolder.ChildAdded:Connect(startTracking))
table.insert(connections, ItemsFolder.ChildRemoved:Connect(stopTracking))
table.insert(connections, RunService.RenderStepped:Connect(updateAll))
