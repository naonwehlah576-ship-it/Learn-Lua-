-- Safe slice inspect of CollectableObjectClient
local copyToClipboard = setclipboard or toclipboard or (Clipboard and Clipboard.set)
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local output = {}
local function log(str) table.insert(output, str); print(str) end

pcall(function()
    local mod = ReplicatedStorage.Client.Core.Classes:FindFirstChild("CollectableObjectClient")
    if mod and typeof(decompile) == "function" then
        local ok, code = pcall(decompile, mod)
        if ok and code then
            log("=== CollectableObjectClient (Part 2: 800-2400) ===")
            log(string.sub(code, 800, 2400))
        end
    end
end)

pcall(function()
    local mod2 = ReplicatedStorage.Client.Core.Classes:FindFirstChild("VariantTokenSpawnClient")
    if mod2 and typeof(decompile) == "function" then
        local ok2, code2 = pcall(decompile, mod2)
        if ok2 and code2 then
            log("\n=== VariantTokenSpawnClient (Part 2: 800-2400) ===")
            log(string.sub(code2, 800, 2400))
        end
    end
end)

local full = table.concat(output, "\n")
if copyToClipboard then pcall(copyToClipboard, full) end
if writefile then pcall(writefile, "collect_slice.txt", full) end
print("Done slice inspect!")
