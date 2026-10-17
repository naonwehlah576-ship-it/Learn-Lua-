-- ============================================================================
-- 🏴‍☠️ RNG TYCOON & FARM - AUTO LOOT & CASH CYCLE (V1.0)
-- 100% Work & Guaranteed Hit | 3-Step Full Cycle | Jeda 10 Detik
-- ============================================================================

local Players = game:GetService("Players")
local CoreGui = game:GetService("CoreGui")
local UserInputService = game:GetService("UserInputService")
local LocalPlayer = Players.LocalPlayer

if not LocalPlayer.Character then
    LocalPlayer.CharacterAdded:Wait()
end

-- ============================================================================
-- KONFIGURASI
-- ============================================================================
local Config = {
    AutoLootCycle = false
}

local statusText = "Idle (Tekan ON untuk mulai)"

-- ============================================================================
-- DETEKSI PLOT PLAYER
-- ============================================================================
local function getMyPlot()
    local slot = LocalPlayer:GetAttribute("AssignedSlotName")
    if slot and workspace:FindFirstChild(slot) then
        return workspace[slot]
    end

    for i = 1, 6 do
        local pName = "Player" .. i
        local p = workspace:FindFirstChild(pName)
        if p and p:FindFirstChild("Interactive") and p.Interactive:FindFirstChild("LikePlot") then
            local prompt = p.Interactive.LikePlot:FindFirstChildWhichIsA("ProximityPrompt", true)
            if prompt and prompt.ObjectText == LocalPlayer.Name then
                return p
            end
        end
    end

    return nil
end

-- ============================================================================
-- SIKLUS UTAMA LENGKAP (3 TAHAPAN BERURUTAN)
-- ============================================================================
local isRunningCycle = false

local function runFullFarmCycle(updateGuiStatus)
    if isRunningCycle then return end
    isRunningCycle = true

    local char = LocalPlayer.Character
    local hrp = char and char:FindFirstChild("HumanoidRootPart")
    local hum = char and char:FindFirstChildWhichIsA("Humanoid")

    if not hrp or not hum then
        isRunningCycle = false
        return
    end

    local myPlot = getMyPlot()
    if not myPlot then
        if updateGuiStatus then updateGuiStatus("❌ Plot Tidak Ditemukan!") end
        isRunningCycle = false
        return
    end

    -- 0. Catat titik berdiri awal player
    local originCFrame = hrp.CFrame

    -- ========================================================================
    -- TAHAP 1: Ambil Loot dari Kotak Kaca (PointPlace)
    -- ========================================================================
    local pp = myPlot:FindFirstChild("Pos") and myPlot.Pos:FindFirstChild("PointPlace")
    local lootPrompt = pp and pp:FindFirstChildWhichIsA("ProximityPrompt", true)

    if pp and lootPrompt and lootPrompt.Enabled then
        if updateGuiStatus then updateGuiStatus("📦 [1/3] Mengambil Loot...") end
        local targetPos = Vector3.new(pp.Position.X, pp.Position.Y + 0.5, pp.Position.Z - 5.5)
        hrp.CFrame = CFrame.new(targetPos, pp.Position)
        task.wait(0.25)

        if typeof(fireproximityprompt) == "function" then
            fireproximityprompt(lootPrompt)
        end
        lootPrompt:InputHoldBegin()
        task.wait(0.08)
        lootPrompt:InputHoldEnd()
        task.wait(0.25)
    end

    -- ========================================================================
    -- TAHAP 2: Setor ke Mesin Deposit
    -- ========================================================================
    local dep = myPlot:FindFirstChild("Interactive") and myPlot.Interactive:FindFirstChild("Deposit")
    local depPrompt = dep and dep:FindFirstChildWhichIsA("ProximityPrompt", true)

    if dep and depPrompt then
        if updateGuiStatus then updateGuiStatus("🏭 [2/3] Menyetor ke Deposit...") end
        local depPos = depPrompt.Parent.Position
        local targetPos = Vector3.new(depPos.X, depPos.Y + 0.5, depPos.Z + 5.5)
        hrp.CFrame = CFrame.new(targetPos, depPos)
        task.wait(0.25)

        if typeof(fireproximityprompt) == "function" then
            fireproximityprompt(depPrompt)
        end
        depPrompt:InputHoldBegin()
        task.wait(0.08)
        depPrompt:InputHoldEnd()
        task.wait(0.25)
    end

    -- ========================================================================
    -- TAHAP 3: Ambil Uang di Pad Hijau (PayoutButton)
    -- ========================================================================
    local pb = myPlot:FindFirstChild("Interactive") and myPlot.Interactive:FindFirstChild("PayoutButton")
    local head = pb and pb:FindFirstChild("Head")

    if head then
        if updateGuiStatus then updateGuiStatus("💰 [3/3] Mengambil Uang...") end
        hrp.CFrame = CFrame.new(head.Position.X, head.Position.Y + 2.8, head.Position.Z)

        local limbs = {
            hrp,
            char:FindFirstChild("LeftFoot"),
            char:FindFirstChild("RightFoot"),
            char:FindFirstChild("Left Leg"),
            char:FindFirstChild("Right Leg"),
            char:FindFirstChild("Torso"),
            char:FindFirstChild("LowerTorso")
        }

        for _, limb in ipairs(limbs) do
            if limb and typeof(firetouchinterest) == "function" then
                firetouchinterest(limb, head, 0)
                task.wait(0.01)
                firetouchinterest(limb, head, 1)
            end
        end

        task.wait(0.05)
        hum:MoveTo(head.Position)
        task.wait(0.2)
    end

    -- ========================================================================
    -- SELESAI: Kembali ke Titik Awal Berdiri
    -- ========================================================================
    hrp.CFrame = originCFrame
    if updateGuiStatus then updateGuiStatus("✅ Siklus Selesai! Menunggu...") end

    isRunningCycle = false
