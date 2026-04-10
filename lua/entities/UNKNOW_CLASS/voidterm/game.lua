VOIDTERM = VOIDTERM or {}
VOIDTERM.Game = {}
local gameState = {
    running = false,
    lines = {},
    labels = {},
    currentLine = 1,
    vars = {},
    waitUntil = 0,
    graphicsMode = false,
    lastKey = "",
    keyBuffer = "",
    mouseX = 0,
    mouseY = 0,
    mouseDown = false,
    mouseRightDown = false,
    onStop = nil,
}
local COLOR_MAP = {
    green   = Color(0, 255, 65),
    red     = Color(255, 60, 60),
    blue    = Color(50, 150, 255),
    white   = Color(255, 255, 255),
    cyan    = Color(0, 255, 255),
    magenta = Color(255, 0, 255),
    amber   = Color(255, 176, 0),
    yellow  = Color(255, 200, 0),
    orange  = Color(255, 120, 0),
    pink    = Color(255, 100, 200),
    purple  = Color(180, 60, 255),
    black   = Color(0, 0, 0),
    gray    = Color(128, 128, 128),
    grey    = Color(128, 128, 128),
    darkgreen = Color(0, 100, 30),
    darkred = Color(150, 0, 0),
    darkblue = Color(0, 0, 150),
}
local function ParseColor(name)
    if not name then return Color(0, 255, 65) end
    name = string.lower(name)
    if COLOR_MAP[name] then return COLOR_MAP[name] end
    local r, g, b = string.match(name, "(%d+),(%d+),(%d+)")
    if r then
        return Color(tonumber(r), tonumber(g), tonumber(b))
    end
    return Color(0, 255, 65)
end
local function ExpandVars(str)
    return str:gsub("%%(%w+)%%", function(name)
        return tostring(gameState.vars[name] or 0)
    end)
end
local function EvalMath(expr)
    expr = ExpandVars(expr)
    local safe = expr:gsub("[^%d%+%-%*%/%s%.%(%)%%]", "")
    safe = string.Trim(safe)
    if safe == "" then return expr end
    local func = CompileString("return " .. safe, "eval", false)
    if type(func) == "function" then
        local ok, result = pcall(func)
        if ok and result then return result end
    end
    return expr
