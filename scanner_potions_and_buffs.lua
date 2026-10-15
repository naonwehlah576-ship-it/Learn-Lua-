-- ============================================================================
-- 🧪 SCANNER: POTIONS, BUFFS, INVENTORY & USE POTION REMOTES
-- Auto Copy to Clipboard (setclipboard / toclipboard)
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
    log("\n" .. string.rep("=", 65))
    log("📌 " .. title)
    log(string.rep("=", 65))
end

local function dumpTable(tbl, indent, maxDepth, currentDepth)
    indent = indent or "  "
    maxDepth = maxDepth or 3
    currentDepth = currentDepth or 1
    if currentDepth > maxDepth then
        log(indent .. "[... truncated depth ...]")
        return
    end
    if type(tbl) ~= "table" then
        log(indent .. tostring(tbl))
        return
    end
    for k, v in pairs(tbl) do
        if type(v) == "table" then
            log(string.format("%s• [%s] (table):", indent, tostring(k)))
            dumpTable(v, indent .. "    ", maxDepth, currentDepth + 1)
        else
            log(string.format("%s• [%s] = %s (%s)", indent, tostring(k), tostring(v), typeof(v)))
        end
    end
end

header("SCAN REPORT: POTIONS & ACTIVE BUFFS SYSTEM")
log("Waktu: " .. os.date("%Y-%m-%d %H:%M:%S"))
log("Player: " .. tostring(LocalPlayer and LocalPlayer.Name))

-- 1. INSPECT POTIONS LIBRARY
header("1. POTIONS LIBRARY (ReplicatedStorage.Shared.Core.Storage.Game.PotionsLibrary)")
pcall(function()
    local mod = ReplicatedStorage:FindFirstChild("Shared")
        and ReplicatedStorage.Shared:FindFirstChild("Core")
        and ReplicatedStorage.Shared.Core:FindFirstChild("Storage")
        and ReplicatedStorage.Shared.Core.Storage:FindFirstChild("Game")
        and ReplicatedStorage.Shared.Core.Storage.Game:FindFirstChild("PotionsLibrary")

    if not mod then
        for _, desc in ipairs(ReplicatedStorage:GetDescendants()) do
            if desc.Name == "PotionsLibrary" and desc:IsA("ModuleScript") then
                mod = desc
                break
            end
        end
    end

    if mod then
        log("✅ Menemukan PotionsLibrary: " .. mod:GetFullName())
        local s, data = pcall(require, mod)
        if s and type(data) == "table" then
            dumpTable(data, "  ", 2)
        else
            log("⚠️ Require PotionsLibrary gagal: " .. tostring(data))
        end
    else
        log("❌ PotionsLibrary tidak ditemukan.")
    end
end)

-- 2. INSPECT POTION SERVICE
header("2. POTION SERVICE (ReplicatedStorage.Shared.Services.PotionService)")
pcall(function()
    local mod = ReplicatedStorage:FindFirstChild("Shared")
        and ReplicatedStorage.Shared:FindFirstChild("Services")
        and ReplicatedStorage.Shared.Services:FindFirstChild("PotionService")

    if not mod then
        for _, desc in ipairs(ReplicatedStorage:GetDescendants()) do
            if desc.Name == "PotionService" and desc:IsA("ModuleScript") then
                mod = desc
                break
            end
        end
    end

    if mod then
        log("✅ Menemukan PotionService: " .. mod:GetFullName())
        if typeof(decompile) == "function" then
            local s, code = pcall(decompile, mod)
            if s and code and #code > 10 then
                log("--- DECOMPILED SOURCE PotionService ---")
                log(code)
            end
        end
        local s, req = pcall(require, mod)
        if s and type(req) == "table" then
            log("Methods in PotionService:")
            for k, v in pairs(req) do
                log(string.format("  • %s : %s", tostring(k), typeof(v)))
            end
        end
    else
        log("❌ PotionService tidak ditemukan.")
    end
end)

-- 3. INSPECT BUFFS GUI CLIENT
header("3. BUFFS GUI CLIENT (ReplicatedStorage.Client.Core.Gui.BuffsGuiClient)")
pcall(function()
    local mod = ReplicatedStorage:FindFirstChild("Client")
        and ReplicatedStorage.Client:FindFirstChild("Core")
        and ReplicatedStorage.Client.Core:FindFirstChild("Gui")
        and ReplicatedStorage.Client.Core.Gui:FindFirstChild("BuffsGuiClient")

    if not mod then
        for _, desc in ipairs(ReplicatedStorage:GetDescendants()) do
            if desc.Name == "BuffsGuiClient" and desc:IsA("ModuleScript") then
                mod = desc
                break
            end
        end
    end

    if mod then
        log("✅ Menemukan BuffsGuiClient: " .. mod:GetFullName())
        if typeof(decompile) == "function" then
            local s, code = pcall(decompile, mod)
            if s and code and #code > 10 then
                log("--- DECOMPILED SOURCE BuffsGuiClient ---")
                log(code)
            end
        end
        local s, req = pcall(require, mod)
        if s and type(req) == "table" then
            log("Methods in BuffsGuiClient:")
            for k, v in pairs(req) do
                log(string.format("  • %s : %s", tostring(k), typeof(v)))
            end
        end
    else
        log("❌ BuffsGuiClient tidak ditemukan.")
    end
end)

