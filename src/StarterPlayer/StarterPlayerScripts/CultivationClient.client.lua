--[[
    CultivationClient.client.lua
    จัดการ HUD แสดงค่าตบะ (CultivationExp), พลังปราณ (Qi), ขอบเขตพลัง (Realms),
    การนั่งสมาธิ (Meditation M) และการแจ้งเตือนคอขวด 100% เชื่อมต่อกับ BreakthroughTrialUI
]]

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local UserInputService = game:GetService("UserInputService")
local TweenService = game:GetService("TweenService")

local localPlayer = Players.LocalPlayer
local playerGui = localPlayer:WaitForChild("PlayerGui")

local CultivationConfig = require(ReplicatedStorage:WaitForChild("SharedModules"):WaitForChild("CultivationConfig"))
local CultivationTypes = require(ReplicatedStorage:WaitForChild("SharedModules"):WaitForChild("CultivationTypes"))
local NetworkEvents = require(ReplicatedStorage:WaitForChild("Remotes"):WaitForChild("NetworkEvents"))
local UIManager = require(ReplicatedStorage:WaitForChild("SharedModules"):WaitForChild("UIManager"))

-- สร้าง ScreenGui
local screenGui = Instance.new("ScreenGui")
screenGui.Name = "CultivationGui"
screenGui.ResetOnSpawn = false
screenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
screenGui.Parent = playerGui

--------------------------------------------------------------------------------
-- 1. สร้างหน้าต่าง Cultivation HUD (ด้านบนกลางจอ)
--------------------------------------------------------------------------------
local hudFrame = Instance.new("Frame")
hudFrame.Name = "CultivationHUD"
hudFrame.Size = UDim2.new(0, 440, 0, 115)
hudFrame.Position = UDim2.new(0.5, -220, 0, 12)
hudFrame.BackgroundColor3 = Color3.fromRGB(18, 21, 28)
hudFrame.BorderSizePixel = 0
hudFrame.Parent = screenGui

local hudCorner = Instance.new("UICorner")
hudCorner.CornerRadius = UDim.new(0, 12)
hudCorner.Parent = hudFrame

local hudStroke = Instance.new("UIStroke")
hudStroke.Thickness = 2
hudStroke.Color = Color3.fromRGB(120, 240, 180)
hudStroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
hudStroke.Parent = hudFrame

-- หัวข้อ: ฉายา + ขอบเขต
local headerFrame = Instance.new("Frame")
headerFrame.Size = UDim2.new(1, -20, 0, 26)
headerFrame.Position = UDim2.new(0, 10, 0, 6)
headerFrame.BackgroundTransparency = 1
headerFrame.Parent = hudFrame

local titleLabel = Instance.new("TextLabel")
titleLabel.Name = "TitleLabel"
titleLabel.Size = UDim2.new(0.55, 0, 1, 0)
titleLabel.BackgroundTransparency = 1
titleLabel.Text = "« ผู้เริ่มต้นวิถีเซียน »"
titleLabel.TextColor3 = Color3.fromRGB(180, 210, 190)
titleLabel.Font = Enum.Font.GothamBold
titleLabel.TextSize = 13
titleLabel.TextXAlignment = Enum.TextXAlignment.Left
titleLabel.Parent = headerFrame

local realmLabel = Instance.new("TextLabel")
realmLabel.Name = "RealmLabel"
realmLabel.Size = UDim2.new(0.45, 0, 1, 0)
realmLabel.Position = UDim2.new(0.55, 0, 0, 0)
realmLabel.BackgroundTransparency = 1
realmLabel.Text = "☯ ครรภ์เซียน (1)"
realmLabel.TextColor3 = Color3.fromRGB(255, 230, 120)
realmLabel.Font = Enum.Font.GothamBold
realmLabel.TextSize = 14
realmLabel.TextXAlignment = Enum.TextXAlignment.Right
realmLabel.Parent = headerFrame

-- แถบความคืบหน้าของตบะ (Tapasya Progress Bar)
local progressBg = Instance.new("Frame")
progressBg.Name = "ProgressBg"
progressBg.Size = UDim2.new(1, -20, 0, 18)
progressBg.Position = UDim2.new(0, 10, 0, 36)
progressBg.BackgroundColor3 = Color3.fromRGB(32, 36, 48)
progressBg.BorderSizePixel = 0
progressBg.Parent = hudFrame

local progressCorner = Instance.new("UICorner")
progressCorner.CornerRadius = UDim.new(0, 9)
progressCorner.Parent = progressBg

