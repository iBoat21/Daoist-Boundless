--[[
    CultivationConfig.lua
    การกำหนดค่าระบบขอบเขตพลัง, กฎการบำเพ็ญเพียร, และนิยามบททดสอบทะลวงขั้น
    ตามข้อกำหนด Genesis of the Myriad Gods: Daoist Boundless (Core System MVP)
]]

local CultivationTypes = require(script.Parent:WaitForChild("CultivationTypes"))

local CultivationConfig = {}

-- โครงสร้างข้อมูลตั้งต้นสำหรับผู้เล่นใหม่ (Schema Version 1)
CultivationConfig.DefaultSchema = {
    SchemaVersion = 1,
    RealmId = "SpiritEmbryo",
    RealmLevel = 1,
    CultivationExp = 0,
    RequiredExp = 1000,
    Qi = 0,
    MaxQi = 50,
    IsMeditating = false,
    BreakthroughState = CultivationTypes.BreakthroughState.Locked,
    TrialId = nil,
    TrialProgress = {},
    CompletedTrials = {},
    LastBreakthroughAt = 0,
}

-- อัตราการฟื้นฟูและการได้รับตบะ
CultivationConfig.AfkInterval = 1               -- ตรวจสอบและให้ตบะทุก 1 วินาที
CultivationConfig.BaseMeditationExp = 15        -- ตบะที่ได้รับต่อวินาทีเมื่อนั่งสมาธิ
CultivationConfig.SafeZoneExpBonus = 1.25       -- โบนัส 25% เมื่อนั่งสมาธิใน Safe Zone หมู่บ้านเมฆาคราม

