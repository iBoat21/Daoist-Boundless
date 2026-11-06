--[[
    InventoryUI.client.lua
    ระบบกระเป๋าสัมภาระแบบช่องสี่เหลี่ยม (Grid-Slot Inventory System)
    - ช่องเก็บไอเทมแบบ Grid 5x5 พร้อม Mock Model สีสันตามธาตุและความหายาก
    - หมวดหมู่แท็บ: ทั้งหมด, สมุนไพร, โอสถ, ศาสตราวุธ
    - หน้าต่างตรวจสอบไอเทม (Item Inspector): แสดงชื่อ, รายละเอียด, ธาตุ และปุ่มใช้งาน (กลืนโอสถ/ติดตั้งอาวุธ)
    - ผสานระบบ UIManager เพื่อไม่ให้เปิดหน้าต่างซ้อนทับกัน
]]

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local UserInputService = game:GetService("UserInputService")
local TweenService = game:GetService("TweenService")

local localPlayer = Players.LocalPlayer
local playerGui = localPlayer:WaitForChild("PlayerGui")

local GameConfig = require(ReplicatedStorage:WaitForChild("SharedModules"):WaitForChild("GameConfig"))
local HerbDatabase = require(ReplicatedStorage:WaitForChild("SharedModules"):WaitForChild("HerbDatabase"))
local PillDatabase = require(ReplicatedStorage:WaitForChild("SharedModules"):WaitForChild("PillDatabase"))
local NetworkEvents = require(ReplicatedStorage:WaitForChild("Remotes"):WaitForChild("NetworkEvents"))
local UIManager = require(ReplicatedStorage:WaitForChild("SharedModules"):WaitForChild("UIManager"))

local currentInventory = {}
local activeCategory = "All" -- "All" | "Herb" | "Pill" | "Weapon"
local selectedItemName = nil

-- สร้าง ScreenGui
local screenGui = Instance.new("ScreenGui")
screenGui.Name = "InventoryGui"
screenGui.ResetOnSpawn = false
screenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
screenGui.Parent = playerGui

-- หน้าต่างหลัก (Main Window)
local mainFrame = Instance.new("Frame")
mainFrame.Name = "InventoryFrame"
mainFrame.Size = UDim2.new(0, 720, 0, 480)
mainFrame.Position = UDim2.new(0.5, -360, 0.5, -240)
mainFrame.BackgroundColor3 = Color3.fromRGB(16, 18, 24)
mainFrame.BorderSizePixel = 0
mainFrame.Visible = false
mainFrame.ClipsDescendants = true
mainFrame.Parent = screenGui

local frameCorner = Instance.new("UICorner")
frameCorner.CornerRadius = UDim.new(0, 12)
frameCorner.Parent = mainFrame

local frameStroke = Instance.new("UIStroke")
frameStroke.Thickness = 2
frameStroke.Color = Color3.fromRGB(60, 180, 120)
frameStroke.Parent = mainFrame

-- Title Bar
local titleBar = Instance.new("Frame")
titleBar.Size = UDim2.new(1, 0, 0, 42)
titleBar.BackgroundColor3 = Color3.fromRGB(22, 26, 34)
titleBar.BorderSizePixel = 0
titleBar.Parent = mainFrame

local titleLabel = Instance.new("TextLabel")
titleLabel.Size = UDim2.new(0.7, 0, 1, 0)
titleLabel.Position = UDim2.new(0, 16, 0, 0)
titleLabel.BackgroundTransparency = 1
titleLabel.Text = "🎒 ย่ามสัมภาระมิติ (Dimensional Inventory)"
titleLabel.TextColor3 = Color3.fromRGB(255, 215, 80)
titleLabel.Font = Enum.Font.SourceSansBold
titleLabel.TextSize = 17
titleLabel.TextXAlignment = Enum.TextXAlignment.Left
titleLabel.Parent = titleBar

