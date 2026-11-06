--[[
    DevLoginUI.client.lua
    ระบบยืนยันตัวตนผู้พัฒนา (Dev Authentication) และศูนย์ควบคุมการทดสอบระบบ (Dev Testing Suite)
    - ต้องกรอก Username & Password ถูกต้องจึงจะปลดล็อก Admin Panel
    - มีปุ่มทางลัดสำหรับทดสอบ Trial 1 (ครรภ์เซียน) และ Trial 2 (เบญจธาตุ) ได้ทันที
]]

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local UserInputService = game:GetService("UserInputService")
local TweenService = game:GetService("TweenService")

local localPlayer = Players.LocalPlayer
local playerGui = localPlayer:WaitForChild("PlayerGui")

local NetworkEvents = require(ReplicatedStorage:WaitForChild("Remotes"):WaitForChild("NetworkEvents"))
local UIManager = require(ReplicatedStorage:WaitForChild("SharedModules"):WaitForChild("UIManager"))

-- สร้าง ScreenGui
local screenGui = Instance.new("ScreenGui")
screenGui.Name = "DevSuiteGui"
screenGui.ResetOnSpawn = false
screenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
screenGui.Parent = playerGui

local isAuthenticated = false

--------------------------------------------------------------------------------
-- 1. ปุ่มลอยเปิดโหมด Dev ที่มุมขวาบน (Floating Dev Mode Button)
--------------------------------------------------------------------------------
local devHudBtn = Instance.new("TextButton")
devHudBtn.Name = "DevHudButton"
devHudBtn.Size = UDim2.new(0, 115, 0, 36)
devHudBtn.Position = UDim2.new(1, -125, 0, 12)
devHudBtn.BackgroundColor3 = Color3.fromRGB(35, 40, 52)
devHudBtn.Text = "⚙️ Dev Mode (F2)"
devHudBtn.TextColor3 = Color3.fromRGB(255, 215, 90)
devHudBtn.Font = Enum.Font.GothamBold
devHudBtn.TextSize = 13
devHudBtn.Parent = screenGui

local devHudCorner = Instance.new("UICorner")
devHudCorner.CornerRadius = UDim.new(0, 8)
devHudCorner.Parent = devHudBtn

local devHudStroke = Instance.new("UIStroke")
devHudStroke.Thickness = 1.5
devHudStroke.Color = Color3.fromRGB(255, 215, 90)
devHudStroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
devHudStroke.Parent = devHudBtn

--------------------------------------------------------------------------------
-- 2. หน้าต่างป้อนรหัสผ่านผู้พัฒนา (Dev Authentication Modal)
--------------------------------------------------------------------------------
local loginModal = Instance.new("Frame")
loginModal.Name = "DevLoginModal"
loginModal.Size = UDim2.new(0, 420, 0, 320)
loginModal.Position = UDim2.new(0.5, -210, 0.5, -160)
loginModal.BackgroundColor3 = Color3.fromRGB(20, 23, 30)
loginModal.BorderSizePixel = 0
loginModal.Visible = false
loginModal.Parent = screenGui

local loginCorner = Instance.new("UICorner")
loginCorner.CornerRadius = UDim.new(0, 14)
loginCorner.Parent = loginModal

local loginStroke = Instance.new("UIStroke")
loginStroke.Thickness = 2
loginStroke.Color = Color3.fromRGB(255, 200, 70)
loginStroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
loginStroke.Parent = loginModal

local loginHeader = Instance.new("TextLabel")
loginHeader.Size = UDim2.new(1, 0, 0, 45)
loginHeader.BackgroundTransparency = 1
loginHeader.Text = "🔒 ผู้ทดสอบระบบ (Dev Authentication)"
loginHeader.TextColor3 = Color3.fromRGB(255, 220, 90)
loginHeader.Font = Enum.Font.GothamBold
loginHeader.TextSize = 17
loginHeader.Parent = loginModal

local loginSub = Instance.new("TextLabel")
loginSub.Size = UDim2.new(1, -40, 0, 35)
loginSub.Position = UDim2.new(0, 20, 0, 45)
loginSub.BackgroundTransparency = 1
loginSub.Text = "กรุณากรอก Username และ Password ของผู้พัฒนา เพื่อเปิดใช้งานระบบทดลองก่อนผู้เล่นปกติ"
loginSub.TextColor3 = Color3.fromRGB(200, 205, 220)
loginSub.Font = Enum.Font.Gotham
loginSub.TextSize = 12
loginSub.TextWrapped = true
loginSub.Parent = loginModal

