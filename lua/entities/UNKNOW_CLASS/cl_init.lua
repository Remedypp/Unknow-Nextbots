include("shared.lua")
VOIDTERM = VOIDTERM or {}
include("voidterm/crt_effects.lua")
include("voidterm/beep.lua")
include("voidterm/defaults.lua")
include("voidterm/filesystem.lua")
include("voidterm/graphics.lua")
include("voidterm/drawille.lua")
include("voidterm/game.lua")
include("voidterm/commands.lua")
include("voidterm/input.lua")
include("voidterm/experiments.lua")
local inputs = {}
local SOUNDS = {
    BOOT = "Unknow_Computer/pcbooting.mp3",
    SWITCH_ON = "Unknow_Computer/switchon.mp3",
    SWITCH_OFF = "Unknow_Computer/switchoff.mp3",
    CLICK = "Unknow_Computer/click_mouse.mp3",
    INPUT = "Unknow_Computer/input.mp3",
    INPUT1 = "Unknow_Computer/input1.mp3",
    INPUT2 = "Unknow_Computer/input2.mp3",
    NOTIFICATION = "Unknow_Computer/notification.mp3",
    ERROR = "Unknow_Computer/Error.mp3",
    AMBIENT = "Unknow_Computer/background_computer.mp3",
    CODE_ON = "Unknow_Computer/Code_ON.mp3",
}
local ambientSound = nil
local function PlaySound(soundName, volume, pitch)
    if SOUNDS[soundName] and GSoundSystem and GSoundSystem.playsoundlocal2 then
        GSoundSystem.playsoundlocal2(SOUNDS[soundName], volume or 1.0, pitch or 100, 1.0)
    end
end
local function StartAmbientSound()
    if ambientSound and IsValid(ambientSound) then return end
    local fullPath = "sound/" .. SOUNDS.AMBIENT
    sound.PlayFile(fullPath, "noblock", function(station)
        if IsValid(station) then
            ambientSound = station
            station:SetVolume(0.3)
            station:EnableLooping(true)
            station:Play()
        end
    end)
end
local function StopAmbientSound()
    if ambientSound and IsValid(ambientSound) then
        ambientSound:Stop()
        ambientSound = nil
    end
end
surface.CreateFont("Petrov_Title", {
    font = "VT323",
    size = 18,
    weight = 400,
    antialias = false
})
surface.CreateFont("Petrov_Header", {
    font = "VT323",
    size = 30,
    weight = 400,
    antialias = false
})
surface.CreateFont("Petrov_Tab", {
    font = "VT323",
    size = 20,
    weight = 400,
    antialias = false
})
surface.CreateFont("Petrov_Console", {
    font = "VT323",
    size = 20,
    weight = 400,
    antialias = false
})
surface.CreateFont("Petrov_Small", {
    font = "VT323",
    size = 16,
    weight = 400,
    antialias = false
})
local COLORS = {
    BG = Color(0, 0, 0),
    BG_LIGHT = Color(5, 20, 10),
    PRIMARY = Color(12, 204, 104),
    PRIMARY_DIM = Color(5, 100, 50),
    TEXT = Color(12, 204, 104),
    TEXT_DIM = Color(5, 100, 50),
    ACCENT = Color(20, 230, 120),
    SUCCESS = Color(12, 204, 104),
}
local ASCII_LOGO = {
    "__      __  ____   _____  _____   _______  ______  _____   __  __ ",
    "\\ \\    / / / __ \\ |_   _||  __ \\ |__   __||  ____||  __ \\ |  \\/  |",
    " \\ \\  / / | |  | |  | |  | |  | |   | |   | |__   | |__) || \\  / |",
    "  \\ \\/ /  | |  | |  | |  | |  | |   | |   |  __|  |  _  / | |\\/| |",
    "   \\  /   | |__| | _| |_ | |__| |   | |   | |____ | | \\ \\ | |  | |",
    "    \\/     \\____/ |_____||_____/    |_|   |______||_|  \\_\\|_|  |_|",
}
local menuState = {
    screen = "power_on",
    currentTab = "CONSOLE",
    consoleLines = {},
    scrollOffset = 0,
    powerOnTime = 0,
    bootPhase = 0,
    hexLines = {},
    soundPlayed = {},
    bootStartTime = 0,
    bootLines = {},
    commandHistory = {},
    historyIndex = 0,
    pressedKeys = {},
    graphicsMode = false,
    graphicsBuffer = {},
    graphicsWidth = 40,
    graphicsHeight = 25,
    particles = {},
    codeUnlocked = false,
    codeEntry = nil,
    horrorRedAlpha = 0,
    fileSelection = 1,
    viewingFile = nil,
    logsUnlocked = false,
    logsConnecting = false,
    logsConnectStart = 0,
    logsConnected = false,
    logsScrollOffset = 0,
    selectedExperiment = 1,
    files = {
        {name="blood_analysis_1991.dat", content="[REDACTED ARCHIVE]"},
        {name="project_ares_brief.doc", content="[REDACTED ARCHIVE]"},
        {name="subject_893_viris.dat", content="[REDACTED ARCHIVE]"},
        {name="subject_901_hide.dat", content="[REDACTED ARCHIVE]"},
        {name="subject_887_consumer.dat", content="[REDACTED ARCHIVE]"},
        {name="subject_915_smert.dat", content="[REDACTED ARCHIVE]"},
        {name="subject_850_vomat.dat", content="[REDACTED ARCHIVE]"},
        {name="subject_009_hinn.dat", content="[REDACTED ARCHIVE]"},
    }
}
local TABS = {"CONSOLE", "CODE", "FILES", "EXPERIMENTS", "LOGS"}
local currentFrame = nil
local BOOT_MESSAGES = {
    {0.0, "BIOS ROM v1.43 (c) 1985 Petrov Systems", COLORS.PRIMARY},
    {0.3, "Memory Test: 4096KB OK", COLORS.TEXT},
    {0.6, "Detecting Primary Hard Drive... OK", COLORS.TEXT},
    {0.9, "Loading VOIDTERM v2.43...", COLORS.TEXT},
    {1.3, "", COLORS.TEXT},
    {1.5, "Initializing kernel...", COLORS.TEXT_DIM},
    {1.8, "Loading drivers...", COLORS.TEXT_DIM},
    {2.1, "Mounting encrypted volumes...", COLORS.TEXT_DIM},
    {2.5, "Verifying user credentials...", COLORS.TEXT_DIM},
    {2.9, "", COLORS.TEXT},
    {3.1, "ACCESS GRANTED", COLORS.SUCCESS},
    {3.3, "Welcome back, Dr. Petrov", COLORS.PRIMARY},
    {3.6, "", COLORS.TEXT},
}
local function addConsoleLine(text, color)
    table.insert(menuState.consoleLines, {text = text, color = color or COLORS.TEXT, time = CurTime()})
    if #menuState.consoleLines > 100 then
        table.remove(menuState.consoleLines, 1)
    end
    menuState.scrollOffset = 0
end
local function clearConsole()
    menuState.consoleLines = {}
    menuState.scrollOffset = 0
end
local function setConsoleLine(y, text, color)
    while #menuState.consoleLines < y do
        table.insert(menuState.consoleLines, {text = "", color = COLORS.TEXT, time = CurTime()})
    end
    if menuState.consoleLines[y] then
        menuState.consoleLines[y].text = text
        if color then menuState.consoleLines[y].color = color end
    end
end
function VOIDTERM.ClearConsole()
    clearConsole()
end
function VOIDTERM.CloseMenu()
    if IsValid(currentFrame) then
        currentFrame:Close()
    end
end
if VOIDTERM.Commands then
    VOIDTERM.Commands.SetColors(COLORS)
    VOIDTERM.Commands.SetConsoleCallback(addConsoleLine)
    VOIDTERM.Commands.SetClearCallback(clearConsole)
    VOIDTERM.Commands.SetLineCallback(setConsoleLine)
    VOIDTERM.Commands.SetState(menuState)
    if VOIDTERM.Graphics and VOIDTERM.Graphics.Init then
        VOIDTERM.Graphics.Init(menuState)
    end
