-- Inspect collect function in CollectableObjectClient
local copyToClipboard = setclipboard or toclipboard or (Clipboard and Clipboard.set)
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local output = {}
local function log(str) table.insert(output, str); print(str) end

local mod = ReplicatedStorage.Client.Core.Classes:FindFirstChild("CollectableObjectClient")
if mod and typeof(decompile) == "function" then
    local code = decompile(mod)
    log("=== CollectableObjectClient FULL SOURCE ===")
    log(code)
end

local mod2 = ReplicatedStorage.Client.Core.Classes:FindFirstChild("VariantTokenSpawnClient")
if mod2 and typeof(decompile) == "function" then
    local code2 = decompile(mod2)
    log("\n=== VariantTokenSpawnClient FULL SOURCE ===")
    log(code2)
end

local full = table.concat(output, "\n")
if copyToClipboard then copyToClipboard(full) end
if writefile then writefile("collect_source.txt", full) end
