-- ============================================================================
-- 🔍 SAFE DROPPER & BOX SCANNER (NO DECOMPILE)
-- ============================================================================

local copyToClipboard = setclipboard or toclipboard or (Clipboard and Clipboard.set)
local Players = game:GetService("Players")
local Workspace = game:GetService("Workspace")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local LocalPlayer = Players.LocalPlayer

local output = {}
local function log(str)
    table.insert(output, str)
    print(str)
end

log("=== SAFE DROPPER SCAN ===")
log("Player: " .. tostring(LocalPlayer and LocalPlayer.Name))

pcall(function()
    local plotModels = Workspace:FindFirstChild("Map") and Workspace.Map:FindFirstChild("PlotModels")
    local myPlot = plotModels and (plotModels:FindFirstChild(LocalPlayer.Name) or plotModels:GetChildren()[1])
    
    if not myPlot then
        for _, p in ipairs(plotModels:GetChildren()) do
            if p.Name:find(LocalPlayer.Name) then myPlot = p break end
        end
    end

    if myPlot then
        log("Found Plot: " .. myPlot.Name)
        local systems = myPlot:FindFirstChild("Systems")
        local conveyors = systems and systems:FindFirstChild("TycoonConveyor") and systems.TycoonConveyor:FindFirstChild("Conveyors")
        
        if conveyors then
            local count = 0
            for _, conv in ipairs(conveyors:GetChildren()) do
                local dFolder = conv:FindFirstChild("Droppers")
                if dFolder then
                    for _, dropPart in ipairs(dFolder:GetChildren()) do
                        count = count + 1
                        local attrs = dropPart:GetAttributes()
                        local attrList = {}
                        for k, v in pairs(attrs) do
                            table.insert(attrList, string.format("%s=%s", tostring(k), tostring(v)))
                        end
                        log(string.format("[%d] %s | Attrs: %s", count, dropPart.Name, table.concat(attrList, ", ")))

                        for _, desc in ipairs(dropPart:GetDescendants()) do
                            if desc:IsA("ProximityPrompt") then
                                log(string.format("    -> PROMPT: Action='%s' | Object='%s' | Enabled=%s", desc.ActionText, desc.ObjectText, tostring(desc.Enabled)))
                            elseif desc:IsA("TextLabel") and desc.Text ~= "" then
                                log(string.format("    -> TEXT: %s = '%s'", desc.Name, desc.Text))
                            end
                        end
                    end
                end
            end
            log("Total Droppers scanned: " .. count)
        else
            log("Conveyors folder not found!")
        end
    else
        log("myPlot not found!")
    end
end)

local full = table.concat(output, "\n")
pcall(function()
    if copyToClipboard then
        copyToClipboard(full)
    end
end)
pcall(function()
    if writefile then
        writefile("dropper_scan.txt", full)
    end
end)

log("\n=== SELESAI! Check clipboard ===")