-- กล่องกรอก Username
local userInput = Instance.new("TextBox")
userInput.Name = "UserInput"
userInput.Size = UDim2.new(1, -40, 0, 40)
userInput.Position = UDim2.new(0, 20, 0, 95)
userInput.BackgroundColor3 = Color3.fromRGB(32, 36, 48)
userInput.PlaceholderText = "Username (เช่น dev)"
userInput.PlaceholderColor3 = Color3.fromRGB(130, 140, 160)
userInput.Text = ""
userInput.TextColor3 = Color3.fromRGB(255, 255, 255)
userInput.Font = Enum.Font.Gotham
userInput.TextSize = 14
userInput.ClearTextOnFocus = false
userInput.Parent = loginModal

local userCorner = Instance.new("UICorner")
userCorner.CornerRadius = UDim.new(0, 8)
userCorner.Parent = userInput

-- กล่องกรอก Password
local passInput = Instance.new("TextBox")
passInput.Name = "PassInput"
passInput.Size = UDim2.new(1, -40, 0, 40)
passInput.Position = UDim2.new(0, 20, 0, 145)
passInput.BackgroundColor3 = Color3.fromRGB(32, 36, 48)
passInput.PlaceholderText = "Password (เช่น daoist2026)"
passInput.PlaceholderColor3 = Color3.fromRGB(130, 140, 160)
passInput.Text = ""
passInput.TextColor3 = Color3.fromRGB(255, 255, 255)
passInput.Font = Enum.Font.Gotham
passInput.TextSize = 14
passInput.ClearTextOnFocus = false
passInput.Parent = loginModal

local passCorner = Instance.new("UICorner")
passCorner.CornerRadius = UDim.new(0, 8)
passCorner.Parent = passInput

local loginStatus = Instance.new("TextLabel")
loginStatus.Name = "LoginStatus"
loginStatus.Size = UDim2.new(1, -40, 0, 25)
loginStatus.Position = UDim2.new(0, 20, 0, 195)
loginStatus.BackgroundTransparency = 1
loginStatus.Text = ""
loginStatus.TextColor3 = Color3.fromRGB(255, 100, 100)
loginStatus.Font = Enum.Font.Gotham
loginStatus.TextSize = 12
loginStatus.Parent = loginModal

local submitLoginBtn = Instance.new("TextButton")
submitLoginBtn.Name = "SubmitLoginBtn"
submitLoginBtn.Size = UDim2.new(1, -40, 0, 44)
submitLoginBtn.Position = UDim2.new(0, 20, 0, 225)
submitLoginBtn.BackgroundColor3 = Color3.fromRGB(45, 160, 95)
submitLoginBtn.Text = "🔑 ยืนยันตัวตน (Dev Login)"
submitLoginBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
submitLoginBtn.Font = Enum.Font.GothamBold
submitLoginBtn.TextSize = 15
submitLoginBtn.Parent = loginModal

local submitCorner = Instance.new("UICorner")
submitCorner.CornerRadius = UDim.new(0, 8)
submitCorner.Parent = submitLoginBtn

local closeLoginBtn = Instance.new("TextButton")
closeLoginBtn.Size = UDim2.new(0, 30, 0, 30)
closeLoginBtn.Position = UDim2.new(1, -38, 0, 8)
closeLoginBtn.BackgroundColor3 = Color3.fromRGB(45, 50, 65)
closeLoginBtn.Text = "✕"
closeLoginBtn.TextColor3 = Color3.fromRGB(200, 200, 200)
closeLoginBtn.Font = Enum.Font.GothamBold
closeLoginBtn.TextSize = 14
closeLoginBtn.Parent = loginModal

local closeLoginCorner = Instance.new("UICorner")
closeLoginCorner.CornerRadius = UDim.new(0, 6)
closeLoginCorner.Parent = closeLoginBtn

