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

-- Modul Game & Services dengan Safe Dynamic Getters (Kompatibel Delta & PC)
local BoxService = nil
local function getBoxService()
    if not BoxService then
        pcall(function()
            local s = ReplicatedStorage:FindFirstChild("Shared") and ReplicatedStorage.Shared:FindFirstChild("Services")
            if s and s:FindFirstChild("BoxService") then
                BoxService = require(s.BoxService)
            else
                for _, desc in ipairs(ReplicatedStorage:GetDescendants()) do
                    if desc.Name == "BoxService" and desc:IsA("ModuleScript") then
                        BoxService = require(desc)
                        break
                    end
                end
            end
        end)
    end
    return BoxService
end

local PlayerUnitService = nil
local function getPlayerUnitService()
    if not PlayerUnitService then
        pcall(function()
            local s = ReplicatedStorage:FindFirstChild("Shared") and ReplicatedStorage.Shared:FindFirstChild("Services")
            if s and s:FindFirstChild("PlayerUnitService") then
                PlayerUnitService = require(s.PlayerUnitService)
            else
                for _, desc in ipairs(ReplicatedStorage:GetDescendants()) do
                    if desc.Name == "PlayerUnitService" and desc:IsA("ModuleScript") then
                        PlayerUnitService = require(desc)
                        break
                    end
                end
            end
        end)
    end
    return PlayerUnitService
end

local CurrencyService = nil
local function getCurrencyService()
    if not CurrencyService then
        pcall(function()
            local s = ReplicatedStorage:FindFirstChild("Shared") and ReplicatedStorage.Shared:FindFirstChild("Services")
            if s and s:FindFirstChild("CurrencyService") then
                CurrencyService = require(s.CurrencyService)
            else
                for _, desc in ipairs(ReplicatedStorage:GetDescendants()) do
                    if desc.Name == "CurrencyService" and desc:IsA("ModuleScript") then
                        CurrencyService = require(desc)
                        break
                    end
                end
            end
        end)
    end
    return CurrencyService
end

local ClientDataManager = nil
local function getClientDataManager()
    if not ClientDataManager then
        pcall(function()
            local c = ReplicatedStorage:FindFirstChild("Client") and ReplicatedStorage.Client:FindFirstChild("Data")
            if c and c:FindFirstChild("ClientDataManager") then
                ClientDataManager = require(c.ClientDataManager)
            else
                for _, desc in ipairs(ReplicatedStorage:GetDescendants()) do
                    if desc.Name == "ClientDataManager" and desc:IsA("ModuleScript") then
                        ClientDataManager = require(desc)
                        break
                    end
                end
            end
        end)
    end
    return ClientDataManager
end

local BoxesLibrary = nil
local function getBoxesLibrary()
    if not BoxesLibrary then
        pcall(function()
            local bMod = ReplicatedStorage:FindFirstChild("Shared")
                and ReplicatedStorage.Shared:FindFirstChild("Core")
                and ReplicatedStorage.Shared.Core:FindFirstChild("Storage")
                and ReplicatedStorage.Shared.Core.Storage:FindFirstChild("Game")
                and ReplicatedStorage.Shared.Core.Storage.Game:FindFirstChild("BoxesLibrary")
            if bMod then
                BoxesLibrary = require(bMod)
            else
                for _, desc in ipairs(ReplicatedStorage:GetDescendants()) do
                    if desc.Name == "BoxesLibrary" and desc:IsA("ModuleScript") then
                        BoxesLibrary = require(desc)
                        break
                    end
                end
            end
        end)
    end
    return BoxesLibrary
end

local InfinityTowerGuiClient = nil
pcall(function()
    InfinityTowerGuiClient = require(ReplicatedStorage.Client.Core.Gui.InfinityTowerGuiClient)
end)

-- Inisialisasi awal services jika sudah siap di memory
pcall(getBoxService)
pcall(getPlayerUnitService)
pcall(getCurrencyService)
pcall(getClientDataManager)
pcall(getBoxesLibrary)

-- Helper Parse Angka Berformat ($1.5M, $250K, $ 50,000, dll)
local function parseFormattedNumber(text)
    if not text or type(text) ~= "string" then return nil end
    local clean = text:gsub("[%$,%s]", "")
    local num, suffix = clean:match("^([%d%.]+)%s*([A-Za-z]*)$")
    if num then
        local val = tonumber(num)
        if not val then return nil end
        suffix = suffix:upper()
        if suffix == "K" then val = val * 1e3
        elseif suffix == "M" then val = val * 1e6
        elseif suffix == "B" then val = val * 1e9
        elseif suffix == "T" then val = val * 1e12
        elseif suffix == "QA" or suffix == "Q" then val = val * 1e15
        end
        return val
    end
    return nil
end

-- Deteksi Saldo Cash Pemain Multi-Source (100% Akurat)
local function getPlayerCash()
    -- 1. Cek ClientDataManager
    local cdm = getClientDataManager()
    if cdm and cdm.GetData then
        local ok, data = pcall(cdm.GetData)
        if ok and type(data) == "table" then
            if typeof(data.Cash) == "number" then return data.Cash end
            if type(data.Currencies) == "table" and typeof(data.Currencies.Cash) == "number" then
                return data.Currencies.Cash
            end
        end
    end

    -- 2. Cek CurrencyService.GetCurrency
    local cs = getCurrencyService()
    if cs and cs.GetCurrency then
        local ok, cash = pcall(cs.GetCurrency, LocalPlayer, "Cash")
        if ok and typeof(cash) == "number" then return cash end
    end

    -- 3. Cek leaderstats
    pcall(function()
        local leaderstats = LocalPlayer:FindFirstChild("leaderstats")
        if leaderstats and leaderstats:FindFirstChild("Cash") then
            local val = leaderstats.Cash.Value
            if typeof(val) == "number" then return val end
        end
    end)

    -- 4. Cek Attribute
    pcall(function()
        local cAttr = LocalPlayer:GetAttribute("Cash")
        if typeof(cAttr) == "number" then return cAttr end
    end)

    -- 5. Cek Topbar / UI Cash Label di PlayerGui
    local uiCash = nil
    pcall(function()
        if LocalPlayer:FindFirstChild("PlayerGui") then
            for _, gui in ipairs(LocalPlayer.PlayerGui:GetChildren()) do
                if gui:IsA("ScreenGui") and gui.Enabled and gui.Name ~= "CardTycoonV3Gui" then
                    for _, desc in ipairs(gui:GetDescendants()) do
                        if desc:IsA("TextLabel") and desc.Visible and desc.Text:find("%$") then
                            local n = parseFormattedNumber(desc.Text)
                            if n and n > 0 then
                                uiCash = n
                                break
                            end
                        end
                    end
                end
                if uiCash then break end
            end
        end
    end)
    if uiCash ~= nil then return uiCash end

    return nil
end

-- Ambil Harga Box Conveyor Multi-Source (BoxService -> BoxesLibrary -> UI RollStation)
local function getConveyorBoxPrice(boxNameInternal, variant)
    -- 1. Via BoxService.GetConveyorBoxPrice
    local bs = getBoxService()
    if bs and bs.GetConveyorBoxPrice then
        local ok, val = pcall(bs.GetConveyorBoxPrice, boxNameInternal, variant)
        if ok and typeof(val) == "number" and val > 0 then
            return val
        end
    end

    -- 2. Via BoxesLibrary & Multipliers
    local boxesLib = getBoxesLibrary()
    if boxesLib and boxesLib[boxNameInternal] then
        local bData = boxesLib[boxNameInternal]
        local base = bData.Price or bData.Cost or bData.ConveyorPrice
        if typeof(base) == "number" and base > 0 then
            local mults = {
                ["Normal"] = 1, ["Gold"] = 1.5, ["Diamond"] = 2, ["Jade"] = 3,
                ["Honey"] = 5, ["Rose"] = 10, ["Astral"] = 15, ["Aurora"] = 20,
                ["Starweaver"] = 30, ["Rainbow"] = 50, ["Admin"] = 75, ["Unwritten"] = 90
            }
            local m = mults[variant] or 1
            return math.floor(base * m)
        end
    end

    -- 3. Via UI / TextLabel parsing on RollStation
    local uiPrice = nil
    pcall(function()
        local myPlot = getMyPlot()
        if myPlot then
            local rs = myPlot:FindFirstChild("Systems") and myPlot.Systems:FindFirstChild("RollStation")
            if rs then
                for _, desc in ipairs(rs:GetDescendants()) do
                    if desc:IsA("TextLabel") and (desc.Name:lower():find("price") or desc.Text:find("%$")) then
                        local parsed = parseFormattedNumber(desc.Text)
                        if parsed and parsed > 0 then
                            uiPrice = parsed
                            break
                        end
                    end
                end
            end
        end
    end)
    if uiPrice and uiPrice > 0 then return uiPrice end

    return 0
