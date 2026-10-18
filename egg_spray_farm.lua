-- =========================================================================
--   AUTO SPRAY & MAP PET WATCHER (FAST BREAKER + SMART INTERRUPT)
--   Path: C:\Users\Rzoi7\Documents\Roblox\TD\script_egg_spray_farm.lua
--   Update: Auto-Save Status ON/OFF + Built-in Auto Reconnect & QueueOnTeleport
-- =========================================================================

-- Tunggu sampai Game benar-benar selesai loading (Wajib untuk AutoExec & AutoReconnect)
if not game:IsLoaded() then
    game.Loaded:Wait()
end

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local CollectionService = game:GetService("CollectionService")
local VirtualUser = game:GetService("VirtualUser")
local UserInputService = game:GetService("UserInputService")
local HttpService = game:GetService("HttpService")
local TeleportService = game:GetService("TeleportService")
local GuiService = game:GetService("GuiService")
local CoreGui = game:GetService("CoreGui")

-- Cek apakah game ini benar adalah game Egg Spray (mencegah error jika masuk game lain seperti FTD)
local configFolder = ReplicatedStorage:WaitForChild("Configurations", 10)
if not configFolder or not configFolder:FindFirstChild("Gameplay") or not configFolder.Gameplay:FindFirstChild("EggConfiguration") then
    print("[AUTOEXEC] Bukan game Egg Spray, script diabaikan.")
    return
end

local LocalPlayer = Players.LocalPlayer
while not LocalPlayer do
    task.wait(0.1)
    LocalPlayer = Players.LocalPlayer
end
local PlayerGui = LocalPlayer:WaitForChild("PlayerGui", 30)
if not PlayerGui then return end

-- Anti-AFK
LocalPlayer.Idled:Connect(function()
    VirtualUser:Button2Down(Vector2.new(0, 0), workspace.CurrentCamera.CFrame)
    task.wait(1)
    VirtualUser:Button2Up(Vector2.new(0, 0), workspace.CurrentCamera.CFrame)
end)

-- Load Modul Game
local NetworkShared = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("Remotes"):WaitForChild("NetworkShared"))
local EggConfig = require(ReplicatedStorage.Configurations.Gameplay:WaitForChild("EggConfiguration"))
local SprayConfig = require(ReplicatedStorage.Configurations.Gameplay:WaitForChild("SprayConfiguration"))

local MonetizationConfig = nil
pcall(function()
    MonetizationConfig = require(ReplicatedStorage.Configurations.Core:WaitForChild("MonetizationConfiguration"))
end)

-- Menghitung cooldown semprot secara dinamis (Otomatis 0.25s jika punya x2 Spray Pass, atau 0.5s normal)
local function getSprayCooldown()
    if MonetizationConfig and typeof(MonetizationConfig.SprayCooldown) == "function" then
        local ok, cd = pcall(MonetizationConfig.SprayCooldown, LocalPlayer, SprayConfig.Cooldown)
        if ok and typeof(cd) == "number" and cd > 0 then
            return cd
        end
    end
    return SprayConfig.Cooldown or 0.5
end

-- [[ KONFIGURASI ]] --
local SAVE_FILE = "EggFarm_Settings.json"

local CONFIG = {
    Enabled = true, -- Default ON jika belum ada file save
    AutoReconnect = true, -- Auto Reconnect saat DC / Error
    AutoEquipBest = true,
    TargetMode = "HighestLuck", -- "HighestLuck", "LowestHP", "HighestHP", "Closest"
    BaseCFrame = CFrame.new(83.5596, -22.502, 11.1891),
    MinIncome = 100000, -- Default 100K/s
    MinIncomeText = "100K",
    TargetRarities = {
        ["Secret"] = true,
        ["Cosmic"] = true,
        ["Divine"] = true,
        ["Mythic"] = false,
        ["Legendary"] = false,
        ["Epic"] = false,
        ["Rare"] = false,
        ["Uncommon"] = false,
        ["Common"] = false,
    },
    AttackDistance = 5,
    ClaimWait = 1.2,
}

local ALL_RARITIES = {
    "Secret",
    "Cosmic",
    "Divine",
    "Mythic",
    "Legendary",
    "Epic",
    "Rare",
    "Uncommon",
    "Common",
}

local TARGET_MODES = {
    { id = "HighestLuck", label = "Target: Luck Tertinggi" },
    { id = "LowestHP", label = "Target: HP Terendah" },
    { id = "HighestHP", label = "Target: HP Tertinggi" },
    { id = "Closest", label = "Target: Jarak Terdekat" },
}

local function getTargetModeLabel(id)
    for _, m in ipairs(TARGET_MODES) do
        if m.id == id then return m.label end
    end
    return "Target: Luck Tertinggi"
end

-- Riwayat Hewan yang Berhasil Di-claim
local CLAIM_LOGS = {}
local refreshLogUI = function() end
local updateLogTabBadge = function() end

-- Parser Shorthand
local function parseShorthand(str)
    if not str then return 0 end
    local clean = tostring(str):lower():gsub("%$", ""):gsub("/s", ""):gsub("%s+", "")
    local numStr = clean:match("[%d%.]+")
    local num = tonumber(numStr) or 0

    if clean:find("qi") or clean:find("qn") then
        return num * 1e18
    elseif clean:find("qd") or clean:find("qa") then
        return num * 1e15
    elseif clean:find("t") then
        return num * 1e12
    elseif clean:find("b") then
        return num * 1e9
    elseif clean:find("m") then
        return num * 1e6
    elseif clean:find("k") then
        return num * 1e3
    end
    return num
end

local function formatShorthand(num)
    if not num or num == 0 then return "0" end
    if num >= 1e18 then
        return string.format("%.2fQi", num / 1e18):gsub("%.00", "")
    elseif num >= 1e15 then
        return string.format("%.2fQd", num / 1e15):gsub("%.00", "")
    elseif num >= 1e12 then
        return string.format("%.2fT", num / 1e12):gsub("%.00", "")
    elseif num >= 1e9 then
        return string.format("%.2fB", num / 1e9):gsub("%.00", "")
    elseif num >= 1e6 then
        return string.format("%.2fM", num / 1e6):gsub("%.00", "")
    elseif num >= 1e3 then
        return string.format("%.2fK", num / 1e3):gsub("%.00", "")
    end
    return tostring(math.floor(num))
