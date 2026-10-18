-- =========================================================================
-- 🏋️🎲 AUTO BENCH PRESS & CLEAN AUTO ROLL DEALER
-- Path: C:\Users\Rzoi7\Documents\Roblox\TD\script_auto_roll_egg.lua
-- =========================================================================

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local CollectionService = game:GetService("CollectionService")
local HttpService = game:GetService("HttpService")
local CoreGui = game:GetService("CoreGui")
local RunService = game:GetService("RunService")
local LocalPlayer = Players.LocalPlayer

-- Modul Game
local UIAction = ReplicatedStorage:WaitForChild("UIAction")
local EggResult = ReplicatedStorage:WaitForChild("EggResult")
local EggData = require(ReplicatedStorage:WaitForChild("EggData"))
local ShopData = require(ReplicatedStorage:WaitForChild("ShopData"))

-- Player Data
local PlayerStats = LocalPlayer:WaitForChild("PlayerStats", 10)
local Coins = PlayerStats and PlayerStats:WaitForChild("Coins", 10)

-- Konfigurasi Script
local CONFIG = {
    AutoRoll = false,
    AutoBench = false,
    HideGameShop = true,    -- Sembunyikan GUI shop bawaan game agar layar bersih
    AutoTpToPad = true,     -- Otomatis teleport ke ShopPad saat Auto Roll ON
    SelectedTier = "Basic", -- "Basic" (10K) atau "Premium" (50K)
    StopIfFull = true,
}

local basicCost = EggData.DealerById["Basic"] and EggData.DealerById["Basic"].Cost or 10000
local premiumCost = EggData.DealerById["Premium"] and EggData.DealerById["Premium"].Cost or 50000

-- Lokasi ShopPad Dealer di Map
local function getShopPad()
    local map = workspace:FindFirstChild("Map") and workspace.Map:FindFirstChild("EggShop")
    return map and map:FindFirstChild("ShopPad")
end

-- Cek apakah karakter sedang berdiri di ShopPad
local function isAtShopPad()
    local pad = getShopPad()
    local char = LocalPlayer.Character
    local root = char and char:FindFirstChild("HumanoidRootPart")
    if pad and root then
        local dist = (Vector3.new(root.Position.X - pad.Position.X, 0, root.Position.Z - pad.Position.Z)).Magnitude
        local yDiff = math.abs(root.Position.Y - pad.Position.Y)
        return (dist <= (pad:GetAttribute("Radius") or 2.9) + 1.5) and (yDiff < 6)
    end
    return false
end

-- Teleport ke ShopPad
local function tpToShopPad()
    local pad = getShopPad()
    local char = LocalPlayer.Character
    local root = char and char:FindFirstChild("HumanoidRootPart")
    if pad and root then
        root.CFrame = pad.CFrame * CFrame.new(0, 3, 0)
    end
end

-- Cek apakah inventory penuh
local function isInventoryFull()
    local count = 0
    for _, attr in ipairs({"Inventory", "HatchEggs"}) do
        local raw = LocalPlayer:GetAttribute(attr) or "[]"
        local ok, data = pcall(HttpService.JSONDecode, HttpService, raw)
        if ok and type(data) == "table" then
            count = count + #data
        end
    end
    local maxCap = ShopData.InventoryMax(LocalPlayer)
    return count >= maxCap, count, maxCap
end

-- Cari Bench Press milik kita
local function getMyBench()
    for _, bench in ipairs(CollectionService:GetTagged("BenchPress")) do
        if bench:IsA("Model") and bench:GetAttribute("OwnerId") == LocalPlayer.UserId then
            return bench
        end
    end
    local char = LocalPlayer.Character
    local root = char and char:FindFirstChild("HumanoidRootPart")
    if root then
        local closest = nil
        local minDist = math.huge
        for _, bench in ipairs(CollectionService:GetTagged("BenchPress")) do
            if bench:IsA("Model") and not bench:GetAttribute("User") then
                local dist = (bench:GetPivot().Position - root.Position).Magnitude
                if dist < minDist then
                    minDist = dist
                    closest = bench
                end
            end
        end
        return closest
    end
    return nil
end

