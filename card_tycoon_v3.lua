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

while not Players.LocalPlayer do
    task.wait(0.2)
end
local LocalPlayer = Players.LocalPlayer
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

local PotionService = nil
local function getPotionService()
    if not PotionService then
        pcall(function()
            local s = ReplicatedStorage:FindFirstChild("Shared") and ReplicatedStorage.Shared:FindFirstChild("Services")
            if s and s:FindFirstChild("PotionService") then
                PotionService = require(s.PotionService)
            else
                for _, desc in ipairs(ReplicatedStorage:GetDescendants()) do
                    if desc.Name == "PotionService" and desc:IsA("ModuleScript") then
                        PotionService = require(desc)
                        break
                    end
                end
            end
        end)
    end
    return PotionService
end

local ItemService = nil
local function getItemService()
    if not ItemService then
        pcall(function()
            local s = ReplicatedStorage:FindFirstChild("Shared") and ReplicatedStorage.Shared:FindFirstChild("Services")
            if s and s:FindFirstChild("ItemService") then
                ItemService = require(s.ItemService)
            else
                for _, desc in ipairs(ReplicatedStorage:GetDescendants()) do
                    if desc.Name == "ItemService" and desc:IsA("ModuleScript") then
                        ItemService = require(desc)
                        break
                    end
                end
            end
        end)
    end
    return ItemService
end

local PotionsLibrary = nil
local function getPotionsLibrary()
    if not PotionsLibrary then
        pcall(function()
            local bMod = ReplicatedStorage:FindFirstChild("Shared")
                and ReplicatedStorage.Shared:FindFirstChild("Core")
                and ReplicatedStorage.Shared.Core:FindFirstChild("Storage")
                and ReplicatedStorage.Shared.Core.Storage:FindFirstChild("Game")
                and ReplicatedStorage.Shared.Core.Storage.Game:FindFirstChild("PotionsLibrary")
            if bMod then
                PotionsLibrary = require(bMod)
            else
                for _, desc in ipairs(ReplicatedStorage:GetDescendants()) do
                    if desc.Name == "PotionsLibrary" and desc:IsA("ModuleScript") then
                        PotionsLibrary = require(desc)
                        break
                    end
                end
            end
        end)
    end
    return PotionsLibrary
end

local PotionList = {
    {
        Id = "LuckPotion",
        Name = "Luck Potion",
        ConfigKey = "AutoUseLuckPotion",
        Description = "+1 Luck",
        Color = Color3.fromRGB(110, 220, 140)
    },
    {
        Id = "CashPotion",
        Name = "Cash Potion",
        ConfigKey = "AutoUseCashPotion",
        Description = "x2 Cash",
        Color = Color3.fromRGB(255, 215, 60)
    },
    {
        Id = "GradeSpeedPotion",
        Name = "Token Speed Potion",
        ConfigKey = "AutoUseGradeSpeedPotion",
        Description = "+25% Token Speed",
        Color = Color3.fromRGB(255, 90, 80)
    },
    {
        Id = "DuckPotion",
        Name = "Duck Potion",
        ConfigKey = "AutoUseDuckPotion",
        Description = "x3 Walk Speed",
        Color = Color3.fromRGB(255, 230, 80)
    }
}

local function getPotionSecondsLeft(potionId)
    local timeLeft = nil
    pcall(function()
        local ps = getPotionService()
        if ps and ps.GetPotionTimeLeft then
            local sec = ps.GetPotionTimeLeft(LocalPlayer, potionId)
            if typeof(sec) == "number" then timeLeft = sec end
        end
    end)
    if timeLeft ~= nil then
        if timeLeft < 0 then timeLeft = 0 end
        return timeLeft
    end

    pcall(function()
        local potFolder = LocalPlayer:FindFirstChild("Potions")
        if potFolder then
            local sec = potFolder:GetAttribute(potionId)
            if typeof(sec) == "number" then timeLeft = sec end
        end
    end)
    if timeLeft ~= nil then
        if timeLeft < 0 then timeLeft = 0 end
        return timeLeft
    end

    return 0
end

