--[[
    ToolbarCombatClient.client.lua
    ระบบแถบไอเทมลัด (Hotbar / Toolbar) และการต่อสู้ด้วยหมัดมวย/ศาสตราวุธ (Melee Combat)
    - แถบ Hotbar 6 ช่องที่ด้านล่างจอ (กดเลข 1-6 เพื่อสลับอาวุธ)
    - ช่องที่ 1: หมัดมวยปราณแท้ (Unarmed Punch) เสมอ
    - ช่องที่ 2-6: ศาสตราวุธและไอเทมที่ติดตั้งจากกระเป๋า
    - คลิกซ้าย (M1) เพื่อออกหมัดหรือฟันกระบี่ มีแอนิเมชัน คลื่นพลัง และเสียงเอฟเฟกต์
    - ระบบแสดงตัวเลขดาเมจลอยในโลก 3D (Floating Damage Numbers)
]]

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local UserInputService = game:GetService("UserInputService")
local TweenService = game:GetService("TweenService")
local RunService = game:GetService("RunService")

local localPlayer = Players.LocalPlayer
local playerGui = localPlayer:WaitForChild("PlayerGui")

local GameConfig = require(ReplicatedStorage:WaitForChild("SharedModules"):WaitForChild("GameConfig"))
local NetworkEvents = require(ReplicatedStorage:WaitForChild("Remotes"):WaitForChild("NetworkEvents"))

-- สร้าง ScreenGui
local screenGui = Instance.new("ScreenGui")
screenGui.Name = "ToolbarCombatGui"
screenGui.ResetOnSpawn = false
screenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
screenGui.Parent = playerGui

--------------------------------------------------------------------------------
-- 1. แถบ Hotbar ด้านล่างกลางจอ (6 ช่อง)
--------------------------------------------------------------------------------
local hotbarFrame = Instance.new("Frame")
hotbarFrame.Name = "HotbarFrame"
hotbarFrame.Size = UDim2.new(0, 360, 0, 62)
hotbarFrame.Position = UDim2.new(0.5, -180, 1, -74)
hotbarFrame.BackgroundColor3 = Color3.fromRGB(15, 18, 24)
hotbarFrame.BorderSizePixel = 0
hotbarFrame.Parent = screenGui

local hfCorner = Instance.new("UICorner")
hfCorner.CornerRadius = UDim.new(0, 10)
hfCorner.Parent = hotbarFrame

local hfStroke = Instance.new("UIStroke")
hfStroke.Thickness = 2
hfStroke.Color = Color3.fromRGB(80, 100, 140)
hfStroke.Parent = hotbarFrame

local hfLayout = Instance.new("UIListLayout")
hfLayout.FillDirection = Enum.FillDirection.Horizontal
hfLayout.HorizontalAlignment = Enum.HorizontalAlignment.Center
hfLayout.VerticalAlignment = Enum.VerticalAlignment.Center
hfLayout.Padding = UDim.new(0, 8)
hfLayout.Parent = hotbarFrame

-- โครงสร้างข้อมูลช่อง Hotbar
local hotbarSlots = {
    [1] = { Name = "หมัดมวยปราณแท้", Icon = "👊", Type = "Fist", WeaponData = GameConfig.Weapons["หมัดมวยปราณแท้"] },
    [2] = { Name = "กระบี่ไม้เซียน", Icon = "⚔️", Type = "Sword", WeaponData = GameConfig.Weapons["กระบี่ไม้เซียน"] },
    [3] = nil,
    [4] = nil,
    [5] = nil,
    [6] = nil,
}

local selectedSlotIndex = 1
local slotButtons = {}
local isAttacking = false
local attackCooldown = false

-- สร้างปุ่มแต่ละช่องใน Hotbar
local function buildHotbarUI()
    for _, btn in pairs(slotButtons) do
        btn:Destroy()
    end
    slotButtons = {}

    for i = 1, 6 do
        local slotData = hotbarSlots[i]

        local slotBtn = Instance.new("TextButton")
        slotBtn.Name = "Slot_" .. i
        slotBtn.Size = UDim2.new(0, 50, 0, 50)
        slotBtn.BackgroundColor3 = (i == selectedSlotIndex) and Color3.fromRGB(35, 45, 65) or Color3.fromRGB(22, 26, 36)
        slotBtn.Text = ""
        slotBtn.AutoButtonColor = true
        slotBtn.Parent = hotbarFrame

        local sc = Instance.new("UICorner")
        sc.CornerRadius = UDim.new(0, 8)
        sc.Parent = slotBtn

        local ss = Instance.new("UIStroke")
        ss.Name = "SlotStroke"
        ss.Thickness = (i == selectedSlotIndex) and 2 or 1
        ss.Color = (i == selectedSlotIndex) and Color3.fromRGB(255, 215, 80) or Color3.fromRGB(50, 56, 72)
        ss.Parent = slotBtn

        -- ป้ายหมายเลขคีย์ลัดมุมบนซ้าย [1]-[6]
        local keyLbl = Instance.new("TextLabel")
        keyLbl.Size = UDim2.new(0, 16, 0, 16)
        keyLbl.Position = UDim2.new(0, 4, 0, 2)
        keyLbl.BackgroundTransparency = 1
        keyLbl.Text = tostring(i)
        keyLbl.TextColor3 = Color3.fromRGB(180, 190, 210)
        keyLbl.Font = Enum.Font.SourceSansBold
        keyLbl.TextSize = 12
        keyLbl.Parent = slotBtn

        -- ไอคอนของไอเทมในช่อง
        local iconLbl = Instance.new("TextLabel")
        iconLbl.Size = UDim2.new(1, 0, 1, 0)
        iconLbl.BackgroundTransparency = 1
        iconLbl.Text = slotData and slotData.Icon or ""
        iconLbl.TextSize = 24
        iconLbl.Parent = slotBtn

        slotBtn.MouseButton1Click:Connect(function()
            selectSlot(i)
        end)

        slotButtons[i] = slotBtn
    end
