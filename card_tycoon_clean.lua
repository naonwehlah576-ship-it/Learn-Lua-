-- ============================================================================
-- CARD & CRATE TYCOON - COMPACT ALL-IN-ONE AUTOFARM (DELTA EXECUTOR READY)
-- 100% Pure Offline UI - Ultra Compact & Responsive Mobile Layout
-- Fitur:
--   1. Auto Full Crate Cycle (Jeda 10s Tiap Cycle, 100% Work)
--   2. Auto Roll & Buy Filter (Jeda 0.5s + Proteksi Saldo Uang + Shortcut Key Q)
--   3. Auto Level Up Base Cards (Prioritas Termurah + Target Level)
--   4. Auto Teleport Variant Token & Pasti Balik ke Titik Awal
--   5. Auto Infinity Tower Battle (Mode Single & Rotate 3 Tower)
--   6. Auto-Save Persistent Config (writefile JSON)
-- ============================================================================

if not game:IsLoaded() then
    pcall(function() game.Loaded:Wait() end)
end

-- Cleanup script instance lama jika di-execute ulang
pcall(function()
    local g = (getgenv and getgenv()) or _G
    if g and g._CardTycoonCleanCleanup then
        g._CardTycoonCleanCleanup()
    end
end)

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Workspace = game:GetService("Workspace")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local CollectionService = game:GetService("CollectionService")
local HttpService = game:GetService("HttpService")
local CoreGui = game:GetService("CoreGui")

local LocalPlayer = Players.LocalPlayer or Players.PlayerAdded:Wait()
local Remotes = ReplicatedStorage:WaitForChild("Remotes", 15)

-- Remote Resolver Helper
local Remoting = nil
pcall(function()
    Remoting = require(ReplicatedStorage.Shared.Utility.Remoting)
end)

local function getRemote(name)
    local found = nil
    pcall(function()
        if Remoting then
            if Remoting.RemoteEvent then found = Remoting.RemoteEvent(name) end
            if not found and Remoting.RemoteFunction then found = Remoting.RemoteFunction(name) end
        end
    end)
    if found then return found end

    if Remotes and Remotes:FindFirstChild(name) then
        return Remotes[name]
    end

    local rs = game:GetService("ReplicatedStorage")
    for _, folderName in ipairs({"Remotes", "Remoting", "Events"}) do
        local f = rs:FindFirstChild(folderName)
        if f and f:FindFirstChild(name) then
            return f[name]
        end
    end
    return nil
end

-- Click Button Helper (Kompatibel dengan semua executor)
local function clickButton(btn)
    if not btn then return false end
    pcall(function()
        if typeof(firesignal) == "function" then
            firesignal(btn.MouseButton1Click)
        elseif typeof(getconnections) == "function" then
            for _, conn in ipairs(getconnections(btn.MouseButton1Click)) do
                if conn.Fire then conn:Fire() else conn.Function() end
            end
        else
            btn.MouseButton1Click:Fire()
        end
    end)
    return true
end

-- Modul Game
local BoxService = nil
pcall(function()
    BoxService = require(ReplicatedStorage.Shared.Services.BoxService)
end)

local PlayerUnitService = nil
pcall(function()
    PlayerUnitService = require(ReplicatedStorage.Shared.Services.PlayerUnitService)
end)

local CurrencyService = nil
pcall(function()
    CurrencyService = require(ReplicatedStorage.Shared.Services.CurrencyService)
end)

local InfinityTowerGuiClient = nil
pcall(function()
    InfinityTowerGuiClient = require(ReplicatedStorage.Client.Core.Gui.InfinityTowerGuiClient)
end)

-- Cek saldo Cash pemain
local function getPlayerCash()
    local cash = nil
    pcall(function()
        if CurrencyService and CurrencyService.GetCurrency then
            cash = CurrencyService.GetCurrency(LocalPlayer, "Cash")
        end
    end)
    if typeof(cash) == "number" then return cash end

    pcall(function()
        local leaderstats = LocalPlayer:FindFirstChild("leaderstats")
        if leaderstats and leaderstats:FindFirstChild("Cash") then
            cash = leaderstats.Cash.Value
        end
    end)
    if typeof(cash) == "number" then return cash end

    pcall(function()
        local cAttr = LocalPlayer:GetAttribute("Cash")
        if typeof(cAttr) == "number" then cash = cAttr end
    end)
    if typeof(cash) == "number" then return cash end

    return nil
end

local function canAffordPrice(price)
    if not price or price <= 0 then return true end
    
    local canAfford = nil
    pcall(function()
        if CurrencyService and CurrencyService.CanAfford then
            canAfford = CurrencyService.CanAfford(LocalPlayer, "Cash", price)
        end
    end)
    if canAfford ~= nil then return canAfford end

    local currentCash = getPlayerCash()
    if currentCash ~= nil then
        return currentCash >= price
    end

    return true
end

-- ============================================================================
-- DAFTAR PACK & MAPPING
-- ============================================================================
local AllPackNames = {
    "Fire Pack",
    "Ice Pack",
    "Water Pack",
    "Pirate Pack",
    "Romcom Pack",
    "Sword Pack",
    "Knight Pack",
    "Assassin Pack",
    "Ninja Pack",
    "Mage Pack",
    "Hero Pack",
    "Devil Pack",
    "Genius Pack",
    "Idol Pack",
    "Slayer Pack",
    "Titan Pack",
}

local PackInternalMap = {
    ["Fire Pack"]     = "FirePack",
    ["Ice Pack"]      = "IcePack",
    ["Water Pack"]    = "WaterPack",
    ["Pirate Pack"]   = "PiratePack",
    ["Romcom Pack"]   = "RomcomPack",
    ["Sword Pack"]    = "SwordPack",
    ["Knight Pack"]   = "KnightPack",
    ["Assassin Pack"] = "AssassinPack",
    ["Ninja Pack"]    = "NinjaPack",
    ["Mage Pack"]     = "MagePack",
    ["Hero Pack"]     = "HeroPack",
    ["Devil Pack"]    = "DevilPack",
    ["Genius Pack"]   = "GeniusPack",
    ["Idol Pack"]     = "IdolPack",
    ["Slayer Pack"]   = "SlayerPack",
    ["Titan Pack"]    = "TitanPack",
}

local InternalToPrettyMap = {}
for pretty, internal in pairs(PackInternalMap) do
    InternalToPrettyMap[internal] = pretty
end

local PackColors = {
    ["Fire Pack"]     = Color3.fromRGB(255, 120, 60),
    ["Ice Pack"]      = Color3.fromRGB(100, 220, 255),
    ["Water Pack"]    = Color3.fromRGB(70, 160, 255),
    ["Pirate Pack"]   = Color3.fromRGB(255, 200, 70),
    ["Romcom Pack"]   = Color3.fromRGB(255, 120, 180),
    ["Sword Pack"]    = Color3.fromRGB(160, 110, 255),
    ["Knight Pack"]   = Color3.fromRGB(200, 210, 220),
    ["Assassin Pack"] = Color3.fromRGB(255, 70, 90),
    ["Ninja Pack"]    = Color3.fromRGB(140, 90, 230),
    ["Mage Pack"]     = Color3.fromRGB(210, 100, 255),
    ["Hero Pack"]     = Color3.fromRGB(255, 215, 0),
    ["Devil Pack"]    = Color3.fromRGB(230, 50, 50),
    ["Genius Pack"]   = Color3.fromRGB(50, 220, 140),
    ["Idol Pack"]     = Color3.fromRGB(255, 160, 220),
    ["Slayer Pack"]   = Color3.fromRGB(255, 90, 40),
    ["Titan Pack"]    = Color3.fromRGB(220, 150, 80),
}

-- ============================================================================
-- DAFTAR MUTASI / VARIANTS & MULTIPLIERS (DARI VARIANTSLIBRARY)
-- ============================================================================
local AllVariantNames = {
    "Normal",
    "Gold",
    "Diamond",
    "Jade",
    "Honey",
    "Rose",
    "Astral",
    "Aurora",
    "Starweaver",
    "Rainbow",
    "Admin",
    "Unwritten"
}

local VariantMultipliers = {
    ["Normal"]     = "1x",
    ["Gold"]       = "1.5x",
    ["Diamond"]    = "2x",
    ["Jade"]       = "3x",
    ["Honey"]      = "5x",
    ["Rose"]       = "10x",
    ["Astral"]     = "15x",
    ["Aurora"]     = "20x",
    ["Starweaver"] = "30x",
    ["Rainbow"]    = "50x",
    ["Admin"]      = "75x",
    ["Unwritten"]  = "90x",
}

local VariantColors = {
    ["Normal"]     = Color3.fromRGB(180, 185, 195),
    ["Gold"]       = Color3.fromRGB(255, 215, 0),
    ["Diamond"]    = Color3.fromRGB(80, 190, 255),
    ["Jade"]       = Color3.fromRGB(70, 230, 130),
    ["Honey"]      = Color3.fromRGB(255, 190, 40),
    ["Rose"]       = Color3.fromRGB(255, 105, 180),
    ["Astral"]     = Color3.fromRGB(190, 90, 255),
    ["Aurora"]     = Color3.fromRGB(40, 240, 220),
    ["Starweaver"] = Color3.fromRGB(140, 200, 255),
    ["Rainbow"]    = Color3.fromRGB(255, 85, 85),
    ["Admin"]      = Color3.fromRGB(255, 45, 45),
    ["Unwritten"]  = Color3.fromRGB(240, 240, 240),
}

-- Helper Mutasi Per Pack
local function getPackVariantConfig(packName)
    if not Config.PackVariants then
        Config.PackVariants = {}
    end
    if not Config.PackVariants[packName] then
        Config.PackVariants[packName] = {}
        for _, vName in ipairs(AllVariantNames) do
            Config.PackVariants[packName][vName] = true
        end
    end
    return Config.PackVariants[packName]
