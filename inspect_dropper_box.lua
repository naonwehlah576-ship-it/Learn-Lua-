-- ============================================================================
-- 🔍 INSPECT DROPPER BOX HANDLER & OPENBOXONDROPPER
-- ============================================================================

local copyToClipboard = setclipboard or toclipboard or (Clipboard and Clipboard.set)
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Workspace = game:GetService("Workspace")
local Players = game:GetService("Players")
local LocalPlayer = Players.LocalPlayer

local output = {}
local function log(str) table.insert(output, str); print(str) end

log("=== INSPECT DROPPER BOX HANDLER ===")

pcall(function()
    local mod = ReplicatedStorage.Client.Core.Classes:FindFirstChild("DropperBoxHandler")
    if mod and typeof(decompile) == "function" then
        local code = decompile(mod)
        log("--- DECOMPILED DropperBoxHandler ---")
        log(code)
    else
        log("DropperBoxHandler tidak bisa di-decompile atau nil.")
    end
end)

log("\n=== INSPECT DROPPER ATTRIBUTES & PROMPTS DI MYPLOT ===")
pcall(function()
    local plotModels = Workspace.Map.PlotModels
    local myPlot = plotModels:FindFirstChild(LocalPlayer.Name)
    if not myPlot then
        for _, p in ipairs(plotModels:GetChildren()) do
            if p.Name:find(LocalPlayer.Name) then myPlot = p break end
        end
    end
    if myPlot then
        local conveyors = myPlot.Systems.TycoonConveyor.Conveyors
        for _, conv in ipairs(conveyors:GetChildren()) do
            local dFolder = conv:FindFirstChild("Droppers")
            if dFolder then
                for _, dropPart in ipairs(dFolder:GetChildren()) do
                    local attrs = dropPart:GetAttributes()
                    local hasBox = false
                    for k, v in pairs(attrs) do
                        if tostring(k):lower():find("box") or tostring(k):lower():find("time") or tostring(k):lower():find("open") or tostring(k):lower():find("countdown") then
                            hasBox = true
                        end
                    end
                    if hasBox or #dropPart:GetChildren() > 0 then
                        log(string.format("Dropper: %s", dropPart:GetFullName()))
                        for k, v in pairs(attrs) do
                            log(string.format("   Attr: %s = %s (%s)", tostring(k), tostring(v), typeof(v)))
                        end
                        for _, c in ipairs(dropPart:GetDescendants()) do
                            if c:IsA("ProximityPrompt") then
                                log(string.format("   [PROMPT] Action='%s' | Object='%s' | Enabled=%s", c.ActionText, c.ObjectText, tostring(c.Enabled)))
                            elseif c:IsA("BillboardGui") or c:IsA("SurfaceGui") then
                                for _, tl in ipairs(c:GetDescendants()) do
                                    if tl:IsA("TextLabel") then
                                        log(string.format("   [GUI TEXT] %s: '%s'", tl.Name, tl.Text))
                                    end
                                end
                            end
                        end
                    end
                end
            end
        end
    end
end)

local full = table.concat(output, "\n")
if copyToClipboard then copyToClipboard(full) end
log("\nCopied to clipboard!")
