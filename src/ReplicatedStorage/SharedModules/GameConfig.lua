local GameConfig = {}

-- รายการขอบเขตพลังและสเตตัสประจำแต่ละขั้น (14 มหาขอบเขต: กายามนุษย์ 7 ขั้น & ราชสำนักสวรรค์ 7 ชั้น)
GameConfig.Realms = {
    ----------------------------------------------------------------------------
    -- Part 1: 7 มหาขอบเขตกายามนุษย์ (ระดับปุถุชนสู่ยอดคน)
    ----------------------------------------------------------------------------
    [1] = {
        Id = 1,
        Part = 1,
        Name = "คลังตัวอ่อนวิญญาณ",
        NameEN = "Spirit Embryo",
        Title = "ผู้ตื่นรู้ตัวอ่อนวิญญาณ",
        RequiredExp = 0,
        MaxBottleneckExp = 1000, -- จุดคอขวดที่ต้องทะลวง
        BaseBreakthroughRate = 0.85,
        Color = Color3.fromRGB(180, 200, 180),
        Stats = {
            MaxHealth = 150,
            MaxChi = 100,
            ChiRegen = 3,
            TapasyaRegen = 10,
            WalkSpeed = 16,
            AttackPower = 20,
            Defense = 5,
        },
        UnlockedZone = "หมู่บ้านเมฆาคราม (Azure Cloud Village)",
        ZoneLevel = 1,
        Trial = {
            Name = "กะเทาะเปลือกไข่วิญญาณ",
            RequiredPill = "โอสถเบิกวิญญาณ",
            KeyIngredients = "หญ้าวิญญาณเขียว, ผลชะล้างไขกระดูก",
            MinigameType = "BreathingRhythm",
            Description = "ปุถุชนทุกคนเกิดมาพร้อมกับ 'เปลือกหิน' ปิดกั้นตันเถียน หลอมโอสถเบิกวิญญาณแล้วกลืนเพื่อคุมแรงดันลมปราณกะเทาะเปลือกไข่ให้ตัวอ่อนวิญญาณตื่นขึ้น!",
        },
        Description = "ปุถุชนทุกคนเกิดมาพร้อมกับ 'เปลือกหิน' ที่ปิดกั้นตันเถียนไว้ จิตวิญญาณหลับใหลอยู่ข้างในเหมือนตัวอ่อนในไข่ นั่งสมาธิรวบรวมไอวิญญาณหล่อเลี้ยงจนเต็มเพื่อกะเทาะเปลือกไข่"
    },
    [2] = {
        Id = 2,
        Part = 1,
        Name = "ห้าธาตุ",
        NameEN = "Five Elements",
        Title = "ผู้หลอมรวมเบญจธาตุ",
        RequiredExp = 1000,
        MaxBottleneckExp = 3500,
        BaseBreakthroughRate = 0.70,
        Color = Color3.fromRGB(85, 230, 140),
        Stats = {
            MaxHealth = 350,
            MaxChi = 250,
            ChiRegen = 6,
            TapasyaRegen = 25,
            WalkSpeed = 18,
            AttackPower = 45,
            Defense = 20,
        },
        UnlockedZone = "ป่าเบญจธาตุหมื่นภูผา",
        ZoneLevel = 2,
        Trial = {
            Name = "ล่าแก่นธาตุ & หลอมรวมตามวัฏจักร",
            RequiredPill = "โอสถธาตุสมบูรณ์",
            Sequence = {"Earth", "Metal", "Water", "Wood", "Fire"},
            SequenceTH = "ดิน -> ทอง -> น้ำ -> ไม้ -> ไฟ",
            Description = "ร่างกายขับเคลื่อนด้วย 5 ธาตุประจำอวัยวะ ตับ หัวใจ ม้าม ปอด ไต หลอมแก่นอสูร 5 ธาตุและซึมซับตามลำดับการก่อเกิด หากผิดพลาดจะติดสถานะธาตุไฟแตกซ่าน!",
        },
        Description = "ร่างกายขับเคลื่อนด้วย 5 ธาตุ (ไม้ ไฟ ดิน ทอง น้ำ) ประจำอยู่ที่ ตับ หัวใจ ม้าม ปอด ไต นั่งสมาธิสะสมปราณธาตุและหลอมรวมตามวัฏจักร"
    },
    [3] = {
        Id = 3,
        Part = 1,
        Name = "หกทิศ",
        NameEN = "Six Directions",
        Title = "ผู้ขยายมิติหกทิศ",
        RequiredExp = 3500,
        MaxBottleneckExp = 8000,
        BaseBreakthroughRate = 0.60,
        Color = Color3.fromRGB(85, 180, 255),
        Stats = {
            MaxHealth = 800,
            MaxChi = 600,
            ChiRegen = 15,
            TapasyaRegen = 60,
            WalkSpeed = 20,
            AttackPower = 95,
            Defense = 45,
        },
        UnlockedZone = "แดนพฤกษาสวรรค์ [PvE Zone]",
        ZoneLevel = 3,
        Trial = {
            Name = "ปักหมุดเจตจำนงสุดขอบโลก",
            Points = {"ยอดผาสูงชัน (บน)", "ก้นบึ้งรอยแยกเหวลึก (ล่าง)", "ทิศเหนือสุด", "ทิศใต้สุด", "ทิศตะวันออกสุด", "ทิศตะวันตกสุด"},
            HoldSeconds = 10,
            Description = "ปราณแผ่ขยายออกไป 6 ทิศรอบตัว เดินทางไปยัง 6 จุดธรรมชาติ ยืนต้านแรงลม 10 วินาทีเพื่อปักเสาเจตจำนงเชื่อมโครงข่ายสามมิติเข้าสู่ร่าง",
        },
        Description = "ปราณไม่ได้อยู่แค่ในอวัยวะ แต่แผ่ขยายออกไป 6 ทิศ (บน ล่าง เหนือ ใต้ ตะวันออก ตะวันตก) ทลายกรอบเนื้อหนัง"
    },
    [4] = {
        Id = 4,
        Part = 1,
        Name = "เจ็ดดาว",
        NameEN = "Seven Stars",
        Title = "ผู้สยบกลุ่มดาวกระบวยใหญ่",
        RequiredExp = 8000,
        MaxBottleneckExp = 18000,
        BaseBreakthroughRate = 0.50,
        Color = Color3.fromRGB(180, 140, 255),
        Stats = {
            MaxHealth = 1800,
            MaxChi = 1400,
            ChiRegen = 30,
            TapasyaRegen = 150,
            WalkSpeed = 22,
            AttackPower = 210,
            Defense = 95,
        },
        UnlockedZone = "หอดูดาวกระบวยสวรรค์",
        ZoneLevel = 4,
        Trial = {
            Name = "ทัณฑ์ดวงดาวกลางดึก (Time-Gated)",
            Condition = "เวลากลางคืนเท่านั้น",
            LightningStrikes = 7,
            Description = "ทำได้เฉพาะเวลากลางคืน ขึ้นไปนั่งบนแท่นหอดูดาว ชักนำสายฟ้าแสงดาวลงมาฟาดใส่ร่าง 7 ครั้ง เอาชีวิตรอดให้พ้นเพื่อเชื่อมพลังดาราจักร",
        },
        Description = "เชื่อมต่อพลัง 6 ทิศในร่างเข้ากับกลุ่มดาวกระบวยใหญ่ 7 ดวงบนท้องฟ้า ชักนำพลังดาราจักรเบื้องบนลงสู่ร่าง"
    },
    [5] = {
        Id = 5,
        Part = 1,
        Name = "ชาวสวรรค์",
        NameEN = "Celestial Being",
        Title = "ชาวสวรรค์เหินเวหา",
        RequiredExp = 18000,
        MaxBottleneckExp = 40000,
        BaseBreakthroughRate = 0.40,
        Color = Color3.fromRGB(255, 215, 80),
        Stats = {
            MaxHealth = 3800,
            MaxChi = 3000,
            ChiRegen = 60,
            TapasyaRegen = 350,
            WalkSpeed = 26,
            AttackPower = 420,
            Defense = 180,
        },
        UnlockedZone = "หุบเหวอสูรโลหิต [PvP Zone]",
        ZoneLevel = 5,
        Perk = "ปลดล็อกระบบบินลอยตัว (Flight) และออร่ารัศมีเซียนถาวร",
        Trial = {
            Name = "ผลัดกระดูกหยก & ดิ่งพสุธา",
            RequiredPill = "โอสถผลัดกระดูก",
            Description = "ดื่มโอสถผลัดกระดูก ร่างกายจะเข้าสู่สภาวะกระดูกสลาย เดินช้าลง จากนั้นกระโดดลงจากหน้าผาสูงเพื่อปลุกสัญชาตญาณเหินเวหา ปลดล็อกการบินถาวร!",
        },
        Description = "กายเนื้อเบาหวิว ปราณในร่างยกตัวลอยต้านแรงโน้มถ่วงโลก สลัดคราบปุถุชนเหินเวหาท่องนภา"
    },
    [6] = {
        Id = 6,
        Part = 1,
        Name = "เป็นตาย",
        NameEN = "Life and Death",
        Title = "ผู้หยั่งรู้เป็นตาย",
        RequiredExp = 40000,
        MaxBottleneckExp = 90000,
        BaseBreakthroughRate = 0.30,
        Color = Color3.fromRGB(240, 90, 90),
        Stats = {
            MaxHealth = 8500,
            MaxChi = 7000,
            ChiRegen = 120,
            TapasyaRegen = 800,
            WalkSpeed = 28,
            AttackPower = 900,
            Defense = 380,
        },
        UnlockedZone = "ประตูปราการยมโลก",
        ZoneLevel = 6,
        Trial = {
            Name = "ถอดจิตท่องแดนยมโลก",
            RequiredPill = "ยาพิษหยุดการเต้นของหัวใจ",
            TimeLimitSeconds = 180,
            Description = "ดื่มยาพิษหยุดหัวใจ ร่างเนื้อกลายเป็นหิน วิญญาณหลุดเข้ามิติขาวดำ วิ่งหลบยมทูตในเวลา 3 นาที ขโมยหญ้าคืนวิญญาณแล้ววิ่งกลับเข้าร่างให้ทัน",
        },
        Description = "จะเข้าใจการมีชีวิตอยู่ ต้องสัมผัสความตายเสียก่อน นั่งสมาธิขัดเกลาจิตวิญญาณข้ามขอบเหวปรโลก"
    },
    [7] = {
        Id = 7,
        Part = 1,
        Name = "สะพานเทวะ",
        NameEN = "Divine Bridge",
        Title = "ผู้ทอดสะพานสู่สวรรค์",
        RequiredExp = 90000,
        MaxBottleneckExp = 200000,
        BaseBreakthroughRate = 0.25,
        Color = Color3.fromRGB(255, 140, 0),
        Stats = {
            MaxHealth = 18000,
            MaxChi = 15000,
            ChiRegen = 250,
            TapasyaRegen = 1800,
            WalkSpeed = 30,
            AttackPower = 1800,
            Defense = 750,
        },
        UnlockedZone = "สะพานเทวะโบราณทอดสู่สรวงสวรรค์",
        ZoneLevel = 7,
        Trial = {
            Name = "ทอดสะพานข้ามอเวจี & ชนะใจตนเอง",
            RequiredItems = "ศิลาซ่อมสวรรค์ x10",
            Boss = "มารในใจ (Heart Demon - ตัวก๊อปปี้ผู้เล่น 100%)",
            Description = "ขุดศิลาซ่อมสวรรค์ 10 ก้อนมาสร้างสะพาน ขณะสร้างจะมีบอสมารในใจที่ก๊อปปี้ตัวละครผู้เล่น 100% ผุดขึ้นมา จงดวลชนะเงาตนเองเพื่อก้าวสู่แดนเทพ!",
        },
        Description = "สะพานที่เชื่อมระหว่างมนุษย์กับสวรรค์หักสะบั้นไปแล้ว ต้องสร้างสะพานของตนเองขึ้นมาใหม่ ก้าวข้ามขีดจำกัดมนุษย์สู่แดนเทพ"
    },

    ----------------------------------------------------------------------------
    -- Part 2: ราชสำนักสวรรค์ (Heavenly Palace — แดนเทพ 7 ชั้น)
    ----------------------------------------------------------------------------
    [8] = {
        Id = 8,
        Part = 2,
        Name = "ประตูสวรรค์ทิศใต้",
        NameEN = "Southern Heavenly Gate",
        Title = "กึ่งเทพผู้พิทักษ์ทวาราสวรรค์",
        RequiredExp = 200000,
        MaxBottleneckExp = 450000,
        BaseBreakthroughRate = 0.20,
        Color = Color3.fromRGB(120, 255, 220),
        Stats = {
            MaxHealth = 40000,
            MaxChi = 35000,
            ChiRegen = 500,
            TapasyaRegen = 4000,
            WalkSpeed = 32,
            AttackPower = 3600,
            Defense = 1500,
        },
        UnlockedZone = "ประตูสวรรค์ทิศใต้ (แดนเทพ)",
        ZoneLevel = 8,
        Perk = "สถานะกึ่งเทพ (วิ่งบนฟ้าได้เหมือนพื้นดิน)",
        Trial = {
            Name = "ศึกดวลเดี่ยวขุนพลเทพเฝ้าประตู",
            Restriction = "ห้ามปาร์ตี้ช่วย & ห้ามกินยาเกิน 3 ขวด",
            Reward = "สถานะกึ่งเทพ วิ่งบนท้องฟ้าได้อิสระ",
            Description = "ดวล 1v1 เอาชนะขุนพลเทพเฝ้าประตูสวรรค์ทิศใต้ เพื่อเปิดทางสู่แดนเทพชั้นใน",
        },
        Description = "ปราการด่านแรกของแดนสวรรค์ ดวล 1v1 เอาชนะขุนพลเทพเฝ้าประตูเพื่อปลดล็อกสถานะกึ่งเทพ"
    },
    [9] = {
        Id = 9,
        Part = 2,
        Name = "สระหยก",
        NameEN = "Jasper Pool",
        Title = "เซียนบริสุทธิ์สระหยก",
        RequiredExp = 450000,
        MaxBottleneckExp = 950000,
        BaseBreakthroughRate = 0.18,
        Color = Color3.fromRGB(80, 240, 180),
        Stats = {
            MaxHealth = 90000,
            MaxChi = 80000,
            ChiRegen = 1000,
            TapasyaRegen = 9000,
            WalkSpeed = 34,
            AttackPower = 7500,
            Defense = 3200,
        },
        UnlockedZone = "สระหยกอมฤตสวรรค์",
        ZoneLevel = 9,
        Perk = "เลือดและมานารีเจนเร็วขึ้น 5 เท่า & ภูมิคุ้มกันพิษทุกชนิด 100%",
        Trial = {
            Name = "แช่สระน้ำอมฤต & คุมสมดุลหยิน-หยาง",
            Reward = "Regen HP/Chi เร็วขึ้น 5 เท่า และภูมิคุ้มกันพิษถาวร",
            Description = "ลงไปแช่ในสระน้ำอมฤตเพื่อขับของเสียในวิญญาณ คุมสมดุลหยินหยางสู้กับคลื่นน้ำเย็นจัดและร้อนจัด",
        },
        Description = "ชำระล้างจิตวิญญาณในสระหยกอมฤต ปราศจากสิ่งเจือปน ร่างกายต้านทานพิษและฟื้นฟูมหาศาล"
    },
    [10] = {
        Id = 10,
        Part = 2,
        Name = "แท่นประหารเทพ",
        NameEN = "God Execution Stage",
        Title = "ผู้รอดพ้นทัณฑ์ประหารสวรรค์",
        RequiredExp = 950000,
        MaxBottleneckExp = 2000000,
        BaseBreakthroughRate = 0.15,
        Color = Color3.fromRGB(255, 60, 60),
        Stats = {
            MaxHealth = 200000,
            MaxChi = 180000,
            ChiRegen = 2200,
            TapasyaRegen = 20000,
            WalkSpeed = 36,
            AttackPower = 16000,
            Defense = 6800,
        },
        UnlockedZone = "แท่นประหารเทพโบราณ",
        ZoneLevel = 10,
        Perk = "สกิลติดตัว: โจมตีทะลุเกราะ 100% (True Damage)",
        Trial = {
            Name = "ทัณฑ์มีดประหารสวรรค์",
            Duration = 60,
            Reward = "โจมตีทะลุเกราะ 100% (True Damage)",
            Description = "เลือดโดนฟันเหลือ 1 หน่วยทันที! ต้องประคองสติหลบพายุคมมีดให้รอด 60 วินาที เพื่อพิสูจน์ตน",
        },
        Description = "ยอมจำนนต่อทัณฑ์สวรรค์เพื่อหล่อหลอมจิตสังหาร เลือดลดเหลือ 1 รอดพ้นพายุคมมีดเพื่อได้รับพลังโจมตีทะลุเกราะแท้จริง"
    },
    [11] = {
        Id = 11,
        Part = 2,
        Name = "เมืองหลวงหยก",
        NameEN = "Jade Capital",
        Title = "ผู้สถาปนาวิหารแห่งเต๋า",
        RequiredExp = 2000000,
        MaxBottleneckExp = 4500000,
        BaseBreakthroughRate = 0.12,
        Color = Color3.fromRGB(160, 240, 255),
        Stats = {
            MaxHealth = 450000,
            MaxChi = 400000,
            ChiRegen = 4500,
            TapasyaRegen = 45000,
            WalkSpeed = 38,
            AttackPower = 34000,
            Defense = 14500,
        },
        UnlockedZone = "นครหลวงหยกโบราณเก้าสวรรค์",
        ZoneLevel = 11,
        Perk = "All Stats +50% & ขยายช่องเก็บของและกระเป๋าไร้ขีดจำกัด",
        Trial = {
            Name = "สร้างวิหารแห่งเต๋าจำลอง",
            Reward = "All Stats +50% และช่องเก็บของขยายไม่จำกัด",
            Description = "มินิเกมสถาปัตยกรรม สร้าง 'วิหารแห่งเต๋าจำลอง' ในมิติตัวละครโดยใช้แร่ศักดิ์สิทธิ์ฟ้าดิน",
        },
        Description = "สร้างวิหารแห่งเต๋าในมิติดวงจิต ขยายความจุแห่งสวรรค์และเพิ่มพูนพลังทุกสาย 50%"
    },
    [12] = {
        Id = 12,
        Part = 2,
        Name = "นภาปราศจากสิ่งเจือปน",
        NameEN = "Numinous Sky",
        Title = "ผู้ท่องสุญญากาศนภาแท้",
        RequiredExp = 4500000,
        MaxBottleneckExp = 10000000,
        BaseBreakthroughRate = 0.10,
        Color = Color3.fromRGB(220, 160, 255),
        Stats = {
            MaxHealth = 1000000,
            MaxChi = 900000,
            ChiRegen = 9500,
            TapasyaRegen = 100000,
            WalkSpeed = 40,
            AttackPower = 72000,
            Defense = 31000,
        },
        UnlockedZone = "สุญญากาศนภาปราศจากสิ่งเจือปน",
        ZoneLevel = 12,
        Perk = "สกิลทุกอัน Instant Cast (ไม่มีเวลาร่าย) & ไร้สถานะสตั๊นตลอดกาล",
        Trial = {
            Name = "ท่องสุญญากาศอวกาศไร้แสงเสียง",
            Reward = "Instant Cast ทุกสกิล & ไม่มีวันติดสตั๊น",
            Description = "ท่องทะยานสู่สุญญากาศอวกาศที่ไร้แสง ไร้เสียง ฝ่าพายุความว่างเปล่าด้วยพลังเจตจำนงแท้จริง",
        },
        Description = "จิตวิญญาณหลุดพ้นจากสิ่งเจือปน ท่องสุญญากาศอวกาศ ปลดปล่อยเคล็ดวิชาฉับพลันไร้การสะดุด"
    },
    [13] = {
        Id = 13,
        Part = 2,
        Name = "บัลลังก์จักรพรรดิ",
        NameEN = "Emperor's Throne",
        Title = "มหาจักรพรรดิเก้าบรรพกาล",
        RequiredExp = 10000000,
        MaxBottleneckExp = 25000000,
        BaseBreakthroughRate = 0.08,
        Color = Color3.fromRGB(255, 215, 0),
        Stats = {
            MaxHealth = 2500000,
            MaxChi = 2200000,
            ChiRegen = 20000,
            TapasyaRegen = 250000,
            WalkSpeed = 42,
            AttackPower = 160000,
            Defense = 70000,
        },
        UnlockedZone = "ท้องพระโรงบัลลังก์ทองคำจักรพรรดิ",
        ZoneLevel = 13,
        Perk = "ออร่าจักรพรรดิ: ผู้เล่นขอบเขตต่ำกว่าเดินช้าลง 50% ทันทีเมื่อเข้าใกล้",
        Trial = {
            Name = "รับมือเงาจักรพรรดิโบราณ 9 องค์",
            Reward = "ออร่ากดดันจักรพรรดิ ศัตรูขอบเขตต่ำกว่าเดินช้าลง 50%",
            Description = "ขึ้นไปนั่งบนบัลลังก์ทอง แล้วรับมือกับเงาจักรพรรดิโบราณ 9 องค์ที่รุมโจมตีเข้ามาพร้อมกัน!",
        },
        Description = "ขึ้นสู่บัลลังก์จักรพรรดิเก้าบรรพกาล ปลดปล่อยแรงกดดันสะท้านสวรรค์ ผู้มีขอบเขตต่ำกว่าล้วนสยบแทบเท้า"
    },
    [14] = {
        Id = 14,
        Part = 2,
        Name = "ราชสำนักสวรรค์",
        NameEN = "Heavenly Court",
        Title = "มหาเทพสูงสุดแห่งราชสำนักสวรรค์",
        RequiredExp = 25000000,
        MaxBottleneckExp = nil, -- จุดสูงสุดของจักรวาล
        BaseBreakthroughRate = 0.05,
        Color = Color3.fromRGB(255, 255, 255),
        Stats = {
            MaxHealth = 6000000,
            MaxChi = 5000000,
            ChiRegen = 50000,
            TapasyaRegen = 600000,
            WalkSpeed = 45,
            AttackPower = 380000,
            Defense = 160000,
        },
        UnlockedZone = "ราชสำนักสวรรค์สูงสุดแห่งมหาเอกภพ",
        ZoneLevel = 14,
        Perk = "ฉายา [มหาเทพสูงสุด], รัศมีแสงสีทองถาวร, สลักชื่อบนศิลากลางเมืองให้ทั้งเซิร์ฟเวอร์เห็น",
        Trial = {
            Name = "มหาทัณฑ์สายฟ้า 99 เส้น (Server Broadcast Event)",
            Strikes = 99,
            Reward = "ฉายามหาเทพสูงสุด รัศมีทองคำถาวร สลักชื่อบนศิลากลางเมือง",
            Description = "มหาทัณฑ์สายฟ้า 99 เส้น! ท้องฟ้าทั้งเซิร์ฟเวอร์จะมืดดับ มีประกาศวิ่งทั้งเกม ฟ้าผ่าฟาดลงมา ถ้าทนจนจบได้จะบรรลุขั้นสูงสุด!",
        },
        Description = "จุดสูงสุดแห่งมหาเอกภพ บรรลุเป็นมหาเทพสูงสุดแห่งราชสำนักสวรรค์ ผู้ปกครองกฎเกณฑ์ฟ้าดินและสรรพชีวิต"
    }
}

