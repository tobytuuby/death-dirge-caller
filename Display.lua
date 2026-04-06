local _, ns = ...

local Constants = ns.Constants
local Display = {}
ns.Display = Display

local function ApplySavedPoint(frame, pointData)
    frame:ClearAllPoints()
    frame:SetPoint(pointData.point, UIParent, pointData.relativePoint, pointData.x, pointData.y)
end

local function SaveCurrentPoint(frame, key)
    local point, _, relativePoint, x, y = frame:GetPoint(1)
    if point then
        ns.Config:SetPoint(key, point, relativePoint, x, y)
    end
end

local function SaveCurrentSize(frame, key)
    ns.Config:SetSize(key, frame:GetWidth(), frame:GetHeight())
end

local function ApplyResizeBounds(frame, minWidth, minHeight)
    if frame.SetResizeBounds then
        frame:SetResizeBounds(minWidth, minHeight)
    elseif frame.SetMinResize then
        frame:SetMinResize(minWidth, minHeight)
    end
end

function Display:Initialize()
    self:CreateFrame()
    self:CreateTextures()
    self:SetLocked(ns.Config:IsDisplayLocked())
    self:RestorePosition()
    self:RestoreSize()
    self:ClearSequence(true)
end

function Display:CreateFrame()
    local frame = CreateFrame("Frame", "DeathDirgeDisplayFrame", UIParent, "BackdropTemplate")
    frame:SetSize(Constants.DISPLAY.frameWidth, Constants.DISPLAY.frameHeight)
    frame:SetClampedToScreen(true)
    frame:SetMovable(true)
    frame:SetResizable(true)
    ApplyResizeBounds(frame, Constants.DISPLAY.minWidth, Constants.DISPLAY.minHeight)
    frame:EnableMouse(true)
    frame:RegisterForDrag("LeftButton")
    frame:SetFrameStrata("MEDIUM")
    frame:SetBackdrop({
        bgFile = "Interface\\DialogFrame\\UI-DialogBox-Background-Dark",
        edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
        edgeSize = 14,
        insets = { left = 3, right = 3, top = 3, bottom = 3 },
    })
    frame:SetBackdropColor(0.04, 0.04, 0.04, 0.8)
    frame:SetBackdropBorderColor(0.4, 0.4, 0.4, 0.9)
    frame:Hide()

    frame.status = frame:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    frame.status:SetPoint("BOTTOM", frame, "BOTTOM", 0, 10)
    frame.status:SetText("")

    frame:SetScript("OnDragStart", function(current)
        if not Display.locked then
            current:StartMoving()
        end
    end)

    frame:SetScript("OnDragStop", function(current)
        current:StopMovingOrSizing()
        SaveCurrentPoint(current, "displayPoint")
    end)

    frame:SetScript("OnSizeChanged", function(current)
        SaveCurrentSize(current, "displaySize")
        Display:UpdateResizeHandle()
    end)

    frame.resizeHandle = CreateFrame("Button", nil, frame)
    frame.resizeHandle:SetSize(18, 18)
    frame.resizeHandle:SetPoint("BOTTOMRIGHT", frame, "BOTTOMRIGHT", -4, 4)
    frame.resizeHandle:SetNormalTexture("Interface\\ChatFrame\\UI-ChatIM-SizeGrabber-Up")
    frame.resizeHandle:SetHighlightTexture("Interface\\ChatFrame\\UI-ChatIM-SizeGrabber-Highlight")
    frame.resizeHandle:SetPushedTexture("Interface\\ChatFrame\\UI-ChatIM-SizeGrabber-Down")
    frame.resizeHandle:SetScript("OnMouseDown", function()
        if not Display.locked then
            frame:StartSizing("BOTTOMRIGHT")
        end
    end)
    frame.resizeHandle:SetScript("OnMouseUp", function()
        frame:StopMovingOrSizing()
        SaveCurrentPoint(frame, "displayPoint")
        SaveCurrentSize(frame, "displaySize")
    end)

    self.frame = frame
end

