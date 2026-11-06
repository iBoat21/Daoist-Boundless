--[[
    AdminDevAuthService.lua
    ระบบยืนยันตัวตนผู้พัฒนา (Dev Authentication) และคอนโซลคำสั่งทดสอบระบบ (Dev Testing Suite)
    - ป้องกันไม่ให้ผู้เล่นทั่วไปเข้าถึง Admin Panel จนกว่าจะป้อน User/Password ที่ถูกต้อง
    - มีฟังก์ชันอำนวยความสะดวกสำหรับ Dev ในการทดสอบ Trial 1, Trial 2, การเสกของ, และการต่อสู้
]]

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")

local CultivationConfig = require(ReplicatedStorage:WaitForChild("SharedModules"):WaitForChild("CultivationConfig"))
local CultivationTypes = require(ReplicatedStorage:WaitForChild("SharedModules"):WaitForChild("CultivationTypes"))
local NetworkEvents = require(ReplicatedStorage:WaitForChild("Remotes"):WaitForChild("NetworkEvents"))
local HerbDatabase = require(ReplicatedStorage:WaitForChild("SharedModules"):WaitForChild("HerbDatabase"))
local PillDatabase = require(ReplicatedStorage:WaitForChild("SharedModules"):WaitForChild("PillDatabase"))

local ProfileService = require(script.Parent:WaitForChild("ProfileService"))
local BreakthroughService = require(script.Parent:WaitForChild("BreakthroughService"))
local CombatManager = require(ServerScriptService:WaitForChild("CombatManager"))

-- รหัสผ่านผู้พัฒนาสำหรับเข้าสู่โหมด Dev (สามารถเปลี่ยนได้)
local DEV_CREDENTIALS = {
    Username = "dev",
    Password = "daoist2026",
    -- บัญชีสำรอง
    BackupUser = "admin",
    BackupPass = "gods2026"
}

local AuthenticatedDevs = {}

local AdminDevAuthService = {}

-- ตรวจสอบสิทธิ์ Dev ของผู้เล่น
function AdminDevAuthService:IsDev(player)
    return AuthenticatedDevs[player.UserId] == true
end

-- ดำเนินการล็อกอิน Dev
function AdminDevAuthService:Authenticate(player, username, password)
    username = string.lower(string.gsub(tostring(username or ""), "^%s*(.-)%s*$", "%1"))
    password = string.gsub(tostring(password or ""), "^%s*(.-)%s*$", "%1")

    local isValid = (username == DEV_CREDENTIALS.Username and password == DEV_CREDENTIALS.Password)
        or (username == DEV_CREDENTIALS.BackupUser and password == DEV_CREDENTIALS.BackupPass)

    if isValid then
        AuthenticatedDevs[player.UserId] = true
        player:SetAttribute("IsDevAuthenticated", true)
        print(string.format("🔑 [AdminDevAuth] ผู้เล่น '%s' (%d) ยืนยันตัวตน Dev สำเร็จ!", player.Name, player.UserId))
        NetworkEvents.AdminStatusChanged:FireClient(player, true)
        return true, "ยืนยันตัวตนสำเร็จ! ปลดล็อก Dev Testing Suite และ Admin Panel เรียบร้อยแล้ว"
    else
        warn(string.format("⚠️ [AdminDevAuth] ผู้เล่น '%s' พยายามล็อกอิน Dev แต่รหัสผ่านไม่ถูกต้อง", player.Name))
        return false, "ชื่อผู้ใช้หรือรหัสผ่านผู้พัฒนาไม่ถูกต้อง (กรุณาตรวจสอบสเปก MVP)"
    end
end

