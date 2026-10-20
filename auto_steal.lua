-- =========================================================================
-- 🥷🐾 AUTO STEAL PETS & BASE RUNNER
-- Path: C:\Users\Rzoi7\Documents\Roblox\TD\script_auto_steal.lua
-- =========================================================================

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local CollectionService = game:GetService("CollectionService")
local CoreGui = game:GetService("CoreGui")
local RunService = game:GetService("RunService")
local LocalPlayer = Players.LocalPlayer

-- Modul Game
local EggRewards = nil
pcall(function()
    EggRewards = require(ReplicatedStorage.Shared.EggRewards)
end)
local OwnBase = nil
pcall(function()
    local clientControllers = LocalPlayer:WaitForChild("PlayerScripts"):WaitForChild("Client"):WaitForChild("Controllers")
    OwnBase = require(clientControllers:WaitForChild("OwnBase"))
end)

-- Konfigurasi Default
local CONFIG = {
    AutoSteal = false,
    BasePos = Vector3.new(-59.5, 3.4, -4.9), -- Koordinat Slot 2 sesuai gambar
    MinCashPerSec = 0,                       -- Minimal $/s
    MinKg = 0,                               -- Minimal Kg
    SelectedRarities = {
        ["Common"] = false,
        ["Uncommon"] = false,
        ["Rare"] = true,
        ["Epic"] = true,
        ["Legendary"] = true,
        ["Mythic"] = true,
        ["Cosmic"] = true,
        ["Divine"] = true,
        ["Celestial"] = true,
        ["Void"] = true,
        ["Inferno"] = true,
        ["Secret"] = true,
        ["Unknown"] = true,
    }
}

-- Warna Rarity untuk UI
local RARITY_COLORS = {
    Common = Color3.fromRGB(190, 190, 190),
    Uncommon = Color3.fromRGB(88, 214, 96),
    Rare = Color3.fromRGB(79, 168, 255),
    Epic = Color3.fromRGB(138, 112, 255),
    Legendary = Color3.fromRGB(255, 170, 40),
    Mythic = Color3.fromRGB(255, 80, 80),
    Cosmic = Color3.fromRGB(255, 90, 245),
    Divine = Color3.fromRGB(120, 235, 235),
    Celestial = Color3.fromRGB(255, 223, 110),
    Void = Color3.fromRGB(150, 70, 255),
    Inferno = Color3.fromRGB(235, 30, 30),
    Secret = Color3.fromRGB(235, 235, 235),
    Unknown = Color3.fromRGB(160, 160, 170),
}

-- Parsing Text ObjectText ProximityPrompt
-- Contoh: '<font color="#8A70FF"><b>[58,092Kg]</b></font> Mantis'
local function parsePromptInfo(prompt)
    local raw = prompt.ObjectText or ""
    local clean = raw:gsub("<[^>]+>", "") -- Bersihkan tag HTML
    
    local weightStr, species = clean:match("%[?([%d,%.]+)%s*[Kk][Gg]%]%s*(.+)")
    if not species then
        species = clean:gsub("%[.-%]", ""):match("^%s*(.-)%s*$")
    end
    
    local weightKg = 0
    if weightStr then
        weightKg = tonumber((weightStr:gsub(",", ""))) or 0
    end
    species = species and species:match("^%s*(.-)%s*$") or "Unknown"
    
    -- Ambil warna hex jika ada
    local hexColor = raw:match('color="(#[%x]+)"') or raw:match("color='(#[%x]+)'")
    
    -- Tentukan Rarity
    local rarity = "Unknown"
    if EggRewards and typeof(EggRewards.RarityOf) == "function" then
        local ok, r = pcall(EggRewards.RarityOf, species)
        if ok and r and type(r) == "string" then
            rarity = r
        end
    end
    if rarity == "Unknown" and hexColor then
        local uHex = hexColor:upper()
        if uHex:find("8A70FF") then rarity = "Epic"
        elseif uHex:find("4FA8FF") then rarity = "Rare"
        elseif uHex:find("58D660") or uHex:find("58D6") then rarity = "Uncommon"
        elseif uHex:find("FFAA28") or uHex:find("FFAA") then rarity = "Legendary"
        elseif uHex:find("FF5050") or uHex:find("FF50") then rarity = "Mythic"
        elseif uHex:find("FF5AF5") or uHex:find("960784") then rarity = "Cosmic"
        elseif uHex:find("78EBEB") or uHex:find("470588") then rarity = "Divine"
        elseif uHex:find("FFDF6E") or uHex:find("E0") then rarity = "Celestial"
        elseif uHex:find("C8C8C8") then rarity = "Common"
        end
    end
    
    -- Hitung $/s (Cash Per Second)
    local cashPerSec = 0
    if EggRewards then
        if typeof(EggRewards.PlacedCashPerSecond) == "function" then
            local ok, val = pcall(EggRewards.PlacedCashPerSecond, species, weightKg)
            if ok and typeof(val) == "number" then cashPerSec = val end
        elseif typeof(EggRewards.CashPerSecond) == "function" then
            local ok, val = pcall(EggRewards.CashPerSecond, species, weightKg)
            if ok and typeof(val) == "number" then cashPerSec = val end
        end
    end
    if cashPerSec == 0 then
        cashPerSec = weightKg -- fallback
    end
    
    return species, weightKg, rarity, cashPerSec