end

-- Validasi Kemampuan Beli (Strict & Anti-Skip)
local function canAffordPrice(price)
    if not price or price <= 0 then
        local cur = getPlayerCash()
        if cur and cur > 0 then return true end
        return true
    end
    
    -- 1. Cek langsung via CurrencyService.CanAfford
    local cs = getCurrencyService()
    if cs and cs.CanAfford then
        local ok, res = pcall(cs.CanAfford, LocalPlayer, "Cash", price)
        if ok and typeof(res) == "boolean" then
            return res
        end
    end

    -- 2. Cek saldo via getPlayerCash()
    local currentCash = getPlayerCash()
    if currentCash ~= nil then
        return currentCash >= price
    end

    -- Jika harga > 0 dan saldo gagal terdeteksi, tolak beli demi keamanan (mencegah skip kartu target)
    return false
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




-- ============================================================================
-- KONFIGURASI PERSISTENT & AUTOSAVE (DELTA EXECUTOR & PC COMPATIBLE)
-- ============================================================================
local CONFIG_FILE = "CardTycoon_V3_2_Config.json"

local Config = {
    AutoFullCrateCycle = false,
    AutoRoll = false,
    AutoLevelUp = false,
    AutoOpenReadyCards = false,
    MaxBuyLimit = 10,
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

local function saveConfig(isManual)
    pcall(function()
        if not writefile then
            warn("⚠️ [Config] 'writefile' tidak didukung di executor ini.")
            return
        end
        local data = HttpService:JSONEncode(Config)
        writefile(CONFIG_FILE, data)
        if isManual then
            print("💾 [Card Tycoon] Semua settingan berhasil DISIMPAN ke disk (" .. CONFIG_FILE .. ")!")
        end
    end)
end

local function loadConfig()
    pcall(function()
        if not readfile then return end

        local success, data = pcall(readfile, CONFIG_FILE)
        if not success or not data or #data < 2 then
            -- Fallback coba baca dari nama config versi sebelumnya jika ada
            local oldOk, oldData = pcall(readfile, "CardTycoon_V3_Config.json")
            if oldOk and oldData and #oldData > 2 then
                success, data = oldOk, oldData
            end
        end

        if success and data and #data > 2 then
            local decSuccess, decoded = pcall(function() return HttpService:JSONDecode(data) end)
            if decSuccess and type(decoded) == "table" then
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
                print("💾 [Card Tycoon] Settingan terakhir berhasil DIMUAT dari disk (" .. CONFIG_FILE .. ")!")
            end
        else
            print("ℹ️ [Card Tycoon] File config baru dibuat untuk versi ini.")
        end
    end)
end

loadConfig()



-- Helper Mutasi Per Pack
local function getPackVariantConfig(packName)
    if not Config.PackVariants then
        Config.PackVariants = {}
    end
    if not Config.PackVariants[packName] then
        Config.PackVariants[packName] = {}
        for _, vName in ipairs(AllVariantNames) do
            Config.PackVariants[packName][vName] = false
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
local purchasedCardCount = 0

local function resetAutoRollState()
    lastPurchasedRollCount = -1
    lastSkippedRollCount = -1
    lastRollRequestTime = 0
    lastAffordLogTime = 0
    purchasedCardCount = 0
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

    local hasBoxOnConveyor = (boxNameInternal ~= nil and boxNameInternal ~= "") and (packModel ~= nil or rollCount > 0)

    -- TAHAP 1: CEK PACK DI ATAS CONVEYOR SEKARANG
    if hasBoxOnConveyor then
        local prettyName = InternalToPrettyMap[boxNameInternal] or boxNameInternal:gsub("Pack", " Pack")
        local isWanted = (Config.SelectedPacks[prettyName] == true) or (Config.SelectedPacks[boxNameInternal] == true)
        local isVariantAllowed = isVariantAllowedForPack(prettyName, variant) and isVariantAllowedForPack(boxNameInternal, variant)

        if isWanted and isVariantAllowed then
            -- Ini adalah pack target yang kita cari!
            local price = getConveyorBoxPrice(boxNameInternal, variant)
            local affordable = canAffordPrice(price)

            if not affordable then
                local myCash = getPlayerCash() or 0
                if now - lastAffordLogTime > 3.0 then
                    lastAffordLogTime = now
                    print(string.format("⏳ [Auto Roll] Uang belum cukup untuk beli %s (%s)! [Harga: $%s | Saldo: $%s]. Menahan conveyor sampai uang terkumpul...", 
                        prettyName, variant, tostring(price or 0), tostring(myCash)))
                end
                -- TAHAN CONVEYOR! Jangan roll, jangan skip, biarkan box tetap di conveyor sampai uang terkumpul!
                return
            end

            -- Uang cukup! Beli box sekarang jika belum dibeli di rollCount ini
            if rollCount ~= lastPurchasedRollCount then
                task.wait(0.2)
                local buyRemote = getRemote("PurchaseConveyorRoll")
                if buyRemote then
                    pcall(function()
                        buyRemote:FireServer(boxNameInternal, variant, price or 0)
                    end)
                end

                pcall(function()
                    for _, desc in ipairs(rollPart:GetDescendants()) do
                        if desc:IsA("ProximityPrompt") then
                            triggerPrompt(desc)
                        end
                    end
                end)

                lastPurchasedRollCount = rollCount
                purchasedCardCount = purchasedCardCount + 1
                local maxLimit = tonumber(Config.MaxBuyLimit) or 0
                local limitInfo = maxLimit > 0 and string.format(" | Beli #%d / %d", purchasedCardCount, maxLimit) or string.format(" | Total Beli: %d", purchasedCardCount)

                print(string.format("✅ [Auto Roll] SUKSES BELI: %s (%s) [Roll #%s, $%s%s]", prettyName, variant, tostring(rollCount), tostring(price or 0), limitInfo))

                if maxLimit > 0 and purchasedCardCount >= maxLimit then
                    print(string.format("🛑 [Auto Roll] BATAS MAKSIMAL TERCAPAI! Telah membeli %d kartu. Auto Roll & Buy otomatis DIMATIKAN.", purchasedCardCount))
                    Config.AutoRoll = false
                    if toggleRefs["AutoRoll"] and toggleRefs["AutoRoll"].UpdateUI then
                        toggleRefs["AutoRoll"].UpdateUI(false)
                    end
                    saveConfig()
                    return
                end

                task.wait(0.3)
            end
        else
            -- Bukan pack target atau mutasi tidak diizinkan -> Skip agar conveyor lanjut roll
            if rollCount ~= lastSkippedRollCount then
                lastSkippedRollCount = rollCount
                if isWanted and not isVariantAllowed then
                    print(string.format("⏭️ [Auto Roll] Lewati %s (%s) [Roll #%s] (Mutasi %s di-skip untuk pack ini)", prettyName, variant, tostring(rollCount), variant))
                else
                    print(string.format("⏭️ [Auto Roll] Lewati %s (%s) [Roll #%s] (Bukan target filter)", prettyName, variant, tostring(rollCount)))
                end
            end
        end
    end

    -- TAHAP 2: ROLL BARU JIKA TIDAK ADA PACK TARGET YANG MENUNGGU UANG / DIBELI
    -- JIKA DI CONVEYOR ADA PACK TARGET DAN BELUM BERHASIL DIBELI -> JANGAN SEKALI-KALI ROLL!
    if hasBoxOnConveyor then
        local prettyName = InternalToPrettyMap[boxNameInternal] or boxNameInternal:gsub("Pack", " Pack")
        local isWanted = (Config.SelectedPacks[prettyName] == true) or (Config.SelectedPacks[boxNameInternal] == true)
        local isVariantAllowed = isVariantAllowedForPack(prettyName, variant) and isVariantAllowedForPack(boxNameInternal, variant)

        if isWanted and isVariantAllowed then
            -- Pack ini adalah target! Jika belum terbeli (misal uang belum cukup), TAHAN & JANGAN ROLL!
            if rollCount ~= lastPurchasedRollCount then
                return
            end
        end
    end

    -- Cek cooldown roll station
    local cooldownUntil = rollPart:GetAttribute("RollCooldownUntil")
    if cooldownUntil and workspace:GetServerTimeNow() < cooldownUntil then
        return
    end

    if now - lastRollRequestTime < 0.7 then
        return
    end

    -- Hanya roll jika conveyor kosong ATAU pack sudah diskip / sudah dibeli
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
-- 3B. AUTO OPEN READY CARDS (PADA DROPPER BASE SAAT COUNTDOWN 0S / READY)
-- ============================================================================
local function doOpenReadyCards()
    if not Config.AutoOpenReadyCards then return end
    local myPlot = getMyPlot()
    if not myPlot then return end

    local droppers = getAllDropperParts(myPlot)
    if #droppers == 0 then return end

    local openRemote = getRemote("OpenBoxOnDropper")

    for _, dropPart in ipairs(droppers) do
        if not Config.AutoOpenReadyCards then break end

        local bType = dropPart:GetAttribute("Type")
        local boxName = dropPart:GetAttribute("BoxName")
        local placedAt = dropPart:GetAttribute("PlacedAt")
        local variant = dropPart:GetAttribute("Variant") or "Normal"
        local isUnlocked = dropPart:GetAttribute("Unlocked")

        if (bType == "Box" or boxName ~= nil) and isUnlocked ~= false then
            local isReady = false

            -- 1. Cek via BoxService.IsBoxReady
            pcall(function()
                if BoxService and BoxService.IsBoxReady then
                    isReady = BoxService.IsBoxReady(boxName, placedAt, variant)
                end
            end)

            -- 2. Cek via ProximityPrompt (Action == "Open")
            if not isReady then
                pcall(function()
                    for _, desc in ipairs(dropPart:GetDescendants()) do
                        if desc:IsA("ProximityPrompt") and desc.Enabled and desc.ActionText == "Open" then
                            isReady = true
                            break
                        end
                    end
                end)
            end

            -- 3. Cek via TimerLabel Text == "Ready"
            if not isReady then
                pcall(function()
                    for _, desc in ipairs(dropPart:GetDescendants()) do
                        if desc:IsA("TextLabel") and desc.Text == "Ready" then
                            isReady = true
                            break
                        end
                    end
                end)
            end

            if isReady then
                print(string.format("🎁 [Auto Open] Membuka kartu ready: %s (%s) di %s", tostring(boxName), tostring(variant), dropPart.Name))

                pcall(function()
                    if openRemote then
                        openRemote:InvokeServer(dropPart)
                    end
                end)

                task.wait(0.4)
            end
        end
    end
end


-- ============================================================================
-- 4. AUTO TELEPORT COLLECT ALL TOKENS & POTIONS (PASTI BALIK KE POSISI AWAL)
-- Mendukung: Trait Token, Grade Token, Luck Potion, Cash Potion, & Variant Tokens
-- ============================================================================

local function findActiveCollectable()
    local systems = Workspace:FindFirstChild("Systems")
    if not systems then return nil end

    -- 1. Cek CollectableObjects (TraitToken, GradeToken, LuckPotion, CashPotion)
    local colFolder = systems:FindFirstChild("CollectableObjects")
    if colFolder then
        for _, child in ipairs(colFolder:GetChildren()) do
            if child:GetAttribute("Occupied") == true then
                local objKey = child:GetAttribute("ObjectKey") or "Collectable"
                return {
                    Node = child,
                    Type = "Collectable",
                    Key = objKey,
                    Name = tostring(objKey)
                }
            end
        end
    end

    -- 2. Cek VariantTokenSpawns (Aurora, Admin, Unwritten, Rainbow, Starweaver)
    local varFolder = systems:FindFirstChild("VariantTokenSpawns")
    if varFolder then
        for _, child in ipairs(varFolder:GetChildren()) do
            if child:GetAttribute("Occupied") == true then
                local varName = child:GetAttribute("Variant") or "Variant"
                return {
                    Node = child,
                    Type = "VariantToken",
                    Key = varName,
                    Name = tostring(varName) .. " Token"
                }
            end
        end
    end

    -- Fallback via CollectionService tags
    for _, child in ipairs(CollectionService:GetTagged("CollectableObject")) do
        if child:GetAttribute("Occupied") == true then
            local objKey = child:GetAttribute("ObjectKey") or "Collectable"
            return {
                Node = child,
                Type = "Collectable",
                Key = objKey,
                Name = tostring(objKey)
            }
        end
    end

    for _, child in ipairs(CollectionService:GetTagged("VariantTokenSpawn")) do
        if child:GetAttribute("Occupied") == true then
            local varName = child:GetAttribute("Variant") or "Variant"
            return {
                Node = child,
                Type = "VariantToken",
                Key = varName,
                Name = tostring(varName) .. " Token"
            }
        end
    end

    return nil
end

local isCollectingItem = false
local function collectMapItem(itemData)
    if isCollectingItem then return end
    isCollectingItem = true

    local char = LocalPlayer.Character
    local hrp = char and char:FindFirstChild("HumanoidRootPart")
    if not hrp or not itemData or not itemData.Node then 
        isCollectingItem = false
        return 
    end

    local node = itemData.Node
    local returnCFrame = hrp.CFrame
    print(string.format("🔮 [Auto Collect] Menemukan %s di %s! Teleport mengambil...", tostring(itemData.Name), node.Name))

    -- 1. Teleport ke part item (jarak aman < 3 stud agar proximity check <= 5 stud tembus 100%)
    hrp.AssemblyLinearVelocity = Vector3.zero
    hrp.CFrame = CFrame.new(node.Position + Vector3.new(0, 2.0, 0))
    task.wait(0.2)

    -- 2. Tembak remote sesuai tipe
    if itemData.Type == "Collectable" then
        local rem = getRemote("CollectCollectableObject")
        if rem then
            pcall(function() rem:FireServer(node) end)
        end
    elseif itemData.Type == "VariantToken" then
        local rem = getRemote("CollectVariantTokenSpawn")
        if rem then
            pcall(function() rem:FireServer(node) end)
        end
    end

    -- 3. Tunggu sampai item terambil (Occupied = false) maksimal 2 detik
    local waitStart = os.clock()
    while os.clock() - waitStart < 2.0 do
        if not node.Parent or node:GetAttribute("Occupied") == false then
            break
        end
        task.wait(0.1)
    end

    -- 4. Teleport PASTI KEMBALI ke posisi semula sebelum teleport
    pcall(function()
        local curChar = LocalPlayer.Character
        local curHrp = curChar and curChar:FindFirstChild("HumanoidRootPart")
        if curHrp and returnCFrame then
            curHrp.AssemblyLinearVelocity = Vector3.zero
            curHrp.CFrame = returnCFrame
            task.wait(0.08)
            curHrp.CFrame = returnCFrame
            print(string.format("✅ [Auto Collect] %s berhasil diambil! Kembali ke posisi semula.", tostring(itemData.Name)))
        end
    end)

    task.wait(0.5)
    isCollectingItem = false
end

-- Listener otomatis tiap ada part yang berubah menjadi Occupied = true
pcall(function()
    local function bindSpawns(folderName)
        local f = Workspace:FindFirstChild("Systems") and Workspace.Systems:FindFirstChild(folderName)
        if f then
            for _, node in ipairs(f:GetChildren()) do
                node:GetAttributeChangedSignal("Occupied"):Connect(function()
                    if Config.AutoCollectTokens and node:GetAttribute("Occupied") == true then
                        task.wait(0.1)
                        local item = findActiveCollectable()
                        if item then
                            collectMapItem(item)
                        end
                    end
                end)
            end
        end
    end
    bindSpawns("CollectableObjects")
    bindSpawns("VariantTokenSpawns")
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


-- Auto Open Ready Cards Loop
task.spawn(function()
    while true do
        if Config.AutoOpenReadyCards then
            pcall(doOpenReadyCards)
        end
        task.wait(1.0)
    end
end)


-- All Tokens & Potions Loop
task.spawn(function()
    while true do
        if Config.AutoCollectTokens then
            local activeItem = findActiveCollectable()
            if activeItem then
                collectMapItem(activeItem)
            end
        end
        task.wait(1.0)
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
-- CARD TYCOON V3.2 - UNIFIED 4-TAB GUI (PC & DELTA EXECUTOR)
-- ============================================================================

-- Auto cleanup existing GUI so re-execution always replaces cleanly
pcall(function()
    local g = (getgenv and getgenv()) or _G
    if g and g._CardTycoonV3Cleanup then
        pcall(g._CardTycoonV3Cleanup)
    end
    local targets = {}
    if gethui then table.insert(targets, gethui()) end
    if CoreGui then table.insert(targets, CoreGui) end
    if LocalPlayer and LocalPlayer:FindFirstChild("PlayerGui") then
        table.insert(targets, LocalPlayer.PlayerGui)
    end
    for _, container in ipairs(targets) do
        for _, c in ipairs(container:GetChildren()) do
            if c.Name == "CardTycoonV3Gui" then
                pcall(function() c:Destroy() end)
            end
        end
    end
end)

local ScreenGui = Instance.new("ScreenGui")
ScreenGui.Name = "CardTycoonV3Gui"
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
if g then g._CardTycoonV3Cleanup = cleanup end

-- Universal Click / Touch Binder (Works 100% on PC, Mobile Touch, & Delta Emulator)
local function bindBtn(btn, callback)
    btn.Active = true
    btn.Selectable = true
    local lastClick = 0
    local function fire()
        local now = tick()
        if now - lastClick < 0.15 then return end
        lastClick = now
        callback()
    end
    btn.Activated:Connect(fire)
    btn.MouseButton1Click:Connect(fire)
end

-- Drag Helper
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

-- Floating Toggle Button
local FloatBtn = Instance.new("TextButton")
FloatBtn.Name = "FloatToggle"
FloatBtn.Size = UDim2.new(0, 48, 0, 48)
FloatBtn.Position = UDim2.new(0.02, 0, 0.25, 0)
FloatBtn.BackgroundColor3 = Color3.fromRGB(20, 24, 34)
FloatBtn.Text = "🃏"
FloatBtn.TextSize = 22
FloatBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
FloatBtn.Font = Enum.Font.GothamBold
FloatBtn.Parent = ScreenGui

local FloatCorner = Instance.new("UICorner")
FloatCorner.CornerRadius = UDim.new(0, 12)
FloatCorner.Parent = FloatBtn

local FloatStroke = Instance.new("UIStroke")
FloatStroke.Color = Color3.fromRGB(65, 120, 230)
FloatStroke.Thickness = 2
FloatStroke.Parent = FloatBtn

makeDraggable(FloatBtn, FloatBtn)

-- Main Frame (Spacious 560 x 380)
local MainFrame = Instance.new("Frame")
MainFrame.Name = "MainFrame"
MainFrame.Size = UDim2.new(0, 560, 0, 380)
MainFrame.Position = UDim2.new(0.5, -280, 0.5, -190)
MainFrame.BackgroundColor3 = Color3.fromRGB(16, 18, 26)
MainFrame.BorderSizePixel = 0
MainFrame.ClipsDescendants = true
MainFrame.Parent = ScreenGui

local MainCorner = Instance.new("UICorner")
MainCorner.CornerRadius = UDim.new(0, 12)
MainCorner.Parent = MainFrame

local MainStroke = Instance.new("UIStroke")
MainStroke.Color = Color3.fromRGB(45, 52, 75)
MainStroke.Thickness = 1.5
MainStroke.Parent = MainFrame

-- TopBar
local TopBar = Instance.new("Frame")
TopBar.Name = "TopBar"
TopBar.Size = UDim2.new(1, 0, 0, 40)
TopBar.BackgroundColor3 = Color3.fromRGB(22, 26, 38)
TopBar.BorderSizePixel = 0
TopBar.Parent = MainFrame

local TopBarCorner = Instance.new("UICorner")
TopBarCorner.CornerRadius = UDim.new(0, 12)
TopBarCorner.Parent = TopBar

makeDraggable(TopBar, MainFrame)

local TitleLabel = Instance.new("TextLabel")
TitleLabel.Name = "TitleLabel"
TitleLabel.Size = UDim2.new(1, -90, 1, 0)
TitleLabel.Position = UDim2.new(0, 14, 0, 0)
TitleLabel.BackgroundTransparency = 1
TitleLabel.Text = "🃏 <b>CARD TYCOON</b> <font color=\"#4A90E2\">ALL-IN-ONE v3.2</font>"
TitleLabel.RichText = true
TitleLabel.TextColor3 = Color3.fromRGB(240, 240, 255)
TitleLabel.TextSize = 14
TitleLabel.Font = Enum.Font.GothamBold
TitleLabel.TextXAlignment = Enum.TextXAlignment.Left
TitleLabel.Parent = TopBar

local CloseBtn = Instance.new("TextButton")
CloseBtn.Name = "CloseBtn"
CloseBtn.Size = UDim2.new(0, 28, 0, 28)
CloseBtn.Position = UDim2.new(1, -34, 0, 6)
CloseBtn.BackgroundColor3 = Color3.fromRGB(215, 50, 65)
CloseBtn.Text = "✕"
CloseBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
CloseBtn.Font = Enum.Font.GothamBold
CloseBtn.TextSize = 12
CloseBtn.Parent = TopBar

local CloseBtnCorner = Instance.new("UICorner")
CloseBtnCorner.CornerRadius = UDim.new(0, 6)
CloseBtnCorner.Parent = CloseBtn

local MinBtn = Instance.new("TextButton")
MinBtn.Name = "MinBtn"
MinBtn.Size = UDim2.new(0, 28, 0, 28)
MinBtn.Position = UDim2.new(1, -68, 0, 6)
MinBtn.BackgroundColor3 = Color3.fromRGB(42, 50, 70)
MinBtn.Text = "—"
MinBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
MinBtn.Font = Enum.Font.GothamBold
MinBtn.TextSize = 12
MinBtn.Parent = TopBar

local MinBtnCorner = Instance.new("UICorner")
MinBtnCorner.CornerRadius = UDim.new(0, 6)
MinBtnCorner.Parent = MinBtn

bindBtn(CloseBtn, function() MainFrame.Visible = false end)
bindBtn(MinBtn, function() MainFrame.Visible = false end)
bindBtn(FloatBtn, function() MainFrame.Visible = not MainFrame.Visible end)

-- Sidebar (Left)
local Sidebar = Instance.new("Frame")
Sidebar.Name = "Sidebar"
Sidebar.Size = UDim2.new(0, 135, 1, -40)
Sidebar.Position = UDim2.new(0, 0, 0, 40)
Sidebar.BackgroundColor3 = Color3.fromRGB(20, 23, 33)
Sidebar.BorderSizePixel = 0
Sidebar.Parent = MainFrame

local SidebarLayout = Instance.new("UIListLayout")
SidebarLayout.Padding = UDim.new(0, 6)
SidebarLayout.HorizontalAlignment = Enum.HorizontalAlignment.Center
SidebarLayout.SortOrder = Enum.SortOrder.LayoutOrder
SidebarLayout.Parent = Sidebar

local SidebarPadding = Instance.new("UIPadding")
SidebarPadding.PaddingTop = UDim.new(0, 10)
SidebarPadding.Parent = Sidebar

-- Content Container (Right)
local ContentFrame = Instance.new("Frame")
ContentFrame.Name = "ContentFrame"
ContentFrame.Size = UDim2.new(1, -145, 1, -48)
ContentFrame.Position = UDim2.new(0, 140, 0, 44)
ContentFrame.BackgroundTransparency = 1
ContentFrame.Parent = MainFrame

-- Tab System
local tabs = {}

local function createTab(name, icon, order)
    local tabBtn = Instance.new("TextButton")
    tabBtn.Name = name .. "TabBtn"
    tabBtn.Size = UDim2.new(0, 120, 0, 36)
    tabBtn.BackgroundColor3 = Color3.fromRGB(26, 30, 42)
    tabBtn.Text = icon .. "  " .. name
    tabBtn.TextColor3 = Color3.fromRGB(175, 185, 205)
    tabBtn.Font = Enum.Font.GothamBold
    tabBtn.TextSize = 11.5
    tabBtn.LayoutOrder = order
    tabBtn.Parent = Sidebar

    local btnCorner = Instance.new("UICorner")
    btnCorner.CornerRadius = UDim.new(0, 8)
    btnCorner.Parent = tabBtn

    local page = Instance.new("ScrollingFrame")
    page.Name = name .. "Page"
    page.Size = UDim2.new(1, 0, 1, 0)
    page.BackgroundTransparency = 1
    page.BorderSizePixel = 0
    page.ScrollBarThickness = 4
    page.ScrollBarImageColor3 = Color3.fromRGB(65, 120, 230)
    page.CanvasSize = UDim2.new(0, 0, 0, 500)
    page.Visible = false
    page.Parent = ContentFrame

    local pageLayout = Instance.new("UIListLayout")
    pageLayout.Padding = UDim.new(0, 8)
    pageLayout.SortOrder = Enum.SortOrder.LayoutOrder
    pageLayout.Parent = page

    local pagePadding = Instance.new("UIPadding")
    pagePadding.PaddingTop = UDim.new(0, 6)
    pagePadding.PaddingLeft = UDim.new(0, 4)
    pagePadding.PaddingRight = UDim.new(0, 8)
    pagePadding.PaddingBottom = UDim.new(0, 12)
    pagePadding.Parent = page

    pageLayout:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function()
        page.CanvasSize = UDim2.new(0, 0, 0, math.max(300, pageLayout.AbsoluteContentSize.Y + 25))
    end)

    bindBtn(tabBtn, function()
        for _, t in pairs(tabs) do
            t.Page.Visible = false
            t.Btn.BackgroundColor3 = Color3.fromRGB(26, 30, 42)
            t.Btn.TextColor3 = Color3.fromRGB(175, 185, 205)
        end
        page.Visible = true
        tabBtn.BackgroundColor3 = Color3.fromRGB(50, 105, 220)
        tabBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
    end)

    tabs[name] = {Btn = tabBtn, Page = page, Layout = pageLayout}
    return page, pageLayout
end

-- Component Helpers
local function createSectionHeader(page, title)
    local lbl = Instance.new("TextLabel")
    lbl.Size = UDim2.new(1, 0, 0, 18)
    lbl.BackgroundTransparency = 1
    lbl.Text = "— " .. title:upper() .. " —"
    lbl.TextColor3 = Color3.fromRGB(120, 145, 195)
    lbl.Font = Enum.Font.GothamBold
    lbl.TextSize = 10
    lbl.TextXAlignment = Enum.TextXAlignment.Left
    lbl.Parent = page
    return lbl
end

local function createToggle(page, labelText, configKey, callback)
    local defaultVal = Config[configKey] or false
    
    local toggleFrame = Instance.new("Frame")
    toggleFrame.Size = UDim2.new(1, 0, 0, 40)
    toggleFrame.BackgroundColor3 = Color3.fromRGB(24, 28, 40)
    toggleFrame.Parent = page

    local corner = Instance.new("UICorner")
    corner.CornerRadius = UDim.new(0, 8)
    corner.Parent = toggleFrame

    local stroke = Instance.new("UIStroke")
    stroke.Color = Color3.fromRGB(38, 46, 66)
    stroke.Thickness = 1
    stroke.Parent = toggleFrame

    local label = Instance.new("TextLabel")
    label.Size = UDim2.new(1, -70, 1, 0)
    label.Position = UDim2.new(0, 12, 0, 0)
    label.BackgroundTransparency = 1
    label.Text = labelText
    label.TextColor3 = Color3.fromRGB(230, 235, 245)
    label.Font = Enum.Font.GothamMedium
    label.TextSize = 11.5
    label.TextXAlignment = Enum.TextXAlignment.Left
    label.Active = false
    label.Parent = toggleFrame

    local switch = Instance.new("TextButton")
    switch.Size = UDim2.new(0, 48, 0, 24)
    switch.Position = UDim2.new(1, -58, 0.5, -12)
    switch.BackgroundColor3 = defaultVal and Color3.fromRGB(45, 175, 85) or Color3.fromRGB(45, 52, 68)
    switch.Text = defaultVal and "ON" or "OFF"
    switch.TextColor3 = Color3.fromRGB(255, 255, 255)
    switch.Font = Enum.Font.GothamBold
    switch.TextSize = 10
    switch.Parent = toggleFrame

    local switchCorner = Instance.new("UICorner")
    switchCorner.CornerRadius = UDim.new(0, 12)
    switchCorner.Parent = switch

    local state = defaultVal
    local function setVisualState(val)
        state = val
        switch.BackgroundColor3 = state and Color3.fromRGB(45, 175, 85) or Color3.fromRGB(45, 52, 68)
        switch.Text = state and "ON" or "OFF"
    end

    bindBtn(switch, function()
        setVisualState(not state)
        Config[configKey] = state
        if callback then callback(state) end
        saveConfig()
    end)

    toggleRefs[configKey] = {
        Frame = toggleFrame,
        UpdateUI = function(val)
            setVisualState(val)
            Config[configKey] = val
        end
    }

    return toggleFrame
end

local function createTextBox(page, labelText, configKey, defaultVal)
    local val = Config[configKey] or defaultVal
    Config[configKey] = val

    local boxFrame = Instance.new("Frame")
    boxFrame.Size = UDim2.new(1, 0, 0, 40)
    boxFrame.BackgroundColor3 = Color3.fromRGB(24, 28, 40)
    boxFrame.Parent = page

    local corner = Instance.new("UICorner")
    corner.CornerRadius = UDim.new(0, 8)
    corner.Parent = boxFrame

    local stroke = Instance.new("UIStroke")
    stroke.Color = Color3.fromRGB(38, 46, 66)
    stroke.Thickness = 1
    stroke.Parent = boxFrame

    local label = Instance.new("TextLabel")
    label.Size = UDim2.new(1, -85, 1, 0)
    label.Position = UDim2.new(0, 12, 0, 0)
    label.BackgroundTransparency = 1
    label.Text = labelText
    label.TextColor3 = Color3.fromRGB(230, 235, 245)
    label.Font = Enum.Font.GothamMedium
    label.TextSize = 11.5
    label.TextXAlignment = Enum.TextXAlignment.Left
    label.Active = false
    label.Parent = boxFrame

    local textBox = Instance.new("TextBox")
    textBox.Size = UDim2.new(0, 65, 0, 24)
    textBox.Position = UDim2.new(1, -75, 0.5, -12)
    textBox.BackgroundColor3 = Color3.fromRGB(34, 40, 56)
    textBox.Text = tostring(val)
    textBox.TextColor3 = Color3.fromRGB(255, 215, 0)
    textBox.Font = Enum.Font.GothamBold
    textBox.TextSize = 12
    textBox.ClearTextOnFocus = false
    textBox.Parent = boxFrame

    local tbCorner = Instance.new("UICorner")
    tbCorner.CornerRadius = UDim.new(0, 6)
    tbCorner.Parent = textBox

    textBox.FocusLost:Connect(function()
        local num = tonumber(textBox.Text)
        if num and num >= 0 then
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
-- TAB 1: 📦 CRATE FARM
-- ============================================================================
local FarmPage = createTab("Farm", "📦", 1)

createSectionHeader(FarmPage, "Auto Crate Cycle (100% Work)")
createToggle(FarmPage, "⚡ Auto Full Crate Cycle (Jeda 10s)", "AutoFullCrateCycle")

local runOnceBtn = Instance.new("TextButton")
runOnceBtn.Size = UDim2.new(1, 0, 0, 36)
runOnceBtn.BackgroundColor3 = Color3.fromRGB(40, 110, 210)
runOnceBtn.Text = "🔄 Jalankan 1x Siklus Crate Sekarang"
runOnceBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
runOnceBtn.Font = Enum.Font.GothamBold
runOnceBtn.TextSize = 11.5
runOnceBtn.Parent = FarmPage

local roCorner = Instance.new("UICorner")
roCorner.CornerRadius = UDim.new(0, 8)
roCorner.Parent = runOnceBtn

bindBtn(runOnceBtn, function()
    task.spawn(pcall, runSingleCycle)
end)

local farmDesc = Instance.new("TextLabel")
farmDesc.Size = UDim2.new(1, 0, 0, 50)
farmDesc.BackgroundTransparency = 1
farmDesc.Text = "ℹ️ Fitur ini otomatis mengambil crate, teleport ke conveyor plot, menunggu conveyor selesai, dan menekan tombol unboxing dengan jeda 10 detik per cycle."
farmDesc.TextColor3 = Color3.fromRGB(140, 155, 185)
farmDesc.Font = Enum.Font.Gotham
farmDesc.TextSize = 10
farmDesc.TextWrapped = true
farmDesc.TextXAlignment = Enum.TextXAlignment.Left
farmDesc.Parent = FarmPage

-- ============================================================================
-- TAB 2: 🎰 ROLL & BUY (ALL-IN-ONE: PACK & FILTER MUTASI JADI SATU!)
-- ============================================================================
local RollPage, RollLayout = createTab("Roll & Buy", "🎰", 2)

createSectionHeader(RollPage, "Conveyor Roll")
createToggle(RollPage, "🎰 Auto Roll & Auto Buy [Key: Q]", "AutoRoll", function(state)
    if state then resetAutoRollState() end
end)

local rollDesc = Instance.new("TextLabel")
rollDesc.Size = UDim2.new(1, 0, 0, 26)
rollDesc.BackgroundTransparency = 1
rollDesc.Text = "💡 Shortcut Q untuk ON/OFF. Jika uang kurang, roll jeda dan otomatis beli saat saldo cukup!"
rollDesc.TextColor3 = Color3.fromRGB(150, 165, 195)
rollDesc.Font = Enum.Font.GothamMedium
rollDesc.TextSize = 9.5
rollDesc.TextWrapped = true
rollDesc.TextXAlignment = Enum.TextXAlignment.Left
rollDesc.Parent = RollPage

createTextBox(RollPage, "🎯 Batas Maksimal Buy (0 = Bebas):", "MaxBuyLimit", 10)

local limitDesc = Instance.new("TextLabel")
limitDesc.Size = UDim2.new(1, 0, 0, 24)
limitDesc.BackgroundTransparency = 1
limitDesc.Text = "ℹ️ Jika diisi angka (misal 10), setelah berhasil membeli 10 kartu, Auto Roll otomatis OFF."
limitDesc.TextColor3 = Color3.fromRGB(140, 155, 185)
limitDesc.Font = Enum.Font.Gotham
limitDesc.TextSize = 9.5
limitDesc.TextWrapped = true
limitDesc.TextXAlignment = Enum.TextXAlignment.Left
limitDesc.Parent = RollPage

createSectionHeader(RollPage, "Pilih Pack Dibeli & Filter Mutasi Langsung:")

local rollPresetBar = Instance.new("Frame")
rollPresetBar.Size = UDim2.new(1, 0, 0, 26)
rollPresetBar.BackgroundTransparency = 1
rollPresetBar.Parent = RollPage

local rollPresetLayout = Instance.new("UIListLayout")
rollPresetLayout.FillDirection = Enum.FillDirection.Horizontal
rollPresetLayout.SortOrder = Enum.SortOrder.LayoutOrder
rollPresetLayout.Padding = UDim.new(0, 6)
rollPresetLayout.Parent = rollPresetBar

local packCards = {}

local function updateAllPacksVisual()
    for pName, data in pairs(packCards) do
        local isSel = Config.SelectedPacks[pName] == true
        data.BuyBtn.BackgroundColor3 = isSel and Color3.fromRGB(45, 175, 85) or Color3.fromRGB(45, 52, 68)
        data.BuyBtn.Text = isSel and "✓ BELI" or "OFF"
        
        -- Update variant chips visual with accurate multipliers
        local varCfg = getPackVariantConfig(pName)
        for vName, vBtn in pairs(data.VariantBtns) do
            local allowed = varCfg[vName] == true
            local mult = VariantMultipliers[vName] or ""
            vBtn.BackgroundColor3 = allowed and Color3.fromRGB(35, 75, 140) or Color3.fromRGB(24, 28, 40)
            vBtn.TextColor3 = allowed and (VariantColors[vName] or Color3.fromRGB(255, 255, 255)) or Color3.fromRGB(105, 115, 130)
            vBtn.Text = string.format("%s %s (%s)", allowed and "✓" or "✗", vName, mult)
        end
    end
    saveConfig()
end

local function createPresetBtn(text, width, callback)
    local btn = Instance.new("TextButton")
    btn.Size = UDim2.new(0, width, 1, 0)
    btn.BackgroundColor3 = Color3.fromRGB(34, 40, 56)
    btn.Text = text
    btn.TextColor3 = Color3.fromRGB(220, 230, 250)
    btn.Font = Enum.Font.GothamBold
    btn.TextSize = 10
    btn.Parent = rollPresetBar

    local c = Instance.new("UICorner")
    c.CornerRadius = UDim.new(0, 6)
    c.Parent = btn

    bindBtn(btn, callback)
end

createPresetBtn("Semua: Beli", 85, function()
    for _, p in ipairs(AllPackNames) do Config.SelectedPacks[p] = true end
    updateAllPacksVisual()
end)

createPresetBtn("6 Pertama", 75, function()
    for idx, p in ipairs(AllPackNames) do Config.SelectedPacks[p] = (idx <= 6) end
    updateAllPacksVisual()
end)

createPresetBtn("Reset Beli", 75, function()
    for _, p in ipairs(AllPackNames) do Config.SelectedPacks[p] = false end
    updateAllPacksVisual()
end)

-- List of 16 Unified Pack Cards
for _, pName in ipairs(AllPackNames) do
    local isSel = Config.SelectedPacks[pName] == true
    local pColor = PackColors[pName] or Color3.fromRGB(255, 255, 255)

    local card = Instance.new("Frame")
    card.Name = "Card_" .. pName
    card.Size = UDim2.new(1, 0, 0, 36)
    card.BackgroundColor3 = Color3.fromRGB(22, 26, 38)
    card.ClipsDescendants = true
    card.Parent = RollPage

    local cCorner = Instance.new("UICorner")
    cCorner.CornerRadius = UDim.new(0, 8)
    cCorner.Parent = card

    local cStroke = Instance.new("UIStroke")
    cStroke.Color = Color3.fromRGB(38, 46, 66)
    cStroke.Thickness = 1
    cStroke.Parent = card

    -- Main Row
    local buyBtn = Instance.new("TextButton")
    buyBtn.Size = UDim2.new(0, 55, 0, 24)
    buyBtn.Position = UDim2.new(0, 6, 0, 6)
    buyBtn.BackgroundColor3 = isSel and Color3.fromRGB(45, 175, 85) or Color3.fromRGB(45, 52, 68)
    buyBtn.Text = isSel and "✓ BELI" or "OFF"
    buyBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
    buyBtn.Font = Enum.Font.GothamBold
    buyBtn.TextSize = 9.5
    buyBtn.Parent = card

    local bbCorner = Instance.new("UICorner")
    bbCorner.CornerRadius = UDim.new(0, 6)
    bbCorner.Parent = buyBtn

    local titleLbl = Instance.new("TextLabel")
    titleLbl.Size = UDim2.new(0, 100, 0, 24)
    titleLbl.Position = UDim2.new(0, 66, 0, 6)
    titleLbl.BackgroundTransparency = 1
    titleLbl.Text = pName
    titleLbl.TextColor3 = pColor
    titleLbl.Font = Enum.Font.GothamBold
    titleLbl.TextSize = 10.5
    titleLbl.TextXAlignment = Enum.TextXAlignment.Left
    titleLbl.Active = false
    titleLbl.Parent = card

    -- Quick Mutasi Presets on the Right
    local function createQuickMutBtn(text, posX, width, onClick)
        local btn = Instance.new("TextButton")
        btn.Size = UDim2.new(0, width, 0, 24)
        btn.Position = UDim2.new(0, posX, 0, 6)
        btn.BackgroundColor3 = Color3.fromRGB(32, 38, 54)
        btn.Text = text
        btn.TextColor3 = Color3.fromRGB(200, 215, 240)
        btn.Font = Enum.Font.GothamBold
        btn.TextSize = 9
        btn.Parent = card

        local bCorner = Instance.new("UICorner")
        bCorner.CornerRadius = UDim.new(0, 5)
        bCorner.Parent = btn

        bindBtn(btn, function()
            onClick()
            updateAllPacksVisual()
        end)
        return btn
    end

    createQuickMutBtn("Semua", 172, 44, function()
        local varCfg = getPackVariantConfig(pName)
        for _, v in ipairs(AllVariantNames) do varCfg[v] = true end
    end)

    createQuickMutBtn("No Norm", 220, 52, function()
        local varCfg = getPackVariantConfig(pName)
        for _, v in ipairs(AllVariantNames) do varCfg[v] = (v ~= "Normal") end
    end)

    createQuickMutBtn("Gold+", 276, 44, function()
        local varCfg = getPackVariantConfig(pName)
        for _, v in ipairs(AllVariantNames) do varCfg[v] = (v ~= "Normal") end
    end)

    createQuickMutBtn("Dia+", 324, 40, function()
        local varCfg = getPackVariantConfig(pName)
        for _, v in ipairs(AllVariantNames) do varCfg[v] = (v ~= "Normal" and v ~= "Gold") end
    end)

    -- Toggle Drawer Detail Mutasi (⚙️)
    local gearBtn = Instance.new("TextButton")
    gearBtn.Size = UDim2.new(0, 28, 0, 24)
    gearBtn.Position = UDim2.new(0, 368, 0, 6)
    gearBtn.BackgroundColor3 = Color3.fromRGB(42, 48, 68)
    gearBtn.Text = "⚙️"
    gearBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
    gearBtn.Font = Enum.Font.GothamBold
    gearBtn.TextSize = 10
    gearBtn.Parent = card

    local gCorner = Instance.new("UICorner")
    gCorner.CornerRadius = UDim.new(0, 5)
    gCorner.Parent = gearBtn

    -- Drawer Detail Mutasi Container (3 Columns, Spacious, Shows Multiplier!)
    local drawer = Instance.new("Frame")
    drawer.Size = UDim2.new(1, -12, 0, 114)
    drawer.Position = UDim2.new(0, 6, 0, 34)
    drawer.BackgroundTransparency = 1
    drawer.Visible = false
    drawer.Parent = card

    local drawerLayout = Instance.new("UIGridLayout")
    drawerLayout.CellSize = UDim2.new(0.32, 0, 0, 24)
    drawerLayout.CellPadding = UDim2.new(0, 5, 0, 4)
    drawerLayout.Parent = drawer

    local isDrawerOpen = false
    bindBtn(gearBtn, function()
        isDrawerOpen = not isDrawerOpen
        drawer.Visible = isDrawerOpen
        card.Size = isDrawerOpen and UDim2.new(1, 0, 0, 155) or UDim2.new(1, 0, 0, 36)
        gearBtn.BackgroundColor3 = isDrawerOpen and Color3.fromRGB(65, 120, 230) or Color3.fromRGB(42, 48, 68)
    end)

    local packVariantBtns = {}
    local varCfg = getPackVariantConfig(pName)

    for _, vName in ipairs(AllVariantNames) do
        local allowed = varCfg[vName] == true
        local mult = VariantMultipliers[vName] or ""
        local vBtn = Instance.new("TextButton")
        vBtn.Size = UDim2.new(1, 0, 1, 0)
        vBtn.BackgroundColor3 = allowed and Color3.fromRGB(35, 75, 140) or Color3.fromRGB(24, 28, 40)
        vBtn.Text = string.format("%s %s (%s)", allowed and "✓" or "✗", vName, mult)
        vBtn.TextColor3 = allowed and (VariantColors[vName] or Color3.fromRGB(255, 255, 255)) or Color3.fromRGB(105, 115, 130)
        vBtn.Font = Enum.Font.GothamBold
        vBtn.TextSize = 9
        vBtn.Parent = drawer

        local vbCorner = Instance.new("UICorner")
        vbCorner.CornerRadius = UDim.new(0, 4)
        vbCorner.Parent = vBtn

        bindBtn(vBtn, function()
            local cfg = getPackVariantConfig(pName)
            cfg[vName] = not cfg[vName]
            local nowAllowed = cfg[vName] == true
            local curMult = VariantMultipliers[vName] or ""
            vBtn.BackgroundColor3 = nowAllowed and Color3.fromRGB(35, 75, 140) or Color3.fromRGB(24, 28, 40)
            vBtn.TextColor3 = nowAllowed and (VariantColors[vName] or Color3.fromRGB(255, 255, 255)) or Color3.fromRGB(105, 115, 130)
            vBtn.Text = string.format("%s %s (%s)", nowAllowed and "✓" or "✗", vName, curMult)
            saveConfig()
        end)

        packVariantBtns[vName] = vBtn
    end

    bindBtn(buyBtn, function()
        Config.SelectedPacks[pName] = not Config.SelectedPacks[pName]
        local nowSel = Config.SelectedPacks[pName] == true
        buyBtn.BackgroundColor3 = nowSel and Color3.fromRGB(45, 175, 85) or Color3.fromRGB(45, 52, 68)
        buyBtn.Text = nowSel and "✓ BELI" or "OFF"
        saveConfig()
    end)

    packCards[pName] = {
        BuyBtn = buyBtn,
        VariantBtns = packVariantBtns,
        Card = card
    }
end

-- ============================================================================
-- TAB 3: 🏰 INFINITY TOWER BATTLE
-- ============================================================================
local TowerPage = createTab("Tower", "🏰", 3)

createSectionHeader(TowerPage, "Auto Infinity Tower")
createToggle(TowerPage, "🏰 Auto Tower Battle (Repeat Run)", "AutoTower", function(state)
    if state then
        task.spawn(pcall, runTowerCycle)
    end
end)

-- Mode Selector
local modeFrame = Instance.new("Frame")
modeFrame.Size = UDim2.new(1, 0, 0, 36)
modeFrame.BackgroundColor3 = Color3.fromRGB(24, 28, 40)
modeFrame.Parent = TowerPage

local modeCorner = Instance.new("UICorner")
modeCorner.CornerRadius = UDim.new(0, 8)
modeCorner.Parent = modeFrame

local modeStroke = Instance.new("UIStroke")
modeStroke.Color = Color3.fromRGB(38, 46, 66)
modeStroke.Thickness = 1
modeStroke.Parent = modeFrame

local modeLabel = Instance.new("TextLabel")
modeLabel.Size = UDim2.new(0, 110, 1, 0)
modeLabel.Position = UDim2.new(0, 12, 0, 0)
modeLabel.BackgroundTransparency = 1
modeLabel.Text = "Mode Battle:"
modeLabel.TextColor3 = Color3.fromRGB(200, 210, 230)
modeLabel.Font = Enum.Font.GothamMedium
modeLabel.TextSize = 11.5
modeLabel.TextXAlignment = Enum.TextXAlignment.Left
modeLabel.Active = false
modeLabel.Parent = modeFrame

local singleBtn = Instance.new("TextButton")
singleBtn.Size = UDim2.new(0, 100, 0, 24)
singleBtn.Position = UDim2.new(1, -215, 0.5, -12)
singleBtn.BackgroundColor3 = Config.TowerMode == "Single" and Color3.fromRGB(50, 105, 220) or Color3.fromRGB(34, 40, 56)
singleBtn.Text = "Single Tower"
singleBtn.TextColor3 = Config.TowerMode == "Single" and Color3.fromRGB(255, 255, 255) or Color3.fromRGB(150, 160, 185)
singleBtn.Font = Enum.Font.GothamBold
singleBtn.TextSize = 10
singleBtn.Parent = modeFrame

local scCorner = Instance.new("UICorner")
scCorner.CornerRadius = UDim.new(0, 6)
scCorner.Parent = singleBtn

local rotateBtn = Instance.new("TextButton")
rotateBtn.Size = UDim2.new(0, 100, 0, 24)
rotateBtn.Position = UDim2.new(1, -110, 0.5, -12)
rotateBtn.BackgroundColor3 = Config.TowerMode == "Rotate" and Color3.fromRGB(50, 105, 220) or Color3.fromRGB(34, 40, 56)
rotateBtn.Text = "Rotate Mode"
rotateBtn.TextColor3 = Config.TowerMode == "Rotate" and Color3.fromRGB(255, 255, 255) or Color3.fromRGB(150, 160, 185)
rotateBtn.Font = Enum.Font.GothamBold
rotateBtn.TextSize = 10
rotateBtn.Parent = modeFrame

local rcCorner = Instance.new("UICorner")
rcCorner.CornerRadius = UDim.new(0, 6)
rcCorner.Parent = rotateBtn

local function updateTowerModeVisual()
    singleBtn.BackgroundColor3 = Config.TowerMode == "Single" and Color3.fromRGB(50, 105, 220) or Color3.fromRGB(34, 40, 56)
    singleBtn.TextColor3 = Config.TowerMode == "Single" and Color3.fromRGB(255, 255, 255) or Color3.fromRGB(150, 160, 185)
    
    rotateBtn.BackgroundColor3 = Config.TowerMode == "Rotate" and Color3.fromRGB(50, 105, 220) or Color3.fromRGB(34, 40, 56)
    rotateBtn.TextColor3 = Config.TowerMode == "Rotate" and Color3.fromRGB(255, 255, 255) or Color3.fromRGB(150, 160, 185)
    saveConfig()
end

bindBtn(singleBtn, function()
    Config.TowerMode = "Single"
    updateTowerModeVisual()
end)

bindBtn(rotateBtn, function()
    Config.TowerMode = "Rotate"
    updateTowerModeVisual()
end)

createSectionHeader(TowerPage, "Pilih Tower yang Dimainkan:")

for _, tId in ipairs(TowerOrder) do
    local isChecked = Config.SelectedTowers[tId] == true
    
    local tFrame = Instance.new("Frame")
    tFrame.Size = UDim2.new(1, 0, 0, 34)
    tFrame.BackgroundColor3 = Color3.fromRGB(24, 28, 40)
    tFrame.Parent = TowerPage

    local tfCorner = Instance.new("UICorner")
    tfCorner.CornerRadius = UDim.new(0, 8)
    tfCorner.Parent = tFrame

    local tfStroke = Instance.new("UIStroke")
    tfStroke.Color = Color3.fromRGB(38, 46, 66)
    tfStroke.Thickness = 1
    tfStroke.Parent = tFrame

    local tLbl = Instance.new("TextLabel")
    tLbl.Size = UDim2.new(1, -70, 1, 0)
    tLbl.Position = UDim2.new(0, 12, 0, 0)
    tLbl.BackgroundTransparency = 1
    tLbl.Text = TowerDisplayNames[tId] or tId
    tLbl.TextColor3 = Color3.fromRGB(230, 235, 245)
    tLbl.Font = Enum.Font.GothamMedium
    tLbl.TextSize = 11
    tLbl.TextXAlignment = Enum.TextXAlignment.Left
    tLbl.Active = false
    tLbl.Parent = tFrame

    local tCheck = Instance.new("TextButton")
    tCheck.Size = UDim2.new(0, 55, 0, 22)
    tCheck.Position = UDim2.new(1, -65, 0.5, -11)
    tCheck.BackgroundColor3 = isChecked and Color3.fromRGB(50, 105, 220) or Color3.fromRGB(42, 48, 64)
    tCheck.Text = isChecked and "✓ ON" or "OFF"
    tCheck.TextColor3 = Color3.fromRGB(255, 255, 255)
    tCheck.Font = Enum.Font.GothamBold
    tCheck.TextSize = 9.5
    tCheck.Parent = tFrame

    local tcCorner = Instance.new("UICorner")
    tcCorner.CornerRadius = UDim.new(0, 6)
    tcCorner.Parent = tCheck

    bindBtn(tCheck, function()
        Config.SelectedTowers[tId] = not Config.SelectedTowers[tId]
        local nowState = Config.SelectedTowers[tId]
        tCheck.BackgroundColor3 = nowState and Color3.fromRGB(50, 105, 220) or Color3.fromRGB(42, 48, 64)
        tCheck.Text = nowState and "✓ ON" or "OFF"
        saveConfig()
    end)
end

createSectionHeader(TowerPage, "Pengaturan Tambahan")
createToggle(TowerPage, "👁️ Auto Hide Layar Battle", "AutoHideTowerBattle")

-- ============================================================================
-- TAB 4: ⭐ BASE & TOKEN
-- ============================================================================
local BasePage = createTab("Base & Token", "⭐", 4)

createSectionHeader(BasePage, "Auto Open Ready Cards (Dropper Base)")
createToggle(BasePage, "🎁 Auto Open Card (Saat Countdown 0s / Ready)", "AutoOpenReadyCards")

local openDesc = Instance.new("TextLabel")
openDesc.Size = UDim2.new(1, 0, 0, 36)
openDesc.BackgroundTransparency = 1
openDesc.Text = "ℹ️ Otomatis mendeteksi box/kartu di dropper base yang countdown-nya sudah 0 (Ready) dan langsung membukanya."
openDesc.TextColor3 = Color3.fromRGB(140, 155, 185)
openDesc.Font = Enum.Font.Gotham
openDesc.TextSize = 10
openDesc.TextWrapped = true
openDesc.TextXAlignment = Enum.TextXAlignment.Left
openDesc.Parent = BasePage

createSectionHeader(BasePage, "Auto Level Up Kartu")
createToggle(BasePage, "⭐ Auto Level Up (Kartu Base Terendah)", "AutoLevelUp")
createTextBox(BasePage, "🎯 Target Maksimal Level Up:", "TargetCardLevel", 35)

createSectionHeader(BasePage, "Kolektor Semua Token & Potion (Map)")
createToggle(BasePage, "🔮 Auto Collect Semua Token & Potion", "AutoCollectTokens")

local tokenDesc = Instance.new("TextLabel")
tokenDesc.Size = UDim2.new(1, 0, 0, 42)
tokenDesc.BackgroundTransparency = 1
tokenDesc.Text = "ℹ️ Otomatis mendeteksi Trait Token, Grade Token, Luck/Cash Potion, & Variant Token di map, teleport mengambilnya, lalu instan kembali ke posisi semula."
tokenDesc.TextColor3 = Color3.fromRGB(140, 155, 185)
tokenDesc.Font = Enum.Font.Gotham
tokenDesc.TextSize = 10
tokenDesc.TextWrapped = true
tokenDesc.TextXAlignment = Enum.TextXAlignment.Left
tokenDesc.Parent = BasePage

createSectionHeader(BasePage, "💾 Manajemen Penyimpanan Settingan")

local saveBtn = Instance.new("TextButton")
saveBtn.Size = UDim2.new(1, 0, 0, 36)
saveBtn.BackgroundColor3 = Color3.fromRGB(35, 130, 75)
saveBtn.Text = "💾 Simpan Semua Pengaturan Sekarang"
saveBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
saveBtn.Font = Enum.Font.GothamBold
saveBtn.TextSize = 11
saveBtn.Parent = BasePage

local sbc = Instance.new("UICorner")
sbc.CornerRadius = UDim.new(0, 8)
sbc.Parent = saveBtn

bindBtn(saveBtn, function()
    saveConfig(true)
    saveBtn.Text = "✅ Berhasil Disimpan ke Disk!"
    saveBtn.BackgroundColor3 = Color3.fromRGB(50, 180, 95)
    task.delay(1.5, function()
        if saveBtn and saveBtn.Parent then
            saveBtn.Text = "💾 Simpan Semua Pengaturan Sekarang"
            saveBtn.BackgroundColor3 = Color3.fromRGB(35, 130, 75)
        end
    end)
end)

local saveStatusLabel = Instance.new("TextLabel")
saveStatusLabel.Size = UDim2.new(1, 0, 0, 32)
saveStatusLabel.BackgroundTransparency = 1
saveStatusLabel.Text = "ℹ️ Pengaturan otomatis tersimpan tiap kali kamu mengubah toggle / filter. Tombol di atas untuk memastikan tersimpan ke disk Delta."
saveStatusLabel.TextColor3 = Color3.fromRGB(140, 155, 185)
saveStatusLabel.Font = Enum.Font.Gotham
saveStatusLabel.TextSize = 10
saveStatusLabel.TextWrapped = true
saveStatusLabel.TextXAlignment = Enum.TextXAlignment.Left
saveStatusLabel.Parent = BasePage

-- Inisialisasi Tampilan
updateAllPacksVisual()

-- Buka Tab Farm secara Default
if tabs["Farm"] then
    tabs["Farm"].Page.Visible = true
    tabs["Farm"].Btn.BackgroundColor3 = Color3.fromRGB(50, 105, 220)
    tabs["Farm"].Btn.TextColor3 = Color3.fromRGB(255, 255, 255)
end

print("✅ Card & Crate Tycoon ALL-IN-ONE v3.2 Loaded Successfully!")
