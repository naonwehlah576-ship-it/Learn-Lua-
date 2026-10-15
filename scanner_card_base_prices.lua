-- ============================================================================
-- 🃏 SCANNER HARGA BASE / NORMAL CARD & PACKS
-- Card & Crate Tycoon
-- Auto Copy to Clipboard (setclipboard) & Auto Save to File (writefile)
-- ============================================================================

local copyToClipboard = setclipboard or toclipboard or (Clipboard and Clipboard.set)
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")
local Workspace = game:GetService("Workspace")
local LocalPlayer = Players.LocalPlayer

local output = {}
local function log(str)
    table.insert(output, str)
    print(str)
end

local function header(title)
    log("\n" .. string.rep("=", 68))
    log("📌 " .. title)
    log(string.rep("=", 68))
end

local function formatNumber(n)
    if typeof(n) ~= "number" then return tostring(n) end
    if n >= 1e15 then return string.format("$%.2fQA", n / 1e15)
    elseif n >= 1e12 then return string.format("$%.2fT", n / 1e12)
    elseif n >= 1e9 then return string.format("$%.2fB", n / 1e9)
    elseif n >= 1e6 then return string.format("$%.2fM", n / 1e6)
    elseif n >= 1e3 then return string.format("$%.2fK", n / 1e3)
    else return "$" .. tostring(n)
    end
end

local function formatCommas(n)
    if typeof(n) ~= "number" then return tostring(n) end
    local formatted = tostring(math.floor(n))
    local k
    while true do
        formatted, k = string.gsub(formatted, "^(-?%d+)(%d%d%d)", "%1,%2")
        if k == 0 then break end
    end
    return formatted
end

header("SCAN REPORT: HARGA BASE / NORMAL CARD & PACKS")
log("Waktu : " .. os.date("%Y-%m-%d %H:%M:%S"))
log("Player: " .. tostring(LocalPlayer and LocalPlayer.Name))

-- 1. INSPECT BOXES LIBRARY (SUMBER UTAMA HARGA PACK/BOX)
header("1. BOXES LIBRARY (ReplicatedStorage.Shared.Core.Storage.Game.BoxesLibrary)")

local BoxesLibrary = nil
pcall(function()
    local bMod = ReplicatedStorage:FindFirstChild("Shared")
        and ReplicatedStorage.Shared:FindFirstChild("Core")
        and ReplicatedStorage.Shared.Core:FindFirstChild("Storage")
        and ReplicatedStorage.Shared.Core.Storage:FindFirstChild("Game")
        and ReplicatedStorage.Shared.Core.Storage.Game:FindFirstChild("BoxesLibrary")

    if not bMod then
        for _, desc in ipairs(ReplicatedStorage:GetDescendants()) do
            if desc.Name == "BoxesLibrary" and desc:IsA("ModuleScript") then
                bMod = desc
                break
            end
        end
    end

    if bMod then
        BoxesLibrary = require(bMod)
        log("✅ Menemukan BoxesLibrary di: " .. bMod:GetFullName())
    else
        log("❌ BoxesLibrary tidak ditemukan di ReplicatedStorage.")
    end
end)

-- 2. INSPECT BOX SERVICE
header("2. BOX SERVICE (ReplicatedStorage.Shared.Services.BoxService)")
local BoxService = nil
pcall(function()
    local bsMod = ReplicatedStorage:FindFirstChild("Shared")
        and ReplicatedStorage.Shared:FindFirstChild("Services")
        and ReplicatedStorage.Shared.Services:FindFirstChild("BoxService")

    if not bsMod then
        for _, desc in ipairs(ReplicatedStorage:GetDescendants()) do
            if desc.Name == "BoxService" and desc:IsA("ModuleScript") then
                bsMod = desc
                break
            end
        end
    end

    if bsMod then
        BoxService = require(bsMod)
        log("✅ Menemukan BoxService di: " .. bsMod:GetFullName())
        log("Metode di BoxService:")
        for k, v in pairs(BoxService) do
            log(string.format("  • %s : %s", tostring(k), typeof(v)))
        end
    else
        log("❌ BoxService tidak ditemukan.")
    end
end)

-- 3. DAFTAR SEMUA PACK & HARGA BASE / NORMAL
header("3. DAFTAR LENGKAP HARGA BASE (NORMAL) SEMUA PACK")

local packList = {}

if BoxesLibrary and type(BoxesLibrary) == "table" then
    for key, data in pairs(BoxesLibrary) do
        if type(data) == "table" then
            local displayName = data.DisplayName or data.Name or key
            local basePrice = data.Price or data.Cost or data.ConveyorPrice or data.BasePrice or 0
            
            -- Cek juga via BoxService.GetConveyorBoxPrice
            local servicePrice = nil
            if BoxService and BoxService.GetConveyorBoxPrice then
                local ok, pVal = pcall(BoxService.GetConveyorBoxPrice, key, "Normal")
                if ok and typeof(pVal) == "number" then
                    servicePrice = pVal
                end
            end

            local finalPrice = (typeof(basePrice) == "number" and basePrice > 0) and basePrice or (servicePrice or 0)

            table.insert(packList, {
                Key = key,
                DisplayName = displayName,
                Price = finalPrice,
                ServicePrice = servicePrice,
                RawData = data
            })
        end
    end

    -- Urutkan berdasarkan harga dari termurah ke termahal
    table.sort(packList, function(a, b)
        if a.Price == b.Price then
            return tostring(a.DisplayName) < tostring(b.DisplayName)
        end
        return a.Price < b.Price
    end)

    log(string.format("%-4s | %-20s | %-16s | %-14s | %s", "No", "Nama Pack", "ID Internal", "Harga Format", "Harga Asli (Cash)"))
    log(string.rep("-", 80))

    for i, item in ipairs(packList) do
        local fmt = formatNumber(item.Price)
        local raw = formatCommas(item.Price)
        log(string.format("[%02d] | %-20s | %-16s | %-14s | $%s", i, tostring(item.DisplayName), tostring(item.Key), fmt, raw))
    end