-- 4. INSPECT CLIENT DATA MANAGER (POTION INVENTORY & ACTIVE POTIONS)
header("4. CLIENT DATA MANAGER: POTION INVENTORY & ACTIVE POTIONS/BUFFS")
pcall(function()
    local cdmMod = ReplicatedStorage:FindFirstChild("Client")
        and ReplicatedStorage.Client:FindFirstChild("Data")
        and ReplicatedStorage.Client.Data:FindFirstChild("ClientDataManager")

    if cdmMod then
        local s, cdm = pcall(require, cdmMod)
        if s and cdm and cdm.GetData then
            local data = cdm.GetData()
            if type(data) == "table" then
                log("Cek key di ClientDataManager.GetData():")
                for k, v in pairs(data) do
                    local strK = tostring(k):lower()
                    if strK:find("potion") or strK:find("buff") or strK:find("item") or strK:find("boost") then
                        log(string.format("  • [MATCH] %s (%s):", tostring(k), typeof(v)))
                        if type(v) == "table" then
                            dumpTable(v, "      ", 2)
                        else
                            log(string.format("      = %s", tostring(v)))
                        end
                    end
                end
            end
            if cdm.Signals then
                log("Signals di ClientDataManager:")
                for k, v in pairs(cdm.Signals) do
                    local strK = tostring(k):lower()
                    if strK:find("potion") or strK:find("buff") or strK:find("item") then
                        log(string.format("  • Signal: %s", tostring(k)))
                    end
                end
            end
        end
    else
        log("ClientDataManager tidak ditemukan.")
    end
end)

-- 5. INSPECT LOCALPLAYER ATTRIBUTES & DESCENDANTS FOR BUFFS
header("5. LOCALPLAYER ATTRIBUTES & BUFF FOLDERS")
pcall(function()
    local attrs = LocalPlayer:GetAttributes()
    log("LocalPlayer Attributes (Potion/Buff related):")
    local count = 0
    for k, v in pairs(attrs) do
        local strK = tostring(k):lower()
        if strK:find("potion") or strK:find("buff") or strK:find("boost") or strK:find("time") or strK:find("luck") or strK:find("duck") then
            count = count + 1
            log(string.format("  • %s = %s (%s)", tostring(k), tostring(v), typeof(v)))
        end
    end
    if count == 0 then log("  (Tidak ada attribute terkait potion/buff di LocalPlayer)") end

    log("LocalPlayer Children (Folders/Values):")
    for _, c in ipairs(LocalPlayer:GetChildren()) do
        local strN = c.Name:lower()
        if strN:find("potion") or strN:find("buff") or strN:find("boost") then
            log(string.format("  • %s (%s)", c.Name, c.ClassName))
            for _, sub in ipairs(c:GetChildren()) do
                log(string.format("      - %s (%s) = %s", sub.Name, sub.ClassName, tostring(sub.Value or "")))
            end
        end
    end
end)

-- 6. INSPECT PLAYERGUI FOR ACTIVE BUFFS / POTIONS UI
header("6. PLAYERGUI BUFFS & TIMERS INSPECTION")
pcall(function()
    local pGui = LocalPlayer:FindFirstChild("PlayerGui")
    if pGui then
        for _, gui in ipairs(pGui:GetChildren()) do
            if gui:IsA("ScreenGui") then
                local gName = gui.Name:lower()
                if gName:find("buff") or gName:find("potion") or gName:find("boost") or gName:find("timer") or gName:find("hud") or gName:find("front") then
                    log(string.format("ScreenGui: %s (Enabled: %s)", gui.Name, tostring(gui.Enabled)))
                    for _, desc in ipairs(gui:GetDescendants()) do
                        if desc:IsA("TextLabel") and desc.Visible and #desc.Text > 0 then
                            local t = desc.Text:lower()
                            if t:find(":") or t:find("luck") or t:find("potion") or t:find("cash") or t:find("duck") or t:find("grade") or t:find("m") or t:find("s") then
                                log(string.format("    TextLabel '%s' [Parent: %s]: '%s'", desc.Name, desc.Parent.Name, desc.Text))
                            end
                        end
                    end
                end
            end
        end
    end
end)

-- 7. SEARCH ALL REMOTES FOR POTION & ITEM ACTIONS
header("7. POTION & ITEM REMOTES IN REPLICATEDSTORAGE")
pcall(function()
    for _, desc in ipairs(ReplicatedStorage:GetDescendants()) do
        if desc:IsA("RemoteEvent") or desc:IsA("RemoteFunction") then
            local rName = desc.Name:lower()
            if rName:find("potion") or rName:find("buff") or rName:find("drink") or rName:find("use") or rName:find("item") then
                log(string.format("  • [%s] %s (%s)", desc.ClassName, desc:GetFullName(), desc.Name))
            end
        end
    end
end)

header("SCAN FINISHED")
local full = table.concat(output, "\n")
if copyToClipboard then
    pcall(copyToClipboard, full)
    log("\n🎉 HASIL SCAN POTION TELAH DISALIN KE CLIPBOARD! Tinggal paste ke chat ini.")
else
    log("\n⚠️ Hasil di-print di F9 Console.")
end
if writefile then
    pcall(writefile, "scan_potions_report.txt", full)
end
