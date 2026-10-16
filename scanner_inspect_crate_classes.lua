-- ============================================================================
-- 🔍 INSPECT CRATE, POLISHER & SELL CLASSES
-- Menampilkan hasil langsung di ScreenGui layar (agar di emulator tidak hilang)
-- ============================================================================

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local LocalPlayer = Players.LocalPlayer

local logs = {}
local function log(str)
    table.insert(logs, str)
    print(str)
end

log("=== INSPECT CRATE, POLISHER & SELL NPC ===")

-- 1. INSPECT CrateBasePart
pcall(function()
    local mod = ReplicatedStorage.Client.Core.Classes:FindFirstChild("CrateBasePart")
    if mod then
        log("\n📁 CrateBasePart:")
        if typeof(decompile) == "function" then
            local s, src = pcall(decompile, mod)
            if s and src then log(src) end
        else
            local s, req = pcall(require, mod)
            if s and type(req) == "table" then
                for k, v in pairs(req) do log(string.format("  • %s : %s", tostring(k), typeof(v))) end
            end
        end
    end
end)

-- 2. INSPECT PolisherCollectPart & PolisherService
pcall(function()
    local mod = ReplicatedStorage.Client.Core.Classes:FindFirstChild("PolisherCollectPart")
    if mod then
        log("\n📁 PolisherCollectPart:")
        if typeof(decompile) == "function" then
            local s, src = pcall(decompile, mod)
            if s and src then log(src) end
        end
    end
end)

pcall(function()
    local mod = ReplicatedStorage.Shared.Services:FindFirstChild("PolisherService")
    if mod then
        log("\n📁 PolisherService:")
        if typeof(decompile) == "function" then
            local s, src = pcall(decompile, mod)
            if s and src then log(src) end
        end
    end
end)

-- 3. INSPECT SellNPC
pcall(function()
    local mod = ReplicatedStorage.Client.Core.Classes:FindFirstChild("SellNPC")
    if mod then
        log("\n📁 SellNPC:")
        if typeof(decompile) == "function" then
            local s, src = pcall(decompile, mod)
            if s and src then log(src) end
        end
    end
end)

local fullText = table.concat(logs, "\n")
if setclipboard then pcall(setclipboard, fullText) end
if toclipboard then pcall(toclipboard, fullText) end
if writefile then pcall(writefile, "crate_classes_dump.txt", fullText) end

-- BUAT SCREEN GUI DENGAN SCROLLING FRAME DI LAYAR AGAR BISA DIBACA & DISALIN LANGSUNG
pcall(function()
    local pGui = LocalPlayer:WaitForChild("PlayerGui")
    if pGui:FindFirstChild("InspectCrateGui") then pGui.InspectCrateGui:Destroy() end

    local sg = Instance.new("ScreenGui")
    sg.Name = "InspectCrateGui"
    sg.ResetOnSpawn = false
    sg.Parent = pGui

    local frame = Instance.new("Frame")
    frame.Size = UDim2.new(0.85, 0, 0.75, 0)
    frame.Position = UDim2.new(0.075, 0, 0.125, 0)
    frame.BackgroundColor3 = Color3.fromRGB(20, 24, 34)
    frame.BorderSizePixel = 2
    frame.Parent = sg

    local close = Instance.new("TextButton")
    close.Size = UDim2.new(0, 30, 0, 30)
    close.Position = UDim2.new(1, -35, 0, 5)
    close.Text = "X"
    close.BackgroundColor3 = Color3.fromRGB(200, 50, 50)
    close.TextColor3 = Color3.fromRGB(255, 255, 255)
    close.Parent = frame
    close.MouseButton1Click:Connect(function() sg:Destroy() end)

    local copyBtn = Instance.new("TextButton")
    copyBtn.Size = UDim2.new(0, 140, 0, 30)
    copyBtn.Position = UDim2.new(0, 10, 0, 5)
    copyBtn.Text = "Copy Full Text"
    copyBtn.BackgroundColor3 = Color3.fromRGB(50, 150, 220)
    copyBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
    copyBtn.Parent = frame
    copyBtn.MouseButton1Click:Connect(function()
        if setclipboard then setclipboard(fullText) end
        if toclipboard then toclipboard(fullText) end
        copyBtn.Text = "Copied!"
        task.delay(1, function() copyBtn.Text = "Copy Full Text" end)
    end)

    local tb = Instance.new("TextBox")
    tb.Size = UDim2.new(1, -20, 1, -45)
    tb.Position = UDim2.new(0, 10, 0, 40)
    tb.Text = fullText
    tb.TextColor3 = Color3.fromRGB(220, 220, 240)
    tb.BackgroundColor3 = Color3.fromRGB(30, 35, 50)
    tb.ClearTextOnFocus = false
    tb.TextXAlignment = Enum.TextXAlignment.Left
    tb.TextYAlignment = Enum.TextYAlignment.Top
    tb.TextSize = 11
    tb.Font = Enum.Font.Code
    tb.MultiLine = true
    tb.Parent = frame
end)
print("Inspect Crate Classes GUI Loaded!")
