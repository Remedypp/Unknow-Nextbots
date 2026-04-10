if not CLIENT then return end
local FONT_PATH_TERROR = "resource/fonts/who asks satan.ttf"
local FALLBACK          = "Roboto-Regular"
local fontsCreated = false
local function CreateFonts()
    if fontsCreated then return end
    local useTerror = file.Exists(FONT_PATH_TERROR, "GAME")
    local terrorFont = useTerror and "who asks satan" or FALLBACK
    local fonts = {
        { name = "TerrorFonts",          size = 48, weight = 500 },
        { name = "TerrorFonts_Large",    size = 60, weight = 800, shadow = true },
        { name = "TerrorFonts_Small",    size = 24, weight = 500 },
        { name = "TerrorFonts_Medium",   size = 48, weight = 600 },
        { name = "UNKNOW_Message_Font",  size = 18, weight = 800 },
        { name = "UNKNOW_Scoreboard_Font", size = 20, weight = 500, shadow = true },
    }
    for _, cfg in ipairs(fonts) do
        surface.CreateFont(cfg.name, {
            font      = terrorFont,
            size      = cfg.size,
            weight    = cfg.weight,
            antialias = true,
            shadow    = cfg.shadow or false,
        })
    end
    fontsCreated = true
end
hook.Add("Initialize", "REWORK_CreateFonts", CreateFonts)
hook.Add("HUDPaint", "REWORK_EnsureFonts", function()
    if not fontsCreated then
        CreateFonts()
    else
        hook.Remove("HUDPaint", "REWORK_EnsureFonts")
    end
end)