-- รายการศาสตราวุธและอุปกรณ์สวมใส่ (Weapons & Tools)
GameConfig.Weapons = {
    ["หมัดมวยปราณแท้"] = {
        Name = "หมัดมวยปราณแท้",
        Type = "Fist",
        Slot = 1,
        BaseDamage = 15,
        AttackRange = 5,
        Cooldown = 0.45,
        Animation = "Punch",
        Color = Color3.fromRGB(255, 200, 100),
        Description = "เพลงหมัดพื้นฐานของนักพรต ชกด้วยพลังปราณธรรมชาติ",
    },
    ["กระบี่ไม้เซียน"] = {
        Name = "กระบี่ไม้เซียน",
        Type = "Sword",
        Slot = 2,
        BaseDamage = 35,
        AttackRange = 7,
        Cooldown = 0.55,
        Animation = "Slash",
        Color = Color3.fromRGB(120, 220, 140),
        Description = "กระบี่ไม้ท้อเหลาอาคม สร้างความเสียหายฟันลมปราณ",
    },
    ["กระบี่เหล็กฟ้าคราม"] = {
        Name = "กระบี่เหล็กฟ้าคราม",
        Type = "Sword",
        Slot = 2,
        BaseDamage = 80,
        AttackRange = 8,
        Cooldown = 0.50,
        Animation = "Slash",
        Color = Color3.fromRGB(80, 180, 255),
        Description = "กระบี่เหล็กกลั่นจากแร่ฟ้าคราม คมกริบเฉือนผ่านเนื้อเหล็ก",
    },
    ["ดาบเพลิงสุริยัน"] = {
        Name = "ดาบเพลิงสุริยัน",
        Type = "Blade",
        Slot = 2,
        BaseDamage = 180,
        AttackRange = 8,
        Cooldown = 0.60,
        Animation = "HeavySlash",
        Color = Color3.fromRGB(255, 100, 40),
        Description = "ดาบยักษ์อาบเพลิงสุริยัน ฟันพร้อมคลื่นเพลิงระเบิด",
    },
    ["ทวนวายุทลายเมฆา"] = {
        Name = "ทวนวายุทลายเมฆา",
        Type = "Spear",
        Slot = 2,
        BaseDamage = 350,
        AttackRange = 11,
        Cooldown = 0.70,
        Animation = "Thrust",
        Color = Color3.fromRGB(140, 240, 200),
        Description = "ทวนยาวแทงทะลวงลมปราณ แทงได้ไกลและรวดเร็ว",
    },
    ["กระบี่เซียนเก้ามังกร"] = {
        Name = "กระบี่เซียนเก้ามังกร",
        Type = "Sword",
        Slot = 2,
        BaseDamage = 1200,
        AttackRange = 10,
        Cooldown = 0.40,
        Animation = "Slash",
        Color = Color3.fromRGB(255, 215, 0),
        Description = "กระบี่เซียนโบราณสถิตวิญญาณมังกรทอง โจมตีเป็นสายฟ้าทองคำ",
    }
}