end

local function isVariantAllowedForPack(packName, variant)
    if not Config.PackVariants then return true end
    local pConfig = Config.PackVariants[packName]
    if not pConfig then
        local altName = packName:find(" Pack") and packName:gsub(" Pack", "Pack") or packName:gsub("Pack", " Pack")
        pConfig = Config.PackVariants[altName]
    end
    if not pConfig then return true end
    if pConfig[variant] ~= nil then
        return pConfig[variant] == true
    end
    return true
end

local function hasCustomVariantFilter(packName)
    if not Config.PackVariants or not Config.PackVariants[packName] then return false end
    for _, vName in ipairs(AllVariantNames) do
        if Config.PackVariants[packName][vName] == false then
            return true
        end
    end
    return false
end

-- Deteksi Plot Player
local function getMyPlot()
    local plotModels = Workspace:FindFirstChild("Map") and Workspace.Map:FindFirstChild("PlotModels")
    if not plotModels then return nil end

    local myPlot = plotModels:FindFirstChild(LocalPlayer.Name)
    if myPlot then return myPlot end

    for _, plot in ipairs(plotModels:GetChildren()) do
        if plot.Name:find(LocalPlayer.Name) then
            return plot
        end
    end
    return nil
end

-- Bypass ProximityPrompt
local function triggerPrompt(prompt)
    if not prompt or not prompt.Enabled then return false end
    pcall(function()
        local oldDist = prompt.MaxActivationDistance
        local oldLos = prompt.RequiresLineOfSight
        prompt.MaxActivationDistance = 999999
        prompt.RequiresLineOfSight = false
        
        if typeof(fireproximityprompt) == "function" then
            fireproximityprompt(prompt)
        else
            prompt:InputHoldBegin()
            task.wait(prompt.HoldDuration + 0.02)
            prompt:InputHoldEnd()
        end
        
        prompt.MaxActivationDistance = oldDist
        prompt.RequiresLineOfSight = oldLos
    end)
    return true
end

-- ============================================================================
-- KONFIGURASI PERSISTENT & AUTOSAVE
-- ============================================================================
local CONFIG_FILE = "CardTycoon_CleanConfig.json"

local Config = {
    AutoFullCrateCycle = false,
    AutoRoll = false,
    AutoLevelUp = false,
    TargetCardLevel = 35,
    AutoCollectTokens = false,
    AutoTower = false,
    TowerMode = "Single", -- "Single" atau "Rotate"
    AutoHideTowerBattle = true,
    
    SelectedTowers = {
        ["DistantCastle"] = true,
        ["WisteriaVeil"]  = false,
        ["PirateIsland"]  = false,
    },
    
    SelectedPacks = {
        ["Fire Pack"]     = true,
        ["Ice Pack"]      = true,
        ["Water Pack"]    = true,
        ["Pirate Pack"]   = true,
        ["Romcom Pack"]   = true,
        ["Sword Pack"]    = true,
        ["Knight Pack"]   = false,
        ["Assassin Pack"] = false,
        ["Ninja Pack"]    = false,
        ["Mage Pack"]     = false,
        ["Hero Pack"]     = false,
        ["Devil Pack"]    = false,
        ["Genius Pack"]   = false,
        ["Idol Pack"]     = false,
        ["Slayer Pack"]   = false,
        ["Titan Pack"]    = false,
    },
    
    PackVariants = {}
}

local toggleRefs = {}

local function saveConfig()
    pcall(function()
        if writefile then
            local data = HttpService:JSONEncode(Config)
            writefile(CONFIG_FILE, data)
        end
    end)
end

local function loadConfig()
    pcall(function()
        if readfile and isfile and isfile(CONFIG_FILE) then
            local data = readfile(CONFIG_FILE)
            local decoded = HttpService:JSONDecode(data)
            if type(decoded) == "table" then
                for k, v in pairs(decoded) do
                    if k == "SelectedPacks" and type(v) == "table" then
                        for pK, pV in pairs(v) do
                            Config.SelectedPacks[pK] = pV
                        end
                    elseif k == "SelectedTowers" and type(v) == "table" then
                        for tK, tV in pairs(v) do
                            Config.SelectedTowers[tK] = tV
                        end
                    elseif k == "PackVariants" and type(v) == "table" then
                        Config.PackVariants = Config.PackVariants or {}
                        for pK, pV in pairs(v) do
                            if type(pV) == "table" then
                                Config.PackVariants[pK] = Config.PackVariants[pK] or {}
                                for varK, varV in pairs(pV) do
                                    Config.PackVariants[pK][varK] = varV
                                end
                            end
                        end
                    elseif Config[k] ~= nil then
                        Config[k] = v
                    end
                end
            end
        end
    end)
end

loadConfig()

-- ============================================================================
-- 1. AUTO FULL CRATE CYCLE (PERSIS SCRIPT SEBELUMNYA YANG TERBUKTI WORK)
-- ============================================================================
local function doCarryCrate()
    local myPlot = getMyPlot()
    if not myPlot then return end
    
    pcall(function()
        local rem = getRemote("PickupCrateBox")
        if rem then rem:FireServer() end
    end)
    
    pcall(function()
        local collectPart = myPlot:FindFirstChild("Systems") 
            and myPlot.Systems:FindFirstChild("TycoonConveyor") 
            and myPlot.Systems.TycoonConveyor:FindFirstChild("CollectPart")
            
        if collectPart then
            for _, desc in ipairs(collectPart:GetDescendants()) do
                if desc:IsA("ProximityPrompt") then
                    triggerPrompt(desc)
                end
            end
        end
    end)
end

local function doDepositPolisher()
    local myPlot = getMyPlot()
    if not myPlot then return end
    
    pcall(function()
        local rem = getRemote("DepositCrate")
        if rem then rem:FireServer() end
    end)
    
    pcall(function()
        local polisherCollect = myPlot:FindFirstChild("Systems") 
            and myPlot.Systems:FindFirstChild("PolisherModel")
            and myPlot.Systems.PolisherModel:FindFirstChild("PhysicalModel")
            and myPlot.Systems.PolisherModel.PhysicalModel:FindFirstChild("CollectPart")
            
        if polisherCollect then
            for _, desc in ipairs(polisherCollect:GetDescendants()) do
                if desc:IsA("ProximityPrompt") then
                    triggerPrompt(desc)
                end
            end
        end
    end)
end

local function doCollectPolisher()
    pcall(function()
        local rem = getRemote("CollectPolisherCrate")
        if rem then rem:FireServer() end
    end)
end

local function doSellCrates()
    local myPlot = getMyPlot()
    if not myPlot then return end
    
    pcall(function()
        local rem = getRemote("SellCrate")
        if rem then rem:FireServer() end
    end)
    
    pcall(function()
        local sellNpcZone = myPlot:FindFirstChild("Systems") 
            and myPlot.Systems:FindFirstChild("Zones") 
            and myPlot.Systems.Zones:FindFirstChild("sell npc")
            
        if sellNpcZone then
            for _, desc in ipairs(sellNpcZone:GetDescendants()) do
                if desc:IsA("ProximityPrompt") then
                    triggerPrompt(desc)
                end
            end
        end
    end)

    pcall(function()
        local npcModels = Workspace:FindFirstChild("Map") and Workspace.Map:FindFirstChild("NpcModels")
        if npcModels then
            for _, npc in ipairs(npcModels:GetChildren()) do
                for _, prompt in ipairs(npc:GetDescendants()) do
                    if prompt:IsA("ProximityPrompt") then
                        triggerPrompt(prompt)
                    end
                end
            end
        end
    end)
end

local function runSingleCycle()
    doCarryCrate()
    task.wait(0.3)
    doDepositPolisher()
    task.wait(0.3)
    doCollectPolisher()
    task.wait(0.3)
    doSellCrates()
end

-- ============================================================================
-- 2. AUTO ROLL & BUY FILTER (JEDA 0.5S + CEK SALDO UANG)
-- ============================================================================
local function getRollConveyorPart()
    local myPlot = getMyPlot()
    if not myPlot then return nil end

    local rollStation = myPlot:FindFirstChild("Systems") and myPlot.Systems:FindFirstChild("RollStation")
    if rollStation then
        return rollStation:FindFirstChild("ConveyorPart")
    end

    for _, part in ipairs(CollectionService:GetTagged("RollConveyorPart")) do
        if part:IsDescendantOf(myPlot) then
            return part
        end
    end
    return nil
end

local lastPurchasedRollCount = -1
local lastSkippedRollCount = -1
local lastRollRequestTime = 0
local lastAffordLogTime = 0

local function resetAutoRollState()
    lastPurchasedRollCount = -1
    lastSkippedRollCount = -1
    lastRollRequestTime = 0
    lastAffordLogTime = 0
end

