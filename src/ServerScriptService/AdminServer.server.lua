--[[
    AdminServer.server.lua
    เซิร์ฟเวอร์สคริปต์หลักสำหรับระบบผู้พัฒนาและคอนโซลแอดมิน
    เชื่อมต่อโดยตรงกับ AdminDevAuthService
]]

local ServerScriptService = game:GetService("ServerScriptService")
local AdminDevAuthService = require(ServerScriptService:WaitForChild("Services"):WaitForChild("AdminDevAuthService"))

print("✅ [Server] AdminServer & AdminDevAuthService พร้อมทำงาน (ระบบ Dev Authentication ทำงานสมบูรณ์)")
