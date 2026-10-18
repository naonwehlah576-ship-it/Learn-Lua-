-- =========================================================================
-- 🎲 AUTO ROLL EGG DEALER (INSTANT NO-ANIMATION / REMOTE ONLY)
-- Path: C:\Users\Rzoi7\Documents\Roblox\TD\script_auto_roll_egg.lua
-- Remote: ReplicatedStorage.UIAction:FireServer("DealerRoll", tierId)
-- =========================================================================

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local HttpService = game:GetService("HttpService")
local CoreGui = game:GetService("CoreGui")
local LocalPlayer = Players.LocalPlayer

-- Modul Game
local UIAction = ReplicatedStorage:WaitForChild("UIAction")
local EggResult = ReplicatedStorage:WaitForChild("EggResult")
local EggData = require(ReplicatedStorage:WaitForChild("EggData"))
local ShopData = require(ReplicatedStorage:WaitForChild("ShopData"))

-- Ambil Coins Player
local PlayerStats = LocalPlayer:WaitForChild("PlayerStats", 10)
local Coins = PlayerStats and PlayerStats:WaitForChild("Coins", 10)

-- Konfigurasi
local CONFIG = {
    Enabled = false,
    SelectedTier = "Basic", -- "Basic" atau "Premium"
    Delay = 0.5,            -- Jeda antar roll (bisa diatur)
    StopIfFull = true,      -- Berhenti jika inventory penuh
}

-- Cari Tier mana yang harganya 10,000
local basicCost = EggData.DealerById["Basic"] and EggData.DealerById["Basic"].Cost or 10000
local premiumCost = EggData.DealerById["Premium"] and EggData.DealerById["Premium"].Cost or 50000

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

-- Riwayat Roll
local ROLL_LOGS = {}
local refreshLogUI = function() end
local updateRollCount = function() end

local totalRolled = 0
local rarityCount = {}

-- [[ LISTENER HASIL ROLL DARI SERVER ]] --
EggResult.OnClientEvent:Connect(function(action, status, tierId, rarity)
    if action == "dealer" then
        if status == "rolled" then
            totalRolled = totalRolled + 1
            rarityCount[rarity] = (rarityCount[rarity] or 0) + 1
            
            table.insert(ROLL_LOGS, 1, {
                time = os.date("%H:%M:%S"),
                tier = tierId,
                rarity = rarity or "Unknown",
            })
            if #ROLL_LOGS > 40 then table.remove(ROLL_LOGS) end
            
            refreshLogUI()
            updateRollCount()
            print(string.format("[AUTO ROLL] Berhasil roll %s Egg -> %s!", tierId, tostring(rarity)))
        elseif status == "poor" then
            print("[AUTO ROLL] Uang tidak cukup!")
            CONFIG.Enabled = false
        end
    end
end)

-- [[ LOOP UTAMA AUTO ROLL ]] --
local autoRollActive = true
task.spawn(function()
    while autoRollActive do
        if CONFIG.Enabled then
            local cost = (CONFIG.SelectedTier == "Premium") and premiumCost or basicCost
            local currentCoins = Coins and Coins.Value or 0
            
            -- 1. Cek Uang
            if currentCoins < cost then
                print("[AUTO ROLL] Koin habis! Menghentikan auto roll...")
                CONFIG.Enabled = false
            else
                -- 2. Cek Inventory
                local full, cur, max = isInventoryFull()
                if CONFIG.StopIfFull and full then
                    print(string.format("[AUTO ROLL] Inventory Penuh (%d/%d)! Menghentikan auto roll...", cur, max))
                    CONFIG.Enabled = false
                else
                    -- 3. Tembak Remote DealerRoll Langsung (Tanpa buka shop & Tanpa Animasi!)
                    UIAction:FireServer("DealerRoll", CONFIG.SelectedTier)
                end
            end
        end
        task.wait(CONFIG.Delay)
    end
end)

-- =========================================================================
-- 🖥️ MODERN CLEAN GUI AUTO ROLL
-- =========================================================================
local guiName = "AutoRollDealerGui"
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
Main.Size = UDim2.new(0, 260, 0, 310)
Main.Position = UDim2.new(0.04, 0, 0.35, 0)
Main.BackgroundColor3 = Color3.fromRGB(22, 22, 28)
Main.BorderSizePixel = 0
Main.Active = true
Main.Draggable = true
Main.Parent = ScreenGui

local MainCorner = Instance.new("UICorner")
MainCorner.CornerRadius = UDim.new(0, 10)
MainCorner.Parent = Main

local MainStroke = Instance.new("UIStroke")
MainStroke.Thickness = 1.5
MainStroke.Color = Color3.fromRGB(60, 60, 75)
MainStroke.Parent = Main

-- Title Bar
local TitleBar = Instance.new("Frame")
TitleBar.Size = UDim2.new(1, 0, 0, 32)
TitleBar.BackgroundColor3 = Color3.fromRGB(30, 30, 40)
TitleBar.BorderSizePixel = 0
TitleBar.Parent = Main
local TitleCorner = Instance.new("UICorner")
TitleCorner.CornerRadius = UDim.new(0, 10)
TitleCorner.Parent = TitleBar

local Title = Instance.new("TextLabel")
Title.Size = UDim2.new(0.8, 0, 1, 0)
Title.Position = UDim2.fromOffset(10, 0)
Title.BackgroundTransparency = 1
Title.Text = "🎲 AUTO ROLL DEALER"
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
    CONFIG.Enabled = false
    autoRollActive = false
    ScreenGui:Destroy()