local function doRollCard()
    if not Config.AutoRoll then return end
    
    local rollPart = getRollConveyorPart()
    if not rollPart then return end

    local now = os.clock()
    local rollCount = rollPart:GetAttribute("RollCount") or 0
    local boxNameInternal = rollPart:GetAttribute("BoxName")
    local variant = rollPart:GetAttribute("Variant") or "Normal"
    local packModel = rollPart:FindFirstChild("PackModel")

    -- TAHAP 1: CEK PACK DI ATAS CONVEYOR SEKARANG
    if boxNameInternal and boxNameInternal ~= "" and (packModel ~= nil or rollCount > 0) then
        if rollCount ~= lastPurchasedRollCount and rollCount ~= lastSkippedRollCount then
            local prettyName = InternalToPrettyMap[boxNameInternal] or boxNameInternal:gsub("Pack", " Pack")
            local isWanted = (Config.SelectedPacks[prettyName] == true) or (Config.SelectedPacks[boxNameInternal] == true)
            local isVariantAllowed = isVariantAllowedForPack(prettyName, variant) and isVariantAllowedForPack(boxNameInternal, variant)

            if isWanted and isVariantAllowed then
                -- 1. Hitung harga akurat via BoxService
                local price = 0
                pcall(function()
                    if BoxService and BoxService.GetConveyorBoxPrice then
                        price = BoxService.GetConveyorBoxPrice(boxNameInternal, variant)
                    end
                end)

                -- 2. Cek apakah uang cukup untuk beli pack ini
                if not canAffordPrice(price) then
                    local myCash = getPlayerCash() or 0
                    if now - lastAffordLogTime > 4.0 then
                        lastAffordLogTime = now
                        print(string.format("⏳ [Auto Roll] Menunggu saldo terkumpul untuk beli %s (%s) [Harga: $%s | Saldo: $%s]...", prettyName, variant, tostring(price or 0), tostring(myCash)))
                    end
                    -- Berhenti roll sementara dan pertahankan pack ini di conveyor sampai uang cukup
                    return
                end

                -- Uang sudah cukup: jeda sedikit 0.3s agar transaksi server mulus
                task.wait(0.3)

                -- 3. Beli pack via remote PurchaseConveyorRoll
                local buyRemote = getRemote("PurchaseConveyorRoll")
                if buyRemote then
                    pcall(function()
                        buyRemote:FireServer(boxNameInternal, variant, price or 0)
                    end)
                end

                -- 4. Trigger prompt jika ada di rollPart atau packModel
                pcall(function()
                    for _, desc in ipairs(rollPart:GetDescendants()) do
                        if desc:IsA("ProximityPrompt") then
                            triggerPrompt(desc)
                        end
                    end
                end)

                lastPurchasedRollCount = rollCount
                print(string.format("✅ [Auto Roll] SUKSES BELI: %s (%s) [Roll #%s, $%s]", prettyName, variant, tostring(rollCount), tostring(price or 0)))

                task.wait(0.3)
            else
                -- Bukan pack yang dicari atau mutasi tidak diizinkan -> tandai sudah diskip agar langsung lanjut roll
                lastSkippedRollCount = rollCount
                if isWanted and not isVariantAllowed then
                    print(string.format("⏭️ [Auto Roll] Lewati %s (%s) [Roll #%s] (Mutasi %s di-skip untuk pack ini)", prettyName, variant, tostring(rollCount), variant))
                else
                    print(string.format("⏭️ [Auto Roll] Lewati %s (%s) [Roll #%s] (Bukan target filter)", prettyName, variant, tostring(rollCount)))
                end
            end
        end
    end

    -- TAHAP 2: ROLL BARU JIKA TIDAK ADA PACK YANG MENUNGGU DIBELI
    local cooldownUntil = rollPart:GetAttribute("RollCooldownUntil")
    if cooldownUntil and workspace:GetServerTimeNow() < cooldownUntil then
        return
    end

    if now - lastRollRequestTime < 0.7 then
        return
    end

    if boxNameInternal and boxNameInternal ~= "" and packModel ~= nil and rollCount ~= lastPurchasedRollCount and rollCount ~= lastSkippedRollCount then
        return
    end

    local rollRemote = getRemote("RequestConveyorRoll")
    if rollRemote then
        lastRollRequestTime = now
        pcall(function()
            rollRemote:FireServer()
        end)
    end
end

-- ============================================================================
-- 3. AUTO LEVEL UP CARDS (HANYA KARTU DI BASE + PRIORITAS TERMURAH)
-- ============================================================================
local function getAllDropperParts(myPlot)
    local droppers = {}
    pcall(function()
        local conveyors = myPlot:FindFirstChild("Systems") 
            and myPlot.Systems:FindFirstChild("TycoonConveyor") 
            and myPlot.Systems.TycoonConveyor:FindFirstChild("Conveyors")
        if conveyors then
            for _, conv in ipairs(conveyors:GetChildren()) do
                local dFolder = conv:FindFirstChild("Droppers")
                if dFolder then
                    for _, dropPart in ipairs(dFolder:GetChildren()) do
                        table.insert(droppers, dropPart)
                    end
                end
            end
        end
    end)
    return droppers
end

local function doLevelUpCards()
    local myPlot = getMyPlot()
    if not myPlot then return end

    local droppers = getAllDropperParts(myPlot)
    if #droppers == 0 then return end

    local targetLevel = tonumber(Config.TargetCardLevel) or 35
    local candidates = {}

    for _, dropPart in ipairs(droppers) do
        local unitName = dropPart:GetAttribute("PlayerUnitName")
        local unitLevel = dropPart:GetAttribute("PlayerUnitLevel") or 1

        -- Hanya upgrade kartu terpasang di base yang belum mencapai target level
        if unitName and unitLevel < targetLevel and unitLevel < 100 then
            local cost = unitLevel * 1000
            local cardData = {
                ["PlayerUnitName"] = unitName,
                ["PlayerUnitVariant"] = dropPart:GetAttribute("PlayerUnitVariant"),
                ["PlayerUnitGrade"] = dropPart:GetAttribute("PlayerUnitGrade"),
                ["PlayerUnitTrait"] = dropPart:GetAttribute("PlayerUnitTrait")
            }

            pcall(function()
                if PlayerUnitService and PlayerUnitService.GetLevelUpgradeCost then
                    local calcCost = PlayerUnitService.GetLevelUpgradeCost(LocalPlayer, cardData, unitLevel + 1)
                    if calcCost and calcCost > 0 then
                        cost = calcCost
                    end
                end
            end)

            table.insert(candidates, {
                Part = dropPart,
                Level = unitLevel,
                Cost = cost,
                Name = unitName
            })
        end
    end

    -- Prioritaskan kartu yang biaya upgrade-nya PALING MURAH
    if #candidates > 0 then
        table.sort(candidates, function(a, b)
            return a.Cost < b.Cost
        end)

        local cheapest = candidates[1]
        local lvlRemote = getRemote("RequestPlayerUnitLevelUp")
        if lvlRemote then
            pcall(function()
                lvlRemote:FireServer(cheapest.Part)
            end)
        end
    end
end

-- ============================================================================
-- 4. AUTO TELEPORT VARIANT TOKEN & PASTI BALIK KE POSISI AWAL
-- ============================================================================
local function findActiveVariantToken()
    local folder = Workspace:FindFirstChild("Systems") and Workspace.Systems:FindFirstChild("VariantTokenSpawns")
    if not folder then return nil end

    for _, child in ipairs(folder:GetChildren()) do
        if child:GetAttribute("Occupied") == true then
            return child
        end
    end

    for _, part in ipairs(CollectionService:GetTagged("VariantTokenSpawn")) do
        if part:GetAttribute("Occupied") == true then
            return part
        end
    end

    return nil
end

local isCollectingToken = false
local function collectVariantToken(targetObj)
    if isCollectingToken then return end
    isCollectingToken = true

    local char = LocalPlayer.Character
    local hrp = char and char:FindFirstChild("HumanoidRootPart")
    if not hrp or not targetObj then 
        isCollectingToken = false
        return 
    end

    local targetPart = targetObj:IsA("BasePart") and targetObj or targetObj:FindFirstChildWhichIsA("BasePart")
    if not targetPart then 
        isCollectingToken = false
        return 
    end

    -- Simpan posisi persis player saat ini sebelum teleport
    local returnCFrame = hrp.CFrame
    print("🔮 [Variant Token] Menemukan token di: " .. targetObj.Name .. "! Teleport ke token...")

    -- 1. Teleport ke lokasi token
    hrp.AssemblyLinearVelocity = Vector3.zero
    hrp.CFrame = targetPart.CFrame + Vector3.new(0, 3.5, 0)
    task.wait(0.3)

    -- 2. Simulasi sentuhan fisik (firetouchinterest)
    if typeof(firetouchinterest) == "function" then
        pcall(function()
            firetouchinterest(hrp, targetPart, 0)
            task.wait(0.02)
            firetouchinterest(hrp, targetPart, 1)
        end)
    end

    -- 3. Trigger ProximityPrompt jika ada
    for _, desc in ipairs(targetObj:GetDescendants()) do
        if desc:IsA("ProximityPrompt") then
            triggerPrompt(desc)
        end
    end

    -- 4. Tembak Remote Collect & Found
    local remFound = getRemote("VariantTokenFound")
    if remFound then
        pcall(function() remFound:FireServer(targetObj) end)
        pcall(function() remFound:FireServer(targetObj.Name) end)
    end
    local remCollect = getRemote("CollectVariantTokenSpawn")
    if remCollect then
        pcall(function() remCollect:FireServer(targetObj) end)
        pcall(function() remCollect:FireServer(targetObj.Name) end)
    end

    -- 4. Tunggu sampai token benar-benar hilang / Occupied = false (maksimal 3.5 detik)
    local waitStart = os.clock()
    while os.clock() - waitStart < 3.5 do
        if not targetObj.Parent or targetObj:GetAttribute("Occupied") == false then
            break
        end
        task.wait(0.2)
    end

    -- 5. Teleport PASTI KEMBALI ke posisi semula sebelum teleport
    pcall(function()
        local curChar = LocalPlayer.Character
        local curHrp = curChar and curChar:FindFirstChild("HumanoidRootPart")
        if curHrp and returnCFrame then
            curHrp.AssemblyLinearVelocity = Vector3.zero
            curHrp.CFrame = returnCFrame
            task.wait(0.08)
            curHrp.CFrame = returnCFrame
            print("✅ [Variant Token] Token hilang & berhasil diambil! Kembali ke posisi awal.")
        end
    end)

    -- Cooldown kecil agar tidak spam mendeteksi sisa part token lama
    task.wait(1.5)
    isCollectingToken = false