end

-- Cek apakah prompt ada di base sendiri (jangan curi punya sendiri)
local function isInsideMyBase(prompt)
    if OwnBase and typeof(OwnBase.Get) == "function" then
        local myPlot = OwnBase.Get()
        if myPlot and prompt:IsDescendantOf(myPlot) then
            return true
        end
    end
    local part = prompt.Parent:IsA("BasePart") and prompt.Parent or prompt.Parent:FindFirstChildWhichIsA("BasePart")
    if part and CONFIG.BasePos then
        if (part.Position - CONFIG.BasePos).Magnitude < 35 then
            return true
        end
    end
    return false
end

-- Cari semua StealPrompt yang valid & memenuhi filter
local function getValidStealTargets()
    local valid = {}
    local char = LocalPlayer.Character
    local root = char and char:FindFirstChild("HumanoidRootPart")
    if not root then return valid end
    
    for _, prompt in ipairs(workspace:GetDescendants()) do
        if prompt:IsA("ProximityPrompt") and prompt.Name == "StealPrompt" and prompt.Enabled then
            if not isInsideMyBase(prompt) then
                local species, weightKg, rarity, cashPerSec = parsePromptInfo(prompt)
                
                -- Cek Filter Rarity
                local rarityAllowed = CONFIG.SelectedRarities[rarity] == true or CONFIG.SelectedRarities["Unknown"] == true
                
                -- Cek Filter $/s dan Kg
                local cashAllowed = cashPerSec >= CONFIG.MinCashPerSec
                local kgAllowed = weightKg >= CONFIG.MinKg
                
                if rarityAllowed and cashAllowed and kgAllowed then
                    local targetPart = prompt.Parent:IsA("BasePart") and prompt.Parent or prompt.Parent:FindFirstChildWhichIsA("BasePart")
                    if targetPart then
                        local dist = (targetPart.Position - root.Position).Magnitude
                        table.insert(valid, {
                            prompt = prompt,
                            part = targetPart,
                            species = species,
                            weightKg = weightKg,
                            rarity = rarity,
                            cashPerSec = cashPerSec,
                            dist = dist,
                        })
                    end
                end
            end
        end
    end
    
    -- Urutkan berdasarkan Cash Per Second tertinggi, lalu terdekat
    table.sort(valid, function(a, b)
        if math.abs(a.cashPerSec - b.cashPerSec) > 10 then
            return a.cashPerSec > b.cashPerSec
        end
        return a.dist < b.dist
    end)
    
    return valid
end

-- Cek apakah karakter sedang membawa curian
local function isCarrying()
    local cAttr = LocalPlayer:GetAttribute("Carrying")
    local cCount = LocalPlayer:GetAttribute("CarryCount") or 0
    return (cAttr ~= nil) or (cCount > 0)
end

