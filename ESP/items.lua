local Players = game:GetService("Players")
local Workspace = game:GetService("Workspace")
local RunService = game:GetService("RunService")

local LocalPlayer = Players.LocalPlayer
local Camera = Workspace.CurrentCamera

local ItemsFolder = Workspace:WaitForChild("Item_Spawns"):WaitForChild("Items")
local tracked = {}

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
    if instance:IsA("Model") then
        return instance:FindFirstChild("Head") or instance.PrimaryPart
    elseif instance:IsA("BasePart") then
        return instance
    end
end

local function worldToScreen(pos)
    local sp, onScreen = Camera:WorldToViewportPoint(pos)
    return Vector2.new(sp.X, sp.Y), onScreen and sp.Z > 0
end

local function startTracking(instance)
    if tracked[instance] then return end

    local head = getHead(instance)
    if not head then return end

    local line = Drawing.new("Line")
    line.Thickness = 1
    line.Color = getColor(instance:GetAttribute("Rarity"))
    line.Transparency = 1
    line.Visible = false

    local conn = RunService.RenderStepped:Connect(function()
        if not head.Parent then
            line.Visible = false
            return
        end

        local char = LocalPlayer.Character
        local root = char and char:FindFirstChild("HumanoidRootPart")
        if not root then
            line.Visible = false
            return
        end

        local from, fromOn = worldToScreen(head.Position)
        local to, toOn = worldToScreen(root.Position)

        line.From = from
        line.To = to
        line.Visible = fromOn and toOn
    end)

    tracked[instance] = { line = line, conn = conn }
end

local function stopTracking(instance)
    local data = tracked[instance]
    if not data then return end
    data.conn:Disconnect()
    data.line:Remove()
    tracked[instance] = nil
end

for _, v in ipairs(ItemsFolder:GetChildren()) do
    startTracking(v)
end
print("ready")

ItemsFolder.ChildAdded:Connect(startTracking)
ItemsFolder.ChildRemoved:Connect(stopTracking)
