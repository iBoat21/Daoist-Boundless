--[[
    BreakthroughTrialUI.client.lua
    หน้าต่างอินเตอร์เฟซและมินิเกมบททดสอบทะลวงขั้น (Playable Breakthrough Trials MVP)
    - รองรับทั้ง Touch บนมือถือ และ Mouse/Keyboard บน PC
    - มีหน้าสรุปพิธี (Preparation Summary) พร้อม Checklist วัตถุดิบ
    - Trial 1: มินิเกมจังหวะลมหายใจ 3 ช่วง (Breathing Rhythm Minigame)
    - Trial 2: มินิเกมวัฏจักรเบญจธาตุก่อเกิด (Five Elements Generation Minigame)
    - หน้าฉลองความสำเร็จ (Victory Celebration)
]]

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")
local SoundService = game:GetService("SoundService")

local localPlayer = Players.LocalPlayer
local playerGui = localPlayer:WaitForChild("PlayerGui")

local CultivationConfig = require(ReplicatedStorage:WaitForChild("SharedModules"):WaitForChild("CultivationConfig"))
local CultivationTypes = require(ReplicatedStorage:WaitForChild("SharedModules"):WaitForChild("CultivationTypes"))
local NetworkEvents = require(ReplicatedStorage:WaitForChild("Remotes"):WaitForChild("NetworkEvents"))
local UIManager = require(ReplicatedStorage:WaitForChild("SharedModules"):WaitForChild("UIManager"))

-- สร้าง ScreenGui
local screenGui = Instance.new("ScreenGui")
screenGui.Name = "BreakthroughTrialGui"
screenGui.ResetOnSpawn = false
screenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
screenGui.Parent = playerGui

--------------------------------------------------------------------------------
-- 1. กรอบพื้นหลัง Modal หลัก (Centred Modal Window)
--------------------------------------------------------------------------------
local modalFrame = Instance.new("Frame")
modalFrame.Name = "TrialModalFrame"
modalFrame.Size = UDim2.new(0, 560, 0, 480)
modalFrame.Position = UDim2.new(0.5, -280, 0.5, -240)
modalFrame.BackgroundColor3 = Color3.fromRGB(18, 20, 26)
modalFrame.BorderSizePixel = 0
modalFrame.Visible = false
modalFrame.Parent = screenGui

local modalCorner = Instance.new("UICorner")
modalCorner.CornerRadius = UDim.new(0, 16)
modalCorner.Parent = modalFrame

local modalStroke = Instance.new("UIStroke")
modalStroke.Thickness = 2.5
modalStroke.Color = Color3.fromRGB(255, 215, 90)
modalStroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
modalStroke.Parent = modalFrame

-- แถบหัวเรื่อง (Header)
local header = Instance.new("Frame")
header.Size = UDim2.new(1, 0, 0, 50)
header.BackgroundColor3 = Color3.fromRGB(28, 32, 42)
header.BorderSizePixel = 0
header.Parent = modalFrame

local headerCorner = Instance.new("UICorner")
headerCorner.CornerRadius = UDim.new(0, 16)
headerCorner.Parent = header

local titleLabel = Instance.new("TextLabel")
titleLabel.Name = "TitleLabel"
titleLabel.Size = UDim2.new(1, -60, 1, 0)
titleLabel.Position = UDim2.new(0, 20, 0, 0)
titleLabel.BackgroundTransparency = 1
titleLabel.Text = "⚡ พิธีทะลวงมหาขอบเขต (Breakthrough Ritual)"
titleLabel.TextColor3 = Color3.fromRGB(255, 235, 130)
titleLabel.Font = Enum.Font.GothamBold
titleLabel.TextSize = 18
titleLabel.TextXAlignment = Enum.TextXAlignment.Left
titleLabel.Parent = header

local closeBtn = Instance.new("TextButton")
closeBtn.Name = "CloseBtn"
closeBtn.Size = UDim2.new(0, 36, 0, 36)
closeBtn.Position = UDim2.new(1, -44, 0, 7)
closeBtn.BackgroundColor3 = Color3.fromRGB(45, 50, 65)
closeBtn.Text = "✕"
closeBtn.TextColor3 = Color3.fromRGB(220, 220, 220)
closeBtn.Font = Enum.Font.GothamBold
closeBtn.TextSize = 16
closeBtn.Parent = header