end
local function ExecuteCommand(line)
    line = string.Trim(line)
    if line == "" or string.StartWith(line, "--") then return end
    local expanded = ExpandVars(line)
    local parts = string.Split(expanded, " ")
    local cmd = string.lower(parts[1] or "")
    table.remove(parts, 1)
    local args = parts
    local GFX = VOIDTERM.Graphics
    if cmd == "gfx" then
        local w = tonumber(args[1]) or 160
        local h = tonumber(args[2]) or 100
        gameState.graphicsMode = true
        if GFX then GFX.Enable(w, h) end
    elseif cmd == "txt" then
        gameState.graphicsMode = false
        if GFX then GFX.Disable() end
    elseif cmd == "fill" then
        local color = args[1] and ParseColor(args[1]) or nil
        if GFX then GFX.Clear(color) end
    elseif cmd == "px" then
        local x = tonumber(args[1]) or 0
        local y = tonumber(args[2]) or 0
        local color = ParseColor(args[3])
        if GFX then GFX.Pixel(x, y, color) end
    elseif cmd == "ln" then
        local x1 = tonumber(args[1]) or 0
        local y1 = tonumber(args[2]) or 0
        local x2 = tonumber(args[3]) or 0
        local y2 = tonumber(args[4]) or 0
        local color = ParseColor(args[5])
        if GFX then GFX.Line(x1, y1, x2, y2, color) end
    elseif cmd == "rect" then
        local x = tonumber(args[1]) or 0
        local y = tonumber(args[2]) or 0
        local w = tonumber(args[3]) or 10
        local h = tonumber(args[4]) or 10
        local color = ParseColor(args[5])
        if GFX then GFX.Rect(x, y, w, h, color) end
    elseif cmd == "frect" then
        local x = tonumber(args[1]) or 0
        local y = tonumber(args[2]) or 0
        local w = tonumber(args[3]) or 10
        local h = tonumber(args[4]) or 10
        local color = ParseColor(args[5])
        if GFX then GFX.FillRect(x, y, w, h, color) end
    elseif cmd == "circ" then
        local cx = tonumber(args[1]) or 80
        local cy = tonumber(args[2]) or 50
        local r = tonumber(args[3]) or 20
        local color = ParseColor(args[4])
        if GFX then GFX.Circle(cx, cy, r, color) end
    elseif cmd == "fcirc" then
        local cx = tonumber(args[1]) or 80
        local cy = tonumber(args[2]) or 50
        local r = tonumber(args[3]) or 20
        local color = ParseColor(args[4])
        if GFX then GFX.FillCircle(cx, cy, r, color) end
    elseif cmd == "scirc" then
        local cx = tonumber(args[1]) or 80
        local cy = tonumber(args[2]) or 50
        local r = tonumber(args[3]) or 20
        local color = ParseColor(args[4])
        if GFX then GFX.SmoothCircle(cx, cy, r, color) end
    elseif cmd == "tri" then
        local x1 = tonumber(args[1]) or 0
        local y1 = tonumber(args[2]) or 0
        local x2 = tonumber(args[3]) or 10
        local y2 = tonumber(args[4]) or 0
        local x3 = tonumber(args[5]) or 5
        local y3 = tonumber(args[6]) or 10
        local color = ParseColor(args[7])
        if GFX then GFX.Triangle(x1,y1, x2,y2, x3,y3, color) end
    elseif cmd == "ftri" then
        local x1 = tonumber(args[1]) or 0
        local y1 = tonumber(args[2]) or 0
        local x2 = tonumber(args[3]) or 10
        local y2 = tonumber(args[4]) or 0
        local x3 = tonumber(args[5]) or 5
        local y3 = tonumber(args[6]) or 10
        local color = ParseColor(args[7])
        if GFX then GFX.FillTriangle(x1,y1, x2,y2, x3,y3, color) end
    elseif cmd == "text" then
        local x = tonumber(args[1]) or 0
        local y = tonumber(args[2]) or 0
        local color = ParseColor(args[3])
        table.remove(args, 1)
        table.remove(args, 1)
        table.remove(args, 1)
        local str = table.concat(args, " ")
        if str == "" then str = "TEXT" end
        if GFX then GFX.Text(x, y, str, color) end
    elseif cmd == "bigtxt" then
        local x = tonumber(args[1]) or 0
        local y = tonumber(args[2]) or 0
        local color = ParseColor(args[3])
        table.remove(args, 1)
        table.remove(args, 1)
        table.remove(args, 1)
        local str = table.concat(args, " ")
        if str == "" then str = "TEXT" end
        if GFX then GFX.BigText(x, y, str, color) end
    elseif cmd == "cam" then
        local x = tonumber(args[1]) or 0
        local y = tonumber(args[2]) or 0
        local z = tonumber(args[3]) or -200
        local rx = tonumber(args[4]) or 0
        local ry = tonumber(args[5]) or 0
        if GFX then GFX.SetCamera(x, y, z, rx, ry) end
    elseif cmd == "ln3" then
        local x1 = tonumber(args[1]) or 0
        local y1 = tonumber(args[2]) or 0
        local z1 = tonumber(args[3]) or 0
        local x2 = tonumber(args[4]) or 0
        local y2 = tonumber(args[5]) or 0
        local z2 = tonumber(args[6]) or 0
        local color = ParseColor(args[7])
        if GFX then GFX.Line3D(x1,y1,z1, x2,y2,z2, color) end
    elseif cmd == "cube3" then
        local x = tonumber(args[1]) or 0
        local y = tonumber(args[2]) or 0
        local z = tonumber(args[3]) or 100
        local size = tonumber(args[4]) or 50
        local color = ParseColor(args[5])
        if GFX then GFX.Cube3D(x, y, z, size, color) end
    elseif cmd == "tri3" then
        local x1 = tonumber(args[1]) or 0
        local y1 = tonumber(args[2]) or 0
        local z1 = tonumber(args[3]) or 0
        local x2 = tonumber(args[4]) or 0
        local y2 = tonumber(args[5]) or 0
        local z2 = tonumber(args[6]) or 0
        local x3 = tonumber(args[7]) or 0
        local y3 = tonumber(args[8]) or 0
        local z3 = tonumber(args[9]) or 0
        local color = ParseColor(args[10])
        if GFX then GFX.Triangle3D(x1,y1,z1, x2,y2,z2, x3,y3,z3, color) end
    elseif cmd == "ellipse" then
        local cx = tonumber(args[1]) or 80
        local cy = tonumber(args[2]) or 50
        local rx = tonumber(args[3]) or 20
        local ry = tonumber(args[4]) or 10
        local color = ParseColor(args[5])
        if GFX then GFX.Ellipse(cx, cy, rx, ry, color) end
    elseif cmd == "fellipse" then
        local cx = tonumber(args[1]) or 80
        local cy = tonumber(args[2]) or 50
        local rx = tonumber(args[3]) or 20
        local ry = tonumber(args[4]) or 10
        local color = ParseColor(args[5])
        if GFX then GFX.FillEllipse(cx, cy, rx, ry, color) end
    elseif cmd == "ngon" then
        local cx = tonumber(args[1]) or 80
        local cy = tonumber(args[2]) or 50
        local r = tonumber(args[3]) or 20
        local sides = tonumber(args[4]) or 6
        local color = ParseColor(args[5])
        if GFX then GFX.RegularPolygon(cx, cy, r, sides, color, false) end
    elseif cmd == "fngon" then
        local cx = tonumber(args[1]) or 80
        local cy = tonumber(args[2]) or 50
        local r = tonumber(args[3]) or 20
        local sides = tonumber(args[4]) or 6
        local color = ParseColor(args[5])
        if GFX then GFX.RegularPolygon(cx, cy, r, sides, color, true) end
    elseif cmd == "sphere3" then
        local x = tonumber(args[1]) or 0
        local y = tonumber(args[2]) or 0
        local z = tonumber(args[3]) or 100
        local r = tonumber(args[4]) or 20
        local color = ParseColor(args[5])
        if GFX then GFX.Sphere3D(x, y, z, r, color) end
    elseif cmd == "pyramid3" then
        local x = tonumber(args[1]) or 0
        local y = tonumber(args[2]) or 0
        local z = tonumber(args[3]) or 100
        local size = tonumber(args[4]) or 30
        local color = ParseColor(args[5])
        if GFX then GFX.Pyramid3D(x, y, z, size, color) end
    elseif cmd == "set" then
        local full = table.concat(args, " ")
        local name, valueExpr = string.match(full, "([%w]+)%s*=%s*(.*)")
        if name and valueExpr then
            gameState.vars[name] = EvalMath(valueExpr)
        end
    elseif cmd == "add" then
        local varName = args[1]
        local amount = tonumber(args[2]) or 1
        if varName then
            gameState.vars[varName] = (tonumber(gameState.vars[varName]) or 0) + amount
        end
    elseif cmd == "sub" then
        local varName = args[1]
        local amount = tonumber(args[2]) or 1
        if varName then
            gameState.vars[varName] = (tonumber(gameState.vars[varName]) or 0) - amount
        end
    elseif cmd == "mul" then
        local varName = args[1]
        local amount = tonumber(args[2]) or 1
        if varName then
            gameState.vars[varName] = (tonumber(gameState.vars[varName]) or 0) * amount
        end
    elseif cmd == "sin" then
        local varName = args[1]
        local angle = tonumber(args[2]) or 0
        if varName then
            gameState.vars[varName] = math.floor(math.sin(math.rad(angle)) * 100)
        end
    elseif cmd == "cos" then
        local varName = args[1]
        local angle = tonumber(args[2]) or 0
        if varName then
            gameState.vars[varName] = math.floor(math.cos(math.rad(angle)) * 100)
        end
    elseif cmd == "sqrt" then
        local varName = args[1]
        local value = tonumber(args[2]) or 0
        if varName then
            gameState.vars[varName] = math.floor(math.sqrt(math.abs(value)))
        end
    elseif cmd == "dist" then
        local varName = args[1]
        local x1 = tonumber(args[2]) or 0
        local y1 = tonumber(args[3]) or 0
        local x2 = tonumber(args[4]) or 0
        local y2 = tonumber(args[5]) or 0
        if varName then
            local dx = x2 - x1
            local dy = y2 - y1
            gameState.vars[varName] = math.floor(math.sqrt(dx*dx + dy*dy))
        end
    elseif cmd == "atan2" then
        local varName = args[1]
        local y = tonumber(args[2]) or 0
        local x = tonumber(args[3]) or 0
        if varName then
            gameState.vars[varName] = math.floor(math.deg(math.atan2(y, x)))
        end
    elseif cmd == "abs" then
        local varName = args[1]
        local value = tonumber(args[2]) or 0
        if varName then
            gameState.vars[varName] = math.abs(value)
        end
    elseif cmd == "mod" then
        local varName = args[1]
        local a = tonumber(args[2]) or 0
        local b = tonumber(args[3]) or 1
        if varName and b ~= 0 then
            gameState.vars[varName] = a % b
        end
    elseif cmd == "div" then
        local varName = args[1]
        local a = tonumber(args[2]) or 0
        local b = tonumber(args[3]) or 1
        if varName and b ~= 0 then
            gameState.vars[varName] = math.floor(a / b)
        end
    elseif cmd == "pow" then
        local varName = args[1]
        local base = tonumber(args[2]) or 0
        local exp = tonumber(args[3]) or 1
        if varName then
            gameState.vars[varName] = math.floor(math.pow(base, exp))
        end
    elseif cmd == "min" then
        local varName = args[1]
        local a = tonumber(args[2]) or 0
        local b = tonumber(args[3]) or 0
        if varName then
            gameState.vars[varName] = math.min(a, b)
        end
    elseif cmd == "max" then
        local varName = args[1]
        local a = tonumber(args[2]) or 0
        local b = tonumber(args[3]) or 0
        if varName then
            gameState.vars[varName] = math.max(a, b)
        end
    elseif cmd == "lerp" then
        local varName = args[1]
        local a = tonumber(args[2]) or 0
        local b = tonumber(args[3]) or 0
        local t = tonumber(args[4]) or 50
        if varName then
            local frac = t / 100
            gameState.vars[varName] = math.floor(a + (b - a) * frac)
        end
    elseif cmd == "clamp" then
        local varName = args[1]
        local val = tonumber(args[2]) or 0
        local lo = tonumber(args[3]) or 0
        local hi = tonumber(args[4]) or 100
        if varName then
            gameState.vars[varName] = math.max(lo, math.min(hi, val))
        end
    elseif cmd == "key" then
        local varName = args[1] or "K"
        gameState.vars[varName] = gameState.keyBuffer ~= "" and gameState.keyBuffer or gameState.lastKey
    elseif cmd == "mouse" then
        if VOIDTERM.Graphics then
            local mx, my = VOIDTERM.Graphics.GetMousePos()
            gameState.vars["MX"] = mx
            gameState.vars["MY"] = my
            gameState.vars["MB"] = VOIDTERM.Graphics.IsMouseDown() and 1 or 0
            gameState.vars["MB2"] = VOIDTERM.Graphics.IsMouseRightDown() and 1 or 0
        end
    elseif cmd == "rnd" then
        local min = tonumber(args[1]) or 1
        local max = tonumber(args[2]) or 100
        gameState.vars["RND"] = math.random(min, max)
    elseif cmd == "mark" then
    elseif cmd == "jump" then
        local labelName = args[1]
        if labelName and gameState.labels[labelName] then
            gameState.currentLine = gameState.labels[labelName]
        end
    elseif cmd == "if" then
        local full = table.concat(args, " ")
        local left, op, right, thenCmd
        left, right, thenCmd = string.match(full, "(.-)%s*>=%s*(.-)%s+[Tt][Hh][Ee][Nn]%s+(.+)")
        if left then op = ">=" end
        if not op then
            left, right, thenCmd = string.match(full, "(.-)%s*<=%s*(.-)%s+[Tt][Hh][Ee][Nn]%s+(.+)")
            if left then op = "<=" end
        end
        if not op then
            left, right, thenCmd = string.match(full, "(.-)%s*!=%s*(.-)%s+[Tt][Hh][Ee][Nn]%s+(.+)")
            if left then op = "!=" end
        end
        if not op then
            left, right, thenCmd = string.match(full, "(.-)%s*==%s*(.-)%s+[Tt][Hh][Ee][Nn]%s+(.+)")
            if left then op = "==" end
        end
        if not op then
            left, right, thenCmd = string.match(full, "(.-)%s*>%s*(.-)%s+[Tt][Hh][Ee][Nn]%s+(.+)")
            if left then op = ">" end
        end
        if not op then
            left, right, thenCmd = string.match(full, "(.-)%s*<%s*(.-)%s+[Tt][Hh][Ee][Nn]%s+(.+)")
            if left then op = "<" end
        end
        if left and right and thenCmd and op then
            left = string.Trim(left)
            right = string.Trim(right)
            local lnum = tonumber(left)
            local rnum = tonumber(right)
            local result = false
            if lnum and rnum then
                if op == "==" then result = lnum == rnum
                elseif op == "!=" then result = lnum ~= rnum
                elseif op == ">" then result = lnum > rnum
                elseif op == "<" then result = lnum < rnum
                elseif op == ">=" then result = lnum >= rnum
                elseif op == "<=" then result = lnum <= rnum
                end
            else
                if op == "==" then result = left == right
                elseif op == "!=" then result = left ~= right
                else result = left == right end
            end
            if result then
                ExecuteCommand(thenCmd)
            end
        end
    elseif cmd == "wait" then
        local seconds = tonumber(args[1]) or 0.1
        gameState.waitUntil = CurTime() + seconds
    elseif cmd == "echo" then
        local text = table.concat(args, " ")
    elseif cmd == "halt" then
        VOIDTERM.Game.Stop()
    elseif cmd == "tone" then
        local freq = tonumber(args[1]) or 800
        local dur = tonumber(args[2]) or 200
        if VOIDTERM.Beep and VOIDTERM.Beep.Play then
            VOIDTERM.Beep.Play(freq, dur)
        end
    elseif cmd == "gr" then
        gameState.graphicsMode = true
        if GFX then GFX.Enable(160, 100) end
    elseif cmd == "cls" then
        if GFX then GFX.Clear() end
    elseif cmd == "pset" then
        local x = tonumber(args[1]) or 0
        local y = tonumber(args[2]) or 0
        if GFX then GFX.Pixel(x, y, ParseColor(args[3])) end
    elseif cmd == "let" then
        local full = table.concat(args, " ")
        local name, valueExpr = string.match(full, "([%w]+)%s*=%s*(.*)")
        if name and valueExpr then
            gameState.vars[name] = EvalMath(valueExpr)
        end
    elseif cmd == "get" then
        local varName = args[1] or "K"
        gameState.vars[varName] = gameState.keyBuffer ~= "" and gameState.keyBuffer or gameState.lastKey
    elseif cmd == "label" then
    elseif cmd == "goto" then
        local labelName = args[1]
        if labelName and gameState.labels[labelName] then
            gameState.currentLine = gameState.labels[labelName]
        end
    end