-- Jalan Natural Menyesuaikan Speed Game
local function naturalWalkTo(targetPos, maxWait, stopDist)
    maxWait = maxWait or 25
    stopDist = stopDist or 5
    local char = LocalPlayer.Character
    local hum = char and char:FindFirstChildOfClass("Humanoid")
    local root = char and char:FindFirstChild("HumanoidRootPart")
    if not (hum and root) then return false end
    
    local startTime = os.clock()
    local lastPos = root.Position
    local lastMoved = os.clock()
    
    while CONFIG.AutoSteal do
        char = LocalPlayer.Character
        hum = char and char:FindFirstChildOfClass("Humanoid")
        root = char and char:FindFirstChild("HumanoidRootPart")
        if not (hum and root) then return false end
        
        local d = (Vector3.new(root.Position.X, 0, root.Position.Z) - Vector3.new(targetPos.X, 0, targetPos.Z)).Magnitude
        if d <= stopDist then
            return true
        end
        
        if os.clock() - startTime > maxWait then
            return false
        end
        
        -- Anti-Stuck: lompat jika tidak bergerak 1 detik
        if (root.Position - lastPos).Magnitude > 0.8 then
            lastPos = root.Position
            lastMoved = os.clock()
        elseif os.clock() - lastMoved > 1.2 then
            hum.Jump = true
            lastMoved = os.clock()
        end
        
        hum:MoveTo(targetPos)
        task.wait(0.1)
    end
    return false
end

-- Riwayat & Stats UI
local LOGS = {}
local refreshLogUI = function() end
local updateStatsUI = function() end
local totalStolen = 0
local scriptRunning = true

local function addLog(tag, text, color)
    table.insert(LOGS, 1, {
        time = os.date("%H:%M:%S"),
        tag = tag,
        text = text,
        color = color or Color3.fromRGB(220, 220, 220)
    })
    if #LOGS > 35 then table.remove(LOGS) end
    refreshLogUI()
end

-- [[ AUTO STEAL MAIN LOOP ]] --
task.spawn(function()
    while scriptRunning do
        if CONFIG.AutoSteal then
            -- 1. Jika sedang membawa curian, langsung jalan pulang ke Base
            if isCarrying() then
                addLog("RUN", "Membawa curian! Berlari pulang ke Base...", Color3.fromRGB(255, 215, 80))
                local reached = naturalWalkTo(CONFIG.BasePos, 30, 4)
                if reached then
                    addLog("BANK", "Sampai di Base! Menunggu banking...", Color3.fromRGB(100, 255, 120))
                    -- Tunggu sampai banking selesai
                    local bankTimeout = os.clock() + 5
                    while isCarrying() and os.clock() < bankTimeout and CONFIG.AutoSteal do
                        task.wait(0.2)
                    end
                    totalStolen = totalStolen + 1
                    updateStatsUI()
                end
            else
                -- 2. Cari target terbaik
                local targets = getValidStealTargets()
                if #targets > 0 then
                    local best = targets[1]
                    local cashStr = tostring(math.floor(best.cashPerSec)):reverse():gsub("(%d%d%d)", "%1,"):reverse():gsub("^,", "")
                    addLog("TARGET", string.format("[%s] %s (%dKg | $%s/s)", best.rarity, best.species, math.floor(best.weightKg), cashStr), RARITY_COLORS[best.rarity] or Color3.fromRGB(255, 255, 255))
                    
                    -- Jalan ke target
                    local targetPos = best.part.Position
                    local reached = naturalWalkTo(targetPos, 25, (best.prompt.MaxActivationDistance or 6) - 1.5)
                    
                    if reached and CONFIG.AutoSteal and not isCarrying() then
                        -- Eksekusi ProximityPrompt [E]
                        if best.prompt and best.prompt.Parent and best.prompt.Enabled then
                            addLog("STEAL", "Mencuri: " .. best.species .. "...", Color3.fromRGB(255, 180, 50))
                            if typeof(fireproximityprompt) == "function" then
                                fireproximityprompt(best.prompt)
                                task.wait((best.prompt.HoldDuration or 0) + 0.2)
                            end
                        end
                        
                        -- Cek apakah berhasil dibawa
                        if isCarrying() then
                            addLog("SUCCESS", "Berhasil mencuri! Kembali ke Base...", Color3.fromRGB(100, 255, 100))
                            naturalWalkTo(CONFIG.BasePos, 30, 4)
                            task.wait(0.5)
                            totalStolen = totalStolen + 1
                            updateStatsUI()
                        end
                    end
                else
                    -- Tidak ada target yang sesuai filter
                    task.wait(1.5)
                end
            end
        end
        task.wait(0.3)
    end
end)

