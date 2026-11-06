--[[
    RewardService.lua
    จัดการการมอบรางวัลและปรับปรุงค่าสเตตัสตัวละครอย่างปลอดภัย (Idempotent Reward Commits)
]]

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")
local NetworkEvents = require(ReplicatedStorage:WaitForChild("Remotes"):WaitForChild("NetworkEvents"))

local RewardService = {}

-- มอบรางวัลและปรับสเกลค่าสเตตัสตัวละครตามขอบเขตใหม่
function RewardService:ApplyRealmStats(player, realmConfig)
    local character = player.Character
    if not character then return end

    local humanoid = character:FindFirstChildOfClass("Humanoid")
    local root = character:FindFirstChild("HumanoidRootPart")
    if not humanoid or not root then return end

    local stats = realmConfig.BaseStats or {}
    local maxHealth = stats.MaxHealth or 100
    local walkSpeed = stats.WalkSpeed or 16
    local maxQi = stats.MaxQi or 50
    local attackPower = stats.AttackPower or 15
    local defense = stats.Defense or 5

    humanoid.MaxHealth = maxHealth
    humanoid.Health = maxHealth
    humanoid.WalkSpeed = walkSpeed

    player:SetAttribute("MaxHealth", maxHealth)
    player:SetAttribute("WalkSpeed", walkSpeed)
    player:SetAttribute("MaxQi", maxQi)
    player:SetAttribute("Chi", maxQi)
    player:SetAttribute("AttackPower", attackPower)
    player:SetAttribute("Defense", defense)

    -- อัปเดต Overhead Billboard
    local head = character:FindFirstChild("Head")
    if head then
        local bg = head:FindFirstChild("PlayerOverhead")
        if bg then
            local realmLabel = bg:FindFirstChild("RealmLabel")
            if realmLabel then
                realmLabel.Text = string.format("【%s】", realmConfig.Name)
                realmLabel.TextColor3 = realmConfig.Color or Color3.fromRGB(255, 230, 140)
            end
        end
    end
end

-- สร้างเอฟเฟกต์ระเบิดปราณทะลวงขั้น (Breakthrough Golden Lotus VFX)
function RewardService:PlayBreakthroughVFX(character, realmConfig)
    local root = character:FindFirstChild("HumanoidRootPart")
    if not root then return end

    local color = realmConfig.Color or Color3.fromRGB(255, 220, 100)

    local att = Instance.new("Attachment")
    att.Name = "BreakthroughFX"
    att.Parent = root

    -- ประกายแสงเสาพลังพุ่งขึ้นฟ้า
    local p = Instance.new("ParticleEmitter")
    p.Color = ColorSequence.new(color, Color3.fromRGB(255, 255, 255))
    p.Size = NumberSequence.new({
        NumberSequenceKeypoint.new(0, 3),
        NumberSequenceKeypoint.new(0.5, 6),
        NumberSequenceKeypoint.new(1, 0)
    })
    p.Lifetime = NumberRange.new(1.0, 1.8)
    p.Rate = 120
    p.Speed = NumberRange.new(15, 30)
    p.SpreadAngle = Vector2.new(20, 20)
    p.EmissionDirection = Enum.NormalId.Top
    p.LightEmission = 1.0
    p.Parent = att

    -- แสงสว่างเจิดจ้า
    local light = Instance.new("PointLight")
    light.Color = color
    light.Range = 25
    light.Brightness = 8
    light.Parent = root

    TweenService:Create(light, TweenInfo.new(2.5, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
        Brightness = 0,
        Range = 0
    }):Play()

    task.delay(2.5, function()
        if att and att.Parent then att:Destroy() end
        if light and light.Parent then light:Destroy() end
    end)
end

-- ดำเนินการมอบรางวัลทะลวงขั้นแบบครบวงจร
function RewardService:CommitReward(player, newRealmConfig)
    local profile = _G.ProfileService and _G.ProfileService:GetProfile(player)
    if profile and profile.Cultivation then
        profile.Cultivation.RealmId = newRealmConfig.Id
        profile.Cultivation.RealmLevel = newRealmConfig.Level
        profile.Cultivation.CultivationExp = 0
        profile.Cultivation.RequiredExp = newRealmConfig.RequiredExp or 100000
        profile.Cultivation.BreakthroughState = "Locked"
        profile.Cultivation.LastBreakthroughAt = os.time()
        
        if newRealmConfig.Trial then
            profile.Cultivation.CompletedTrials[newRealmConfig.Trial.Id] = os.time()
        end
    end

    self:ApplyRealmStats(player, newRealmConfig)

    if player.Character then
        self:PlayBreakthroughVFX(player.Character, newRealmConfig)
        NetworkEvents.BreakthroughEffect:FireAllClients(player.Character, newRealmConfig)
    end

    -- ประกาศข้อความยินดีทั้งเซิร์ฟเวอร์
    local announcement = string.format("📢 [ประกาศฟ้าดิน] ผู้บำเพ็ญ '%s' ได้ก้าวข้ามสู่ [%s] สำเร็จ! ได้รับฉายา «%s»",
        player.DisplayName, newRealmConfig.Name, newRealmConfig.Title)
    print(announcement)
end

return RewardService
