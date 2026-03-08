print("Radius Scanner Loaded")

local player = game.Players.LocalPlayer

local gui = Instance.new("ScreenGui")
gui.Name = "RadiusScanner"
gui.Parent = game.CoreGui

local frame = Instance.new("Frame")
frame.Size = UDim2.new(0,350,0,250)
frame.Position = UDim2.new(0.5,-175,0.5,-125)
frame.BackgroundColor3 = Color3.fromRGB(25,25,25)
frame.Parent = gui

local title = Instance.new("TextLabel")
title.Size = UDim2.new(1,0,0,30)
title.Text = "Radius Scanner"
title.TextColor3 = Color3.new(1,1,1)
title.BackgroundColor3 = Color3.fromRGB(40,40,40)
title.Parent = frame

local box = Instance.new("TextBox")
box.Size = UDim2.new(1,-20,1,-80)
box.Position = UDim2.new(0,10,0,40)
box.Text = ""
box.TextColor3 = Color3.new(1,1,1)
box.TextXAlignment = Enum.TextXAlignment.Left
box.TextYAlignment = Enum.TextYAlignment.Top
box.ClearTextOnFocus = false
box.BackgroundColor3 = Color3.fromRGB(20,20,20)
box.MultiLine = true
box.Parent = frame

local scan = Instance.new("TextButton")
scan.Size = UDim2.new(0.45,0,0,30)
scan.Position = UDim2.new(0.05,0,1,-35)
scan.Text = "SCAN"
scan.BackgroundColor3 = Color3.fromRGB(60,120,60)
scan.Parent = frame

local close = Instance.new("TextButton")
close.Size = UDim2.new(0.45,0,0,30)
close.Position = UDim2.new(0.5,0,1,-35)
close.Text = "CLOSE"
close.BackgroundColor3 = Color3.fromRGB(120,60,60)
close.Parent = frame

local radius = 60 -- jarak scan (studs)

scan.MouseButton1Click:Connect(function()

box.Text = "Scanning around player...\n"

local char = player.Character
if not char then return end

local hrp = char:FindFirstChild("HumanoidRootPart")
if not hrp then return end

for _,v in pairs(workspace:GetDescendants()) do

if v:IsA("BasePart") then

local distance = (v.Position - hrp.Position).Magnitude

if distance <= radius then

if string.find(v.Name,"Submit")
or string.find(v.Name,"Sell")
or string.find(v.Name,"Coin")
or string.find(v.Name,"Orb")
or string.find(v.Name,"Shard")
or string.find(v.Name,"Prompt") then

box.Text = box.Text .. v:GetFullName() .. "\n"

end

end

end

end

box.Text = box.Text .. "\nScan finished"

end)

close.MouseButton1Click:Connect(function()
gui:Destroy()
end)