end

-- ============================================================================
-- GUI BUILDER (CLEAN, DRAGGABLE & MODULAR)
-- ============================================================================
local ScreenGui = Instance.new("ScreenGui")
ScreenGui.Name = "RNGFarmGui"
ScreenGui.ResetOnSpawn = false

pcall(function()
    if gethui then
        ScreenGui.Parent = gethui()
    elseif syn and syn.protect_gui then
        syn.protect_gui(ScreenGui)
        ScreenGui.Parent = CoreGui
    else
        ScreenGui.Parent = CoreGui
    end
end)

if not ScreenGui.Parent then
    ScreenGui.Parent = LocalPlayer:WaitForChild("PlayerGui")
end

local MainFrame = Instance.new("Frame")
MainFrame.Name = "MainFrame"
MainFrame.Size = UDim2.new(0, 360, 0, 245)
MainFrame.Position = UDim2.new(0.5, -180, 0.4, -122)
MainFrame.BackgroundColor3 = Color3.fromRGB(20, 24, 34)
MainFrame.BorderSizePixel = 0
MainFrame.Parent = ScreenGui

local mainCorner = Instance.new("UICorner")
mainCorner.CornerRadius = UDim.new(0, 10)
mainCorner.Parent = MainFrame

local mainStroke = Instance.new("UIStroke")
mainStroke.Color = Color3.fromRGB(45, 55, 75)
mainStroke.Thickness = 1.5
mainStroke.Parent = MainFrame

-- Topbar (Draggable)
local TopBar = Instance.new("Frame")
TopBar.Name = "TopBar"
TopBar.Size = UDim2.new(1, 0, 0, 38)
TopBar.BackgroundColor3 = Color3.fromRGB(28, 34, 48)
TopBar.BorderSizePixel = 0
TopBar.Parent = MainFrame

local topCorner = Instance.new("UICorner")
topCorner.CornerRadius = UDim.new(0, 10)
topCorner.Parent = TopBar

