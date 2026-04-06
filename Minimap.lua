local _, ns = ...

local MinimapButton = {}
ns.MinimapButton = MinimapButton

local function UpdatePosition(button)
    local settings = ns.Config:GetMinimapSettings()
    local angle = math.rad(settings.angle or 220)
    local radius = 78
    local x = math.cos(angle) * radius
    local y = math.sin(angle) * radius

    button:ClearAllPoints()
    button:SetPoint("CENTER", Minimap, "CENTER", x, y)
end

function MinimapButton:Initialize()
    local button = CreateFrame("Button", "DeathDirgeMinimapButton", Minimap)
    button:SetSize(32, 32)
    button:SetFrameStrata("MEDIUM")
    button:SetMovable(true)
    button:SetClampedToScreen(true)
    button:RegisterForClicks("LeftButtonUp", "RightButtonUp")
    button:RegisterForDrag("LeftButton")

    button:SetHighlightTexture("Interface\\Minimap\\UI-Minimap-ZoomButton-Highlight")

    button.border = button:CreateTexture(nil, "OVERLAY")
    button.border:SetSize(54, 54)
    button.border:SetTexture("Interface\\Minimap\\MiniMap-TrackingBorder")
    button.border:SetPoint("TOPLEFT")

    button.background = button:CreateTexture(nil, "BACKGROUND")
    button.background:SetSize(20, 20)
    button.background:SetTexture("Interface\\Minimap\\UI-Minimap-Background")
    button.background:SetPoint("CENTER")

    button.icon = button:CreateTexture(nil, "ARTWORK")
    button.icon:SetSize(18, 18)
    button.icon:SetTexture(ns.Constants.TEXTURES.boss)
    button.icon:SetTexCoord(0.08, 0.92, 0.08, 0.92)
    button.icon:SetPoint("CENTER")

    button:SetScript("OnEnter", function(current)
        GameTooltip:SetOwner(current, "ANCHOR_LEFT")
        GameTooltip:AddLine("Death's Dirge Caller")
        GameTooltip:AddLine("Left-click: show/hide caller panel", 0.8, 0.8, 0.8)
        GameTooltip:AddLine("Right-click: lock/unlock frames", 0.8, 0.8, 0.8)
        GameTooltip:AddLine("Drag: move minimap icon", 0.8, 0.8, 0.8)
        GameTooltip:Show()
    end)

    button:SetScript("OnLeave", function()
        GameTooltip:Hide()
    end)

    button:SetScript("OnClick", function(_, mouseButton)
        if mouseButton == "LeftButton" then
            ns.Core:ToggleAddonUI()
        else
            ns.Core:SetFramesLocked(not ns.Config:IsDisplayLocked())
        end
    end)

    button:SetScript("OnDragStart", function(current)
        current:SetScript("OnUpdate", function(self)
            local cursorX, cursorY = GetCursorPosition()
            local scale = Minimap:GetEffectiveScale()
            local centerX, centerY = Minimap:GetCenter()
            local offsetX = cursorX / scale - centerX
            local offsetY = cursorY / scale - centerY
            local angle = math.deg(math.atan2(offsetY, offsetX))
            ns.Config:GetMinimapSettings().angle = angle
            UpdatePosition(self)
        end)
    end)

    button:SetScript("OnDragStop", function(current)
        current:SetScript("OnUpdate", nil)
    end)

    self.button = button
    UpdatePosition(button)

    if ns.Config:GetMinimapSettings().hidden then
        button:Hide()
    end
end
