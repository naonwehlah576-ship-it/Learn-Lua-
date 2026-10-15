-- ============================================================================
-- 🔍 SCANNER INDEX 64 KARTU (NEW FILE - NO CDN CACHE)
-- ============================================================================

local output = {}

local function fmt(n)
    n = tonumber(n) or 0
    if n >= 1e12 then return string.format("$%.2fT", n / 1e12) end
    if n >= 1e9 then return string.format("$%.2fB", n / 1e9) end
    if n >= 1e6 then return string.format("$%.2fM", n / 1e6) end
    if n >= 1e3 then return string.format("$%.2fK", n / 1e3) end
    return "$" .. tostring(n)
end

pcall(function()
    local ReplicatedStorage = game:GetService("ReplicatedStorage")
    local unitsLib = require(ReplicatedStorage.Shared.Core.Storage.Game.PlayerUnitsLibrary)

    local cards = {}
    for k, v in pairs(unitsLib) do
        if type(v) == "table" then
            table.insert(cards, {
                Key = tostring(k),
                Name = tostring(v.Name or k),
                DisplayName = tostring(v.DisplayName or v.Name or k),
                BoxName = tostring(v.BoxName or "Unknown"),
                Cash = tonumber(v.CashPerDrop) or 0,
                Chance = tostring(v.Chance or "?")
            })
        end
    end

    table.insert(output, "=================================================================")
    table.insert(output, "📌 DAFTAR 64 KARTU DI INDEX & HARGA AWAL $/CARD (LEVEL 1 NORMAL)")
    table.insert(output, "=================================================================")
    table.insert(output, "Total Kartu: " .. #cards .. " (16 Pack x 4 Kartu)\n")

    local packOrder = {
        "FirePack", "IcePack", "WaterPack", "PiratePack",
        "RomcomPack", "SwordPack", "KnightPack", "AssassinPack",
        "NinjaPack", "MagePack", "HeroPack", "DevilPack",
        "GeniusPack", "IdolPack", "SlayerPack", "TitanPack"
    }

    local byPack = {}
    for _, c in ipairs(cards) do
        if not byPack[c.BoxName] then byPack[c.BoxName] = {} end
        table.insert(byPack[c.BoxName], c)
    end

    for _, p in pairs(byPack) do
        table.sort(p, function(a, b) return a.Cash < b.Cash end)
    end

    for _, pName in ipairs(packOrder) do
        local list = byPack[pName]
        if list then
            local prettyPack = pName:gsub("Pack", " Pack")
            table.insert(output, string.format("📦 %s:", prettyPack))
            table.insert(output, string.rep("-", 60))
            for i, c in ipairs(list) do
                table.insert(output, string.format(
                    "  %d. %-18s (%-10s) : %-12s (Chance: %s%%)",
                    i,
                    c.DisplayName,
                    c.Name,
                    fmt(c.Cash) .. "/Card",
                    c.Chance
                ))
            end
            table.insert(output, "")
        end
    end

    -- Top 10 Termahal
    table.sort(cards, function(a, b) return a.Cash > b.Cash end)
    table.insert(output, "=================================================================")
    table.insert(output, "🏆 TOP 10 KARTU DENGAN PENGHASILAN TERBESAR DI GAME (LVL 1):")
    table.insert(output, "=================================================================")
    for i = 1, math.min(10, #cards) do
        local c = cards[i]
        table.insert(output, string.format(
            " #%2d. %-18s | Pack: %-12s | %-12s",
            i,
            c.DisplayName,
            c.BoxName:gsub("Pack", ""),
            fmt(c.Cash) .. "/Card"
        ))
    end
end)

local fullResult = table.concat(output, "\n")
local copy = setclipboard or toclipboard or (Clipboard and Clipboard.set)
if copy then
    pcall(copy, fullResult)
end
if writefile then
    pcall(writefile, "index_cards_result.txt", fullResult)
end
print(fullResult)
