print("===== SCANNING GAME =====")

local player = game.Players.LocalPlayer

-- scan workspace
print("---- WORKSPACE OBJECTS ----")

for _,v in pairs(workspace:GetDescendants()) do
    if v:IsA("Part") or v:IsA("Model") then
        print(v.Name)
    end
end


-- scan replicated storage
print("---- REMOTE EVENTS ----")

local rs = game:GetService("ReplicatedStorage")

for _,v in pairs(rs:GetDescendants()) do
    if v:IsA("RemoteEvent") or v:IsA("RemoteFunction") then
        print("Remote:", v.Name)
    end
end


-- detect objects near player
print("---- NEARBY OBJECTS ----")

local char = player.Character or player.CharacterAdded:Wait()
local root = char:WaitForChild("HumanoidRootPart")

for _,v in pairs(workspace:GetDescendants()) do
    if v:IsA("Part") then
        
        local dist = (v.Position - root.Position).Magnitude
        
        if dist < 50 then
            print("Nearby:", v.Name)
        end
        
    end
end

print("===== SCAN FINISHED =====")