local closeBtn = Instance.new("TextButton")
closeBtn.Size = UDim2.new(0, 30, 0, 28)
closeBtn.Position = UDim2.new(1, -38, 0, 7)
closeBtn.BackgroundColor3 = Color3.fromRGB(180, 50, 50)
closeBtn.Text = "✕"
closeBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
closeBtn.Font = Enum.Font.SourceSansBold
closeBtn.TextSize = 15
closeBtn.Parent = titleBar

local cbCorner = Instance.new("UICorner")
cbCorner.CornerRadius = UDim.new(0, 6)
cbCorner.Parent = closeBtn

-- Category Bar
local catBar = Instance.new("Frame")
catBar.Size = UDim2.new(1, -30, 0, 32)
catBar.Position = UDim2.new(0, 15, 0, 48)
catBar.BackgroundTransparency = 1
catBar.Parent = mainFrame

local catLayout = Instance.new("UIListLayout")
catLayout.FillDirection = Enum.FillDirection.Horizontal
catLayout.Padding = UDim.new(0, 8)
catLayout.Parent = catBar

local catButtons = {}
local function createCatButton(catId, title)
    local btn = Instance.new("TextButton")
    btn.Size = UDim2.new(0, 110, 1, 0)
    btn.BackgroundColor3 = (catId == "All") and Color3.fromRGB(50, 140, 90) or Color3.fromRGB(28, 32, 42)
    btn.Text = title
    btn.TextColor3 = Color3.fromRGB(255, 255, 255)
    btn.Font = Enum.Font.SourceSansBold
    btn.TextSize = 13
    btn.Parent = catBar

    local c = Instance.new("UICorner")
    c.CornerRadius = UDim.new(0, 6)
    c.Parent = btn

    catButtons[catId] = btn

    btn.MouseButton1Click:Connect(function()
        activeCategory = catId
        for id, b in pairs(catButtons) do
            b.BackgroundColor3 = (id == catId) and Color3.fromRGB(50, 140, 90) or Color3.fromRGB(28, 32, 42)
        end
        updateGridUI()
    end)
end

createCatButton("All", "ทั้งหมด (All)")
createCatButton("Herb", "🌿 สมุนไพร")
createCatButton("Pill", "💊 เม็ดยาโอสถ")
createCatButton("Weapon", "⚔️ ศาสตราวุธ")

-- Left: Grid Slots Frame (ช่องเก็บของ)
local gridScroll = Instance.new("ScrollingFrame")
gridScroll.Name = "GridScroll"
gridScroll.Size = UDim2.new(0, 430, 1, -94)
gridScroll.Position = UDim2.new(0, 15, 0, 86)
gridScroll.BackgroundColor3 = Color3.fromRGB(12, 14, 18)
gridScroll.BorderSizePixel = 0
gridScroll.ScrollBarThickness = 5
gridScroll.CanvasSize = UDim2.new(0, 0, 0, 0)
gridScroll.Parent = mainFrame

local gsCorner = Instance.new("UICorner")
gsCorner.CornerRadius = UDim.new(0, 8)
gsCorner.Parent = gridScroll

local gridLayout = Instance.new("UIGridLayout")
gridLayout.CellSize = UDim2.new(0, 74, 0, 74)
gridLayout.CellPadding = UDim2.new(0, 8, 0, 8)
gridLayout.SortOrder = Enum.SortOrder.LayoutOrder
gridLayout.Parent = gridScroll

local gridPadding = Instance.new("UIPadding")
gridPadding.PaddingTop = UDim.new(0, 8)
gridPadding.PaddingLeft = UDim.new(0, 8)
gridPadding.PaddingRight = UDim.new(0, 8)
gridPadding.PaddingBottom = UDim.new(0, 8)
gridPadding.Parent = gridScroll

-- Right: Item Inspector Panel (แผงตรวจสอบรายละเอียดไอเทม)
local inspectorFrame = Instance.new("Frame")
inspectorFrame.Name = "InspectorFrame"
inspectorFrame.Size = UDim2.new(0, 245, 1, -94)
inspectorFrame.Position = UDim2.new(0, 460, 0, 86)
inspectorFrame.BackgroundColor3 = Color3.fromRGB(20, 23, 32)
inspectorFrame.BorderSizePixel = 0
inspectorFrame.Parent = mainFrame

