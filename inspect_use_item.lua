local copyToClipboard = setclipboard or toclipboard or (Clipboard and Clipboard.set)
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local output = {}
local function log(str) table.insert(output, str); print(str) end

log("=== INSPECT USE ITEM & INVENTORY GUI ===")

pcall(function()
    local mod = ReplicatedStorage.Client.Core.Gui:FindFirstChild("InventoryGuiClient")
    if mod then
        if typeof(decompile) == "function" then
            local s, code = pcall(decompile, mod)
            if s and code and #code > 10 then
                log("--- DECOMPILED InventoryGuiClient ---")
                log(code)
            end
        end
    end
end)

pcall(function()
    local mod = ReplicatedStorage.Shared.Services:FindFirstChild("ItemService")
    if mod then
        if typeof(decompile) == "function" then
            local s, code = pcall(decompile, mod)
            if s and code and #code > 10 then
                log("--- DECOMPILED ItemService ---")
                log(code)
            end
        end
    end
end)

local res = table.concat(output, "\n")
if copyToClipboard then pcall(copyToClipboard, res) end
if writefile then pcall(writefile, "inspect_use_item.txt", res) end
print("Done inspect use item!")