end

-- สลับช่องที่เลือกใช้งาน
function selectSlot(index)
    selectedSlotIndex = index
    for i = 1, 6 do
        local btn = slotButtons[i]
        if btn then
            local isSelected = (i == selectedSlotIndex)
            btn.BackgroundColor3 = isSelected and Color3.fromRGB(35, 45, 65) or Color3.fromRGB(22, 26, 36)
            local ss = btn:FindFirstChild("SlotStroke")
            if ss then
                ss.Thickness = isSelected and 2 or 1
                ss.Color = isSelected and Color3.fromRGB(255, 215, 80) or Color3.fromRGB(50, 56, 72)
            end
        end
    end
end

-- ติดตั้งอาวุธจากกระเป๋าลงใน Hotbar
_G.DaoistEquipWeapon = function(weaponName)
    local weaponData = GameConfig.Weapons and GameConfig.Weapons[weaponName]
    if not weaponData then return end

    -- หาช่องว่าง (เริ่มจากช่อง 2)
    local targetSlot = 2
    for i = 2, 6 do
        if hotbarSlots[i] == nil or hotbarSlots[i].Name == weaponName then
            targetSlot = i
            break
        end
    end

    hotbarSlots[targetSlot] = {
        Name = weaponName,
        Icon = (weaponData.Type == "Fist") and "👊" or "⚔️",
        Type = weaponData.Type or "Sword",
        WeaponData = weaponData
    }

    buildHotbarUI()
    selectSlot(targetSlot)
end

--------------------------------------------------------------------------------
-- 2. ระบบการโจมตี (Punch & Weapon Attack Logic)
--------------------------------------------------------------------------------
local function performAttackAction()
    if isAttacking or attackCooldown then return end

    local char = localPlayer.Character
    if not char then return end
    local hum = char:FindFirstChildOfClass("Humanoid")
    local root = char:FindFirstChild("HumanoidRootPart")
    if not hum or not root or hum.Health <= 0 then return end

    -- หากกำลังนั่งสมาธิ ให้โจมตีไม่ได้
    if localPlayer:GetAttribute("IsMeditating") then return end

    local activeItem = hotbarSlots[selectedSlotIndex]
    local weaponData = activeItem and activeItem.WeaponData or GameConfig.Weapons["หมัดมวยปราณแท้"]
    local cd = weaponData and weaponData.Cooldown or 0.45
    local atkRange = weaponData and weaponData.AttackRange or 6
    local wColor = weaponData and weaponData.Color or Color3.fromRGB(255, 200, 100)

    isAttacking = true
    attackCooldown = true

    -- แอนิเมชันขยับแขน/ออกหมัดเบื้องต้น
    local rightArm = char:FindFirstChild("RightHand") or char:FindFirstChild("Right Arm")
    if rightArm then
        local originalCFrame = rightArm.CFrame
        local swingTween = TweenService:Create(rightArm, TweenInfo.new(cd * 0.4, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
            CFrame = rightArm.CFrame * CFrame.Angles(math.rad(45), 0, math.rad(-30))
        })
        swingTween:Play()
        task.delay(cd * 0.4, function()
            local returnTween = TweenService:Create(rightArm, TweenInfo.new(cd * 0.5, Enum.EasingStyle.Quad, Enum.EasingDirection.In), {
                CFrame = originalCFrame
            })
            returnTween:Play()
        end)
    end

    -- แสดงคลื่นพลังปราณ/รอยฟันคมกระบี่ในโลก 3D (Slash / Fist Arc Effect)
    local slashPart = Instance.new("Part")
    slashPart.Name = "AttackVFX"
    slashPart.Size = Vector3.new(atkRange * 0.8, 0.4, 2.5)
    slashPart.CFrame = root.CFrame * CFrame.new(0, 0, -3.5) * CFrame.Angles(0, 0, math.rad(math.random(-25, 25)))
    slashPart.Material = Enum.Material.Neon
    slashPart.Color = wColor
    slashPart.Transparency = 0.2
    slashPart.CanCollide = false
    slashPart.Anchored = true
    slashPart.Parent = workspace

    local fadeTween = TweenService:Create(slashPart, TweenInfo.new(0.25, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
        Transparency = 1,
        Size = slashPart.Size * 1.4
    })
    fadeTween:Play()
    task.delay(0.28, function() slashPart:Destroy() end)

    -- การค้นหาเป้าหมาย (Raycast & Overlap in front of character)
    local overlapParams = OverlapParams.new()
    overlapParams.FilterType = Enum.RaycastFilterType.Exclude
    overlapParams.FilterDescendantsInstances = {char}

    local hitParts = workspace:GetPartBoundsInBox(root.CFrame * CFrame.new(0, 0, -(atkRange / 2)), Vector3.new(5, 5, atkRange), overlapParams)
    local targetFound = nil

    for _, part in ipairs(hitParts) do
        local targetModel = part:FindFirstAncestorOfClass("Model")
        if targetModel and targetModel ~= char then
            local tHum = targetModel:FindFirstChildOfClass("Humanoid")
            if tHum and tHum.Health > 0 then
                targetFound = targetModel
                break
            end
        end
    end

    -- ส่งคำสั่งโจมตีไปยังเซิร์ฟเวอร์
    if targetFound then
        task.spawn(function()
            local weaponName = activeItem and activeItem.Name or "หมัดมวยปราณแท้"
            NetworkEvents.PerformAttack:InvokeServer(targetFound, "Melee", weaponName)
        end)
    end

    task.delay(cd, function()
        isAttacking = false
        attackCooldown = false
    end)
