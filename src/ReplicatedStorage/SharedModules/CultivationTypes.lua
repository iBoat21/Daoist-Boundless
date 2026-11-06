--[[
    CultivationTypes.lua
    นิยาม Type และ Enum สำหรับระบบ Progression และ Breakthrough ตาม MVP Specification
]]

local CultivationTypes = {}

-- สถานะการทะลวงขั้น (Breakthrough State Machine)
CultivationTypes.BreakthroughState = {
    Locked = "Locked",             -- ตบะยังไม่เต็ม หรือเงื่อนไขยังไม่ครบ
    Ready = "Ready",               -- ตบะเต็ม 100% ถึงคอขวด พร้อมเริ่มพิธี
    TrialActive = "TrialActive",   -- อยู่ในระหว่างการทำพิธี/บททดสอบ
    Success = "Success",           -- ผ่านบททดสอบและเลื่อนขั้นสำเร็จ
    Failed = "Failed"              -- ล้มเหลวในบททดสอบ (พร้อมเริ่มใหม่ ไม่เสีย Exp หลัก)
}

-- ชนิดของบททดสอบ (Trial Types)
CultivationTypes.TrialType = {
    BreathingRhythm = "BreathingRhythm",                 -- มินิเกมจังหวะลมหายใจ 3 ช่วง (Realm 1)
    FiveElementsGeneration = "FiveElementsGeneration",   -- มินิเกมวัฏจักรเบญจธาตุ ดิน->ทอง->น้ำ->ไม้->ไฟ (Realm 2)
    Roadmap = "Roadmap"                                 -- ขั้น 3-7 (Roadmap data-driven)
}

-- ข้อความแจ้งเตือนข้อผิดพลาด (Error Codes)
CultivationTypes.ErrorCodes = {
    NotReady = "ตบะยังไม่ถึงคอขวด 100% ไม่สามารถเริ่มพิธีได้",
    MissingItems = "วัตถุดิบและโอสถที่จำเป็นสำหรับพิธีไม่ครบถ้วน",
    TrialAlreadyActive = "กำลังดำเนินการบททดสอบอยู่แล้ว",
    InvalidAction = "คำสั่งการกระทำไม่ถูกต้องตามลำดับพิธี",
    NotInRitualZone = "ต้องอยู่ในจุดทำพิธีหรือเขตปลอดภัยในการเริ่มทะลวงขั้น",
    InternalError = "เกิดข้อผิดพลาดในการบันทึกข้อมูล กรุณาลองใหม่อีกครั้ง"
}

return CultivationTypes
