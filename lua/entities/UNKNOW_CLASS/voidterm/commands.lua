VOIDTERM = VOIDTERM or {}
VOIDTERM.Commands = {}
VOIDTERM.BASIC = {
    vars = {},
    labels = {},
    jumpTo = nil,
    Running = false
}
function VOIDTERM.BASIC.Stop()
    VOIDTERM.BASIC.Running = false
    VOIDTERM.BASIC.jumpTo = nil
    if VOIDTERM.Graphics then
        VOIDTERM.Graphics.Disable()
    end
end
local COMMANDS = {}
local COLORS = {
    TEXT = Color(0, 220, 60),
    TEXT_DIM = Color(0, 100, 35),
    PRIMARY = Color(0, 255, 65),
    SUCCESS = Color(0, 255, 65),
    ACCENT = Color(255, 80, 80),
}
local addConsoleLine = function(text, color) print(text) end
function VOIDTERM.Commands.SetColors(colors)
    COLORS = colors
end
function VOIDTERM.Commands.SetConsoleCallback(callback)
    addConsoleLine = callback
end
local clearConsole = function() end
function VOIDTERM.Commands.SetClearCallback(callback)
    clearConsole = callback
end
local setConsoleLine = function(y, text, color) end
function VOIDTERM.Commands.SetLineCallback(callback)
    setConsoleLine = callback
end
local state = nil
function VOIDTERM.Commands.SetState(s)
    state = s