else
    log("⚠️ Tidak dapat membaca data dari BoxesLibrary.")
end

-- 4. DETAIL ATTRIBUTES SETIAP PACK DI BOXESLIBRARY
header("4. DETAIL ISI DATA SETIAP PACK (BOXESLIBRARY)")
if #packList > 0 then
    for i, item in ipairs(packList) do
        log(string.format("\n📦 [%02d] %s (%s):", i, item.DisplayName, item.Key))
        log(string.format("   • Base Normal Price : %s ($%s)", formatNumber(item.Price), formatCommas(item.Price)))
        if item.ServicePrice then
            log(string.format("   • BoxService Price  : %s ($%s)", formatNumber(item.ServicePrice), formatCommas(item.ServicePrice)))
        end
        for k, v in pairs(item.RawData) do
            if type(v) ~= "table" then
                log(string.format("   • %s = %s (%s)", tostring(k), tostring(v), typeof(v)))
            else
                log(string.format("   • %s (table with %d keys)", tostring(k), #v > 0 and #v or 0))
            end
        end
    end
end

-- 5. INSPECT ROLL STATION / CONVEYOR DI PLOT (REAL-TIME LIVE CHECK)
header("5. LIVE CHECK DARI ROLL STATION PLOT")
pcall(function()
    local plotModels = Workspace:FindFirstChild("Map") and Workspace.Map:FindFirstChild("PlotModels")
    local myPlot = plotModels and (plotModels:FindFirstChild(LocalPlayer.Name) or plotModels:FindFirstChild(LocalPlayer.DisplayName))
    if not myPlot and plotModels then
        for _, p in ipairs(plotModels:GetChildren()) do
            if p.Name:find(LocalPlayer.Name) then myPlot = p break end
        end
    end

    if myPlot then
        log("Plot ditemukan: " .. myPlot.Name)
        local rollStation = myPlot:FindFirstChild("Systems") and myPlot.Systems:FindFirstChild("RollStation")
        if rollStation then
            log("RollStation ditemukan!")
            for _, desc in ipairs(rollStation:GetDescendants()) do
                if desc:IsA("TextLabel") and desc.Text ~= "" then
                    log(string.format("  • TextLabel '%s' [Parent: %s]: '%s'", desc.Name, desc.Parent and desc.Parent.Name or "None", desc.Text))
                end
                if desc:IsA("ProximityPrompt") then
                    log(string.format("  • ProximityPrompt: Object='%s' | Action='%s' | HoldDuration=%.1f", desc.ObjectText, desc.ActionText, desc.HoldDuration))
                end
            end
            local cp = rollStation:FindFirstChild("ConveyorPart")
            if cp then
                log("ConveyorPart Attributes:")
                for k, v in pairs(cp:GetAttributes()) do
                    log(string.format("    - %s = %s (%s)", tostring(k), tostring(v), typeof(v)))
                end
            end
        else
            log("RollStation tidak ditemukan di plot player.")
        end
    else
        log("Plot pemain tidak ditemukan.")
    end
end)

-- 6. CEK LIBRARY TERKAIT LAINNYA (JIKA ADA)
header("6. CEK MODULE LAIN (Card / Unit / Pack Libraries)")
pcall(function()
    for _, desc in ipairs(ReplicatedStorage:GetDescendants()) do
        if desc:IsA("ModuleScript") then
            local n = desc.Name:lower()
            if (n:find("card") or n:find("unit") or n:find("pack") or n:find("price") or n:find("tier")) and not n:find("gui") and not n:find("client") then
                log(string.format("  • Menemukan Module: %s (%s)", desc.Name, desc:GetFullName()))
                local s, req = pcall(require, desc)
                if s and type(req) == "table" then
                    local count = 0
                    for _ in pairs(req) do count = count + 1 end
                    log(string.format("      -> Sukses require (%d keys)", count))
                end
            end
        end
    end
end)

-- 7. SIMPAN DAN COPY KE CLIPBOARD
header("7. STATUS EXPORT")
local fullOutput = table.concat(output, "\n")
local clipOk = false
if copyToClipboard then
    local s = pcall(copyToClipboard, fullOutput)
    if s then clipOk = true end
end

local fileOk = false
if writefile then
    local s = pcall(writefile, "scan_card_base_prices.txt", fullOutput)
    if s then fileOk = true end
end

log(string.format("📋 Copy ke Clipboard : %s", clipOk and "BERHASIL (Tinggal Paste / Ctrl+V)" or "GAGAL / Tidak didukung"))
log(string.format("💾 Simpan ke File     : %s", fileOk and "BERHASIL (scan_card_base_prices.txt)" or "GAGAL / Tidak didukung"))
log("\n✅ Selesai! Kamu bisa langsung paste hasil scan ini ke sini.")