end

-- [[ SISTEM AUTO-SAVE & LOAD (TERMASUK STATUS ON/OFF) ]] --
local function saveSettings()
    if typeof(writefile) == "function" then
        pcall(function()
            local data = {
                Enabled = CONFIG.Enabled, -- Status Farm ON/OFF sekarang tersimpan!
                AutoReconnect = CONFIG.AutoReconnect,
                AutoEquipBest = CONFIG.AutoEquipBest,
                TargetMode = CONFIG.TargetMode,
                MinIncome = CONFIG.MinIncome,
                MinIncomeText = CONFIG.MinIncomeText,
                TargetRarities = CONFIG.TargetRarities,
                BaseCFrame = {
                    X = CONFIG.BaseCFrame.Position.X,
                    Y = CONFIG.BaseCFrame.Position.Y,
                    Z = CONFIG.BaseCFrame.Position.Z,
                }
            }
            writefile(SAVE_FILE, HttpService:JSONEncode(data))
        end)
    end
end

local function loadSettings()
    if typeof(isfile) == "function" and typeof(readfile) == "function" and isfile(SAVE_FILE) then
        pcall(function()
            local decoded = HttpService:JSONDecode(readfile(SAVE_FILE))
            if decoded then
                if decoded.Enabled ~= nil then CONFIG.Enabled = decoded.Enabled end
                if decoded.AutoReconnect ~= nil then CONFIG.AutoReconnect = decoded.AutoReconnect end
                if decoded.AutoEquipBest ~= nil then CONFIG.AutoEquipBest = decoded.AutoEquipBest end
                if decoded.TargetMode then CONFIG.TargetMode = decoded.TargetMode end
                if decoded.MinIncome then CONFIG.MinIncome = decoded.MinIncome end
                if decoded.MinIncomeText then CONFIG.MinIncomeText = decoded.MinIncomeText end
                if decoded.TargetRarities then
                    for k, v in pairs(decoded.TargetRarities) do
                        CONFIG.TargetRarities[k] = v
                    end
                end
                if decoded.BaseCFrame and decoded.BaseCFrame.X then
                    CONFIG.BaseCFrame = CFrame.new(decoded.BaseCFrame.X, decoded.BaseCFrame.Y, decoded.BaseCFrame.Z)
                end
            end
        end)
    end
end

loadSettings()

-- [[ SISTEM AUTO RECONNECT & QUEUE ON TELEPORT ]] --
local isReconnecting = false

local function queueScriptExecution()
    local qot = queue_on_teleport or (syn and syn.queue_on_teleport) or queueonteleport or (fluxus and fluxus.queue_on_teleport)
    if qot then
        pcall(function()
            qot([[
                repeat task.wait() until game:IsLoaded()
                if typeof(loadfile) == "function" then
                    local paths = {
                        "C:\\Users\\Rzoi7\\Documents\\Roblox\\TD\\script_egg_spray_farm.lua",
                        "script_egg_spray_farm.lua",
                        "egg_spray_farm.lua"
                    }
                    for _, p in ipairs(paths) do
                        local ok, fn = pcall(loadfile, p)
                        if ok and typeof(fn) == "function" then
                            fn()
                            break
                        end
                    end
                end
            ]])
        end)
    end
end

local function triggerReconnect()
    if not CONFIG.AutoReconnect or isReconnecting then return end
    isReconnecting = true
    print("[AUTO RECONNECT] Terputus dari server! Mempersiapkan reconnect dalam 5 detik...")
    
    queueScriptExecution()
    task.wait(5)

    pcall(function()
        if #Players:GetPlayers() <= 1 then
            TeleportService:Teleport(game.PlaceId, LocalPlayer)
        else
            TeleportService:TeleportToPlaceInstance(game.PlaceId, game.JobId, LocalPlayer)
        end
    end)
    task.wait(5)
    -- Fallback jika instance gagal
    pcall(function()
        TeleportService:Teleport(game.PlaceId, LocalPlayer)
    end)
end

-- Deteksi 1: GuiService Error
GuiService.ErrorMessageChanged:Connect(function()
    local err = GuiService:GetErrorType()
    if err ~= Enum.ConnectionError.OK then
        triggerReconnect()
    end
end)

-- Deteksi 2: PromptOverlay ErrorPrompt (Error 277, 268, dll)
pcall(function()
    local promptOverlay = CoreGui:WaitForChild("RobloxPromptGui", 10):WaitForChild("promptOverlay", 10)
    if promptOverlay then
        promptOverlay.ChildAdded:Connect(function(child)
            if child.Name == "ErrorPrompt" then
                triggerReconnect()
            end
        end)
    end
end)

-- [[ FUNGSI BANTUAN ]] --
local function getRoot()
    local char = LocalPlayer.Character
    return char and char:FindFirstChild("HumanoidRootPart")
end

local function getHumanoid()
    local char = LocalPlayer.Character
    return char and char:FindFirstChildOfClass("Humanoid")
end

-- [[ KALKULASI SKOR LUCK TELUR ]] --
local function getEggLuckScore(egg)
    local score = 0
    if egg:GetAttribute(EggConfig.Attributes.Titanic) == true or CollectionService:HasTag(egg, "TitanicEgg") then
        score = score + 1000000
    end
    local luckGrowth = egg:GetAttribute(EggConfig.Attributes.HatchLuckGrowth)
    if typeof(luckGrowth) == "number" then
        score = score + (luckGrowth * 1000)
    end
    local directLuck = egg:GetAttribute("Luck") or egg:GetAttribute("LuckMult")
    if typeof(directLuck) == "number" then
        score = score + (directLuck * 1000)
    end
    local sizeMult = egg:GetAttribute(EggConfig.Attributes.SpawnSizeMult)
    if typeof(sizeMult) == "number" then
        score = score + (sizeMult * 100)
    end
    return score
end

