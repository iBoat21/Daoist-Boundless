--[[
    CultivationServer.server.lua
    เซิร์ฟเวอร์สคริปต์หลักสำหรับระบบบำเพ็ญเพียร, การนั่งสมาธิ (Meditation), และวงจรชีวิตพิธีทะลวงขั้น
    ตามสถาปัตยกรรม Genesis of the Myriad Gods: Daoist Boundless (Core System MVP)
]]

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")

local CultivationConfig = require(ReplicatedStorage:WaitForChild("SharedModules"):WaitForChild("CultivationConfig"))
local NetworkEvents = require(ReplicatedStorage:WaitForChild("Remotes"):WaitForChild("NetworkEvents"))

-- โหลด Services หัวใจหลัก
local ProfileService = require(ServerScriptService:WaitForChild("Services"):WaitForChild("ProfileService"))
local CultivationService = require(ServerScriptService:WaitForChild("Services"):WaitForChild("CultivationService"))
local BreakthroughService = require(ServerScriptService:WaitForChild("Services"):WaitForChild("BreakthroughService"))
local TrialService = require(ServerScriptService:WaitForChild("Services"):WaitForChild("TrialService"))
local RewardService = require(ServerScriptService:WaitForChild("Services"):WaitForChild("RewardService"))

-- จัดการการเกิดของตัวละคร (Character Added)
local function onCharacterAdded(player, character)
    local profile = ProfileService:GetProfile(player)
    if profile and profile.Cultivation then
        local realm = CultivationConfig.Realms[profile.Cultivation.RealmLevel or 1]
        if realm then
            RewardService:ApplyRealmStats(player, realm)
        end
    end
end

Players.PlayerAdded:Connect(function(player)
    player.CharacterAdded:Connect(function(char)
        onCharacterAdded(player, char)
    end)
    if player.Character then
        onCharacterAdded(player, player.Character)
    end
end)

for _, player in ipairs(Players:GetPlayers()) do
    if player.Character then
        task.spawn(onCharacterAdded, player, player.Character)
    end
end

print("✅ [Server] CultivationServer, CultivationService, และ BreakthroughService พร้อมทำงานสมบูรณ์!")