local function getPotionStock(potionId)
    local amount = nil
    pcall(function()
        local is = getItemService()
        if is and is.GetAmountOfItem then
            local cnt = is.GetAmountOfItem(LocalPlayer, potionId)
            if typeof(cnt) == "number" then amount = cnt end
        end
    end)
    if amount ~= nil then return amount end

    pcall(function()
        local cdm = getClientDataManager()
        if cdm and cdm.GetData then
            local data = cdm.GetData()
            if data and data.Potions and typeof(data.Potions[potionId]) == "number" then
                amount = data.Potions[potionId]
            end
        end
    end)
    if amount ~= nil then return amount end

    return 0
end

local function usePotion(potionId)
    local rem = getRemote("UseItem")
    if not rem then
        pcall(function()
            if Remoting and Remoting.RemoteEvent then
                rem = Remoting.RemoteEvent("UseItem")
            end
        end)
    end
    if not rem then
        pcall(function()
            rem = ReplicatedStorage:FindFirstChild("Remotes") and ReplicatedStorage.Remotes:FindFirstChild("UseItem")
        end)
    end
    if rem then
        local ok, err = pcall(function()
            rem:FireServer(potionId)
        end)
        if ok then
            return true
        else
            warn("⚠️ [Potion] Gagal menembak UseItem: " .. tostring(err))
        end
    else
        warn("⚠️ [Potion] Remote 'UseItem' tidak ditemukan!")
    end
    return false
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
pcall(getPotionService)
pcall(getItemService)
pcall(getPotionsLibrary)

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
    "Genius Pack",
    "Knight Pack",
    "Mage Pack",
    "Slayer Pack",
    "Ninja Pack",
    "Assassin Pack",
    "Devil Pack",
    "Idol Pack",
    "Hero Pack",
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
        ["Genius Pack"]   = false,
        ["Knight Pack"]   = false,
        ["Mage Pack"]     = false,
        ["Slayer Pack"]   = false,
        ["Ninja Pack"]    = false,
        ["Assassin Pack"] = false,
        ["Devil Pack"]    = false,
        ["Idol Pack"]     = false,
        ["Hero Pack"]     = false,
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
-- 1. SMART CRATE & POLISHER SYSTEM (OPSI B - ANTI NABRAK, JEDA 10S)
-- ============================================================================

-- Helper: Cek apakah player sedang memegang Crate
local function getHeldCrateInfo()
    local ok, res = pcall(function()
        local htc = require(ReplicatedStorage.Client.Core.HeldToolClient)
        if htc and htc.GetHeldToolInfo then
            local info = htc.GetHeldToolInfo()
            if info and (info.Type == "Crate" or info.CrateGuid) then
                return info
            end
        end
        return nil
    end)
    if ok and res then return res end

    -- Fallback: Cek apakah di Character ada Model/Tool Crate
    local char = LocalPlayer.Character
    if char then
        for _, child in ipairs(char:GetChildren()) do
            if child:IsA("Model") or child:IsA("Tool") then
                local name = child.Name:lower()
                if name:find("crate") or child:GetAttribute("CrateGuid") then
                    return { Type = "Crate", CrateGuid = child:GetAttribute("CrateGuid") }
                end
            end
        end
    end
    return nil
end

-- Helper: Jual Crate ke Sell NPC (HANYA dipanggil jika benar-benar memegang crate!)
local function doSellCrate(guid)
    -- 1. RemoteEvent SellCrate dengan CrateGuid
    pcall(function()
        local rem = getRemote("SellCrate")
        if rem then
            if guid then
                rem:FireServer(guid)
            else
                rem:FireServer()
            end
        end
    end)

    -- 2. ProximityPrompt Sell NPC di Plot
    local myPlot = getMyPlot()
    if myPlot then
        pcall(function()
            local sellZone = myPlot:FindFirstChild("Systems") 
                and myPlot.Systems:FindFirstChild("Zones") 
                and myPlot.Systems.Zones:FindFirstChild("sell npc")
            if sellZone then
                for _, desc in ipairs(sellZone:GetDescendants()) do
                    if desc:IsA("ProximityPrompt") then
                        triggerPrompt(desc)
                    end
                end
            end
        end)
    end

    -- 3. ProximityPrompt Sell NPC di Map Models
    pcall(function()
        local npcModels = Workspace:FindFirstChild("Map") and Workspace.Map:FindFirstChild("NpcModels")
        if npcModels then
            for _, npc in ipairs(npcModels:GetChildren()) do
                for _, prompt in ipairs(npc:GetDescendants()) do
                    if prompt:IsA("ProximityPrompt") then
                        local act = (prompt.ActionText or ""):lower()
                        if act:find("sell") or prompt.Parent.Name:lower():find("sell") then
                            triggerPrompt(prompt)
                        end
                    end
                end
            end
        end
    end)
