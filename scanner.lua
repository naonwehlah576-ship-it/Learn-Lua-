print("Advanced Speed Scanner Loaded")

local player = game.Players.LocalPlayer

local gui = Instance.new("ScreenGui",game.CoreGui)
gui.Name = "AdvancedSpeedScanner"

local frame = Instance.new("Frame",gui)
frame.Size = UDim2.new(0,400,0,300)
frame.Position = UDim2.new(0.5,-200,0.5,-150)
frame.BackgroundColor3 = Color3.fromRGB(25,25,25)

local title = Instance.new("TextLabel",frame)
title.Size = UDim2.new(1,0,0,30)
title.Text = "Advanced Speed Scanner"
title.TextColor3 = Color3.new(1,1,1)
title.BackgroundColor3 = Color3.fromRGB(40,40,40)

local box = Instance.new("TextBox",frame)
box.Size = UDim2.new(1,-20,1,-80)
box.Position = UDim2.new(0,10,0,40)
box.BackgroundColor3 = Color3.fromRGB(20,20,20)
box.TextColor3 = Color3.new(1,1,1)
box.MultiLine = true
box.TextXAlignment = Enum.TextXAlignment.Left
box.TextYAlignment = Enum.TextYAlignment.Top
box.ClearTextOnFocus = false
box.Text = ""

local scan = Instance.new("TextButton",frame)
scan.Size = UDim2.new(0.45,0,0,30)
scan.Position = UDim2.new(0.05,0,1,-35)
scan.Text = "SCAN"
scan.BackgroundColor3 = Color3.fromRGB(60,120,60)

local close = Instance.new("TextButton",frame)
close.Size = UDim2.new(0.45,0,0,30)
close.Position = UDim2.new(0.5,0,1,-35)
close.Text = "CLOSE"
close.BackgroundColor3 = Color3.fromRGB(120,60,60)

scan.MouseButton1Click:Connect(function()

box.Text = "Scanning...\n"

for _,v in pairs(game:GetDescendants()) do

-- Number values
if v:IsA("IntValue") or v:IsA("NumberValue") then
if v.Value == 541 then
box.Text = box.Text .. "VALUE FOUND: "..v:GetFullName().." = "..v.Value.."\n"
end
end

-- Attributes
for _,attr in pairs(v:GetAttributes()) do
if attr == 541 then
box.Text = box.Text .. "ATTRIBUTE FOUND: "..v:GetFullName().."\n"
end
end

-- UI text
if v:IsA("TextLabel") or v:IsA("TextButton") then
if string.find(v.Text,"541") then
box.Text = box.Text .. "UI TEXT: "..v:GetFullName().." = "..v.Text.."\n"
end
end

end

box.Text = box.Text .. "\nScan finished"

end)

close.MouseButton1Click:Connect(function()
gui:Destroy()
end)