end

-- Listener Event Token Spawned
pcall(function()
    local remSpawned = getRemote("VariantTokenSpawned")
    if remSpawned then
        remSpawned.OnClientEvent:Connect(function(tokenInstance)
            if Config.AutoCollectTokens then
                task.wait(0.5)
                if tokenInstance and typeof(tokenInstance) == "Instance" then
                    collectVariantToken(tokenInstance)
                else
                    local activeToken = findActiveVariantToken()
                    if activeToken then
                        collectVariantToken(activeToken)
                    end
                end
            end
        end)
    end
end)

-- ============================================================================
-- 5. AUTO INFINITY TOWER BATTLE (MODE SINGLE & ROTATE 3 TOWER)
-- ============================================================================
local TowerOrder = { "DistantCastle", "WisteriaVeil", "PirateIsland" }
local TowerDisplayNames = {
    ["DistantCastle"] = "🏰 Distant Castle",
    ["WisteriaVeil"]  = "🌸 Wisteria Veil",
    ["PirateIsland"]  = "🏴‍☠️ Pirate Island",
}
local currentRotateIndex = 1

local function getNextTower()
    local checkedTowers = {}
    for _, tName in ipairs(TowerOrder) do
        if Config.SelectedTowers[tName] then
            table.insert(checkedTowers, tName)
        end
    end

    if #checkedTowers == 0 then
        return "DistantCastle"
    end

    if Config.TowerMode == "Single" then
        return checkedTowers[1]
    else
        currentRotateIndex = currentRotateIndex + 1
        if currentRotateIndex > #checkedTowers then
            currentRotateIndex = 1
        end
        return checkedTowers[currentRotateIndex]
    end
end

local function isTowerInBattle()
    local pGui = LocalPlayer:FindFirstChild("PlayerGui")
    local tGui = pGui and pGui:FindFirstChild("InfinityTowerGui")
    if tGui and tGui:FindFirstChild("BattleMainFrame") and tGui.BattleMainFrame.Visible then
        return true
    end

    local inBattle = false
    pcall(function()
        local getBattleState = getRemote("GetInfinityTowerBattleState")
        if getBattleState then
            local state = getBattleState:InvokeServer()
            if state and state ~= false then inBattle = true end
        end
    end)
    return inBattle
end

local isStartingTower = false

local function runTowerCycle()
    if not Config.AutoTower or isStartingTower then return end

    -- Jika sedang di dalam battle, pastikan Auto battle aktif & hide frame jika disetting
    if isTowerInBattle() then
        pcall(function()
            local setAuto = getRemote("SetInfinityTowerAutoBattle")
            if setAuto then setAuto:FireServer(true) end
        end)
        
        if Config.AutoHideTowerBattle then
            pcall(function()
                local pGui = LocalPlayer:FindFirstChild("PlayerGui")
                local tGui = pGui and pGui:FindFirstChild("InfinityTowerGui")
                if tGui and tGui:FindFirstChild("BattleMainFrame") and tGui.BattleMainFrame:FindFirstChild("HideButton") then
                    clickButton(tGui.BattleMainFrame.HideButton)
                end
            end)
        end
        return
    end

    isStartingTower = true
    local towerToPlay = getNextTower()
    print("🏰 [Infinity Tower] Memulai run di: " .. towerToPlay .. " (Mode: " .. tostring(Config.TowerMode) .. ")")

    pcall(function()
        local pGui = LocalPlayer:FindFirstChild("PlayerGui")
        local tGui = pGui and pGui:FindFirstChild("InfinityTowerGui")
        
        -- 1. Buka GUI Tower jika tertutup
        if InfinityTowerGuiClient and InfinityTowerGuiClient.Open then
            InfinityTowerGuiClient.Open()
        end
        task.wait(0.4)

        -- 2. Pilih Tower dari list (FloorSelectionMainFrame)
        if tGui and tGui:FindFirstChild("FloorSelectionMainFrame") then
            local scroll = tGui.FloorSelectionMainFrame:FindFirstChild("ScrollingHolder") 
                and tGui.FloorSelectionMainFrame.ScrollingHolder:FindFirstChild("ScrollingFrame")
            local towerItem = scroll and scroll:FindFirstChild(towerToPlay)
            local playBtn = towerItem and towerItem:FindFirstChild("PlayButton")
            if playBtn then
                clickButton(playBtn)
            end
        end
        task.wait(0.5)

        -- 3. Tekan Tombol Equip Best untuk pasang 4 kartu terkuat di tower
        if tGui and tGui:FindFirstChild("UnitsSelectionMainFrame") then
            local equipBestBtn = tGui.UnitsSelectionMainFrame:FindFirstChild("ButtonHolder") 
                and tGui.UnitsSelectionMainFrame.ButtonHolder:FindFirstChild("EquipBestButton")
            if equipBestBtn then
                clickButton(equipBestBtn)
                print("⚔️ [Infinity Tower] Equip Best Units berhasil ditekan.")
            end
        end
        task.wait(0.5)

        -- 4. Mulai Pertarungan (StartButton / StartInfinityTowerBattle Remote)
        local started = false
        if tGui and tGui:FindFirstChild("UnitsSelectionMainFrame") then
            local startBtn = tGui.UnitsSelectionMainFrame:FindFirstChild("ButtonHolder") 
                and tGui.UnitsSelectionMainFrame.ButtonHolder:FindFirstChild("StartButton")
            if startBtn then
                clickButton(startBtn)
                started = true
            end
        end

        if not started then
            local startRemote = getRemote("StartInfinityTowerBattle")
            if startRemote then
                startRemote:InvokeServer(towerToPlay)
            end
        end

        task.wait(1.0)

        -- 5. Aktifkan In-Game Auto Battle
        local setAuto = getRemote("SetInfinityTowerAutoBattle")
        if setAuto then
            setAuto:FireServer(true)
        end

        -- 6. Sembunyikan Battle Frame jika user memilih AutoHide
        if Config.AutoHideTowerBattle then
            task.wait(0.3)
            if tGui and tGui:FindFirstChild("BattleMainFrame") and tGui.BattleMainFrame:FindFirstChild("HideButton") then
                clickButton(tGui.BattleMainFrame.HideButton)
            end
        end
    end)

    task.wait(1.0)
    isStartingTower = false
end

-- Listener: Begitu run selesai / kalah / tamat -> Otomatis ulang
pcall(function()
    local battleEnded = getRemote("InfinityTowerBattleEnded")
    if battleEnded then
        battleEnded.OnClientEvent:Connect(function()
            if Config.AutoTower then
                print("🏆 [Infinity Tower] Pertarungan selesai! Mempersiapkan run berikutnya...")
                task.wait(2.0)
                runTowerCycle()
            end
        end)
    end
end)

-- ============================================================================
-- BACKGROUND WORKER LOOPS
-- ============================================================================
-- Full Crate Cycle Loop (Jeda 10s Tiap Cycle, Persis Script Asli)
task.spawn(function()
    while true do
        if Config.AutoFullCrateCycle then
            runSingleCycle()
            for i = 1, 100 do
                if not Config.AutoFullCrateCycle then break end
                task.wait(0.1)
            end
        else
            task.wait(0.5)
        end
    end
end)

-- Auto Roll Loop (Cek Conveyor & Beli Filter)
task.spawn(function()
    while true do
        if Config.AutoRoll then
            pcall(doRollCard)
            task.wait(0.25)
        else
            task.wait(0.4)
        end
    end
end)

-- Auto Level Up Loop
task.spawn(function()
    while true do
        if Config.AutoLevelUp then
            pcall(doLevelUpCards)
        end
        task.wait(0.6)
    end
end)

-- Variant Token Loop
task.spawn(function()
    while true do
        if Config.AutoCollectTokens then
            local activeToken = findActiveVariantToken()
            if activeToken then
                collectVariantToken(activeToken)
            end
        end
        task.wait(2.0)
    end
end)

-- Infinity Tower Loop
task.spawn(function()
    while true do
        if Config.AutoTower then
            pcall(runTowerCycle)
            task.wait(2.0)
        else
            task.wait(1.0)
        end
    end
end)

-- Keyboard Shortcut: Tekan Q untuk toggle ON/OFF Auto Roll secara instan
UserInputService.InputBegan:Connect(function(input, gameProcessed)
    if gameProcessed then return end
    if UserInputService:GetFocusedTextBox() then return end
    
    if input.KeyCode == Enum.KeyCode.Q then
        Config.AutoRoll = not Config.AutoRoll
        if Config.AutoRoll then
            resetAutoRollState()
        end
        if toggleRefs["AutoRoll"] and toggleRefs["AutoRoll"].UpdateUI then
            toggleRefs["AutoRoll"].UpdateUI(Config.AutoRoll)
        end
        saveConfig()
        print(string.format("⌨️ [Shortcut Q] Auto Roll di-%s!", Config.AutoRoll and "AKTIFKAN" or "NONAKTIFKAN"))
    end
end)

-- ============================================================================
-- ULTRA COMPACT OFFLINE UI (OPTIMAL UNTUK DELTA & MOBILE SCREEN)
-- ============================================================================
local ScreenGui = Instance.new("ScreenGui")
ScreenGui.Name = "CardTycoonCompactGui"
ScreenGui.ResetOnSpawn = false
ScreenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling

pcall(function()
    if gethui then
        ScreenGui.Parent = gethui()
    elseif syn and syn.protect_gui then
        syn.protect_gui(ScreenGui)
        ScreenGui.Parent = CoreGui
    else
        ScreenGui.Parent = CoreGui
    end
end)

if not ScreenGui.Parent then
    ScreenGui.Parent = LocalPlayer:WaitForChild("PlayerGui")
end

-- Cleanup Handler
local function cleanup()
    ScreenGui:Destroy()