local closeBtnCorner = Instance.new("UICorner")
closeBtnCorner.CornerRadius = UDim.new(0, 8)
closeBtnCorner.Parent = closeBtn

-- พื้นที่แสดงเนื้อหาด้านใน (Content Container)
local contentContainer = Instance.new("Frame")
contentContainer.Name = "ContentContainer"
contentContainer.Size = UDim2.new(1, -30, 1, -70)
contentContainer.Position = UDim2.new(0, 15, 0, 58)
contentContainer.BackgroundTransparency = 1
contentContainer.Parent = modalFrame

--------------------------------------------------------------------------------
-- 2. หน้าย่อยที่ 1: สรุปพิธีและตรวจสอบวัตถุดิบ (Preparation Summary Screen)
--------------------------------------------------------------------------------
local summaryView = Instance.new("Frame")
summaryView.Name = "SummaryView"
summaryView.Size = UDim2.new(1, 0, 1, 0)
summaryView.BackgroundTransparency = 1
summaryView.Visible = true
summaryView.Parent = contentContainer

local loreText = Instance.new("TextLabel")
loreText.Name = "LoreText"
loreText.Size = UDim2.new(1, 0, 0, 75)
loreText.BackgroundTransparency = 1
loreText.Text = "กำลังโหลดข้อมูลบททดสอบ..."
loreText.TextColor3 = Color3.fromRGB(210, 215, 230)
loreText.Font = Enum.Font.Gotham
loreText.TextSize = 14
loreText.TextWrapped = true
loreText.TextXAlignment = Enum.TextXAlignment.Left
loreText.TextYAlignment = Enum.TextYAlignment.Top
loreText.Parent = summaryView

local checklistHeader = Instance.new("TextLabel")
checklistHeader.Size = UDim2.new(1, 0, 0, 25)
checklistHeader.Position = UDim2.new(0, 0, 0, 80)
checklistHeader.BackgroundTransparency = 1
checklistHeader.Text = "📜 วัตถุดิบและโอสถที่จำเป็น (Required Items):"
checklistHeader.TextColor3 = Color3.fromRGB(255, 215, 80)
checklistHeader.Font = Enum.Font.GothamBold
checklistHeader.TextSize = 15
checklistHeader.TextXAlignment = Enum.TextXAlignment.Left
checklistHeader.Parent = summaryView

local checklistScroll = Instance.new("ScrollingFrame")
checklistScroll.Name = "ChecklistScroll"
checklistScroll.Size = UDim2.new(1, 0, 0, 140)
checklistScroll.Position = UDim2.new(0, 0, 0, 110)
checklistScroll.BackgroundColor3 = Color3.fromRGB(25, 28, 38)
checklistScroll.BorderSizePixel = 0
checklistScroll.ScrollBarThickness = 4
checklistScroll.Parent = summaryView

local checklistCorner = Instance.new("UICorner")
checklistCorner.CornerRadius = UDim.new(0, 8)
checklistCorner.Parent = checklistScroll

local checklistLayout = Instance.new("UIListLayout")
checklistLayout.Padding = UDim.new(0, 6)
checklistLayout.Parent = checklistScroll

local warningNotice = Instance.new("TextLabel")
warningNotice.Name = "WarningNotice"
warningNotice.Size = UDim2.new(1, 0, 0, 45)
warningNotice.Position = UDim2.new(0, 0, 0, 260)
warningNotice.BackgroundTransparency = 1
warningNotice.Text = "⚠️ วัตถุดิบที่ใช้ทำพิธีจะถูกหลอมรวมเมื่อเริ่มบททดสอบ หากล้มเหลวสามารถลองใหม่ได้ทันทีโดยไม่เสียระดับตบะหลัก"
warningNotice.TextColor3 = Color3.fromRGB(255, 170, 70)
warningNotice.Font = Enum.Font.Gotham
warningNotice.TextSize = 12
warningNotice.TextWrapped = true
warningNotice.Parent = summaryView

