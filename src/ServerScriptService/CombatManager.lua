--[[
    CombatManager.lua
    ระบบคำนวณและตรวจสอบความเสียหาย (Combat & Party-Friendly Logic)
    - รองรับการโจมตีด้วยหมัดมวย (Fists) และศาสตราวุธ (Weapons)
    - ตรวจสอบโซน: ห้ามโจมตีในเมืองเริ่มต้น (Safe Zone) และแดนพฤกษาสวรรค์ (PvE Zone)
    - ตรวจสอบหุ่นฟางฝึกยุทธ์ (Training Dummy): สามารถโจมตีทดสอบได้ทุกที่
    - ตรวจสอบปาร์ตี้: ในแดน PvP ผู้เล่นที่อยู่ปาร์ตี้เดียวกันจะไม่ได้รับความเสียหาย
    - ตรวจสอบสถานะกลิ้งหลบ: หากเป้าหมายอยู่ในสถานะ IsDodging จะมี I-Frames ปลอดความเสียหาย
    - ตัวเลขดาเมจลอย (Floating Damage Numbers Indicator)
]]

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local GameConfig = require(ReplicatedStorage:WaitForChild("SharedModules"):WaitForChild("GameConfig"))
local NetworkEvents = require(ReplicatedStorage:WaitForChild("Remotes"):WaitForChild("NetworkEvents"))

local CombatManager = {}

-- ตรวจสอบว่าผู้โจมตีสามารถสร้างความเสียหายแก่เป้าหมายได้หรือไม่
function CombatManager.CanDamage(attacker, victim)
    if not attacker or not victim then return false, "ข้อมูลไม่ครบถ้วน" end
    if attacker == victim then return false, "ไม่สามารถโจมตีตัวเองได้" end

    -- กรณีเป้าหมายเป็นหุ่นดัมมี่ (Training Dummy) สามารถทดสอบดาเมจได้ทุกที่
    if typeof(victim) == "Instance" and victim:IsA("Model") and victim:GetAttribute("IsDummy") then
        return true, "โจมตีดัมมี่ได้ตลอดเวลา"
    end

    local victimPlayer = (typeof(victim) == "Instance" and victim:IsA("Player")) and victim or Players:GetPlayerFromCharacter(victim)
    if not victimPlayer then
        return true, "สามารถโจมตีวัตถุสิ่งมีชีวิตได้"
    end

    -- 1. ตรวจสอบสถานะอมตะหรือกลิ้งหลบของเป้าหมาย
    local victimChar = victimPlayer.Character
    if victimChar and victimChar:GetAttribute("IsDodging") then
        return false, "เป้าหมายกำลังม้วนตัวกลิ้งหลบ (I-Frames)"
    end
    if victimPlayer:GetAttribute("Invincible") then
        return false, "เป้าหมายอยู่ในสถานะกายาอมตะจักรพรรดิ์ (Invincible)"
    end

    -- 2. ตรวจสอบตำแหน่งโซนของเป้าหมาย
    local root = victimChar and victimChar:FindFirstChild("HumanoidRootPart")
    if not root then return false, "ไม่พบตำแหน่งเป้าหมาย" end
    local pos = root.Position

    local worldCoords = GameConfig.WorldCoordinates
    if worldCoords then
        -- อยู่ในหมู่บ้านเมฆาคราม (Safe Zone)
        local distFromCity = (pos - worldCoords.CityCenter).Magnitude
        if distFromCity <= 320 then
            return false, "เขตหมู่บ้านเมฆาคราม [Safe Zone] ห้ามประลองยุทธ์"
        end

        -- อยู่ในแดนพฤกษาสวรรค์ (PvE Zone)
        local pve = worldCoords.PvEZone
        if pve and (pos - pve.Center).Magnitude <= pve.Radius then
            return false, "แดนพฤกษาสวรรค์ [PvE Zone] ปลอดภัยจากการต่อสู้ระหว่างผู้เล่น"
        end
    end

    -- 3. ตรวจสอบปาร์ตี้เดียวกัน (Party Immunity)
    local partyA = attacker:GetAttribute("PartyId")
    local partyB = victimPlayer:GetAttribute("PartyId")
    if partyA and partyB and partyA == partyB then
        return false, "สหายร่วมปาร์ตี้ไม่สามารถทำร้ายกันได้"
    end

    return true, "สามารถโจมตีได้"
end