-- รายชื่อสมุนไพรและค่าพลังทางโอสถ (Alchemy Potency)
GameConfig.Herbs = {
    ["หญ้าวิญญาณเขียว"] = {
        Rarity = "Common",
        Description = "พบเห็นได้ทั่วไป ช่วยฟื้นฟูพลังเล็กน้อย",
        Color = Color3.fromRGB(85, 255, 127),
        Potency = 10,
        Element = "ธาตุไม้ (Wood)"
    },
    ["โสมร้อยปี"] = {
        Rarity = "Rare",
        Description = "สมุนไพรหายาก เพิ่มรากฐานพลัง",
        Color = Color3.fromRGB(255, 170, 0),
        Potency = 35,
        Element = "ธาตุดิน (Earth)"
    },
    ["บัวหิมะพันปี [ระดับเทพ]"] = {
        Rarity = "Legendary",
        Description = "สมุนไพรในตำนาน พลังมหาศาล!",
        Color = Color3.fromRGB(170, 255, 255),
        Potency = 120,
        Element = "ธาตุน้ำแข็งเทวะ (Divine Ice)"
    }
}

GameConfig.HerbSpawnInterval = 30 -- สปอนสมุนไพรทุกๆ 30 วินาที

-- รายชื่อพื้นที่และม่านพลัง (Zone Barriers)
GameConfig.Zones = {
    {
        Name = "ป่าเบญจธาตุหมื่นภูผา",
        RequiredRealm = "ห้าธาตุ",
        RequiredRealmIndex = 2,
        Position = Vector3.new(0, 5, 80),
        BarrierSize = Vector3.new(40, 20, 4),
        Color = Color3.fromRGB(85, 230, 140),
        Description = "ต้องการขอบเขต [ห้าธาตุ] ขึ้นไปเพื่อผ่านม่านพลัง"
    },
    {
        Name = "แดนพฤกษาสวรรค์",
        RequiredRealm = "หกทิศ",
        RequiredRealmIndex = 3,
        Position = Vector3.new(0, 5, 180),
        BarrierSize = Vector3.new(40, 20, 4),
        Color = Color3.fromRGB(85, 180, 255),
        Description = "ต้องการขอบเขต [หกทิศ] ขึ้นไปเพื่อผ่านม่านพลัง"
    }
}