-- Cek apakah karakter sedang di bench
local function isSittingOnBench()
    for _, bench in ipairs(CollectionService:GetTagged("BenchPress")) do
        if bench:GetAttribute("User") == LocalPlayer.UserId then
            return true, bench
        end
    end
    return false, nil
end

-- Riwayat & Statistik
local LOGS = {}
local refreshLogUI = function() end
local updateStatsUI = function() end
local totalRolled = 0
local isRolling = false
local lastRollTime = 0
local ROLL_COOLDOWN = 3.2

-- [[ 1. AUTO HIDE DEFAULT GAME SHOP GUI ]] --
local function setupGuiHider()
    task.spawn(function()
        while true do
            task.wait(0.2)
            if CONFIG.HideGameShop then
                local pGui = LocalPlayer:FindFirstChild("PlayerGui")
                local shopGui = pGui and pGui:FindFirstChild("EggShopUI")
                if shopGui and shopGui.Enabled then
                    shopGui.Enabled = false
                    local eggBar = pGui:FindFirstChild("EggBar")
                    if eggBar and not eggBar.Enabled then
                        eggBar.Enabled = true
                    end
                end
            end
        end
    end)
end
setupGuiHider()

-- [[ 2. LISTENER EGG RESULT & BENCH RESULT DARI SERVER ]] --
EggResult.OnClientEvent:Connect(function(action, status, p3, p4)
    if action == "dealer" then
        if status == "rolled" then
            isRolling = false
            lastRollTime = os.clock()
            totalRolled = totalRolled + 1
            table.insert(LOGS, 1, {
                time = os.date("%H:%M:%S"),
                tag = "ROLL",
                text = string.format("%s -> %s", tostring(p3), tostring(p4)),
                color = Color3.fromRGB(100, 255, 120),
            })
        elseif status == "busy" then
            task.delay(1.0, function()
                isRolling = false
            end)
        elseif status == "poor" then
            isRolling = false
            table.insert(LOGS, 1, {
                time = os.date("%H:%M:%S"),
                tag = "ROLL",
                text = "Koin habis! Auto Roll dimatikan.",
                color = Color3.fromRGB(255, 100, 100),
            })
            CONFIG.AutoRoll = false
        else
            isRolling = false
            table.insert(LOGS, 1, {
                time = os.date("%H:%M:%S"),
                tag = "SERVER",
                text = string.format("Dealer: %s (%s)", tostring(status), tostring(p3)),
                color = Color3.fromRGB(240, 200, 80),
            })
        end
    end
    if #LOGS > 35 then table.remove(LOGS) end
    refreshLogUI()
    updateStatsUI()
end)

-- [[ 3. LOOP AUTO BENCH PRESS ]] --
local scriptRunning = true
task.spawn(function()
    while scriptRunning do
        if CONFIG.AutoBench then
            local sitting, curBench = isSittingOnBench()
            if not sitting then
                local bench = getMyBench()
                if bench then
                    local prompt = bench:FindFirstChildWhichIsA("ProximityPrompt", true)
                    local char = LocalPlayer.Character
                    local root = char and char:FindFirstChild("HumanoidRootPart")
                    if prompt and root then
                        local basePos = bench:GetAttribute("Base") or bench:GetPivot()
                        root.CFrame = basePos * CFrame.new(0, 1.5, 0)
                        task.wait(0.08)
                        if prompt.Enabled and typeof(fireproximityprompt) == "function" then
                            fireproximityprompt(prompt)
                        end
                    end
                end
            end
        end
        task.wait(0.5)
    end
end)