-- ประมวลผลความเสียหายอย่างปลอดภัย
function CombatManager.ApplyDamage(attacker, victim, damageAmount)
    local canDmg, reason = CombatManager.CanDamage(attacker, victim)
    if not canDmg then
        return false, reason
    end

    local victimChar = (typeof(victim) == "Instance" and victim:IsA("Model")) and victim or (victim.Character or victim)
    local hum = victimChar and victimChar:FindFirstChildOfClass("Humanoid")
    if hum and hum.Health > 0 then
        -- โบนัสพลังโจมตีจากโอสถ/บัฟของผู้โจมตี (AttackPowerBonus)
        local atkBonus = attacker and (attacker:GetAttribute("AttackPowerBonus") or 0) or 0
        if atkBonus > 0 then
            damageAmount = damageAmount * (1 + (atkBonus / 100))
        end

        -- บัฟกายาวชิระ (VajraArmor) ลดความเสียหายทางกายภาพ 60%
        if victimChar:GetAttribute("VajraArmor") or (typeof(victim) == "Instance" and victim:IsA("Player") and victim:GetAttribute("VajraArmor")) then
            damageAmount = damageAmount * 0.4
        end

        -- เช็คยันต์คุ้มภัย (Talisman Shield)
        local shield = victimChar:GetAttribute("TalismanShield") or 0
        if shield > 0 then
            local absorbed = math.min(shield, damageAmount)
            shield = shield - absorbed
            damageAmount = damageAmount - absorbed
            victimChar:SetAttribute("TalismanShield", (shield > 0) and shield or nil)
        end

        if damageAmount > 0 then
            hum:TakeDamage(damageAmount)
        end
        return true, "สร้างความเสียหายสำเร็จ"
    end

    return false, "เป้าหมายหมดสติแล้ว"
end

-- ประมวลผลการโจมตีจากผู้เล่น (Punches & Weapons)
function CombatManager.ProcessAttack(attacker, targetInstance, attackType, weaponName)
    local char = attacker.Character
    if not char then return false, "ไม่พบตัวละคร" end
    local root = char:FindFirstChild("HumanoidRootPart")
    if not root then return false, "ไม่พบตำแหน่ง" end

    -- ตรวจสอบข้อมูลอาวุธ
    local weaponData = GameConfig.Weapons and GameConfig.Weapons[weaponName or "หมัดมวยปราณแท้"]
    local baseDmg = weaponData and weaponData.BaseDamage or 15
    local atkRange = weaponData and weaponData.AttackRange or 6

    -- พลังโจมตีพื้นฐานของผู้เล่นตามขอบเขต
    local playerAtk = attacker:GetAttribute("AttackPower") or 10
    local totalDmg = baseDmg + playerAtk

    -- โบนัสคริติคอล 20%
    local isCrit = (math.random() < 0.20)
    if isCrit then
        totalDmg = totalDmg * 1.5
    end

    -- โบนัสบัฟโอสถ (AttackPowerBonus)
    local atkBonus = attacker:GetAttribute("AttackPowerBonus") or 0
    if atkBonus > 0 then
        totalDmg = totalDmg * (1 + (atkBonus / 100))
    end

    totalDmg = math.floor(totalDmg)

    if not targetInstance then
        return false, "ไม่พบเป้าหมาย"
    end

    local targetModel = targetInstance:FindFirstAncestorOfClass("Model") or targetInstance
    local targetHum = targetModel:FindFirstChildOfClass("Humanoid")
    local targetRoot = targetModel:FindFirstChild("HumanoidRootPart") or targetModel:FindFirstChild("Head") or targetModel.PrimaryPart

    if not targetHum or targetHum.Health <= 0 or not targetRoot then
        return false, "เป้าหมายไม่มีพลังชีวิต"
    end

    local dist = (root.Position - targetRoot.Position).Magnitude
    if dist > (atkRange + 6) then
        return false, "เป้าหมายอยู่นอกระยะโจมตี"
    end

    local hitPos = targetRoot.Position + Vector3.new(0, 1.5, 0)

    -- กรณีโจมตีหุ่นฟางฝึกยุทธ์ (Training Dummy)
    if targetModel:GetAttribute("IsDummy") then
        targetHum:TakeDamage(totalDmg)
        NetworkEvents.ShowDamageIndicator:FireAllClients(hitPos, totalDmg, isCrit)
        return true, "โจมตีหุ่นฝึกยุทธ์สำเร็จ", totalDmg
    end

    -- กรณีโจมตีผู้เล่น
    local victimPlayer = Players:GetPlayerFromCharacter(targetModel)
    if victimPlayer then
        local success, reason = CombatManager.ApplyDamage(attacker, victimPlayer, totalDmg)
        if success then
            NetworkEvents.ShowDamageIndicator:FireAllClients(hitPos, totalDmg, isCrit)
            return true, "โจมตีผู้เล่นสำเร็จ", totalDmg
        end
        return false, reason
    end

    -- มอนสเตอร์ทั่วไป
    targetHum:TakeDamage(totalDmg)
    NetworkEvents.ShowDamageIndicator:FireAllClients(hitPos, totalDmg, isCrit)
    return true, "โจมตีสำเร็จ", totalDmg
end

local SpawnedDummies = {}

