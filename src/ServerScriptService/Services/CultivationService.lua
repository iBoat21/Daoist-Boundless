--[[
    CultivationService.lua
    บริการควบคุมวงจรการบำเพ็ญเพียร, การนั่งสมาธิ (Meditation), และการล็อกคอขวด 100%
]]

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")

local CultivationConfig = require(ReplicatedStorage:WaitForChild("SharedModules"):WaitForChild("CultivationConfig"))
local CultivationTypes = require(ReplicatedStorage:WaitForChild("SharedModules"):WaitForChild("CultivationTypes"))
local NetworkEvents = require(ReplicatedStorage:WaitForChild("Remotes"):WaitForChild("NetworkEvents"))

local ProfileService = require(script.Parent:WaitForChild("ProfileService"))

local CultivationService = {}

-- สลับสถานะการนั่งสมาธิ
function CultivationService:SetMeditation(player, active)
    local char = player.Character
    if not char then return false end
    local hum = char:FindFirstChildOfClass("Humanoid")
    local root = char:FindFirstChild("HumanoidRootPart")
    if not hum or not root or hum.Health <= 0 then return false end

    if active then
        player:SetAttribute("IsMeditating", true)
        char:SetAttribute("IsMeditating", true)
        hum.Sit = true

        -- สร้างออร่าดอกบัวหมุนใต้เท้า (Lotus Aura)
        local existingAura = root:FindFirstChild("MeditationAura")
        if not existingAura then
            local att = Instance.new("Attachment")
            att.Name = "MeditationAura"
            att.Position = Vector3.new(0, -2.5, 0)
            att.Parent = root

            local p = Instance.new("ParticleEmitter")
            p.Name = "LotusParticles"
            p.Color = ColorSequence.new(Color3.fromRGB(120, 240, 180), Color3.fromRGB(255, 230, 120))
            p.Size = NumberSequence.new({
                NumberSequenceKeypoint.new(0, 0.4),
                NumberSequenceKeypoint.new(0.5, 1.2),
                NumberSequenceKeypoint.new(1, 0.1)
            })
            p.Lifetime = NumberRange.new(1.2, 2.0)
            p.Rate = 25
            p.Speed = NumberRange.new(2, 5)
            p.SpreadAngle = Vector2.new(180, 0)
            p.EmissionDirection = Enum.NormalId.Top
            p.LightEmission = 0.8
            p.Parent = att

            local light = Instance.new("PointLight")
            light.Name = "MeditationLight"
            light.Color = Color3.fromRGB(150, 255, 200)
            light.Range = 14
            light.Brightness = 2.5
            light.Parent = att
        end

        -- ตรวจจับการเคลื่อนไหวเพื่อยกเลิกสมาธิทันที
        local moveConn
        moveConn = hum:GetPropertyChangedSignal("MoveDirection"):Connect(function()
            if hum.MoveDirection.Magnitude > 0.1 then
                self:SetMeditation(player, false)
                if moveConn then moveConn:Disconnect() end
            end
        end)

        local jumpConn
        jumpConn = hum.Jumping:Connect(function(isActive)
            if isActive then
                self:SetMeditation(player, false)
                if jumpConn then jumpConn:Disconnect() end
            end
        end)

        NetworkEvents.MeditationStateChanged:FireClient(player, true)
        return true, true
    else
        player:SetAttribute("IsMeditating", false)
        char:SetAttribute("IsMeditating", false)
        hum.Sit = false

        local aura = root:FindFirstChild("MeditationAura")
        if aura then aura:Destroy() end

        NetworkEvents.MeditationStateChanged:FireClient(player, false)
        return true, false
    end
end

-- เพิ่มแต้มตบะแบบปลอดภัยและล็อกคอขวด
function CultivationService:AddExp(player, amount)
    ProfileService:MutateCultivation(player, function(cult)
        -- หากแต้มเต็มคอขวดอยู่แล้ว ห้ามเพิ่มต่อเด็ดขาด!
        if cult.CultivationExp >= cult.RequiredExp then
            cult.CultivationExp = cult.RequiredExp
            cult.BreakthroughState = CultivationTypes.BreakthroughState.Ready
            return
        end

        cult.CultivationExp = math.min(cult.RequiredExp, cult.CultivationExp + amount)

        if cult.CultivationExp >= cult.RequiredExp then
            cult.CultivationExp = cult.RequiredExp
            cult.BreakthroughState = CultivationTypes.BreakthroughState.Ready
        end
    end)
end

-- ลูป Heartbeat เพิ่มตบะและฟื้นฟูปราณ
task.spawn(function()
    while true do
        task.wait(CultivationConfig.AfkInterval or 1)

        for _, player in ipairs(Players:GetPlayers()) do
            local isMeditating = player:GetAttribute("IsMeditating") or false
            local cult = ProfileService:GetCultivation(player)

            if cult and isMeditating then
                local expGain = CultivationConfig.BaseMeditationExp
                -- โบนัสพื้นที่ปลอดภัย
                if player:GetAttribute("InSafeZone") then
                    expGain = expGain * CultivationConfig.SafeZoneExpBonus
                end
                CultivationService:AddExp(player, math.floor(expGain))
            end

            -- ฟื้นฟูค่าพลังปราณ (Chi Regeneration)
            if cult and cult.MaxQi and cult.MaxQi > 0 then
                local currentQi = player:GetAttribute("Chi") or 0
                local maxQi = player:GetAttribute("MaxQi") or cult.MaxQi
                local qiRegen = player:GetAttribute("QiRegen") or 2
                if currentQi < maxQi then
                    local newQi = math.min(maxQi, currentQi + qiRegen)
                    player:SetAttribute("Chi", newQi)
                    if player.Character then
                        player.Character:SetAttribute("Chi", newQi)
                    end
                end
            end
        end
    end
end)

-- ผูก Remote สลับสมาธิ
NetworkEvents.ToggleMeditation.OnServerInvoke = function(player)
    local isMeditating = player:GetAttribute("IsMeditating") or false
    return CultivationService:SetMeditation(player, not isMeditating)
end

_G.CultivationService = CultivationService
return CultivationService