local insCorner = Instance.new("UICorner")
insCorner.CornerRadius = UDim.new(0, 8)
insCorner.Parent = inspectorFrame

local insStroke = Instance.new("UIStroke")
insStroke.Thickness = 1.2
insStroke.Color = Color3.fromRGB(50, 60, 80)
insStroke.Parent = inspectorFrame

-- Mock Model Icon Preview (โมเดลตัวอย่างสีสันตามธาตุ)
local previewBox = Instance.new("Frame")
previewBox.Size = UDim2.new(0, 84, 0, 84)
previewBox.Position = UDim2.new(0.5, -42, 0, 16)
previewBox.BackgroundColor3 = Color3.fromRGB(14, 16, 22)
previewBox.BorderSizePixel = 0
previewBox.Parent = inspectorFrame

local pbCorner = Instance.new("UICorner")
pbCorner.CornerRadius = UDim.new(0, 8)
pbCorner.Parent = previewBox

local pbStroke = Instance.new("UIStroke")
pbStroke.Thickness = 2
pbStroke.Color = Color3.fromRGB(85, 255, 127)
pbStroke.Parent = previewBox

local mockModelShape = Instance.new("Frame")
mockModelShape.Size = UDim2.new(0, 48, 0, 48)
mockModelShape.Position = UDim2.new(0.5, -24, 0.5, -24)
mockModelShape.BackgroundColor3 = Color3.fromRGB(85, 255, 127)
mockModelShape.Rotation = 45
mockModelShape.BorderSizePixel = 0
mockModelShape.Parent = previewBox

local msCorner = Instance.new("UICorner")
msCorner.CornerRadius = UDim.new(0, 6)
msCorner.Parent = mockModelShape

local insNameLabel = Instance.new("TextLabel")
insNameLabel.Size = UDim2.new(1, -20, 0, 26)
insNameLabel.Position = UDim2.new(0, 10, 0, 108)
insNameLabel.BackgroundTransparency = 1
insNameLabel.Text = "เลือกไอเทมในกระเป๋า"
insNameLabel.TextColor3 = Color3.fromRGB(255, 215, 80)
insNameLabel.Font = Enum.Font.SourceSansBold
insNameLabel.TextSize = 15
insNameLabel.TextWrapped = true
insNameLabel.Parent = inspectorFrame

local insTypeBadge = Instance.new("TextLabel")
insTypeBadge.Size = UDim2.new(1, -20, 0, 20)
insTypeBadge.Position = UDim2.new(0, 10, 0, 134)
insTypeBadge.BackgroundTransparency = 1
insTypeBadge.Text = "ประเภท: -"
insTypeBadge.TextColor3 = Color3.fromRGB(120, 200, 255)
insTypeBadge.Font = Enum.Font.SourceSans
insTypeBadge.TextSize = 12
insTypeBadge.Parent = inspectorFrame

local insDescLabel = Instance.new("TextLabel")
insDescLabel.Size = UDim2.new(1, -24, 0, 80)
insDescLabel.Position = UDim2.new(0, 12, 0, 158)
insDescLabel.BackgroundTransparency = 1
insDescLabel.Text = "คลิกที่ช่องไอเทมด้านซ้ายเพื่อดูรายละเอียด สรรพคุณ หรือกดใช้งาน"
insDescLabel.TextColor3 = Color3.fromRGB(180, 190, 205)
insDescLabel.Font = Enum.Font.SourceSans
insDescLabel.TextSize = 12
insDescLabel.TextWrapped = true
insDescLabel.TextYAlignment = Enum.TextYAlignment.Top
insDescLabel.Parent = inspectorFrame

local insActionBtn = Instance.new("TextButton")
insActionBtn.Size = UDim2.new(1, -24, 0, 38)
insActionBtn.Position = UDim2.new(0, 12, 1, -50)
insActionBtn.BackgroundColor3 = Color3.fromRGB(40, 140, 80)
insActionBtn.Text = "ใช้งาน"
insActionBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
insActionBtn.Font = Enum.Font.SourceSansBold
insActionBtn.TextSize = 14
insActionBtn.Visible = false
insActionBtn.Parent = inspectorFrame

