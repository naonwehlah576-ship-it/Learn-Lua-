-- ============================================================================
-- 🔍 SCANNER: INDEX CARDS STATS ($/CARD & $/S LEVEL 1)
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
    log("\n" .. string.rep("=", 70))
    log("📌 " .. title)
    log(string.rep("=", 70))
end

header("INDEX 64 KARTU: STATS LEVEL 1 ($/CARD & $/S) CARD & CRATE TYCOON")
log("Waktu: " .. os.date("%Y-%m-%d %H:%M:%S"))

local unitsLib = nil
pcall(function()
    local mod = ReplicatedStorage.Shared.Core.Storage.Game.PlayerUnitsLibrary
    unitsLib = require(mod)
end)

local unitService = nil
pcall(function()
    local mod = ReplicatedStorage.Shared.Services.PlayerUnitService
    unitService = require(mod)
end)

local NumberUtils = nil
pcall(function()
    NumberUtils = require(ReplicatedStorage.Shared.Utility.NumberUtils)
end)

local function formatCash(val)
    if not val or val == 0 then return "$0" end
    if NumberUtils and NumberUtils.FormatNumber then
        return "$" .. NumberUtils.FormatNumber(val)
    end
    if val >= 1e12 then return string.format("$%.2fT", val / 1e12) end
    if val >= 1e9 then return string.format("$%.2fB", val / 1e9) end
    if val >= 1e6 then return string.format("$%.2fM", val / 1e6) end
    if val >= 1e3 then return string.format("$%.2fK", val / 1e3) end
    return "$" .. tostring(val)
end

local allCards = {}
if type(unitsLib) == "table" then
    for cardKey, cardData in pairs(unitsLib) do
        if type(cardData) == "table" then
            local displayName = cardData.DisplayName or cardData.Name or cardKey
            local internalName = cardData.Name or cardKey
            local boxName = cardData.BoxName or "Unknown"
            local chance = cardData.Chance or 0
            local cashPerDrop = cardData.CashPerDrop or 0
            local dropCooldown = 1
            local cashPerSec = cashPerDrop

            -- Hitung Cooldown & CashPerSecond via PlayerUnitService jika tersedia
            pcall(function()
                if unitService then
                    if unitService.GetDropCooldown then
                        dropCooldown = unitService.GetDropCooldown(internalName) or 1
                    end
                    if unitService.GetCashPerSecond then
                        cashPerSec = unitService.GetCashPerSecond({
                            PlayerUnitName = internalName,
                            PlayerUnitVariant = "Normal",
                            PlayerUnitLevel = 1,
                            PlayerUnitGrade = "D",
                            PlayerUnitTrait = "None"
                        })
                    elseif dropCooldown > 0 then
                        cashPerSec = cashPerDrop / dropCooldown
                    end
                end
            end)

            table.insert(allCards, {
                Key = cardKey,
                DisplayName = displayName,
                InternalName = internalName,
                BoxName = boxName,
                Chance = chance,
                CashPerDrop = cashPerDrop,
                DropCooldown = dropCooldown,
                CashPerSecond = cashPerSec or cashPerDrop
            })
        end
    end
end

-- Kelompokkan berdasarkan Pack
local packOrder = {
    "FirePack", "IcePack", "WaterPack", "PiratePack",
    "RomcomPack", "SwordPack", "KnightPack", "AssassinPack",
    "NinjaPack", "MagePack", "HeroPack", "DevilPack",
    "GeniusPack", "IdolPack", "SlayerPack", "TitanPack"
}

local cardsByPack = {}
for _, c in ipairs(allCards) do
    local b = c.BoxName
    if not cardsByPack[b] then cardsByPack[b] = {} end
    table.insert(cardsByPack[b], c)
end

-- Urutkan kartu dalam setiap pack berdasarkan CashPerDrop dari terendah ke tertinggi
for b, list in pairs(cardsByPack) do
    table.sort(list, function(a, b)
        return a.CashPerDrop < b.CashPerDrop
    end)
end

header("DAFTAR LENGKAP 64 KARTU PER PACK (LEVEL 1 NORMAL)")
for _, pName in ipairs(packOrder) do
    local list = cardsByPack[pName]
    if list then
        log(string.format("\n📦 %s (Total: %d Kartu):", pName:gsub("Pack", " Pack"), #list))
        log(string.rep("-", 70))
        for idx, c in ipairs(list) do
            log(string.format(
                " %d. %-18s (%-12s) | %-11s | %-10s | Drop: %4.1fs | Chance: %2d%%",
                idx,
                c.DisplayName,
                c.InternalName,
                formatCash(c.CashPerDrop) .. "/Card",
                formatCash(c.CashPerSecond) .. "/s",
                c.DropCooldown,
                c.Chance
            ))
        end
    end
end

-- Tampilkan Top 10 Kartu Penghasil Terbesar di Game pada Level 1
header("TOP 10 KARTU DENGAN $/CARD TERBESAR DI GAME (LEVEL 1)")
table.sort(allCards, function(a, b)
    return a.CashPerDrop > b.CashPerDrop
end)

for i = 1, math.min(10, #allCards) do
    local c = allCards[i]
    log(string.format(
        " #%2d. %-18s | Pack: %-12s | %-12s | %-11s",
        i,
        c.DisplayName,
        c.BoxName:gsub("Pack", ""),
        formatCash(c.CashPerDrop) .. "/Card",
        formatCash(c.CashPerSecond) .. "/s"
    ))
end

header("SCAN FINISHED")
local fullResult = table.concat(output, "\n")

pcall(function()
    if writefile then
        writefile("IndexCards_DetailedStats.txt", fullResult)
        log("📁 File disimpan: IndexCards_DetailedStats.txt")
    end
end)

pcall(function()
    if copyToClipboard then
        copyToClipboard(fullResult)
        log("📋 Hasil scan telah disalin ke Clipboard!")
    end
end)
