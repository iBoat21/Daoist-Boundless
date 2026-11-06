--[[
    BreakthroughService.lua
    วงจรชีวิตพิธีทะลวงขั้นฉบับสมบูรณ์ (Breakthrough Lifecycle Service)
    ตามข้อกำหนดมาตรฐาน Section 4: ตรวจสอบพร้อม -> สรุปข้อมูล -> หักวัตถุดิบ Atomic -> ดำเนินบททดสอบ -> มอบรางวัล
]]

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")

local CultivationConfig = require(ReplicatedStorage:WaitForChild("SharedModules"):WaitForChild("CultivationConfig"))
local CultivationTypes = require(ReplicatedStorage:WaitForChild("SharedModules"):WaitForChild("CultivationTypes"))
local NetworkEvents = require(ReplicatedStorage:WaitForChild("Remotes"):WaitForChild("NetworkEvents"))

local ProfileService = require(script.Parent:WaitForChild("ProfileService"))
local TrialService = require(script.Parent:WaitForChild("TrialService"))
local RewardService = require(script.Parent:WaitForChild("RewardService"))

local BreakthroughService = {}

-- ตรวจสอบเงื่อนไขและความพร้อมในการทะลวงขั้น
function BreakthroughService:GetBreakthroughInfo(player)
    local cult = ProfileService:GetCultivation(player)
    if not cult then
        return { Success = false, Reason = "ไม่พบข้อมูลการบำเพ็ญเพียร" }
    end

    local currentLevel = cult.RealmLevel or 1
    local nextLevel = currentLevel + 1
    local currentRealm = CultivationConfig.Realms[currentLevel]
    local nextRealm = CultivationConfig.Realms[nextLevel]

    if not nextRealm then
        return {
            Success = false,
            IsMaxRealm = true,
            CurrentRealm = currentRealm,
            Message = "ท่านได้บรรลุขอบเขตสูงสุดของช่วงทดสอบแล้ว"
        }
    end

    local trialDef = currentRealm.Trial
    local isTapasyaFull = (cult.CultivationExp >= cult.RequiredExp)

    -- ตรวจสอบวัตถุดิบและโอสถที่จำเป็น
    local itemChecklist = {}
    local hasAllItems = true

    if trialDef and trialDef.RequiredItems then
        for itemName, requiredCount in pairs(trialDef.RequiredItems) do
            local alias = trialDef.ItemAliases and trialDef.ItemAliases[itemName]
            local hasItem, count = ProfileService:HasItem(player, itemName, requiredCount, alias)
            table.insert(itemChecklist, {
                Name = itemName,
                Required = requiredCount,
                Current = count,
                IsMet = hasItem
            })
            if not hasItem then
                hasAllItems = false
            end
        end
    end

    local canStart = isTapasyaFull and hasAllItems

    return {
        Success = true,
        CanStart = canStart,
        IsTapasyaFull = isTapasyaFull,
        HasAllItems = hasAllItems,
        CurrentRealm = currentRealm,
        NextRealm = nextRealm,
        Trial = trialDef,
        ItemChecklist = itemChecklist,
        Cultivation = cult,
    }
end

-- เริ่มต้นพิธีทะลวงขั้น (หักวัตถุดิบแบบ Atomic และเปิดบททดสอบ)
function BreakthroughService:StartTrial(player)
    local info = self:GetBreakthroughInfo(player)
    if not info.Success then
        return false, info.Reason or "ไม่สามารถเริ่มพิธีได้"
    end

    if not info.IsTapasyaFull then
        return false, CultivationTypes.ErrorCodes.NotReady
    end

    if not info.HasAllItems then
        return false, CultivationTypes.ErrorCodes.MissingItems
    end

    local activeSession = TrialService:GetActiveTrial(player)
    if activeSession then
        return false, CultivationTypes.ErrorCodes.TrialAlreadyActive
    end

    local trialDef = info.Trial
    if not trialDef then
        -- หากไม่มีบททดสอบ ให้เลื่อนขั้นได้ทันที
        return self:CommitBreakthrough(player, info.NextRealm)
    end

    -- [Atomic Deduction] หักวัตถุดิบและโอสถตามที่ระบุ
    if trialDef.RequiredItems then
        for itemName, requiredCount in pairs(trialDef.RequiredItems) do
            local alias = trialDef.ItemAliases and trialDef.ItemAliases[itemName]
            local ok, err = ProfileService:DeductItem(player, itemName, requiredCount, alias)
            if not ok then
                return false, "หักไอเทมไม่สำเร็จ: " .. tostring(err)
            end
        end
    end

    -- อัปเดตสถานะเป็น TrialActive
    ProfileService:MutateCultivation(player, function(cult)
        cult.BreakthroughState = CultivationTypes.BreakthroughState.TrialActive
        cult.TrialId = trialDef.Id
    end)

    -- เริ่มต้นเซสชันบททดสอบ
    local session = TrialService:StartTrial(player, trialDef)
    return true, "เริ่มพิธีทะลวงขั้นแล้ว! จงปฏิบัติตามบททดสอบ", session
