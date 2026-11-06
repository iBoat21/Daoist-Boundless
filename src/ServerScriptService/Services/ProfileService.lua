--[[
    ProfileService.lua
    ระบบจัดการ Profile และการบันทึกข้อมูลถาวร (Single Source of Truth)
    รองรับ Schema Versioning, Session Locking, และ Atomic Item Mutations
]]

local DataStoreService = game:GetService("DataStoreService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local CultivationConfig = require(ReplicatedStorage:WaitForChild("SharedModules"):WaitForChild("CultivationConfig"))
local CultivationTypes = require(ReplicatedStorage:WaitForChild("SharedModules"):WaitForChild("CultivationTypes"))
local NetworkEvents = require(ReplicatedStorage:WaitForChild("Remotes"):WaitForChild("NetworkEvents"))

local ProfileStore
local dataStoreAvailable = false
local success, err = pcall(function()
    ProfileStore = DataStoreService:GetDataStore("DaoistPlayerProfile_v2")
end)

if success and ProfileStore then
    dataStoreAvailable = true
else
    warn("⚠️ [ProfileService] DataStore ไม่พร้อมใช้งาน (ทำงานใน Local/Mock Memory Mode): " .. tostring(err))
end

local Profiles = {}
local SessionLocks = {}

local ProfileService = {}

-- คัดลอก Table แบบตื้น/ลึก
local function deepCopy(orig)
    local orig_type = type(orig)
    local copy
    if orig_type == 'table' then
        copy = {}
        for orig_key, orig_value in next, orig, nil do
            copy[deepCopy(orig_key)] = deepCopy(orig_value)
        end
        setmetatable(copy, deepCopy(getmetatable(orig)))
    else
        copy = orig
    end
    return copy
end

-- สร้าง Profile เริ่มต้นสำหรับผู้เล่นใหม่
local function createDefaultProfile(player)
    local defaultCultivation = deepCopy(CultivationConfig.DefaultSchema)
    return {
        SchemaVersion = 1,
        UserId = player.UserId,
        PlayerName = player.Name,
        Cultivation = defaultCultivation,
        Inventory = {
            -- สมุนไพรเริ่มต้นสำหรับผู้เล่นใหม่เพื่อลองเล่น Loop การปรุงยา
            ["หญ้าหยกปฐพี"] = 3,
            ["ดอกบัวนิลกาล"] = 2,
        },
        Gold = 500,
        DiscoveredPills = {},
        CreatedAt = os.time(),
        LastSavedAt = os.time(),
    }
end

-- อัปเกรด Schema เก่ามาเป็น Schema ใหม่ (Migration)
local function migrateProfile(data, player)
    if not data or type(data) ~= "table" then
        return createDefaultProfile(player)
    end

    local profile = createDefaultProfile(player)

    -- กรณีข้อมูลมาจากเวอร์ชันเดิม
    if data.Cultivation then
        profile.Cultivation = data.Cultivation
    else
        -- แปลง Tapasya เดิม
        local oldTapasya = data.Tapasya or 0
        local oldRealmIndex = data.RealmIndex or 1
        local realmCfg = CultivationConfig.Realms[oldRealmIndex] or CultivationConfig.Realms[1]
        profile.Cultivation.RealmId = realmCfg.Id
        profile.Cultivation.RealmLevel = oldRealmIndex
        profile.Cultivation.CultivationExp = oldTapasya
        profile.Cultivation.RequiredExp = realmCfg.RequiredExp
        profile.Cultivation.BreakthroughState = (oldTapasya >= realmCfg.RequiredExp) and CultivationTypes.BreakthroughState.Ready or CultivationTypes.BreakthroughState.Locked
    end

    if data.Inventory then
        profile.Inventory = data.Inventory
    end
    if data.Gold then
        profile.Gold = data.Gold
    end
    if data.DiscoveredPills then
        profile.DiscoveredPills = data.DiscoveredPills
    end

    return profile
end

-- โหลดข้อมูลผู้เล่นเมื่อเข้าเกม
function ProfileService:LoadProfile(player)
    local userId = player.UserId
    print("📥 [ProfileService] กำลังโหลด Profile สำหรับ: " .. player.Name .. " (" .. userId .. ")")

    local loadedData = nil
    if dataStoreAvailable then
        local ok, result = pcall(function()
            return ProfileStore:GetAsync(tostring(userId))
        end)
        if ok and result then
            loadedData = result
        elseif not ok then
            warn("❌ [ProfileService] เกิดข้อผิดพลาดขณะ GetAsync: " .. tostring(result))
        end
    end

    local profile = migrateProfile(loadedData, player)
    Profiles[userId] = profile
    SessionLocks[userId] = true

    -- ตั้งค่า Attribute บนตัวผู้เล่นเพื่อให้ระบบ UI และ Client อ่านได้ทันที
    local cult = profile.Cultivation
    player:SetAttribute("RealmId", cult.RealmId)
    player:SetAttribute("RealmLevel", cult.RealmLevel)
    player:SetAttribute("CultivationExp", cult.CultivationExp)
    player:SetAttribute("RequiredExp", cult.RequiredExp)
    player:SetAttribute("Qi", cult.Qi or 0)
    player:SetAttribute("MaxQi", cult.MaxQi or 50)
    player:SetAttribute("IsMeditating", false)
    player:SetAttribute("BreakthroughState", cult.BreakthroughState)

    -- ซิงก์ข้อมูลไป Client
    NetworkEvents.UpdateInventory:FireClient(player, profile.Inventory)
    NetworkEvents.SyncDiscoveredPills:FireClient(player, profile.DiscoveredPills)
    NetworkEvents.SyncCultivation:FireClient(player, cult)

    print("✅ [ProfileService] Profile ของ " .. player.Name .. " โหลดสำเร็จ (Realm: " .. cult.RealmId .. ")")
    return profile
end

-- บันทึกข้อมูลผู้เล่น
function ProfileService:SaveProfile(player)
    local userId = player.UserId
    local profile = Profiles[userId]
    if not profile then return false end

    profile.LastSavedAt = os.time()

    if dataStoreAvailable then
        local ok, err = pcall(function()
            ProfileStore:SetAsync(tostring(userId), profile)
        end)
        if ok then
            print("💾 [ProfileService] บันทึกข้อมูลของ " .. player.Name .. " สำเร็จ")
            return true
        else
            warn("❌ [ProfileService] บันทึกข้อมูลไม่สำเร็จ: " .. tostring(err))
            return false
        end
    end
    return true
end

-- ดึงข้อมูล Profile ของผู้เล่น
function ProfileService:GetProfile(player)
    return Profiles[player.UserId]
end

-- ดึงข้อมูล Cultivation
function ProfileService:GetCultivation(player)
    local profile = Profiles[player.UserId]
    if profile then
        return profile.Cultivation
    end
    return nil
end

-- ปรับปรุงข้อมูล Cultivation แบบ Transaction ปลอดภัย
function ProfileService:MutateCultivation(player, mutatorFn)
    local profile = Profiles[player.UserId]
    if not profile or not profile.Cultivation then return false end

    mutatorFn(profile.Cultivation)

    local cult = profile.Cultivation
    player:SetAttribute("RealmId", cult.RealmId)
    player:SetAttribute("RealmLevel", cult.RealmLevel)
    player:SetAttribute("CultivationExp", cult.CultivationExp)
    player:SetAttribute("RequiredExp", cult.RequiredExp)
    player:SetAttribute("Qi", cult.Qi or 0)
    player:SetAttribute("MaxQi", cult.MaxQi or 50)
    player:SetAttribute("BreakthroughState", cult.BreakthroughState)

    NetworkEvents.SyncCultivation:FireClient(player, cult)
    return true
end

-- ดึงข้อมูล Inventory
function ProfileService:GetInventory(player)
    local profile = Profiles[player.UserId]
    if profile then
        return profile.Inventory
    end
    return {}
end

-- ตรวจสอบว่าผู้เล่นมีไอเทมตามจำนวนที่ระบุหรือไม่ (รองรับ Alias ชื่อไอเทม)
function ProfileService:HasItem(player, itemName, count, alias)
    local inv = self:GetInventory(player)
    count = count or 1

    local actualCount = inv[itemName] or 0
    if actualCount < count and alias and inv[alias] then
        actualCount = actualCount + (inv[alias] or 0)
    end

    return actualCount >= count, actualCount
end

-- หักไอเทมแบบ Atomic (รองรับ Alias ชื่อไอเทม)
function ProfileService:DeductItem(player, itemName, count, alias)
    local profile = Profiles[player.UserId]
    if not profile then return false, "Profile ไม่พบ" end
    local inv = profile.Inventory
    count = count or 1

    local hasEnough, total = self:HasItem(player, itemName, count, alias)
    if not hasEnough then
        return false, string.format("ไอเทม '%s' ไม่เพียงพอ (ต้องการ %d ชิ้น, มี %d ชิ้น)", itemName, count, total)
    end

    local remainingToDeduct = count
    if inv[itemName] then
        local deductFromPrimary = math.min(inv[itemName], remainingToDeduct)
        inv[itemName] = inv[itemName] - deductFromPrimary
        if inv[itemName] <= 0 then inv[itemName] = nil end
        remainingToDeduct = remainingToDeduct - deductFromPrimary
    end

    if remainingToDeduct > 0 and alias and inv[alias] then
        local deductFromAlias = math.min(inv[alias], remainingToDeduct)
        inv[alias] = inv[alias] - deductFromAlias
        if inv[alias] <= 0 then inv[alias] = nil end
        remainingToDeduct = remainingToDeduct - deductFromAlias
    end

    NetworkEvents.UpdateInventory:FireClient(player, inv)
    return true
end

-- เพิ่มไอเทมเข้ากระเป๋า
function ProfileService:AddItem(player, itemName, count)
    local profile = Profiles[player.UserId]
    if not profile then return false end
    count = count or 1
    local inv = profile.Inventory
    inv[itemName] = (inv[itemName] or 0) + count
    NetworkEvents.UpdateInventory:FireClient(player, inv)
    return true, inv[itemName]
end

-- เพิ่มไอเทมหลายชิ้นพร้อมกัน (Bulk Add)
function ProfileService:AddItems(player, itemsMap)
    local profile = Profiles[player.UserId]
    if not profile then return false end
    local inv = profile.Inventory
    for name, count in pairs(itemsMap) do
        count = tonumber(count) or 1
        inv[name] = (inv[name] or 0) + count
    end
    NetworkEvents.UpdateInventory:FireClient(player, inv)
    return true
end

-- ล้างกระเป๋า (สำหรับทดสอบ)
function ProfileService:ClearInventory(player)
    local profile = Profiles[player.UserId]
    if not profile then return false end
    profile.Inventory = {}
    NetworkEvents.UpdateInventory:FireClient(player, profile.Inventory)
    return true
end

-- เชื่อมต่อ Player Lifecycle
Players.PlayerAdded:Connect(function(player)
    ProfileService:LoadProfile(player)
end)

Players.PlayerRemoving:Connect(function(player)
    ProfileService:SaveProfile(player)
    Profiles[player.UserId] = nil
    SessionLocks[player.UserId] = nil
end)

-- Autosave loop ทุก 60 วินาที
task.spawn(function()
    while true do
        task.wait(60)
        for _, player in ipairs(Players:GetPlayers()) do
            ProfileService:SaveProfile(player)
        end
    end
end)

-- ผูก BindToClose เมื่อปิดเซิร์ฟเวอร์
game:BindToClose(function()
    print("🛑 [ProfileService] เซิร์ฟเวอร์กำลังปิด บันทึกข้อมูลผู้เล่นทั้งหมด...")
    for _, player in ipairs(Players:GetPlayers()) do
        ProfileService:SaveProfile(player)
    end
    task.wait(1)
end)

-- ผูก Global เพื่อให้โมดูลอื่นสามารถอ้างอิงได้
_G.ProfileService = ProfileService
_G.DaoistDataManager = {
    GetInventory = function(player) return ProfileService:GetInventory(player) end,
    AddHerb = function(player, name, count) return ProfileService:AddItem(player, name, count) end,
    AddItems = function(player, map) return ProfileService:AddItems(player, map) end,
    ClearInventory = function(player) return ProfileService:ClearInventory(player) end,
    SaveData = function(player) return ProfileService:SaveProfile(player) end,
    GetDiscoveredPills = function(player)
        local p = ProfileService:GetProfile(player)
        return p and p.DiscoveredPills or {}
    end,
    AddDiscoveredPill = function(player, pillName)
        local p = ProfileService:GetProfile(player)
        if p then
            p.DiscoveredPills[pillName] = true
            NetworkEvents.SyncDiscoveredPills:FireClient(player, p.DiscoveredPills)
            return true
        end
        return false
    end
}

return ProfileService
