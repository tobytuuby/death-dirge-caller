local _, ns = ...

local Constants = ns.Constants
local Controls = {}
ns.Controls = Controls

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

local function SequenceToText(sequence)
    if #sequence == 0 then
        return "None"
    end

    local parts = {}
    for _, symbolID in ipairs(sequence) do
        parts[#parts + 1] = Constants.TEXTURES.labels[symbolID] or tostring(symbolID)
    end

    return table.concat(parts, " > ")
end

function Controls:Initialize()
    self:CreateFrame()
    self:RestorePosition()
    self:RestoreSize()
    self:Layout()
    self:Refresh()
    self.frame:Hide()
end

function Controls:CreateFrame()
    local frame = CreateFrame("Frame", "DeathDirgeControlFrame", UIParent, "BackdropTemplate")
    frame:SetSize(Constants.CONTROLS.frameWidth, Constants.CONTROLS.frameHeight)
    frame:SetClampedToScreen(true)
    frame:SetMovable(true)
    frame:SetResizable(true)
    ApplyResizeBounds(frame, Constants.CONTROLS.minWidth, Constants.CONTROLS.minHeight)
    frame:EnableMouse(true)
    frame:RegisterForDrag("LeftButton")
    frame:SetFrameStrata("MEDIUM")
    frame:SetBackdrop({
        bgFile = "Interface\\DialogFrame\\UI-DialogBox-Background",
        edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
        edgeSize = 14,
        insets = { left = 3, right = 3, top = 3, bottom = 3 },
    })
    frame:SetBackdropColor(0.08, 0.08, 0.08, 0.9)
    frame:SetBackdropBorderColor(0.45, 0.45, 0.45, 0.95)
    frame:Hide()

    frame:SetScript("OnDragStart", function(current)
        if not ns.Config:IsDisplayLocked() then
            current:StartMoving()
        end
    end)

    frame:SetScript("OnDragStop", function(current)
        current:StopMovingOrSizing()
        SaveCurrentPoint(current, "controlsPoint")
    end)

    frame:SetScript("OnSizeChanged", function(current)
        SaveCurrentSize(current, "controlsSize")
        Controls:Layout()
    end)

    frame.title = frame:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
    frame.title:SetPoint("TOPLEFT", frame, "TOPLEFT", 12, -12)
    frame.title:SetText("Death's Dirge Caller")

    frame.closeButton = CreateFrame("Button", nil, frame, "UIPanelCloseButton")
    frame.closeButton:SetSize(24, 24)
    frame.closeButton:SetScript("OnClick", function()
        Controls:Hide()
    end)

    frame.modeText = frame:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    frame.modeText:SetPoint("TOPLEFT", frame.title, "BOTTOMLEFT", 0, -6)

    frame.modeButtons = {}
    local modeConfigs = {
        { key = Constants.MODES.AUTO, label = "Auto" },
        { key = Constants.MODES.NORMAL, label = "Normal" },
        { key = Constants.MODES.HEROIC, label = "Heroic" },
    }

    for index, config in ipairs(modeConfigs) do
        local button = CreateFrame("Button", nil, frame, "UIPanelButtonTemplate")
        button:SetHeight(Constants.CONTROLS.modeButtonHeight)
        button:SetText(config.label)
        button.modeKey = config.key
        button:SetScript("OnClick", function(self)
            ns.Core:SetModePreference(self.modeKey)
        end)
        frame.modeButtons[index] = button
    end

    frame.senderText = frame:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    frame.senderText:SetPoint("TOPLEFT", frame.modeText, "BOTTOMLEFT", 0, -30)

    frame.sequenceText = frame:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
    frame.sequenceText:SetPoint("TOPLEFT", frame.senderText, "BOTTOMLEFT", 0, -8)
    frame.sequenceText:SetWidth(392)
    frame.sequenceText:SetJustifyH("LEFT")

    frame.buttons = {}
    for index = 1, Constants.MAX_SEQUENCE do
        local button = CreateFrame("Button", nil, frame, "UIPanelButtonTemplate")
        button:SetSize(Constants.CONTROLS.topButtonWidth, Constants.CONTROLS.symbolButtonHeight)
        button:SetText(Constants.TEXTURES.labels[index])
        button:SetScript("OnClick", function()
            ns.Core:AppendSymbol(index)
        end)
        frame.buttons[index] = button
    end

    frame.undoButton = CreateFrame("Button", nil, frame, "UIPanelButtonTemplate")
    frame.undoButton:SetSize(Constants.CONTROLS.actionButtonWidth, Constants.CONTROLS.actionButtonHeight)
    frame.undoButton:SetText("Undo")
    frame.undoButton:SetScript("OnClick", function()
        ns.Core:UndoLastSymbol()
    end)

    frame.clearButton = CreateFrame("Button", nil, frame, "UIPanelButtonTemplate")
    frame.clearButton:SetSize(Constants.CONTROLS.actionButtonWidth, Constants.CONTROLS.actionButtonHeight)
    frame.clearButton:SetText("Clear")
    frame.clearButton:SetScript("OnClick", function()
        ns.Core:ClearSequence()
    end)

    frame.sendButton = CreateFrame("Button", nil, frame, "UIPanelButtonTemplate")
    frame.sendButton:SetSize(Constants.CONTROLS.actionButtonWidth, Constants.CONTROLS.actionButtonHeight)
    frame.sendButton:SetText("Send")
    frame.sendButton:SetScript("OnClick", function()
        ns.Core:SendSequence()
    end)

    frame.testButton = CreateFrame("Button", nil, frame, "UIPanelButtonTemplate")
    frame.testButton:SetSize(Constants.CONTROLS.actionButtonWidth, Constants.CONTROLS.actionButtonHeight)
    frame.testButton:SetText("Test")
    frame.testButton:SetScript("OnClick", function()
        ns.Core:RunTest()
    end)

    frame.lockButton = CreateFrame("Button", nil, frame, "UIPanelButtonTemplate")
    frame.lockButton:SetSize(92, Constants.CONTROLS.actionButtonHeight)
    frame.lockButton:SetScript("OnClick", function()
        ns.Core:SetFramesLocked(not ns.Config:IsDisplayLocked())
    end)

    frame.advancedButton = CreateFrame("Button", nil, frame, "UIPanelButtonTemplate")
    frame.advancedButton:SetHeight(Constants.CONTROLS.actionButtonHeight)
    frame.advancedButton:SetScript("OnClick", function()
        ns.Config:SetAdvancedExpanded(not ns.Config:IsAdvancedExpanded())
        Controls:Refresh()
    end)

    frame.senderLabel = frame:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    frame.senderLabel:SetText("Sender")

    frame.senderEditBox = CreateFrame("EditBox", nil, frame, "InputBoxTemplate")
    frame.senderEditBox:SetAutoFocus(false)
    frame.senderEditBox:SetHeight(22)
    frame.senderEditBox:SetScript("OnEnterPressed", function(self)
        ns.Core:SetSenderFromPanel(self:GetText())
        self:ClearFocus()
    end)

    frame.senderSetButton = CreateFrame("Button", nil, frame, "UIPanelButtonTemplate")
    frame.senderSetButton:SetText("Set")
    frame.senderSetButton:SetScript("OnClick", function()
        ns.Core:SetSenderFromPanel(frame.senderEditBox:GetText())
    end)

    frame.senderClearButton = CreateFrame("Button", nil, frame, "UIPanelButtonTemplate")
    frame.senderClearButton:SetText("Clear")
    frame.senderClearButton:SetScript("OnClick", function()
        frame.senderEditBox:SetText("")
        ns.Core:ClearSenderFromPanel()
    end)

    frame.senderLockButton = CreateFrame("Button", nil, frame, "UIPanelButtonTemplate")
    frame.senderLockButton:SetScript("OnClick", function()
        ns.Core:ToggleSenderLockFromPanel()
    end)

    frame.timerLabel = frame:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    frame.timerLabel:SetText("Timer")

    frame.timerEditBox = CreateFrame("EditBox", nil, frame, "InputBoxTemplate")
    frame.timerEditBox:SetAutoFocus(false)
    frame.timerEditBox:SetNumeric(false)
    frame.timerEditBox:SetHeight(22)
    frame.timerEditBox:SetScript("OnEnterPressed", function(self)
        ns.Core:SetTimerFromPanel(self:GetText())
        self:ClearFocus()
    end)

    frame.timerSetButton = CreateFrame("Button", nil, frame, "UIPanelButtonTemplate")
    frame.timerSetButton:SetText("Set")
    frame.timerSetButton:SetScript("OnClick", function()
        ns.Core:SetTimerFromPanel(frame.timerEditBox:GetText())
    end)

    frame.timerOffButton = CreateFrame("Button", nil, frame, "UIPanelButtonTemplate")
    frame.timerOffButton:SetText("Off")
    frame.timerOffButton:SetScript("OnClick", function()
        ns.Core:DisableTimerFromPanel()
    end)

    frame.hintText = frame:CreateFontString(nil, "OVERLAY", "GameFontDisableSmall")
    frame.hintText:SetText("/ddc help for commands")

    frame.resizeHandle = CreateFrame("Button", nil, frame)
    frame.resizeHandle:SetSize(18, 18)
    frame.resizeHandle:SetNormalTexture("Interface\\ChatFrame\\UI-ChatIM-SizeGrabber-Up")
    frame.resizeHandle:SetHighlightTexture("Interface\\ChatFrame\\UI-ChatIM-SizeGrabber-Highlight")
    frame.resizeHandle:SetPushedTexture("Interface\\ChatFrame\\UI-ChatIM-SizeGrabber-Down")
    frame.resizeHandle:SetScript("OnMouseDown", function()
        if not ns.Config:IsDisplayLocked() then
            frame:StartSizing("BOTTOMRIGHT")
        end
    end)
    frame.resizeHandle:SetScript("OnMouseUp", function()
        frame:StopMovingOrSizing()
        SaveCurrentPoint(frame, "controlsPoint")
        SaveCurrentSize(frame, "controlsSize")
    end)

    self.frame = frame
end

function Controls:RestorePosition()
    ApplySavedPoint(self.frame, ns.Config:GetPoint("controlsPoint"))
end

function Controls:RestoreSize()
    local size = ns.Config:GetSize("controlsSize")
    self.frame:SetSize(size.width, size.height)
end

function Controls:ResetPosition()
    self:RestorePosition()
end

function Controls:Layout()
    if not self.frame then
        return
    end

    local frame = self.frame
    local padding = Constants.CONTROLS.padding
    local width = frame:GetWidth()
    local contentWidth = width - (padding * 2)
    local topY = -padding

    frame.title:ClearAllPoints()
    frame.title:SetPoint("TOPLEFT", frame, "TOPLEFT", padding, topY)

    frame.closeButton:ClearAllPoints()
    frame.closeButton:SetPoint("TOPRIGHT", frame, "TOPRIGHT", -4, -4)

    frame.modeText:ClearAllPoints()
    frame.modeText:SetPoint("TOPLEFT", frame.title, "BOTTOMLEFT", 0, -6)

    local modeButtonsTop = -42
    local modeButtonSpacing = 6
    local modeButtonWidth = math.max(64, math.floor((contentWidth - (modeButtonSpacing * 2)) / 3))
    local modeButtonX = padding
    for _, button in ipairs(frame.modeButtons) do
        button:ClearAllPoints()
        button:SetWidth(modeButtonWidth)
        button:SetPoint("TOPLEFT", frame, "TOPLEFT", modeButtonX, modeButtonsTop)
        modeButtonX = modeButtonX + modeButtonWidth + modeButtonSpacing
    end

    frame.senderText:ClearAllPoints()
    frame.senderText:SetPoint("TOPLEFT", frame, "TOPLEFT", padding, -70)

    frame.sequenceText:ClearAllPoints()
    frame.sequenceText:SetPoint("TOPLEFT", frame.senderText, "BOTTOMLEFT", 0, -8)
    frame.sequenceText:SetWidth(contentWidth)

    local symbolButtonWidth = math.max(48, math.floor((contentWidth - ((Constants.MAX_SEQUENCE - 1) * 6)) / Constants.MAX_SEQUENCE))
    local symbolSpacing = math.max(4, math.floor((contentWidth - (Constants.MAX_SEQUENCE * symbolButtonWidth)) / (Constants.MAX_SEQUENCE - 1)))
    local startX = padding
    local buttonY = -126
    for index, button in ipairs(frame.buttons) do
        button:ClearAllPoints()
        button:SetWidth(symbolButtonWidth)
        button:SetPoint("TOPLEFT", frame, "TOPLEFT", startX, buttonY)
        startX = startX + symbolButtonWidth + symbolSpacing
    end

    local actions = {
        frame.undoButton,
        frame.clearButton,
        frame.sendButton,
        frame.testButton,
        frame.lockButton,
    }
    local lockWidth = math.max(84, math.floor(contentWidth * 0.22))
    local actionWidth = math.max(56, math.floor((contentWidth - lockWidth - (4 * 6)) / 4))
    local actionWidths = { actionWidth, actionWidth, actionWidth, actionWidth, lockWidth }
    local totalActionWidth = (actionWidth * 4) + lockWidth
    local actionSpacing = math.max(4, math.floor((contentWidth - totalActionWidth) / (#actions - 1)))
    local actionX = padding
    local actionY = -168

    for index, button in ipairs(actions) do
        button:ClearAllPoints()
        button:SetWidth(actionWidths[index])
        button:SetPoint("TOPLEFT", frame, "TOPLEFT", actionX, actionY)
        actionX = actionX + actionWidths[index] + actionSpacing
    end

    local advancedY = -206
    frame.advancedButton:ClearAllPoints()
    frame.advancedButton:SetWidth(contentWidth)
    frame.advancedButton:SetPoint("TOPLEFT", frame, "TOPLEFT", padding, advancedY)

    local bottomY = advancedY - Constants.CONTROLS.actionButtonHeight
    local advancedExpanded = ns.Config:IsAdvancedExpanded()

    if advancedExpanded then
        local fieldY = advancedY - 34
        local smallButtonWidth = 52
        local senderLockWidth = 92
        local senderEditWidth = math.max(120, contentWidth - (smallButtonWidth * 2) - senderLockWidth - 24)

        frame.senderLabel:ClearAllPoints()
        frame.senderLabel:SetPoint("TOPLEFT", frame, "TOPLEFT", padding, fieldY)

        frame.senderEditBox:ClearAllPoints()
        frame.senderEditBox:SetWidth(senderEditWidth)
        frame.senderEditBox:SetPoint("TOPLEFT", frame.senderLabel, "BOTTOMLEFT", 0, -4)

        frame.senderSetButton:ClearAllPoints()
        frame.senderSetButton:SetSize(smallButtonWidth, 22)
        frame.senderSetButton:SetPoint("LEFT", frame.senderEditBox, "RIGHT", 6, 0)

        frame.senderClearButton:ClearAllPoints()
        frame.senderClearButton:SetSize(smallButtonWidth, 22)
        frame.senderClearButton:SetPoint("LEFT", frame.senderSetButton, "RIGHT", 6, 0)

        frame.senderLockButton:ClearAllPoints()
        frame.senderLockButton:SetSize(senderLockWidth, 22)
        frame.senderLockButton:SetPoint("LEFT", frame.senderClearButton, "RIGHT", 6, 0)

        frame.timerLabel:ClearAllPoints()
        frame.timerLabel:SetPoint("TOPLEFT", frame.senderEditBox, "BOTTOMLEFT", 0, -12)

        local timerEditWidth = math.max(80, contentWidth - 116)
        frame.timerEditBox:ClearAllPoints()
        frame.timerEditBox:SetWidth(timerEditWidth)
        frame.timerEditBox:SetPoint("TOPLEFT", frame.timerLabel, "BOTTOMLEFT", 0, -4)

        frame.timerSetButton:ClearAllPoints()
        frame.timerSetButton:SetSize(52, 22)
        frame.timerSetButton:SetPoint("LEFT", frame.timerEditBox, "RIGHT", 6, 0)

        frame.timerOffButton:ClearAllPoints()
        frame.timerOffButton:SetSize(52, 22)
        frame.timerOffButton:SetPoint("LEFT", frame.timerSetButton, "RIGHT", 6, 0)

        bottomY = fieldY - 72
    end

    frame.hintText:ClearAllPoints()
    frame.hintText:SetPoint("TOPLEFT", frame, "TOPLEFT", padding, bottomY - 12)

    local targetHeight = math.max(Constants.CONTROLS.minHeight, math.abs(bottomY) + 42)
    if math.abs(frame:GetHeight() - targetHeight) > 1 then
        frame:SetHeight(targetHeight)
    end

    frame.resizeHandle:ClearAllPoints()
    frame.resizeHandle:SetPoint("BOTTOMRIGHT", frame, "BOTTOMRIGHT", -4, 4)
    frame.resizeHandle:SetShown(not ns.Config:IsDisplayLocked())
end

function Controls:Toggle()
    if self.frame:IsShown() then
        self.frame:Hide()
    else
        self.frame:Show()
    end
end

function Controls:IsShown()
    return self.frame and self.frame:IsShown()
end

function Controls:Show()
    if self.frame then
        self.frame:Show()
    end
end

function Controls:Hide()
    if self.frame then
        self.frame:Hide()
    end
end

function Controls:Refresh()
    if not self.frame then
        return
    end

    local sequence = ns.Core:GetSequence()
    local activeMode = ns.Core:GetActiveMode()
    local modePreference = ns.Config:GetModePreference()
    local senderLabel
    local modeLabel

    if ns.Config:IsSenderLockEnabled() then
        senderLabel = ns.Config:GetSenderName() or "No approved sender"
        senderLabel = "Sender Lock: ON (" .. senderLabel .. ")"
    else
        senderLabel = "Sender Lock: OFF"
    end

    if modePreference == Constants.MODES.AUTO then
        modeLabel = ("Auto (%s)"):format(activeMode == Constants.MODES.HEROIC and "Heroic" or "Normal")
    elseif modePreference == Constants.MODES.HEROIC then
        modeLabel = "Heroic"
    else
        modeLabel = "Normal"
    end

    self.frame.modeText:SetText("Mode: " .. modeLabel)
    self.frame.senderText:SetText(senderLabel)
    self.frame.sequenceText:SetText("Sequence: " .. SequenceToText(sequence))
    self.frame.lockButton:SetText(ns.Config:IsDisplayLocked() and "Unlock Frames" or "Lock Frames")
    self.frame.advancedButton:SetText(ns.Config:IsAdvancedExpanded() and "Advanced: Hide" or "Advanced: Show")
    self.frame.senderEditBox:SetText(ns.Config:GetSenderName() or "")
    self.frame.senderLockButton:SetText(ns.Config:IsSenderLockEnabled() and "Lock: On" or "Lock: Off")
    self.frame.timerEditBox:SetText(ns.Config:IsTimerEnabled() and tostring(ns.Config:GetTimerSeconds()) or "")

    local advancedWidgets = {
        self.frame.senderLabel,
        self.frame.senderEditBox,
        self.frame.senderSetButton,
        self.frame.senderClearButton,
        self.frame.senderLockButton,
        self.frame.timerLabel,
        self.frame.timerEditBox,
        self.frame.timerSetButton,
        self.frame.timerOffButton,
    }
    for _, widget in ipairs(advancedWidgets) do
        widget:SetShown(ns.Config:IsAdvancedExpanded())
    end

    for _, button in ipairs(self.frame.modeButtons) do
        button:SetEnabled(button.modeKey ~= modePreference)
    end

    self:Layout()

    for index, button in ipairs(self.frame.buttons) do
        button:SetEnabled(true)
    end
end
