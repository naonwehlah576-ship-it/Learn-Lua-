-- ============================================================================
-- 🏴‍☠️ RNG TYCOON & FARM - AUTO LOOT & CASH CYCLE (V1.0)
-- 100% DIAM (Tanpa Perlu Jalan) | Fast & Guaranteed Hit | Jeda 10 Detik
-- ============================================================================

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local CoreGui = game:GetService("CoreGui")
local UserInputService = game:GetService("UserInputService")
local LocalPlayer = Players.LocalPlayer

-- Tunggu karakter siap
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
    -- 1. Deteksi lewat Attribute game
    local slot = LocalPlayer:GetAttribute("AssignedSlotName")
    if slot and workspace:FindFirstChild(slot) then
        return workspace[slot]
    end

    -- 2. Fallback: Cari di Player1 - Player6 yang LikePlot-nya sesuai nama player
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
-- BYPASS PROXIMITY PROMPT (JARAK JAUH & CEPAT)
-- ============================================================================
local function triggerPrompt(prompt)
    if not prompt or not prompt.Enabled then return false end
    pcall(function()
        local oldDist = prompt.MaxActivationDistance
        local oldLos = prompt.RequiresLineOfSight
        local oldDur = prompt.HoldDuration
        
        prompt.MaxActivationDistance = 999999
        prompt.RequiresLineOfSight = false

        if typeof(fireproximityprompt) == "function" then
            fireproximityprompt(prompt)
        else
            prompt.HoldDuration = 0
            prompt:InputHoldBegin()
            task.wait(0.05)
            prompt:InputHoldEnd()
            prompt.HoldDuration = oldDur
        end

        prompt.MaxActivationDistance = oldDist
        prompt.RequiresLineOfSight = oldLos
    end)
    return true
end

-- ============================================================================
-- SENTUH PAD UANG HIJAU (FIRETOUCHINTEREST - DIAM TOTAL)
-- ============================================================================
local function collectPayoutPad(myPlot)
    local pb = myPlot:FindFirstChild("Interactive") and myPlot.Interactive:FindFirstChild("PayoutButton")
    if not pb then return end

    local char = LocalPlayer.Character
    local hrp = char and char:FindFirstChild("HumanoidRootPart")
    if not hrp then return end

    local targets = {}
    if pb:FindFirstChild("Head") and pb.Head:IsA("BasePart") then table.insert(targets, pb.Head) end
    if pb:FindFirstChild("Deco") and pb.Deco:IsA("BasePart") then table.insert(targets, pb.Deco) end
    for _, child in ipairs(pb:GetChildren()) do
        if child:IsA("BasePart") and not table.find(targets, child) then
            table.insert(targets, child)
        end
    end

    for _, part in ipairs(targets) do
        pcall(function()
            if typeof(firetouchinterest) == "function" then
                firetouchinterest(hrp, part, 0)
                task.wait(0.03)
                firetouchinterest(hrp, part, 1)
            end
        end)
    end
end

-- ============================================================================
-- SIKLUS UTAMA (3 TAHAP: PICK UP -> DEPOSIT -> AMBIL UANG)
-- ============================================================================
local function runFarmCycle(updateGuiStatus)
    local myPlot = getMyPlot()
    if not myPlot then
        if updateGuiStatus then updateGuiStatus("❌ Plot Tidak Ditemukan!") end
        return
    end

    -- TAHAP 1: Ambil Loot dari Kotak Kaca (PointPlace)
    if updateGuiStatus then updateGuiStatus("📦 [1/3] Mengambil Loot...") end
    local pp = myPlot:FindFirstChild("Pos") and myPlot.Pos:FindFirstChild("PointPlace")
    if pp then
        for _, desc in ipairs(pp:GetDescendants()) do
            if desc:IsA("ProximityPrompt") then
                triggerPrompt(desc)
            end
        end
    end
    task.wait(0.3) -- Jeda pas agar server memproses barang masuk ke punggung

    -- TAHAP 2: Setor Loot ke Mesin Deposit
    if updateGuiStatus then updateGuiStatus("🏭 [2/3] Menyetor ke Mesin Deposit...") end
    local dep = myPlot:FindFirstChild("Interactive") and myPlot.Interactive:FindFirstChild("Deposit")
    if dep then
        for _, desc in ipairs(dep:GetDescendants()) do
            if desc:IsA("ProximityPrompt") then
                triggerPrompt(desc)
            end
        end
    end
    task.wait(0.3) -- Jeda pas agar server mendaftarkan setor loot

    -- TAHAP 3: Ambil Uang di Pad Hijau (PayoutButton)
    if updateGuiStatus then updateGuiStatus("💰 [3/3] Mengambil Uang di Pad Hijau...") end
    collectPayoutPad(myPlot)
    task.wait(0.2)

    if updateGuiStatus then updateGuiStatus("✅ Siklus Selesai! Menunggu...") end
end

-- ============================================================================
-- GUI BUILDER (CLEAN, MODULAR, SIAP DITAMBAH FITUR LAIN)
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

-- Main Window
local MainFrame = Instance.new("Frame")
MainFrame.Name = "MainFrame"
MainFrame.Size = UDim2.new(0, 360, 0, 240)
MainFrame.Position = UDim2.new(0.5, -180, 0.4, -120)
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

-- Close Button
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

CloseBtn.MouseButton1Click:Connect(function()
    ScreenGui:Destroy()
end)

-- Dragging Handler
local dragging, dragInput, dragStart, startPos
TopBar.InputBegan:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
        dragging = true
        dragStart = input.Position
        startPos = MainFrame.Position
        input.Changed:Connect(function()
            if input.UserInputState == Enum.UserInputState.End then
                dragging = false
            end
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

-- Content Container
local Content = Instance.new("Frame")
Content.Size = UDim2.new(1, -24, 1, -50)
Content.Position = UDim2.new(0, 12, 0, 44)
Content.BackgroundTransparency = 1
Content.Parent = MainFrame

-- Plot Info Label
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

-- Status Display Label
local StatusLabel = Instance.new("TextLabel")
StatusLabel.Size = UDim2.new(1, 0, 0, 22)
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

-- Button Manual: Run 1x Now
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
        runFarmCycle(setStatus)
    end)
end)

-- Info Note
local InfoLabel = Instance.new("TextLabel")
InfoLabel.Size = UDim2.new(1, 0, 0, 32)
InfoLabel.Position = UDim2.new(0, 0, 0, 154)
InfoLabel.BackgroundTransparency = 1
InfoLabel.Text = "💡 Siklus otomatis menjalankan: Pick Up Loot (Kotak Kaca) ➜ Setor ke Mesin Deposit ➜ Tarik Uang dari Pad Hijau tanpa karakter harus bergerak."
InfoLabel.TextColor3 = Color3.fromRGB(130, 145, 170)
InfoLabel.Font = Enum.Font.Gotham
InfoLabel.TextSize = 9.5
InfoLabel.TextWrapped = true
InfoLabel.TextXAlignment = Enum.TextXAlignment.Left
InfoLabel.Parent = Content

-- ============================================================================
-- BACKGROUND WORKER LOOP (JEDA 10 DETIK)
-- ============================================================================
task.spawn(function()
    while true do
        if Config.AutoLootCycle then
            runFarmCycle(setStatus)
            -- Jeda 10 detik dengan countdown di status bar
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

print("✅ RNG Farm Tycoon Script Loaded Successfully!")