local progressFill = Instance.new("Frame")
progressFill.Name = "ProgressFill"
progressFill.Size = UDim2.new(0, 0, 1, 0)
progressFill.BackgroundColor3 = Color3.fromRGB(80, 240, 150)
progressFill.BorderSizePixel = 0
progressFill.Parent = progressBg

local fillCorner = Instance.new("UICorner")
fillCorner.CornerRadius = UDim.new(0, 9)
fillCorner.Parent = progressFill

local progressText = Instance.new("TextLabel")
progressText.Name = "ProgressText"
progressText.Size = UDim2.new(1, 0, 1, 0)
progressText.BackgroundTransparency = 1
progressText.Text = "ตบะ: 0 / 1000 (0%)"
progressText.TextColor3 = Color3.fromRGB(255, 255, 255)
progressText.Font = Enum.Font.GothamBold
progressText.TextSize = 11
progressText.Parent = progressBg

-- แถบพลังปราณ (Qi Bar)
local qiBg = Instance.new("Frame")
qiBg.Name = "QiBg"
qiBg.Size = UDim2.new(1, -20, 0, 14)
qiBg.Position = UDim2.new(0, 10, 0, 58)
qiBg.BackgroundColor3 = Color3.fromRGB(32, 36, 48)
qiBg.BorderSizePixel = 0
qiBg.Parent = hudFrame

local qiCorner = Instance.new("UICorner")
qiCorner.CornerRadius = UDim.new(0, 7)
qiCorner.Parent = qiBg

local qiFill = Instance.new("Frame")
qiFill.Name = "QiFill"
qiFill.Size = UDim2.new(0, 0, 1, 0)
qiFill.BackgroundColor3 = Color3.fromRGB(70, 170, 255)
qiFill.BorderSizePixel = 0
qiFill.Parent = qiBg

local qiFillCorner = Instance.new("UICorner")
qiFillCorner.CornerRadius = UDim.new(0, 7)
qiFillCorner.Parent = qiFill

local qiText = Instance.new("TextLabel")
qiText.Name = "QiText"
qiText.Size = UDim2.new(1, 0, 1, 0)
qiText.BackgroundTransparency = 1
qiText.Text = "พลังปราณ: 0 / 50"
qiText.TextColor3 = Color3.fromRGB(220, 240, 255)
qiText.Font = Enum.Font.GothamBold
qiText.TextSize = 10
qiText.Parent = qiBg

-- ป้ายเตือนคอขวด 100% (Bottleneck Alert Banner)
local bottleneckBanner = Instance.new("TextButton")
bottleneckBanner.Name = "BottleneckBanner"
bottleneckBanner.Size = UDim2.new(1, -20, 0, 28)
bottleneckBanner.Position = UDim2.new(0, 10, 0, 78)
bottleneckBanner.BackgroundColor3 = Color3.fromRGB(180, 50, 50)
bottleneckBanner.Text = "🔒 ติดคอขวด 100%! [แตะที่นี่เพื่อทำพิธีทะลวงขั้น]"
bottleneckBanner.TextColor3 = Color3.fromRGB(255, 240, 180)
bottleneckBanner.Font = Enum.Font.GothamBold
bottleneckBanner.TextSize = 12
bottleneckBanner.Visible = false
bottleneckBanner.Parent = hudFrame

local bannerCorner = Instance.new("UICorner")
bannerCorner.CornerRadius = UDim.new(0, 8)
bannerCorner.Parent = bottleneckBanner

local bannerStroke = Instance.new("UIStroke")
bannerStroke.Thickness = 1.5
bannerStroke.Color = Color3.fromRGB(255, 215, 80)
bannerStroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
bannerStroke.Parent = bottleneckBanner

-- ปุ่มนั่งสมาธิบนหน้าจอ (Touch & Mouse Friendly)
local meditateHudBtn = Instance.new("TextButton")
meditateHudBtn.Name = "MeditateHudButton"
meditateHudBtn.Size = UDim2.new(0, 135, 0, 42)
meditateHudBtn.Position = UDim2.new(0.5, -67, 0, 134)
meditateHudBtn.BackgroundColor3 = Color3.fromRGB(35, 110, 75)
meditateHudBtn.Text = "🧘 นั่งสมาธิ (M)"
meditateHudBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
meditateHudBtn.Font = Enum.Font.GothamBold
meditateHudBtn.TextSize = 13
meditateHudBtn.Parent = screenGui

local medCorner = Instance.new("UICorner")
medCorner.CornerRadius = UDim.new(0, 10)
medCorner.Parent = meditateHudBtn

local medStroke = Instance.new("UIStroke")
medStroke.Thickness = 2
medStroke.Color = Color3.fromRGB(120, 240, 180)
medStroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
medStroke.Parent = meditateHudBtn

