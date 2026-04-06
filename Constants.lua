local ADDON_NAME, ns = ...

ns.Constants = {
    ADDON_NAME = ADDON_NAME,
    ADDON_PREFIX = "DeathDirge",
    SLASH_ALIASES = {
        "/ddc",
        "/deathdirge",
    },
    MODES = {
        NORMAL = "normal",
        HEROIC = "heroic",
    },
    MAX_SEQUENCE = 5,
    NORMAL_SEQUENCE = 3,
    DEFAULT_TIMER_SECONDS = 20,
    DEFAULT_DISPLAY_POINT = {
        point = "TOP",
        relativePoint = "TOP",
        x = 0,
        y = -160,
    },
    DEFAULT_CONTROLS_POINT = {
        point = "TOP",
        relativePoint = "TOP",
        x = 0,
        y = -360,
    },
    TEXTURE_BASE = "Interface\\AddOns\\DeathDirge\\textures\\",
    DISPLAY = {
        frameWidth = 260,
        frameHeight = 230,
        minWidth = 220,
        minHeight = 190,
        bossSize = 72,
        tankSize = 38,
        symbolSize = 32,
    },
    CONTROLS = {
        frameWidth = 420,
        frameHeight = 240,
        minWidth = 360,
        minHeight = 220,
        padding = 12,
        topButtonWidth = 58,
        modeButtonHeight = 22,
        actionButtonWidth = 70,
        actionButtonHeight = 26,
        symbolButtonHeight = 28,
    },
    TEXTURES = {
        boss = "Interface\\AddOns\\DeathDirge\\textures\\boss",
        tank = "Interface\\AddOns\\DeathDirge\\textures\\tank",
        symbols = {
            [1] = "Interface\\AddOns\\DeathDirge\\textures\\X",
            [2] = "Interface\\AddOns\\DeathDirge\\textures\\Triangle",
            [3] = "Interface\\AddOns\\DeathDirge\\textures\\T",
            [4] = "Interface\\AddOns\\DeathDirge\\textures\\Circle",
            [5] = "Interface\\AddOns\\DeathDirge\\textures\\Diamond",
        },
        labels = {
            [1] = "X",
            [2] = "Triangle",
            [3] = "T",
            [4] = "Circle",
            [5] = "Diamond",
        },
    },
    LAYOUTS = {
        normal = {
            tank = { x = 0, y = 58 },
            seq = {
                { x = 58, y = 0 },
                { x = 0, y = -58 },
                { x = -58, y = 0 },
            },
        },
        heroic = {
            tank = { x = 0, y = 64 },
            seq = {
                { x = 72, y = 0 },
                { x = 54, y = -50 },
                { x = 0, y = -68 },
                { x = -54, y = -50 },
                { x = -72, y = 0 },
            },
        },
    },
}