-- [[ BULLETPROOF SPRAY EQUIPPER ]] --
local function ensureSprayEquipped()
    local char = LocalPlayer.Character
    local hum = getHumanoid()
    if not char or not hum or hum.Health <= 0 then return nil end

    for _, tool in ipairs(char:GetChildren()) do
        if tool:IsA("Tool") then
            if tool:GetAttribute(SprayConfig.ToolAttribute) or tool.Name:lower():find("spray") then
                return tool
            end
        end
    end

    local backpack = LocalPlayer:FindFirstChild("Backpack")
    if backpack then
        for _, tool in ipairs(backpack:GetChildren()) do
            if tool:IsA("Tool") then
                if tool:GetAttribute(SprayConfig.ToolAttribute) or tool.Name:lower():find("spray") then
                    hum:EquipTool(tool)
                    return tool
                end
            end
        end
    end
    return nil
end

local scriptActive = true
task.spawn(function()
    while scriptActive do
        if CONFIG.Enabled then
            ensureSprayEquipped()
        end
        task.wait(0.25)
    end
end)

-- [[ DIRECT REMOTE AUTO EQUIP BEST ]] --
local function triggerEquipBest()
    pcall(function()
        local remotesFolder = ReplicatedStorage:WaitForChild("Shared"):WaitForChild("Remotes")
        local rf = remotesFolder:FindFirstChild("akiE99ICE9K7SOfn02GbIsxmNEdcrhV-Ei1bGwCV8egPTe7bYW9-FsemHBvqM5DIcY8WdQu7TBylsl7ZbP89og")
        if rf and rf:IsA("RemoteFunction") then
            rf:InvokeServer({ action = "EquipBest" })
        else
            NetworkShared.RequestPetsInventory:Invoke({ action = "EquipBest" })
        end
    end)
end

task.spawn(function()
    while scriptActive do
        if CONFIG.Enabled and CONFIG.AutoEquipBest then
            triggerEquipBest()
        end
        task.wait(5)
    end
end)

-- [[ TARGETING TELUR ]] --
local ignoredEggs = {}

local function findTargetEgg()
    local root = getRoot()
    if not root then return nil end

    local candidates = {}

    for _, egg in ipairs(CollectionService:GetTagged(EggConfig.WorldEggTag)) do
        if egg:IsA("Model") and egg.Parent ~= nil and not ignoredEggs[egg] then
            local health = egg:GetAttribute(EggConfig.Attributes.Health) or 0
            local hatching = egg:GetAttribute(EggConfig.Attributes.Hatching) == true
            local reserved = egg:GetAttribute(EggConfig.Attributes.ReservedUserId)
            local rarity = egg:GetAttribute(EggConfig.Attributes.Rarity) or "Common"

            local isFree = (reserved == nil or reserved == LocalPlayer.UserId)
            if health > 0 and not hatching and isFree and CONFIG.TargetRarities[rarity] then
                local eggPos = egg:GetPivot().Position
                local dist = (Vector2.new(root.Position.X, root.Position.Z) - Vector2.new(eggPos.X, eggPos.Z)).Magnitude
                local luckScore = getEggLuckScore(egg)

                table.insert(candidates, {
                    egg = egg,
                    health = health,
                    dist = dist,
                    luckScore = luckScore,
                })
            end
        end
    end

    if #candidates == 0 then return nil end

    if CONFIG.TargetMode == "HighestLuck" then
        table.sort(candidates, function(a, b)
            if a.luckScore ~= b.luckScore then
                return a.luckScore > b.luckScore
            end
            return a.dist < b.dist
        end)
    elseif CONFIG.TargetMode == "LowestHP" then
        table.sort(candidates, function(a, b) return a.health < b.health end)
    elseif CONFIG.TargetMode == "HighestHP" then
        table.sort(candidates, function(a, b) return a.health > b.health end)
    else -- "Closest"
        table.sort(candidates, function(a, b) return a.dist < b.dist end)
    end

    return candidates[1].egg
end

-- [[ MAP PET WATCHER & SECURE TAKE/CLAIM ]] --
local pickupsFolder = workspace:WaitForChild("AnimalPickups", 5)
local claimedPets = {}

local function findValuablePet()
    if not pickupsFolder then return nil end

    for _, animal in ipairs(pickupsFolder:GetChildren()) do
        if animal:IsA("Model") and not claimedPets[animal] then
            local income = animal:GetAttribute("Income") or 0
            if income >= CONFIG.MinIncome then
                local prompt = animal:FindFirstChildWhichIsA("ProximityPrompt", true)
                if prompt then
                    return animal, prompt, income
                end
            end
        end
    end
    return nil
end

local function isCarryingPet(petName)
    local char = LocalPlayer.Character
    if not char then return false end

    for _, c in ipairs(char:GetChildren()) do
        if c:IsA("Model") then
            if (petName and c.Name == petName) or c:GetAttribute("Income") or c:GetAttribute("AnimalId") or c:GetAttribute("PickupId") then
                return true
            end
        end
    end
    return false
end

local function addClaimLog(name, income, rarity)
    table.insert(CLAIM_LOGS, 1, {
        time = os.date("%H:%M:%S"),
        name = name,
        income = income,
        rarity = rarity or "Pet",
    })
    if #CLAIM_LOGS > 60 then
        table.remove(CLAIM_LOGS)
    end
    updateLogTabBadge()
    refreshLogUI()
end

-- [[ SECURE TAKE & CLAIM ]] --
local function secureTakeAndClaim(pet, prompt, petIncome)
    local root = getRoot()
    local char = LocalPlayer.Character
    if not root or not char then return false end

    local promptPart = prompt.Parent
    local promptPos = promptPart:IsA("BasePart") and promptPart.Position or pet:GetPivot().Position
    local petRarity = pet:GetAttribute("Rarity") or "Pet"
    local petName = pet.Name

    root.CFrame = CFrame.lookAt(promptPos + Vector3.new(0, 0.5, 2.5), promptPos)
    task.wait(0.06)

    local pickedUp = false
    local startPick = os.clock()

    while os.clock() - startPick < 0.9 do
        if pet.Parent == nil or not pet:IsDescendantOf(workspace) or not prompt.Parent then
            pickedUp = true
            break
        end

        if isCarryingPet(petName) then
            pickedUp = true
            break
        end

        root.CFrame = CFrame.lookAt(promptPos + Vector3.new(0, 0.5, 2.5), promptPos)
        if prompt.Enabled and prompt.Parent then
            fireproximityprompt(prompt)
        end
        task.wait(0.05)
    end

    if not pickedUp then
        print(string.format("[!] Pet %s gagal terangkat, skip!", petName))
        return false
    end

    print(string.format("[+] Pet %s ($%s/s) DI TANGAN! Teleport ke Base...", petName, formatShorthand(petIncome)))

    root.CFrame = CONFIG.BaseCFrame + Vector3.new(0, 3, 0)
    task.wait(0.08)

    local startClaim = os.clock()
    while os.clock() - startClaim < 1.4 do
        if not isCarryingPet(petName) and (pet.Parent == nil or not pet:IsDescendantOf(workspace)) then
            print(string.format("[CLAIMED] %s (%s) +$%s/s", petName, petRarity, formatShorthand(petIncome)))
            addClaimLog(petName, petIncome, petRarity)
            return true
        end

        root.CFrame = CONFIG.BaseCFrame + Vector3.new(0, 3, 0)
        task.wait(0.08)
    end

    addClaimLog(petName, petIncome, petRarity)
    return true
