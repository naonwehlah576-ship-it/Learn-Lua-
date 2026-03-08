print("Phantom Scanner Loaded")

local player = game.Players.LocalPlayer
local gui = Instance.new("ScreenGui")
gui.Name = "PhantomScanner"
gui.Parent = game.CoreGui

local frame = Instance.new("Frame")
frame.Size = UDim2.new(0,350,0,250)
frame.Position = UDim2.new(0.5,-175,0.5,-125)
frame.BackgroundColor3 = Color3.fromRGB(25,25,25)
frame.Parent = gui

local title = Instance.new("TextLabel")
title.Size = UDim2.new(1,0,0,30)
title.Text = "Phantom Scanner"
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

local scanning = false

scan.MouseButton1Click:Connect(function()

    if scanning then return end
    scanning = true

    box.Text = "Scanning...\n"

    for _,v in pairs(workspace:GetDescendants()) do

        if string.find(v.Name,"Phantom")
        or string.find(v.Name,"Converter")
        or string.find(v.Name,"Prompt")
        or string.find(v.Name,"Submit") then

            box.Text = box.Text .. v:GetFullName() .. "\n"

        end

    end

    box.Text = box.Text .. "\nScan finished"
    scanning = false

end)

close.MouseButton1Click:Connect(function()

    gui:Destroy()

end)
