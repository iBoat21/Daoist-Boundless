--[[
    TrialService.lua
    ตัวควบคุมและตรวจสอบความถูกต้องของบททดสอบทะลวงขั้น (Server-Authoritative Trial Engine)
    - Trial 1: Breathing Rhythm Minigame (จังหวะลมหายใจ 3 ช่วง)
    - Trial 2: Five Elements Generation Minigame (วัฏจักรเบญจธาตุ ดิน->ทอง->น้ำ->ไม้->ไฟ)
]]

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local CultivationConfig = require(ReplicatedStorage:WaitForChild("SharedModules"):WaitForChild("CultivationConfig"))
local CultivationTypes = require(ReplicatedStorage:WaitForChild("SharedModules"):WaitForChild("CultivationTypes"))
local NetworkEvents = require(ReplicatedStorage:WaitForChild("Remotes"):WaitForChild("NetworkEvents"))

local ActiveTrials = {}

local TrialService = {}

-- เริ่มต้นเซสชันบททดสอบ
function TrialService:StartTrial(player, trialDef)
    local userId = player.UserId
    local trialSession = {
        TrialId = trialDef.Id,
        Type = trialDef.Type,
        StartedAt = os.clock(),
        LastActionAt = os.clock(),
        Phase = 1,
        BeatsInPhase = 0,
        CurrentElementStep = 1,
        Completed = false
    }

    ActiveTrials[userId] = trialSession

    -- แจ้งสถานะเริ่มต้นไปยัง Client
    NetworkEvents.TrialStateUpdate:FireClient(player, {
        State = "Started",
        TrialId = trialDef.Id,
        Type = trialDef.Type,
        Phase = 1,
        BeatsInPhase = 0,
        CurrentElementStep = 1,
        TotalPhases = trialDef.Phases and #trialDef.Phases or 1,
    })

    return trialSession
end

-- ดึงเซสชันที่กำลังดำเนินการ
function TrialService:GetActiveTrial(player)
    return ActiveTrials[player.UserId]
end

-- ยกเลิกบททดสอบ
function TrialService:CancelTrial(player)
    ActiveTrials[player.UserId] = nil
    NetworkEvents.TrialStateUpdate:FireClient(player, { State = "Cancelled" })
end

-- ประมวลผล Action ของ Trial 1: Breathing Rhythm
local function processBreathingAction(player, session, trialDef, actionData)
    local now = os.clock()
    local currentPhaseDef = trialDef.Phases[session.Phase]
    if not currentPhaseDef then
        return false, "Phase ไม่ถูกต้อง", false
    end

    local interval = now - session.LastActionAt
    session.LastActionAt = now

    -- สำหรับครั้งแรกของแต่ละ Phase อนุญาตให้เริ่มจังหวะได้ทันที
    local isFirstBeat = (session.BeatsInPhase == 0)
    local targetInterval = currentPhaseDef.TargetInterval
    local tolerance = currentPhaseDef.WindowTolerance

    local isHit = false
    if isFirstBeat then
        isHit = true
    else
        local diff = math.abs(interval - targetInterval)
        if diff <= tolerance then
            isHit = true
        else
            isHit = false
        end
    end

    if isHit then
        session.BeatsInPhase = session.BeatsInPhase + 1
        
        -- ตรวจสอบว่าครบจำนวนจังหวะของ Phase ปัจจุบันหรือไม่
        if session.BeatsInPhase >= currentPhaseDef.BeatsRequired then
            if session.Phase >= #trialDef.Phases then
                -- ผ่านครบทั้ง 3 Phase!
                session.Completed = true
                ActiveTrials[player.UserId] = nil
                NetworkEvents.TrialStateUpdate:FireClient(player, {
                    State = "PhaseComplete",
                    Phase = session.Phase,
                    BeatsInPhase = session.BeatsInPhase,
                    TrialFinished = true
                })
                return true, "ผ่านการควบคุมลมหายใจครบทั้ง 3 ห้วงบริสุทธิ์!", true
            else
                -- เลื่อนสู่ Phase ถัดไป
                session.Phase = session.Phase + 1
                session.BeatsInPhase = 0
                NetworkEvents.TrialStateUpdate:FireClient(player, {
                    State = "PhaseAdvance",
                    Phase = session.Phase,
                    BeatsInPhase = 0,
                    NextPhaseName = trialDef.Phases[session.Phase].Name
                })
                return true, "ก้าวข้ามสู่: " .. trialDef.Phases[session.Phase].Name, false
            end
        else
            -- ตีจังหวะเข้าเป้าหมาย
            NetworkEvents.TrialStateUpdate:FireClient(player, {
                State = "BeatHit",
                Phase = session.Phase,
                BeatsInPhase = session.BeatsInPhase,
                BeatsRequired = currentPhaseDef.BeatsRequired
            })
            return true, string.format("ชีพจรประสาน (%d/%d)", session.BeatsInPhase, currentPhaseDef.BeatsRequired), false
        end
    else
        -- ตีพลาดจังหวะ (ให้โอกาส Reset จังหวะใน Phase เดิม ไม่เสีย Exp หลัก)
        session.BeatsInPhase = 0
        NetworkEvents.TrialStateUpdate:FireClient(player, {
            State = "BeatMiss",
            Phase = session.Phase,
            BeatsInPhase = 0,
            Message = "จังหวะคลาดเคลื่อนเล็กน้อย รวมสมาธิแล้วลองใหม่"
        })
        return false, "จังหวะคลาดเคลื่อน! หายใจให้สอดคล้องกับชีพจรเต้น", false
    end
