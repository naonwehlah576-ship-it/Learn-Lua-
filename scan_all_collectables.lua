-- ============================================================================
-- 🔍 SCANNER: ALL COLLECTABLES, TOKENS, POTIONS, TRAITS & SPAWNS
-- ============================================================================

local copyToClipboard = setclipboard or toclipboard or (Clipboard and Clipboard.set)
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Workspace = game:GetService("Workspace")
local CollectionService = game:GetService("CollectionService")
local Players = game:GetService("Players")
local LocalPlayer = Players.LocalPlayer

local output = {}
local function log(str) table.insert(output, str); print(str) end
local function header(title)
    log("\n" .. string.rep("=", 65))
    log("📌 " .. title)
    log(string.rep("=", 65))
end

header("SCAN REPORT: ALL COLLECTABLES, TOKENS, POTIONS & MAP SPAWNS")
log("Waktu: " .. os.date("%Y-%m-%d %H:%M:%S"))

-- 1. INSPECT LIBRARIES
header("1. LIBRARIES: TOKENS, COLLECTABLES, POTIONS, TRAITS")
local function dumpModule(pathStr, label)
    log("\n--- " .. label .. " (" .. pathStr .. ") ---")
    local curr = ReplicatedStorage
    for part in string.gmatch(pathStr, "[^.]+") do
        if curr then curr = curr:FindFirstChild(part) end
    end
    if not curr then
        log("❌ Tidak ditemukan.")
        return
    end

    local ok, res = pcall(require, curr)
    if ok and type(res) == "table" then
        local count = 0
        for k, v in pairs(res) do
            count = count + 1
            if count <= 15 then
                if type(v) == "table" then
                    local subKeys = {}
                    for sK, _ in pairs(v) do table.insert(subKeys, tostring(sK)) end
                    log(string.format("  • [%s] = { %s }", tostring(k), table.concat(subKeys, ", ")))
                else
                    log(string.format("  • [%s] = %s (%s)", tostring(k), tostring(v), typeof(v)))
                end
            end
        end
        log(string.format("  Total entries: %d", count))
    else
        log("Gagal require: " .. tostring(res))
    end
end

dumpModule("Shared.Core.Storage.Game.CollectableObjectsLibrary", "COLLECTABLE OBJECTS LIBRARY")
dumpModule("Shared.Core.Storage.Game.TokensLibrary", "TOKENS LIBRARY")
dumpModule("Shared.Core.Storage.Game.VariantTokensLibrary", "VARIANT TOKENS LIBRARY")
dumpModule("Shared.Core.Storage.Game.PotionsLibrary", "POTIONS LIBRARY")
dumpModule("Shared.Core.Storage.Game.TraitsLibrary", "TRAITS LIBRARY")

-- 2. INSPECT CLIENT CLASSES: CollectableObjectClient & VariantTokenSpawnClient
header("2. CLIENT CLASSES INSPECTION")
local function inspectClass(pathStr, label)
    log("\n--- " .. label .. " ---")
    local curr = ReplicatedStorage
    for part in string.gmatch(pathStr, "[^.]+") do
        if curr then curr = curr:FindFirstChild(part) end
    end
    if not curr then log("❌ Tidak ditemukan."); return end

    if typeof(decompile) == "function" then
        local ok, code = pcall(decompile, curr)
        if ok and code and #code > 10 then
            log("📄 DECOMPILED SOURCE:")
            log(string.sub(code, 1, 1200) .. "\n... [truncated] ...")
            return
        end
    end

    local ok, res = pcall(require, curr)
    if ok and type(res) == "table" then
        for k, v in pairs(res) do
            log(string.format("  • %s : %s", tostring(k), typeof(v)))
        end
    end
end

inspectClass("Client.Core.Classes.CollectableObjectClient", "CollectableObjectClient")
inspectClass("Client.Core.Classes.VariantTokenSpawnClient", "VariantTokenSpawnClient")

-- 3. SCAN ALL REMOTES TERKAIT COLLECT / TOKEN / POTION / PICKUP / TRAIT
header("3. REMOTES BERHUBUNGAN DENGAN TOKEN, POTION, COLLECT, TRAIT")
local matchedRemotes = {}
for _, desc in ipairs(ReplicatedStorage:GetDescendants()) do
    if desc:IsA("RemoteEvent") or desc:IsA("RemoteFunction") then
        local nl = desc.Name:lower()
        if nl:find("token") or nl:find("collect") or nl:find("potion") 
            or nl:find("pickup") or nl:find("spawn") or nl:find("item") or nl:find("trait") or nl:find("grade") then
            table.insert(matchedRemotes, string.format("[%s] %s", desc.ClassName, desc:GetFullName()))
        end
    end
end
log("Total Remotes Cocok: " .. #matchedRemotes)
for _, r in ipairs(matchedRemotes) do
    log("  • " .. r)
end

-- 4. SCAN WORKSPACE SYSTEMS & TAGGED OBJECTS
header("4. WORKSPACE: SYSTEMS, SPAWNS & COLLECTIONSERVICE TAGS")
pcall(function()
    local systems = Workspace:FindFirstChild("Systems")
    if systems then
        log("📁 Workspace.Systems:")
        for _, child in ipairs(systems:GetChildren()) do
            local childCount = #child:GetChildren()
            local occupiedCount = 0
            for _, sub in ipairs(child:GetChildren()) do
                if sub:GetAttribute("Occupied") == true then
                    occupiedCount = occupiedCount + 1
                end
            end
            log(string.format("   • [%s] (%s) - Total: %d, Occupied: %d", child.Name, child.ClassName, childCount, occupiedCount))
            if occupiedCount > 0 or child.Name:lower():find("token") or child.Name:lower():find("collect") then
                for i = 1, math.min(5, childCount) do
                    local sample = child:GetChildren()[i]
                    local attrStr = {}
                    for aK, aV in pairs(sample:GetAttributes()) do
                        table.insert(attrStr, string.format("%s=%s", tostring(aK), tostring(aV)))
                    end
                    log(string.format("       [%s] Attrs: %s", sample.Name, table.concat(attrStr, ", ")))
                end
            end
        end
    else
        log("❌ Workspace.Systems tidak ada!")
    end
end)

pcall(function()
    log("\n🏷️ CollectionService Tags di Workspace:")
    local tags = {
        "CollectableObject", "Collectable", "TokenSpawn", "VariantTokenSpawn",
        "Token", "Potion", "DropItem", "Pickup"
    }
    for _, tag in ipairs(tags) do
        local tagged = CollectionService:GetTagged(tag)
        if #tagged > 0 then
            log(string.format("   • Tag '%s': %d objek ditemukan!", tag, #tagged))
            for i = 1, math.min(3, #tagged) do
                local o = tagged[i]
                log(string.format("       -> %s (Parent: %s)", o:GetFullName(), tostring(o.Parent and o.Parent.Name)))
            end
        end
    end
end)

header("SCAN FINISHED")
local fullResult = table.concat(output, "\n")
if copyToClipboard then copyToClipboard(fullResult) end
pcall(function()
    if writefile then writefile("all_collectables_scan.txt", fullResult) end
end)
log("\n🎉 SCAN SELESAI & TERSALIN KE CLIPBOARD!")