local startRitualBtn = Instance.new("TextButton")
startRitualBtn.Name = "StartRitualBtn"
startRitualBtn.Size = UDim2.new(1, 0, 0, 48)
startRitualBtn.Position = UDim2.new(0, 0, 1, -52)
startRitualBtn.BackgroundColor3 = Color3.fromRGB(45, 160, 95)
startRitualBtn.Text = "🔥 เริ่มต้นพิธีทะลวงขั้น (Start Breakthrough Ritual)"
startRitualBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
startRitualBtn.Font = Enum.Font.GothamBold
startRitualBtn.TextSize = 16
startRitualBtn.Parent = summaryView

local startRitualCorner = Instance.new("UICorner")
startRitualCorner.CornerRadius = UDim.new(0, 10)
startRitualCorner.Parent = startRitualBtn

--------------------------------------------------------------------------------
-- 3. หน้าย่อยที่ 2: มินิเกม Trial 1 Breathing Rhythm (จังหวะลมหายใจ 3 ช่วง)
--------------------------------------------------------------------------------
local breathingView = Instance.new("Frame")
breathingView.Name = "BreathingView"
breathingView.Size = UDim2.new(1, 0, 1, 0)
breathingView.BackgroundTransparency = 1
breathingView.Visible = false
breathingView.Parent = contentContainer

local breathPhaseLabel = Instance.new("TextLabel")
breathPhaseLabel.Name = "BreathPhaseLabel"
breathPhaseLabel.Size = UDim2.new(1, 0, 0, 28)
breathPhaseLabel.BackgroundTransparency = 1
breathPhaseLabel.Text = "ช่วงที่ 1/3: รวบรวมลมปราณฟ้าดิน"
breathPhaseLabel.TextColor3 = Color3.fromRGB(120, 240, 180)
breathPhaseLabel.Font = Enum.Font.GothamBold
breathPhaseLabel.TextSize = 16
breathPhaseLabel.Parent = breathingView

local breathHintLabel = Instance.new("TextLabel")
breathHintLabel.Name = "BreathHintLabel"
breathHintLabel.Size = UDim2.new(1, 0, 0, 24)
breathHintLabel.Position = UDim2.new(0, 0, 0, 30)
breathHintLabel.BackgroundTransparency = 1
breathHintLabel.Text = "กดปุ่มควบคุมลมหายใจเมื่อวงแหวนปราณหดเข้าสู่ศูนย์กลาง"
breathHintLabel.TextColor3 = Color3.fromRGB(200, 205, 220)
breathHintLabel.Font = Enum.Font.Gotham
breathHintLabel.TextSize = 13
breathHintLabel.Parent = breathingView

-- วงแหวนปราณชีพจร (Pulsing Qi Circle)
local circleContainer = Instance.new("Frame")
circleContainer.Name = "CircleContainer"
circleContainer.Size = UDim2.new(0, 180, 0, 180)
circleContainer.Position = UDim2.new(0.5, -90, 0, 70)
circleContainer.BackgroundTransparency = 1
circleContainer.Parent = breathingView

local outerCircle = Instance.new("Frame")
outerCircle.Name = "OuterCircle"
outerCircle.Size = UDim2.new(1, 0, 1, 0)
outerCircle.Position = UDim2.new(0, 0, 0, 0)
outerCircle.BackgroundColor3 = Color3.fromRGB(40, 70, 90)
outerCircle.BackgroundTransparency = 0.5
outerCircle.Parent = circleContainer

local outerCorner = Instance.new("UICorner")
outerCorner.CornerRadius = UDim.new(1, 0)
outerCorner.Parent = outerCircle

local innerCore = Instance.new("Frame")
innerCore.Name = "InnerCore"
innerCore.Size = UDim2.new(0.5, 0, 0.5, 0)
innerCore.Position = UDim2.new(0.25, 0, 0.25, 0)
innerCore.BackgroundColor3 = Color3.fromRGB(80, 255, 160)
innerCore.Parent = circleContainer

local innerCorner = Instance.new("UICorner")
innerCorner.CornerRadius = UDim.new(1, 0)
innerCorner.Parent = innerCore

local pulseRing = Instance.new("Frame")
pulseRing.Name = "PulseRing"
pulseRing.Size = UDim2.new(1.2, 0, 1.2, 0)
pulseRing.Position = UDim2.new(-0.1, 0, -0.1, 0)
pulseRing.BackgroundTransparency = 1
pulseRing.Parent = circleContainer

