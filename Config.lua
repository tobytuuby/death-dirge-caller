local _, ns = ...

local Constants = ns.Constants
local Config = {}
ns.Config = Config

local defaults = {
    modePreference = Constants.MODES.AUTO,
    timerSeconds = Constants.DEFAULT_TIMER_SECONDS,
    timerEnabled = true,
    senderLockEnabled = false,
    senderName = nil,
    displayLocked = false,
    displayPoint = nil,
    controlsPoint = nil,
    displaySize = nil,
    controlsSize = nil,
    minimap = {
        angle = 220,
        hidden = false,
    },
    configVersion = 2,
}

local function DeepCopy(value)
    if type(value) ~= "table" then
        return value
    end

    local copy = {}
    for key, nestedValue in pairs(value) do
        copy[key] = DeepCopy(nestedValue)
    end

    return copy
end

local function ApplyDefaults(target, source)
    for key, value in pairs(source) do
        if type(value) == "table" then
            if type(target[key]) ~= "table" then
                target[key] = DeepCopy(value)
            else
                ApplyDefaults(target[key], value)
            end
        elseif target[key] == nil then
            target[key] = value
        end
    end
end

function Config:Initialize()
    DeathDirgeDB = DeathDirgeDB or {}
    ApplyDefaults(DeathDirgeDB, defaults)

    -- Migrate older installs to the current defaults.
    if not DeathDirgeDB.configVersion then
        DeathDirgeDB.displayLocked = false
        DeathDirgeDB.configVersion = 1
    end

    if DeathDirgeDB.configVersion < 2 then
        if DeathDirgeDB.timerEnabled ~= false and (DeathDirgeDB.timerSeconds == nil or DeathDirgeDB.timerSeconds == 8) then
            DeathDirgeDB.timerSeconds = Constants.DEFAULT_TIMER_SECONDS
            DeathDirgeDB.timerEnabled = true
        end

        DeathDirgeDB.configVersion = 2
    end

    if not DeathDirgeDB.displayPoint then
        DeathDirgeDB.displayPoint = DeepCopy(Constants.DEFAULT_DISPLAY_POINT)
    end

    if not DeathDirgeDB.controlsPoint then
        DeathDirgeDB.controlsPoint = DeepCopy(Constants.DEFAULT_CONTROLS_POINT)
    end

    if not DeathDirgeDB.displaySize then
        DeathDirgeDB.displaySize = {
            width = Constants.DISPLAY.frameWidth,
            height = Constants.DISPLAY.frameHeight,
        }
    end

    if not DeathDirgeDB.controlsSize then
        DeathDirgeDB.controlsSize = {
            width = Constants.CONTROLS.frameWidth,
            height = Constants.CONTROLS.frameHeight,
        }
    end

    self.db = DeathDirgeDB
end

function Config:GetDB()
    return self.db
end

function Config:GetModePreference()
    return self.db.modePreference
end

function Config:SetModePreference(mode)
    self.db.modePreference = mode
end

function Config:IsTimerEnabled()
    return self.db.timerEnabled
end

function Config:SetTimer(seconds)
    if not seconds then
        self.db.timerEnabled = false
        self.db.timerSeconds = 0
        return
    end

    self.db.timerEnabled = true
    self.db.timerSeconds = seconds
end

function Config:GetTimerSeconds()
    return self.db.timerSeconds
end

function Config:IsSenderLockEnabled()
    return self.db.senderLockEnabled
end

function Config:SetSenderLockEnabled(enabled)
    self.db.senderLockEnabled = enabled and true or false
end

function Config:GetSenderName()
    return self.db.senderName
end

function Config:SetSenderName(name)
    if name and name ~= "" then
        self.db.senderName = Ambiguate(name, "none")
    else
        self.db.senderName = nil
    end
end

function Config:IsDisplayLocked()
    return self.db.displayLocked
end

function Config:SetDisplayLocked(locked)
    self.db.displayLocked = locked and true or false
end

function Config:GetPoint(key)
    return self.db[key]
end

function Config:SetPoint(key, point, relativePoint, x, y)
    self.db[key] = {
        point = point,
        relativePoint = relativePoint,
        x = x,
        y = y,
    }
end

function Config:ResetPositions()
    self.db.displayPoint = DeepCopy(Constants.DEFAULT_DISPLAY_POINT)
    self.db.controlsPoint = DeepCopy(Constants.DEFAULT_CONTROLS_POINT)
end

function Config:GetSize(key)
    return self.db[key]
end

function Config:SetSize(key, width, height)
    self.db[key] = {
        width = width,
        height = height,
    }
end

function Config:GetMinimapSettings()
    return self.db.minimap
end