-- =========================================================================
-- 🖥️ GUI AUTO STEAL & RARITY MULTI-SELECT
-- =========================================================================
local guiName = "AutoStealGui"
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
Main.Size = UDim2.new(0, 290, 0, 470)
Main.Position = UDim2.new(0.03, 0, 0.22, 0)
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
Title.Text = "🥷 AUTO STEAL PETS (BASE RUNNER)"
Title.TextColor3 = Color3.fromRGB(255, 215, 0)
Title.Font = Enum.Font.GothamBold
Title.TextSize = 11
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
    CONFIG.AutoSteal = false
    scriptRunning = false
    ScreenGui:Destroy()
end)

-- 1. Tombol Utama: AUTO STEAL
local StealBtn = Instance.new("TextButton")
StealBtn.Size = UDim2.new(0.92, 0, 0, 32)
StealBtn.Position = UDim2.new(0.04, 0, 0, 38)
StealBtn.BackgroundColor3 = Color3.fromRGB(180, 45, 45)
StealBtn.Text = "🥷 AUTO STEAL: OFF"
StealBtn.TextColor3 = Color3.new(1, 1, 1)
StealBtn.Font = Enum.Font.GothamBold
StealBtn.TextSize = 12
StealBtn.Parent = Main
local StealCorner = Instance.new("UICorner")
StealCorner.CornerRadius = UDim.new(0, 6)
StealCorner.Parent = StealBtn

StealBtn.MouseButton1Click:Connect(function()
    CONFIG.AutoSteal = not CONFIG.AutoSteal
    if CONFIG.AutoSteal then
        StealBtn.BackgroundColor3 = Color3.fromRGB(45, 175, 75)
        StealBtn.Text = "🥷 AUTO STEAL: ON"
        addLog("SYSTEM", "Auto Steal diaktifkan!", Color3.fromRGB(100, 255, 120))
    else
        StealBtn.BackgroundColor3 = Color3.fromRGB(180, 45, 45)
        StealBtn.Text = "🥷 AUTO STEAL: OFF"
        addLog("SYSTEM", "Auto Steal dimatikan.", Color3.fromRGB(255, 100, 100))
    end
end)

-- 2. Input Base Position & Tombol Set
local BaseFrame = Instance.new("Frame")
BaseFrame.Size = UDim2.new(0.92, 0, 0, 24)
BaseFrame.Position = UDim2.new(0.04, 0, 0, 74)
BaseFrame.BackgroundTransparency = 1
BaseFrame.Parent = Main

local BaseLbl = Instance.new("TextLabel")
BaseLbl.Size = UDim2.new(0.65, 0, 1, 0)
BaseLbl.BackgroundTransparency = 1
BaseLbl.Font = Enum.Font.GothamMedium
BaseLbl.TextSize = 10
BaseLbl.TextColor3 = Color3.fromRGB(190, 210, 230)
BaseLbl.TextXAlignment = Enum.TextXAlignment.Left
BaseLbl.Text = string.format("Base: %.1f, %.1f, %.1f", CONFIG.BasePos.X, CONFIG.BasePos.Y, CONFIG.BasePos.Z)
BaseLbl.Parent = BaseFrame

local SetBaseBtn = Instance.new("TextButton")
SetBaseBtn.Size = UDim2.new(0.33, 0, 1, 0)
SetBaseBtn.Position = UDim2.new(0.67, 0, 0, 0)
SetBaseBtn.BackgroundColor3 = Color3.fromRGB(50, 110, 180)
SetBaseBtn.Text = "📍 Set Pos"
SetBaseBtn.TextColor3 = Color3.new(1, 1, 1)
SetBaseBtn.Font = Enum.Font.GothamMedium
SetBaseBtn.TextSize = 9
SetBaseBtn.Parent = BaseFrame
local SetBaseCorner = Instance.new("UICorner")
SetBaseCorner.CornerRadius = UDim.new(0, 4)
SetBaseCorner.Parent = SetBaseBtn