-- สร้างหุ่นฟางซ้อมดาเมจ (Training Dummy)
function CombatManager:SpawnDummy(position, maxHp)
    maxHp = maxHp or 1000
    position = position or Vector3.new(0, 10, 0)

    local dummy = Instance.new("Model")
    dummy.Name = "TrainingDummy"
    dummy:SetAttribute("IsDummy", true)

    local root = Instance.new("Part")
    root.Name = "HumanoidRootPart"
    root.Size = Vector3.new(2, 2, 1)
    root.Position = position
    root.Anchored = true
    root.CanCollide = true
    root.Material = Enum.Material.Wood
    root.Color = Color3.fromRGB(160, 110, 60)
    root.Parent = dummy

    dummy.PrimaryPart = root

    local torso = Instance.new("Part")
    torso.Name = "Torso"
    torso.Size = Vector3.new(2, 2, 1)
    torso.CFrame = root.CFrame
    torso.Anchored = true
    torso.CanCollide = true
    torso.Material = Enum.Material.WoodPlanks
    torso.Color = Color3.fromRGB(140, 95, 50)
    torso.Parent = dummy

    local head = Instance.new("Part")
    head.Name = "Head"
    head.Shape = Enum.PartType.Cylinder
    head.Size = Vector3.new(1.2, 1.2, 1.2)
    head.CFrame = root.CFrame * CFrame.new(0, 1.6, 0) * CFrame.Angles(0, 0, math.rad(90))
    head.Anchored = true
    head.CanCollide = false
    head.Material = Enum.Material.Fabric
    head.Color = Color3.fromRGB(220, 180, 120)
    head.Parent = dummy

    local hum = Instance.new("Humanoid")
    hum.MaxHealth = maxHp
    hum.Health = maxHp
    hum.Parent = dummy

    -- สร้างหลอดเลือด 3D BillboardGui เหนือหัวดัมมี่
    local bb = Instance.new("BillboardGui")
    bb.Name = "DummyHealthGui"
    bb.Size = UDim2.new(4, 0, 1, 0)
    bb.StudsOffset = Vector3.new(0, 2.5, 0)
    bb.AlwaysOnTop = true
    bb.MaxDistance = 60
    bb.Parent = head

    local title = Instance.new("TextLabel")
    title.Size = UDim2.new(1, 0, 0.4, 0)
    title.BackgroundTransparency = 1
    title.Text = "🎯 หุ่นฟางฝึกยุทธ์ (Training Dummy)"
    title.TextColor3 = Color3.fromRGB(255, 230, 130)
    title.Font = Enum.Font.GothamBold
    title.TextScaled = true
    title.Parent = bb

    local hpBg = Instance.new("Frame")
    hpBg.Size = UDim2.new(1, 0, 0.35, 0)
    hpBg.Position = UDim2.new(0, 0, 0.45, 0)
    hpBg.BackgroundColor3 = Color3.fromRGB(40, 40, 45)
    hpBg.BorderSizePixel = 0
    hpBg.Parent = bb

    local hpBar = Instance.new("Frame")
    hpBar.Name = "HPFill"
    hpBar.Size = UDim2.new(1, 0, 1, 0)
    hpBar.BackgroundColor3 = Color3.fromRGB(230, 60, 60)
    hpBar.BorderSizePixel = 0
    hpBar.Parent = hpBg

    local hpText = Instance.new("TextLabel")
    hpText.Size = UDim2.new(1, 0, 1, 0)
    hpText.BackgroundTransparency = 1
    hpText.Text = string.format("%d / %d", maxHp, maxHp)
    hpText.TextColor3 = Color3.fromRGB(255, 255, 255)
    hpText.Font = Enum.Font.GothamBold
    hpText.TextScaled = true
    hpText.Parent = hpBg

    -- อัปเดตแถบเลือดและฟื้นฟูเลือดอัตโนมัติ
    local lastHitTime = os.clock()
    hum.HealthChanged:Connect(function(newHp)
        lastHitTime = os.clock()
        local pct = math.clamp(newHp / maxHp, 0, 1)
        hpBar.Size = UDim2.new(pct, 0, 1, 0)
        hpText.Text = string.format("%d / %d", math.floor(newHp), maxHp)
    end)

    task.spawn(function()
        while dummy and dummy.Parent do
            task.wait(1)
            if os.clock() - lastHitTime > 4 and hum.Health < maxHp then
                hum.Health = math.min(maxHp, hum.Health + (maxHp * 0.15))
            end
        end
    end)

    dummy.Parent = workspace
    table.insert(SpawnedDummies, dummy)
    return dummy
end

-- ล้างดัมมี่ทั้งหมด
function CombatManager:ClearDummies()
    for _, d in ipairs(SpawnedDummies) do
        if d and d.Parent then d:Destroy() end
    end
    SpawnedDummies = {}
end

-- รับรีโมตการโจมตีจาก Client
NetworkEvents.PerformAttack.OnServerInvoke = function(player, targetInstance, attackType, weaponName)
    return CombatManager.ProcessAttack(player, targetInstance, attackType, weaponName)
end

NetworkEvents.CombatAttack.OnServerInvoke = function(player, targetInstance, attackType, weaponName)
    return CombatManager.ProcessAttack(player, targetInstance, attackType, weaponName)
end

_G.DaoistCombatManager = CombatManager

return CombatManager