end

-- ประมวลผล Action ที่ส่งมาจาก Client ระหว่างบททดสอบ
function BreakthroughService:SubmitAction(player, actionData)
    local cult = ProfileService:GetCultivation(player)
    if not cult or cult.BreakthroughState ~= CultivationTypes.BreakthroughState.TrialActive then
        return false, "ไม่มีบททดสอบที่กำลังดำเนินการอยู่", false
    end

    local ok, message, isTrialFinished = TrialService:ProcessAction(player, actionData)
    if not ok then
        return false, message, false
    end

    if isTrialFinished then
        -- ผ่านบททดสอบครบทุกขั้นตอน! เลื่อนขั้นและมอบรางวัล
        local nextLevel = (cult.RealmLevel or 1) + 1
        local nextRealm = CultivationConfig.Realms[nextLevel]
        if nextRealm then
            self:CommitBreakthrough(player, nextRealm)
            return true, "ผ่านบททดสอบและเลื่อนขั้นสำเร็จ!", true, nextRealm
        end
    end

    return true, message, false
end

-- ยืนยันการเลื่อนขั้นและมอบรางวัลอย่างปลอดภัย
function BreakthroughService:CommitBreakthrough(player, newRealm)
    RewardService:CommitReward(player, newRealm)

    ProfileService:MutateCultivation(player, function(cult)
        cult.RealmId = newRealm.Id
        cult.RealmLevel = newRealm.Level
        cult.CultivationExp = 0
        cult.RequiredExp = newRealm.RequiredExp or 100000
        cult.BreakthroughState = CultivationTypes.BreakthroughState.Locked
        cult.TrialId = nil
    end)

    local leaderstats = player:FindFirstChild("leaderstats")
    if leaderstats and leaderstats:FindFirstChild("Realm") then
        leaderstats.Realm.Value = newRealm.Name
    end

    return true, "ทะลวงสู่ขอบเขต " .. newRealm.Name .. " สำเร็จ!", newRealm
end

-- ยกเลิกบททดสอบอย่างปลอดภัย
function BreakthroughService:CancelTrial(player)
    local session = TrialService:GetActiveTrial(player)
    if session then
        TrialService:CancelTrial(player)
    end

    ProfileService:MutateCultivation(player, function(cult)
        cult.BreakthroughState = CultivationTypes.BreakthroughState.Ready
        cult.TrialId = nil
    end)

    return true, "ยกเลิกบททดสอบเรียบร้อยแล้ว"
end

-- ผูก Remotes เข้ากับ Service
NetworkEvents.RequestBreakthroughInfo.OnServerInvoke = function(player)
    return BreakthroughService:GetBreakthroughInfo(player)
end

NetworkEvents.StartBreakthroughTrial.OnServerInvoke = function(player)
    return BreakthroughService:StartTrial(player)
end

NetworkEvents.SubmitTrialAction.OnServerInvoke = function(player, actionData)
    return BreakthroughService:SubmitAction(player, actionData)
end

NetworkEvents.CancelBreakthroughTrial.OnServerInvoke = function(player)
    return BreakthroughService:CancelTrial(player)
end

-- ให้เข้ากันได้กับ Remote ดั้งเดิม
NetworkEvents.Breakthrough.OnServerInvoke = function(player)
    return BreakthroughService:StartTrial(player)
end

_G.BreakthroughService = BreakthroughService
return BreakthroughService