-- พิกัดและข้อมูลโซนแผนที่โลก (World Coordinates & Biomes)
GameConfig.WorldCoordinates = {
    CityCenter = Vector3.new(0, 10, 0),         -- Azure Cloud Village (หมู่บ้านเมฆาคราม)
    CitySpawn = Vector3.new(0, 15, 0),
    CityPortals = {
        ToPvE = Vector3.new(-250, 10, 250),
        ToPvP = Vector3.new(250, 10, 250),
    },
    PvEZone = {
        Name = "แดนพฤกษาสวรรค์ (Empyrean Mist Forest)",
        Center = Vector3.new(1500, 50, 0),
        Spawn = Vector3.new(1500, 50, 0),
        ReturnPortal = Vector3.new(1500, 50, 0),
        Radius = 320,
        IsPvP = false,
        BannerText = "🌿 เข้าสู่แดนพฤกษาสวรรค์ [PvE Zone] - ปลอดภัยจากการต่อสู้",
        BannerColor = Color3.fromRGB(85, 255, 170),
        AtmosphereColor = Color3.fromRGB(160, 240, 220),
        FogColor = Color3.fromRGB(180, 255, 230),
        FogEnd = 350,
    },
    PvPZone = {
        Name = "หุบเหวอสูรโลหิต (Abyssal Asura Valley)",
        Center = Vector3.new(-1500, 50, 0),
        Spawn = Vector3.new(-1500, 50, 0),
        ReturnPortal = Vector3.new(-1500, 50, 0),
        Radius = 320,
        IsPvP = true,
        BannerText = "⚠️ เข้าสู่หุบเขาอสูรโลหิต [PvP Zone] - ผู้เล่นนอกปาร์ตี้สามารถโจมตีกันได้!",
        BannerColor = Color3.fromRGB(255, 80, 60),
        AtmosphereColor = Color3.fromRGB(220, 60, 40),
        FogColor = Color3.fromRGB(100, 25, 20),
        FogEnd = 260,
    }
}