end
local lastKeyState = {}
local function UpdateKeyBuffer()
    gameState.keyBuffer = ""
    local keys = {
        {KEY_W, "W"}, {KEY_A, "A"}, {KEY_S, "S"}, {KEY_D, "D"},
        {KEY_UP, "W"}, {KEY_LEFT, "A"}, {KEY_DOWN, "S"}, {KEY_RIGHT, "D"},
        {KEY_SPACE, "SPACE"}, {KEY_ENTER, "ENTER"},
    }
    for _, k in ipairs(keys) do
        local isDown = input.IsKeyDown(k[1])
        local wasDown = lastKeyState[k[1]] or false
        if isDown and not wasDown then
            gameState.keyBuffer = k[2]
        end
        lastKeyState[k[1]] = isDown
    end
    gameState.lastKey = ""
    if input.IsKeyDown(KEY_W) or input.IsKeyDown(KEY_UP) then gameState.lastKey = "W"
    elseif input.IsKeyDown(KEY_A) or input.IsKeyDown(KEY_LEFT) then gameState.lastKey = "A"
    elseif input.IsKeyDown(KEY_S) or input.IsKeyDown(KEY_DOWN) then gameState.lastKey = "S"
    elseif input.IsKeyDown(KEY_D) or input.IsKeyDown(KEY_RIGHT) then gameState.lastKey = "D"
    elseif input.IsKeyDown(KEY_SPACE) then gameState.lastKey = "SPACE"
    end
