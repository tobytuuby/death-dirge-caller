local _, ns = ...

local Constants = ns.Constants

ns.Core = CreateFrame("Frame")
local Core = ns.Core

Core.sequence = {}
Core.currentMode = Constants.MODES.NORMAL
Core.sequenceMode = Constants.MODES.NORMAL
Core.testPreviewActive = false

local function Print(message)
    DEFAULT_CHAT_FRAME:AddMessage("|cff7bd7ffDeathDirge:|r " .. message)
end

local function GetModeLabel(mode)
    return mode == Constants.MODES.HEROIC and "Heroic" or "Normal"
end

local function GetMaxSequenceForMode(mode)
    return mode == Constants.MODES.HEROIC and Constants.MAX_SEQUENCE or Constants.NORMAL_SEQUENCE
end

local function FormatSequenceForChat(sequence)
    local parts = {}
    for _, value in ipairs(sequence) do
        parts[#parts + 1] = tostring(value)
    end

    return table.concat(parts, ", ")
end

local function SequenceHasSymbol(sequence, symbolID)
    for _, value in ipairs(sequence) do
        if value == symbolID then
            return true
        end
    end

    return false
end

function Core:GetSequence()
    return self.sequence
end

function Core:GetSequenceMode()
    return self.sequenceMode or self:GetActiveMode()
end

function Core:SetSequence(sequence, skipRender, mode)
    self.testPreviewActive = false
    self.sequenceMode = mode or self:GetActiveMode()
    wipe(self.sequence)
    for _, value in ipairs(sequence) do
        self.sequence[#self.sequence + 1] = value
    end

    if not skipRender then
        ns.Display:RenderSequence(self:GetSequenceMode(), self.sequence, "Sequence updated")
    end
end

function Core:RefreshMode()
    self.currentMode = ns.Config:GetModePreference()

    if self.sequenceMode ~= Constants.MODES.NORMAL and self.sequenceMode ~= Constants.MODES.HEROIC then
        self.sequenceMode = self.currentMode
    end

    if self.sequenceMode == self.currentMode then
        local maxLength = GetMaxSequenceForMode(self.currentMode)
        while #self.sequence > maxLength do
            table.remove(self.sequence)
        end
    end

    ns.Controls:Refresh()

    if self.testPreviewActive then
        self:RenderTestPreview("Local test preview")
    elseif #self.sequence > 0 then
        ns.Display:RenderSequence(self:GetSequenceMode(), self.sequence, "Mode refreshed")
    end

end

function Core:GetActiveMode()
    return self.currentMode
end

function Core:SetModePreference(mode)
    ns.Config:SetModePreference(mode)
    self:RefreshMode()
    Print(("Mode set to %s."):format(GetModeLabel(mode)))
end

function Core:AppendSymbol(symbolID)
    self.testPreviewActive = false
    local maxLength = GetMaxSequenceForMode(self:GetActiveMode())
    if #self.sequence >= maxLength then
        Print(("Sequence is full for %s mode."):format(GetModeLabel(self:GetActiveMode())))
        return
    end

    if SequenceHasSymbol(self.sequence, symbolID) then
        Print("That symbol is already in the sequence.")
        return
    end

    self.sequence[#self.sequence + 1] = symbolID
    self.sequenceMode = self:GetActiveMode()
    ns.Display:RenderSequence(self.sequenceMode, self.sequence, "Sequence updated")
    ns.Controls:Refresh()
end

function Core:UndoLastSymbol()
    self.testPreviewActive = false
    if #self.sequence == 0 then
        return
    end

    table.remove(self.sequence)
    if #self.sequence == 0 then
        self.sequenceMode = self:GetActiveMode()
        ns.Display:ClearSequence(false)
    else
        self.sequenceMode = self:GetActiveMode()
        ns.Display:RenderSequence(self.sequenceMode, self.sequence, "Sequence updated")
    end
    ns.Controls:Refresh()
end

function Core:ClearSequence()
    self.testPreviewActive = false
    wipe(self.sequence)
    self.sequenceMode = self:GetActiveMode()
    ns.Display:ClearSequence(false)
    ns.Controls:Refresh()
end

function Core:SendSequence()
    self.testPreviewActive = false
    if #self.sequence == 0 then
        Print("Nothing to send. Build a sequence first.")
        return
    end

    self.sequenceMode = self:GetActiveMode()
    local ok, errorMessage = ns.Comm:BroadcastSequence(self.sequence, self.sequenceMode)
    if not ok then
        Print(errorMessage)
        return
    end

    ns.Display:RenderSequence(self.sequenceMode, self.sequence, "Sent to raid")
    Print(("Sent %s panel: [%s]"):format(GetModeLabel(self.sequenceMode), FormatSequenceForChat(self.sequence)))
end

function Core:GetTestPreviewSequence()
    local mode = self:GetActiveMode()
    local maxLength = GetMaxSequenceForMode(mode)
    local preview = {}

    if #self.sequence > 0 then
        for _, value in ipairs(self.sequence) do
            preview[#preview + 1] = value
        end
    else
        for index = 1, maxLength do
            preview[#preview + 1] = index
        end
    end

    while #preview > maxLength do
        table.remove(preview)
    end

    return preview
end

function Core:RenderTestPreview(source)
    ns.Display:RenderSequence(self:GetActiveMode(), self:GetTestPreviewSequence(), source or "Local test preview")
end

function Core:RunTest()
    self.testPreviewActive = true
    self:RenderTestPreview("Local test preview")
end

function Core:SetFramesLocked(locked)
    ns.Config:SetDisplayLocked(locked)
    ns.Display:SetLocked(locked)
    ns.Controls:Refresh()
    Print(locked and "Frames locked." or "Frames unlocked. Drag the display or caller panel to move them.")
end

function Core:ToggleAddonUI()
    ns.Controls:Toggle()
end

function Core:SetTimerFromPanel(value)
    local trimmed = value and value:match("^%s*(.-)%s*$") or ""
    local seconds = tonumber(trimmed)
    if not seconds or seconds <= 0 then
        Print("Timer must be a positive number of seconds.")
        return
    end

    ns.Config:SetTimer(seconds)
    Print(("Auto-hide timer set to %.1f seconds."):format(seconds))
    ns.Controls:Refresh()
end

function Core:DisableTimerFromPanel()
    ns.Config:SetTimer(nil)
    Print("Auto-hide timer disabled.")
    ns.Controls:Refresh()
end

function Core:ResetPositions()
    ns.Config:ResetPositions()
    ns.Display:ResetPosition()
    ns.Controls:ResetPosition()
    Print("Display and caller panel positions reset.")
end

function Core:PrintHelp()
    Print("Commands: /ddc, /ddc help, /ddc status, /ddc resetpos")
    Print("Mode, raid, and timer controls are available in the caller panel.")
end

function Core:PrintStatus()
    local timerText = ns.Config:IsTimerEnabled() and tostring(ns.Config:GetTimerSeconds()) .. "s" or "off"

    Print(("Active mode: %s"):format(GetModeLabel(self:GetActiveMode())))
    Print(("Mode preference: %s"):format(GetModeLabel(ns.Config:GetModePreference())))
    Print(("Sequence length: %d/%d"):format(#self.sequence, GetMaxSequenceForMode(self:GetActiveMode())))
    Print(("Timer: %s"):format(timerText))
    Print(("Frames: %s"):format(ns.Config:IsDisplayLocked() and "locked" or "unlocked"))
end

function Core:HandleSlashCommand(message)
    local command = message:match("^(%S+)")
    command = command and command:lower() or ""

    if command == "" then
        ns.Controls:Toggle()
        return
    end

    if command == "help" then
        self:PrintHelp()
    elseif command == "status" then
        self:PrintStatus()
    elseif command == "resetpos" then
        self:ResetPositions()
    else
        self:PrintHelp()
    end
end

function Core:OnEvent(event, ...)
    if event == "PLAYER_LOGIN" then
        ns.Config:Initialize()
        ns.Display:Initialize()
        ns.Comm:Initialize()
        ns.Controls:Initialize()
        ns.MinimapButton:Initialize()
        self:RefreshMode()
        self:RegisterEvent("CHAT_MSG_ADDON")

        SLASH_DEATHDIRGE1 = Constants.SLASH_ALIASES[1]
        SLASH_DEATHDIRGE2 = Constants.SLASH_ALIASES[2]
        SlashCmdList.DEATHDIRGE = function(msg)
            self:HandleSlashCommand(msg or "")
        end
    elseif event == "CHAT_MSG_ADDON" then
        ns.Comm:HandleAddonMessage(...)
    end
end

Core:RegisterEvent("PLAYER_LOGIN")
Core:SetScript("OnEvent", function(_, ...)
    Core:OnEvent(...)
end)
