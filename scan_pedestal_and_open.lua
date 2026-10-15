-- ============================================================================
-- 🔍 SCANNER: PAD / PEDESTAL / OPEN PACK & COUNTDOWN SYSTEM
-- Auto Copy to Clipboard (setclipboard)
-- ============================================================================

local copyToClipboard = setclipboard or toclipboard or (Clipboard and Clipboard.set)
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local CollectionService = game:GetService("CollectionService")
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

header("SCAN REPORT: BASE PAD / OPEN PACK / PEDESTAL / COUNTDOWN")
log("Waktu: " .. os.date("%Y-%m-%d %H:%M:%S"))

-- 1. DETEKSI STRUKTUR MYPLOT LENGKAP
header("1. STRUKTUR LENGKAP MY PLOT (BASE PLAYER)")
local myPlot = nil
pcall(function()
    local plotModels = Workspace:FindFirstChild("Map") and Workspace.Map:FindFirstChild("PlotModels")
    if plotModels then
        myPlot = plotModels:FindFirstChild(LocalPlayer.Name)
        if not myPlot then
            for _, p in ipairs(plotModels:GetChildren()) do
                if p.Name:find(LocalPlayer.Name) then
                    myPlot = p
                    break
                end
            end
        end
    end
end)

if myPlot then
    log("Plot ditemukan: " .. myPlot:GetFullName())
    for _, folder in ipairs(myPlot:GetChildren()) do
        log(string.format("  📁 [%s] (%s) - %d children", folder.Name, folder.ClassName, #folder:GetChildren()))
        for _, child in ipairs(folder:GetChildren()) do
            local nameLower = child.Name:lower()
            if nameLower:find("pedestal") or nameLower:find("pad") or nameLower:find("open") 
                or nameLower:find("card") or nameLower:find("box") or nameLower:find("pack") 
                or nameLower:find("stand") or nameLower:find("station") or nameLower:find("timer") then
                log(string.format("      -> 🎯 %s (%s)", child.Name, child.ClassName))
                for aK, aV in pairs(child:GetAttributes()) do
                    log(string.format("           Attr: %s = %s", tostring(aK), tostring(aV)))
                end
                for _, sub in ipairs(child:GetDescendants()) do
                    if sub:IsA("ProximityPrompt") then
                        log(string.format("           [PROMPT] Action='%s' | Object='%s' | Enabled=%s", sub.ActionText, sub.ObjectText, tostring(sub.Enabled)))
                    elseif sub:IsA("TextLabel") or sub:IsA("SurfaceGui") or sub:IsA("BillboardGui") then
                        if sub:IsA("TextLabel") and sub.Text ~= "" then
                            log(string.format("           [TEXT] %s = '%s'", sub.Name, sub.Text))
                        end
                    end
                end
            end
        end
    end
else
    log("❌ myPlot tidak ditemukan!")
end

-- 2. SCAN KELAS: UnitPedestalPart & BundlePedestalPart
header("2. INSPECTION: PEDESTAL CLASSES (CLIENT/SHARED)")
local function inspectModule(pathStr)
    log("\n--- " .. pathStr .. " ---")
    local curr = ReplicatedStorage
    for part in string.gmatch(pathStr, "[^.]+") do
        if curr then curr = curr:FindFirstChild(part) end
    end
    if not curr then
        log("❌ Tidak ditemukan.")
        return
    end
    
    if typeof(decompile) == "function" then
        local ok, code = pcall(decompile, curr)
        if ok and code and #code > 10 then
            log("📄 DECOMPILED CODE:")
            log(string.sub(code, 1, 1500) .. "\n... [truncated] ...")
            return
        end
    end
    
    local ok, res = pcall(require, curr)
    if ok and type(res) == "table" then
        log("🔹 Exported Keys/Methods:")
        for k, v in pairs(res) do
            log(string.format("  • %s : %s", tostring(k), typeof(v)))
        end
    else
        log("Require status: " .. tostring(ok) .. " | " .. tostring(res))
    end
end

inspectModule("Client.Core.Classes.BundlePedestalPart")
inspectModule("Client.Core.Classes.UnitPedestalPart")
inspectModule("Client.Core.Classes.BestPlayerUnitShowcasePart")

-- 3. SCAN SEMUA REMOTE DI REPLICATEDSTORAGE TERKAIT OPEN / PACK / PEDESTAL / BOX
header("3. REMOTES BERHUBUNGAN DENGAN OPEN / PACK / PEDESTAL / BOX")
local foundRemotes = {}
for _, desc in ipairs(ReplicatedStorage:GetDescendants()) do
    if desc:IsA("RemoteEvent") or desc:IsA("RemoteFunction") then
        local nLower = desc.Name:lower()
        if nLower:find("open") or nLower:find("pedestal") or nLower:find("unbox") 
            or nLower:find("pack") or nLower:find("box") or nLower:find("claim") or nLower:find("card") then
            table.insert(foundRemotes, string.format("[%s] %s", desc.ClassName, desc:GetFullName()))
        end
    end
end
log("Total Remotes Cocok: " .. #foundRemotes)
for _, r in ipairs(foundRemotes) do
    log("  • " .. r)
end

-- 4. SCAN PLAYERGUI UNTUK COUNTDOWN / OPEN GUI
header("4. PLAYERGUI: COUNTDOWN / OPEN PACK / UNBOX GUI")
local pGui = LocalPlayer:FindFirstChild("PlayerGui")
if pGui then
    for _, gui in ipairs(pGui:GetChildren()) do
        local nLower = gui.Name:lower()
        if nLower:find("open") or nLower:find("unbox") or nLower:find("pack") or nLower:find("pedestal") or nLower:find("card") then
            log(string.format("  🎨 GUI: %s (%s)", gui.Name, gui.ClassName))
            for _, d in ipairs(gui:GetDescendants()) do
                if d:IsA("TextLabel") and (d.Text:find(":") or d.Text:lower():find("open") or d.Text:lower():find("wait") or d.Text:lower():find("s")) then
                    log(string.format("      -> Text: '%s' (Path: %s)", d.Text, d.Name))
                end
            end
        end
    end
end

header("SCAN FINISHED")
local fullResult = table.concat(output, "\n")
if copyToClipboard then
    copyToClipboard(fullResult)
    log("\n🎉 HASIL SCAN TELAH DISALIN KE CLIPBOARD! Silakan paste (Ctrl+V) ke sini.")
else
    log("\n⚠️ Hasil di-print di F9 Console.")
end