SetBaseBtn.MouseButton1Click:Connect(function()
    local char = LocalPlayer.Character
    local root = char and char:FindFirstChild("HumanoidRootPart")
    if root then
        CONFIG.BasePos = root.Position
        BaseLbl.Text = string.format("Base: %.1f, %.1f, %.1f", CONFIG.BasePos.X, CONFIG.BasePos.Y, CONFIG.BasePos.Z)
        addLog("BASE", string.format("Base Pos diupdate ke: %.1f, %.1f, %.1f", CONFIG.BasePos.X, CONFIG.BasePos.Y, CONFIG.BasePos.Z), Color3.fromRGB(120, 200, 255))
    end
end)

-- 3. Filter Minimal $/s (Textbox)
local CashFrame = Instance.new("Frame")
CashFrame.Size = UDim2.new(0.92, 0, 0, 24)
CashFrame.Position = UDim2.new(0.04, 0, 0, 102)
CashFrame.BackgroundTransparency = 1
CashFrame.Parent = Main

local CashLbl = Instance.new("TextLabel")
CashLbl.Size = UDim2.new(0.5, 0, 1, 0)
CashLbl.BackgroundTransparency = 1
CashLbl.Font = Enum.Font.GothamMedium
CashLbl.TextSize = 10
CashLbl.TextColor3 = Color3.fromRGB(180, 200, 220)
CashLbl.TextXAlignment = Enum.TextXAlignment.Left
CashLbl.Text = "Steal Above $/s:"
CashLbl.Parent = CashFrame

local CashBox = Instance.new("TextBox")
CashBox.Size = UDim2.new(0.48, 0, 1, 0)
CashBox.Position = UDim2.new(0.52, 0, 0, 0)
CashBox.BackgroundColor3 = Color3.fromRGB(30, 32, 42)
CashBox.TextColor3 = Color3.fromRGB(100, 255, 120)
CashBox.Font = Enum.Font.GothamBold
CashBox.TextSize = 10
CashBox.Text = "0"
CashBox.ClearTextOnFocus = false
CashBox.Parent = CashFrame
local CashBoxCorner = Instance.new("UICorner")
CashBoxCorner.CornerRadius = UDim.new(0, 4)
CashBoxCorner.Parent = CashBox

CashBox.FocusLost:Connect(function()
    local clean = CashBox.Text:lower():gsub("%$", ""):gsub(",", "")
    local mult = 1
    if clean:find("k") then mult = 1000 clean = clean:gsub("k", "")
    elseif clean:find("m") then mult = 1000000 clean = clean:gsub("m", "")
    elseif clean:find("b") then mult = 1000000000 clean = clean:gsub("b", "")
    end
    local val = tonumber(clean)
    if val then
        CONFIG.MinCashPerSec = val * mult
        addLog("FILTER", string.format("Min $/s diset: $%s", tostring(CONFIG.MinCashPerSec):reverse():gsub("(%d%d%d)", "%1,"):reverse():gsub("^,", "")), Color3.fromRGB(240, 200, 80))
    else
        CashBox.Text = tostring(CONFIG.MinCashPerSec)
    end
end)

-- 4. Rarity Multi-Select Container
local RarityTitle = Instance.new("TextLabel")
RarityTitle.Size = UDim2.new(0.92, 0, 0, 16)
RarityTitle.Position = UDim2.new(0.04, 0, 0, 130)
RarityTitle.BackgroundTransparency = 1
RarityTitle.Font = Enum.Font.GothamBold
RarityTitle.TextSize = 10
RarityTitle.TextColor3 = Color3.fromRGB(240, 210, 100)
RarityTitle.TextXAlignment = Enum.TextXAlignment.Left
RarityTitle.Text = "Target Rarity (Klik untuk Pilih/Batal):"
RarityTitle.Parent = Main