end
local g = (getgenv and getgenv()) or _G
if g then g._CardTycoonCleanCleanup = cleanup end

-- Drag Helper (PC & Mobile Touch)
local function makeDraggable(dragHandle, mainFrame)
    local dragging = false
    local dragInput, dragStart, startPos

    dragHandle.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
            dragging = true
            dragStart = input.Position
            startPos = mainFrame.Position
            
            input.Changed:Connect(function()
                if input.UserInputState == Enum.UserInputState.End then
                    dragging = false
                end
            end)
        end
    end)

    dragHandle.InputChanged:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch then
            dragInput = input
        end
    end)

    UserInputService.InputChanged:Connect(function(input)
        if input == dragInput and dragging then
            local delta = input.Position - dragStart
            mainFrame.Position = UDim2.new(
                startPos.X.Scale,
                startPos.X.Offset + delta.X,
                startPos.Y.Scale,
                startPos.Y.Offset + delta.Y
            )
        end
    end)
end

-- Floating Toggle Button Kecil & Rapih (🃏)
local ToggleButton = Instance.new("TextButton")
ToggleButton.Name = "ToggleOpenBtn"
ToggleButton.Size = UDim2.new(0, 38, 0, 38)
ToggleButton.Position = UDim2.new(0, 10, 0.45, 0)
ToggleButton.BackgroundColor3 = Color3.fromRGB(22, 26, 38)
ToggleButton.Text = "🃏"
ToggleButton.TextSize = 18
ToggleButton.TextColor3 = Color3.fromRGB(255, 255, 255)
ToggleButton.Font = Enum.Font.GothamBold
ToggleButton.Parent = ScreenGui

local ToggleBtnCorner = Instance.new("UICorner")
ToggleBtnCorner.CornerRadius = UDim.new(0, 10)
ToggleBtnCorner.Parent = ToggleButton

local ToggleBtnStroke = Instance.new("UIStroke")
ToggleBtnStroke.Color = Color3.fromRGB(65, 120, 230)
ToggleBtnStroke.Thickness = 1.5
ToggleBtnStroke.Parent = ToggleButton

makeDraggable(ToggleButton, ToggleButton)

-- Main Frame: Ultra Compact (310 x 280) Pas Banget di Layar Delta!
local MainFrame = Instance.new("Frame")
MainFrame.Name = "MainFrame"
MainFrame.Size = UDim2.new(0, 320, 0, 315)
MainFrame.Position = UDim2.new(0.5, -160, 0.5, -157)
MainFrame.BackgroundColor3 = Color3.fromRGB(15, 17, 24)
MainFrame.BorderSizePixel = 0
MainFrame.ClipsDescendants = false
MainFrame.Parent = ScreenGui

local MainCorner = Instance.new("UICorner")
MainCorner.CornerRadius = UDim.new(0, 10)
MainCorner.Parent = MainFrame

local MainStroke = Instance.new("UIStroke")
MainStroke.Color = Color3.fromRGB(45, 55, 85)
MainStroke.Thickness = 1.2
MainStroke.Parent = MainFrame

-- TopBar Compact
local TopBar = Instance.new("Frame")
TopBar.Name = "TopBar"
TopBar.Size = UDim2.new(1, 0, 0, 32)
TopBar.BackgroundColor3 = Color3.fromRGB(20, 24, 35)
TopBar.BorderSizePixel = 0
TopBar.Parent = MainFrame

local TopBarCorner = Instance.new("UICorner")
TopBarCorner.CornerRadius = UDim.new(0, 10)
TopBarCorner.Parent = TopBar

makeDraggable(TopBar, MainFrame)

local TitleLabel = Instance.new("TextLabel")
TitleLabel.Name = "TitleLabel"
TitleLabel.Size = UDim2.new(1, -70, 1, 0)
TitleLabel.Position = UDim2.new(0, 10, 0, 0)
TitleLabel.BackgroundTransparency = 1
TitleLabel.Text = "🃏 <b>CARD TYCOON</b> <font color=\"#4A90E2\">AIO</font>"
TitleLabel.RichText = true
TitleLabel.TextColor3 = Color3.fromRGB(240, 240, 255)
TitleLabel.TextSize = 11.5
TitleLabel.Font = Enum.Font.GothamBold
TitleLabel.TextXAlignment = Enum.TextXAlignment.Left
TitleLabel.Parent = TopBar

local CloseBtn = Instance.new("TextButton")
CloseBtn.Name = "CloseBtn"
CloseBtn.Size = UDim2.new(0, 24, 0, 24)
CloseBtn.Position = UDim2.new(1, -29, 0, 4)
CloseBtn.BackgroundColor3 = Color3.fromRGB(210, 50, 65)
CloseBtn.Text = "✕"
CloseBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
CloseBtn.Font = Enum.Font.GothamBold
CloseBtn.TextSize = 11
CloseBtn.Parent = TopBar

local CloseBtnCorner = Instance.new("UICorner")
CloseBtnCorner.CornerRadius = UDim.new(0, 6)
CloseBtnCorner.Parent = CloseBtn

CloseBtn.MouseButton1Click:Connect(function()
    MainFrame.Visible = false
end)

ToggleButton.MouseButton1Click:Connect(function()
    MainFrame.Visible = not MainFrame.Visible
end)

-- ============================================================================
-- TAB BAR (3 TAB: FARM, ROLL & BUY, TOWER)
-- ============================================================================
local TabBar = Instance.new("Frame")
TabBar.Name = "TabBar"
TabBar.Size = UDim2.new(1, -12, 0, 26)
TabBar.Position = UDim2.new(0, 6, 0, 36)
TabBar.BackgroundTransparency = 1
TabBar.Parent = MainFrame

local TabLayout = Instance.new("UIListLayout")
TabLayout.FillDirection = Enum.FillDirection.Horizontal
TabLayout.SortOrder = Enum.SortOrder.LayoutOrder
TabLayout.Padding = UDim.new(0, 4)
TabLayout.Parent = TabBar

local function createTabButton(text, order)
    local btn = Instance.new("TextButton")
    btn.Size = UDim2.new(0.333, -3, 1, 0)
    btn.BackgroundColor3 = Color3.fromRGB(24, 28, 40)
    btn.Text = text
    btn.TextColor3 = Color3.fromRGB(150, 165, 195)
    btn.Font = Enum.Font.GothamBold
    btn.TextSize = 9.5
    btn.LayoutOrder = order
    btn.Parent = TabBar

    local c = Instance.new("UICorner")
    c.CornerRadius = UDim.new(0, 6)
    c.Parent = btn

    local s = Instance.new("UIStroke")
    s.Color = Color3.fromRGB(38, 46, 68)
    s.Thickness = 1
    s.Parent = btn

    return btn
end

local TabFarmBtn = createTabButton("⚡ Farm", 1)
local TabRollBtn = createTabButton("🎰 Roll", 2)
local TabTowerBtn = createTabButton("🏰 Tower", 3)

-- Page Containers (Standard Frames agar 100% Anti-Bug di Delta / MuMu!)
local function createPageFrame(name)
    local page = Instance.new("Frame")
    page.Name = "Page_" .. name
    page.Size = UDim2.new(1, -12, 1, -68)
    page.Position = UDim2.new(0, 6, 0, 66)
    page.BackgroundTransparency = 1
    page.BorderSizePixel = 0
    page.Visible = false
    page.Parent = MainFrame

    local layout = Instance.new("UIListLayout")
    layout.SortOrder = Enum.SortOrder.LayoutOrder
    layout.Padding = UDim.new(0, 5)
    layout.Parent = page

    return page, layout
end

local PageFarm, FarmLayout = createPageFrame("Farm")
local PageRoll, RollLayout = createPageFrame("Roll")
local PageTower, TowerLayout = createPageFrame("Tower")

local function switchTab(tab)
    PageFarm.Visible = (tab == "Farm")
    PageRoll.Visible = (tab == "Roll")
    PageTower.Visible = (tab == "Tower")

    TabFarmBtn.BackgroundColor3 = (tab == "Farm") and Color3.fromRGB(65, 120, 230) or Color3.fromRGB(24, 28, 40)
    TabFarmBtn.TextColor3 = (tab == "Farm") and Color3.fromRGB(255, 255, 255) or Color3.fromRGB(150, 165, 195)

    TabRollBtn.BackgroundColor3 = (tab == "Roll") and Color3.fromRGB(65, 120, 230) or Color3.fromRGB(24, 28, 40)
    TabRollBtn.TextColor3 = (tab == "Roll") and Color3.fromRGB(255, 255, 255) or Color3.fromRGB(150, 165, 195)

    TabTowerBtn.BackgroundColor3 = (tab == "Tower") and Color3.fromRGB(65, 120, 230) or Color3.fromRGB(24, 28, 40)
    TabTowerBtn.TextColor3 = (tab == "Tower") and Color3.fromRGB(255, 255, 255) or Color3.fromRGB(150, 165, 195)
end

TabFarmBtn.Activated:Connect(function() switchTab("Farm") end)
TabRollBtn.Activated:Connect(function() switchTab("Roll") end)
TabTowerBtn.Activated:Connect(function() switchTab("Tower") end)

-- UI Helpers
local function createSectionHeader(title, parent)
    local lbl = Instance.new("TextLabel")
    lbl.Size = UDim2.new(1, 0, 0, 15)
    lbl.BackgroundTransparency = 1
    lbl.Text = "— " .. title:upper() .. " —"
    lbl.TextColor3 = Color3.fromRGB(105, 125, 170)
    lbl.Font = Enum.Font.GothamBold
    lbl.TextSize = 9
    lbl.TextXAlignment = Enum.TextXAlignment.Left
    lbl.Parent = parent
    return lbl
end