end
local HELP_STRINGS = {
    ["?"]     = "? [command]\nShows available commands or detailed help.\nExample: ? scan",
    id        = "ID\nDisplays current operator identity and access level.",
    sys       = "SYS\nDisplays system diagnostics: CPU, memory, storage, network, uptime.",
    ver       = "VER\nDisplays VOIDTERM version and build information.",
    wipe      = "WIPE\nClears the terminal display buffer.",
    halt      = "HALT\nTerminates the current VOIDTERM session.",
    clock     = "CLOCK\nDisplays the current system date and time.",
    tone      = "TONE [freq] [duration]\nEmits a system tone at the specified frequency.\nExample: TONE 800 200",
    scan      = "SCAN\nLists all files in the current storage volume.",
    read      = "READ <file>\nDisplays the contents of the specified file.\nExample: READ notes.void",
    forge     = "FORGE <file> <content>\nCreates or overwrites a file with the given content.\nExample: FORGE log.void Entry 001",
    purge     = "PURGE <file>\nPermanently removes a file from storage.\nExample: PURGE temp.void",
    exec      = "EXEC <file>\nExecutes a VOIDLANG script file.\nExample: EXEC snake.void\nPress TAB to stop execution.",
    hue       = "HUE <color>\nChanges the terminal phosphor color.\nAvailable: green, amber, white, red, cyan\nExample: HUE amber",
    echo      = "ECHO <text>\nPrints text to the terminal output.\nSupports variable expansion: ECHO Score is %SCORE%",
    set       = "SET <var> = <value>\nAssigns a value to a memory variable.\nSupports math: SET X = %Y% + 1\nExample: SET score = 100",
    get       = "GET [var]\nDisplays the value of a variable, or all variables if none specified.\nExample: GET score",
    calc      = "CALC <expression>\nEvaluates a mathematical expression.\nExample: CALC 2 + 2 * 4",
    rand      = "RAND [min] [max]\nGenerates a random number and stores it in %RND%.\nExample: RAND 1 100",
    dump      = "DUMP\nDisplays raw hexadecimal memory contents.\nUse with caution.",
    dworld    = "DWORLD\nLaunches the Digital World connection.",
    gfx       = "GFX [w] [h]\nEnters pixel graphics mode.\nDefault: 160x100 resolution.\nExample: GFX 160 100",
    txt       = "TXT\nReturns to text mode from graphics mode.",
    res       = "RES [width] [height]\nSets the graphics resolution.\nExample: RES 80 50\nMax: 320x200",
    px        = "PX <x> <y> [color]\nSets a pixel in graphics mode.\nColors: green, red, amber, blue, white, cyan, magenta, or R,G,B\nExample: PX 20 12 red",
}
local HELP_CATEGORIES = {
    { name = "SYSTEM",   cmds = {"?", "id", "sys", "ver", "clock", "wipe", "halt"} },
    { name = "FILES",    cmds = {"scan", "read", "forge", "purge", "exec"} },
    { name = "DISPLAY",  cmds = {"echo", "hue"} },
    { name = "MEMORY",   cmds = {"set", "get", "calc", "rand"} },
    { name = "DATA",     cmds = {"dump", "probe"} },
    { name = "DIGITAL",  cmds = {"dworld"} },
    { name = "GRAPHICS", cmds = {"gfx", "txt", "res", "px"} },
}
COMMANDS["?"] = function(args)
    if args[1] then
        local cmd = string.lower(args[1])
        if HELP_STRINGS[cmd] then
            local lines = string.Explode("\n", HELP_STRINGS[cmd])
            for _, line in ipairs(lines) do
                addConsoleLine(line, COLORS.TEXT)
            end
        else
            addConsoleLine("Unknown command: " .. cmd, COLORS.ACCENT)
        end
        return
    end
    addConsoleLine("", COLORS.TEXT)
    addConsoleLine("VOIDTERM COMMAND REFERENCE", COLORS.PRIMARY)
    addConsoleLine("Type ? <command> for detailed information.", COLORS.TEXT_DIM)
    addConsoleLine("", COLORS.TEXT)
    for _, cat in ipairs(HELP_CATEGORIES) do
        local line = "  [" .. cat.name .. "]  "
        for _, cmd in ipairs(cat.cmds) do
            local padding = string.rep(" ", 8 - #cmd)
            line = line .. string.upper(cmd) .. padding
        end
        addConsoleLine(line, COLORS.TEXT)
    end
    addConsoleLine("", COLORS.TEXT)
end
COMMANDS["wipe"] = function(args)
    if VOIDTERM.Graphics and menuState and menuState.graphicsMode then
        VOIDTERM.Graphics.Clear()
    else
        if clearConsole then
            clearConsole()
        end
    end
end
COMMANDS["echo"] = function(args)
    local text = table.concat(args, " ")
    if text == "" then
        addConsoleLine("", COLORS.TEXT)
    else
        addConsoleLine(text, COLORS.TEXT)
    end
end
COMMANDS["ver"] = function(args)
    addConsoleLine("", COLORS.TEXT)
    addConsoleLine("VOIDTERM [Version 2.43 Build 891]", COLORS.PRIMARY)
    addConsoleLine("Petrov Research Systems (c) 1989", COLORS.TEXT_DIM)
    addConsoleLine("Kernel: VOIDKERNEL 1.7.3", COLORS.TEXT_DIM)
    addConsoleLine("", COLORS.TEXT)
end
COMMANDS["clock"] = function(args)
    addConsoleLine("", COLORS.TEXT)
    addConsoleLine("DATE: " .. os.date("%A, %B %d, %Y", os.time()), COLORS.TEXT)
    addConsoleLine("TIME: " .. os.date("%H:%M:%S", os.time()), COLORS.TEXT)
    addConsoleLine("", COLORS.TEXT)
end
COMMANDS["id"] = function(args)
    addConsoleLine("", COLORS.TEXT)
    addConsoleLine("OPERATOR: Dr. Viktor Petrov", COLORS.PRIMARY)
    addConsoleLine("ACCESS:   LEVEL 5 - ADMINISTRATOR", COLORS.SUCCESS)
    addConsoleLine("STATION:  RESEARCH TERMINAL 03", COLORS.TEXT_DIM)
    addConsoleLine("", COLORS.TEXT)
end
COMMANDS["sys"] = function(args)
    local secs = math.floor(CurTime())
    local h, m, s = math.floor(secs/3600), math.floor((secs%3600)/60), secs%60
    addConsoleLine("", COLORS.TEXT)
    addConsoleLine("=== SYSTEM DIAGNOSTICS ===", COLORS.PRIMARY)
    addConsoleLine("", COLORS.TEXT)
    addConsoleLine("  PROCESSOR    Intel 80386 @ 33MHz     [OK]", COLORS.SUCCESS)
    addConsoleLine("  MEMORY       4096KB / 8192KB         [62%]", COLORS.TEXT)
    addConsoleLine("  STORAGE      VOL-A: ENCRYPTED        [LOCKED]", COLORS.TEXT_DIM)
    addConsoleLine("  NETWORK      ISOLATED (NO UPLINK)    [OFFLINE]", COLORS.ACCENT)
    addConsoleLine("  UPTIME       " .. string.format("%02d:%02d:%02d", h, m, s), COLORS.TEXT)
    addConsoleLine("  BIOS         VOIDBIOS 1.2", COLORS.TEXT_DIM)
    addConsoleLine("", COLORS.TEXT)
end
COMMANDS["halt"] = function(args)
    addConsoleLine("> Shutting down VOIDTERM...", COLORS.ACCENT)
    timer.Simple(0.5, function()
        net.Start("UNKNOW_ComputerAction")
        net.WriteString("CLOSE")
        net.WriteString("")
        net.SendToServer()
        if VOIDTERM.CloseMenu then
            VOIDTERM.CloseMenu()
        end
    end)
end
COMMANDS["tone"] = function(args)
    local freq = tonumber(args[1]) or 800
    local dur = tonumber(args[2]) or 200
    if VOIDTERM.Beep and VOIDTERM.Beep.Play then
        VOIDTERM.Beep.Play(freq, dur)
    end
    addConsoleLine("TONE " .. freq .. "Hz " .. dur .. "ms", COLORS.TEXT_DIM)
end
COMMANDS["scan"] = function(args)
    if not VOIDTERM.FileSystem then
        addConsoleLine("Error: File system not available.", COLORS.ACCENT)
        return
    end
    local files = VOIDTERM.FileSystem.List()
    addConsoleLine("", COLORS.TEXT)
    if #files == 0 then
        addConsoleLine("  No files found in storage.", COLORS.TEXT_DIM)
    else
        addConsoleLine("  STORAGE VOLUME A:       " .. #files .. " file(s)", COLORS.PRIMARY)
        addConsoleLine("  " .. string.rep("-", 40), COLORS.TEXT_DIM)
        for i, f in ipairs(files) do
            local idx = string.format("%03d", i)
            addConsoleLine("  [" .. idx .. "]  " .. f, COLORS.TEXT)
        end
    end
    addConsoleLine("", COLORS.TEXT)
end
COMMANDS["read"] = function(args)
    if #args < 1 then
        addConsoleLine("Usage: READ <filename>", COLORS.TEXT_DIM)
        return
    end
    local filename = args[1]
    if not string.find(filename, "%.") then filename = filename .. ".void" end
    if not VOIDTERM.FileSystem then
        addConsoleLine("Error: File system not available.", COLORS.ACCENT)
        return
    end
    local content, err = VOIDTERM.FileSystem.Load(filename)
    if content then
        addConsoleLine("", COLORS.TEXT)
        addConsoleLine("--- " .. filename .. " ---", COLORS.PRIMARY)
        local lines = string.Explode("\n", content)
        for _, line in ipairs(lines) do
            addConsoleLine(line, COLORS.TEXT)
        end
        addConsoleLine("--- END ---", COLORS.PRIMARY)
    else
        addConsoleLine("File not found: " .. filename, COLORS.ACCENT)
    end
end
COMMANDS["forge"] = function(args)
    if #args < 2 then
        addConsoleLine("Usage: FORGE <filename> <content>", COLORS.TEXT_DIM)
        return
    end
    local filename = args[1]
    if not string.find(filename, "%.") then filename = filename .. ".void" end
    table.remove(args, 1)
    local content = table.concat(args, " ")
    if not VOIDTERM.FileSystem then
        addConsoleLine("Error: File system not available.", COLORS.ACCENT)
        return
    end
    local success, err = VOIDTERM.FileSystem.Save(filename, content)
    if success then
        addConsoleLine("Forged: " .. filename, COLORS.SUCCESS)
    else
        addConsoleLine("Error: " .. (err or "Write failed"), COLORS.ACCENT)
    end
end
COMMANDS["purge"] = function(args)
    if #args < 1 then
        addConsoleLine("Usage: PURGE <filename>", COLORS.TEXT_DIM)
        return
    end
    local filename = args[1]
    if not string.find(filename, "%.") then filename = filename .. ".void" end
    if not VOIDTERM.FileSystem then
        addConsoleLine("Error: File system not available.", COLORS.ACCENT)
        return
    end
    local success, err = VOIDTERM.FileSystem.Delete(filename)
    if success then
        addConsoleLine("Purged: " .. filename, COLORS.TEXT_DIM)
    else
        addConsoleLine("Error: " .. (err or "File not found"), COLORS.ACCENT)
    end
end
COMMANDS["exec"] = function(args)
    if #args < 1 then
        addConsoleLine("Usage: EXEC <filename>", COLORS.TEXT_DIM)
        return
    end
    local filename = args[1]
    if not string.find(filename, "%.") then filename = filename .. ".void" end
    if not VOIDTERM.FileSystem then
        addConsoleLine("Error: File system not available.", COLORS.ACCENT)
        return
    end
    local content, err = VOIDTERM.FileSystem.Load(filename)
    if not content then
        addConsoleLine("Error: " .. (err or "File not found"), COLORS.ACCENT)
        return
    end
    addConsoleLine("EXECUTING " .. filename .. "... [TAB] to abort", COLORS.PRIMARY)
    if VOIDTERM.Game and VOIDTERM.Game.Run then
        VOIDTERM.Game.Run(content)
    else
        addConsoleLine("Error: Execution engine not loaded", COLORS.ACCENT)
    end
end
COMMANDS["hue"] = function(args)
    local hueName = string.lower(args[1] or "")
    local hues = {
        green = { text = Color(0, 220, 60),    primary = Color(0, 255, 65) },
        amber = { text = Color(255, 176, 0),   primary = Color(255, 200, 0) },
        white = { text = Color(220, 220, 220), primary = Color(255, 255, 255) },
        red   = { text = Color(220, 60, 60),   primary = Color(255, 80, 80) },
        cyan  = { text = Color(0, 200, 220),   primary = Color(0, 255, 255) },
    }
    if hues[hueName] then
        COLORS.TEXT = hues[hueName].text
        COLORS.PRIMARY = hues[hueName].primary
        addConsoleLine("Phosphor set to " .. string.upper(hueName), COLORS.PRIMARY)
    else
        addConsoleLine("Available hues: green, amber, white, red, cyan", COLORS.TEXT_DIM)
    end
end
COMMANDS["set"] = function(args)
    local full = table.concat(args, " ")
    local name, value = string.match(full, "([^=]+)=(.*)")
    if name and value then
        name = string.Trim(name)
        value = string.Trim(value)
        value = value:gsub("%%(%w+)%%", function(v)
            return tostring(VOIDTERM.BASIC.vars[v] or 0)
        end)
        local safe = value:gsub("[^%d%+%-%*%/%^%(%)%.%s]", "")
        safe = string.Trim(safe)
        if safe ~= "" then
            local func = CompileString("return " .. safe, "set", false)
            if type(func) == "function" then
                local ok, result = pcall(func)
                if ok and result then
                    VOIDTERM.BASIC.vars[name] = result
                    addConsoleLine(name .. " = " .. tostring(result), COLORS.TEXT)
                    return
                end
            end
        end
        VOIDTERM.BASIC.vars[name] = value
        addConsoleLine(name .. " = " .. value, COLORS.TEXT)
    else
        addConsoleLine("Syntax: SET <var> = <value>", COLORS.TEXT_DIM)
    end
end
COMMANDS["get"] = function(args)
    if #args == 0 then
        addConsoleLine("", COLORS.TEXT)
        if next(VOIDTERM.BASIC.vars) == nil then
            addConsoleLine("  No variables defined.", COLORS.TEXT_DIM)
        else
            addConsoleLine("  MEMORY REGISTERS:", COLORS.PRIMARY)
            for name, value in pairs(VOIDTERM.BASIC.vars) do
                addConsoleLine("    " .. name .. " = " .. tostring(value), COLORS.TEXT)
            end
        end
        addConsoleLine("", COLORS.TEXT)
        return
    end
    local varName = args[1]
    if VOIDTERM.BASIC.vars[varName] ~= nil then
        addConsoleLine(varName .. " = " .. tostring(VOIDTERM.BASIC.vars[varName]), COLORS.TEXT)
    else
        addConsoleLine("Undefined: " .. varName, COLORS.TEXT_DIM)
    end
end
COMMANDS["calc"] = function(args)
    local expr = table.concat(args, " ")
    if expr == "" then
        addConsoleLine("Usage: CALC <expression>", COLORS.TEXT_DIM)
        return
    end
    local safe = expr:gsub("[^%d%+%-%*%/%^%(%)%.]", "")
    local func = CompileString("return " .. safe, "calc", false)
    if type(func) == "function" then
        local ok, result = pcall(func)
        if ok then
            addConsoleLine("= " .. tostring(result), COLORS.SUCCESS)
        else
            addConsoleLine("Syntax error in expression.", COLORS.ACCENT)
        end
    else
        addConsoleLine("Syntax error in expression.", COLORS.ACCENT)
    end
end
COMMANDS["rand"] = function(args)
    local min = tonumber(args[1]) or 1
    local max = tonumber(args[2]) or 100
    local result = math.random(min, max)
    VOIDTERM.BASIC.vars["RND"] = result
    addConsoleLine("RND = " .. result, COLORS.TEXT)
end
COMMANDS["dump"] = function(args)
    addConsoleLine("", COLORS.TEXT)
    addConsoleLine("MEMORY DUMP @ 0x0300-0x033F", COLORS.PRIMARY)
    addConsoleLine("", COLORS.TEXT)
    for i = 1, 8 do
        local addr = string.format("%04X", 0x0300 + (i-1)*8)
        local bytes = ""
        local ascii = ""
        for j = 1, 8 do
            local byte = math.random(0, 255)
            bytes = bytes .. string.format("%02X ", byte)
            if byte >= 32 and byte <= 126 then
                ascii = ascii .. string.char(byte)
            else
                ascii = ascii .. "."
            end
        end
        addConsoleLine("  " .. addr .. ": " .. bytes .. " |" .. ascii .. "|", COLORS.TEXT_DIM)
    end
    addConsoleLine("", COLORS.TEXT)
end
COMMANDS["probe"] = function(args)
    addConsoleLine("", COLORS.TEXT)
    addConsoleLine("=== ACTIVE SUBJECT DATABASE ===", COLORS.PRIMARY)
    addConsoleLine("", COLORS.TEXT)
    addConsoleLine("  ID    CODENAME     STATUS      THREAT", COLORS.TEXT_DIM)
    addConsoleLine("  " .. string.rep("-", 46), COLORS.TEXT_DIM)
    addConsoleLine("  001   VIRIS        ACTIVE      EXTREME", COLORS.ACCENT)
    addConsoleLine("  002   H.I.D.E      ACTIVE      EXTREME", COLORS.ACCENT)
    addConsoleLine("  003   CONSUMER     ACTIVE      HIGH", COLORS.SUCCESS)
    addConsoleLine("  004   SMERT        ACTIVE      HIGH", COLORS.SUCCESS)
    addConsoleLine("  005   VOMAT        ACTIVE      MODERATE", COLORS.TEXT)
    addConsoleLine("  006   HINN         SPECTRAL    UNKNOWN", COLORS.TEXT_DIM)
    addConsoleLine("", COLORS.TEXT)
    addConsoleLine("  WARNING: Do not approach subjects without", COLORS.ACCENT)
    addConsoleLine("  proper containment equipment.", COLORS.ACCENT)
    addConsoleLine("", COLORS.TEXT)
end
COMMANDS["gfx"] = function(args)
    if VOIDTERM.Graphics then
        local w = tonumber(args[1]) or 160
        local h = tonumber(args[2]) or 100
        VOIDTERM.Graphics.Enable(w, h)
        addConsoleLine("Graphics mode: " .. w .. "x" .. h, COLORS.PRIMARY)
    end
end
COMMANDS["txt"] = function(args)
    if VOIDTERM.Graphics then
        VOIDTERM.Graphics.Disable()
        addConsoleLine("Text mode restored.", COLORS.TEXT_DIM)
    end
end
COMMANDS["res"] = function(args)
    local w = tonumber(args[1])
    local h = tonumber(args[2])
    if w and h and VOIDTERM.Graphics and VOIDTERM.Graphics.SetResolution then
        VOIDTERM.Graphics.SetResolution(w, h)
        addConsoleLine("Resolution: " .. w .. "x" .. h, COLORS.PRIMARY)
    else
        local cw, ch = 160, 100
        if VOIDTERM.Graphics and VOIDTERM.Graphics.GetResolution then
            cw, ch = VOIDTERM.Graphics.GetResolution()
        end
        addConsoleLine("Current: " .. cw .. "x" .. ch .. " (max 320x200)", COLORS.TEXT)
        addConsoleLine("Usage: RES <width> <height>", COLORS.TEXT_DIM)
    end
end
COMMANDS["px"] = function(args)
    local x = tonumber(args[1])
    local y = tonumber(args[2])
    local colName = string.lower(args[3] or "green")
    local colorMap = {
        green   = Color(0, 255, 65),
        red     = Color(255, 60, 60),
        amber   = Color(255, 176, 0),
        yellow  = Color(255, 176, 0),
        blue    = Color(50, 150, 255),
        white   = Color(255, 255, 255),
        cyan    = Color(0, 255, 255),
        magenta = Color(255, 0, 255),
        black   = Color(0, 0, 0),
    }
    local color = colorMap[colName] or COLORS.PRIMARY
    if not colorMap[colName] then
        local r, g, b = string.match(colName, "(%d+),(%d+),(%d+)")
        if r then color = Color(tonumber(r), tonumber(g), tonumber(b)) end
    end
    if x and y and VOIDTERM.Graphics and VOIDTERM.Graphics.Pixel then
        VOIDTERM.Graphics.Pixel(x, y, color)
    end
end
COMMANDS["if"] = function(args)
    local full = table.concat(args, " ")
    local left, right, command = string.match(full, "(.-)%s*==%s*(.-)%s+[Tt][Hh][Ee][Nn]%s+(.+)")
    if not command then
        left, right, command = string.match(full, "(.-)%s*==%s*(%S+)%s+(.+)")
    end
    if left and right and command then
        left = string.Trim(left):gsub("%%(%w+)%%", function(v) return VOIDTERM.BASIC.vars[v] or "" end)
        right = string.Trim(right):gsub("%%(%w+)%%", function(v) return VOIDTERM.BASIC.vars[v] or "" end)
        if left == right then
            VOIDTERM.Commands.Execute(command, true)
        end
    end
end
COMMANDS["for"] = function(args)
    local full = table.concat(args, " ")
    local var, startVal, endVal, command = string.match(full, "([%w]+)%s*=%s*(%d+)%s+[Tt][Oo]%s+(%d+)%s+[Dd][Oo]%s+(.+)")
    if var and startVal and endVal and command then
        local s = tonumber(startVal)
        local e = tonumber(endVal)
        if math.abs(e - s) > 50 then
            addConsoleLine("Error: Loop range too large (max 50)", COLORS.ACCENT)
            return
        end
        local step = (s <= e) and 1 or -1
        for i = s, e, step do
            VOIDTERM.BASIC.vars[var] = i
            local execCmd = command:gsub("%%" .. var .. "%%", tostring(i)):gsub("%f[%w]" .. var .. "%f[%W]", tostring(i))
            VOIDTERM.Commands.Execute(execCmd, true)
        end
    else
        addConsoleLine("Syntax: FOR var = start TO end DO command", COLORS.TEXT_DIM)
    end
end
COMMANDS["repeat"] = function(args)
    local times = tonumber(args[1])
    if not times or times < 1 then
        addConsoleLine("Syntax: REPEAT n command", COLORS.TEXT_DIM)
        return
    end
    table.remove(args, 1)
    local command = table.concat(args, " ")
    for i = 1, math.min(times, 50) do
        VOIDTERM.BASIC.vars["i"] = i
        local execCmd = command:gsub("%%i%%", tostring(i)):gsub("%%i", tostring(i))
        VOIDTERM.Commands.Execute(execCmd, true)
    end
end
local function ExpandVariables(input)
    return input:gsub("%%(%w+)%%", function(var)
        return VOIDTERM.BASIC.vars[var] or ("%" .. var .. "%")
    end)
end
function VOIDTERM.Commands.Execute(input, bypassLineCheck)
    if not input or input == "" then return end
    input = ExpandVariables(input)
    if not bypassLineCheck then
        addConsoleLine("> " .. input, COLORS.PRIMARY)
    end
    local parts = string.Split(input, " ")
    local cmd = string.lower(parts[1] or "")
    table.remove(parts, 1)
    if COMMANDS[cmd] then
        COMMANDS[cmd](parts)
    else
        addConsoleLine("'" .. cmd .. "' is not recognized.", COLORS.ACCENT)
        addConsoleLine("Type ? for a list of commands.", COLORS.TEXT_DIM)
    end
end
COMMANDS["dworld"] = function(args)
    if state and not state.logsUnlocked then
        addConsoleLine("Error: Digital World connection refused.", COLORS.ACCENT)
        addConsoleLine("System access restricted. Requires master log authentication.", COLORS.TEXT_DIM)
        return
    end
    if not _G.CreateDigitalWorldInterface then
        addConsoleLine("Error: External Digital World module not found or loaded.", COLORS.ACCENT)
        return
    end
    addConsoleLine("", COLORS.TEXT)
    addConsoleLine("ACCESSING DIGITAL WORLD...", COLORS.ACCENT)
    addConsoleLine("Redirecting input thread. Closing terminal...", COLORS.TEXT_DIM)
    timer.Simple(0.8, function()
        net.Start("UNKNOW_ComputerAction")
        net.WriteString("CLOSE")
        net.WriteString("")
        net.SendToServer()
        if VOIDTERM.CloseMenu then
            VOIDTERM.CloseMenu()
        end
        timer.Simple(0.1, function()
            if _G.CreateDigitalWorldInterface then
                _G.CreateDigitalWorldInterface()
            end
        end)
    end)
end
function VOIDTERM.Commands.GetCommand(name)
    return COMMANDS[string.lower(name)]
end