end
local function InitConsole()
    menuState.consoleLines = {}
    addConsoleLine("============================================", COLORS.PRIMARY_DIM)
    addConsoleLine("", COLORS.TEXT)
    addConsoleLine("> Welcome back, Dr. Petrov", COLORS.SUCCESS)
    addConsoleLine("> System initialized", COLORS.TEXT)
    addConsoleLine("> Last session: 1991-XX-XX [DATA INCOMPLETE]", COLORS.TEXT_DIM)
    addConsoleLine("", COLORS.TEXT)
    addConsoleLine("> Type ? for commands", COLORS.TEXT_DIM)
    addConsoleLine("", COLORS.TEXT)
end
local function DrawBootScreen(frame, x, y, w, h)
    local elapsed = CurTime() - menuState.bootStartTime
    surface.SetFont("Petrov_Console")
    local lineH = 18
    local startY = y + 30
    local linesToShow = {}
    for _, msg in ipairs(BOOT_MESSAGES) do
        if elapsed >= msg[1] then
            table.insert(linesToShow, {text = msg[2], color = msg[3]})
        end
    end
    for i, line in ipairs(linesToShow) do
        surface.SetTextColor(line.color)
        surface.SetTextPos(x + 20, startY + (i-1) * lineH)
        surface.DrawText(line.text)
    end
    if #linesToShow > 0 and math.floor(CurTime() * 2) % 2 == 0 then
        local lastLine = linesToShow[#linesToShow]
        local tw = surface.GetTextSize(lastLine.text)
        surface.SetTextColor(COLORS.PRIMARY)
        surface.SetTextPos(x + 20 + tw + 5, startY + (#linesToShow - 1) * lineH)
        surface.DrawText("_")
    end
    local bootDuration = 4.0
    local progress = math.min(1, elapsed / bootDuration)
    local barW = w - 40
    local barH = 8
    local barX = x + 20
    local barY = y + h - 50
    surface.SetDrawColor(COLORS.BG_LIGHT)
    surface.DrawRect(barX, barY, barW, barH)
    surface.SetDrawColor(COLORS.PRIMARY)
    surface.DrawRect(barX, barY, barW * progress, barH)
    surface.SetDrawColor(COLORS.PRIMARY_DIM)
    surface.DrawOutlinedRect(barX, barY, barW, barH)
    if elapsed >= bootDuration then
        menuState.screen = "computer"
        InitConsole()
    end
end
local function DrawPowerOnAnim(frame, x, y, w, h)
    local elapsed = CurTime() - menuState.powerOnTime
    surface.SetFont("Petrov_Console")
    local lineH = 16
    if elapsed < 2.5 then
        local lines = {
            "PETROV RESEARCH SYSTEMS BIOS v2.4",
            "COPYRIGHT (C) 1985-2010",
            "--------------------------------",
            "CPU: UNKNOW-86 @ 12MHz ..... OK",
        }
        local ramProgress = math.min(1, elapsed / 1.5)
        local currentRam = math.floor(4096 * ramProgress)
        table.insert(lines, "RAM: " .. currentRam .. "KB CHECKING...")
        if elapsed < 1.5 and math.floor(elapsed * 20) % 2 == 0 then
             if VOIDTERM.Beep and VOIDTERM.Beep.Play then
                VOIDTERM.Beep.Play(1000 + math.random(-50, 50), 30)
             end
        end
        if elapsed > 1.5 then
            lines[#lines] = "RAM: 4096KB ................ OK"
            table.insert(lines, "BIO-INTERFACE .............. INITIALIZED")
            table.insert(lines, "LOADING KERNEL ............. DONE")
            if not menuState.soundPlayed["bios_ok"] then
                if VOIDTERM.Beep and VOIDTERM.Beep.Play then
                    VOIDTERM.Beep.Play(2000, 100)
                end
                menuState.soundPlayed["bios_ok"] = true
            end
        end
        for i, line in ipairs(lines) do
            surface.SetTextColor(COLORS.PRIMARY)
            surface.SetTextPos(x + 20, y + 20 + (i-1) * lineH)
            surface.DrawText(line)
        end
        if math.floor(CurTime() * 4) % 2 == 0 then
            surface.SetDrawColor(COLORS.PRIMARY)
            surface.DrawRect(x + 20, y + 20 + #lines * lineH, 10, 16)
        end
    elseif elapsed < 3.5 then
        local logoY = y + 80
        local centerX = x + w/2
        local logoProgress = (elapsed - 2.5) / 0.5
        local visibleChars = math.floor(#ASCII_LOGO[1] * logoProgress)
        for i, line in ipairs(ASCII_LOGO) do
            local subLine = string.sub(line, 1, visibleChars)
            local tw = surface.GetTextSize(line)
            surface.SetTextColor(COLORS.PRIMARY)
            surface.SetTextPos(centerX - tw/2, logoY + (i-1) * 14)
            surface.DrawText(subLine)
        end
        if not menuState.soundPlayed["logo_burst"] then
            if VOIDTERM.Beep and VOIDTERM.Beep.PlaySequence then
                local notes = {
                    {freq=800, dur=50}, {freq=1000, dur=50}, {freq=1200, dur=50},
                    {freq=1500, dur=50}, {freq=2000, dur=100}
                }
                VOIDTERM.Beep.PlaySequence(notes, 0.05)
            end
            menuState.soundPlayed["logo_burst"] = true
        end
    else
        menuState.screen = "login"
        if VOIDTERM.Beep and VOIDTERM.Beep.PlaySequence then
            VOIDTERM.Beep.PlaySequence({{freq=1500, dur=100}, {freq=2500, dur=300}}, 0.1)
        end
    end
end
local function DrawLoginScreen(frame, x, y, w, h)
    surface.SetDrawColor(15, 22, 15, 40)
    for gx = x, x + w, 40 do
        surface.DrawRect(gx, y, 1, h)
    end
    for gy = y, y + h, 40 do
        surface.DrawRect(x, gy, w, 1)
    end
    surface.SetFont("Petrov_Console")
    local logoY = y + 80
    local centerX = x + w/2
    for i, line in ipairs(ASCII_LOGO) do
        local tw = surface.GetTextSize(line)
        surface.SetTextColor(COLORS.PRIMARY)
        surface.SetTextPos(centerX - tw/2, logoY + (i-1) * 14)
        surface.DrawText(line)
    end
    local infoY = logoY + #ASCII_LOGO * 14 + 50
    surface.SetFont("Petrov_Title")
    local sessionText = "SESSION: Dr. Viktor Petrov"
    local stw = surface.GetTextSize(sessionText)
    surface.SetTextColor(COLORS.TEXT)
    surface.SetTextPos(centerX - stw/2, infoY)
    surface.DrawText(sessionText)
    local statusText = "STATUS: AWAITING AUTHENTICATION"
    local sttw = surface.GetTextSize(statusText)
    surface.SetTextColor(COLORS.PRIMARY)
    surface.SetTextPos(centerX - sttw/2, infoY + 25)
    surface.DrawText(statusText)
    surface.SetFont("Petrov_Title")
    surface.SetTextColor(COLORS.PRIMARY)
    surface.SetTextPos(225, 324)
    surface.DrawText("> Password:")
    if frame.passEntry then
        local peX, peY = 225, 349
        local peW, peH = 220, 30
        local active = frame.passEntry:HasFocus()
        surface.SetDrawColor(COLORS.PRIMARY_DIM)
        surface.DrawOutlinedRect(peX, peY, peW, peH)
        if active then
            surface.SetDrawColor(COLORS.PRIMARY)
            surface.DrawRect(peX, peY + peH - 2, peW, 2)
        end
        surface.SetFont("Petrov_Console")
        surface.SetTextColor(COLORS.PRIMARY)
        local txt = string.rep("*", #frame.passEntry:GetValue())
        surface.SetTextPos(peX + 5, peY + 5)
        surface.DrawText(txt)
        if active and math.floor(CurTime()*2)%2==0 then
            local tw = surface.GetTextSize(txt)
            surface.DrawRect(peX + 5 + tw, peY + 5, 10, 20)
        end
    end
    if frame.loginBtn then
        local btnX, btnY = 460, 349
        local btnW, btnH = 80, 30
        local hover = frame.loginBtn:IsHovered()
        if hover then
            surface.SetDrawColor(COLORS.PRIMARY)
            surface.DrawRect(btnX, btnY, btnW, btnH)
        else
            surface.SetDrawColor(COLORS.PRIMARY_DIM)
            surface.DrawOutlinedRect(btnX, btnY, btnW, btnH)
        end
        local txtColor = hover and COLORS.BG or COLORS.PRIMARY
        draw.SimpleText("[LOGIN]", "Petrov_Tab", btnX + btnW/2, btnY + btnH/2, txtColor, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
    end
    local lastText = "LAST ACCESS: [DATA CORRUPTED]"
    local ltw = surface.GetTextSize(lastText)
    surface.SetTextColor(COLORS.TEXT_DIM)
    surface.SetTextPos(centerX - ltw/2, y + h - 40)
    surface.DrawText(lastText)
end
local function DrawComputerScreen(frame, sx, sy, w, h)
    surface.SetDrawColor(COLORS.BG_LIGHT)
    surface.DrawRect(sx, sy, w, 35)
    surface.SetFont("Petrov_Title")
    surface.SetTextColor(COLORS.PRIMARY)
    surface.SetTextPos(sx + 10, sy + 10)
    surface.DrawText("VOIDTERM v2.43")
    local tabY = sy + 40
    local tabH = 26
    local tabGap = 4
    local tabPad = 16
    local curX = sx + 10
    surface.SetFont("Petrov_Tab")
    menuState.tabHitboxes = {}
    for i, tabName in ipairs(TABS) do
        local isActive = menuState.currentTab == tabName
        local ttw = surface.GetTextSize(tabName)
        local tabW = ttw + tabPad
        menuState.tabHitboxes[i] = { x = curX - sx, y = tabY - sy, w = tabW, h = tabH, name = tabName }
        if isActive then
            surface.SetDrawColor(COLORS.BG_LIGHT)
        else
            surface.SetDrawColor(COLORS.BG)
        end
        surface.DrawRect(curX, tabY, tabW, tabH)
        surface.SetDrawColor(isActive and COLORS.PRIMARY or COLORS.PRIMARY_DIM)
        surface.DrawOutlinedRect(curX, tabY, tabW, tabH)
        if isActive then
            surface.SetDrawColor(COLORS.PRIMARY)
            surface.DrawRect(curX, tabY + tabH - 2, tabW, 2)
        end
        surface.SetTextColor(isActive and COLORS.PRIMARY or COLORS.TEXT_DIM)
        surface.SetTextPos(curX + tabPad/2, tabY + 5)
        surface.DrawText(tabName)
        curX = curX + tabW + tabGap
    end
    local contentY = tabY + tabH + 8
    local contentH = h - (contentY - sy) - 35
    surface.SetDrawColor(COLORS.BG_LIGHT)
    surface.DrawRect(sx + 10, contentY, w - 20, contentH)
    surface.SetDrawColor(COLORS.PRIMARY_DIM)
    surface.DrawOutlinedRect(sx + 10, contentY, w - 20, contentH)
    if menuState.currentTab == "CONSOLE" then
        local isGameGraphics = VOIDTERM.Game and VOIDTERM.Game.IsRunning and VOIDTERM.Game.IsRunning() and VOIDTERM.Game.IsGraphicsMode and VOIDTERM.Game.IsGraphicsMode()
        if isGameGraphics and VOIDTERM.Graphics then
            local buffer, gw, gh = VOIDTERM.Graphics.GetBuffer()
            gw = gw or 160
            gh = gh or 100
            local gridWidth = w - 40
            local gridHeight = contentH - 20
            local scaleX = gridWidth / gw
            local scaleY = gridHeight / gh
            local scale = math.min(scaleX, scaleY)
            local totalW = math.floor(gw * scale)
            local totalH = math.floor(gh * scale)
            local gridX = sx + math.floor((w - totalW) / 2)
            local gridY = contentY + math.floor((contentH - totalH) / 2)
            if VOIDTERM.Graphics.SetRenderArea then
                VOIDTERM.Graphics.SetRenderArea(gridX, gridY, totalW, totalH)
            end
            surface.SetDrawColor(0, 0, 0, 255)
            surface.DrawRect(gridX, gridY, totalW, totalH)
            if buffer then
                local pixW = math.ceil(scale)
                local pixH = math.ceil(scale)
                for i = 1, gw * gh do
                    local color = buffer[i]
                    if color and color.r and color.g and color.b then
                        local bx = (i - 1) % gw
                        local by = math.floor((i - 1) / gw)
                        local px = gridX + math.floor(bx * scale)
                        local py = gridY + math.floor(by * scale)
                        surface.SetDrawColor(color.r, color.g, color.b, color.a or 255)
                        surface.DrawRect(px, py, pixW, pixH)
                    end
                end
            end
            surface.SetDrawColor(COLORS.PRIMARY_DIM)
            surface.DrawOutlinedRect(gridX - 1, gridY - 1, totalW + 2, totalH + 2)
            surface.SetFont("Petrov_Tab")
            surface.SetTextColor(COLORS.ACCENT)
            surface.SetTextPos(sx + w - 100, sy + 25)
            surface.DrawText("[TAB] STOP")
        elseif VOIDTERM.Game and VOIDTERM.Game.IsRunning and VOIDTERM.Game.IsRunning() then
            surface.SetFont("Petrov_Console")
            surface.SetTextColor(COLORS.PRIMARY)
            surface.SetTextPos(sx + 20, contentY + 20)
            surface.DrawText("VOIDLANG script executing...")
            surface.SetTextColor(COLORS.ACCENT)
            surface.SetTextPos(sx + 20, contentY + 45)
            surface.DrawText("[TAB] Stop execution")
        else
            local lineH = 18
            local availableH = contentH - 50
            local maxLines = math.floor(availableH / lineH)
            local totalLines = #menuState.consoleLines
            local endLine = math.max(0, totalLines - menuState.scrollOffset)
            local startLine = math.max(1, endLine - maxLines + 1)
            local yPos = contentY + 10
            for i = startLine, endLine do
                local line = menuState.consoleLines[i]
                if line then
                    if yPos + lineH > contentY + contentH - 40 then break end
                    surface.SetTextColor(line.color)
                    surface.SetTextPos(sx + 20, yPos)
                    surface.DrawText(line.text)
                    yPos = yPos + lineH
                end
            end
            local inputY = contentY + contentH - 30
            surface.SetDrawColor(COLORS.PRIMARY_DIM)
            surface.DrawLine(sx + 20, inputY - 5, sx + w - 20, inputY - 5)
            surface.SetTextColor(COLORS.PRIMARY)
            surface.SetTextPos(sx + 20, inputY)
            local consoleInput = VOIDTERM.Input.consoleEntry
            surface.DrawText("> " .. (consoleInput and consoleInput:GetValue() or ""))
            if consoleInput and consoleInput:HasFocus() and math.floor(CurTime() * 2) % 2 == 0 then
                local txt = consoleInput:GetValue()
                local caretPos = consoleInput:GetCaretPos()
                local beforeCaret = txt:sub(1, caretPos)
                local tw, th = surface.GetTextSize("> " .. beforeCaret)
                surface.DrawRect(sx + 20 + tw, inputY + 2, 10, 16)
            end
        end
    elseif menuState.currentTab == "CODE" then
        surface.SetDrawColor(0, 0, 0, 255)
        surface.DrawRect(sx + 10, contentY, w - 20, contentH)
        if #menuState.particles == 0 then
            for i = 1, 50 do
                table.insert(menuState.particles, {
                    x = math.random(0, w - 20),
                    y = math.random(0, contentH),
                    speed = math.random(10, 30),
                    size = math.random(1, 2)
                })
            end
        end
        surface.SetDrawColor(255, 255, 255, 150)
        for _, p in ipairs(menuState.particles) do
            p.y = p.y + p.speed * FrameTime()
            if p.y > contentH then p.y = 0 end
            surface.DrawRect(sx + 10 + p.x, contentY + p.y, p.size, p.size)
        end
        if menuState.codeMessage and menuState.codeMessageTime then
            local msgAge = CurTime() - menuState.codeMessageTime
            if msgAge < 2.5 then
                local msgAlpha = math.floor(255 * math.max(0, 1 - (msgAge / 2.5)))
                if menuState.codeMessageSuccess then
                    surface.SetTextColor(0, 200, 80, msgAlpha)
                else
                    surface.SetTextColor(200, 50, 50, msgAlpha)
                end
                surface.SetFont("Petrov_Console")
                surface.SetTextPos(sx + 40, contentY + 80)
                surface.DrawText("> " .. menuState.codeMessage)
            else
                menuState.codeMessage = nil
            end
        end
        surface.SetFont("Petrov_Console")
        surface.SetTextColor(255, 255, 255)
        surface.SetTextPos(sx + 40, contentY + 100)
        surface.DrawText("ENTER AUTHORIZATION CODE:")
        surface.SetDrawColor(255, 255, 255)
        surface.DrawOutlinedRect(sx + 40, contentY + 130, 200, 30)
        local codeInput = VOIDTERM.Input.codeEntry
        if codeInput then
            local codeText = string.rep("*", #codeInput:GetValue())
            surface.SetFont("Petrov_Console")
            surface.SetTextColor(255, 255, 255)
            surface.SetTextPos(sx + 45, contentY + 135)
            surface.DrawText(codeText)
            if codeInput:HasFocus() and math.floor(CurTime() * 2) % 2 == 0 then
                local caretPos = codeInput:GetCaretPos()
                local beforeCaret = string.rep("*", math.min(caretPos, #codeInput:GetValue()))
                local tw = surface.GetTextSize(beforeCaret)
                surface.SetDrawColor(255, 255, 255)
                surface.DrawRect(sx + 45 + tw, contentY + 135, 10, 18)
            end
        end
    elseif menuState.currentTab == "FILES" then
        surface.SetFont("Petrov_Console")
        if menuState.viewingFile then
            surface.SetTextColor(COLORS.PRIMARY)
            surface.SetTextPos(sx + 20, contentY + 10)
            surface.DrawText("VIEWING: " .. menuState.viewingFile.name)
            local boxY = contentY + 35
            local boxH = contentH - 70
            surface.SetDrawColor(COLORS.PRIMARY_DIM)
            surface.DrawOutlinedRect(sx + 15, boxY, w - 30, boxH)
            local lines = string.Explode("\n", menuState.viewingFile.content)
            local lineH = 18
            local maxVisibleLines = math.floor(boxH / lineH) - 1
            menuState.fileScrollOffset = menuState.fileScrollOffset or 0
            local maxScroll = math.max(0, #lines - maxVisibleLines)
            menuState.fileScrollOffset = math.Clamp(menuState.fileScrollOffset, 0, maxScroll)
            local startLine = menuState.fileScrollOffset + 1
            local endLine = math.min(#lines, startLine + maxVisibleLines - 1)
            surface.SetFont("Petrov_Console")
            surface.SetTextColor(COLORS.TEXT)
            for i = startLine, endLine do
                local yPos = boxY + 5 + (i - startLine) * lineH
                if yPos + lineH < boxY + boxH then
                    surface.SetTextPos(sx + 25, yPos)
                    surface.DrawText(lines[i] or "")
                end
            end
            if #lines > maxVisibleLines then
                local scrollPct = menuState.fileScrollOffset / maxScroll
                local barH = math.max(20, boxH * (maxVisibleLines / #lines))
                local barY = boxY + scrollPct * (boxH - barH)
                surface.SetDrawColor(COLORS.PRIMARY_DIM)
                surface.DrawRect(sx + w - 20, barY, 4, barH)
            end
            surface.SetTextColor(COLORS.ACCENT)
            surface.SetTextPos(sx + 20, contentY + contentH - 20)
            surface.DrawText("[BACKSPACE] RETURN  [UP/DOWN] SCROLL")
        else
            surface.SetTextColor(COLORS.TEXT_DIM)
            surface.SetTextPos(sx + 20, contentY + 10)
            surface.DrawText("/research/ (Use UP/DOWN/ENTER)")
            local fileItemH = 20
            local listY = contentY + 30
            local listH = contentH - 50
            local maxVisible = math.floor(listH / fileItemH)
            local fileCount = #menuState.files
            menuState.fileListScroll = menuState.fileListScroll or 0
            local sel = menuState.fileSelection or 1
            if sel - 1 < menuState.fileListScroll then
                menuState.fileListScroll = sel - 1
            elseif sel > menuState.fileListScroll + maxVisible then
                menuState.fileListScroll = sel - maxVisible
            end
            menuState.fileListScroll = math.Clamp(menuState.fileListScroll, 0, math.max(0, fileCount - maxVisible))
            local startIdx = menuState.fileListScroll + 1
            local endIdx = math.min(fileCount, startIdx + maxVisible - 1)
            for idx = startIdx, endIdx do
                local f = menuState.files[idx]
                local drawIdx = idx - startIdx
                local fy = listY + drawIdx * fileItemH
                local isSelected = (idx == sel)
                if isSelected then
                    surface.SetDrawColor(COLORS.PRIMARY_DIM)
                    surface.DrawRect(sx + 20, fy, w - 40, fileItemH)
                    surface.SetTextColor(COLORS.BG)
                else
                    surface.SetTextColor(COLORS.TEXT)
                end
                surface.SetTextPos(sx + 25, fy + 2)
                surface.DrawText((isSelected and "> " or "  ") .. f)
            end
            if fileCount > maxVisible then
                local scrollFrac = menuState.fileListScroll / math.max(1, fileCount - maxVisible)
                local barH = math.max(20, listH * (maxVisible / fileCount))
                local barY = listY + scrollFrac * (listH - barH)
                surface.SetDrawColor(COLORS.PRIMARY_DIM)
                surface.DrawRect(sx + w - 22, barY, 4, barH)
            end
        end
    elseif menuState.currentTab == "EXPERIMENTS" then
        if VOIDTERM.Experiments and VOIDTERM.Experiments.IsRunning and VOIDTERM.Experiments.IsRunning() then
            VOIDTERM.Experiments.DrawActive(sx + 5, contentY + 5, w - 10, contentH - 10)
        else
            surface.SetFont("Petrov_Console")
            local experiments = VOIDTERM.Experiments and VOIDTERM.Experiments.List or {}
            local sel = menuState.selectedExperiment or 1
            local selExp = experiments[sel]
            local headerH = 38
            surface.SetDrawColor(Color(0, 30, 15, 180))
            surface.DrawRect(sx + 10, contentY + 2, w - 20, headerH)
            surface.SetDrawColor(COLORS.ACCENT)
            surface.DrawOutlinedRect(sx + 10, contentY + 2, w - 20, headerH)
            surface.SetTextColor(COLORS.ACCENT)
            surface.SetTextPos(sx + 18, contentY + 5)
            surface.DrawText("╔ PETROV RESEARCH SYSTEMS")
            surface.SetTextColor(COLORS.PRIMARY)
            surface.SetTextPos(sx + 18, contentY + 20)
            surface.DrawText("║ CLASSIFIED EXPERIMENT DATABASE")
            local countStr = "[" .. #experiments .. " RECORDS]"
            local cw = surface.GetTextSize(countStr)
            surface.SetTextColor(COLORS.TEXT_DIM)
            surface.SetTextPos(sx + w - 28 - cw, contentY + 20)
            surface.DrawText(countStr)
            local detailW = 170
            local listW = w - detailW - 35
            local listX = sx + 12
            local detailX = sx + w - detailW - 14
            local bodyY = contentY + headerH + 6
            local footerH = 34
            local bodyH = contentH - headerH - footerH - 10
            surface.SetDrawColor(Color(0, 20, 12, 150))
            surface.DrawRect(detailX, bodyY, detailW, bodyH)
            surface.SetDrawColor(COLORS.PRIMARY_DIM)
            surface.DrawOutlinedRect(detailX, bodyY, detailW, bodyH)
            surface.SetDrawColor(Color(0, 40, 20, 200))
            surface.DrawRect(detailX + 1, bodyY + 1, detailW - 2, 18)
            surface.SetTextColor(COLORS.PRIMARY)
            surface.SetTextPos(detailX + 6, bodyY + 3)
            surface.DrawText("▸ EXPERIMENT DETAIL")
            if selExp then
                local dy = bodyY + 24
                local stColor = COLORS.SUCCESS
                if selExp.status == "CLASSIFIED" then stColor = COLORS.ACCENT
                elseif selExp.status == "TERMINATED" then stColor = Color(140, 140, 140) end
                surface.SetTextColor(COLORS.TEXT_DIM)
                surface.SetTextPos(detailX + 8, dy)
                surface.DrawText("ID:")
                surface.SetTextColor(COLORS.PRIMARY)
                surface.SetTextPos(detailX + 55, dy)
                surface.DrawText(selExp.id)
                dy = dy + 16
                surface.SetTextColor(COLORS.TEXT_DIM)
                surface.SetTextPos(detailX + 8, dy)
                surface.DrawText("NAME:")
                dy = dy + 14
                surface.SetTextColor(Color(200, 240, 220))
                local nameWords = string.Explode(" ", selExp.name)
                local line = ""
                for _, word in ipairs(nameWords) do
                    local test = line == "" and word or (line .. " " .. word)
                    local tw = surface.GetTextSize(test)
                    if tw > detailW - 20 and line ~= "" then
                        surface.SetTextPos(detailX + 8, dy)
                        surface.DrawText(line)
                        dy = dy + 14
                        line = word
                    else
                        line = test
                    end
                end
                if line ~= "" then
                    surface.SetTextPos(detailX + 8, dy)
                    surface.DrawText(line)
                    dy = dy + 18
                end
                surface.SetTextColor(COLORS.TEXT_DIM)
                surface.SetTextPos(detailX + 8, dy)
                surface.DrawText("STATUS:")
                surface.SetTextColor(stColor)
                surface.SetTextPos(detailX + 75, dy)
                surface.DrawText(selExp.status)
                dy = dy + 16
                surface.SetTextColor(COLORS.TEXT_DIM)
                surface.SetTextPos(detailX + 8, dy)
                surface.DrawText("DATE:")
                surface.SetTextColor(COLORS.TEXT)
                surface.SetTextPos(detailX + 55, dy)
                surface.DrawText(selExp.date or "N/A")
                dy = dy + 20
                surface.SetDrawColor(COLORS.PRIMARY_DIM)
                surface.DrawRect(detailX + 8, dy, detailW - 16, 1)
                dy = dy + 6
                surface.SetTextColor(COLORS.TEXT_DIM)
                surface.SetTextPos(detailX + 8, dy)
                surface.DrawText("DESCRIPTION:")
                dy = dy + 14
                surface.SetTextColor(COLORS.TEXT)
                local descWords = string.Explode(" ", selExp.desc)
                local dline = ""
                for _, word in ipairs(descWords) do
                    local test = dline == "" and word or (dline .. " " .. word)
                    local tw = surface.GetTextSize(test)
                    if tw > detailW - 20 and dline ~= "" then
                        surface.SetTextPos(detailX + 8, dy)
                        surface.DrawText(dline)
                        dy = dy + 14
                        dline = word
                    else
                        dline = test
                    end
                end
                if dline ~= "" then
                    surface.SetTextPos(detailX + 8, dy)
                    surface.DrawText(dline)
                end
                surface.SetDrawColor(stColor)
                surface.DrawRect(detailX + 1, bodyY + bodyH - 4, detailW - 2, 3)
            else
                surface.SetTextColor(COLORS.TEXT_DIM)
                surface.SetTextPos(detailX + 8, bodyY + 30)
                surface.DrawText("No experiment")
                surface.SetTextPos(detailX + 8, bodyY + 44)
                surface.DrawText("selected.")
            end
            local entryH = 22
            local maxVisible = math.floor(bodyH / entryH)
            local expCount = #experiments
            menuState.expListScroll = menuState.expListScroll or 0
            if sel - 1 < menuState.expListScroll then
                menuState.expListScroll = sel - 1
            elseif sel > menuState.expListScroll + maxVisible then
                menuState.expListScroll = sel - maxVisible
            end
            menuState.expListScroll = math.Clamp(menuState.expListScroll, 0, math.max(0, expCount - maxVisible))
            local startIdx = menuState.expListScroll + 1
            local endIdx = math.min(expCount, startIdx + maxVisible - 1)
            for idx = startIdx, endIdx do
                local exp = experiments[idx]
                local drawIdx = idx - startIdx
                local ey = bodyY + drawIdx * entryH
                local isSelected = (idx == sel)
                local stColor = COLORS.SUCCESS
                if exp.status == "CLASSIFIED" then stColor = COLORS.ACCENT
                elseif exp.status == "TERMINATED" then stColor = Color(140, 140, 140) end
                if isSelected then
                    surface.SetDrawColor(Color(0, 60, 30, 180))
                    surface.DrawRect(listX, ey, listW, entryH)
                    surface.SetDrawColor(COLORS.PRIMARY)
                    surface.DrawRect(listX, ey, 3, entryH)
                end
                surface.SetDrawColor(stColor)
                surface.DrawRect(listX + 8, ey + 7, 6, 6)
                surface.SetTextColor(isSelected and COLORS.PRIMARY or COLORS.TEXT_DIM)
                surface.SetTextPos(listX + 20, ey + 3)
                local label = exp.id .. ": " .. exp.name
                local maxTextW = listW - 100
                local tw = surface.GetTextSize(label)
                if tw > maxTextW then
                    while #label > 5 and surface.GetTextSize(label .. "...") > maxTextW do
                        label = label:sub(1, -2)
                    end
                    label = label .. "..."
                end
                surface.DrawText(label)
                local tag = "[" .. exp.status .. "]"
                local tagW = surface.GetTextSize(tag)
                surface.SetTextColor(stColor)
                surface.SetTextPos(listX + listW - tagW - 6, ey + 3)
                surface.DrawText(tag)
                if idx < endIdx then
                    surface.SetDrawColor(Color(0, 40, 20, 80))
                    surface.DrawRect(listX + 6, ey + entryH - 1, listW - 12, 1)
                end
            end
            if expCount > maxVisible then
                local scrollFrac = menuState.expListScroll / math.max(1, expCount - maxVisible)
                local barH = math.max(16, bodyH * (maxVisible / expCount))
                local barY = bodyY + scrollFrac * (bodyH - barH)
                surface.SetDrawColor(COLORS.PRIMARY_DIM)
                surface.DrawRect(listX + listW - 3, barY, 3, barH)
            end
            surface.SetDrawColor(COLORS.PRIMARY_DIM)
            surface.DrawOutlinedRect(listX, bodyY, listW, bodyH)
            local footY = contentY + contentH - footerH
            surface.SetDrawColor(Color(0, 30, 15, 180))
            surface.DrawRect(sx + 10, footY, w - 20, footerH - 2)
            surface.SetDrawColor(COLORS.PRIMARY_DIM)
            surface.DrawOutlinedRect(sx + 10, footY, w - 20, footerH - 2)
            surface.SetTextColor(COLORS.PRIMARY)
            surface.SetTextPos(sx + 18, footY + 4)
            surface.DrawText("▲▼ SELECT  │  ENTER: RUN EXPERIMENT")
            if selExp then
                local selStr = "» " .. selExp.id .. ": " .. selExp.name
                surface.SetTextColor(COLORS.ACCENT)
                surface.SetTextPos(sx + 18, footY + 18)
                surface.DrawText(selStr)
            end
        end
    elseif menuState.currentTab == "LOGS" then
        if not menuState.logsUnlocked then
            surface.SetDrawColor(5, 0, 0, 255)
            surface.DrawRect(sx + 10, contentY, w - 20, contentH)
            for scanY = 0, contentH, 3 do
                surface.SetDrawColor(0, 0, 0, 40)
                surface.DrawRect(sx + 10, contentY + scanY, w - 20, 1)
            end
            local triCX = sx + w/2
            local triCY = contentY + contentH * 0.35
            local triSize = 30
            for i = 0, 2 do
                local a1 = (i / 3) * math.pi * 2 - math.pi / 2
                local a2 = ((i + 1) / 3) * math.pi * 2 - math.pi / 2
                local x1 = triCX + math.cos(a1) * triSize
                local y1 = triCY + math.sin(a1) * triSize
                local x2 = triCX + math.cos(a2) * triSize
                local y2 = triCY + math.sin(a2) * triSize
                surface.SetDrawColor(200, 0, 0, 180)
                surface.DrawLine(x1, y1, x2, y2)
            end
            surface.SetFont("Petrov_Header")
            surface.SetTextColor(200, 0, 0, math.floor(150 + math.sin(CurTime() * 3) * 80))
            local ew = surface.GetTextSize("!")
            surface.SetTextPos(triCX - ew/2, triCY - 16)
            surface.DrawText("!")
            surface.SetFont("Petrov_Header")
            surface.SetTextColor(180, 0, 0, 255)
            local denyMsg = "ACCESS DENIED"
            local dw = surface.GetTextSize(denyMsg)
            surface.SetTextPos(sx + w/2 - dw/2, contentY + contentH * 0.55)
            surface.DrawText(denyMsg)
            surface.SetFont("Petrov_Console")
            surface.SetTextColor(120, 0, 0, 180)
            local msg1 = "AUTHORIZATION REQUIRED"
            local m1w = surface.GetTextSize(msg1)
            surface.SetTextPos(sx + w/2 - m1w/2, contentY + contentH * 0.68)
            surface.DrawText(msg1)
            surface.SetTextColor(80, 80, 80, 150)
            local msg2 = "Enter access code in CODE tab"
            local m2w = surface.GetTextSize(msg2)
            surface.SetTextPos(sx + w/2 - m2w/2, contentY + contentH * 0.76)
            surface.DrawText(msg2)
            if math.floor(CurTime() * 2) % 2 == 0 then
                surface.SetFont("Petrov_Console")
                surface.SetTextColor(80, 0, 0, 100)
                surface.SetTextPos(sx + 20, contentY + contentH - 20)
                surface.DrawText("_")
            end
        elseif menuState.logsConnecting and not menuState.logsConnected then
            local elapsed = CurTime() - menuState.logsConnectStart
            local connectDuration = 4.5
            local progress = math.min(1, elapsed / connectDuration)
            surface.SetDrawColor(2, 5, 3, 255)
            surface.DrawRect(sx + 10, contentY, w - 20, contentH)
            for _ = 1, math.floor(30 * (1 - progress)) do
                local nx = math.random(sx + 15, sx + w - 25)
                local ny = math.random(contentY + 5, contentY + contentH - 5)
                local ns = math.random(1, 3)
                local na = math.random(20, 60)
                surface.SetDrawColor(0, na + 20, na / 2, na)
                surface.DrawRect(nx, ny, ns, ns)
            end
            local messages = {
                {0.0,  "INITIATING SECURE CHANNEL...",      COLORS.PRIMARY},
                {0.5,  "CONNECTING TO: 192.168.66.6:1665",  COLORS.TEXT_DIM},
                {1.0,  "HANDSHAKE: RSA-4096 ...",           COLORS.TEXT_DIM},
                {1.5,  "AUTHENTICATION: TOKEN ACCEPTED",    COLORS.SUCCESS},
                {2.0,  "DECRYPTING ARCHIVE...",             COLORS.PRIMARY},
                {2.5,  "SECTOR 7 CLEARANCE: GRANTED",      Color(200, 150, 0)},
                {3.0,  "LOADING CLASSIFIED DATA...",        COLORS.PRIMARY},
                {3.5,  "INDEXING LOG ENTRIES...",            COLORS.TEXT_DIM},
                {4.0,  "CONNECTION ESTABLISHED",            COLORS.SUCCESS},
            }
            surface.SetFont("Petrov_Console")
            local msgY = contentY + 30
            for _, msg in ipairs(messages) do
                if elapsed >= msg[1] then
                    surface.SetTextColor(msg[3])
                    surface.SetTextPos(sx + 25, msgY)
                    surface.DrawText("> " .. msg[2])
                    msgY = msgY + 18
                    if elapsed >= msg[1] + 0.4 then
                        surface.SetTextColor(COLORS.SUCCESS)
                        surface.SetTextPos(sx + w - 50, msgY - 18)
                        surface.DrawText("[OK]")
                    end
                end
            end
            local barX = sx + 25
            local barY = contentY + contentH - 50
            local barW = w - 60
            local barH = 12
            surface.SetDrawColor(30, 40, 30, 200)
            surface.DrawRect(barX, barY, barW, barH)
            surface.SetDrawColor(0, 180, 80, 200)
            surface.DrawRect(barX + 1, barY + 1, math.floor((barW - 2) * progress), barH - 2)
            surface.SetDrawColor(0, 255, 100, 100)
            surface.DrawOutlinedRect(barX, barY, barW, barH)
            surface.SetFont("Petrov_Console")
            surface.SetTextColor(COLORS.SUCCESS)
            local pctStr = string.format("%d%%", math.floor(progress * 100))
            local pw = surface.GetTextSize(pctStr)
            surface.SetTextPos(barX + barW / 2 - pw / 2, barY - 18)
            surface.DrawText(pctStr)
            if progress >= 1 then
                menuState.logsConnecting = false
                menuState.logsConnected = true
                menuState.logsScrollOffset = 0
            end
        else
            local LOG_ENTRIES = {
                {date="1985-01-10", cat="SYSTEM", color=COLORS.SUCCESS,
                 lines={"[REDACTED LORE]"}},
                {date="1985-01-12", cat="ARCHIVED", color=Color(120, 100, 70),
                 lines={"[REDACTED LORE]"}},
                {date="1985-01-12", cat="ARCHIVED", color=Color(120, 100, 70),
                 lines={"[REDACTED LORE]"}},
                {date="1985-01-12", cat="ARCHIVED", color=Color(120, 100, 70),
                 lines={"[REDACTED LORE]"}},
                {date="1985-01-12", cat="ARCHIVED", color=Color(120, 100, 70),
                 lines={"[REDACTED LORE]"}},
                {date="1985-01-12", cat="ARCHIVED", color=Color(120, 100, 70),
                 lines={"[REDACTED LORE]"}},
                {date="1985-06-XX", cat="EXPERIMENT", color=Color(80, 200, 220),
                 lines={"[REDACTED LORE]"}},
                {date="1986-03-15", cat="PERSONAL", color=Color(220, 180, 50),
                 lines={"[REDACTED LORE]"}},
                {date="1991-02-14", cat="EXPERIMENT", color=Color(80, 200, 220),
                 lines={"[REDACTED LORE]"}},
                {date="1997-08-03", cat="SYSTEM", color=COLORS.SUCCESS,
                 lines={"[REDACTED LORE]"}},
                {date="2003-11-22", cat="EXPERIMENT", color=Color(80, 200, 220),
                 lines={"[REDACTED LORE]"}},
                {date="2008-06-15", cat="EXPERIMENT", color=Color(80, 200, 220),
                 lines={"[REDACTED LORE]"}},
                {date="2008-09-03", cat="EXPERIMENT", color=Color(80, 200, 220),
                 lines={"[REDACTED LORE]"}},
                {date="2009-04-17", cat="EXPERIMENT", color=Color(80, 200, 220),
                 lines={"[REDACTED LORE]"}},
                {date="2009-11-20", cat="MEDICAL", color=Color(180, 100, 220),
                 lines={"[REDACTED LORE]"}},
                {date="2010-01-XX", cat="PERSONAL", color=Color(220, 180, 50),
                 lines={"[REDACTED LORE]"}},
                {date="2010-XX-XX", cat="CLASSIFIED", color=Color(200, 50, 50),
                 lines={"[REDACTED LORE]"}},
                {date="UNDATED", cat="PERSONAL", color=Color(220, 180, 50),
                 lines={"[REDACTED LORE]"}},
                {date="SYSTEM", cat="SYSTEM AUTOLOG", color=Color(200, 50, 50),
                 lines={"[REDACTED LORE]"}},
            }
            surface.SetDrawColor(10, 20, 15, 255)
            surface.DrawRect(sx + 10, contentY, w - 20, 24)
            surface.SetDrawColor(0, 100, 50, 100)
            surface.DrawOutlinedRect(sx + 10, contentY, w - 20, 24)
            surface.SetFont("Petrov_Console")
            surface.SetTextColor(COLORS.PRIMARY)
            surface.SetTextPos(sx + 18, contentY + 5)
            surface.DrawText("CLASSIFIED ARCHIVE - DR. V. PETROV")
            if math.floor(CurTime() * 2) % 2 == 0 then
                surface.SetTextColor(COLORS.SUCCESS)
            else
                surface.SetTextColor(Color(0, 120, 40, 150))
            end
            surface.SetTextPos(sx + w - 105, contentY + 5)
            surface.DrawText("CONNECTED")
            local logAreaY = contentY + 28
            local logAreaH = contentH - 32
            surface.SetDrawColor(3, 8, 5, 255)
            surface.DrawRect(sx + 10, logAreaY, w - 20, logAreaH)
            local lineH = 15
            local entryGap = 12
            local totalRenderLines = 0
            for _, entry in ipairs(LOG_ENTRIES) do
                totalRenderLines = totalRenderLines + 2 + #entry.lines + 1
            end
            local totalHeight = totalRenderLines * lineH
            local maxScroll = math.max(0, totalRenderLines - math.floor(logAreaH / lineH) + 2)
            menuState.logsScrollOffset = math.Clamp(menuState.logsScrollOffset or 0, 0, maxScroll)
            local drawY = logAreaY + 8 - menuState.logsScrollOffset * lineH
            for ei, entry in ipairs(LOG_ENTRIES) do
                local entryHeight = (2 + #entry.lines + 1) * lineH
                if drawY + entryHeight < logAreaY then
                    drawY = drawY + entryHeight
                else
                    local catColors = {
                        PERSONAL = Color(220, 180, 50),
                        SYSTEM = COLORS.SUCCESS,
                        EXPERIMENT = Color(80, 200, 220),
                        CLASSIFIED = Color(200, 50, 50),
                        MEDICAL = Color(180, 100, 220),
                        ARCHIVED = Color(120, 100, 70),
                    }
                    local catCol = catColors[entry.cat] or COLORS.TEXT_DIM
                    if drawY >= logAreaY - lineH and drawY < logAreaY + logAreaH then
                        surface.SetFont("Petrov_Console")
                        surface.SetTextColor(COLORS.TEXT_DIM)
                        surface.SetTextPos(sx + 18, drawY)
                        surface.DrawText("[" .. entry.date .. "]")
                        local tagX = sx + 150
                        surface.SetTextColor(catCol)
                        surface.SetTextPos(tagX, drawY)
                        surface.DrawText("[" .. entry.cat .. "]")
                    end
                    drawY = drawY + lineH
                    if drawY >= logAreaY and drawY < logAreaY + logAreaH then
                        surface.SetDrawColor(catCol.r, catCol.g, catCol.b, 40)
                        surface.DrawRect(sx + 18, drawY, w - 46, 1)
                    end
                    drawY = drawY + lineH * 0.3
                    for _, line in ipairs(entry.lines) do
                        if drawY >= logAreaY - lineH and drawY < logAreaY + logAreaH then
                            if line == "" then
                            else
                                surface.SetFont("Petrov_Console")
                                surface.SetTextColor(entry.color.r, entry.color.g, entry.color.b, 200)
                                surface.SetTextPos(sx + 22, drawY)
                                surface.DrawText(line)
                            end
                        end
                        drawY = drawY + lineH
                    end
                    drawY = drawY + entryGap
                end
                if drawY > logAreaY + logAreaH + lineH then break end
            end
            if maxScroll > 0 then
                local scrollBarX = sx + w - 26
                local scrollBarH = logAreaH - 4
                local thumbH = math.max(20, scrollBarH * (math.floor(logAreaH / lineH) / totalRenderLines))
                local scrollPct = menuState.logsScrollOffset / maxScroll
                local thumbY = logAreaY + 2 + scrollPct * (scrollBarH - thumbH)
                surface.SetDrawColor(20, 30, 20, 100)
                surface.DrawRect(scrollBarX, logAreaY + 2, 6, scrollBarH)
                surface.SetDrawColor(0, 120, 60, 150)
                surface.DrawRect(scrollBarX, thumbY, 6, thumbH)
            end
            surface.SetFont("Petrov_Small")
            surface.SetTextColor(60, 80, 60, 100)
            surface.SetTextPos(sx + 18, logAreaY + logAreaH - 12)
            surface.DrawText("[UP/DOWN] Scroll")
        end
    end
    local statusY = sy + h - 28
    surface.SetDrawColor(COLORS.BG_LIGHT)
    surface.DrawRect(sx, statusY, w, 28)
    surface.SetFont("Petrov_Small")
    surface.SetTextColor(COLORS.SUCCESS)
    surface.SetTextPos(sx + 15, statusY + 7)
    surface.DrawText("* ONLINE")
    surface.SetTextColor(COLORS.TEXT_DIM)
    surface.SetTextPos(sx + 100, statusY + 7)
    surface.DrawText("MEM: 4096KB")
    surface.SetTextPos(sx + 220, statusY + 7)
    surface.DrawText(os.date("%H:%M:%S"))
end
local function CreateMenu()
    if IsValid(currentFrame) then
        currentFrame:Close()
    end
    menuState.screen = "power_on"
    menuState.powerOnTime = CurTime()
    menuState.currentTab = "CONSOLE"
    menuState.soundPlayed = {}
    PlaySound("SWITCH_ON")
    local frame = vgui.Create("DFrame")
    currentFrame = frame
    frame:SetSize(760, 610)
    frame:Center()
    frame:SetTitle("")
    frame:SetDraggable(true)
    frame:ShowCloseButton(false)
    frame:MakePopup()
    local margin = 30
    local tabBtnY = margin + 40
    local tabBtnH = 26
    local tabBtnGap = 4
    local tabBtnPad = 16
    local tabBtnX = margin + 10
    surface.SetFont("Petrov_Tab")
    menuState.tabButtons = {}
    local curBtnX = tabBtnX
    for i, tabName in ipairs(TABS) do
        local ttw = surface.GetTextSize(tabName)
        local tabW = ttw + tabBtnPad
        local btn = vgui.Create("DButton", frame)
        btn:SetPos(curBtnX, tabBtnY)
        btn:SetSize(tabW, tabBtnH)
        btn:SetText("")
        btn:SetCursor("arrow")
        btn.Paint = function(self, w, h) end
        local capturedName = tabName
        btn.DoClick = function()
            if menuState.currentTab ~= capturedName then
                menuState.currentTab = capturedName
                if VOIDTERM.Input.OnTabChanged then
                    VOIDTERM.Input.OnTabChanged(capturedName)
                end
            end
        end
        menuState.tabButtons[i] = btn
        curBtnX = curBtnX + tabW + tabBtnGap
    end
    if VOIDTERM.FileSystem then
        VOIDTERM.FileSystem.Init()
    end
    VOIDTERM.Input.Init(frame, menuState, PlaySound)
    VOIDTERM.Input.OnTabChanged(menuState.currentTab)
    if VOIDTERM.Graphics then
        VOIDTERM.Graphics.Init(menuState)
        VOIDTERM.Graphics.SetFrame(frame)
    end
    frame.OnClose = function()
        StopAmbientSound()
    end
    frame.Paint = function(self, w, h)
        local margin = 30
        local screenX = margin
        local screenY = margin
        local screenW = w - margin*2
        local screenH = h - margin*2
        VOIDTERM.CRT.DrawMonitorBezel(screenX, screenY, screenW, screenH)
        VOIDTERM.CRT.BeginCapture()
            local rtW, rtH = 1024, 1024
            surface.SetDrawColor(COLORS.BG)
            surface.DrawRect(0, 0, rtW, rtH)
            local scaleX = rtW / screenW
            local scaleY = rtH / screenH
            local m = Matrix()
            m:Scale(Vector(scaleX, scaleY, 1))
            cam.PushModelMatrix(m)
                if menuState.screen == "power_on" then
                    DrawPowerOnAnim(self, 0, 0, screenW, screenH)
                elseif menuState.screen == "login" then
                    DrawLoginScreen(self, 0, 0, screenW, screenH)
                elseif menuState.screen == "booting" then
                    DrawBootScreen(self, 0, 0, screenW, screenH)
                else
                    DrawComputerScreen(self, 0, 0, screenW, screenH)
                end
            cam.PopModelMatrix()
        VOIDTERM.CRT.EndCapture()
        local absX, absY = self:LocalToScreen(screenX, screenY)
        VOIDTERM.CRT.DrawScreenEffects(screenX, screenY, screenW, screenH, absX, absY)
        VOIDTERM.CRT.DrawCornerMask(screenX, screenY, screenW, screenH, 16, Color(30, 30, 30))
    end
    frame.OnMouseWheeled = function(self, delta)
        if menuState.screen == "computer" then
            if menuState.currentTab == "CONSOLE" then
                menuState.scrollOffset = math.max(0, menuState.scrollOffset + delta * 3)
            elseif menuState.currentTab == "FILES" and menuState.viewingFile then
                menuState.fileScrollOffset = math.max(0, (menuState.fileScrollOffset or 0) - delta * 3)
            end
        end
    end
    frame.OnKeyCodePressed = function(self, key)
        VOIDTERM.Input.HandleKey(key)
    end
    local closeBtn = vgui.Create("DButton", frame)
    closeBtn:SetPos(frame:GetWide() - 30 - 35, 30 + 5)
    closeBtn:SetSize(30, 20)
    closeBtn:SetText("")
    closeBtn.Paint = function(self, w, h)
        local c = self:IsHovered() and COLORS.ACCENT or COLORS.TEXT_DIM
        draw.SimpleText("[X]", "Petrov_Small", w/2, h/2 - 5, c, TEXT_ALIGN_CENTER)
    end
    closeBtn.DoClick = function()
        PlaySound("SWITCH_OFF")
        StopAmbientSound()
        net.Start("UNKNOW_ComputerAction")
        net.WriteString("CLOSE")
        net.WriteString("")
        net.SendToServer()
        frame:Close()
    end
    local bezelMargin = 30
    local passLabel = vgui.Create("DLabel", frame)
    passLabel:SetPos(bezelMargin + 225, bezelMargin + 324)
    passLabel:SetSize(200, 20)
    passLabel:SetText("")
    passLabel:SetFont("Petrov_Title")
    passLabel:SetTextColor(COLORS.PRIMARY)
    local passEntry = vgui.Create("DTextEntry", frame)
    passEntry:SetPos(bezelMargin + 225, bezelMargin + 349)
    passEntry:SetSize(220, 30)
    passEntry:SetAlpha(0)
    passEntry:RequestFocus()
    frame.passEntry = passEntry
    passEntry.Paint = function(self, w, h) end
    passEntry.PaintOver = function() end
    passEntry.lastLength = 0
    passEntry.OnChange = function(self)
        self.lastLength = #self:GetValue()
    end
    passEntry.OnKeyCodeTyped = function(self, code)
        if not menuState.pressedKeys[code] then
            menuState.pressedKeys[code] = true
            PlaySound("INPUT1")
        end
    end
    local loginBtn = vgui.Create("DButton", frame)
    loginBtn:SetPos(bezelMargin + 460, bezelMargin + 349)
    loginBtn:SetSize(80, 30)
    loginBtn:SetText("")
    loginBtn:SetAlpha(0)
    loginBtn.Paint = function() end
    frame.loginBtn = loginBtn
    local errorLabel = vgui.Create("DLabel", frame)
    errorLabel:SetPos(bezelMargin + 170, bezelMargin + 355)
    errorLabel:SetSize(300, 20)
    errorLabel:SetText("")
    errorLabel:SetFont("Petrov_Small")
    errorLabel:SetTextColor(COLORS.ACCENT)
    local function DoLogin()
        PlaySound("CLICK")
        net.Start("UNKNOW_SubmitCode")
        net.WriteString(passEntry:GetValue())
        net.SendToServer()
    end
    loginBtn.DoClick = DoLogin
    passEntry.OnEnter = DoLogin
    frame.Think = function(self)
        menuState.pressedKeys = menuState.pressedKeys or {}
        for key, _ in pairs(menuState.pressedKeys) do
            if not input.IsKeyDown(key) then
                menuState.pressedKeys[key] = nil
                PlaySound("INPUT2")
            end
        end
        if VOIDTERM.BASIC and VOIDTERM.BASIC.Running then
            if input.IsKeyDown(KEY_TAB) and not menuState.tabPressed then
                menuState.tabPressed = true
                VOIDTERM.BASIC.Stop()
            elseif not input.IsKeyDown(KEY_TAB) then
                menuState.tabPressed = false
            end
        end
        local isLogin = menuState.screen == "login"
        local isBooting = menuState.screen == "booting"
        local isComputer = menuState.screen == "computer"
        local isConsole = isComputer and menuState.currentTab == "CONSOLE"
        local isGameRunning = VOIDTERM.BASIC and VOIDTERM.BASIC.Running and menuState.graphicsMode
        passLabel:SetVisible(isLogin)
        passEntry:SetVisible(isLogin)
        loginBtn:SetVisible(isLogin)
        errorLabel:SetVisible(isLogin)
        local bezel = 30
        local fw, fh = self:GetWide(), self:GetTall()
        local screenW = fw - bezel * 2
        local screenH = fh - bezel * 2
        if menuState.tabButtons and menuState.tabHitboxes then
            for i, btn in ipairs(menuState.tabButtons) do
                if IsValid(btn) then
                    local hb = menuState.tabHitboxes[i]
                    if hb and isComputer then
                        local frameX = bezel + hb.x
                        local frameY = bezel + hb.y
                        btn:SetPos(frameX, frameY)
                        btn:SetSize(hb.w, hb.h)
                        btn:SetVisible(true)
                    else
                        btn:SetVisible(false)
                    end
                end
            end
        end
        if isComputer and menuState.currentTab == "FILES" and menuState.viewingFile then
            menuState._scrollTimer = menuState._scrollTimer or 0
            if CurTime() > menuState._scrollTimer then
                local scrollSpeed = 0.08
                if input.IsKeyDown(KEY_UP) then
                    menuState.fileScrollOffset = math.max(0, (menuState.fileScrollOffset or 0) - 1)
                    menuState._scrollTimer = CurTime() + scrollSpeed
                elseif input.IsKeyDown(KEY_DOWN) then
                    menuState.fileScrollOffset = (menuState.fileScrollOffset or 0) + 1
                    menuState._scrollTimer = CurTime() + scrollSpeed
                end
            end
        end
        if isComputer and menuState.currentTab == "LOGS" and menuState.logsConnected then
            menuState._logsScrollTimer = menuState._logsScrollTimer or 0
            if CurTime() > menuState._logsScrollTimer then
                local scrollSpeed = 0.08
                if input.IsKeyDown(KEY_UP) then
                    menuState.logsScrollOffset = math.max(0, (menuState.logsScrollOffset or 0) - 1)
                    menuState._logsScrollTimer = CurTime() + scrollSpeed
                elseif input.IsKeyDown(KEY_DOWN) then
                    menuState.logsScrollOffset = (menuState.logsScrollOffset or 0) + 1
                    menuState._logsScrollTimer = CurTime() + scrollSpeed
                end
            end
        end
        if VOIDTERM.Input and VOIDTERM.Input.UpdateLayout then
            VOIDTERM.Input.UpdateLayout(self:GetWide(), self:GetTall(), 30)
        end
    end
    frame.OnRemove = function(self)
        if VOIDTERM.BASIC and VOIDTERM.BASIC.Stop then
            VOIDTERM.BASIC.Stop()
        end
        if menuState then
            menuState.graphicsMode = false
            menuState.graphicsBuffer = nil
        end
        StopAmbientSound()
    end
    return frame
end
net.Receive("UNKNOW_CodeMenu", function()
    CreateMenu()
end)
net.Receive("UNKNOW_CodeResponse", function()
    local success = net.ReadBool()
    local message = net.ReadString()
    if success then
        PlaySound("NOTIFICATION")
        PlaySound("BOOT")
        menuState.screen = "booting"
        menuState.bootStartTime = CurTime()
        menuState.bootLines = {}
        timer.Simple(4, function()
            StartAmbientSound()
        end)
    else
        PlaySound("ERROR")
        if IsValid(currentFrame) then
            local child = currentFrame:GetChildren()
            for _, c in pairs(child) do
                if c.SetText and c:GetText() == "" and c:GetClassName() == "DLabel" then
                    c:SetText("ERROR: Invalid password")
                end
            end
        end
    end
end)