--------------------------------------------------------------------------------
-- 3. หน้าต่าง Dev Testing Suite (Admin Panel เมื่อยืนยันตัวตนแล้ว)
--------------------------------------------------------------------------------
local panelFrame = Instance.new("Frame")
panelFrame.Name = "DevTestingPanel"
panelFrame.Size = UDim2.new(0, 580, 0, 520)
panelFrame.Position = UDim2.new(0.5, -290, 0.5, -260)
panelFrame.BackgroundColor3 = Color3.fromRGB(18, 21, 28)
panelFrame.BorderSizePixel = 0
panelFrame.Visible = false
panelFrame.Parent = screenGui

local panelCorner = Instance.new("UICorner")
panelCorner.CornerRadius = UDim.new(0, 16)
panelCorner.Parent = panelFrame

local panelStroke = Instance.new("UIStroke")
panelStroke.Thickness = 2
panelStroke.Color = Color3.fromRGB(90, 200, 255)
panelStroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
panelStroke.Parent = panelFrame

local panelHeader = Instance.new("Frame")
panelHeader.Size = UDim2.new(1, 0, 0, 48)
panelHeader.BackgroundColor3 = Color3.fromRGB(26, 30, 40)
panelHeader.BorderSizePixel = 0
panelHeader.Parent = panelFrame

local panelHeaderCorner = Instance.new("UICorner")
panelHeaderCorner.CornerRadius = UDim.new(0, 16)
panelHeaderCorner.Parent = panelHeader

local panelTitle = Instance.new("TextLabel")
panelTitle.Size = UDim2.new(1, -60, 1, 0)
panelTitle.Position = UDim2.new(0, 20, 0, 0)
panelTitle.BackgroundTransparency = 1
panelTitle.Text = "🛠️ ศูนย์ทดสอบระบบสำหรับผู้พัฒนา (Dev Testing Suite)"
panelTitle.TextColor3 = Color3.fromRGB(120, 220, 255)
panelTitle.Font = Enum.Font.GothamBold
panelTitle.TextSize = 16
panelTitle.TextXAlignment = Enum.TextXAlignment.Left
panelTitle.Parent = panelHeader

local closePanelBtn = Instance.new("TextButton")
closePanelBtn.Size = UDim2.new(0, 32, 0, 32)
closePanelBtn.Position = UDim2.new(1, -40, 0, 8)
closePanelBtn.BackgroundColor3 = Color3.fromRGB(45, 50, 65)
closePanelBtn.Text = "✕"
closePanelBtn.TextColor3 = Color3.fromRGB(200, 200, 200)
closePanelBtn.Font = Enum.Font.GothamBold
closePanelBtn.TextSize = 14
closePanelBtn.Parent = panelHeader

local closePanelCorner = Instance.new("UICorner")
closePanelCorner.CornerRadius = UDim.new(0, 6)
closePanelCorner.Parent = closePanelBtn

-- พื้นที่ปุ่มลัดคำสั่งด่วน (Quick Buttons Grid)
local quickGrid = Instance.new("Frame")
quickGrid.Name = "QuickGrid"
quickGrid.Size = UDim2.new(1, -30, 0, 220)
quickGrid.Position = UDim2.new(0, 15, 0, 58)
quickGrid.BackgroundTransparency = 1
quickGrid.Parent = panelFrame

local gridLayout = Instance.new("UIGridLayout")
gridLayout.CellSize = UDim2.new(0, 175, 0, 48)
gridLayout.CellPadding = UDim2.new(0, 10, 0, 8)
gridLayout.Parent = quickGrid

-- คอนโซลข้อความแสดงผล (Output Console)
local logBox = Instance.new("ScrollingFrame")
logBox.Name = "LogBox"
logBox.Size = UDim2.new(1, -30, 0, 160)
logBox.Position = UDim2.new(0, 15, 0, 290)
logBox.BackgroundColor3 = Color3.fromRGB(10, 12, 16)
logBox.BorderSizePixel = 0
logBox.ScrollBarThickness = 4
logBox.Parent = panelFrame

local logCorner = Instance.new("UICorner")
logCorner.CornerRadius = UDim.new(0, 8)
logCorner.Parent = logBox

local logLabel = Instance.new("TextLabel")
logLabel.Name = "LogLabel"
logLabel.Size = UDim2.new(1, -16, 1, -16)
logLabel.Position = UDim2.new(0, 8, 0, 8)
logLabel.BackgroundTransparency = 1
logLabel.Text = "[Dev Console] ระบบพร้อมรับคำสั่งจากผู้พัฒนา..."
logLabel.TextColor3 = Color3.fromRGB(150, 255, 150)
logLabel.Font = Enum.Font.Code
logLabel.TextSize = 12
logLabel.TextXAlignment = Enum.TextXAlignment.Left
logLabel.TextYAlignment = Enum.TextYAlignment.Top
logLabel.TextWrapped = true
logLabel.Parent = logBox