-- [[ 4. LOOP AUTO ROLL DEALER (STAND ON SHOPPAD & HIDE GAME GUI) ]] --
task.spawn(function()
    while scriptRunning do
        if CONFIG.AutoRoll and not isRolling then
            -- Pastikan karakter berada di ShopPad Dealer
            if not isAtShopPad() then
                if CONFIG.AutoTpToPad then
                    tpToShopPad()
                    task.wait(0.3)
                end
            end
            
            local now = os.clock()
            if (now - lastRollTime) >= ROLL_COOLDOWN then
                local cost = (CONFIG.SelectedTier == "Premium") and premiumCost or basicCost
                local currentCoins = Coins and Coins.Value or 0
                
                if currentCoins < cost then
                    CONFIG.AutoRoll = false
                    table.insert(LOGS, 1, {
                        time = os.date("%H:%M:%S"),
                        tag = "ROLL",
                        text = "Koin kurang! Auto Roll stop.",
                        color = Color3.fromRGB(255, 100, 100),
                    })
                    if #LOGS > 35 then table.remove(LOGS) end
                    refreshLogUI()
                else
                    local full, cur, max = isInventoryFull()
                    if CONFIG.StopIfFull and full then
                        table.insert(LOGS, 1, {
                            time = os.date("%H:%M:%S"),
                            tag = "ROLL",
                            text = string.format("Inventory Full (%d/%d)!", cur, max),
                            color = Color3.fromRGB(255, 140, 40),
                        })
                        if #LOGS > 35 then table.remove(LOGS) end
                        refreshLogUI()
                        CONFIG.AutoRoll = false
                    else
                        isRolling = true
                        lastRollTime = now
                        UIAction:FireServer("DealerRoll", CONFIG.SelectedTier)
                        
                        -- Safety Watchdog jika koneksi lag
                        task.delay(4.5, function()
                            if isRolling and (os.clock() - lastRollTime >= 4.0) then
                                isRolling = false
                            end
                        end)
                    end
                end
            end
        end
        task.wait(0.2)
    end
end)

-- =========================================================================
-- 🖥️ GUI CLEAN CONTROL
-- =========================================================================
local guiName = "DualBenchRollGui"
pcall(function()
    local old = CoreGui:FindFirstChild(guiName) or LocalPlayer.PlayerGui:FindFirstChild(guiName)
    if old then old:Destroy() end
end)

local ScreenGui = Instance.new("ScreenGui")
ScreenGui.Name = guiName
ScreenGui.ResetOnSpawn = false
pcall(function() ScreenGui.Parent = CoreGui end)
if not ScreenGui.Parent then ScreenGui.Parent = LocalPlayer:WaitForChild("PlayerGui") end

local Main = Instance.new("Frame")
Main.Size = UDim2.new(0, 275, 0, 395)
Main.Position = UDim2.new(0.03, 0, 0.28, 0)
Main.BackgroundColor3 = Color3.fromRGB(20, 20, 26)
Main.BorderSizePixel = 0
Main.Active = true
Main.Draggable = true
Main.Parent = ScreenGui

local MainCorner = Instance.new("UICorner")
MainCorner.CornerRadius = UDim.new(0, 10)
MainCorner.Parent = Main

local MainStroke = Instance.new("UIStroke")
MainStroke.Thickness = 1.5
MainStroke.Color = Color3.fromRGB(55, 55, 70)
MainStroke.Parent = Main

-- Title Bar
local TitleBar = Instance.new("Frame")
TitleBar.Size = UDim2.new(1, 0, 0, 32)
TitleBar.BackgroundColor3 = Color3.fromRGB(28, 28, 38)
TitleBar.BorderSizePixel = 0
TitleBar.Parent = Main
local TitleCorner = Instance.new("UICorner")
TitleCorner.CornerRadius = UDim.new(0, 10)
TitleCorner.Parent = TitleBar

local Title = Instance.new("TextLabel")
Title.Size = UDim2.new(0.8, 0, 1, 0)
Title.Position = UDim2.fromOffset(10, 0)
Title.BackgroundTransparency = 1
Title.Text = "🏋️ BENCH & 🎲 CLEAN ROLL"
Title.TextColor3 = Color3.fromRGB(255, 215, 0)
Title.Font = Enum.Font.GothamBold
Title.TextSize = 12
Title.TextXAlignment = Enum.TextXAlignment.Left
Title.Parent = TitleBar

local CloseBtn = Instance.new("TextButton")
CloseBtn.Size = UDim2.fromOffset(22, 22)
CloseBtn.Position = UDim2.new(1, -26, 0.5, -11)
CloseBtn.BackgroundColor3 = Color3.fromRGB(210, 50, 50)
CloseBtn.Text = "X"
CloseBtn.TextColor3 = Color3.new(1, 1, 1)
CloseBtn.Font = Enum.Font.GothamBold
CloseBtn.TextSize = 11
CloseBtn.Parent = TitleBar
local CloseCorner = Instance.new("UICorner")
CloseCorner.CornerRadius = UDim.new(0, 4)
CloseCorner.Parent = CloseBtn
CloseBtn.MouseButton1Click:Connect(function()
    CONFIG.AutoRoll = false
    CONFIG.AutoBench = false
    scriptRunning = false
    ScreenGui:Destroy()
end)