local abCorner = Instance.new("UICorner")
abCorner.CornerRadius = UDim.new(0, 6)
abCorner.Parent = insActionBtn

--------------------------------------------------------------------------------
-- ฟังก์ชันแสดงรายละเอียดไอเทมใน Inspector
--------------------------------------------------------------------------------
local function selectItem(name, count)
    selectedItemName = name
    insActionBtn.Visible = true

    local herbData = HerbDatabase.Get(name) or (GameConfig.Herbs and GameConfig.Herbs[name])
    local pillData = PillDatabase.Get(name) or (GameConfig.Pills and GameConfig.Pills[name])
    local weaponData = GameConfig.Weapons and GameConfig.Weapons[name]

    local itemColor = Color3.fromRGB(200, 200, 200)
    local itemType = "ทั่วไป"
    local desc = ""

    if weaponData then
        itemType = "⚔️ ศาสตราวุธ (Weapon)"
        itemColor = weaponData.Color or Color3.fromRGB(255, 140, 40)
        desc = string.format("%s\n\nพลังโจมตีพื้นฐาน: +%d\nระยะโจมตี: %d เมตร",
            weaponData.Description, weaponData.BaseDamage or 10, weaponData.AttackRange or 6)
        insActionBtn.Text = "⚔️ ติดตั้งอาวุธ"
        insActionBtn.BackgroundColor3 = Color3.fromRGB(180, 80, 40)
    elseif pillData then
        itemType = "💊 เม็ดยาโอสถ (Pill)"
        itemColor = pillData.Color or Color3.fromRGB(255, 215, 80)
        desc = string.format("%s\n\nราคากลาง: %d เหรียญ\nมีในย่าม: %d เม็ด",
            pillData.Description or "", pillData.Price or 500, count)
        insActionBtn.Text = "💊 กลืนโอสถ (กิน)"
        insActionBtn.BackgroundColor3 = Color3.fromRGB(40, 140, 80)
    elseif herbData then
        itemType = string.format("🌿 สมุนไพร [ระดับ %d: %s]", herbData.Tier or 1, herbData.TierName or "ปฐพี")
        itemColor = herbData.Color or Color3.fromRGB(85, 255, 127)
        desc = string.format("ธาตุ: %s | ฤทธิ์: +%d | ความเสถียร: %+d\nถิ่นกำเนิด: %s\nมีในย่าม: %d ต้น",
            herbData.Element or "Wood", herbData.Potency or 15, herbData.Stability or 0, herbData.Habitat or "ทั่วยุทธภพ", count)
        insActionBtn.Text = "🔥 นำไปหลอมในเตา"
        insActionBtn.BackgroundColor3 = Color3.fromRGB(200, 120, 20)
    else
        desc = "มีจำนวน: " .. tostring(count) .. " ชิ้น"
        insActionBtn.Text = "ใช้งาน"
        insActionBtn.BackgroundColor3 = Color3.fromRGB(50, 100, 150)
    end

    insNameLabel.Text = name
    insNameLabel.TextColor3 = itemColor
    insTypeBadge.Text = itemType
    insDescLabel.Text = desc
    pbStroke.Color = itemColor
    mockModelShape.BackgroundColor3 = itemColor
end

insActionBtn.MouseButton1Click:Connect(function()
    if not selectedItemName then return end

    local pillData = PillDatabase.Get(selectedItemName) or (GameConfig.Pills and GameConfig.Pills[selectedItemName])
    local weaponData = GameConfig.Weapons and GameConfig.Weapons[selectedItemName]

    if weaponData then
        insActionBtn.Text = "ติดตั้งแล้ว!"
        if _G.DaoistEquipWeapon then
            _G.DaoistEquipWeapon(selectedItemName)
        end
        task.wait(1)
        insActionBtn.Text = "⚔️ ติดตั้งอาวุธ"
    elseif pillData or string.find(selectedItemName, "โอสถ") or string.find(selectedItemName, "เม็ดยา") then
        insActionBtn.Text = "กำลังกลืน..."
        local success = NetworkEvents.UsePill:InvokeServer(selectedItemName)
        if success then
            insActionBtn.Text = "สำเร็จ!"
            task.wait(0.5)
            updateGridUI()
            selectItem(selectedItemName, currentInventory[selectedItemName] or 0)
        else
            insActionBtn.Text = "ล้มเหลว"
            task.wait(1)
            insActionBtn.Text = "💊 กลืนโอสถ (กิน)"
        end
    else
        -- เป็นสมุนไพร -> เปิดเตาหลอม
        UIManager:Open("Alchemy")
    end
end)