-- รายการสินค้าในร้านค้า NPC (NPC Merchant Inventories)
GameConfig.ShopConfig = {
    ElderQing = {
        Title = "หอโอสถเทวะ - ผู้อาวุโสชิง เจ้าหอโอสถ",
        Description = "จำหน่ายสมุนไพรตั้งต้น และรับซื้อโอสถวิเศษที่ท่านหลอมขึ้น",
        Items = {
            { Name = "หญ้ากระดูกมังกรดิน", Type = "Herb", Price = 150, Currency = "Tapasya", Description = "สมุนไพรธาตุดิน 100 ปี เสริมความเสถียร" },
            { Name = "ดอกเพลิงกัลป์ป่า", Type = "Herb", Price = 180, Currency = "Tapasya", Description = "สมุนไพรธาตุไฟ 100 ปี พลังรุนแรง" },
            { Name = "ไผ่หยกเขียวขจี", Type = "Herb", Price = 150, Currency = "Tapasya", Description = "สมุนไพรธาตุวายุ 100 ปี ปราณไหลเวียน" },
            { Name = "ผลชะล้างไขกระดูก", Type = "Herb", Price = 250, Currency = "Tapasya", Description = "สมุนไพรปรับปรุงเส้นชีพจร ชำระสิ่งเจือปน" },
            { Name = "โสมร้อยปี", Type = "Herb", Price = 300, Currency = "Tapasya", Description = "สมุนไพรหายาก เพิ่มรากฐานพลัง" },
        }
    },
    MasterTie = {
        Title = "หอศัสตราวุธเซียน - ปรมาจารย์เถี่ย ช่างตีเหล็กสวรรค์",
        Description = "สร้างสรรค์เครื่องมือและศาสตราวุธเพื่อช่วยในการบำเพ็ญเพียร",
        Items = {
            { Name = "เคียวตัดสมุนไพรเทวะ", Type = "Tool", Price = 1200, Currency = "Tapasya", Description = "เคียวอาคม ช่วยเพิ่มผลผลิตการเด็ดสมุนไพร +1 ชิ้นทุกครั้ง!" },
            { Name = "กระเป๋ามิติร้อยช่อง", Type = "BagUpgrade", Price = 2500, Currency = "Tapasya", Description = "ขยายขนาดความจุกระเป๋าและช่องใส่ของ" },
            { Name = "ยันต์หยกคุ้มกายาสวรรค์", Type = "Talisman", Price = 800, Currency = "Tapasya", Description = "สร้างบาเรียป้องกันความเสียหาย 500 หน่วย เมื่อเข้าสู่แดน PvP" },
        }
    }
}