-- 1. Tombol Auto Roll Dealer
local RollBtn = Instance.new("TextButton")
RollBtn.Size = UDim2.new(0.92, 0, 0, 30)
RollBtn.Position = UDim2.new(0.04, 0, 0, 38)
RollBtn.BackgroundColor3 = Color3.fromRGB(180, 45, 45)
RollBtn.Text = "🎲 AUTO ROLL DEALER: OFF"
RollBtn.TextColor3 = Color3.new(1, 1, 1)
RollBtn.Font = Enum.Font.GothamBold
RollBtn.TextSize = 11
RollBtn.Parent = Main
local RollCorner = Instance.new("UICorner")
RollCorner.CornerRadius = UDim.new(0, 6)
RollCorner.Parent = RollBtn

-- 2. Tombol Auto Bench Press
local BenchBtn = Instance.new("TextButton")
BenchBtn.Size = UDim2.new(0.92, 0, 0, 30)
BenchBtn.Position = UDim2.new(0.04, 0, 0, 72)
BenchBtn.BackgroundColor3 = Color3.fromRGB(180, 45, 45)
BenchBtn.Text = "🏋️ AUTO BENCH PRESS: OFF"
BenchBtn.TextColor3 = Color3.new(1, 1, 1)
BenchBtn.Font = Enum.Font.GothamBold
BenchBtn.TextSize = 11
BenchBtn.Parent = Main
local BenchCorner = Instance.new("UICorner")
BenchCorner.CornerRadius = UDim.new(0, 6)
BenchCorner.Parent = BenchBtn

RollBtn.MouseButton1Click:Connect(function()
    CONFIG.AutoRoll = not CONFIG.AutoRoll
    if CONFIG.AutoRoll then
        -- Jika Bench sedang aktif, matikan bench dan lepas dari bench
        if CONFIG.AutoBench then
            CONFIG.AutoBench = false
            BenchBtn.BackgroundColor3 = Color3.fromRGB(180, 45, 45)
            BenchBtn.Text = "🏋️ AUTO BENCH PRESS: OFF"
            UIAction:FireServer("Bench", "Leave")
        end
        RollBtn.BackgroundColor3 = Color3.fromRGB(45, 175, 75)
        RollBtn.Text = "🎲 AUTO ROLL DEALER: ON"
        tpToShopPad()
    else
        RollBtn.BackgroundColor3 = Color3.fromRGB(180, 45, 45)
        RollBtn.Text = "🎲 AUTO ROLL DEALER: OFF"
    end
end)

BenchBtn.MouseButton1Click:Connect(function()
    CONFIG.AutoBench = not CONFIG.AutoBench
    if CONFIG.AutoBench then
        -- Jika AutoRoll sedang aktif, matikan roll
        if CONFIG.AutoRoll then
            CONFIG.AutoRoll = false
            RollBtn.BackgroundColor3 = Color3.fromRGB(180, 45, 45)
            RollBtn.Text = "🎲 AUTO ROLL DEALER: OFF"
        end
        BenchBtn.BackgroundColor3 = Color3.fromRGB(45, 175, 75)
        BenchBtn.Text = "🏋️ AUTO BENCH PRESS: ON"
    else
        BenchBtn.BackgroundColor3 = Color3.fromRGB(180, 45, 45)
        BenchBtn.Text = "🏋️ AUTO BENCH PRESS: OFF"
        UIAction:FireServer("Bench", "Leave")
    end
end)

-- 3. Tombol Ganti Tier Roll ($10K Basic vs Premium)
local TierBtn = Instance.new("TextButton")
TierBtn.Size = UDim2.new(0.44, 0, 0, 24)
TierBtn.Position = UDim2.new(0.04, 0, 0, 106)
TierBtn.BackgroundColor3 = Color3.fromRGB(45, 120, 200)
TierBtn.Text = string.format("Tier: Basic ($%s)", tostring(basicCost):reverse():gsub("(%d%d%d)", "%1,"):reverse():gsub("^,", ""))
TierBtn.TextColor3 = Color3.new(1, 1, 1)
TierBtn.Font = Enum.Font.GothamMedium
TierBtn.TextSize = 10
TierBtn.Parent = Main
local TierCorner = Instance.new("UICorner")
TierCorner.CornerRadius = UDim.new(0, 5)
TierCorner.Parent = TierBtn