--------------------------------------------------------------------------------
-- ฟังก์ชันเรนเดอร์ช่อง Grid Slots
--------------------------------------------------------------------------------
function updateGridUI()
    for _, child in ipairs(gridScroll:GetChildren()) do
        if child:IsA("Frame") or child:IsA("TextButton") then child:Destroy() end
    end

    local itemsList = {}
    for name, count in pairs(currentInventory) do
        if count > 0 then
            local isPill = (PillDatabase.Get(name) ~= nil) or (string.find(name, "โอสถ") ~= nil) or (string.find(name, "เม็ดยา") ~= nil)
            local isWeapon = (GameConfig.Weapons and GameConfig.Weapons[name] ~= nil)
            local isHerb = (not isPill and not isWeapon)

            local matchesCat = false
            if activeCategory == "All" then matchesCat = true
            elseif activeCategory == "Herb" and isHerb then matchesCat = true
            elseif activeCategory == "Pill" and isPill then matchesCat = true
            elseif activeCategory == "Weapon" and isWeapon then matchesCat = true end

            if matchesCat then
                table.insert(itemsList, {Name = name, Count = count, IsPill = isPill, IsWeapon = isWeapon, IsHerb = isHerb})
            end
        end
    end

    -- แสดงอย่างน้อย 25 ช่อง (5x5) เสมือนช่องกระเป๋าเกม RPG
    local totalSlots = math.max(25, #itemsList)
    for i = 1, totalSlots do
        local item = itemsList[i]

        local slot = Instance.new("TextButton")
        slot.Name = "Slot_" .. i
        slot.Size = UDim2.new(0, 74, 0, 74)
        slot.BackgroundColor3 = Color3.fromRGB(20, 24, 32)
        slot.Text = ""
        slot.AutoButtonColor = (item ~= nil)
        slot.Parent = gridScroll

        local sc = Instance.new("UICorner")
        sc.CornerRadius = UDim.new(0, 8)
        sc.Parent = slot

        local ss = Instance.new("UIStroke")
        ss.Thickness = 1
        ss.Color = Color3.fromRGB(40, 46, 60)
        ss.Parent = slot

        if item then
            local color = Color3.fromRGB(180, 180, 180)
            local tagIcon = "📦"
            if item.IsWeapon then
                local w = GameConfig.Weapons[item.Name]
                color = w and w.Color or Color3.fromRGB(255, 140, 40)
                tagIcon = "⚔️"
            elseif item.IsPill then
                local p = PillDatabase.Get(item.Name) or (GameConfig.Pills and GameConfig.Pills[item.Name])
                color = p and p.Color or Color3.fromRGB(255, 215, 80)
                tagIcon = "💊"
            else
                local h = HerbDatabase.Get(item.Name) or (GameConfig.Herbs and GameConfig.Herbs[item.Name])
                color = h and h.Color or Color3.fromRGB(85, 255, 127)
                tagIcon = "🌿"
            end

            ss.Color = color
            ss.Thickness = 1.4

            -- ไอคอน Mock Model แสดงทรงเหลี่ยมสีตามธาตุ
            local mockIcon = Instance.new("Frame")
            mockIcon.Size = UDim2.new(0, 34, 0, 34)
            mockIcon.Position = UDim2.new(0.5, -17, 0.5, -17)
            mockIcon.BackgroundColor3 = color
            mockIcon.Rotation = 45
            mockIcon.BorderSizePixel = 0
            mockIcon.Parent = slot

            local mc = Instance.new("UICorner")
            mc.CornerRadius = UDim.new(0, 5)
            mc.Parent = mockIcon

            -- สัญลักษณ์มุมบนซ้าย
            local symLbl = Instance.new("TextLabel")
            symLbl.Size = UDim2.new(0, 20, 0, 20)
            symLbl.Position = UDim2.new(0, 4, 0, 4)
            symLbl.BackgroundTransparency = 1
            symLbl.Text = tagIcon
            symLbl.TextSize = 12
            symLbl.Parent = slot

            -- ป้ายจำนวนนับมุมล่างขวา
            local cntLbl = Instance.new("TextLabel")
            cntLbl.Size = UDim2.new(1, -6, 0, 18)
            cntLbl.Position = UDim2.new(0, 0, 1, -20)
            cntLbl.BackgroundTransparency = 1
            cntLbl.Text = "x" .. tostring(item.Count)
            cntLbl.TextColor3 = Color3.fromRGB(255, 255, 255)
            cntLbl.Font = Enum.Font.SourceSansBold
            cntLbl.TextSize = 13
            cntLbl.TextXAlignment = Enum.TextXAlignment.Right
            cntLbl.Parent = slot

            slot.MouseButton1Click:Connect(function()
                selectItem(item.Name, item.Count)
            end)
        else
            -- ช่องว่าง
            local emptyIcon = Instance.new("TextLabel")
            emptyIcon.Size = UDim2.new(1, 0, 1, 0)
            emptyIcon.BackgroundTransparency = 1
            emptyIcon.Text = "+"
            emptyIcon.TextColor3 = Color3.fromRGB(40, 46, 56)
            emptyIcon.Font = Enum.Font.SourceSans
            emptyIcon.TextSize = 22
            emptyIcon.Parent = slot
        end
    end

    gridScroll.CanvasSize = UDim2.new(0, 0, 0, gridLayout.AbsoluteContentSize.Y + 20)
end

-- รับการอัปเดตกระเป๋า
NetworkEvents.UpdateInventory.OnClientEvent:Connect(function(inventory)
    currentInventory = inventory or {}
    if mainFrame.Visible then
        updateGridUI()
        if selectedItemName then
            selectItem(selectedItemName, currentInventory[selectedItemName] or 0)
        end
    end
end)

-- ลงทะเบียนเข้าสู่ UIManager เพื่อควบคุมการเปิดทับกัน
UIManager:Register("Inventory", mainFrame, function()
    mainFrame.Visible = true
    updateGridUI()
end, function()
    mainFrame.Visible = false
end)

closeBtn.MouseButton1Click:Connect(function()
    UIManager:Close("Inventory")
end)

-- ปุ่มลอยเปิดกระเป๋า (Mobile Friendly)
local toggleButton = Instance.new("TextButton")
toggleButton.Name = "ToggleInventory"
toggleButton.Size = UDim2.new(0, 52, 0, 52)
toggleButton.Position = UDim2.new(1, -68, 0.5, -20)
toggleButton.BackgroundColor3 = Color3.fromRGB(35, 40, 52)
toggleButton.Text = "🎒"
toggleButton.TextSize = 28
toggleButton.Parent = screenGui

local tbCorner = Instance.new("UICorner")
tbCorner.CornerRadius = UDim.new(0, 26)
tbCorner.Parent = toggleButton

local tbStroke = Instance.new("UIStroke")
tbStroke.Thickness = 2
tbStroke.Color = Color3.fromRGB(60, 180, 120)
tbStroke.Parent = toggleButton

toggleButton.MouseButton1Click:Connect(function()
    UIManager:Toggle("Inventory")
end)

-- ปุ่มลัด 'B'
UserInputService.InputBegan:Connect(function(input, gameProcessed)
    if gameProcessed then return end
    if input.KeyCode == Enum.KeyCode.B then
        UIManager:Toggle("Inventory")
    end
end)

NetworkEvents.RequestInitialData:FireServer()

print("✅ [Client] Grid-Slot Inventory UI & UIManager พร้อมทำงาน! (กด B หรือคลิก 🎒)")
