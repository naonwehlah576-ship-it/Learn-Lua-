-- ============================================================================
-- 🔍 SCANNER: CRATE CARRY, POLISHER (CLAIM), & SELL NPC SYSTEM
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

header("SCAN REPORT: CRATE CARRY, POLISHER & SELL NPC SYSTEM")
log("Waktu : " .. os.date("%Y-%m-%d %H:%M:%S"))
log("Player: " .. tostring(LocalPlayer and LocalPlayer.Name))

-- 1. DETEKSI MY PLOT
header("1. PLOT STRUKTUR & SYSTEMS")
local plotModels = Workspace:FindFirstChild("Map") and Workspace.Map:FindFirstChild("PlotModels")
local myPlot = nil
if plotModels then
    myPlot = plotModels:FindFirstChild(LocalPlayer.Name) or plotModels:FindFirstChild(LocalPlayer.DisplayName)
    if not myPlot then
        for _, p in ipairs(plotModels:GetChildren()) do
            if p.Name:find(LocalPlayer.Name) then myPlot = p break end
        end
    end
end

if myPlot then
    log("✅ Plot ditemukan: " .. myPlot:GetFullName())
    local systems = myPlot:FindFirstChild("Systems")
    if systems then
        log("Children di Systems:")
        for _, child in ipairs(systems:GetChildren()) do
            log(string.format("  • [%s] (%s) - %d children", child.Name, child.ClassName, #child:GetChildren()))
        end
    else
        log("❌ Folder 'Systems' tidak ditemukan di myPlot.")
    end
else
    log("❌ myPlot tidak ditemukan!")
end

-- 2. SCAN SEMUA PROXIMITY PROMPT DI PLOT & MAP
header("2. SEMUA PROXIMITY PROMPT DI MY PLOT & MAP")
local foundPrompts = 0
if myPlot then
    for _, desc in ipairs(myPlot:GetDescendants()) do
        if desc:IsA("ProximityPrompt") then
            foundPrompts = foundPrompts + 1
            log(string.format("[%02d] Action='%s' | Object='%s' | HoldDuration=%.2f | Enabled=%s", 
                foundPrompts, desc.ActionText, desc.ObjectText, desc.HoldDuration, tostring(desc.Enabled)))
            log("     -> Path: " .. desc:GetFullName())
            local parent = desc.Parent
            if parent and parent:IsA("BasePart") then
                log(string.format("     -> Parent Part Pos: %.1f, %.1f, %.1f", parent.Position.X, parent.Position.Y, parent.Position.Z))
                local attrs = parent:GetAttributes()
                local aList = {}
                for k, v in pairs(attrs) do table.insert(aList, string.format("%s=%s", tostring(k), tostring(v))) end
                if #aList > 0 then
                    log("     -> Parent Attrs: " .. table.concat(aList, ", "))
                end
            end
        end
    end
end
log("Total ProximityPrompts di myPlot: " .. tostring(foundPrompts))

-- 3. SCAN NPC MODELS & SELL ZONES
header("3. NPC MODELS & SELL ZONES DI WORKSPACE")
pcall(function()
    local npcFolder = Workspace:FindFirstChild("Map") and Workspace.Map:FindFirstChild("NpcModels")
    if npcFolder then
        log("✅ Menemukan NpcModels:")
        for _, npc in ipairs(npcFolder:GetChildren()) do
            log(string.format("  • NPC: %s (%s)", npc.Name, npc.ClassName))
            for _, p in ipairs(npc:GetDescendants()) do
                if p:IsA("ProximityPrompt") then
                    log(string.format("      -> [PROMPT] Action='%s' | Object='%s' | Enabled=%s | Path: %s", 
                        p.ActionText, p.ObjectText, tostring(p.Enabled), p:GetFullName()))
                end
            end
        end
    else
        log("NpcModels tidak ditemukan di Workspace.Map.")
    end
end)

pcall(function()
    if myPlot and myPlot:FindFirstChild("Systems") then
        local zones = myPlot.Systems:FindFirstChild("Zones")
        if zones then
            log("✅ Menemukan Zones di myPlot:")
            for _, z in ipairs(zones:GetChildren()) do
                log(string.format("  • Zone: %s (%s)", z.Name, z.ClassName))
                for _, p in ipairs(z:GetDescendants()) do
                    if p:IsA("ProximityPrompt") then
                        log(string.format("      -> [PROMPT] Action='%s' | Object='%s' | Enabled=%s", p.ActionText, p.ObjectText, tostring(p.Enabled)))
                    end
                end
            end
        end
    end
end)

-- 4. SCAN SEMUA REMOTES TERKAIT CRATE, POLISHER, CARRY, SELL
header("4. REMOTES DI REPLICATEDSTORAGE TERKAIT CRATE / POLISHER / SELL")
pcall(function()
    for _, desc in ipairs(ReplicatedStorage:GetDescendants()) do
        if desc:IsA("RemoteEvent") or desc:IsA("RemoteFunction") then
            local n = desc.Name:lower()
            if n:find("crate") or n:find("box") or n:find("polish") or n:find("sell") or n:find("carry") 
                or n:find("claim") or n:find("drop") or n:find("deposit") or n:find("pickup") then
                log(string.format("  • [%s] %s -> %s", desc.ClassName, desc.Name, desc:GetFullName()))
            end
        end
    end
end)

-- 5. CEK ATTRIBUTES LOCALPLAYER & CHARACTER (CARRY STATUS)
header("5. ATTRIBUTES PEMAIN (CARRY / CRATE STATUS)")
pcall(function()
    log("LocalPlayer Attributes:")
    local count = 0
    for k, v in pairs(LocalPlayer:GetAttributes()) do
        count = count + 1
        log(string.format("  • %s = %s (%s)", tostring(k), tostring(v), typeof(v)))
    end
    if count == 0 then log("  (Tidak ada attribute di LocalPlayer)") end

    local char = LocalPlayer.Character
    if char then
        log("Character Attributes:")
        local cCount = 0
        for k, v in pairs(char:GetAttributes()) do
            cCount = cCount + 1
            log(string.format("  • %s = %s (%s)", tostring(k), tostring(v), typeof(v)))
        end
        if cCount == 0 then log("  (Tidak ada attribute di Character)") end
        
        log("Character Children (Tools / Welds / Crates):")
        for _, c in ipairs(char:GetChildren()) do
            if c:IsA("Tool") or c:IsA("Model") or c:IsA("Accessory") or c.Name:lower():find("crate") or c.Name:lower():find("box") then
                log(string.format("  • %s (%s)", c.Name, c.ClassName))
            end
        end
    end
end)

-- 6. INSPECT POLISHER MODEL & TYCOON CONVEYOR DETAIL
header("6. DETAIL POLISHER MODEL & TYCOON CONVEYOR")
if myPlot and myPlot:FindFirstChild("Systems") then
    local polisher = myPlot.Systems:FindFirstChild("PolisherModel") or myPlot.Systems:FindFirstChild("Polisher")
    if polisher then
        log("✅ Menemukan Polisher: " .. polisher:GetFullName())
        for _, desc in ipairs(polisher:GetDescendants()) do
            if desc:IsA("ProximityPrompt") then
                log(string.format("  • [POLISHER PROMPT] Action='%s' | Object='%s' | Hold=%.2f | Path: %s", 
                    desc.ActionText, desc.ObjectText, desc.HoldDuration, desc:GetFullName()))
            end
            if desc:IsA("TextLabel") and desc.Text ~= "" then
                log(string.format("  • [POLISHER TEXT] '%s' = '%s'", desc.Name, desc.Text))
            end
        end
        for k, v in pairs(polisher:GetAttributes()) do
            log(string.format("  • Polisher Attr: %s = %s", tostring(k), tostring(v)))
        end
    else
        log("PolisherModel tidak ditemukan di Systems.")
    end

    local conveyor = myPlot.Systems:FindFirstChild("TycoonConveyor")
    if conveyor then
        log("✅ Menemukan TycoonConveyor: " .. conveyor:GetFullName())
        for _, desc in ipairs(conveyor:GetDescendants()) do
            if desc:IsA("ProximityPrompt") then
                log(string.format("  • [CONVEYOR PROMPT] Action='%s' | Object='%s' | Hold=%.2f | Path: %s", 
                    desc.ActionText, desc.ObjectText, desc.HoldDuration, desc:GetFullName()))
            end
        end
    end
end

-- 7. EXPORT HASIL
header("7. EXPORT HASIL")
local fullOutput = table.concat(output, "\n")
local clipOk = false
if copyToClipboard then
    local s = pcall(copyToClipboard, fullOutput)
    if s then clipOk = true end
end

local fileOk = false
if writefile then
    local s = pcall(writefile, "scan_crate_polisher_report.txt", fullOutput)
    if s then fileOk = true end
end

log(string.format("📋 Copy ke Clipboard : %s", clipOk and "BERHASIL (Tinggal Paste ke chat)" or "GAGAL"))
log(string.format("💾 Simpan ke File     : %s", fileOk and "BERHASIL (scan_crate_polisher_report.txt)" or "GAGAL"))
log("\n✅ Selesai! Silakan paste hasil scan ke chat.")