end

-- ประมวลผล Action ของ Trial 2: Five Elements Generation
local function processFiveElementsAction(player, session, trialDef, actionData)
    local selectedElement = actionData.Element
    local sequence = trialDef.ElementSequence
    local expectedElement = sequence[session.CurrentElementStep]

    if selectedElement == expectedElement then
        -- กดธาตุถูกต้องตามวัฏจักรก่อเกิด!
        local infusedName = trialDef.ElementData[selectedElement].Name
        session.CurrentElementStep = session.CurrentElementStep + 1

        if session.CurrentElementStep > #sequence then
            -- ประสานครบ 5 ธาตุ!
            session.Completed = true
            ActiveTrials[player.UserId] = nil
            NetworkEvents.TrialStateUpdate:FireClient(player, {
                State = "ElementInfused",
                Element = selectedElement,
                Step = #sequence,
                TrialFinished = true
            })
            return true, "วัฏจักรเบญจธาตุก่อเกิดประสานสมบูรณ์แบบ!", true
        else
            -- ก้าวสู่ธาตุถัดไป
            NetworkEvents.TrialStateUpdate:FireClient(player, {
                State = "ElementInfused",
                Element = selectedElement,
                Step = session.CurrentElementStep,
                NextHint = trialDef.ElementData[selectedElement].Hint
            })
            return true, string.format("ธาตุ %s ประสานสำเร็จ! (%s)", infusedName, trialDef.ElementData[selectedElement].Hint), false
        end
    else
        -- เลือกธาตุผิดลำดับวัฏจักร
        session.CurrentElementStep = 1
        NetworkEvents.TrialStateUpdate:FireClient(player, {
            State = "ElementMiss",
            Step = 1,
            Message = "ธาตุขัดแย้ง! ต้องเรียงลำดับ: ดิน ก่อเกิด ทอง ก่อเกิด น้ำ ก่อเกิด ไม้ ก่อเกิด ไฟ"
        })
        return false, "ธาตุขัดแย้ง! วัฏจักรเริ่มต้นใหม่ที่ธาตุดิน", false
    end
end

-- จุดรับคำสั่งและส่งต่อไปยัง Trial ที่เกี่ยวข้อง
function TrialService:ProcessAction(player, actionData)
    local session = ActiveTrials[player.UserId]
    if not session then
        return false, "ไม่มีบททดสอบที่กำลังดำเนินการอยู่", false
    end

    local realm = CultivationConfig.Realms[player:GetAttribute("RealmLevel") or 1]
    if not realm or not realm.Trial then
        return false, "ไม่พบข้อมูลบททดสอบ", false
    end

    local trialDef = realm.Trial

    if trialDef.Type == CultivationTypes.TrialType.BreathingRhythm then
        return processBreathingAction(player, session, trialDef, actionData)
    elseif trialDef.Type == CultivationTypes.TrialType.FiveElementsGeneration then
        return processFiveElementsAction(player, session, trialDef, actionData)
    else
        return false, "บททดสอบชนิดนี้ยังอยู่ในช่วงพัฒนา", false
    end
end

return TrialService