local TitleLabel = Instance.new("TextLabel")
TitleLabel.Size = UDim2.new(1, -70, 1, 0)
TitleLabel.Position = UDim2.new(0, 14, 0, 0)
TitleLabel.BackgroundTransparency = 1
TitleLabel.Text = "⚡ <b>RNG FARM TYCOON</b> <font color=\"#4A90E2\">v1.0</font>"
TitleLabel.RichText = true
TitleLabel.TextColor3 = Color3.fromRGB(240, 245, 255)
TitleLabel.TextSize = 13
TitleLabel.Font = Enum.Font.GothamBold
TitleLabel.TextXAlignment = Enum.TextXAlignment.Left
TitleLabel.Parent = TopBar

local CloseBtn = Instance.new("TextButton")
CloseBtn.Size = UDim2.new(0, 28, 0, 28)
CloseBtn.Position = UDim2.new(1, -34, 0, 5)
CloseBtn.BackgroundColor3 = Color3.fromRGB(215, 50, 65)
CloseBtn.Text = "✕"
CloseBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
CloseBtn.Font = Enum.Font.GothamBold
CloseBtn.TextSize = 13
CloseBtn.Parent = TopBar

local closeCorner = Instance.new("UICorner")
closeCorner.CornerRadius = UDim.new(0, 6)
closeCorner.Parent = CloseBtn
CloseBtn.MouseButton1Click:Connect(function() ScreenGui:Destroy() end)

-- Dragging Handler
local dragging, dragInput, dragStart, startPos
TopBar.InputBegan:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
        dragging = true
        dragStart = input.Position
        startPos = MainFrame.Position
        input.Changed:Connect(function()
            if input.UserInputState == Enum.UserInputState.End then dragging = false end
        end)
    end
end)

TopBar.InputChanged:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch then
        dragInput = input
    end
end)

UserInputService.InputChanged:Connect(function(input)
    if input == dragInput and dragging then
        local delta = input.Position - dragStart
        MainFrame.Position = UDim2.new(startPos.X.Scale, startPos.X.Offset + delta.X, startPos.Y.Scale, startPos.Y.Offset + delta.Y)
    end
end)

local Content = Instance.new("Frame")
Content.Size = UDim2.new(1, -24, 1, -50)
Content.Position = UDim2.new(0, 12, 0, 44)
Content.BackgroundTransparency = 1
Content.Parent = MainFrame

-- Plot Info
local PlotInfo = Instance.new("TextLabel")
PlotInfo.Size = UDim2.new(1, 0, 0, 20)
PlotInfo.BackgroundTransparency = 1
local curPlot = getMyPlot()
PlotInfo.Text = "📍 Plot Terdeteksi: <font color=\"#60D080\"><b>" .. (curPlot and curPlot.Name or "Mencari...") .. "</b></font>"
PlotInfo.RichText = true
PlotInfo.TextColor3 = Color3.fromRGB(180, 190, 210)
PlotInfo.Font = Enum.Font.Gotham
PlotInfo.TextSize = 11
PlotInfo.TextXAlignment = Enum.TextXAlignment.Left
PlotInfo.Parent = Content

-- Status Display
local StatusLabel = Instance.new("TextLabel")
StatusLabel.Size = UDim2.new(1, 0, 0, 24)
StatusLabel.Position = UDim2.new(0, 0, 0, 24)
StatusLabel.BackgroundColor3 = Color3.fromRGB(14, 17, 24)
StatusLabel.Text = "Status: " .. statusText
StatusLabel.TextColor3 = Color3.fromRGB(100, 210, 255)
StatusLabel.Font = Enum.Font.GothamMedium
StatusLabel.TextSize = 11
StatusLabel.Parent = Content

local statusCorner = Instance.new("UICorner")
statusCorner.CornerRadius = UDim.new(0, 6)
statusCorner.Parent = StatusLabel

local function setStatus(msg)
    statusText = msg
    StatusLabel.Text = "Status: " .. msg