TierBtn.MouseButton1Click:Connect(function()
    if CONFIG.SelectedTier == "Basic" then
        CONFIG.SelectedTier = "Premium"
        TierBtn.BackgroundColor3 = Color3.fromRGB(160, 60, 210)
        TierBtn.Text = string.format("Tier: Premium ($%s)", tostring(premiumCost):reverse():gsub("(%d%d%d)", "%1,"):reverse():gsub("^,", ""))
    else
        CONFIG.SelectedTier = "Basic"
        TierBtn.BackgroundColor3 = Color3.fromRGB(45, 120, 200)
        TierBtn.Text = string.format("Tier: Basic ($%s)", tostring(basicCost):reverse():gsub("(%d%d%d)", "%1,"):reverse():gsub("^,", ""))
    end
end)

-- 4. Tombol Toggle Sembunyikan GUI Bawaan (Hide Default Game Shop GUI)
local HideGuiBtn = Instance.new("TextButton")
HideGuiBtn.Size = UDim2.new(0.44, 0, 0, 24)
HideGuiBtn.Position = UDim2.new(0.52, 0, 0, 106)
HideGuiBtn.BackgroundColor3 = Color3.fromRGB(35, 135, 110)
HideGuiBtn.Text = "🛡️ Hide Shop GUI: ON"
HideGuiBtn.TextColor3 = Color3.new(1, 1, 1)
HideGuiBtn.Font = Enum.Font.GothamMedium
HideGuiBtn.TextSize = 10
HideGuiBtn.Parent = Main
local HideGuiCorner = Instance.new("UICorner")
HideGuiCorner.CornerRadius = UDim.new(0, 5)
HideGuiCorner.Parent = HideGuiBtn

HideGuiBtn.MouseButton1Click:Connect(function()
    CONFIG.HideGameShop = not CONFIG.HideGameShop
    if CONFIG.HideGameShop then
        HideGuiBtn.BackgroundColor3 = Color3.fromRGB(35, 135, 110)
        HideGuiBtn.Text = "🛡️ Hide Shop GUI: ON"
    else
        HideGuiBtn.BackgroundColor3 = Color3.fromRGB(130, 110, 35)
        HideGuiBtn.Text = "🛡️ Hide Shop GUI: OFF"
        local pGui = LocalPlayer:FindFirstChild("PlayerGui")
        local shopGui = pGui and pGui:FindFirstChild("EggShopUI")
        if shopGui and isAtShopPad() then
            shopGui.Enabled = true
        end
    end
end)

-- 5. Tombol Teleport Cepat (TP to ShopPad / TP to Bench)
local TpShopBtn = Instance.new("TextButton")
TpShopBtn.Size = UDim2.new(0.44, 0, 0, 22)
TpShopBtn.Position = UDim2.new(0.04, 0, 0, 134)
TpShopBtn.BackgroundColor3 = Color3.fromRGB(60, 60, 75)
TpShopBtn.Text = "📍 TP to Dealer"
TpShopBtn.TextColor3 = Color3.fromRGB(220, 220, 240)
TpShopBtn.Font = Enum.Font.GothamMedium
TpShopBtn.TextSize = 10
TpShopBtn.Parent = Main
local TpShopCorner = Instance.new("UICorner")
TpShopCorner.CornerRadius = UDim.new(0, 4)
TpShopCorner.Parent = TpShopBtn
TpShopBtn.MouseButton1Click:Connect(function()
    tpToShopPad()
end)