-- คัมภีร์ตำรับโอสถโบราณฉบับปฐมบท (Beginner Alchemy Treatise)
GameConfig.AlchemyTreatise = [[
📜 [คัมภีร์ตำรับโอสถปฐมบทแห่งบรรพชน]
"เตาหลอมเกิดจากจิตวิญญาณ โอสถสวรรค์หามีสูตรตายตัวไม่!
ใส่สมุนไพรสิ่งใดลงไป พลังแห่งตัวยาย่อมหลอมรวมตามสิ่งนั้น
ทว่าความบริสุทธิ์และระดับของเม็ดยา ล้วนขึ้นอยู่กับ 4 ขั้นตอน:
1. การเลือกส่วนผสม: สมุนไพรล้ำค่าให้ฤทธิ์ยาเข้มข้น
2. การจุดไฟ & เลี้ยงเปลวเพลิง: คุมไฟให้อยู่ในโซนทองคำ มิต่ำไปมิสูงไป
3. การกวนประสานเนื้อยา: รักษาสมดุลไม้พายมิให้ปราณกระจายตัว
4. การส่งลมปราณตามจังหวะ: ถ่ายทอดปราณแท้ในชั่วพริบตาแห่งความสมบูรณ์!

หากทำได้ไร้ที่ติ โอสถจักเลื่อนระดับสู่ 'ระดับสมบูรณ์แบบ' 
ส่งผลให้ตบะและโอกาสทะลวงขอบเขตพุ่งทะยานสูงสุด!"
]]