end

-- Helper: Cek apakah Polisher memiliki Crate siap panen
local function hasPolishedCrates()
    -- Cek via PolisherService
    local ok, res = pcall(function()
        local ps = require(ReplicatedStorage.Shared.Services.PolisherService)
        if ps and ps.GetPolishedCash then
            local cash = ps.GetPolishedCash(LocalPlayer)
            if cash and cash > 0 then return true end
        end
        return nil
    end)
    if ok and res ~= nil then return res end

    -- Cek via Attribute di Polisher Model
    local myPlot = getMyPlot()
    if myPlot and myPlot:FindFirstChild("Systems") then
        local pm = myPlot.Systems:FindFirstChild("PolisherModel")
        if pm then
            local phys = pm:FindFirstChild("PhysicalModel")
            local cp = (phys and phys:FindFirstChild("CollectPart")) or pm:FindFirstChild("CollectPart")
            if cp then
                local count = cp:GetAttribute("PolishedBallCount") or 0
                if count > 0 then return true end
            end
            local balls = pm:GetAttribute("PolishedBallCount") or 0
            if balls > 0 then return true end
        end
    end
    return false
end

-- Helper: Ambil / Claim Crate dari Polisher (Action "Claim" / "Collect")
local function doClaimPolisherCrate()
    pcall(function()
        local rem = getRemote("CollectPolisherCrate")
        if rem then rem:FireServer() end
    end)

    local myPlot = getMyPlot()
    if myPlot and myPlot:FindFirstChild("Systems") then
        local pm = myPlot.Systems:FindFirstChild("PolisherModel")
        if pm then
            for _, desc in ipairs(pm:GetDescendants()) do
                if desc:IsA("ProximityPrompt") then
                    local act = (desc.ActionText or ""):lower()
                    if act:find("claim") or act:find("collect") or desc.Name:lower():find("collect") then
                        triggerPrompt(desc)
                    end
                end
            end
        end
    end
end

-- Helper: Ambil / Carry Crate dari Tycoon Conveyor (Action "Carry")
local function doCarryConveyorCrate()
    pcall(function()
        local rem = getRemote("PickupCrateBox")
        if rem then rem:FireServer() end
    end)

    local myPlot = getMyPlot()
    if myPlot and myPlot:FindFirstChild("Systems") then
        local tc = myPlot.Systems:FindFirstChild("TycoonConveyor")
        if tc then
            local cp = tc:FindFirstChild("CollectPart")
            if cp then
                for _, desc in ipairs(cp:GetDescendants()) do
                    if desc:IsA("ProximityPrompt") then
                        triggerPrompt(desc)
                    end
                end
            end
        end
    end
end

-- Helper: Masukkan / Deposit Crate ke Polisher
local function doDepositCrateToPolisher()
    pcall(function()
        local rem = getRemote("DepositCrate")
        if rem then rem:FireServer() end
    end)

    local myPlot = getMyPlot()
    if myPlot and myPlot:FindFirstChild("Systems") then
        local pm = myPlot.Systems:FindFirstChild("PolisherModel")
        if pm then
            for _, desc in ipairs(pm:GetDescendants()) do
                if desc:IsA("ProximityPrompt") then
                    local act = (desc.ActionText or ""):lower()
                    if act:find("deposit") or act:find("load") or act:find("insert") then
                        triggerPrompt(desc)
                    end
                end
            end
        end
    end
end

-- Compatibility Aliases
local doCarryCrate = doCarryConveyorCrate
local doDepositPolisher = doDepositCrateToPolisher
local doCollectPolisher = doClaimPolisherCrate
local function doSellCrates()
    local h = getHeldCrateInfo()
    if h then
        doSellCrate(h.CrateGuid)
    end
end