local function createToggle(labelText, configKey, callback, parent)
    local defaultVal = Config[configKey] or false
    
    local toggleFrame = Instance.new("Frame")
    toggleFrame.Size = UDim2.new(1, 0, 0, 30)
    toggleFrame.BackgroundColor3 = Color3.fromRGB(22, 26, 36)
    toggleFrame.Parent = parent

    local corner = Instance.new("UICorner")
    corner.CornerRadius = UDim.new(0, 6)
    corner.Parent = toggleFrame

    local stroke = Instance.new("UIStroke")
    stroke.Color = Color3.fromRGB(35, 42, 58)
    stroke.Thickness = 1
    stroke.Parent = toggleFrame

    local label = Instance.new("TextLabel")
    label.Size = UDim2.new(1, -55, 1, 0)
    label.Position = UDim2.new(0, 8, 0, 0)
    label.BackgroundTransparency = 1
    label.Text = labelText
    label.TextColor3 = Color3.fromRGB(225, 230, 240)
    label.Font = Enum.Font.GothamMedium
    label.TextSize = 10
    label.TextXAlignment = Enum.TextXAlignment.Left
    label.Active = false
    label.Parent = toggleFrame

    local switch = Instance.new("TextButton")
    switch.Size = UDim2.new(0, 44, 0, 20)
    switch.Position = UDim2.new(1, -48, 0.5, -10)
    switch.BackgroundColor3 = defaultVal and Color3.fromRGB(45, 170, 85) or Color3.fromRGB(42, 48, 62)
    switch.Text = defaultVal and "ON" or "OFF"
    switch.TextColor3 = Color3.fromRGB(255, 255, 255)
    switch.Font = Enum.Font.GothamBold
    switch.TextSize = 9
    switch.Parent = toggleFrame

    local switchCorner = Instance.new("UICorner")
    switchCorner.CornerRadius = UDim.new(0, 10)
    switchCorner.Parent = switch

    local state = defaultVal
    local function setVisualState(val)
        state = val
        switch.BackgroundColor3 = state and Color3.fromRGB(45, 170, 85) or Color3.fromRGB(42, 48, 62)
        switch.Text = state and "ON" or "OFF"
    end

    switch.Activated:Connect(function()
        setVisualState(not state)
        Config[configKey] = state
        if callback then callback(state) end
        saveConfig()
    end)

    toggleRefs[configKey] = {
        UpdateUI = function(val)
            setVisualState(val)
            Config[configKey] = val
        end
    }

    return toggleFrame
end

local function createTextBox(labelText, configKey, defaultVal, parent)
    local val = Config[configKey] or defaultVal
    Config[configKey] = val

    local boxFrame = Instance.new("Frame")
    boxFrame.Size = UDim2.new(1, 0, 0, 30)
    boxFrame.BackgroundColor3 = Color3.fromRGB(22, 26, 36)
    boxFrame.Parent = parent

    local corner = Instance.new("UICorner")
    corner.CornerRadius = UDim.new(0, 6)
    corner.Parent = boxFrame

    local stroke = Instance.new("UIStroke")
    stroke.Color = Color3.fromRGB(35, 42, 58)
    stroke.Thickness = 1
    stroke.Parent = boxFrame

    local label = Instance.new("TextLabel")
    label.Size = UDim2.new(1, -70, 1, 0)
    label.Position = UDim2.new(0, 8, 0, 0)
    label.BackgroundTransparency = 1
    label.Text = labelText
    label.TextColor3 = Color3.fromRGB(225, 230, 240)
    label.Font = Enum.Font.GothamMedium
    label.TextSize = 10
    label.TextXAlignment = Enum.TextXAlignment.Left
    label.Active = false
    label.Parent = boxFrame

    local textBox = Instance.new("TextBox")
    textBox.Size = UDim2.new(0, 52, 0, 22)
    textBox.Position = UDim2.new(1, -60, 0.5, -11)
    textBox.BackgroundColor3 = Color3.fromRGB(32, 38, 52)
    textBox.Text = tostring(val)
    textBox.TextColor3 = Color3.fromRGB(255, 215, 0)
    textBox.Font = Enum.Font.GothamBold
    textBox.TextSize = 11
    textBox.ClearTextOnFocus = false
    textBox.Parent = boxFrame

    local tbCorner = Instance.new("UICorner")
    tbCorner.CornerRadius = UDim.new(0, 5)
    tbCorner.Parent = textBox

    textBox.FocusLost:Connect(function()
        local num = tonumber(textBox.Text)
        if num and num > 0 then
            Config[configKey] = math.floor(num)
            textBox.Text = tostring(Config[configKey])
        else
            textBox.Text = tostring(Config[configKey])
        end
        saveConfig()
    end)

    return boxFrame
end

-- ============================================================================
-- 1. TAB FARM: AUTO CRATE, AUTO LEVEL UP, VARIANT TOKEN
-- ============================================================================
createSectionHeader("1. Auto Crate Farm", PageFarm)
createToggle("⚡ Auto Full Crate Cycle (Jeda 10s)", "AutoFullCrateCycle", nil, PageFarm)

createSectionHeader("2. Auto Level Up Base Cards", PageFarm)
createToggle("⭐ Auto Level Up (Kartu Base)", "AutoLevelUp", nil, PageFarm)
createTextBox("🎯 Target Level Up:", "TargetCardLevel", 35, PageFarm)

createSectionHeader("3. Variant Token Collector", PageFarm)
createToggle("🔮 Auto Teleport Token & Pasti Balik", "AutoCollectTokens", nil, PageFarm)

-- ============================================================================
-- MODAL POPUP SUB-MENU: FILTER MUTASI PER PACK (FLOATING POPUP)
-- ============================================================================
local MutationModal = Instance.new("Frame")
MutationModal.Name = "MutationModal"
MutationModal.Size = UDim2.new(0, 310, 0, 290)
MutationModal.Position = UDim2.new(0.5, -155, 0.5, -145)
MutationModal.BackgroundColor3 = Color3.fromRGB(15, 17, 26)
MutationModal.BorderSizePixel = 0
MutationModal.Visible = false
MutationModal.ZIndex = 50
MutationModal.Parent = ScreenGui

local modalCorner = Instance.new("UICorner")
modalCorner.CornerRadius = UDim.new(0, 10)
modalCorner.Parent = MutationModal

local modalStroke = Instance.new("UIStroke")
modalStroke.Color = Color3.fromRGB(65, 120, 230)
modalStroke.Thickness = 1.5
modalStroke.Parent = MutationModal

local modalTopBar = Instance.new("Frame")
modalTopBar.Size = UDim2.new(1, 0, 0, 32)
modalTopBar.BackgroundColor3 = Color3.fromRGB(22, 26, 38)
modalTopBar.BorderSizePixel = 0
modalTopBar.ZIndex = 51
modalTopBar.Parent = MutationModal

local mtCorner = Instance.new("UICorner")
mtCorner.CornerRadius = UDim.new(0, 10)
mtCorner.Parent = modalTopBar

makeDraggable(modalTopBar, MutationModal)

local modalTitle = Instance.new("TextLabel")
modalTitle.Size = UDim2.new(1, -60, 1, 0)
modalTitle.Position = UDim2.new(0, 10, 0, 0)
modalTitle.BackgroundTransparency = 1
modalTitle.Text = "⚙️ <b>MUTASI:</b> ROMCOM PACK"
modalTitle.RichText = true
modalTitle.TextColor3 = Color3.fromRGB(240, 240, 255)
modalTitle.TextSize = 11
modalTitle.Font = Enum.Font.GothamBold
modalTitle.TextXAlignment = Enum.TextXAlignment.Left
modalTitle.ZIndex = 52
modalTitle.Parent = modalTopBar

local modalCloseBtn = Instance.new("TextButton")
modalCloseBtn.Size = UDim2.new(0, 22, 0, 22)
modalCloseBtn.Position = UDim2.new(1, -27, 0, 5)
modalCloseBtn.BackgroundColor3 = Color3.fromRGB(210, 50, 65)
modalCloseBtn.Text = "✕"
modalCloseBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
modalCloseBtn.Font = Enum.Font.GothamBold
modalCloseBtn.TextSize = 10
modalCloseBtn.ZIndex = 52
modalCloseBtn.Parent = modalTopBar

local mcCorner = Instance.new("UICorner")
mcCorner.CornerRadius = UDim.new(0, 5)
mcCorner.Parent = modalCloseBtn

local modalSubTitle = Instance.new("TextLabel")
modalSubTitle.Size = UDim2.new(1, -16, 0, 14)
modalSubTitle.Position = UDim2.new(0, 8, 0, 36)
modalSubTitle.BackgroundTransparency = 1
modalSubTitle.Text = "Pilih mutasi yang diizinkan untuk dibeli:"
modalSubTitle.TextColor3 = Color3.fromRGB(140, 150, 175)
modalSubTitle.Font = Enum.Font.GothamMedium
modalSubTitle.TextSize = 9
modalSubTitle.TextXAlignment = Enum.TextXAlignment.Left
modalSubTitle.ZIndex = 51
modalSubTitle.Parent = MutationModal

local mPresetRow = Instance.new("Frame")
mPresetRow.Size = UDim2.new(1, -16, 0, 22)
mPresetRow.Position = UDim2.new(0, 8, 0, 52)
mPresetRow.BackgroundTransparency = 1
mPresetRow.ZIndex = 51
mPresetRow.Parent = MutationModal

local mPresetLayout = Instance.new("UIListLayout")
mPresetLayout.FillDirection = Enum.FillDirection.Horizontal
mPresetLayout.SortOrder = Enum.SortOrder.LayoutOrder
mPresetLayout.Padding = UDim.new(0, 4)
mPresetLayout.Parent = mPresetRow

