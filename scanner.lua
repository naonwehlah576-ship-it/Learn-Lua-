print("SCANNER EXECUTED")

local parent
pcall(function()
    parent = gethui()
end)

if not parent then
    parent = game:GetService("CoreGui")
end

local gui = Instance.new("ScreenGui")
gui.Parent = parent

local frame = Instance.new("Frame")
frame.Size = UDim2.new(0,420,0,340)
frame.Position = UDim2.new(0.5,-210,0.5,-170)
frame.BackgroundColor3 = Color3.fromRGB(30,30,30)
frame.Parent = gui

local title = Instance.new("TextLabel")
title.Size = UDim2.new(1,0,0,35)
title.BackgroundColor3 = Color3.fromRGB(50,50,50)
title.TextColor3 = Color3.new(1,1,1)
title.Text = "GAME SCANNER"
title.Parent = frame

local status = Instance.new("TextLabel")
status.Size = UDim2.new(1,0,0,25)
status.Position = UDim2.new(0,0,0,35)
status.TextColor3 = Color3.new(1,1,0)
status.BackgroundTransparency = 1
status.Text = "STATUS: EXECUTED"
status.Parent = frame

local copy = Instance.new("TextButton")
copy.Size = UDim2.new(0,100,0,30)
copy.Position = UDim2.new(1,-110,0,35)
copy.Text = "COPY ALL"
copy.BackgroundColor3 = Color3.fromRGB(70,70,70)
copy.TextColor3 = Color3.new(1,1,1)
copy.Parent = frame

local box = Instance.new("TextBox")
box.Size = UDim2.new(1,-10,1,-75)
box.Position = UDim2.new(0,5,0,65)
box.MultiLine = true
box.TextXAlignment = Enum.TextXAlignment.Left
box.TextYAlignment = Enum.TextYAlignment.Top
box.ClearTextOnFocus = false
box.Text = ""
box.BackgroundColor3 = Color3.fromRGB(20,20,20)
box.TextColor3 = Color3.new(1,1,1)
box.Parent = frame

local function log(text)
    box.Text = box.Text .. "\n" .. text
end

copy.MouseButton1Click:Connect(function()
    if setclipboard then
        setclipboard(box.Text)
        status.Text = "STATUS: COPIED TO CLIPBOARD"
    else
        status.Text = "STATUS: CLIPBOARD NOT SUPPORTED"
    end
end)

task.wait(1)

status.Text = "STATUS: SCANNING WORKSPACE"

for _,v in pairs(workspace:GetDescendants()) do
    if v:IsA("Part") or v:IsA("Model") then
        log(v.Name)
    end
end

status.Text = "STATUS: SCANNING REPLICATED STORAGE"

local rs = game:GetService("ReplicatedStorage")

for _,v in pairs(rs:GetDescendants()) do
    if v:IsA("RemoteEvent") or v:IsA("RemoteFunction") then
        log("REMOTE: "..v.Name)
    end
end

status.Text = "STATUS: SCAN FINISHED"
print("SCAN FINISHED")