-- ============================================================================
-- SIKLUS UTAMA OPSI B (SMART & ANTI-NABRAK)
-- ============================================================================
local function runSingleCycle()
    -- 0. CEK STATUS TANGAN: Jika sebelumnya sudah memegang crate (misal sisa putaran lalu), jual dulu!
    local initialHeld = getHeldCrateInfo()
    if initialHeld then
        doSellCrate(initialHeld.CrateGuid)
        task.wait(0.5)
    end

    -- 1. PRIORITAS UTAMA: POLISHER (+30% Cash Bonus)
    -- Cek apakah ada crate hasil polish yang siap di-claim
    if hasPolishedCrates() then
        doClaimPolisherCrate()
        task.wait(0.6)

        -- Cek apakah tangan kita sekarang memegang polished crate?
        local polishedHeld = getHeldCrateInfo()
        if polishedHeld then
            -- Bawa dan jual ke NPC langsung!
            doSellCrate(polishedHeld.CrateGuid)
            task.wait(0.5)
            -- Siklus polish selesai dengan sempurna, tidak tabrakan
            return
        end
    end

    -- 2. PRIORITAS KEDUA: KARTU KONVEYOR (CARRY CRATE)
    -- Ambil crate kartu normal dari conveyor
    doCarryConveyorCrate()
    task.wait(0.6)

    local cardHeld = getHeldCrateInfo()
    if cardHeld then
        -- Cek apakah polisher terbuka & bisa dimasukkan crate
        local polisherUnlocked = false
        pcall(function()
            local ps = require(ReplicatedStorage.Shared.Services.PolisherService)
            if ps and ps.IsUnlocked then
                polisherUnlocked = ps.IsUnlocked(LocalPlayer)
            end
        end)

        if polisherUnlocked then
            -- Coba deposit ke polisher untuk dipoles (+30% bonus)
            doDepositCrateToPolisher()
            task.wait(0.5)

            -- Cek apakah crate berhasil masuk polisher (tangan jadi kosong)
            local stillHeld = getHeldCrateInfo()
            if not stillHeld then
                -- Crate sukses masuk polisher! Siklus selesai
                return
            end
        end

        -- Jika polisher terkunci / penuh / deposit gagal, jual langsung crate ini ke NPC!
        doSellCrate(cardHeld.CrateGuid)
        task.wait(0.5)
    end
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
-- CARD TYCOON V3 - PREMIUM SIDEBAR TAB GUI (560 x 380)
-- 100% RELIABLE ACROSS PC, DELTA EXECUTOR, & MUMU PLAYER
-- ============================================================================

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

-- Floating Toggle Button (Selalu bisa dibuka/tutup)
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

-- Main Frame (Spacious 540 x 370)
local MainFrame = Instance.new("Frame")
MainFrame.Name = "MainFrame"
MainFrame.Size = UDim2.new(0, 540, 0, 370)
MainFrame.Position = UDim2.new(0.5, -270, 0.5, -185)
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
TitleLabel.Text = "🃏 <b>CARD TYCOON</b> <font color=\"#4A90E2\">ALL-IN-ONE v3.0</font>"
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