end
local function GameThink()
    if not gameState.running then return end
    UpdateKeyBuffer()
    if input.IsKeyDown(KEY_TAB) then
        VOIDTERM.Game.Stop()
        return
    end
    if CurTime() < gameState.waitUntil then
        return
    end
    local linesThisFrame = 0
    local maxLinesPerFrame = 500
    while linesThisFrame < maxLinesPerFrame do
        if gameState.currentLine > #gameState.lines then
            VOIDTERM.Game.Stop()
            return
        end
        local line = gameState.lines[gameState.currentLine]
        local prevLine = gameState.currentLine
        ExecuteCommand(line)
        linesThisFrame = linesThisFrame + 1
        if gameState.currentLine == prevLine then
            gameState.currentLine = gameState.currentLine + 1
        end
        if CurTime() < gameState.waitUntil then
            break
        end
    end
end
hook.Add("Think", "VOIDTERM_GameLoop", GameThink)
function VOIDTERM.Game.Run(script)
    gameState.lines = string.Split(script, "\n")
    gameState.labels = {}
    gameState.vars = {}
    gameState.currentLine = 1
    gameState.waitUntil = 0
    gameState.lastKey = ""
    gameState.keyBuffer = ""
    gameState.graphicsMode = false
    lastKeyState = {}
    for i, line in ipairs(gameState.lines) do
        line = string.Trim(line)
        local markName = string.match(line, "^[Mm][Aa][Rr][Kk]%s+(%w+)")
        if markName then gameState.labels[markName] = i end
        local labelName = string.match(line, "^[Ll][Aa][Bb][Ee][Ll]%s+(%w+)")
        if labelName then gameState.labels[labelName] = i end
    end
    gameState.running = true
end
function VOIDTERM.Game.Stop()
    gameState.running = false
    gameState.graphicsMode = false
    if VOIDTERM.Graphics then
        VOIDTERM.Graphics.Disable()
    end
    if gameState.onStop then
        gameState.onStop()
    end
end
function VOIDTERM.Game.IsRunning()
    return gameState.running
end
function VOIDTERM.Game.IsGraphicsMode()
    return gameState.graphicsMode
end
function VOIDTERM.Game.SetStopCallback(callback)
    gameState.onStop = callback
end
function VOIDTERM.Game.IsHighResMode()
    return false
end
function VOIDTERM.Game.GetBuffer()
    if VOIDTERM.Graphics then
        return VOIDTERM.Graphics.GetBuffer()
    end
    return {}, 160, 100
end
function VOIDTERM.Game.GetDrawilleBuffer()
    return nil
end