-- ประมวลผลคำสั่ง Dev
function AdminDevAuthService:ExecuteCommand(player, cmdText)
    if not self:IsDev(player) then
        return false, "⛔ ปฏิเสธการเข้าถึง: ต้องยืนยันตัวตน Dev ก่อนใช้งานคำสั่งนี้"
    end

    local tokens = {}
    for word in string.gmatch(cmdText, "%S+") do
        table.insert(tokens, word)
    end

    if #tokens == 0 then return false, "กรุณาระบุคำสั่ง" end
    local cmd = string.lower(tokens[1])

    -- 1. ทดสอบ Trial 1: ครรภ์เซียน
    if cmd == "testtrial1" or cmd == "trial1" then
        ProfileService:AddItem(player, "โอสถเบิกวิญญาณ", 1)
        ProfileService:MutateCultivation(player, function(cult)
            cult.RealmId = "SpiritEmbryo"
            cult.RealmLevel = 1
            cult.CultivationExp = 1000
            cult.RequiredExp = 1000
            cult.BreakthroughState = CultivationTypes.BreakthroughState.Ready
        end)
        return true, "⚡ [Dev Mode] ตั้งค่าพร้อมทดสอบ Trial 1: เสกโอสถเบิกวิญญาณ + ตบะเต็ม 1000/1000 (สถานะ: Ready)"

    -- 2. ทดสอบ Trial 2: เบญจธาตุ
    elseif cmd == "testtrial2" or cmd == "trial2" then
        ProfileService:AddItems(player, {
            ["แก่นปฐพี"] = 1,
            ["แก่นโลหะ"] = 1,
            ["แก่นวารี"] = 1,
            ["แก่นพฤกษา"] = 1,
            ["แก่นอัคคี"] = 1,
        })
        ProfileService:MutateCultivation(player, function(cult)
            cult.RealmId = "FiveElements"
            cult.RealmLevel = 2
            cult.CultivationExp = 2500
            cult.RequiredExp = 2500
            cult.BreakthroughState = CultivationTypes.BreakthroughState.Ready
        end)
        return true, "⚡ [Dev Mode] ตั้งค่าพร้อมทดสอบ Trial 2: เสกแก่น 5 ธาตุครบถ้วน + ตบะเต็ม 2500/2500 (สถานะ: Ready)"

    -- 3. ทะลวงขั้นด่วนแบบไม่ผ่านมินิเกม
    elseif cmd == "fastbreakthrough" or cmd == "forcebreak" then
        local cult = ProfileService:GetCultivation(player)
        local nextLevel = (cult.RealmLevel or 1) + 1
        local nextRealm = CultivationConfig.Realms[nextLevel]
        if not nextRealm then
            return false, "บรรลุขอบเขตสูงสุดแล้ว"
        end
        BreakthroughService:CommitBreakthrough(player, nextRealm)
        return true, "⚡ [Dev Mode] บังคับทะลวงขั้นสู่: " .. nextRealm.Name .. " สำเร็จ!"

    -- 4. เสกดัมมี่ซ้อมดาเมจ
    elseif cmd == "spawndummy" or cmd == "dummy" then
        local hp = tonumber(tokens[2]) or 1000
        local char = player.Character
        local pos = char and char.PrimaryPart and (char.PrimaryPart.Position + char.PrimaryPart.CFrame.LookVector * 10) or Vector3.new(0, 10, 0)
        local dummy = CombatManager:SpawnDummy(pos, hp)
        if dummy then
            return true, string.format("🎯 [Dev Mode] เสกดัมมี่ซ้อมดาเมจเรียบร้อย (HP: %d)", hp)
        else
            return false, "ไม่สามารถสร้างดัมมี่ได้"
        end

    -- 5. ล้างดัมมี่
    elseif cmd == "cleardummies" then
        CombatManager:ClearDummies()
        return true, "🧹 [Dev Mode] ล้างดัมมี่ซ้อมดาเมจทั้งหมดในแผนที่แล้ว"

    -- 6. เสกสมุนไพรทั้งหมด 100 ชนิด
    elseif cmd == "giveallherbs" then
        local items = {}
        for _, herb in ipairs(HerbDatabase.List or {}) do
            items[herb.Name] = 10
        end
        ProfileService:AddItems(player, items)
        return true, "🌿 [Dev Mode] เสกสมุนไพรทั้ง 100 ชนิด ชนิดละ 10 ต้นลงกระเป๋าเรียบร้อย!"

    -- 7. เสกโอสถทั้งหมด 50 ขนาน
    elseif cmd == "giveallpills" then
        local items = {}
        for _, pill in ipairs(PillDatabase.GetAll and PillDatabase.GetAll() or PillDatabase.List or {}) do
            items[pill.Name] = 5
        end
        ProfileService:AddItems(player, items)
        return true, "💊 [Dev Mode] เสกโอสถทั้ง 50 ขนาน ขนานละ 5 เม็ดลงกระเป๋าเรียบร้อย!"

    -- 8. เติมเงินตำลึง
    elseif cmd == "setgold" then
        local amount = tonumber(tokens[2]) or 99999
        local profile = ProfileService:GetProfile(player)
        if profile then
            profile.Gold = amount
            return true, "💰 [Dev Mode] ปรับจำนวนเงินตำลึงเป็น: " .. amount
        end

    -- 9. โหมดอมตะ / วิ่งเร็ว
    elseif cmd == "god" or cmd == "godmode" then
        local char = player.Character
        local hum = char and char:FindFirstChildOfClass("Humanoid")
        if hum then
            hum.MaxHealth = 999999
            hum.Health = 999999
            player:SetAttribute("MaxQi", 9999)
            player:SetAttribute("Chi", 9999)
            return true, "🛡️ [Dev Mode] เปิดโหมดอมตะ (Godmode) เลือด/ปราณเต็มพิกัด!"
        end

    elseif cmd == "speed" then
        local spd = tonumber(tokens[2]) or 32
        local char = player.Character
        local hum = char and char:FindFirstChildOfClass("Humanoid")
        if hum then
            hum.WalkSpeed = spd
            return true, "🏃 [Dev Mode] ปรับความเร็วการวิ่งเป็น: " .. spd
        end

    else
        return false, "ไม่พบคำสั่งที่ระบุ กรุณาใช้ปุ่มด่วนบนหน้าต่าง Dev Testing Panel"
    end

    return true, "คำสั่งดำเนินการเรียบร้อย"
end

-- ผูก Remotes
NetworkEvents.DevLogin.OnServerInvoke = function(player, username, password)
    return AdminDevAuthService:Authenticate(player, username, password)
end

NetworkEvents.CheckDevAuth.OnServerInvoke = function(player)
    return AdminDevAuthService:IsDev(player)
end

NetworkEvents.AdminCommand.OnServerInvoke = function(player, cmdText)
    return AdminDevAuthService:ExecuteCommand(player, cmdText)
end

-- รองรับคำสั่งผ่าน Chat: /devauth <user> <pass>
Players.PlayerAdded:Connect(function(player)
    player.Chatted:Connect(function(msg)
        local words = {}
        for w in string.gmatch(msg, "%S+") do
            table.insert(words, w)
        end
        if #words >= 3 and (words[1] == "/devauth" or words[1] == "/login" or words[1] == "!dev") then
            local u = words[2]
            local p = words[3]
            local ok, resp = AdminDevAuthService:Authenticate(player, u, p)
            print(string.format("💬 Chat DevAuth [%s]: %s", player.Name, resp))
        end
    end)
end)

_G.AdminDevAuthService = AdminDevAuthService
return AdminDevAuthService