local pulseStroke = Instance.new("UIStroke")
pulseStroke.Thickness = 3
pulseStroke.Color = Color3.fromRGB(255, 240, 120)
pulseStroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
pulseStroke.Parent = pulseRing

local pulseCorner = Instance.new("UICorner")
pulseCorner.CornerRadius = UDim.new(1, 0)
pulseCorner.Parent = pulseRing

local breathStatusText = Instance.new("TextLabel")
breathStatusText.Name = "BreathStatusText"
breathStatusText.Size = UDim2.new(1, 0, 0, 30)
breathStatusText.Position = UDim2.new(0, 0, 0, 260)
breathStatusText.BackgroundTransparency = 1
breathStatusText.Text = "ชีพจรเต้นประสาน (0/3)"
breathStatusText.TextColor3 = Color3.fromRGB(255, 230, 130)
breathStatusText.Font = Enum.Font.GothamBold
breathStatusText.TextSize = 15
breathStatusText.Parent = breathingView

-- ปุ่มกดหายใจขนาดใหญ่สำหรับ Mobile Touch & Desktop Click
local breatheActionBtn = Instance.new("TextButton")
breatheActionBtn.Name = "BreatheActionBtn"
breatheActionBtn.Size = UDim2.new(1, 0, 0, 60)
breatheActionBtn.Position = UDim2.new(0, 0, 1, -65)
breatheActionBtn.BackgroundColor3 = Color3.fromRGB(30, 130, 210)
breatheActionBtn.Text = "🫁 ควบคุมลมหายใจ (แตะหน้าจอ หรือกด Spacebar)"
breatheActionBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
breatheActionBtn.Font = Enum.Font.GothamBold
breatheActionBtn.TextSize = 17
breatheActionBtn.Parent = breathingView

local breatheCorner = Instance.new("UICorner")
breatheCorner.CornerRadius = UDim.new(0, 12)
breatheCorner.Parent = breatheActionBtn

--------------------------------------------------------------------------------
-- 4. หน้าย่อยที่ 3: มินิเกม Trial 2 Five Elements (วัฏจักรเบญจธาตุ)
--------------------------------------------------------------------------------
local elementsView = Instance.new("Frame")
elementsView.Name = "ElementsView"
elementsView.Size = UDim2.new(1, 0, 1, 0)
elementsView.BackgroundTransparency = 1
elementsView.Visible = false
elementsView.Parent = contentContainer

local elemTitle = Instance.new("TextLabel")
elemTitle.Size = UDim2.new(1, 0, 0, 25)
elemTitle.BackgroundTransparency = 1
elemTitle.Text = "วัฏจักรก่อเกิด: ดิน → ทอง → น้ำ → ไม้ → ไฟ"
elemTitle.TextColor3 = Color3.fromRGB(255, 215, 90)
elemTitle.Font = Enum.Font.GothamBold
elemTitle.TextSize = 15
elemTitle.Parent = elementsView

local elemHint = Instance.new("TextLabel")
elemHint.Name = "ElemHint"
elemHint.Size = UDim2.new(1, 0, 0, 25)
elemHint.Position = UDim2.new(0, 0, 0, 28)
elemHint.BackgroundTransparency = 1
elemHint.Text = "แตะเลือกแก่นธาตุเพื่อถ่ายทอดประสานเข้าสู่กายา"
elemHint.TextColor3 = Color3.fromRGB(210, 215, 230)
elemHint.Font = Enum.Font.Gotham
elemHint.TextSize = 13
elemHint.Parent = elementsView

local elemButtonsContainer = Instance.new("Frame")
elemButtonsContainer.Name = "ElemButtonsContainer"
elemButtonsContainer.Size = UDim2.new(1, 0, 0, 240)
elemButtonsContainer.Position = UDim2.new(0, 0, 0, 65)
elemButtonsContainer.BackgroundTransparency = 1
elemButtonsContainer.Parent = elementsView

