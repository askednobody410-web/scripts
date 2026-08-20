local plr = game:GetService("Players").LocalPlayer
local char = game.Workspace.Characters:FindFirstChild(plr.Name)

if not char then
    for _, v in pairs(game.Workspace.Characters:GetChildren()) do
        if v.Name == plr.Name then
            char = v
        end
    end
end

local function notifyuser()
    local startergui = game:GetService("StarterGui")
    startergui:SetCore("SendNotification", {
    Title = "Script loaded succesfully.",
    Text = "made by tuxsaeht"
    })
end

local function sendnotif(target)
    local startergui = game:GetService("StarterGui")
    startergui:SetCore("SendNotification", {
    Title = "Fruit detected!",
    Text = "A " .. target.Name .. " was detected!",
    Duration = 5
    })
end

local function esp(target)
    local hrp = char.HumanoidRootPart
    if not target.Handle then warn("No handle found! (Corrupted fruit model.)") end
    if not hrp then warn("Character doesn't exist!") return end
    local a0 = hrp:FindFirstChild("Attachment0")
    if not a0 then
        a0 = Instance.new("Attachment")
        a0.Name = "Attachment0"
        a0.Parent = hrp
    end
    local a1 = target:WaitForChild("Handle",1):FindFirstChild("Attachment1")
    if not a1 then
        a1 = Instance.new("Attachment")
        a1.Name = "Attachment1"
        a1.Parent = target:WaitForChild("Handle",1)
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
    end
end

for _, v in pairs(game.Workspace:GetChildren()) do
    if string.find(v.Name, "Fruit") then
        esp(v)
        sendnotif(v)
    end
end

game.Workspace.ChildAdded:Connect(function(v)
    if string.find(v.Name, "Fruit") then
        esp(v)
        sendnotif(v)
    end
end)

notifyuser()