function Display:CreateTextures()
    local frame = self.frame

    frame.boss = frame:CreateTexture(nil, "ARTWORK")
    frame.boss:SetSize(Constants.DISPLAY.bossSize, Constants.DISPLAY.bossSize)
    frame.boss:SetPoint("CENTER", frame, "CENTER", 0, 0)
    frame.boss:SetTexture(Constants.TEXTURES.boss)
    frame.boss:SetAlpha(0.82)

    frame.tank = frame:CreateTexture(nil, "ARTWORK")
    frame.tank:SetSize(Constants.DISPLAY.tankSize, Constants.DISPLAY.tankSize)
    frame.tank:SetTexture(Constants.TEXTURES.tank)

    frame.symbolSlots = {}
    for index = 1, Constants.MAX_SEQUENCE do
        local texture = frame:CreateTexture(nil, "OVERLAY")
        texture:SetSize(Constants.DISPLAY.symbolSize, Constants.DISPLAY.symbolSize)
        texture:Hide()
        frame.symbolSlots[index] = texture
    end
end

function Display:SetLocked(locked)
    self.locked = locked
    self.frame:EnableMouse(true)
    self:UpdateResizeHandle()
end

function Display:RestorePosition()
    ApplySavedPoint(self.frame, ns.Config:GetPoint("displayPoint"))
end

function Display:RestoreSize()
    local size = ns.Config:GetSize("displaySize")
    self.frame:SetSize(size.width, size.height)
end

function Display:ResetPosition()
    self:RestorePosition()
end

function Display:UpdateResizeHandle()
    if self.locked then
        self.frame.resizeHandle:Hide()
    else
        self.frame.resizeHandle:Show()
    end
end

function Display:HideLater()
    if self.hideTimer then
        self.hideTimer:Cancel()
        self.hideTimer = nil
    end

    if not ns.Config:IsTimerEnabled() then
        return
    end

    local seconds = ns.Config:GetTimerSeconds()
    self.hideTimer = C_Timer.NewTimer(seconds, function()
        self.frame:Hide()
    end)
end

function Display:UpdateLayout(mode, sequence)
    local frame = self.frame
    local layout = Constants.LAYOUTS[mode] or Constants.LAYOUTS.normal
    local maxSlots = mode == Constants.MODES.HEROIC and Constants.MAX_SEQUENCE or Constants.NORMAL_SEQUENCE
    frame.boss:SetSize(Constants.DISPLAY.bossSize, Constants.DISPLAY.bossSize)
    frame.tank:SetSize(Constants.DISPLAY.tankSize, Constants.DISPLAY.tankSize)

    frame.tank:ClearAllPoints()
    frame.tank:SetPoint("CENTER", frame, "CENTER", layout.tank.x, layout.tank.y)

    for index = 1, Constants.MAX_SEQUENCE do
        local slot = frame.symbolSlots[index]
        local point = layout.seq[index]
        slot:ClearAllPoints()
        slot:SetSize(Constants.DISPLAY.symbolSize, Constants.DISPLAY.symbolSize)

        if index <= maxSlots and point and sequence[index] then
            slot:SetPoint("CENTER", frame, "CENTER", point.x, point.y)
            slot:SetTexture(Constants.TEXTURES.symbols[sequence[index]])
            slot:Show()
        else
            slot:Hide()
        end
    end
end

function Display:RenderSequence(mode, sequence, source)
    self.lastMode = mode
    self.lastSequence = sequence
    self:UpdateLayout(mode, sequence)
    local status = source or ""
    if not self.locked then
        if status ~= "" then
            status = status .. "  |  Drag to move"
        else
            status = "Drag to move"
        end
    end
    self.frame.status:SetText(status)
    self.frame:Show()
    self:HideLater()
end

function Display:ClearSequence(silent)
    for _, texture in ipairs(self.frame.symbolSlots) do
        texture:Hide()
    end

    if silent then
        self.frame.status:SetText(self.locked and "" or "Drag to move")
        return
    end

    self.frame.status:SetText(self.locked and "Sequence cleared" or "Sequence cleared  |  Drag to move")
    self.frame:Show()
    self:HideLater()
end