-- สารบบขอบเขตพลังและบททดสอบทะลวงขั้น
CultivationConfig.Realms = {
    [1] = {
        Id = "SpiritEmbryo",
        Level = 1,
        Name = "ครรภ์เซียน (Spirit Embryo)",
        Title = "ผู้เริ่มต้นวิถีเซียน",
        RequiredExp = 1000,
        Color = Color3.fromRGB(150, 230, 180),
        BaseStats = {
            MaxHealth = 100,
            MaxQi = 50,
            QiRegen = 2,
            WalkSpeed = 16,
            AttackPower = 15,
            Defense = 5,
        },
        Trial = {
            Id = "Trial_SpiritEmbryo",
            Name = "พิธีเบิกวิญญาณปฐมปราณ (Spirit Awakening Ceremony)",
            Type = CultivationTypes.TrialType.BreathingRhythm,
            Lore = "กลืนกินโอสถเบิกวิญญาณเพื่อหลอมละลายเปลือกหุ้มตันเถียน แล้วควบคุมจังหวะการหายใจ 3 ห้วงเพื่อร้อยเรียงกระแสปราณเข้าสู่จุดชีพจรหลัก",
            RequiredItems = {
                ["โอสถเบิกวิญญาณ"] = 1,
            },
            ItemAliases = {
                ["โอสถเบิกวิญญาณ"] = "โอสถเบิกตัวอ่อนวิญญาณ"
            },
            Phases = {
                [1] = {
                    Phase = 1,
                    Name = "ช่วงที่ 1: รวบรวมลมปราณฟ้าดิน (Accumulation)",
                    Instruction = "กดปุ่มควบคุมลมหายใจตามจังหวะชีพจรเต้น",
                    BeatsRequired = 3,
                    TargetInterval = 2.0,
                    WindowTolerance = 0.65,
                },
                [2] = {
                    Phase = 2,
                    Name = "ช่วงที่ 2: ชำระล้างเส้นชีพจรหลัก (Circulation)",
                    Instruction = "เร่งกระแสปราณหมุนเวียนรอบกายาทั้งแปดทิศ",
                    BeatsRequired = 4,
                    TargetInterval = 1.8,
                    WindowTolerance = 0.55,
                },
                [3] = {
                    Phase = 3,
                    Name = "ช่วงที่ 3: จุดไฟปฐมตันเถียน (Ignition)",
                    Instruction = "ควบรวมปราณทั้งหมดระเบิดเปิดประตูจุดตันเถียน",
                    BeatsRequired = 4,
                    TargetInterval = 1.5,
                    WindowTolerance = 0.50,
                }
            },
            Reward = {
                MaxQi = 100,
                QiUnlocked = true,
                MaxHealth = 120,
                AttackPower = 20,
                Defense = 8,
                Description = "ปลดล็อกหลอดพลังปราณ (MaxQi 100 หน่วย), ปลดล็อกวิชาตัวเบาเร่งความเร็ว และเปิดระบบทะลวงขั้นถัดไป"
            }
        }
    },

    [2] = {
        Id = "FiveElements",
        Level = 2,
        Name = "เบญจธาตุ (Five Elements)",
        Title = "ผู้สอดประสานธาตุทั้งห้า",
        RequiredExp = 2500,
        Color = Color3.fromRGB(100, 200, 255),
        BaseStats = {
            MaxHealth = 160,
            MaxQi = 150,
            QiRegen = 4,
            WalkSpeed = 18,
            AttackPower = 28,
            Defense = 12,
        },
        Trial = {
            Id = "Trial_FiveElements",
            Name = "วัฏจักรเบญจธาตุกำเนิด (Five Elements Mutual Generation)",
            Type = CultivationTypes.TrialType.FiveElementsGeneration,
            Lore = "รวบรวมแก่นพลังธาตุทั้ง 5 ชนิดจากแดนฝึกตน แล้วถ่ายทอดประสานเข้าสู่ร่างตามลำดับวัฏจักรก่อเกิด: ดิน → ทอง → น้ำ → ไม้ → ไฟ เพื่อสถาปนาแก่นธาตุสถิต",
            RequiredItems = {
                ["แก่นปฐพี"] = 1,
                ["แก่นโลหะ"] = 1,
                ["แก่นวารี"] = 1,
                ["แก่นพฤกษา"] = 1,
                ["แก่นอัคคี"] = 1,
            },
            ElementSequence = { "Earth", "Metal", "Water", "Wood", "Fire" },
            ElementData = {
                Earth = { Name = "แก่นปฐพี", ElementName = "ดิน", Color = Color3.fromRGB(190, 140, 70), Hint = "ดิน ก่อเกิด ทอง" },
                Metal = { Name = "แก่นโลหะ", ElementName = "ทอง", Color = Color3.fromRGB(255, 225, 90), Hint = "ทอง ก่อเกิด น้ำ" },
                Water = { Name = "แก่นวารี", ElementName = "น้ำ", Color = Color3.fromRGB(80, 170, 255), Hint = "น้ำ ก่อเกิด ไม้" },
                Wood  = { Name = "แก่นพฤกษา", ElementName = "ไม้", Color = Color3.fromRGB(80, 220, 120), Hint = "ไม้ ก่อเกิด ไฟ" },
                Fire  = { Name = "แก่นอัคคี", ElementName = "ไฟ", Color = Color3.fromRGB(255, 90, 60), Hint = "ไฟ ก่อเกิด ดิน" },
            },
            Reward = {
                ElementalAffinity = "Harmonized",
                ResistanceBonus = 0.15,
                MaxQi = 150,
                MaxHealth = 160,
                AttackPower = 28,
                Defense = 12,
                Description = "ปลดล็อกความสอดประสานแห่งเบญจธาตุ, ต้านทานดาเมจทุกธาตุ +15%, พลังชีวิต 160 และ MaxQi 150"
            }
        }
    },

    -- ขั้น 3-7: นิยามเป็น Data-driven Roadmap ตามข้อกำหนด Section 5
    [3] = {
        Id = "SixDirections",
        Level = 3,
        Name = "หกภพ (Six Directions)",
        Title = "ผู้เบิกเนตรหกทิศ",
        RequiredExp = 5500,
        Color = Color3.fromRGB(180, 130, 255),
        BaseStats = { MaxHealth = 220, MaxQi = 200, QiRegen = 6, WalkSpeed = 19, AttackPower = 40, Defense = 18 },
        LockedRoadmap = true,
        RoadmapNotice = "เตรียมเปิดให้ทดสอบใน Phase ถัดไป (Roadmap Content)"
    },
    [4] = {
        Id = "SevenStars",
        Level = 4,
        Name = "เจ็ดดารา (Seven Stars)",
        Title = "ผู้สื่อสารหมู่ดวงดาว",
        RequiredExp = 12000,
        Color = Color3.fromRGB(255, 215, 80),
        BaseStats = { MaxHealth = 300, MaxQi = 260, QiRegen = 8, WalkSpeed = 20, AttackPower = 58, Defense = 26 },
        LockedRoadmap = true,
        RoadmapNotice = "เตรียมเปิดให้ทดสอบใน Phase ถัดไป (Roadmap Content)"
    },
    [5] = {
        Id = "CelestialBeing",
        Level = 5,
        Name = "กายสวรรค์ (Celestial Being)",
        Title = "ผู้หลุดพ้นแรงดึงดูด",
        RequiredExp = 25000,
        Color = Color3.fromRGB(255, 140, 90),
        BaseStats = { MaxHealth = 400, MaxQi = 350, QiRegen = 10, WalkSpeed = 22, AttackPower = 80, Defense = 36 },
        LockedRoadmap = true,
        RoadmapNotice = "เตรียมเปิดให้ทดสอบใน Phase ถัดไป (Roadmap Content)"
    },
    [6] = {
        Id = "LifeAndDeath",
        Level = 6,
        Name = "เกิดดับ (Life and Death)",
        Title = "ผู้รู้แจ้งวัฏสงสาร",
        RequiredExp = 50000,
        Color = Color3.fromRGB(240, 80, 110),
        BaseStats = { MaxHealth = 550, MaxQi = 450, QiRegen = 12, WalkSpeed = 23, AttackPower = 110, Defense = 50 },
        LockedRoadmap = true,
        RoadmapNotice = "เตรียมเปิดให้ทดสอบใน Phase ถัดไป (Roadmap Content)"
    },
    [7] = {
        Id = "DivineBridge",
        Level = 7,
        Name = "สะพานเทวะ (Divine Bridge)",
        Title = "ยอดเซียนไร้เทียมทาน",
        RequiredExp = 100000,
        Color = Color3.fromRGB(255, 230, 160),
        BaseStats = { MaxHealth = 750, MaxQi = 600, QiRegen = 15, WalkSpeed = 24, AttackPower = 150, Defense = 70 },
        LockedRoadmap = true,
        RoadmapNotice = "เตรียมเปิดให้ทดสอบใน Phase ถัดไป (Roadmap Content)"
    }
}

-- ค้นหา Realm ตาม Level หรือ Id
function CultivationConfig.GetRealm(levelOrId)
    if type(levelOrId) == "number" then
        return CultivationConfig.Realms[levelOrId]
    elseif type(levelOrId) == "string" then
        for _, realm in ipairs(CultivationConfig.Realms) do
            if realm.Id == levelOrId or realm.Name == levelOrId then
                return realm
            end
        end
    end
    return nil
end

return CultivationConfig