local elemStatusLabel = Instance.new("TextLabel")
elemStatusLabel.Name = "ElemStatusLabel"
elemStatusLabel.Size = UDim2.new(1, 0, 0, 40)
elemStatusLabel.Position = UDim2.new(0, 0, 1, -50)
elemStatusLabel.BackgroundTransparency = 1
elemStatusLabel.Text = "กำลังรอการถ่ายทอดธาตุปฐมภูมิ..."
elemStatusLabel.TextColor3 = Color3.fromRGB(120, 230, 180)
elemStatusLabel.Font = Enum.Font.GothamBold
elemStatusLabel.TextSize = 15
elemStatusLabel.Parent = elementsView

--------------------------------------------------------------------------------
-- 5. หน้าย่อยที่ 4: หน้าฉลองความสำเร็จ (Victory Screen)
--------------------------------------------------------------------------------
local victoryView = Instance.new("Frame")
victoryView.Name = "VictoryView"
victoryView.Size = UDim2.new(1, 0, 1, 0)
victoryView.BackgroundTransparency = 1
victoryView.Visible = false
victoryView.Parent = contentContainer

local vicIcon = Instance.new("TextLabel")
vicIcon.Size = UDim2.new(1, 0, 0, 80)
vicIcon.Position = UDim2.new(0, 0, 0, 10)
vicIcon.BackgroundTransparency = 1
vicIcon.Text = "✨ 🌟 ✨"
vicIcon.Font = Enum.Font.GothamBold
vicIcon.TextSize = 40
vicIcon.Parent = victoryView

local vicTitle = Instance.new("TextLabel")
vicTitle.Name = "VicTitle"
vicTitle.Size = UDim2.new(1, 0, 0, 35)
vicTitle.Position = UDim2.new(0, 0, 0, 95)
vicTitle.BackgroundTransparency = 1
vicTitle.Text = "ทะลวงขอบเขตสำเร็จ!"
vicTitle.TextColor3 = Color3.fromRGB(255, 230, 90)
vicTitle.Font = Enum.Font.GothamBold
vicTitle.TextSize = 22
vicTitle.Parent = victoryView

local vicDesc = Instance.new("TextLabel")
vicDesc.Name = "VicDesc"
vicDesc.Size = UDim2.new(1, -20, 0, 120)
vicDesc.Position = UDim2.new(0, 10, 0, 140)
vicDesc.BackgroundTransparency = 1
vicDesc.Text = "ยินดีด้วย ท่านได้ก้าวข้ามขีดจำกัดเดิมและเปิดรับพลังใหม่"
vicDesc.TextColor3 = Color3.fromRGB(220, 230, 245)
vicDesc.Font = Enum.Font.Gotham
vicDesc.TextSize = 14
vicDesc.TextWrapped = true
vicDesc.Parent = victoryView

local vicConfirmBtn = Instance.new("TextButton")
vicConfirmBtn.Name = "VicConfirmBtn"
vicConfirmBtn.Size = UDim2.new(1, 0, 0, 48)
vicConfirmBtn.Position = UDim2.new(0, 0, 1, -52)
vicConfirmBtn.BackgroundColor3 = Color3.fromRGB(45, 160, 95)
vicConfirmBtn.Text = "รับรู้และมุ่งสู่วิถีถัดไป"
vicConfirmBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
vicConfirmBtn.Font = Enum.Font.GothamBold
vicConfirmBtn.TextSize = 16
vicConfirmBtn.Parent = victoryView

local vicBtnCorner = Instance.new("UICorner")
vicBtnCorner.CornerRadius = UDim.new(0, 10)
vicBtnCorner.Parent = vicConfirmBtn

--------------------------------------------------------------------------------
-- 6. ระบบสลับมุมมองและลอจิกการทำงาน (Controller Logic)
--------------------------------------------------------------------------------
local currentTrialData = nil
local activePulseTween = nil

local function showView(viewName)
    summaryView.Visible = (viewName == "Summary")
    breathingView.Visible = (viewName == "Breathing")
    elementsView.Visible = (viewName == "Elements")
    victoryView.Visible = (viewName == "Victory")
end

