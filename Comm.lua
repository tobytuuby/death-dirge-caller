local _, ns = ...

local Constants = ns.Constants
local Comm = {}
ns.Comm = Comm

local function NormalizeSender(name)
    if not name or name == "" then
        return nil
    end

    return strlower(Ambiguate(name, "none"))
end

local function Trim(text)
    return text and text:match("^%s*(.-)%s*$") or ""
end

local function SequenceHasDuplicates(sequence)
    local seen = {}
    for _, value in ipairs(sequence) do
        if seen[value] then
            return true
        end

        seen[value] = true
    end

    return false
end

function Comm:Initialize()
    C_ChatInfo.RegisterAddonMessagePrefix(Constants.ADDON_PREFIX)
end

function Comm:CanBroadcastToRaid()
    return IsInRaid(LE_PARTY_CATEGORY_HOME) or IsInRaid(LE_PARTY_CATEGORY_INSTANCE)
end

function Comm:EncodeSequence(sequence)
    return table.concat(sequence, ",")
end

function Comm:EncodePanel(mode, sequence)
    return ("%s|%s"):format(mode, self:EncodeSequence(sequence))
end

function Comm:DecodePanel(payload)
    payload = Trim(payload)
    if payload == "" then
        return nil, nil, "empty"
    end

    local mode, sequencePayload = payload:match("^(%a+)|(.+)$")
    if not mode or not sequencePayload then
        return nil, nil, "malformed"
    end

    mode = strlower(Trim(mode))
    if mode ~= Constants.MODES.NORMAL and mode ~= Constants.MODES.HEROIC then
        return nil, nil, "invalid_mode"
    end

    local maxLength = mode == Constants.MODES.HEROIC and Constants.MAX_SEQUENCE or Constants.NORMAL_SEQUENCE
    local sequence, err = self:DecodeSequence(sequencePayload, maxLength)
    if not sequence then
        return nil, nil, err
    end

    return mode, sequence
end

function Comm:DecodeSequence(payload, maxLength)
    payload = Trim(payload)
    if payload == "" then
        return nil, "empty"
    end

    local sequence = {}
    for part in payload:gmatch("[^,]+") do
        local value = tonumber(Trim(part))
        if not value or value < 1 or value > Constants.MAX_SEQUENCE then
            return nil, "invalid_symbol"
        end

        if #sequence < maxLength then
            sequence[#sequence + 1] = value
        end
    end

    if #sequence == 0 then
        return nil, "empty"
    end

    if SequenceHasDuplicates(sequence) then
        return nil, "duplicate_symbol"
    end

    return sequence
end

function Comm:BroadcastSequence(sequence, mode)
    if not self:CanBroadcastToRaid() then
        return false, "You are not in a raid group."
    end

    local payload = self:EncodePanel(mode, sequence)
    C_ChatInfo.SendAddonMessage(Constants.ADDON_PREFIX, payload, "RAID")

    return true, payload
end

function Comm:HandleAddonMessage(prefix, payload, channel, sender)
    if prefix ~= Constants.ADDON_PREFIX then
        return
    end

    if sender and NormalizeSender(sender) == NormalizeSender(UnitName("player")) then
        return
    end

    local mode, sequence = self:DecodePanel(payload)
    if not mode or not sequence then
        ns.Core:DebugPrint(("Debug receive reject from %s: %s"):format(
            NormalizeSender(sender) or "unknown",
            "invalid payload"
        ))
        return
    end

    ns.Core:DebugPrint(("Debug receive: %s panel from %s [%s]"):format(
        mode == Constants.MODES.HEROIC and "Heroic" or "Normal",
        NormalizeSender(sender) or "unknown",
        self:EncodeSequence(sequence)
    ))
    ns.Core:SetSequence(sequence, true, mode)
    ns.Display:RenderSequence(mode, sequence, ("Received from %s"):format(NormalizeSender(sender) or "unknown"))
    ns.Controls:Refresh()
end