end

-- รับการคลิกซ้าย (M1) เพื่อโจมตี
UserInputService.InputBegan:Connect(function(input, gameProcessed)
    if gameProcessed then return end

    -- ปุ่มตัวเลข 1-6 สำหรับเลือกช่อง Hotbar
    if input.KeyCode == Enum.KeyCode.One then selectSlot(1)
    elseif input.KeyCode == Enum.KeyCode.Two then selectSlot(2)
    elseif input.KeyCode == Enum.KeyCode.Three then selectSlot(3)
    elseif input.KeyCode == Enum.KeyCode.Four then selectSlot(4)
    elseif input.KeyCode == Enum.KeyCode.Five then selectSlot(5)
    elseif input.KeyCode == Enum.KeyCode.Six then selectSlot(6)
    end

    -- คลิกซ้ายเพื่อโจมตี
    if input.UserInputType == Enum.UserInputType.MouseButton1 then
        performAttackAction()
    end
end)

--------------------------------------------------------------------------------
-- 3. ระบบแสดงตัวเลขดาเมจลอยในโลก 3D (Floating Damage Numbers)
--------------------------------------------------------------------------------
NetworkEvents.ShowDamageIndicator.OnClientEvent:Connect(function(hitPos, damage, isCrit)
    if not hitPos then return end

    local damagePart = Instance.new("Part")
    damagePart.Size = Vector3.new(0.1, 0.1, 0.1)
    damagePart.Position = hitPos + Vector3.new(math.random(-1, 1) * 0.5, 0, math.random(-1, 1) * 0.5)
    damagePart.Transparency = 1
    damagePart.Anchored = true
    damagePart.CanCollide = false
    damagePart.Parent = workspace

    local bb = Instance.new("BillboardGui")
    bb.Size = isCrit and UDim2.new(0, 160, 0, 40) or UDim2.new(0, 120, 0, 30)
    bb.StudsOffset = Vector3.new(0, 1.5, 0)
    bb.AlwaysOnTop = true
    bb.Parent = damagePart

    local label = Instance.new("TextLabel")
    label.Size = UDim2.new(1, 0, 1, 0)
    label.BackgroundTransparency = 1
    label.Text = isCrit and string.format("💥 -%d CRIT!", damage) or string.format("-%d", damage)
    label.TextColor3 = isCrit and Color3.fromRGB(255, 80, 50) or Color3.fromRGB(255, 230, 80)
    label.Font = Enum.Font.SourceSansBold
    label.TextSize = isCrit and 22 or 17
    label.Parent = bb

    local stroke = Instance.new("UIStroke")
    stroke.Thickness = 2
    stroke.Color = Color3.fromRGB(0, 0, 0)
    stroke.Parent = label

    -- Tween ลอยขึ้นด้านบนและค่อยๆ จางหายไป
    local moveTween = TweenService:Create(bb, TweenInfo.new(1.2, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
        StudsOffset = Vector3.new(0, 4.2, 0)
    })
    local fadeTween = TweenService:Create(label, TweenInfo.new(1.2, Enum.EasingStyle.Quad, Enum.EasingDirection.In), {
        TextTransparency = 1
    })
    local strokeFade = TweenService:Create(stroke, TweenInfo.new(1.2, Enum.EasingStyle.Quad, Enum.EasingDirection.In), {
        Transparency = 1
    })

    moveTween:Play()
    fadeTween:Play()
    strokeFade:Play()

    task.delay(1.3, function()
        damagePart:Destroy()
    end)
end)

buildHotbarUI()
selectSlot(1)

print("✅ [Client] Hotbar Toolbar & Combat System พร้อมทำงาน! (กด 1-6 สลับอาวุธ, คลิกซ้ายเพื่อชก/ฟัน)")