-- ช่องพิมพ์คำสั่ง Custom
local cmdInput = Instance.new("TextBox")
cmdInput.Name = "CmdInput"
cmdInput.Size = UDim2.new(1, -120, 0, 42)
cmdInput.Position = UDim2.new(0, 15, 1, -52)
cmdInput.BackgroundColor3 = Color3.fromRGB(28, 32, 42)
cmdInput.PlaceholderText = "พิมพ์คำสั่ง (เช่น spawndummy 1000, god, speed 32)..."
cmdInput.PlaceholderColor3 = Color3.fromRGB(120, 130, 150)
cmdInput.Text = ""
cmdInput.TextColor3 = Color3.fromRGB(255, 255, 255)
cmdInput.Font = Enum.Font.Code
cmdInput.TextSize = 13
cmdInput.ClearTextOnFocus = false
cmdInput.Parent = panelFrame

local cmdCorner = Instance.new("UICorner")
cmdCorner.CornerRadius = UDim.new(0, 8)
cmdCorner.Parent = cmdInput

local runCmdBtn = Instance.new("TextButton")
runCmdBtn.Name = "RunCmdBtn"
runCmdBtn.Size = UDim2.new(0, 80, 0, 42)
runCmdBtn.Position = UDim2.new(1, -95, 1, -52)
runCmdBtn.BackgroundColor3 = Color3.fromRGB(30, 120, 210)
runCmdBtn.Text = "ส่งคำสั่ง"
runCmdBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
runCmdBtn.Font = Enum.Font.GothamBold
runCmdBtn.TextSize = 13
runCmdBtn.Parent = panelFrame

local runCorner = Instance.new("UICorner")
runCorner.CornerRadius = UDim.new(0, 8)
runCorner.Parent = runCmdBtn

local function addLog(msg)
    local timestamp = os.date("%X")
    logLabel.Text = logLabel.Text .. "\n[" .. timestamp .. "] " .. tostring(msg)
    logBox.CanvasPosition = Vector2.new(0, 99999)
end

local function executeDevCmd(cmdString)
    local ok, resp = NetworkEvents.AdminCommand:InvokeServer(cmdString)
    if ok then
        addLog(resp or "สำเร็จ")
    else
        addLog("❌ " .. tostring(resp))
    end
end

-- สร้างปุ่ม Quick Action ที่ออกแบบเฉพาะสำหรับ MVP
local quickButtons = {
    { Text = "🧪 ทดสอบ Trial 1 (ครรภ์เซียน)", Cmd = "testtrial1", Color = Color3.fromRGB(50, 140, 90) },
    { Text = "🌀 ทดสอบ Trial 2 (เบญจธาตุ)", Cmd = "testtrial2", Color = Color3.fromRGB(40, 120, 180) },
    { Text = "⚡ บังคับทะลวงขั้น (Fast)", Cmd = "fastbreakthrough", Color = Color3.fromRGB(160, 90, 40) },
    { Text = "🎯 เสกดัมมี่ซ้อมตี (1000 HP)", Cmd = "spawndummy 1000", Color = Color3.fromRGB(150, 50, 50) },
    { Text = "🧹 ล้างดัมมี่ทั้งหมด", Cmd = "cleardummies", Color = Color3.fromRGB(80, 80, 90) },
    { Text = "🌿 เสกสมุนไพร 100 ชนิด", Cmd = "giveallherbs", Color = Color3.fromRGB(40, 110, 60) },
    { Text = "💊 เสกโอสถ 50 ขนาน", Cmd = "giveallpills", Color = Color3.fromRGB(120, 60, 130) },
    { Text = "🛡️ โหมดอมตะ (Godmode)", Cmd = "godmode", Color = Color3.fromRGB(180, 140, 40) },
    { Text = "🏃 วิ่งเร็ว x2 (Speed 32)", Cmd = "speed 32", Color = Color3.fromRGB(50, 90, 130) },
    { Text = "💰 เติม 99,999 ตำลึง", Cmd = "setgold 99999", Color = Color3.fromRGB(160, 130, 30) },
}