local RarityScroll = Instance.new("ScrollingFrame")
RarityScroll.Size = UDim2.new(0.92, 0, 0, 95)
RarityScroll.Position = UDim2.new(0.04, 0, 0, 148)
RarityScroll.BackgroundColor3 = Color3.fromRGB(14, 14, 18)
RarityScroll.BorderSizePixel = 0
RarityScroll.ScrollBarThickness = 3
RarityScroll.Parent = Main
local RarityScrollCorner = Instance.new("UICorner")
RarityScrollCorner.CornerRadius = UDim.new(0, 6)
RarityScrollCorner.Parent = RarityScroll

local RarityGrid = Instance.new("UIGridLayout")
RarityGrid.CellSize = UDim2.new(0, 80, 0, 22)
RarityGrid.CellPadding = UDim2.new(0, 4, 0, 4)
RarityGrid.Parent = RarityScroll

local rarityOrder = {"Rare", "Epic", "Legendary", "Mythic", "Cosmic", "Divine", "Celestial", "Void", "Inferno", "Secret", "Uncommon", "Common"}

for _, rName in ipairs(rarityOrder) do
    local rBtn = Instance.new("TextButton")
    rBtn.Name = rName
    local active = CONFIG.SelectedRarities[rName] == true
    rBtn.BackgroundColor3 = active and (RARITY_COLORS[rName] or Color3.fromRGB(80, 80, 90)) or Color3.fromRGB(40, 40, 48)
    rBtn.Text = (active and "✓ " or "") .. rName
    rBtn.TextColor3 = active and Color3.new(0, 0, 0) or (RARITY_COLORS[rName] or Color3.fromRGB(180, 180, 180))
    rBtn.Font = Enum.Font.GothamBold
    rBtn.TextSize = 9
    rBtn.Parent = RarityScroll
    local rCorner = Instance.new("UICorner")
    rCorner.CornerRadius = UDim.new(0, 4)
    rCorner.Parent = rBtn
    
    rBtn.MouseButton1Click:Connect(function()
        CONFIG.SelectedRarities[rName] = not CONFIG.SelectedRarities[rName]
        local nowActive = CONFIG.SelectedRarities[rName]
        rBtn.BackgroundColor3 = nowActive and (RARITY_COLORS[rName] or Color3.fromRGB(80, 80, 90)) or Color3.fromRGB(40, 40, 48)
        rBtn.Text = (nowActive and "✓ " or "") .. rName
        rBtn.TextColor3 = nowActive and Color3.new(0, 0, 0) or (RARITY_COLORS[rName] or Color3.fromRGB(180, 180, 180))
    end)
end
RarityScroll.CanvasSize = UDim2.new(0, 0, 0, math.ceil(#rarityOrder / 3) * 27)

-- Status Bar
local StatusLbl = Instance.new("TextLabel")
StatusLbl.Size = UDim2.new(0.92, 0, 0, 16)
StatusLbl.Position = UDim2.new(0.04, 0, 0, 248)
StatusLbl.BackgroundTransparency = 1
StatusLbl.Font = Enum.Font.GothamMedium
StatusLbl.TextSize = 10
StatusLbl.TextColor3 = Color3.fromRGB(180, 200, 220)
StatusLbl.TextXAlignment = Enum.TextXAlignment.Left
StatusLbl.Text = "Stolen: 0 | Carrying: NO"
StatusLbl.Parent = Main

updateStatsUI = function()
    local carr = isCarrying() and "YES" or "NO"
    StatusLbl.Text = string.format("Stolen: %d | Carrying: %s", totalStolen, carr)
end

-- Box Log
local LogContainer = Instance.new("ScrollingFrame")
LogContainer.Size = UDim2.new(0.92, 0, 0, 188)
LogContainer.Position = UDim2.new(0.04, 0, 0, 268)
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
        row.Size = UDim2.new(1, -8, 0, 15)
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
    LogContainer.CanvasSize = UDim2.new(0, 0, 0, #LOGS * 18)
end

print("========================================")
print("✅ AUTO STEAL SCRIPT READY!")
print("========================================")
addLog("INIT", "Auto Steal GUI loaded. Base: -59.5, 3.4, -4.9", Color3.fromRGB(100, 255, 120))