--------------------------------------------------------------------------------
-- 2. ฟังก์ชันอัปเดต HUD จากข้อมูล Cultivation Snapshot
--------------------------------------------------------------------------------
local function updateHUD(cultData)
    if not cultData then return end

    local realmLevel = cultData.RealmLevel or 1
    local realmCfg = CultivationConfig.Realms[realmLevel] or CultivationConfig.Realms[1]
    local exp = cultData.CultivationExp or 0
    local req = cultData.RequiredExp or (realmCfg and realmCfg.RequiredExp or 1000)
    local pct = math.clamp(exp / req, 0, 1)

    titleLabel.Text = "« " .. (realmCfg.Title or "ผู้บำเพ็ญเพียร") .. " »"
    realmLabel.Text = string.format("☯ %s", realmCfg.Name)
    realmLabel.TextColor3 = realmCfg.Color or Color3.fromRGB(255, 230, 120)

    -- ทวีเนอร์แถบตบะ
    TweenService:Create(progressFill, TweenInfo.new(0.3, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
        Size = UDim2.new(pct, 0, 1, 0)
    }):Play()

    progressText.Text = string.format("ตบะ: %d / %d (%.0f%%)", exp, req, pct * 100)

    -- แถบพลังปราณ (Qi)
    local qi = cultData.Qi or localPlayer:GetAttribute("Chi") or 0
    local maxQi = cultData.MaxQi or localPlayer:GetAttribute("MaxQi") or 50
    local qiPct = (maxQi > 0) and math.clamp(qi / maxQi, 0, 1) or 0

    TweenService:Create(qiFill, TweenInfo.new(0.3, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
        Size = UDim2.new(qiPct, 0, 1, 0)
    }):Play()

    qiText.Text = string.format("พลังปราณ: %d / %d", math.floor(qi), maxQi)

    -- ตรวจสอบคอขวด
    local isBottleneck = (cultData.BreakthroughState == CultivationTypes.BreakthroughState.Ready) or (exp >= req)
    bottleneckBanner.Visible = isBottleneck

    -- สลับสีปุ่มนั่งสมาธิ
    local isMeditating = cultData.IsMeditating or localPlayer:GetAttribute("IsMeditating") or false
    if isMeditating then
        meditateHudBtn.BackgroundColor3 = Color3.fromRGB(160, 90, 30)
        meditateHudBtn.Text = "🚶 ลุกขึ้นยืน (M)"
    else
        meditateHudBtn.BackgroundColor3 = Color3.fromRGB(35, 110, 75)
        meditateHudBtn.Text = "🧘 นั่งสมาธิ (M)"
    end
end

-- รับการซิงก์ Cultivation จาก Server
NetworkEvents.SyncCultivation.OnClientEvent:Connect(function(cultData)
    updateHUD(cultData)
end)

NetworkEvents.MeditationStateChanged.OnClientEvent:Connect(function(isMeditating)
    if isMeditating then
        meditateHudBtn.BackgroundColor3 = Color3.fromRGB(160, 90, 30)
        meditateHudBtn.Text = "🚶 ลุกขึ้นยืน (M)"
    else
        meditateHudBtn.BackgroundColor3 = Color3.fromRGB(35, 110, 75)
        meditateHudBtn.Text = "🧘 นั่งสมาธิ (M)"
    end
end)

-- กดปุ่ม M เพื่อสลับการนั่งสมาธิ
local function toggleMeditation()
    NetworkEvents.ToggleMeditation:InvokeServer()
end

meditateHudBtn.Activated:Connect(toggleMeditation)

UserInputService.InputBegan:Connect(function(input, gpe)
    if gpe then return end
    if input.KeyCode == Enum.KeyCode.M then
        toggleMeditation()
    elseif input.KeyCode == Enum.KeyCode.P then
        -- กด P หรือคลิกป้ายคอขวดเพื่อเปิดหน้าต่างทะลวงขั้น
        if _G.BreakthroughTrialUI then
            _G.BreakthroughTrialUI:OpenModal()
        end
    end
end)

-- แตะป้ายคอขวดเพื่อเปิดหน้าต่างทะลวงขั้น
bottleneckBanner.Activated:Connect(function()
    if _G.BreakthroughTrialUI then
        _G.BreakthroughTrialUI:OpenModal()
    end
end)

-- ดึงข้อมูลครั้งแรกเมื่อโหลดเสร็จ
task.spawn(function()
    task.wait(1)
    NetworkEvents.RequestInitialData:FireServer()
end)

print("✅ [Client] CultivationClient & Meditation Controller ทำงานสมบูรณ์!")