end

-- [[ CORE SYSTEM: FAST BREAKER + INTERRUPT CLAIM ]] --
local isClaiming = false

task.spawn(function()
    while scriptActive do
        if CONFIG.Enabled and not isClaiming then
            local pet, prompt, petIncome = findValuablePet()
            if pet and prompt then
                isClaiming = true
                print(string.format("[WATCHER] Pet terdeteksi: $%s/s -> Mengambil...", formatShorthand(petIncome)))

                secureTakeAndClaim(pet, prompt, petIncome)

                claimedPets[pet] = true
                isClaiming = false
            else
                local root = getRoot()
                if root then
                    local egg = findTargetEgg()
                    if egg then
                        local eggId = egg:GetAttribute(EggConfig.Attributes.EggId)
                        local eggPos = egg:GetPivot().Position

                        ensureSprayEquipped()

                        root.CFrame = CFrame.lookAt(eggPos + Vector3.new(0, 1, CONFIG.AttackDistance), eggPos)
                        task.wait(0.08)

                        while CONFIG.Enabled and scriptActive and not isClaiming and egg.Parent ~= nil do
                            local curRoot = getRoot()
                            if not curRoot then break end

                            local hp = egg:GetAttribute(EggConfig.Attributes.Health) or 0
                            local hatching = egg:GetAttribute(EggConfig.Attributes.Hatching) == true
                            if hp <= 0 or hatching then
                                break
                            end

                            local urgentPet, urgentPrompt = findValuablePet()
                            if urgentPet and urgentPrompt then
                                break
                            end

                            -- [PREVENTIF 1]: Pastikan jarak tetap rapat ke telur sebelum menembak spray
                            local currentDist = (curRoot.Position - eggPos).Magnitude
                            if currentDist > (CONFIG.AttackDistance + 2.5) then
                                pcall(function()
                                    curRoot.AssemblyLinearVelocity = Vector3.new(0, 0, 0)
                                    curRoot.AssemblyAngularVelocity = Vector3.new(0, 0, 0)
                                end)
                                curRoot.CFrame = CFrame.lookAt(eggPos + Vector3.new(0, 1, CONFIG.AttackDistance), eggPos)
                                task.wait(0.04)
                            end

                            ensureSprayEquipped()

                            pcall(function()
                                NetworkShared.RequestClean:Invoke({ eggId = eggId })
                            end)

                            -- [PREVENTIF 2]: Watchdog Anti-Knockback / Anti-Punch
                            -- Cooldown otomatis menyesuaikan (0.25s jika punya x2 Spray, atau 0.5s normal)
                            local cd = getSprayCooldown()
                            local waitStep = math.min(0.04, cd / 5)
                            local elapsed = 0
                            while elapsed < cd and CONFIG.Enabled and not isClaiming do
                                task.wait(waitStep)
                                elapsed = elapsed + waitStep

                                local checkRoot = getRoot()
                                if checkRoot then
                                    local distNow = (checkRoot.Position - eggPos).Magnitude
                                    if distNow > (CONFIG.AttackDistance + 2.5) then
                                        pcall(function()
                                            checkRoot.AssemblyLinearVelocity = Vector3.new(0, 0, 0)
                                            checkRoot.AssemblyAngularVelocity = Vector3.new(0, 0, 0)
                                        end)
                                        checkRoot.CFrame = CFrame.lookAt(eggPos + Vector3.new(0, 1, CONFIG.AttackDistance), eggPos)
                                    end
                                end
                            end
                        end

                        ignoredEggs[egg] = true
                        task.delay(4, function() ignoredEggs[egg] = nil end)
                    else
                        task.wait(0.2)
                    end
                end
            end
        end
        task.wait(0.04)
    end
end)