end)

-- Tombol Toggle ON/OFF
local ToggleBtn = Instance.new("TextButton")
ToggleBtn.Size = UDim2.new(0.9, 0, 0, 32)
ToggleBtn.Position = UDim2.new(0.05, 0, 0, 40)
ToggleBtn.BackgroundColor3 = Color3.fromRGB(190, 45, 45)
ToggleBtn.Text = "AUTO ROLL: OFF"
ToggleBtn.TextColor3 = Color3.new(1, 1, 1)
ToggleBtn.Font = Enum.Font.GothamBold
ToggleBtn.TextSize = 13
ToggleBtn.Parent = Main
local ToggleCorner = Instance.new("UICorner")
ToggleCorner.CornerRadius = UDim.new(0, 6)
ToggleCorner.Parent = ToggleBtn

-- Tombol Ganti Tier (Basic 10K vs Premium)
local TierBtn = Instance.new("TextButton")
TierBtn.Size = UDim2.new(0.9, 0, 0, 26)
TierBtn.Position = UDim2.new(0.05, 0, 0, 78)
TierBtn.BackgroundColor3 = Color3.fromRGB(45, 120, 200)
TierBtn.Text = string.format("Tier: Basic ($%s)", tostring(basicCost):reverse():gsub("(%d%d%d)", "%1,"):reverse():gsub("^,", ""))
TierBtn.TextColor3 = Color3.new(1, 1, 1)
TierBtn.Font = Enum.Font.GothamMedium
TierBtn.TextSize = 11
TierBtn.Parent = Main
local TierCorner = Instance.new("UICorner")
TierCorner.CornerRadius = UDim.new(0, 6)
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

ToggleBtn.MouseButton1Click:Connect(function()
    CONFIG.Enabled = not CONFIG.Enabled
    if CONFIG.Enabled then
        ToggleBtn.BackgroundColor3 = Color3.fromRGB(45, 175, 75)
        ToggleBtn.Text = "AUTO ROLL: ON"
    else
        ToggleBtn.BackgroundColor3 = Color3.fromRGB(190, 45, 45)
        ToggleBtn.Text = "AUTO ROLL: OFF"
    end
end)

-- Status Info (Total Roll & Coins)
local StatusLbl = Instance.new("TextLabel")
StatusLbl.Size = UDim2.new(0.9, 0, 0, 20)
StatusLbl.Position = UDim2.new(0.05, 0, 0, 110)
StatusLbl.BackgroundTransparency = 1
StatusLbl.Font = Enum.Font.GothamMedium
StatusLbl.TextSize = 11
StatusLbl.TextColor3 = Color3.fromRGB(180, 200, 220)
StatusLbl.TextXAlignment = Enum.TextXAlignment.Left
StatusLbl.Text = "Total Roll: 0 | Koin: $" .. (Coins and tostring(Coins.Value) or "0")
StatusLbl.Parent = Main

updateRollCount = function()
    local cVal = Coins and Coins.Value or 0
    StatusLbl.Text = string.format("Total: %d | Koin: $%s", totalRolled, tostring(cVal):reverse():gsub("(%d%d%d)", "%1,"):reverse():gsub("^,", ""))
end
if Coins then Coins.Changed:Connect(updateRollCount) end

-- Box Hasil / Log Roll Terakhir
local LogContainer = Instance.new("ScrollingFrame")
LogContainer.Size = UDim2.new(0.9, 0, 0, 160)
LogContainer.Position = UDim2.new(0.05, 0, 0, 136)
LogContainer.BackgroundColor3 = Color3.fromRGB(15, 15, 20)
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
    for idx, item in ipairs(ROLL_LOGS) do
        local row = Instance.new("TextLabel")
        row.Size = UDim2.new(1, -8, 0, 18)
        row.Position = UDim2.fromOffset(4, 0)
        row.BackgroundTransparency = 1
        row.Font = Enum.Font.Code
        row.TextSize = 10
        row.TextXAlignment = Enum.TextXAlignment.Left
        
        -- Warna berdasarkan rarity
        local rCol = Color3.fromRGB(200, 200, 200)
        local r = item.rarity:lower()
        if r == "godly" or r == "divine" then
            rCol = Color3.fromRGB(255, 90, 210)
        elseif r == "secret" then
            rCol = Color3.fromRGB(255, 60, 60)
        elseif r == "mythic" then
            rCol = Color3.fromRGB(255, 215, 0)
        elseif r == "legendary" then
            rCol = Color3.fromRGB(255, 150, 50)
        elseif r == "epic" then
            rCol = Color3.fromRGB(180, 80, 255)
        elseif r == "rare" then
            rCol = Color3.fromRGB(70, 160, 255)
        elseif r == "uncommon" then
            rCol = Color3.fromRGB(80, 230, 90)
        end
        
        row.TextColor3 = rCol
        row.Text = string.format("[%s] %s -> %s", item.time, item.tier, item.rarity)
        row.LayoutOrder = idx
        row.Parent = LogContainer
    end
    LogContainer.CanvasSize = UDim2.new(0, 0, 0, #ROLL_LOGS * 21)
end

print("========================================")
print("✅ Auto Roll Egg Dealer Siap Digunakan!")
print("========================================")