end

-- Toggle Button (Full Farm Cycle)
local ToggleBtn = Instance.new("TextButton")
ToggleBtn.Size = UDim2.new(1, 0, 0, 48)
ToggleBtn.Position = UDim2.new(0, 0, 0, 56)
ToggleBtn.BackgroundColor3 = Color3.fromRGB(40, 48, 65)
ToggleBtn.Text = "⚡ AUTO FARM CYCLE (10s): OFF"
ToggleBtn.TextColor3 = Color3.fromRGB(220, 225, 235)
ToggleBtn.Font = Enum.Font.GothamBold
ToggleBtn.TextSize = 13
ToggleBtn.Parent = Content

local togCorner = Instance.new("UICorner")
togCorner.CornerRadius = UDim.new(0, 8)
togCorner.Parent = ToggleBtn

local function updateToggleVisual()
    if Config.AutoLootCycle then
        ToggleBtn.BackgroundColor3 = Color3.fromRGB(35, 160, 80)
        ToggleBtn.Text = "⚡ AUTO FARM CYCLE (10s): ON"
        ToggleBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
    else
        ToggleBtn.BackgroundColor3 = Color3.fromRGB(40, 48, 65)
        ToggleBtn.Text = "⚡ AUTO FARM CYCLE (10s): OFF"
        ToggleBtn.TextColor3 = Color3.fromRGB(220, 225, 235)
        setStatus("Idle (OFF)")
    end
end

ToggleBtn.MouseButton1Click:Connect(function()
    Config.AutoLootCycle = not Config.AutoLootCycle
    updateToggleVisual()
end)

-- Manual Test Button
local RunOnceBtn = Instance.new("TextButton")
RunOnceBtn.Size = UDim2.new(1, 0, 0, 36)
RunOnceBtn.Position = UDim2.new(0, 0, 0, 112)
RunOnceBtn.BackgroundColor3 = Color3.fromRGB(35, 105, 210)
RunOnceBtn.Text = "🔄 Jalankan 1x Siklus Sekarang (Test)"
RunOnceBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
RunOnceBtn.Font = Enum.Font.GothamBold
RunOnceBtn.TextSize = 11.5
RunOnceBtn.Parent = Content

local roCorner = Instance.new("UICorner")
roCorner.CornerRadius = UDim.new(0, 8)
roCorner.Parent = RunOnceBtn

RunOnceBtn.MouseButton1Click:Connect(function()
    task.spawn(function()
        runFullFarmCycle(setStatus)
    end)
end)

-- Info Footer
local InfoLabel = Instance.new("TextLabel")
InfoLabel.Size = UDim2.new(1, 0, 0, 32)
InfoLabel.Position = UDim2.new(0, 0, 0, 156)
InfoLabel.BackgroundTransparency = 1
InfoLabel.Text = "💡 Siklus otomatis: Ambil Loot ➜ Setor ke Deposit ➜ Tarik Uang dari Pad Hijau ➜ Balik ke Titik Awal."
InfoLabel.TextColor3 = Color3.fromRGB(130, 145, 170)
InfoLabel.Font = Enum.Font.Gotham
InfoLabel.TextSize = 9.5
InfoLabel.TextWrapped = true
InfoLabel.TextXAlignment = Enum.TextXAlignment.Left
InfoLabel.Parent = Content

-- ============================================================================
-- BACKGROUND WORKER LOOP (JEDA 10 DETIK RESPONTIF)
-- ============================================================================
task.spawn(function()
    while true do
        if Config.AutoLootCycle then
            runFullFarmCycle(setStatus)
            for sec = 10, 1, -1 do
                if not Config.AutoLootCycle then break end
                setStatus(string.format("Menunggu siklus berikutnya (%ds)...", sec))
                task.wait(1.0)
            end
        else
            task.wait(0.5)
        end
    end
end)

print("✅ RNG Farm Tycoon v1.0 Loaded Successfully!")