local mGridScroll = Instance.new("ScrollingFrame")
mGridScroll.Size = UDim2.new(1, -16, 1, -114)
mGridScroll.Position = UDim2.new(0, 8, 0, 78)
mGridScroll.BackgroundTransparency = 1
mGridScroll.BorderSizePixel = 0
mGridScroll.ScrollBarThickness = 3
mGridScroll.ScrollBarImageColor3 = Color3.fromRGB(65, 120, 230)
mGridScroll.CanvasSize = UDim2.new(0, 0, 0, 190)
mGridScroll.ZIndex = 51
mGridScroll.Parent = MutationModal

local mGridLayout = Instance.new("UIGridLayout")
mGridLayout.CellSize = UDim2.new(0.5, -3, 0, 24)
mGridLayout.CellPadding = UDim2.new(0, 4, 0, 4)
mGridLayout.Parent = mGridScroll

local mDoneBtn = Instance.new("TextButton")
mDoneBtn.Size = UDim2.new(1, -16, 0, 26)
mDoneBtn.Position = UDim2.new(0, 8, 1, -30)
mDoneBtn.BackgroundColor3 = Color3.fromRGB(45, 170, 85)
mDoneBtn.Text = "✓ SIMPAN & SELESAI"
mDoneBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
mDoneBtn.Font = Enum.Font.GothamBold
mDoneBtn.TextSize = 10
mDoneBtn.ZIndex = 52
mDoneBtn.Parent = MutationModal

local mdCorner = Instance.new("UICorner")
mdCorner.CornerRadius = UDim.new(0, 6)
mdCorner.Parent = mDoneBtn

local currentModalPack = nil
local variantButtons = {}
local packButtons = {}

local function updateVariantButtonsVisual()
    if not currentModalPack then return end
    local varCfg = getPackVariantConfig(currentModalPack)
    for vName, btn in pairs(variantButtons) do
        local isAllowed = varCfg[vName] == true
        local mult = VariantMultipliers[vName] or ""
        btn.BackgroundColor3 = isAllowed and Color3.fromRGB(32, 65, 120) or Color3.fromRGB(24, 28, 38)
        btn.TextColor3 = isAllowed and (VariantColors[vName] or Color3.fromRGB(255, 255, 255)) or Color3.fromRGB(110, 115, 130)
        btn.Text = string.format("%s %s (%s)", isAllowed and "✓" or "✗", vName, mult)
    end
end

local function updatePacksVisual()
    for pName, btns in pairs(packButtons) do
        local isSel = Config.SelectedPacks[pName] == true
        local isCustom = hasCustomVariantFilter(pName)
        btns.Chip.BackgroundColor3 = isSel and Color3.fromRGB(32, 70, 130) or Color3.fromRGB(26, 30, 40)
        btns.Chip.TextColor3 = isSel and (PackColors[pName] or Color3.fromRGB(255, 255, 255)) or Color3.fromRGB(120, 130, 150)
        btns.Chip.Text = (isSel and "✓ " or "") .. pName
        
        btns.Gear.BackgroundColor3 = isCustom and Color3.fromRGB(85, 45, 130) or Color3.fromRGB(30, 35, 48)
        btns.Gear.TextColor3 = isCustom and Color3.fromRGB(255, 215, 0) or Color3.fromRGB(180, 190, 215)
        btns.Gear.Text = isCustom and "⚙️*" or "⚙️"
    end
    saveConfig()
end

local function createModalPreset(name, width, onClick)
    local btn = Instance.new("TextButton")
    btn.Size = UDim2.new(0, width, 1, 0)
    btn.BackgroundColor3 = Color3.fromRGB(30, 36, 50)
    btn.Text = name
    btn.TextColor3 = Color3.fromRGB(200, 215, 240)
    btn.Font = Enum.Font.GothamBold
    btn.TextSize = 8.5
    btn.ZIndex = 52
    btn.Parent = mPresetRow

    local c = Instance.new("UICorner")
    c.CornerRadius = UDim.new(0, 4)
    c.Parent = btn

    btn.Activated:Connect(function()
        if not currentModalPack then return end
        onClick()
        updateVariantButtonsVisual()
        saveConfig()
    end)
end

createModalPreset("Semua", 60, function()
    local varCfg = getPackVariantConfig(currentModalPack)
    for _, v in ipairs(AllVariantNames) do varCfg[v] = true end
end)

createModalPreset("No Normal", 76, function()
    local varCfg = getPackVariantConfig(currentModalPack)
    for _, v in ipairs(AllVariantNames) do varCfg[v] = (v ~= "Normal") end
end)

createModalPreset("Gold+", 56, function()
    local varCfg = getPackVariantConfig(currentModalPack)
    for _, v in ipairs(AllVariantNames) do varCfg[v] = (v ~= "Normal") end
end)

createModalPreset("Diamond+", 76, function()
    local varCfg = getPackVariantConfig(currentModalPack)
    for _, v in ipairs(AllVariantNames) do varCfg[v] = (v ~= "Normal" and v ~= "Gold") end
end)

for _, vName in ipairs(AllVariantNames) do
    local btn = Instance.new("TextButton")
    btn.Size = UDim2.new(1, 0, 1, 0)
    btn.BackgroundColor3 = Color3.fromRGB(32, 65, 120)
    btn.Text = "✓ " .. vName .. " (" .. (VariantMultipliers[vName] or "") .. ")"
    btn.TextColor3 = VariantColors[vName] or Color3.fromRGB(255, 255, 255)
    btn.Font = Enum.Font.GothamBold
    btn.TextSize = 8.5
    btn.ZIndex = 52
    btn.Parent = mGridScroll

    local bCorner = Instance.new("UICorner")
    bCorner.CornerRadius = UDim.new(0, 4)
    bCorner.Parent = btn

    btn.Activated:Connect(function()
        if not currentModalPack then return end
        local varCfg = getPackVariantConfig(currentModalPack)
        varCfg[vName] = not varCfg[vName]
        updateVariantButtonsVisual()
        saveConfig()
    end)

    variantButtons[vName] = btn
end

local function closeMutationModal()
    MutationModal.Visible = false
    updatePacksVisual()
    saveConfig()
end

modalCloseBtn.Activated:Connect(closeMutationModal)
mDoneBtn.Activated:Connect(closeMutationModal)

local function openMutationModal(packName)
    currentModalPack = packName
    local packColor = PackColors[packName] or Color3.fromRGB(255, 255, 255)
    local hexColor = string.format("#%02X%02X%02X", math.floor(packColor.R * 255), math.floor(packColor.G * 255), math.floor(packColor.B * 255))
    modalTitle.Text = string.format("⚙️ <b>MUTASI:</b> <font color=\"%s\">%s</font>", hexColor, packName:upper())
    getPackVariantConfig(packName)
    updateVariantButtonsVisual()
    MutationModal.Visible = true
end

-- ============================================================================
-- 2. TAB ROLL & BUY: AUTO ROLL, PERMANENT PACK GRID & ⚙️ MUTASI
-- ============================================================================
createSectionHeader("Conveyor Roll & Smart Buy", PageRoll)
createToggle("🎰 Auto Roll & Auto Buy [Key: Q]", "AutoRoll", function(state)
    if state then resetAutoRollState() end
end, PageRoll)

createSectionHeader("Filter Pack Dibeli & Mutasi (⚙️)", PageRoll)

local actionRow = Instance.new("Frame")
actionRow.Size = UDim2.new(1, 0, 0, 22)
actionRow.BackgroundTransparency = 1
actionRow.Parent = PageRoll

local function createPresetBtn(text, posX, width, onClick)
    local btn = Instance.new("TextButton")
    btn.Size = UDim2.new(0, width, 1, 0)
    btn.Position = UDim2.new(0, posX, 0, 0)
    btn.BackgroundColor3 = Color3.fromRGB(32, 38, 52)
    btn.Text = text
    btn.TextColor3 = Color3.fromRGB(200, 210, 230)
    btn.Font = Enum.Font.GothamBold
    btn.TextSize = 9
    btn.Parent = actionRow
    
    local c = Instance.new("UICorner")
    c.CornerRadius = UDim.new(0, 4)
    c.Parent = btn

    btn.Activated:Connect(onClick)
end

createPresetBtn("Pilih Semua", 0, 80, function()
    for _, p in ipairs(AllPackNames) do Config.SelectedPacks[p] = true end
    updatePacksVisual()
end)

createPresetBtn("6 Pertama", 86, 75, function()
    for idx, p in ipairs(AllPackNames) do Config.SelectedPacks[p] = (idx <= 6) end
    updatePacksVisual()
end)

createPresetBtn("Reset", 167, 55, function()
    for _, p in ipairs(AllPackNames) do Config.SelectedPacks[p] = false end
    updatePacksVisual()
end)

-- Dedicated Scroll Frame for 16 Packs (Fixed CanvasSize, always scrollable!)
local packScroll = Instance.new("ScrollingFrame")
packScroll.Name = "PackScroll"
packScroll.Size = UDim2.new(1, 0, 1, -110)
packScroll.BackgroundTransparency = 1
packScroll.BorderSizePixel = 0
packScroll.ScrollBarThickness = 3
packScroll.ScrollBarImageColor3 = Color3.fromRGB(65, 120, 230)
packScroll.CanvasSize = UDim2.new(0, 0, 0, 225)
packScroll.Parent = PageRoll

local gridLayout = Instance.new("UIGridLayout")
gridLayout.CellSize = UDim2.new(0.5, -4, 0, 24)
gridLayout.CellPadding = UDim2.new(0, 4, 0, 4)
gridLayout.Parent = packScroll