-- ระดับคุณภาพของยาโอสถที่ได้จากการปรุง
GameConfig.PillQualityTiers = {
    {Name = "ระดับล่าง", Multiplier = 0.7, Color = Color3.fromRGB(160, 160, 160)},
    {Name = "ระดับกลาง", Multiplier = 1.0, Color = Color3.fromRGB(85, 255, 127)},
    {Name = "ระดับสูง", Multiplier = 1.4, Color = Color3.fromRGB(85, 170, 255)},
    {Name = "ระดับสมบูรณ์แบบ", Multiplier = 2.0, Color = Color3.fromRGB(255, 215, 0)}
}

-- ตำรับยาสำเร็จรูปมาตรฐาน (Standard Recipes - ไว้ใช้อ้างอิงหรือเสกผ่าน Admin)
GameConfig.Pills = {
    ["เม็ดยารวบรวมลมปราณ"] = {
        Name = "เม็ดยารวบรวมลมปราณ",
        Rarity = "Common",
        Color = Color3.fromRGB(85, 255, 127),
        Description = "ช่วยควบแน่นปราณ เพิ่มตบะ +300 แต้ม และเพิ่มโอกาสทะลวงขอบเขต +20%",
        TapasyaBonus = 300,
        BreakthroughBonus = 0.20,
    },
    ["เม็ดยาทะลวงชีพจร"] = {
        Name = "เม็ดยาทะลวงชีพจร",
        Rarity = "Rare",
        Color = Color3.fromRGB(85, 170, 255),
        Description = "ชำระไขกระดูกและทะลวงจุดชีพจร เพิ่มตบะ +1,000 แต้ม และเพิ่มโอกาสทะลวงขอบเขต +35%",
        TapasyaBonus = 1000,
        BreakthroughBonus = 0.35,
    },
    ["เม็ดยาแก่นทองคำ"] = {
        Name = "เม็ดยาแก่นทองคำ",
        Rarity = "Epic",
        Color = Color3.fromRGB(255, 170, 0),
        Description = "ยาโอสถล้ำค่า ช่วยป้องกันธาตุไฟเข้าแทรก เพิ่มตบะ +3,000 แต้ม และเพิ่มโอกาสทะลวงขอบเขต +50%",
        TapasyaBonus = 3000,
        BreakthroughBonus = 0.50,
    },
    ["เม็ดยาสัจธรรมเทวะ"] = {
        Name = "เม็ดยาสัจธรรมเทวะ",
        Rarity = "Legendary",
        Color = Color3.fromRGB(255, 85, 255),
        Description = "โอสถระดับเทพจุติ พลังฟ้าดินบริสุทธิ์ เพิ่มตบะ +10,000 แต้ม และการันตีทะลวงขอบเขตสำเร็จ 100%!",
        TapasyaBonus = 10000,
        BreakthroughBonus = 1.00,
    }
}

-- อัตราการได้รับตบะพื้นฐาน
GameConfig.AfkInterval = 1 -- ทุกๆ กี่วินาที

-- รายชื่อ Admin ถาวร
GameConfig.SuperAdmins = {
    [1] = true,
}

return GameConfig