-- อัปเดตรายการ Checklist ในหน้าสรุป
local function updateChecklist(items)
    for _, child in ipairs(checklistScroll:GetChildren()) do
        if child:IsA("Frame") then child:Destroy() end
    end

    if not items or #items == 0 then
        local emptyLabel = Instance.new("TextLabel")
        emptyLabel.Size = UDim2.new(1, 0, 1, 0)
        emptyLabel.BackgroundTransparency = 1
        emptyLabel.Text = "ไม่มีวัตถุดิบที่ต้องใช้เป็นพิเศษ"
        emptyLabel.TextColor3 = Color3.fromRGB(150, 160, 180)
        emptyLabel.Font = Enum.Font.Gotham
        emptyLabel.TextSize = 13
        emptyLabel.Parent = checklistScroll
        return
    end

    for _, itm in ipairs(items) do
        local row = Instance.new("Frame")
        row.Size = UDim2.new(1, -10, 0, 32)
        row.BackgroundColor3 = Color3.fromRGB(35, 40, 52)
        row.BorderSizePixel = 0
        row.Parent = checklistScroll

        local rowCorner = Instance.new("UICorner")
        rowCorner.CornerRadius = UDim.new(0, 6)
        rowCorner.Parent = row

        local icon = Instance.new("TextLabel")
        icon.Size = UDim2.new(0, 30, 1, 0)
        icon.BackgroundTransparency = 1
        icon.Text = itm.IsMet and "✅" or "❌"
        icon.TextSize = 14
        icon.Parent = row

        local nameLabel = Instance.new("TextLabel")
        nameLabel.Size = UDim2.new(0.65, 0, 1, 0)
        nameLabel.Position = UDim2.new(0, 32, 0, 0)
        nameLabel.BackgroundTransparency = 1
        nameLabel.Text = itm.Name
        nameLabel.TextColor3 = itm.IsMet and Color3.fromRGB(120, 240, 160) or Color3.fromRGB(255, 120, 120)
        nameLabel.Font = Enum.Font.GothamBold
        nameLabel.TextSize = 13
        nameLabel.TextXAlignment = Enum.TextXAlignment.Left
        nameLabel.Parent = row

        local countLabel = Instance.new("TextLabel")
        countLabel.Size = UDim2.new(0.3, -10, 1, 0)
        countLabel.Position = UDim2.new(0.7, 0, 0, 0)
        countLabel.BackgroundTransparency = 1
        countLabel.Text = string.format("%d / %d", itm.Current, itm.Required)
        countLabel.TextColor3 = itm.IsMet and Color3.fromRGB(120, 240, 160) or Color3.fromRGB(255, 120, 120)
        countLabel.Font = Enum.Font.Gotham
        countLabel.TextSize = 13
        countLabel.TextXAlignment = Enum.TextXAlignment.Right
        countLabel.Parent = row
    end
end

-- สร้างปุ่ม 5 ธาตุในหน้า Elements View
local function setupElementsButtons(trialDef)
    for _, child in ipairs(elemButtonsContainer:GetChildren()) do
        if child:IsA("GuiObject") then child:Destroy() end
    end

    local sequence = trialDef.ElementSequence or { "Earth", "Metal", "Water", "Wood", "Fire" }
    local elementData = trialDef.ElementData or {}

    local btnWidth = 95
    local btnHeight = 70
    local spacing = 12

    for index, elemKey in ipairs(sequence) do
        local data = elementData[elemKey] or { Name = elemKey, Color = Color3.fromRGB(200, 200, 200) }
        local btn = Instance.new("TextButton")
        btn.Name = "ElemBtn_" .. elemKey
        btn.Size = UDim2.new(0, btnWidth, 0, btnHeight)
        local posX = ((index - 1) % 5) * (btnWidth + spacing) + 8
        btn.Position = UDim2.new(0, posX, 0, 30)
        btn.BackgroundColor3 = Color3.fromRGB(32, 36, 48)
        btn.Text = ""
        btn.Parent = elemButtonsContainer

        local corner = Instance.new("UICorner")
        corner.CornerRadius = UDim.new(0, 10)
        corner.Parent = btn

        local stroke = Instance.new("UIStroke")
        stroke.Thickness = 2
        stroke.Color = data.Color
        stroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
        stroke.Parent = btn

        local iconLabel = Instance.new("TextLabel")
        iconLabel.Size = UDim2.new(1, 0, 0, 30)
        iconLabel.Position = UDim2.new(0, 0, 0, 6)
        iconLabel.BackgroundTransparency = 1
        iconLabel.Text = data.ElementName or elemKey
        iconLabel.TextColor3 = data.Color
        iconLabel.Font = Enum.Font.GothamBold
        iconLabel.TextSize = 18
        iconLabel.Parent = btn

        local subLabel = Instance.new("TextLabel")
        subLabel.Size = UDim2.new(1, 0, 0, 24)
        subLabel.Position = UDim2.new(0, 0, 0, 36)
        subLabel.BackgroundTransparency = 1
        subLabel.Text = data.Name or elemKey
        subLabel.TextColor3 = Color3.fromRGB(220, 225, 235)
        subLabel.Font = Enum.Font.Gotham
        subLabel.TextSize = 11
        subLabel.Parent = btn

        -- รองรับ Touch & Click
        btn.Activated:Connect(function()
            local ok, msg, isFinished, nextRealm = NetworkEvents.SubmitTrialAction:InvokeServer({
                Action = "InfuseElement",
                Element = elemKey
            })
            if ok then
                elemStatusLabel.Text = "✅ " .. msg
                elemStatusLabel.TextColor3 = Color3.fromRGB(120, 240, 180)
                if isFinished then
                    showVictoryScreen(nextRealm)
                end
            else
                elemStatusLabel.Text = "❌ " .. msg
                elemStatusLabel.TextColor3 = Color3.fromRGB(255, 120, 120)
            end
        end)
    end