local TpBenchBtn = Instance.new("TextButton")
TpBenchBtn.Size = UDim2.new(0.44, 0, 0, 22)
TpBenchBtn.Position = UDim2.new(0.52, 0, 0, 134)
TpBenchBtn.BackgroundColor3 = Color3.fromRGB(60, 60, 75)
TpBenchBtn.Text = "📍 TP to My Bench"
TpBenchBtn.TextColor3 = Color3.fromRGB(220, 220, 240)
TpBenchBtn.Font = Enum.Font.GothamMedium
TpBenchBtn.TextSize = 10
TpBenchBtn.Parent = Main
local TpBenchCorner = Instance.new("UICorner")
TpBenchCorner.CornerRadius = UDim.new(0, 4)
TpBenchCorner.Parent = TpBenchBtn
TpBenchBtn.MouseButton1Click:Connect(function()
    local bench = getMyBench()
    local char = LocalPlayer.Character
    local root = char and char:FindFirstChild("HumanoidRootPart")
    if bench and root then
        root.CFrame = (bench:GetAttribute("Base") or bench:GetPivot()) * CFrame.new(0, 2.5, 0)
    end
end)

-- Status Info Bar
local StatusLbl = Instance.new("TextLabel")
StatusLbl.Size = UDim2.new(0.92, 0, 0, 18)
StatusLbl.Position = UDim2.new(0.04, 0, 0, 160)
StatusLbl.BackgroundTransparency = 1
StatusLbl.Font = Enum.Font.GothamMedium
StatusLbl.TextSize = 10
StatusLbl.TextColor3 = Color3.fromRGB(180, 200, 220)
StatusLbl.TextXAlignment = Enum.TextXAlignment.Left
StatusLbl.Text = "Rolled: 0 | Koin: $" .. (Coins and tostring(Coins.Value) or "0")
StatusLbl.Parent = Main

updateStatsUI = function()
    local cVal = Coins and Coins.Value or 0
    local isBench = isSittingOnBench()
    local atPad = isAtShopPad()
    local locStr = isBench and "BENCH" or (atPad and "DEALER PAD" or "MAP")
    StatusLbl.Text = string.format("Rolled: %d | Loc: %s | $%s", totalRolled, locStr, tostring(cVal):reverse():gsub("(%d%d%d)", "%1,"):reverse():gsub("^,", ""))
    
    if not CONFIG.AutoRoll and RollBtn.Text:find("ON") then
        RollBtn.BackgroundColor3 = Color3.fromRGB(180, 45, 45)
        RollBtn.Text = "🎲 AUTO ROLL DEALER: OFF"
    end
end
if Coins then Coins.Changed:Connect(updateStatsUI) end

-- Box Log
local LogContainer = Instance.new("ScrollingFrame")
LogContainer.Size = UDim2.new(0.92, 0, 0, 200)
LogContainer.Position = UDim2.new(0.04, 0, 0, 182)
LogContainer.BackgroundColor3 = Color3.fromRGB(14, 14, 18)
LogContainer.BorderSizePixel = 0
LogContainer.ScrollBarThickness = 3
LogContainer.Parent = Main
local LogCorner = Instance.new("UICorner")
LogCorner.CornerRadius = UDim.new(0, 6)
LogCorner.Parent = LogContainer

local LogLayout = Instance.new("UIListLayout")
LogLayout.SortOrder = Enum.SortOrder.LayoutOrder
LogLayout.Padding = UDim.new(0, 3)
LogLayout.Parent = LogContainer

refreshLogUI = function()
    for _, ch in ipairs(LogContainer:GetChildren()) do
        if ch:IsA("Frame") or ch:IsA("TextLabel") then ch:Destroy() end
    end
    for idx, item in ipairs(LOGS) do
        local row = Instance.new("TextLabel")
        row.Size = UDim2.new(1, -8, 0, 16)
        row.Position = UDim2.fromOffset(4, 0)
        row.BackgroundTransparency = 1
        row.Font = Enum.Font.Code
        row.TextSize = 9
        row.TextXAlignment = Enum.TextXAlignment.Left
        row.TextColor3 = item.color or Color3.fromRGB(200, 200, 200)
        row.Text = string.format("[%s] [%s] %s", item.time, item.tag, item.text)
        row.LayoutOrder = idx
        row.Parent = LogContainer
    end
    LogContainer.CanvasSize = UDim2.new(0, 0, 0, #LOGS * 19)
end

print("========================================")
print("✅ CLEAN AUTO ROLL & BENCH SCRIPT READY!")
print("========================================")