-- [[ MODERN CLEAN ASCII GUI ]] --
local function createUI()
    local existing = PlayerGui:FindFirstChild("AutoEggFarmGui")
    if existing then existing:Destroy() end

    local ScreenGui = Instance.new("ScreenGui")
    ScreenGui.Name = "AutoEggFarmGui"
    ScreenGui.ResetOnSpawn = false
    ScreenGui.Parent = PlayerGui

    local Main = Instance.new("Frame")
    Main.Name = "MainFrame"
    Main.Size = UDim2.new(0, 255, 0, 285)
    Main.Position = UDim2.new(0.05, 0, 0.28, 0)
    Main.BackgroundColor3 = Color3.fromRGB(22, 22, 26)
    Main.BorderSizePixel = 0
    Main.Active = true
    Main.Draggable = true
    Main.Parent = ScreenGui

    local UICorner = Instance.new("UICorner")
    UICorner.CornerRadius = UDim.new(0, 10)
    UICorner.Parent = Main

    -- Title Bar
    local TitleBar = Instance.new("Frame")
    TitleBar.Size = UDim2.new(1, 0, 0, 32)
    TitleBar.BackgroundColor3 = Color3.fromRGB(30, 30, 38)
    TitleBar.BorderSizePixel = 0
    TitleBar.Parent = Main
    local TitleCorner = Instance.new("UICorner")
    TitleCorner.CornerRadius = UDim.new(0, 10)
    TitleCorner.Parent = TitleBar

    local Title = Instance.new("TextLabel")
    Title.Size = UDim2.new(0.7, 0, 1, 0)
    Title.Position = UDim2.new(0, 8, 0, 0)
    Title.BackgroundTransparency = 1
    Title.Text = "FAST BREAKER [RShift]"
    Title.TextColor3 = Color3.fromRGB(255, 255, 255)
    Title.Font = Enum.Font.GothamBold
    Title.TextSize = 12
    Title.TextXAlignment = Enum.TextXAlignment.Left
    Title.Parent = TitleBar

    local CloseBtn = Instance.new("TextButton")
    CloseBtn.Size = UDim2.new(0, 22, 0, 22)
    CloseBtn.Position = UDim2.new(1, -26, 0.5, -11)
    CloseBtn.BackgroundColor3 = Color3.fromRGB(220, 50, 50)
    CloseBtn.Text = "X"
    CloseBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
    CloseBtn.Font = Enum.Font.GothamBold
    CloseBtn.TextSize = 12
    CloseBtn.Parent = TitleBar
    local CloseCorner = Instance.new("UICorner")
    CloseCorner.CornerRadius = UDim.new(0, 4)
    CloseCorner.Parent = CloseBtn

    local MinBtn = Instance.new("TextButton")
    MinBtn.Size = UDim2.new(0, 22, 0, 22)
    MinBtn.Position = UDim2.new(1, -52, 0.5, -11)
    MinBtn.BackgroundColor3 = Color3.fromRGB(50, 50, 65)
    MinBtn.Text = "-"
    MinBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
    MinBtn.Font = Enum.Font.GothamBold
    MinBtn.TextSize = 12
    MinBtn.Parent = TitleBar
    local MinCorner = Instance.new("UICorner")
    MinCorner.CornerRadius = UDim.new(0, 4)
    MinCorner.Parent = MinBtn

    MinBtn.MouseButton1Click:Connect(function()
        Main.Visible = false
    end)

    CloseBtn.MouseButton1Click:Connect(function()
        saveSettings()
        CONFIG.Enabled = false
        scriptActive = false
        ScreenGui:Destroy()
        print("Fast Breaker ditutup & setting tersimpan!")
    end)

    UserInputService.InputBegan:Connect(function(input, gameProcessed)
        if not gameProcessed and input.KeyCode == Enum.KeyCode.RightShift then
            Main.Visible = not Main.Visible
        end
    end)

    -- Tab Bar
    local TabBar = Instance.new("Frame")
    TabBar.Size = UDim2.new(0.92, 0, 0, 26)
    TabBar.Position = UDim2.new(0.04, 0, 0, 36)
    TabBar.BackgroundColor3 = Color3.fromRGB(28, 28, 34)
    TabBar.BorderSizePixel = 0
    TabBar.Parent = Main
    local TabBarCorner = Instance.new("UICorner")
    TabBarCorner.CornerRadius = UDim.new(0, 6)
    TabBarCorner.Parent = TabBar

    local FarmTabBtn = Instance.new("TextButton")
    FarmTabBtn.Size = UDim2.new(0.5, -2, 1, -2)
    FarmTabBtn.Position = UDim2.new(0, 1, 0, 1)
    FarmTabBtn.BackgroundColor3 = Color3.fromRGB(45, 120, 200)
    FarmTabBtn.Text = "Farm"
    FarmTabBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
    FarmTabBtn.Font = Enum.Font.GothamBold
    FarmTabBtn.TextSize = 11
    FarmTabBtn.Parent = TabBar
    local FarmTabCorner = Instance.new("UICorner")
    FarmTabCorner.CornerRadius = UDim.new(0, 5)
    FarmTabCorner.Parent = FarmTabBtn

    local LogTabBtn = Instance.new("TextButton")
    LogTabBtn.Size = UDim2.new(0.5, -2, 1, -2)
    LogTabBtn.Position = UDim2.new(0.5, 1, 0, 1)
    LogTabBtn.BackgroundColor3 = Color3.fromRGB(35, 35, 42)
    LogTabBtn.Text = "Log (0)"
    LogTabBtn.TextColor3 = Color3.fromRGB(180, 180, 190)
    LogTabBtn.Font = Enum.Font.GothamMedium
    LogTabBtn.TextSize = 11
    LogTabBtn.Parent = TabBar
    local LogTabCorner = Instance.new("UICorner")
    LogTabCorner.CornerRadius = UDim.new(0, 5)
    LogTabCorner.Parent = LogTabBtn

    updateLogTabBadge = function()
        LogTabBtn.Text = string.format("Log (%d)", #CLAIM_LOGS)
    end

    local FarmPage = Instance.new("Frame")
    FarmPage.Name = "FarmPage"
    FarmPage.Size = UDim2.new(1, 0, 1, -66)
    FarmPage.Position = UDim2.new(0, 0, 0, 66)
    FarmPage.BackgroundTransparency = 1
    FarmPage.Parent = Main

    local LogPage = Instance.new("Frame")
    LogPage.Name = "LogPage"
    LogPage.Size = UDim2.new(1, 0, 1, -66)
    LogPage.Position = UDim2.new(0, 0, 0, 66)
    LogPage.BackgroundTransparency = 1
    LogPage.Visible = false
    LogPage.Parent = Main

    local function setTab(tabName)
        if tabName == "Farm" then
            FarmPage.Visible = true
            LogPage.Visible = false
            FarmTabBtn.BackgroundColor3 = Color3.fromRGB(45, 120, 200)
            FarmTabBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
            FarmTabBtn.Font = Enum.Font.GothamBold
            LogTabBtn.BackgroundColor3 = Color3.fromRGB(35, 35, 42)
            LogTabBtn.TextColor3 = Color3.fromRGB(180, 180, 190)
            LogTabBtn.Font = Enum.Font.GothamMedium
            Main.Size = UDim2.new(0, 255, 0, 285)
        else
            FarmPage.Visible = false
            LogPage.Visible = true
            LogTabBtn.BackgroundColor3 = Color3.fromRGB(45, 120, 200)
            LogTabBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
            LogTabBtn.Font = Enum.Font.GothamBold
            FarmTabBtn.BackgroundColor3 = Color3.fromRGB(35, 35, 42)
            FarmTabBtn.TextColor3 = Color3.fromRGB(180, 180, 190)
            FarmTabBtn.Font = Enum.Font.GothamMedium
            Main.Size = UDim2.new(0, 255, 0, 310)
            refreshLogUI()
        end
    end

    FarmTabBtn.MouseButton1Click:Connect(function() setTab("Farm") end)
    LogTabBtn.MouseButton1Click:Connect(function() setTab("Log") end)

    -- [[ FARM CONTROLS ]] --
    local ToggleBtn = Instance.new("TextButton")
    ToggleBtn.Size = UDim2.new(0.9, 0, 0, 30)
    ToggleBtn.Position = UDim2.new(0.05, 0, 0, 4)
    ToggleBtn.BackgroundColor3 = CONFIG.Enabled and Color3.fromRGB(45, 175, 75) or Color3.fromRGB(190, 45, 45)
    ToggleBtn.Text = CONFIG.Enabled and "AUTO FARM: ON" or "AUTO FARM: OFF"
    ToggleBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
    ToggleBtn.Font = Enum.Font.GothamBold
    ToggleBtn.TextSize = 13
    ToggleBtn.Parent = FarmPage
    local BtnCorner = Instance.new("UICorner")
    BtnCorner.CornerRadius = UDim.new(0, 6)
    BtnCorner.Parent = ToggleBtn

    ToggleBtn.MouseButton1Click:Connect(function()
        CONFIG.Enabled = not CONFIG.Enabled
        if CONFIG.Enabled then
            ToggleBtn.BackgroundColor3 = Color3.fromRGB(45, 175, 75)
            ToggleBtn.Text = "AUTO FARM: ON"
            ensureSprayEquipped()
            if CONFIG.AutoEquipBest then
                triggerEquipBest()
            end
        else
            ToggleBtn.BackgroundColor3 = Color3.fromRGB(190, 45, 45)
            ToggleBtn.Text = "AUTO FARM: OFF"
        end
        saveSettings() -- Status ON/OFF tersimpan secara otomatis
    end)

    local TargetModeBtn = Instance.new("TextButton")
    TargetModeBtn.Size = UDim2.new(0.9, 0, 0, 24)
    TargetModeBtn.Position = UDim2.new(0.05, 0, 0, 38)
    TargetModeBtn.BackgroundColor3 = Color3.fromRGB(45, 55, 75)
    TargetModeBtn.Text = getTargetModeLabel(CONFIG.TargetMode)
    TargetModeBtn.TextColor3 = Color3.fromRGB(140, 210, 255)
    TargetModeBtn.Font = Enum.Font.GothamBold
    TargetModeBtn.TextSize = 11
    TargetModeBtn.Parent = FarmPage
    local TargetCorner = Instance.new("UICorner")
    TargetCorner.CornerRadius = UDim.new(0, 5)
    TargetCorner.Parent = TargetModeBtn

    TargetModeBtn.MouseButton1Click:Connect(function()
        if CONFIG.TargetMode == "HighestLuck" then
            CONFIG.TargetMode = "LowestHP"
        elseif CONFIG.TargetMode == "LowestHP" then
            CONFIG.TargetMode = "HighestHP"
        elseif CONFIG.TargetMode == "HighestHP" then
            CONFIG.TargetMode = "Closest"
        else
            CONFIG.TargetMode = "HighestLuck"
        end
        TargetModeBtn.Text = getTargetModeLabel(CONFIG.TargetMode)
        saveSettings()
    end)

    local EquipBestBtn = Instance.new("TextButton")
    EquipBestBtn.Size = UDim2.new(0.9, 0, 0, 24)
    EquipBestBtn.Position = UDim2.new(0.05, 0, 0, 66)
    EquipBestBtn.BackgroundColor3 = CONFIG.AutoEquipBest and Color3.fromRGB(35, 130, 70) or Color3.fromRGB(50, 50, 60)
    EquipBestBtn.Text = string.format("Auto Equip Best (5s): %s", CONFIG.AutoEquipBest and "ON" or "OFF")
    EquipBestBtn.TextColor3 = Color3.fromRGB(240, 240, 240)
    EquipBestBtn.Font = Enum.Font.GothamMedium
    EquipBestBtn.TextSize = 11
    EquipBestBtn.Parent = FarmPage
    local EqCorner = Instance.new("UICorner")
    EqCorner.CornerRadius = UDim.new(0, 5)
    EqCorner.Parent = EquipBestBtn

    EquipBestBtn.MouseButton1Click:Connect(function()
        CONFIG.AutoEquipBest = not CONFIG.AutoEquipBest
        EquipBestBtn.BackgroundColor3 = CONFIG.AutoEquipBest and Color3.fromRGB(35, 130, 70) or Color3.fromRGB(50, 50, 60)
        EquipBestBtn.Text = string.format("Auto Equip Best (5s): %s", CONFIG.AutoEquipBest and "ON" or "OFF")
        if CONFIG.AutoEquipBest then
            triggerEquipBest()
        end
        saveSettings()
    end)

    -- Tombol Auto Reconnect
    local ReconnectBtn = Instance.new("TextButton")
    ReconnectBtn.Size = UDim2.new(0.9, 0, 0, 24)
    ReconnectBtn.Position = UDim2.new(0.05, 0, 0, 94)
    ReconnectBtn.BackgroundColor3 = CONFIG.AutoReconnect and Color3.fromRGB(35, 130, 70) or Color3.fromRGB(50, 50, 60)
    ReconnectBtn.Text = string.format("Auto Reconnect: %s", CONFIG.AutoReconnect and "ON" or "OFF")
    ReconnectBtn.TextColor3 = Color3.fromRGB(240, 240, 240)
    ReconnectBtn.Font = Enum.Font.GothamMedium
    ReconnectBtn.TextSize = 11
    ReconnectBtn.Parent = FarmPage
    local RecCorner = Instance.new("UICorner")
    RecCorner.CornerRadius = UDim.new(0, 5)
    RecCorner.Parent = ReconnectBtn

    ReconnectBtn.MouseButton1Click:Connect(function()
        CONFIG.AutoReconnect = not CONFIG.AutoReconnect
        ReconnectBtn.BackgroundColor3 = CONFIG.AutoReconnect and Color3.fromRGB(35, 130, 70) or Color3.fromRGB(50, 50, 60)
        ReconnectBtn.Text = string.format("Auto Reconnect: %s", CONFIG.AutoReconnect and "ON" or "OFF")
        saveSettings()
    end)

    local SetBaseBtn = Instance.new("TextButton")
    SetBaseBtn.Size = UDim2.new(0.9, 0, 0, 24)
    SetBaseBtn.Position = UDim2.new(0.05, 0, 0, 122)
    SetBaseBtn.BackgroundColor3 = Color3.fromRGB(40, 40, 50)
    SetBaseBtn.Text = "Set Base Pos (Current)"
    SetBaseBtn.TextColor3 = Color3.fromRGB(210, 210, 210)
    SetBaseBtn.Font = Enum.Font.GothamMedium
    SetBaseBtn.TextSize = 11
    SetBaseBtn.Parent = FarmPage
    local SetBaseCorner = Instance.new("UICorner")
    SetBaseCorner.CornerRadius = UDim.new(0, 5)
    SetBaseCorner.Parent = SetBaseBtn

    SetBaseBtn.MouseButton1Click:Connect(function()
        local root = getRoot()
        if root then
            CONFIG.BaseCFrame = root.CFrame
            saveSettings()
            SetBaseBtn.Text = "[OK] Base Updated!"
            task.delay(1.2, function()
                SetBaseBtn.Text = "Set Base Pos (Current)"
            end)
        end
    end)

    local MinIncomeBox = Instance.new("TextBox")
    MinIncomeBox.Size = UDim2.new(0.9, 0, 0, 26)
    MinIncomeBox.Position = UDim2.new(0.05, 0, 0, 150)
    MinIncomeBox.BackgroundColor3 = Color3.fromRGB(32, 32, 40)
    MinIncomeBox.Text = CONFIG.MinIncomeText or formatShorthand(CONFIG.MinIncome)
    MinIncomeBox.PlaceholderText = "Threshold $/s (Contoh: 100K, 1M)"
    MinIncomeBox.TextColor3 = Color3.fromRGB(100, 255, 150)
    MinIncomeBox.Font = Enum.Font.GothamBold
    MinIncomeBox.TextSize = 12
    MinIncomeBox.Parent = FarmPage
    local BoxCorner = Instance.new("UICorner")
    BoxCorner.CornerRadius = UDim.new(0, 5)
    BoxCorner.Parent = MinIncomeBox

    MinIncomeBox.FocusLost:Connect(function()
        local parsed = parseShorthand(MinIncomeBox.Text)
        if parsed > 0 then
            CONFIG.MinIncome = parsed
            CONFIG.MinIncomeText = formatShorthand(parsed)
            MinIncomeBox.Text = CONFIG.MinIncomeText
            saveSettings()
        else
            MinIncomeBox.Text = formatShorthand(CONFIG.MinIncome)
        end
    end)

    local DropdownBtn = Instance.new("TextButton")
    DropdownBtn.Size = UDim2.new(0.9, 0, 0, 26)
    DropdownBtn.Position = UDim2.new(0.05, 0, 0, 180)
    DropdownBtn.BackgroundColor3 = Color3.fromRGB(48, 48, 62)
    DropdownBtn.Text = "[v] Filter Rarity (Klik Buka/Tutup)"
    DropdownBtn.TextColor3 = Color3.fromRGB(240, 240, 255)
    DropdownBtn.Font = Enum.Font.GothamMedium
    DropdownBtn.TextSize = 11
    DropdownBtn.Parent = FarmPage
    local DropCorner = Instance.new("UICorner")
    DropCorner.CornerRadius = UDim.new(0, 5)
    DropCorner.Parent = DropdownBtn

    local RarityListFrame = Instance.new("ScrollingFrame")
    RarityListFrame.Name = "RarityList"
    RarityListFrame.Size = UDim2.new(0.9, 0, 0, 140)
    RarityListFrame.Position = UDim2.new(0.05, 0, 0, 210)
    RarityListFrame.BackgroundColor3 = Color3.fromRGB(28, 28, 36)
    RarityListFrame.BorderSizePixel = 0
    RarityListFrame.ScrollBarThickness = 4
    RarityListFrame.CanvasSize = UDim2.new(0, 0, 0, #ALL_RARITIES * 28 + 6)
    RarityListFrame.Visible = false
    RarityListFrame.Parent = FarmPage
    local ListCorner = Instance.new("UICorner")
    ListCorner.CornerRadius = UDim.new(0, 6)
    ListCorner.Parent = RarityListFrame

    local listLayout = Instance.new("UIListLayout")
    listLayout.Padding = UDim.new(0, 3)
    listLayout.HorizontalAlignment = Enum.HorizontalAlignment.Center
    listLayout.Parent = RarityListFrame

    for _, rName in ipairs(ALL_RARITIES) do
        local rBtn = Instance.new("TextButton")
        rBtn.Size = UDim2.new(0.94, 0, 0, 24)
        rBtn.BackgroundColor3 = CONFIG.TargetRarities[rName] and Color3.fromRGB(30, 120, 200) or Color3.fromRGB(38, 38, 46)
        rBtn.Text = string.format("[%s] %s", CONFIG.TargetRarities[rName] and "ON" or "OFF", rName)
        rBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
        rBtn.Font = Enum.Font.Gotham
        rBtn.TextSize = 11
        rBtn.Parent = RarityListFrame

        local rCorner = Instance.new("UICorner")
        rCorner.CornerRadius = UDim.new(0, 4)
        rCorner.Parent = rBtn

        rBtn.MouseButton1Click:Connect(function()
            CONFIG.TargetRarities[rName] = not CONFIG.TargetRarities[rName]
            rBtn.BackgroundColor3 = CONFIG.TargetRarities[rName] and Color3.fromRGB(30, 120, 200) or Color3.fromRGB(38, 38, 46)
            rBtn.Text = string.format("[%s] %s", CONFIG.TargetRarities[rName] and "ON" or "OFF", rName)
            saveSettings()
        end)
    end

    DropdownBtn.MouseButton1Click:Connect(function()
        local isOpening = not RarityListFrame.Visible
        RarityListFrame.Visible = isOpening
        if isOpening then
            DropdownBtn.Text = "[^] Filter Rarity (Klik Buka/Tutup)"
            Main.Size = UDim2.new(0, 255, 0, 420)
        else
            DropdownBtn.Text = "[v] Filter Rarity (Klik Buka/Tutup)"
            Main.Size = UDim2.new(0, 255, 0, 285)
        end
    end)

    -- Log Page
    local LogHeader = Instance.new("Frame")
    LogHeader.Size = UDim2.new(0.9, 0, 0, 24)
    LogHeader.Position = UDim2.new(0.05, 0, 0, 4)
    LogHeader.BackgroundTransparency = 1
    LogHeader.Parent = LogPage

    local LogCountText = Instance.new("TextLabel")
    LogCountText.Size = UDim2.new(0.65, 0, 1, 0)
    LogCountText.BackgroundTransparency = 1
    LogCountText.Text = "Riwayat Claim:"
    LogCountText.TextColor3 = Color3.fromRGB(200, 200, 210)
    LogCountText.Font = Enum.Font.GothamBold
    LogCountText.TextSize = 11
    LogCountText.TextXAlignment = Enum.TextXAlignment.Left
    LogCountText.Parent = LogHeader

    local ClearLogBtn = Instance.new("TextButton")
    ClearLogBtn.Size = UDim2.new(0.35, 0, 1, 0)
    ClearLogBtn.Position = UDim2.new(0.65, 0, 0, 0)
    ClearLogBtn.BackgroundColor3 = Color3.fromRGB(45, 45, 55)
    ClearLogBtn.Text = "Clear Log"
    ClearLogBtn.TextColor3 = Color3.fromRGB(240, 120, 120)
    ClearLogBtn.Font = Enum.Font.GothamMedium
    ClearLogBtn.TextSize = 10
    ClearLogBtn.Parent = LogHeader
    local ClrCorner = Instance.new("UICorner")
    ClrCorner.CornerRadius = UDim.new(0, 4)
    ClrCorner.Parent = ClearLogBtn

    local LogScroll = Instance.new("ScrollingFrame")
    LogScroll.Size = UDim2.new(0.9, 0, 1, -34)
    LogScroll.Position = UDim2.new(0.05, 0, 0, 30)
    LogScroll.BackgroundColor3 = Color3.fromRGB(26, 26, 32)
    LogScroll.BorderSizePixel = 0
    LogScroll.ScrollBarThickness = 4
    LogScroll.Parent = LogPage
    local LogScrollCorner = Instance.new("UICorner")
    LogScrollCorner.CornerRadius = UDim.new(0, 6)
    LogScrollCorner.Parent = LogScroll

    local logLayout = Instance.new("UIListLayout")
    logLayout.Padding = UDim.new(0, 3)
    logLayout.HorizontalAlignment = Enum.HorizontalAlignment.Center
    logLayout.Parent = LogScroll

    refreshLogUI = function()
        if not LogScroll then return end
        for _, child in ipairs(LogScroll:GetChildren()) do
            if child:IsA("Frame") then
                child:Destroy()
            end
        end

        LogCountText.Text = string.format("Total Claim: %d Pet", #CLAIM_LOGS)
        LogScroll.CanvasSize = UDim2.new(0, 0, 0, #CLAIM_LOGS * 32 + 6)

        if #CLAIM_LOGS == 0 then
            local emptyText = Instance.new("TextLabel")
            emptyText.Size = UDim2.new(1, 0, 0, 50)
            emptyText.BackgroundTransparency = 1
            emptyText.Text = "Belum ada pet yang di-claim.\n(Pet di atas threshold akan muncul di sini)"
            emptyText.TextColor3 = Color3.fromRGB(120, 120, 130)
            emptyText.Font = Enum.Font.Gotham
            emptyText.TextSize = 10
            emptyText.Parent = LogScroll
            return
        end

        for _, item in ipairs(CLAIM_LOGS) do
            local card = Instance.new("Frame")
            card.Size = UDim2.new(0.96, 0, 0, 28)
            card.BackgroundColor3 = Color3.fromRGB(34, 34, 42)
            card.BorderSizePixel = 0
            card.Parent = LogScroll
            local cardCorner = Instance.new("UICorner")
            cardCorner.CornerRadius = UDim.new(0, 4)
            cardCorner.Parent = card

            local nameLabel = Instance.new("TextLabel")
            nameLabel.Size = UDim2.new(0.58, 0, 1, 0)
            nameLabel.Position = UDim2.new(0, 6, 0, 0)
            nameLabel.BackgroundTransparency = 1
            nameLabel.Text = string.format("[%s] %s", item.time, item.name)
            nameLabel.TextColor3 = Color3.fromRGB(240, 240, 240)
            nameLabel.Font = Enum.Font.GothamMedium
            nameLabel.TextSize = 10
            nameLabel.TextXAlignment = Enum.TextXAlignment.Left
            nameLabel.Parent = card

            local incomeLabel = Instance.new("TextLabel")
            incomeLabel.Size = UDim2.new(0.38, -6, 1, 0)
            incomeLabel.Position = UDim2.new(0.62, 0, 0, 0)
            incomeLabel.BackgroundTransparency = 1
            incomeLabel.Text = string.format("+$%s/s", formatShorthand(item.income))
            incomeLabel.TextColor3 = Color3.fromRGB(110, 255, 160)
            incomeLabel.Font = Enum.Font.GothamBold
            incomeLabel.TextSize = 11
            incomeLabel.TextXAlignment = Enum.TextXAlignment.Right
            incomeLabel.Parent = card
        end
    end

    ClearLogBtn.MouseButton1Click:Connect(function()
        table.clear(CLAIM_LOGS)
        updateLogTabBadge()
        refreshLogUI()
    end)
end

createUI()

-- Jika setting terakhir adalah ON, langsung mulai farm otomatis
if CONFIG.Enabled then
    task.spawn(function()
        task.wait(0.6)
        ensureSprayEquipped()
        if CONFIG.AutoEquipBest then
            triggerEquipBest()
        end
    end)
end

print("FAST BREAKER: Auto-Save ON/OFF + Auto Reconnect Loaded!")