end

-- เริ่มแอนิเมชันจังหวะหายใจใน Trial 1
local function startBreathingPulse(targetInterval)
    if activePulseTween then activePulseTween:Cancel() end
    targetInterval = targetInterval or 2.0

    pulseRing.Size = UDim2.new(1.4, 0, 1.4, 0)
    pulseRing.Position = UDim2.new(-0.2, 0, -0.2, 0)
    pulseStroke.Transparency = 0.2

    local tweenInfo = TweenInfo.new(targetInterval, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut, -1, true)
    activePulseTween = TweenService:Create(pulseRing, tweenInfo, {
        Size = UDim2.new(0.6, 0, 0.6, 0),
        Position = UDim2.new(0.2, 0, 0.2, 0),
    })
    activePulseTween:Play()
end

-- แสดงหน้า Victory
function showVictoryScreen(nextRealm)
    if activePulseTween then activePulseTween:Cancel() end
    vicTitle.Text = "🎉 บรรลุขอบเขต: " .. (nextRealm and nextRealm.Name or "ขอบเขตใหม่")
    vicDesc.Text = (nextRealm and nextRealm.Trial and nextRealm.Trial.Reward and nextRealm.Trial.Reward.Description)
        or "ท่านได้สถาปนารากฐานเซียนขั้นสูง สเตตัสและขีดจำกัดพลังได้รับการยกระดับสมบูรณ์"
    showView("Victory")
end

-- เปิด Modal ทะลวงขั้น
local BreakthroughTrialUI = {}

function BreakthroughTrialUI:OpenModal()
    local info = NetworkEvents.RequestBreakthroughInfo:InvokeServer()
    if not info or not info.Success then
        warn("⚠️ ไม่สามารถดึงข้อมูลการทะลวงขั้นได้: " .. tostring(info and info.Message or "Unknown"))
        return
    end

    currentTrialData = info
    titleLabel.Text = "⚡ " .. (info.Trial and info.Trial.Name or "พิธีทะลวงมหาขอบเขต")
    loreText.Text = info.Trial and info.Trial.Lore or "สะสมตบะจนถึงจุดสูงสุดแล้วทำพิธีก้าวข้ามสู่ขอบเขตถัดไป"

    updateChecklist(info.ItemChecklist)

    if info.CanStart then
        startRitualBtn.BackgroundColor3 = Color3.fromRGB(45, 160, 95)
        startRitualBtn.Text = "🔥 เริ่มต้นพิธีทะลวงขั้น (Start Breakthrough Ritual)"
        startRitualBtn.Active = true
    else
        startRitualBtn.BackgroundColor3 = Color3.fromRGB(80, 85, 95)
        startRitualBtn.Text = "🔒 เงื่อนไขยังไม่ครบถ้วน (ตรวจสอบตบะและวัตถุดิบ)"
        startRitualBtn.Active = false
    end

    showView("Summary")
    UIManager:Open("BreakthroughModal")