CloseBtn.MouseButton1Click:Connect(function() MainFrame.Visible = false end)
MinBtn.MouseButton1Click:Connect(function() MainFrame.Visible = false end)
FloatBtn.MouseButton1Click:Connect(function() MainFrame.Visible = not MainFrame.Visible end)

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
    tabBtn.TextSize = 12
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
    page.CanvasSize = UDim2.new(0, 0, 0, 450)
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

    tabBtn.MouseButton1Click:Connect(function()
        for _, t in pairs(tabs) do
            t.Page.Visible = false
            t.Btn.BackgroundColor3 = Color3.fromRGB(26, 30, 42)
            t.Btn.TextColor3 = Color3.fromRGB(175, 185, 205)
        end
        page.Visible = true
        tabBtn.BackgroundColor3 = Color3.fromRGB(50, 105, 220)
        tabBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
    end)

    tabs[name] = {Btn = tabBtn, Page = page}
    return page
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

    switch.MouseButton1Click:Connect(function()
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
-- TAB 1: 📦 CRATE FARM
-- ============================================================================
local FarmPage = createTab("Farm", "📦", 1)

createSectionHeader(FarmPage, "Smart Crate Farm (Opsi B - Anti Nabrak)")
createToggle(FarmPage, "⚡ Auto Smart Crate Cycle (Jeda 10s)", "AutoFullCrateCycle")

local runOnceBtn = Instance.new("TextButton")
runOnceBtn.Size = UDim2.new(1, 0, 0, 36)
runOnceBtn.BackgroundColor3 = Color3.fromRGB(40, 110, 210)
runOnceBtn.Text = "🔄 Jalankan 1x Smart Cycle Sekarang"
runOnceBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
runOnceBtn.Font = Enum.Font.GothamBold
runOnceBtn.TextSize = 11.5
runOnceBtn.Parent = FarmPage

local roCorner = Instance.new("UICorner")
roCorner.CornerRadius = UDim.new(0, 8)
roCorner.Parent = runOnceBtn

runOnceBtn.MouseButton1Click:Connect(function()
    task.spawn(pcall, runSingleCycle)
end)

local farmDesc = Instance.new("TextLabel")
farmDesc.Size = UDim2.new(1, 0, 0, 65)
farmDesc.BackgroundTransparency = 1
farmDesc.Text = "💡 Opsi B (Smart Priority): Mengambil Polished Crate terlebih dahulu (+30% bonus cash) lalu menjualnya ke NPC. Jika Polisher kosong, mengambil Crate Kartu dari Conveyor dan menyetorkannya ke Polisher atau langsung menjual ke NPC jika belum terbuka. Dilengkapi Anti-Nabrak (hanya jual saat memegang crate) dengan jeda 10 detik."
farmDesc.TextColor3 = Color3.fromRGB(140, 155, 185)
farmDesc.Font = Enum.Font.Gotham
farmDesc.TextSize = 10
farmDesc.TextWrapped = true
farmDesc.TextXAlignment = Enum.TextXAlignment.Left
farmDesc.Parent = FarmPage

-- ============================================================================
-- TAB 2: 🎰 ROLL & BUY
-- ============================================================================
local RollPage = createTab("Roll & Buy", "🎰", 2)

createSectionHeader(RollPage, "Conveyor Roll")
createToggle(RollPage, "🎰 Auto Roll & Auto Buy [Key: Q]", "AutoRoll", function(state)
    if state then resetAutoRollState() end
end)

local rollDesc = Instance.new("TextLabel")
rollDesc.Size = UDim2.new(1, 0, 0, 26)
rollDesc.BackgroundTransparency = 1
rollDesc.Text = "💡 Tekan tombol Q untuk toggle ON/OFF. Jika uang kurang, roll jeda dan otomatis lanjut saat saldo cukup!"
rollDesc.TextColor3 = Color3.fromRGB(150, 165, 195)
rollDesc.Font = Enum.Font.GothamMedium
rollDesc.TextSize = 9.5
rollDesc.TextWrapped = true
rollDesc.TextXAlignment = Enum.TextXAlignment.Left
rollDesc.Parent = RollPage

createSectionHeader(RollPage, "Pilih Pack yang Mau Dibeli:")

local rollPresetBar = Instance.new("Frame")
rollPresetBar.Size = UDim2.new(1, 0, 0, 26)
rollPresetBar.BackgroundTransparency = 1
rollPresetBar.Parent = RollPage

local rollPresetLayout = Instance.new("UIListLayout")
rollPresetLayout.FillDirection = Enum.FillDirection.Horizontal
rollPresetLayout.SortOrder = Enum.SortOrder.LayoutOrder
rollPresetLayout.Padding = UDim.new(0, 6)
rollPresetLayout.Parent = rollPresetBar

local packButtons = {}

local function updatePacksVisual()
    for pName, btn in pairs(packButtons) do
        local isSel = Config.SelectedPacks[pName] == true
        local isCustom = hasCustomVariantFilter(pName)
        btn.BackgroundColor3 = isSel and Color3.fromRGB(35, 75, 140) or Color3.fromRGB(24, 28, 40)
        btn.TextColor3 = isSel and (PackColors[pName] or Color3.fromRGB(255, 255, 255)) or Color3.fromRGB(120, 130, 150)
        btn.Text = (isSel and "✓ " or "") .. pName .. (isCustom and " [⚙️]" or "")
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

    btn.MouseButton1Click:Connect(callback)
end

createPresetBtn("Pilih Semua", 85, function()
    for _, p in ipairs(AllPackNames) do Config.SelectedPacks[p] = true end
    updatePacksVisual()
end)

createPresetBtn("6 Pertama", 80, function()
    for idx, p in ipairs(AllPackNames) do Config.SelectedPacks[p] = (idx <= 6) end
    updatePacksVisual()
end)

createPresetBtn("Reset", 65, function()
    for _, p in ipairs(AllPackNames) do Config.SelectedPacks[p] = false end
    updatePacksVisual()
end)

local packGridContainer = Instance.new("Frame")
packGridContainer.Size = UDim2.new(1, 0, 0, 210)
packGridContainer.BackgroundTransparency = 1
packGridContainer.Parent = RollPage

local packGridLayout = Instance.new("UIGridLayout")
packGridLayout.CellSize = UDim2.new(0.31, 0, 0, 28)
packGridLayout.CellPadding = UDim2.new(0, 6, 0, 6)
packGridLayout.Parent = packGridContainer

for _, pName in ipairs(AllPackNames) do
    local isSel = Config.SelectedPacks[pName] == true
    
    local chip = Instance.new("TextButton")
    chip.Size = UDim2.new(1, 0, 1, 0)
    chip.BackgroundColor3 = isSel and Color3.fromRGB(35, 75, 140) or Color3.fromRGB(24, 28, 40)
    chip.Text = (isSel and "✓ " or "") .. pName
    chip.TextColor3 = isSel and (PackColors[pName] or Color3.fromRGB(255, 255, 255)) or Color3.fromRGB(120, 130, 150)
    chip.Font = Enum.Font.GothamBold
    chip.TextSize = 9.5
    chip.Parent = packGridContainer

    local chipCorner = Instance.new("UICorner")
    chipCorner.CornerRadius = UDim.new(0, 6)
    chipCorner.Parent = chip

    local chipStroke = Instance.new("UIStroke")
    chipStroke.Color = Color3.fromRGB(38, 46, 66)
    chipStroke.Thickness = 1
    chipStroke.Parent = chip

    chip.MouseButton1Click:Connect(function()
        Config.SelectedPacks[pName] = not Config.SelectedPacks[pName]
        updatePacksVisual()
    end)

    packButtons[pName] = chip
end

-- ============================================================================
-- TAB 3: 🧬 FILTER MUTASI PER PACK
-- ============================================================================
local MutasiPage = createTab("Mutasi", "🧬", 3)

createSectionHeader(MutasiPage, "1. Pilih Pack yang Mau Diatur:")

local selectedMutasiPack = "Romcom Pack"

local activePackLabel = Instance.new("TextLabel")
activePackLabel.Size = UDim2.new(1, 0, 0, 24)
activePackLabel.BackgroundTransparency = 1
activePackLabel.Text = "Sedang Mengatur Mutasi: <font color=\"#FF78B4\"><b>Romcom Pack</b></font>"
activePackLabel.RichText = true
activePackLabel.TextColor3 = Color3.fromRGB(230, 235, 250)
activePackLabel.Font = Enum.Font.GothamMedium
activePackLabel.TextSize = 11
activePackLabel.TextXAlignment = Enum.TextXAlignment.Left
activePackLabel.Parent = MutasiPage

-- Selector Pack Scroll
local packSelectorScroll = Instance.new("ScrollingFrame")
packSelectorScroll.Size = UDim2.new(1, 0, 0, 36)
packSelectorScroll.BackgroundTransparency = 1
packSelectorScroll.BorderSizePixel = 0
packSelectorScroll.ScrollBarThickness = 2
packSelectorScroll.ScrollBarImageColor3 = Color3.fromRGB(65, 120, 230)
packSelectorScroll.CanvasSize = UDim2.new(0, #AllPackNames * 105, 0, 0)
packSelectorScroll.Parent = MutasiPage

local psLayout = Instance.new("UIListLayout")
psLayout.FillDirection = Enum.FillDirection.Horizontal
psLayout.SortOrder = Enum.SortOrder.LayoutOrder
psLayout.Padding = UDim.new(0, 5)
psLayout.Parent = packSelectorScroll

local selectorChips = {}
local variantButtons = {}

local function updateVariantButtonsVisual()
    local varCfg = getPackVariantConfig(selectedMutasiPack)
    for vName, btn in pairs(variantButtons) do
        local isAllowed = varCfg[vName] == true
        local mult = VariantMultipliers[vName] or ""
        btn.BackgroundColor3 = isAllowed and Color3.fromRGB(35, 75, 140) or Color3.fromRGB(24, 28, 40)
        btn.TextColor3 = isAllowed and (VariantColors[vName] or Color3.fromRGB(255, 255, 255)) or Color3.fromRGB(110, 115, 130)
        btn.Text = string.format("%s %s (%s)", isAllowed and "✓" or "✗", vName, mult)
    end
end

local function selectPackForMutation(pName)
    selectedMutasiPack = pName
    local pColor = PackColors[pName] or Color3.fromRGB(255, 255, 255)
    local hex = string.format("#%02X%02X%02X", math.floor(pColor.R * 255), math.floor(pColor.G * 255), math.floor(pColor.B * 255))
    activePackLabel.Text = string.format("Sedang Mengatur Mutasi: <font color=\"%s\"><b>%s</b></font>", hex, pName)
    
    for name, btn in pairs(selectorChips) do
        local isIt = (name == pName)
        btn.BackgroundColor3 = isIt and Color3.fromRGB(50, 105, 220) or Color3.fromRGB(28, 33, 46)
        btn.TextColor3 = isIt and Color3.fromRGB(255, 255, 255) or Color3.fromRGB(160, 170, 190)
    end
    updateVariantButtonsVisual()
end

for idx, pName in ipairs(AllPackNames) do
    local isIt = (pName == selectedMutasiPack)
    local pBtn = Instance.new("TextButton")
    pBtn.Size = UDim2.new(0, 100, 0, 28)
    pBtn.BackgroundColor3 = isIt and Color3.fromRGB(50, 105, 220) or Color3.fromRGB(28, 33, 46)
    pBtn.Text = pName
    pBtn.TextColor3 = isIt and Color3.fromRGB(255, 255, 255) or Color3.fromRGB(160, 170, 190)
    pBtn.Font = Enum.Font.GothamBold
    pBtn.TextSize = 9.5
    pBtn.LayoutOrder = idx
    pBtn.Parent = packSelectorScroll

    local pCorner = Instance.new("UICorner")
    pCorner.CornerRadius = UDim.new(0, 6)
    pCorner.Parent = pBtn

    pBtn.MouseButton1Click:Connect(function()
        selectPackForMutation(pName)
    end)

    selectorChips[pName] = pBtn
end

createSectionHeader(MutasiPage, "2. Preset Cepat Mutasi:")

local mutPresetBar = Instance.new("Frame")
mutPresetBar.Size = UDim2.new(1, 0, 0, 26)
mutPresetBar.BackgroundTransparency = 1
mutPresetBar.Parent = MutasiPage

local mutPresetLayout = Instance.new("UIListLayout")
mutPresetLayout.FillDirection = Enum.FillDirection.Horizontal
mutPresetLayout.SortOrder = Enum.SortOrder.LayoutOrder
mutPresetLayout.Padding = UDim.new(0, 6)
mutPresetLayout.Parent = mutPresetBar

local function createMutPreset(name, width, fn)
    local btn = Instance.new("TextButton")
    btn.Size = UDim2.new(0, width, 1, 0)
    btn.BackgroundColor3 = Color3.fromRGB(34, 40, 56)
    btn.Text = name
    btn.TextColor3 = Color3.fromRGB(220, 230, 250)
    btn.Font = Enum.Font.GothamBold
    btn.TextSize = 10
    btn.Parent = mutPresetBar

    local c = Instance.new("UICorner")
    c.CornerRadius = UDim.new(0, 6)
    c.Parent = btn

    btn.MouseButton1Click:Connect(function()
        fn()
        updateVariantButtonsVisual()
        updatePacksVisual()
        saveConfig()
    end)
end

createMutPreset("Semua Mutasi", 95, function()
    local varCfg = getPackVariantConfig(selectedMutasiPack)
    for _, v in ipairs(AllVariantNames) do varCfg[v] = true end
end)

createMutPreset("No Normal", 80, function()
    local varCfg = getPackVariantConfig(selectedMutasiPack)
    for _, v in ipairs(AllVariantNames) do varCfg[v] = (v ~= "Normal") end
end)

createMutPreset("Gold+", 70, function()
    local varCfg = getPackVariantConfig(selectedMutasiPack)
    for _, v in ipairs(AllVariantNames) do varCfg[v] = (v ~= "Normal") end
end)

createMutPreset("Diamond+", 80, function()
    local varCfg = getPackVariantConfig(selectedMutasiPack)
    for _, v in ipairs(AllVariantNames) do varCfg[v] = (v ~= "Normal" and v ~= "Gold") end
end)

createSectionHeader(MutasiPage, "3. Centang Mutasi yang Diizinkan Dibeli:")

local varGridContainer = Instance.new("Frame")
varGridContainer.Size = UDim2.new(1, 0, 0, 180)
varGridContainer.BackgroundTransparency = 1
varGridContainer.Parent = MutasiPage

local varGridLayout = Instance.new("UIGridLayout")
varGridLayout.CellSize = UDim2.new(0.48, 0, 0, 26)
varGridLayout.CellPadding = UDim2.new(0, 8, 0, 6)
varGridLayout.Parent = varGridContainer

for _, vName in ipairs(AllVariantNames) do
    local btn = Instance.new("TextButton")
    btn.Size = UDim2.new(1, 0, 1, 0)
    btn.BackgroundColor3 = Color3.fromRGB(35, 75, 140)
    btn.Text = "✓ " .. vName .. " (" .. (VariantMultipliers[vName] or "") .. ")"
    btn.TextColor3 = VariantColors[vName] or Color3.fromRGB(255, 255, 255)
    btn.Font = Enum.Font.GothamBold
    btn.TextSize = 10
    btn.Parent = varGridContainer

    local bCorner = Instance.new("UICorner")
    bCorner.CornerRadius = UDim.new(0, 6)
    bCorner.Parent = btn

    btn.MouseButton1Click:Connect(function()
        local varCfg = getPackVariantConfig(selectedMutasiPack)
        varCfg[vName] = not varCfg[vName]
        updateVariantButtonsVisual()
        updatePacksVisual()
        saveConfig()
    end)

    variantButtons[vName] = btn
end

-- ============================================================================
-- TAB 4: 🏰 INFINITY TOWER BATTLE
-- ============================================================================
local TowerPage = createTab("Tower", "🏰", 4)

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

singleBtn.MouseButton1Click:Connect(function()
    Config.TowerMode = "Single"
    updateTowerModeVisual()
end)

rotateBtn.MouseButton1Click:Connect(function()
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

    tCheck.MouseButton1Click:Connect(function()
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
-- TAB 5: ⭐ BASE & TOKEN
-- ============================================================================
local BasePage = createTab("Base & Token", "⭐", 5)

createSectionHeader(BasePage, "Auto Level Up Kartu")
createToggle(BasePage, "⭐ Auto Level Up (Kartu Base Terendah)", "AutoLevelUp")
createTextBox(BasePage, "🎯 Target Maksimal Level Up:", "TargetCardLevel", 35)

createSectionHeader(BasePage, "Variant Token Collector")
createToggle(BasePage, "🔮 Auto Teleport Token & Pasti Balik", "AutoCollectTokens")

local tokenDesc = Instance.new("TextLabel")
tokenDesc.Size = UDim2.new(1, 0, 0, 45)
tokenDesc.BackgroundTransparency = 1
tokenDesc.Text = "ℹ️ Jika ada Variant Token spawn di map, karakter akan teleport instan ke token, menunggu sampai token berhasil diambil, lalu teleport kembali ke posisi semula."
tokenDesc.TextColor3 = Color3.fromRGB(140, 155, 185)
tokenDesc.Font = Enum.Font.Gotham
tokenDesc.TextSize = 10
tokenDesc.TextWrapped = true
tokenDesc.TextXAlignment = Enum.TextXAlignment.Left
tokenDesc.Parent = BasePage

-- Inisialisasi Tampilan
updatePacksVisual()
selectPackForMutation("Romcom Pack")

-- Buka Tab Farm secara Default
if tabs["Farm"] then
    tabs["Farm"].Page.Visible = true
    tabs["Farm"].Btn.BackgroundColor3 = Color3.fromRGB(50, 105, 220)
    tabs["Farm"].Btn.TextColor3 = Color3.fromRGB(255, 255, 255)
end

print("✅ Card & Crate Tycoon ALL-IN-ONE v3.5 Loaded Successfully!")