for _, pName in ipairs(AllPackNames) do
    local isSel = Config.SelectedPacks[pName] == true
    local isCustom = hasCustomVariantFilter(pName)

    local slot = Instance.new("Frame")
    slot.Name = "Slot_" .. pName
    slot.Size = UDim2.new(1, 0, 1, 0)
    slot.BackgroundTransparency = 1
    slot.Parent = packScroll

    local chip = Instance.new("TextButton")
    chip.Size = UDim2.new(1, -25, 1, 0)
    chip.Position = UDim2.new(0, 0, 0, 0)
    chip.BackgroundColor3 = isSel and Color3.fromRGB(32, 70, 130) or Color3.fromRGB(26, 30, 40)
    chip.Text = (isSel and "✓ " or "") .. pName
    chip.TextColor3 = isSel and (PackColors[pName] or Color3.fromRGB(255, 255, 255)) or Color3.fromRGB(120, 130, 150)
    chip.Font = Enum.Font.GothamBold
    chip.TextSize = 8.5
    chip.Parent = slot

    local chipCorner = Instance.new("UICorner")
    chipCorner.CornerRadius = UDim.new(0, 5)
    chipCorner.Parent = chip

    local gearBtn = Instance.new("TextButton")
    gearBtn.Size = UDim2.new(0, 22, 1, 0)
    gearBtn.Position = UDim2.new(1, -22, 0, 0)
    gearBtn.BackgroundColor3 = isCustom and Color3.fromRGB(85, 45, 130) or Color3.fromRGB(30, 35, 48)
    gearBtn.Text = isCustom and "⚙️*" or "⚙️"
    gearBtn.TextColor3 = isCustom and Color3.fromRGB(255, 215, 0) or Color3.fromRGB(180, 190, 215)
    gearBtn.Font = Enum.Font.GothamBold
    gearBtn.TextSize = 9
    gearBtn.Parent = slot

    local gearCorner = Instance.new("UICorner")
    gearCorner.CornerRadius = UDim.new(0, 5)
    gearCorner.Parent = gearBtn

    chip.Activated:Connect(function()
        Config.SelectedPacks[pName] = not Config.SelectedPacks[pName]
        updatePacksVisual()
    end)

    gearBtn.Activated:Connect(function()
        openMutationModal(pName)
    end)

    packButtons[pName] = {
        Chip = chip,
        Gear = gearBtn,
    }
end

-- ============================================================================
-- 3. TAB TOWER: INFINITY TOWER BATTLE (MODE, CHECKBOXES, AUTO HIDE)
-- ============================================================================
createSectionHeader("Infinity Tower Battle", PageTower)
createToggle("🏰 Auto Tower Battle (Repeat)", "AutoTower", function(state)
    if state then
        task.spawn(pcall, runTowerCycle)
    end
end, PageTower)

-- Mode Selector: Single vs Rotate
local modeFrame = Instance.new("Frame")
modeFrame.Size = UDim2.new(1, 0, 0, 28)
modeFrame.BackgroundColor3 = Color3.fromRGB(22, 26, 36)
modeFrame.Parent = PageTower

local modeCorner = Instance.new("UICorner")
modeCorner.CornerRadius = UDim.new(0, 6)
modeCorner.Parent = modeFrame

local modeStroke = Instance.new("UIStroke")
modeStroke.Color = Color3.fromRGB(35, 42, 58)
modeStroke.Thickness = 1
modeStroke.Parent = modeFrame

local modeLabel = Instance.new("TextLabel")
modeLabel.Size = UDim2.new(0, 90, 1, 0)
modeLabel.Position = UDim2.new(0, 8, 0, 0)
modeLabel.BackgroundTransparency = 1
modeLabel.Text = "Mode Battle:"
modeLabel.TextColor3 = Color3.fromRGB(180, 190, 215)
modeLabel.Font = Enum.Font.GothamMedium
modeLabel.TextSize = 10
modeLabel.TextXAlignment = Enum.TextXAlignment.Left
modeLabel.Active = false
modeLabel.Parent = modeFrame

local singleBtn = Instance.new("TextButton")
singleBtn.Size = UDim2.new(0, 85, 0, 20)
singleBtn.Position = UDim2.new(1, -180, 0.5, -10)
singleBtn.BackgroundColor3 = Config.TowerMode == "Single" and Color3.fromRGB(65, 120, 230) or Color3.fromRGB(32, 38, 52)
singleBtn.Text = "Single"
singleBtn.TextColor3 = Config.TowerMode == "Single" and Color3.fromRGB(255, 255, 255) or Color3.fromRGB(150, 160, 185)
singleBtn.Font = Enum.Font.GothamBold
singleBtn.TextSize = 9
singleBtn.Parent = modeFrame

local singleCorner = Instance.new("UICorner")
singleCorner.CornerRadius = UDim.new(0, 5)
singleCorner.Parent = singleBtn

local rotateBtn = Instance.new("TextButton")
rotateBtn.Size = UDim2.new(0, 85, 0, 20)
rotateBtn.Position = UDim2.new(1, -90, 0.5, -10)
rotateBtn.BackgroundColor3 = Config.TowerMode == "Rotate" and Color3.fromRGB(65, 120, 230) or Color3.fromRGB(32, 38, 52)
rotateBtn.Text = "Rotate"
rotateBtn.TextColor3 = Config.TowerMode == "Rotate" and Color3.fromRGB(255, 255, 255) or Color3.fromRGB(150, 160, 185)
rotateBtn.Font = Enum.Font.GothamBold
rotateBtn.TextSize = 9
rotateBtn.Parent = modeFrame

local rotateCorner = Instance.new("UICorner")
rotateCorner.CornerRadius = UDim.new(0, 5)
rotateCorner.Parent = rotateBtn

local function updateModeVisual()
    singleBtn.BackgroundColor3 = Config.TowerMode == "Single" and Color3.fromRGB(65, 120, 230) or Color3.fromRGB(32, 38, 52)
    singleBtn.TextColor3 = Config.TowerMode == "Single" and Color3.fromRGB(255, 255, 255) or Color3.fromRGB(150, 160, 185)
    
    rotateBtn.BackgroundColor3 = Config.TowerMode == "Rotate" and Color3.fromRGB(65, 120, 230) or Color3.fromRGB(32, 38, 52)
    rotateBtn.TextColor3 = Config.TowerMode == "Rotate" and Color3.fromRGB(255, 255, 255) or Color3.fromRGB(150, 160, 185)
    saveConfig()
end

singleBtn.Activated:Connect(function()
    Config.TowerMode = "Single"
    updateModeVisual()
end)

rotateBtn.Activated:Connect(function()
    Config.TowerMode = "Rotate"
    updateModeVisual()
end)

-- Checkboxes for 3 Towers
local towerCheckListFrame = Instance.new("Frame")
towerCheckListFrame.Size = UDim2.new(1, 0, 0, 82)
towerCheckListFrame.BackgroundTransparency = 1
towerCheckListFrame.Parent = PageTower

local tListLayout = Instance.new("UIListLayout")
tListLayout.SortOrder = Enum.SortOrder.LayoutOrder
tListLayout.Padding = UDim.new(0, 3)
tListLayout.Parent = towerCheckListFrame

for _, tId in ipairs(TowerOrder) do
    local isChecked = Config.SelectedTowers[tId] == true
    
    local tFrame = Instance.new("Frame")
    tFrame.Size = UDim2.new(1, 0, 0, 24)
    tFrame.BackgroundColor3 = Color3.fromRGB(22, 26, 36)
    tFrame.Parent = towerCheckListFrame

    local tfCorner = Instance.new("UICorner")
    tfCorner.CornerRadius = UDim.new(0, 5)
    tfCorner.Parent = tFrame

    local tfStroke = Instance.new("UIStroke")
    tfStroke.Color = Color3.fromRGB(35, 42, 58)
    tfStroke.Thickness = 1
    tfStroke.Parent = tFrame

    local tLbl = Instance.new("TextLabel")
    tLbl.Size = UDim2.new(1, -60, 1, 0)
    tLbl.Position = UDim2.new(0, 8, 0, 0)
    tLbl.BackgroundTransparency = 1
    tLbl.Text = TowerDisplayNames[tId] or tId
    tLbl.TextColor3 = Color3.fromRGB(225, 230, 240)
    tLbl.Font = Enum.Font.GothamMedium
    tLbl.TextSize = 9.5
    tLbl.TextXAlignment = Enum.TextXAlignment.Left
    tLbl.Active = false
    tLbl.Parent = tFrame

    local tCheck = Instance.new("TextButton")
    tCheck.Size = UDim2.new(0, 50, 0, 18)
    tCheck.Position = UDim2.new(1, -55, 0.5, -9)
    tCheck.BackgroundColor3 = isChecked and Color3.fromRGB(65, 120, 230) or Color3.fromRGB(32, 38, 52)
    tCheck.Text = isChecked and "✓ ON" or "OFF"
    tCheck.TextColor3 = Color3.fromRGB(255, 255, 255)
    tCheck.Font = Enum.Font.GothamBold
    tCheck.TextSize = 8.5
    tCheck.Parent = tFrame

    local tcCorner = Instance.new("UICorner")
    tcCorner.CornerRadius = UDim.new(0, 4)
    tcCorner.Parent = tCheck

    tCheck.Activated:Connect(function()
        Config.SelectedTowers[tId] = not Config.SelectedTowers[tId]
        local nowState = Config.SelectedTowers[tId]
        tCheck.BackgroundColor3 = nowState and Color3.fromRGB(65, 120, 230) or Color3.fromRGB(32, 38, 52)
        tCheck.Text = nowState and "✓ ON" or "OFF"
        saveConfig()
    end)
end

createToggle("👁️ Auto Hide Layar Battle", "AutoHideTowerBattle", nil, PageTower)

-- Inisialisasi Tampilan & Tab Awal
updatePacksVisual()
switchTab("Farm")

print("✅ Card & Crate Tycoon All-In-One (V2 Tab UI) Loaded Successfully!")