end

function BreakthroughTrialUI:CloseModal()
    if activePulseTween then activePulseTween:Cancel() end
    UIManager:Close("BreakthroughModal")
end

-- ผูกการกดปุ่ม
startRitualBtn.Activated:Connect(function()
    if not startRitualBtn.Active then return end

    local ok, msg, session = NetworkEvents.StartBreakthroughTrial:InvokeServer()
    if ok then
        local trialDef = currentTrialData.Trial
        if trialDef.Type == CultivationTypes.TrialType.BreathingRhythm then
            showView("Breathing")
            breathPhaseLabel.Text = trialDef.Phases[1].Name
            breathStatusText.Text = "ชีพจรเต้นประสาน (0/" .. trialDef.Phases[1].BeatsRequired .. ")"
            startBreathingPulse(trialDef.Phases[1].TargetInterval)
        elseif trialDef.Type == CultivationTypes.TrialType.FiveElementsGeneration then
            showView("Elements")
            setupElementsButtons(trialDef)
            elemStatusLabel.Text = "จงเลือก: แก่นปฐพี (ดิน) เพื่อเริ่มวัฏจักรก่อเกิด"
        else
            showVictoryScreen(currentTrialData.NextRealm)
        end
    else
        warn("❌ ไม่สามารถเริ่มพิธีได้: " .. tostring(msg))
    end
end)

-- ปุ่มหายใจ Trial 1
local function triggerBreathe()
    local ok, msg, isFinished, nextRealm = NetworkEvents.SubmitTrialAction:InvokeServer({
        Action = "Breathe",
        ClientTime = os.clock()
    })
    if ok then
        breathStatusText.Text = "✅ " .. msg
        breathStatusText.TextColor3 = Color3.fromRGB(120, 240, 180)
        if isFinished then
            showVictoryScreen(nextRealm)
        end
    else
        breathStatusText.Text = "❌ " .. msg
        breathStatusText.TextColor3 = Color3.fromRGB(255, 120, 120)
    end
end

breatheActionBtn.Activated:Connect(triggerBreathe)

-- ปุ่ม Spacebar สำหรับ PC
UserInputService.InputBegan:Connect(function(input, gpe)
    if gpe then return end
    if input.KeyCode == Enum.KeyCode.Space and breathingView.Visible and modalFrame.Visible then
        triggerBreathe()
    end
end)

-- ปุ่มปิด
closeBtn.Activated:Connect(function()
    NetworkEvents.CancelBreakthroughTrial:InvokeServer()
    BreakthroughTrialUI:CloseModal()
end)

vicConfirmBtn.Activated:Connect(function()
    BreakthroughTrialUI:CloseModal()
end)

-- รับ Event อัปเดตจาก Server
NetworkEvents.TrialStateUpdate.OnClientEvent:Connect(function(data)
    if data.State == "PhaseAdvance" then
        breathPhaseLabel.Text = data.NextPhaseName
        breathStatusText.Text = "ก้าวสู่ช่วงถัดไป! ชีพจรเต้นประสาน (0/4)"
        local nextPhaseDef = currentTrialData.Trial.Phases[data.Phase]
        if nextPhaseDef then
            startBreathingPulse(nextPhaseDef.TargetInterval)
        end
    elseif data.State == "BeatHit" then
        breathStatusText.Text = string.format("✅ ชีพจรประสาน (%d/%d)", data.BeatsInPhase, data.BeatsRequired)
    elseif data.State == "BeatMiss" then
        breathStatusText.Text = "❌ จังหวะคลาดเคลื่อน ปรับลมหายใจแล้วลองใหม่"
    end
end)

-- ลงทะเบียนเข้ากับ UIManager
UIManager:Register("BreakthroughModal", modalFrame, function()
    modalFrame.Visible = true
end, function()
    modalFrame.Visible = false
    if activePulseTween then activePulseTween:Cancel() end
end)

_G.BreakthroughTrialUI = BreakthroughTrialUI
return BreakthroughTrialUI
