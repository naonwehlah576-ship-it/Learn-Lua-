print("SCANNER START")

local player = game.Players.LocalPlayer

local parentGui
pcall(function()
    parentGui = gethui()
end)

if not parentGui then
    parentGui = game.CoreGui
end

local gui = Instance.new("ScreenGui")
gui.Parent = parentGui

local frame = Instance.new("Frame")
frame.Size = UDim2.new(0,400,0,300)
frame.Position = UDim2.new(0.5,-200,0.5,-150)
frame.BackgroundColor3 = Color3.fromRGB(30,30,30)
frame.Parent = gui

local title = Instance.new("TextLabel")
title.Size = UDim2.new(1,0,0,30)
title.Text = "Game Scanner"
title.BackgroundColor3 = Color3.fromRGB(50,50,50)
title.TextColor3 = Color3.new(1,1,1)
title.Parent = frame

local box = Instance.new("TextBox")
box.Size = UDim2.new(1,-10,1,-40)
box.Position = UDim2.new(0,5,0,35)
box.TextXAlignment = Enum.TextXAlignment.Left
box.TextYAlignment = Enum.TextYAlignment.Top
box.TextWrapped = false
box.ClearTextOnFocus = false
box.MultiLine = true
box.Text = ""
box.BackgroundColor3 = Color3.fromRGB(20,20,20)
box.TextColor3 = Color3.new(1,1,1)
box.Parent = frame

local function add(text)
    box.Text = box.Text .. "\n" .. text
end

add("Scanning Workspace...")

for _,v in pairs(workspace:GetDescendants()) do
    if v:IsA("Part") or v:IsA("Model") then
        add(v.Name)
    end
end

add("---- ReplicatedStorage ----")

local rs = game:GetService("ReplicatedStorage")

for _,v in pairs(rs:GetDescendants()) do
    if v:IsA("RemoteEvent") or v:IsA("RemoteFunction") then
        add("Remote: "..v.Name)
    end
end

add("Scan Finished")