for _, bDef in ipairs(quickButtons) do
    local b = Instance.new("TextButton")
    b.Name = "QBtn_" .. bDef.Cmd
    b.BackgroundColor3 = bDef.Color
    b.Text = bDef.Text
    b.TextColor3 = Color3.fromRGB(255, 255, 255)
    b.Font = Enum.Font.GothamBold
    b.TextSize = 12
    b.TextWrapped = true
    b.Parent = quickGrid

    local bCorner = Instance.new("UICorner")
    bCorner.CornerRadius = UDim.new(0, 8)
    bCorner.Parent = b

    b.Activated:Connect(function()
        executeDevCmd(bDef.Cmd)
        -- หากกดทดสอบ Trial ให้เปิดหน้าต่าง Trial ทันที
        if (bDef.Cmd == "testtrial1" or bDef.Cmd == "testtrial2") and _G.BreakthroughTrialUI then
            task.delay(0.2, function()
                _G.BreakthroughTrialUI:OpenModal()
            end)
        end
    end)
end

runCmdBtn.Activated:Connect(function()
    local text = cmdInput.Text
    if text and text ~= "" then
        executeDevCmd(text)
        cmdInput.Text = ""
    end
end)

cmdInput.FocusLost:Connect(function(enterPressed)
    if enterPressed then
        local text = cmdInput.Text
        if text and text ~= "" then
            executeDevCmd(text)
            cmdInput.Text = ""
        end
    end
end)

--------------------------------------------------------------------------------
-- 4. ลอจิกการเปิด/ปิด และการยืนยันตัวตน (Authentication Logic)
--------------------------------------------------------------------------------
local function toggleDevSuite()
    if isAuthenticated then
        UIManager:Toggle("DevAdminPanel")
    else
        -- ถ้ายังไม่ได้ยืนยันตัวตน ให้เปิดหน้าต่าง Login
        UIManager:Toggle("DevLoginModal")
    end
end

devHudBtn.Activated:Connect(toggleDevSuite)

closeLoginBtn.Activated:Connect(function()
    UIManager:Close("DevLoginModal")
end)

closePanelBtn.Activated:Connect(function()
    UIManager:Close("DevAdminPanel")
end)

submitLoginBtn.Activated:Connect(function()
    local user = userInput.Text
    local pass = passInput.Text
    loginStatus.Text = "กำลังตรวจสอบสิทธิ์..."
    loginStatus.TextColor3 = Color3.fromRGB(200, 200, 100)

    local ok, msg = NetworkEvents.DevLogin:InvokeServer(user, pass)
    if ok then
        isAuthenticated = true
        loginStatus.Text = "✅ " .. msg
        loginStatus.TextColor3 = Color3.fromRGB(120, 240, 160)
        task.wait(0.5)
        UIManager:Close("DevLoginModal")
        UIManager:Open("DevAdminPanel")
        addLog("🔑 ยืนยันตัวตน Dev สำเร็จ! ยินดีต้อนรับ " .. localPlayer.Name)
    else
        loginStatus.Text = "❌ " .. tostring(msg)
        loginStatus.TextColor3 = Color3.fromRGB(255, 100, 100)
    end
end)

-- คีย์ลัด F2 เพื่อเปิด Dev Suite
UserInputService.InputBegan:Connect(function(input, gpe)
    if gpe then return end
    if input.KeyCode == Enum.KeyCode.F2 then
        toggleDevSuite()
    end
end)

-- เช็กสถานะการยืนยันตัวตนเมื่อเริ่มเกม
task.spawn(function()
    local isDev = NetworkEvents.CheckDevAuth:InvokeServer()
    if isDev then
        isAuthenticated = true
    end
end)

-- ลงทะเบียนเข้ากับ UIManager
UIManager:Register("DevLoginModal", loginModal, function()
    loginModal.Visible = true
end, function()
    loginModal.Visible = false
    loginStatus.Text = ""
end)

UIManager:Register("DevAdminPanel", panelFrame, function()
    panelFrame.Visible = true
end, function()
    panelFrame.Visible = false
end)

print("✅ [Client] DevLoginUI & Dev Testing Suite ทำงานสมบูรณ์ (กด F2 หรือคลิกปุ่ม Dev Mode)")
