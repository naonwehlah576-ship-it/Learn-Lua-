-- ============================================================================
-- 🔍 SCANNER: INDEX CARDS & BASE $/CARD (LEVEL 1)
-- ============================================================================

local copyToClipboard = setclipboard or toclipboard or (Clipboard and Clipboard.set)
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")
local LocalPlayer = Players.LocalPlayer

local output = {}
local function log(str)
    table.insert(output, str)
    print(str)
end

local function header(title)
    log("\n" .. string.rep("=", 65))
    log("📌 " .. title)
    log(string.rep("=", 65))
end

header("SCAN REPORT: INDEX CARDS & $/CARD (LEVEL 1)")
log("Waktu: " .. os.date("%Y-%m-%d %H:%M:%S"))

-- 1. INSPECT PLAYER UNITS LIBRARY
header("1. INSPECT PLAYER UNITS LIBRARY")
local unitsLib = nil
pcall(function()
    local mod = ReplicatedStorage:FindFirstChild("Shared")
        and ReplicatedStorage.Shared:FindFirstChild("Core")
        and ReplicatedStorage.Shared.Core:FindFirstChild("Storage")
        and ReplicatedStorage.Shared.Core.Storage:FindFirstChild("Game")
        and ReplicatedStorage.Shared.Core.Storage.Game:FindFirstChild("PlayerUnitsLibrary")
    if mod then
        unitsLib = require(mod)
        log("PlayerUnitsLibrary berhasil di-require! Tipe: " .. typeof(unitsLib))
    else
        log("❌ PlayerUnitsLibrary tidak ditemukan di path default, mencari di descendants...")
        for _, desc in ipairs(ReplicatedStorage:GetDescendants()) do
            if desc.Name == "PlayerUnitsLibrary" and desc:IsA("ModuleScript") then
                unitsLib = require(desc)
                log("Found at: " .. desc:GetFullName())
                break
            end
        end
    end
end)

-- 2. INSPECT PLAYER UNIT SERVICE
header("2. INSPECT PLAYER UNIT SERVICE")
local unitService = nil
pcall(function()
    local mod = ReplicatedStorage:FindFirstChild("Shared")
        and ReplicatedStorage.Shared:FindFirstChild("Services")
        and ReplicatedStorage.Shared.Services:FindFirstChild("PlayerUnitService")
    if mod then
        unitService = require(mod)
        log("PlayerUnitService berhasil di-require! Exported methods:")
        for k, v in pairs(unitService) do
            log(string.format("  • %s : %s", tostring(k), typeof(v)))
        end
    end
end)

-- 3. PARSE ALL CARDS & BASE STATS
header("3. DAFTAR SEMUA KARTU DENGAN HARGA $/CARD (LVL 1 NORMAL)")
local cardList = {}

if type(unitsLib) == "table" then
    for cardKey, cardData in pairs(unitsLib) do
        if type(cardData) == "table" then
            local name = cardData.Name or cardData.DisplayName or cardKey
            local boxName = cardData.BoxName or cardData.Box or cardData.Pack or "Unknown"
            local rarity = cardData.Rarity or "Unknown"
            local baseCash = cardData.BaseCash or cardData.CashPerCard or cardData.Cash or cardData.BaseCashPerCard or 0

            -- Cek apakah ada fungsi perhitungan di PlayerUnitService
            if baseCash == 0 and unitService then
                pcall(function()
                    if unitService.GetCardCash then
                        baseCash = unitService.GetCardCash(cardKey, 1, "Normal")
                    elseif unitService.GetUnitCashPerCard then
                        baseCash = unitService.GetUnitCashPerCard({ PlayerUnitName = cardKey, PlayerUnitVariant = "Normal", PlayerUnitLevel = 1 }, 1)
                    elseif unitService.GetBaseCash then
                        baseCash = unitService.GetBaseCash(cardKey)
                    end
                end)
            end

            -- Simpan juga raw keys untuk sampel pertama
            table.insert(cardList, {
                Key = cardKey,
                Name = name,
                Box = boxName,
                Rarity = rarity,
                BaseCash = baseCash,
                Raw = cardData
            })
        end
    end

    log("Total kartu ditemukan di Library: " .. #cardList)

    -- Cetak sampel 3 kartu pertama dengan detail raw data
    log("\n--- CONTOH STRUKTUR 3 KARTU PERTAMA ---")
    for i = 1, math.min(3, #cardList) do
        local c = cardList[i]
        log(string.format("\n[Sample #%d] Key: %s | Name: %s", i, tostring(c.Key), tostring(c.Name)))
        for rK, rV in pairs(c.Raw) do
            if type(rV) ~= "table" and type(rV) ~= "function" then
                log(string.format("    %s = %s (%s)", tostring(rK), tostring(rV), typeof(rV)))
            elseif type(rV) == "table" then
                log(string.format("    %s = {table with %d keys}", tostring(rK), #rV > 0 and #rV or 0))
            end
        end
    end

    -- Urutkan dari $/Card terendah ke tertinggi
    table.sort(cardList, function(a, b)
        local cashA = tonumber(a.BaseCash) or 0
        local cashB = tonumber(b.BaseCash) or 0
        if cashA ~= cashB then
            return cashA < cashB
        end
        return tostring(a.Name) < tostring(b.Name)
    end)

    -- Kelompokkan berdasarkan Pack / Box
    local byBox = {}
    for _, c in ipairs(cardList) do
        local bName = tostring(c.Box)
        if not byBox[bName] then byBox[bName] = {} end
        table.insert(byBox[bName], c)
    end

    log("\n" .. string.rep("-", 65))
    log("📋 RINGKASAN SEMUA KARTU PER PACK (BASE LEVEL 1)")
    log(string.rep("-", 65))

    for bName, list in pairs(byBox) do
        log(string.format("\n📦 PACK / BOX: %s (Total: %d Kartu)", bName, #list))
        for _, c in ipairs(list) do
            log(string.format("   • %-22s | Rarity: %-10s | Base: $%s/Card", tostring(c.Name), tostring(c.Rarity), tostring(c.BaseCash)))
        end
    end
else
    log("⚠️ unitsLib bukan table: " .. tostring(unitsLib))
end

header("SCAN FINISHED")
local fullResult = table.concat(output, "\n")

pcall(function()
    if writefile then
        writefile("IndexCards_ScanReport.txt", fullResult)
        log("📁 File laporan lengkap disimpan ke: IndexCards_ScanReport.txt")
    end
end)

pcall(function()
    if copyToClipboard then
        copyToClipboard(fullResult)
        log("📋 Hasil scan telah disalin ke Clipboard!")
    end
end)
