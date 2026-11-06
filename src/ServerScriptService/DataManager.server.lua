--[[
    DataManager.server.lua
    เซิร์ฟเวอร์สคริปต์จัดการการจัดเก็บข้อมูลและการเก็บเกี่ยวทรัพยากร
    เชื่อมโยงกับ ProfileService (Single Source of Truth)
]]

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")

local NetworkEvents = require(ReplicatedStorage:WaitForChild("Remotes"):WaitForChild("NetworkEvents"))
local HerbDatabase = require(ReplicatedStorage:WaitForChild("SharedModules"):WaitForChild("HerbDatabase"))
local ProfileService = require(ServerScriptService:WaitForChild("Services"):WaitForChild("ProfileService"))

-- Client ขอข้อมูลตั้งต้นเมื่อโหลดเสร็จ
NetworkEvents.RequestInitialData.OnServerEvent:Connect(function(player)
    local profile = ProfileService:GetProfile(player)
    if profile then
        NetworkEvents.UpdateInventory:FireClient(player, profile.Inventory)
        NetworkEvents.SyncDiscoveredPills:FireClient(player, profile.DiscoveredPills)
        NetworkEvents.SyncCultivation:FireClient(player, profile.Cultivation)
    end
end)

-- จัดการการเก็บเกี่ยวสมุนไพรและแก่นธาตุในโลก
NetworkEvents.GatherHerb.OnServerInvoke = function(player, nodePart)
    if not nodePart or not nodePart:IsA("BasePart") then return false, "จุดเก็บเกี่ยวไม่ถูกต้อง" end

    local itemName = nodePart:GetAttribute("HerbName") or nodePart:GetAttribute("ItemName")
    if not itemName then return false, "ไม่พบชื่อไอเทม" end

    -- ตรวจสอบระยะห่าง (Anti-Cheat Distance Check)
    local char = player.Character
    local root = char and char:FindFirstChild("HumanoidRootPart")
    if root then
        local distance = (root.Position - nodePart.Position).Magnitude
        if distance > 22 then
            return false, "ระยะห่างเกินขอบเขตการเก็บเกี่ยว"
        end
    end

    -- ลบ Node ออกจากโลกชั่วคราว
    nodePart:Destroy()

    -- เพิ่มไอเทมเข้ากระเป๋าใน ProfileService
    ProfileService:AddItem(player, itemName, 1)

    print(string.format("🌿 [Gathering] %s เก็บเกี่ยว '%s' สำเร็จ", player.Name, itemName))
    return true, "เก็บเกี่ยว " .. itemName .. " สำเร็จ"
end

print("✅ [Server] DataManager & ProfileService ทำงานสมบูรณ์ (Single Source of Truth Ready)")
