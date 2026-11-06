--[[
    UIManager.lua
    โมดูลจัดการหน้าต่างอินเทอร์เฟซ (Window Mutual Exclusion Manager)
    ควบคุมให้เมื่อเปิดหน้าต่างใดหน้าต่างหนึ่ง (เช่น Inventory, Alchemy, CharacterStatus, Terminal)
    หน้าต่างอื่นที่กำลังเปิดอยู่จะถูกสั่งปิดทันที เพื่อไม่ให้หน้าต่างซ้อนทับกัน
]]

local UIManager = {}
local windows = {}
local activeWindow = nil

function UIManager:Register(name, frame, openFn, closeFn)
    windows[name] = {
        Name = name,
        Frame = frame,
        Open = openFn,
        Close = closeFn,
    }
end

function UIManager:Open(name)
    if activeWindow and activeWindow ~= name then
        self:Close(activeWindow)
    end

    local win = windows[name]
    if win then
        activeWindow = name
        if win.Open then
            win.Open()
        end
        if win.Frame then
            win.Frame.Visible = true
        end
    end
end

function UIManager:Close(name)
    local win = windows[name]
    if win then
        if win.Close then
            win.Close()
        end
        if win.Frame then
            win.Frame.Visible = false
        end
    end
    if activeWindow == name then
        activeWindow = nil
    end
end

function UIManager:Toggle(name)
    local win = windows[name]
    if not win then return end

    local isVisible = false
    if win.Frame then
        isVisible = win.Frame.Visible
    end

    if isVisible then
        self:Close(name)
    else
        self:Open(name)
    end
end

function UIManager:CloseAll()
    for name, _ in pairs(windows) do
        self:Close(name)
    end
    activeWindow = nil
end

function UIManager:GetActive()
    return activeWindow
end

_G.DaoistUIManager = UIManager

return UIManager
