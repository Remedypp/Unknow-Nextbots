VOIDTERM = VOIDTERM or {}
VOIDTERM.Graphics = {}
local state = {
    enabled = false,
    width = 160,
    height = 100,
    buffer = {},
    inputCallback = nil,
    menuState = nil,
    camX = 0,
    camY = 0,
    camZ = -200,
    camRotX = 0,
    camRotY = 0,
    fov = 200,
}
function VOIDTERM.Graphics.Init(menuState)
    state.menuState = menuState
    VOIDTERM.Graphics.Clear()
end
function VOIDTERM.Graphics.SetInputCallback(callback)
    state.inputCallback = callback
end
function VOIDTERM.Graphics.Enable(w, h)
    state.width = w or 160
    state.height = h or 100
    state.enabled = true
    if state.menuState then
        state.menuState.graphicsMode = true
        state.menuState.graphicsWidth = state.width
        state.menuState.graphicsHeight = state.height
    end
    VOIDTERM.Graphics.Clear()
    if state.inputCallback then
        state.inputCallback(false)
    end
end
function VOIDTERM.Graphics.Disable()
    state.enabled = false
    if state.menuState then
        state.menuState.graphicsMode = false
    end
    if state.inputCallback then
        state.inputCallback(true)
    end
end
function VOIDTERM.Graphics.IsEnabled()
    return state.enabled
end
function VOIDTERM.Graphics.SetResolution(w, h)
    w = math.Clamp(w or 160, 16, 320)
    h = math.Clamp(h or 100, 16, 200)
    state.width = w
    state.height = h
    if state.menuState then
        state.menuState.graphicsWidth = w
        state.menuState.graphicsHeight = h
    end
    VOIDTERM.Graphics.Clear()
end
function VOIDTERM.Graphics.GetResolution()
    return state.width, state.height
end
function VOIDTERM.Graphics.Clear(color)
    state.buffer = {}
    if color then
        for i = 1, state.width * state.height do
            state.buffer[i] = color
        end
    end
    if state.menuState then
        state.menuState.graphicsBuffer = state.buffer
        state.menuState.graphicsWidth = state.width
        state.menuState.graphicsHeight = state.height
    end
end
function VOIDTERM.Graphics.GetBuffer()
    return state.buffer, state.width, state.height
end
local function RawPixel(x, y, color)
    if x >= 0 and x < state.width and y >= 0 and y < state.height then
        state.buffer[y * state.width + x + 1] = color
    end
end
local function SyncBuffer()
    if state.menuState then
        state.menuState.graphicsBuffer = state.buffer
    end
end
function VOIDTERM.Graphics.Pixel(x, y, color)
    x = math.floor(x)
    y = math.floor(y)
    color = color or Color(0, 255, 65)
    RawPixel(x, y, color)
    SyncBuffer()
end
function VOIDTERM.Graphics.Line(x1, y1, x2, y2, color)
    x1 = math.floor(x1)
    y1 = math.floor(y1)
    x2 = math.floor(x2)
    y2 = math.floor(y2)
    color = color or Color(0, 255, 65)
    local dx = math.abs(x2 - x1)
    local dy = math.abs(y2 - y1)
    local sx = x1 < x2 and 1 or -1
    local sy = y1 < y2 and 1 or -1
    local err = dx - dy
    local maxIter = dx + dy + 1
    for i = 1, maxIter do
        RawPixel(x1, y1, color)
        if x1 == x2 and y1 == y2 then break end
        local e2 = 2 * err
        if e2 > -dy then err = err - dy; x1 = x1 + sx end
        if e2 < dx then err = err + dx; y1 = y1 + sy end
    end
    SyncBuffer()
end
function VOIDTERM.Graphics.Rect(x, y, w, h, color)
    color = color or Color(0, 255, 65)
    x = math.floor(x)
    y = math.floor(y)
    w = math.floor(w)
    h = math.floor(h)
    for i = 0, w - 1 do
        RawPixel(x + i, y, color)
        RawPixel(x + i, y + h - 1, color)
    end
    for i = 0, h - 1 do
        RawPixel(x, y + i, color)
        RawPixel(x + w - 1, y + i, color)
    end
    SyncBuffer()
end
function VOIDTERM.Graphics.FillRect(x, y, w, h, color)
    color = color or Color(0, 255, 65)
    x = math.floor(x)
    y = math.floor(y)
    w = math.floor(w)
    h = math.floor(h)
    for py = y, y + h - 1 do
        for px = x, x + w - 1 do
            RawPixel(px, py, color)
        end
    end
    SyncBuffer()
end
function VOIDTERM.Graphics.Circle(cx, cy, r, color)
    color = color or Color(0, 255, 65)
    cx = math.floor(cx)
    cy = math.floor(cy)
    r = math.floor(r)
    local x = r
    local y = 0
    local err = 1 - r
    while x >= y do
        RawPixel(cx + x, cy + y, color)
        RawPixel(cx - x, cy + y, color)
        RawPixel(cx + x, cy - y, color)
        RawPixel(cx - x, cy - y, color)
        RawPixel(cx + y, cy + x, color)
        RawPixel(cx - y, cy + x, color)
        RawPixel(cx + y, cy - x, color)
        RawPixel(cx - y, cy - x, color)
        y = y + 1
        if err < 0 then
            err = err + 2 * y + 1
        else
            x = x - 1
            err = err + 2 * (y - x) + 1
        end
    end
    SyncBuffer()
end
function VOIDTERM.Graphics.FillCircle(cx, cy, r, color)
    color = color or Color(0, 255, 65)
    cx = math.floor(cx)
    cy = math.floor(cy)
    r = math.floor(r)
    for py = -r, r do
        for px = -r, r do
            if px * px + py * py <= r * r then
                RawPixel(cx + px, cy + py, color)
            end
        end
    end
    SyncBuffer()
end
function VOIDTERM.Graphics.SmoothCircle(cx, cy, r, color)
    color = color or Color(0, 255, 65)
    cx = math.floor(cx)
    cy = math.floor(cy)
    local r2 = r * r
    local ri = math.floor(r)
    local edgeColor = Color(
        math.floor(color.r * 0.5),
        math.floor(color.g * 0.5),
        math.floor(color.b * 0.5),
        color.a or 255
    )
    for py = -(ri + 1), ri + 1 do
        for px = -(ri + 1), ri + 1 do
            local dist2 = px * px + py * py
            if dist2 <= r2 * 0.7 then
                RawPixel(cx + px, cy + py, color)
            elseif dist2 <= r2 then
                RawPixel(cx + px, cy + py, edgeColor)
            elseif dist2 <= r2 * 1.3 then
                local glowColor = Color(
                    math.floor(color.r * 0.2),
                    math.floor(color.g * 0.2),
                    math.floor(color.b * 0.2),
                    color.a or 255
                )
                RawPixel(cx + px, cy + py, glowColor)
            end
        end
    end
    SyncBuffer()
end
function VOIDTERM.Graphics.Ellipse(cx, cy, rx, ry, color)
    color = color or Color(0, 255, 65)
    cx = math.floor(cx)
    cy = math.floor(cy)
    local segments = math.max(16, math.floor(math.max(rx, ry) * 4))
    local prevX, prevY
    for i = 0, segments do
        local angle = (i / segments) * math.pi * 2
        local px = math.floor(cx + math.cos(angle) * rx)
        local py = math.floor(cy + math.sin(angle) * ry)
        if prevX then
            VOIDTERM.Graphics.Line(prevX, prevY, px, py, color)
        end
        prevX, prevY = px, py
    end
end
function VOIDTERM.Graphics.FillEllipse(cx, cy, rx, ry, color)
    color = color or Color(0, 255, 65)
    cx = math.floor(cx)
    cy = math.floor(cy)
    local rxi = math.floor(rx)
    local ryi = math.floor(ry)
    for py = -ryi, ryi do
        for px = -rxi, rxi do
            local dx = px / math.max(rx, 0.01)
            local dy = py / math.max(ry, 0.01)
            if dx * dx + dy * dy <= 1 then
                RawPixel(cx + px, cy + py, color)
            end
        end
    end
    SyncBuffer()
end
function VOIDTERM.Graphics.Polygon(points, color)
    color = color or Color(0, 255, 65)
    if #points < 2 then return end
    for i = 1, #points do
        local next = (i % #points) + 1
        VOIDTERM.Graphics.Line(
            math.floor(points[i][1]), math.floor(points[i][2]),
            math.floor(points[next][1]), math.floor(points[next][2]),
            color
        )
    end
end
function VOIDTERM.Graphics.FillPolygon(points, color)
    color = color or Color(0, 255, 65)
    if #points < 3 then return end
    local cx, cy = 0, 0
    for _, p in ipairs(points) do
        cx = cx + p[1]
        cy = cy + p[2]
    end
    cx = cx / #points
    cy = cy / #points
    for i = 1, #points do
        local next = (i % #points) + 1
        VOIDTERM.Graphics.FillTriangle(
            cx, cy,
            points[i][1], points[i][2],
            points[next][1], points[next][2],
            color
        )
    end
end
function VOIDTERM.Graphics.RegularPolygon(cx, cy, r, sides, color, filled)
    color = color or Color(0, 255, 65)
    sides = math.max(3, sides or 6)
    local points = {}
    for i = 0, sides - 1 do
        local angle = (i / sides) * math.pi * 2 - math.pi / 2
        table.insert(points, {
            cx + math.cos(angle) * r,
            cy + math.sin(angle) * r
        })
    end
    if filled then
        VOIDTERM.Graphics.FillPolygon(points, color)
    else
        VOIDTERM.Graphics.Polygon(points, color)
    end
end
function VOIDTERM.Graphics.Sphere3D(x, y, z, r, color)
    color = color or Color(0, 255, 65)
    local latSteps = 6
    local lonSteps = 8
    for lat = 1, latSteps - 1 do
        local phi = (lat / latSteps) * math.pi
        local ringR = r * math.sin(phi)
        local ringY = y + r * math.cos(phi)
        local prevSX, prevSY
        for lon = 0, lonSteps do
            local theta = (lon / lonSteps) * math.pi * 2
            local px = x + ringR * math.cos(theta)
            local pz = z + ringR * math.sin(theta)
            local sx, sy = VOIDTERM.Graphics.Project(px, ringY, pz)
            if sx and prevSX then
                VOIDTERM.Graphics.Line(prevSX, prevSY, sx, sy, color)
            end
            if sx then prevSX, prevSY = sx, sy end
        end
    end
    for lon = 0, lonSteps - 1 do
        local theta = (lon / lonSteps) * math.pi * 2
        local prevSX, prevSY
        for lat = 0, latSteps do
            local phi = (lat / latSteps) * math.pi
            local px = x + r * math.sin(phi) * math.cos(theta)
            local py = y + r * math.cos(phi)
            local pz = z + r * math.sin(phi) * math.sin(theta)
            local sx, sy = VOIDTERM.Graphics.Project(px, py, pz)
            if sx and prevSX then
                VOIDTERM.Graphics.Line(prevSX, prevSY, sx, sy, color)
            end
            if sx then prevSX, prevSY = sx, sy end
        end
    end
end
function VOIDTERM.Graphics.Pyramid3D(x, y, z, size, color)
    color = color or Color(0, 255, 65)
    local s = size / 2
    local apex = {x, y - size, z}
    local b1 = {x - s, y, z - s}
    local b2 = {x + s, y, z - s}
    local b3 = {x + s, y, z + s}
    local b4 = {x - s, y, z + s}
    VOIDTERM.Graphics.Line3D(b1[1],b1[2],b1[3], b2[1],b2[2],b2[3], color)
    VOIDTERM.Graphics.Line3D(b2[1],b2[2],b2[3], b3[1],b3[2],b3[3], color)
    VOIDTERM.Graphics.Line3D(b3[1],b3[2],b3[3], b4[1],b4[2],b4[3], color)
    VOIDTERM.Graphics.Line3D(b4[1],b4[2],b4[3], b1[1],b1[2],b1[3], color)
    VOIDTERM.Graphics.Line3D(apex[1],apex[2],apex[3], b1[1],b1[2],b1[3], color)
    VOIDTERM.Graphics.Line3D(apex[1],apex[2],apex[3], b2[1],b2[2],b2[3], color)
    VOIDTERM.Graphics.Line3D(apex[1],apex[2],apex[3], b3[1],b3[2],b3[3], color)
    VOIDTERM.Graphics.Line3D(apex[1],apex[2],apex[3], b4[1],b4[2],b4[3], color)
end
function VOIDTERM.Graphics.Triangle(x1, y1, x2, y2, x3, y3, color)
    VOIDTERM.Graphics.Line(x1, y1, x2, y2, color)
    VOIDTERM.Graphics.Line(x2, y2, x3, y3, color)
    VOIDTERM.Graphics.Line(x3, y3, x1, y1, color)
end
function VOIDTERM.Graphics.FillTriangle(x1, y1, x2, y2, x3, y3, color)
    color = color or Color(0, 255, 65)
    x1 = math.floor(x1); y1 = math.floor(y1)
    x2 = math.floor(x2); y2 = math.floor(y2)
    x3 = math.floor(x3); y3 = math.floor(y3)
    if y1 > y2 then x1, y1, x2, y2 = x2, y2, x1, y1 end
    if y1 > y3 then x1, y1, x3, y3 = x3, y3, x1, y1 end
    if y2 > y3 then x2, y2, x3, y3 = x3, y3, x2, y2 end
    local totalH = y3 - y1
    if totalH == 0 then return end
    for y = y1, y3 do
        local second = y > y2 or y2 == y1
        local segH = second and (y3 - y2) or (y2 - y1)
        if segH == 0 then segH = 1 end
        local alpha = (y - y1) / totalH
        local beta = second and ((y - y2) / segH) or ((y - y1) / segH)
        local ax = math.floor(x1 + (x3 - x1) * alpha)
        local bx
        if second then
            bx = math.floor(x2 + (x3 - x2) * beta)
        else
            bx = math.floor(x1 + (x2 - x1) * beta)
        end
        if ax > bx then ax, bx = bx, ax end
        for px = ax, bx do
            RawPixel(px, y, color)
        end
    end
    SyncBuffer()
end
local MINI_FONT = {
    ["0"] = {0x69996}, ["1"] = {0x26227}, ["2"] = {0xE1E8F}, ["3"] = {0xE1E1E},
    ["4"] = {0x99F11}, ["5"] = {0xF8E1E}, ["6"] = {0x68E9E}, ["7"] = {0xF1248},
    ["8"] = {0x69696}, ["9"] = {0x69711}, ["A"] = {0x69F99}, ["B"] = {0xE9E9E},
    ["C"] = {0x68896}, ["D"] = {0xE999E}, ["E"] = {0xF8E8F}, ["F"] = {0xF8E88},
    ["G"] = {0x689B6}, ["H"] = {0x99F99}, ["I"] = {0xE444E}, ["J"] = {0x1119E},
    ["K"] = {0x9ACA9}, ["L"] = {0x8888F}, ["M"] = {0x9F999}, ["N"] = {0x9DB99},
    ["O"] = {0x69996}, ["P"] = {0xE9E88}, ["Q"] = {0x6999A}, ["R"] = {0xE9EA9},
    ["S"] = {0x68196}, ["T"] = {0xF4444}, ["U"] = {0x99996}, ["V"] = {0x99966},
    ["W"] = {0x999F9}, ["X"] = {0x96699}, ["Y"] = {0x99644}, ["Z"] = {0xF1248},
    [" "] = {0x00000}, ["."] = {0x00004}, [","] = {0x00024}, ["!"] = {0x44404},
    ["?"] = {0x61200}, [":"] = {0x04040}, ["-"] = {0x00E00}, ["+"] = {0x04E40},
    ["="] = {0x0E0E0}, ["/"] = {0x12480}, ["("] = {0x24842}, [")"] = {0x42124},
    ["_"] = {0x0000F}, ["*"] = {0x04A40}, ["#"] = {0x5F5F5},
}
function VOIDTERM.Graphics.Text(x, y, text, color)
    color = color or Color(0, 255, 65)
    x = math.floor(x)
    y = math.floor(y)
    text = string.upper(tostring(text))
    for ci = 1, #text do
        local ch = text:sub(ci, ci)
        local glyph = MINI_FONT[ch]
        if glyph then
            local bits = glyph[1] or 0
            for py = 0, 4 do
                for px = 0, 3 do
                    local bitPos = (4 - py) * 4 + (3 - px)
                    if bit.band(bits, bit.lshift(1, bitPos)) ~= 0 then
                        RawPixel(x + (ci - 1) * 5 + px, y + py, color)
                    end
                end
            end
        end
    end
    SyncBuffer()
end
function VOIDTERM.Graphics.BigText(x, y, text, color)
    color = color or Color(0, 255, 65)
    x = math.floor(x)
    y = math.floor(y)
    text = string.upper(tostring(text))
    for ci = 1, #text do
        local ch = text:sub(ci, ci)
        local glyph = MINI_FONT[ch]
        if glyph then
            local bits = glyph[1] or 0
            for py = 0, 4 do
                for px = 0, 3 do
                    local bitPos = (4 - py) * 4 + (3 - px)
                    if bit.band(bits, bit.lshift(1, bitPos)) ~= 0 then
                        local bx = x + (ci - 1) * 9 + px * 2
                        local by = y + py * 2
                        RawPixel(bx, by, color)
                        RawPixel(bx + 1, by, color)
                        RawPixel(bx, by + 1, color)
                        RawPixel(bx + 1, by + 1, color)
                    end
                end
            end
        end
    end
    SyncBuffer()
end
function VOIDTERM.Graphics.SetCamera(x, y, z, rotX, rotY)
    state.camX = x or 0
    state.camY = y or 0
    state.camZ = z or -200
    state.camRotX = rotX or 0
    state.camRotY = rotY or 0
    state.fov = 200
end
function VOIDTERM.Graphics.Project(x, y, z)
    local rx = x - state.camX
    local ry = y - state.camY
    local rz = z - state.camZ
    local cosY = math.cos(state.camRotY)
    local sinY = math.sin(state.camRotY)
    local tx = rx * cosY - rz * sinY
    local tz = rx * sinY + rz * cosY
    local cosX = math.cos(state.camRotX)
    local sinX = math.sin(state.camRotX)
    local ty = ry * cosX - tz * sinX
    rz = ry * sinX + tz * cosX
    if rz <= 0.1 then return nil, nil, rz end
    local fov = state.fov
    local sx = math.floor(state.width / 2 + (tx * fov) / rz)
    local sy = math.floor(state.height / 2 - (ty * fov) / rz)
    return sx, sy, rz
end
function VOIDTERM.Graphics.Line3D(x1, y1, z1, x2, y2, z2, color)
    local sx1, sy1 = VOIDTERM.Graphics.Project(x1, y1, z1)
    local sx2, sy2 = VOIDTERM.Graphics.Project(x2, y2, z2)
    if sx1 and sx2 then
        VOIDTERM.Graphics.Line(sx1, sy1, sx2, sy2, color)
    end
end
function VOIDTERM.Graphics.Cube3D(x, y, z, size, color)
    local s = size / 2
    local verts = {
        {x-s, y-s, z-s}, {x+s, y-s, z-s},
        {x+s, y+s, z-s}, {x-s, y+s, z-s},
        {x-s, y-s, z+s}, {x+s, y-s, z+s},
        {x+s, y+s, z+s}, {x-s, y+s, z+s},
    }
    local edges = {
        {1,2},{2,3},{3,4},{4,1},
        {5,6},{6,7},{7,8},{8,5},
        {1,5},{2,6},{3,7},{4,8},
    }
    for _, edge in ipairs(edges) do
        local v1 = verts[edge[1]]
        local v2 = verts[edge[2]]
        VOIDTERM.Graphics.Line3D(v1[1],v1[2],v1[3], v2[1],v2[2],v2[3], color)
    end
end
function VOIDTERM.Graphics.Triangle3D(x1,y1,z1, x2,y2,z2, x3,y3,z3, color)
    VOIDTERM.Graphics.Line3D(x1,y1,z1, x2,y2,z2, color)
    VOIDTERM.Graphics.Line3D(x2,y2,z2, x3,y3,z3, color)
    VOIDTERM.Graphics.Line3D(x3,y3,z3, x1,y1,z1, color)
end
function VOIDTERM.Graphics.GetKey()
    if input.IsKeyDown(KEY_W) or input.IsKeyDown(KEY_UP) then return "W" end
    if input.IsKeyDown(KEY_A) or input.IsKeyDown(KEY_LEFT) then return "A" end
    if input.IsKeyDown(KEY_S) or input.IsKeyDown(KEY_DOWN) then return "S" end
    if input.IsKeyDown(KEY_D) or input.IsKeyDown(KEY_RIGHT) then return "D" end
    if input.IsKeyDown(KEY_SPACE) then return "SPACE" end
    if input.IsKeyDown(KEY_ENTER) then return "ENTER" end
    if input.IsKeyDown(KEY_TAB) then return "TAB" end
    return ""
end
function VOIDTERM.Graphics.CheckExit()
    return input.IsKeyDown(KEY_TAB)
end
VOIDTERM.Graphics.renderArea = { x = 0, y = 0, w = 0, h = 0 }
VOIDTERM.Graphics.screenDims = { w = 700, h = 550 }
local frameRef = nil
local BEZEL_MARGIN = 30
function VOIDTERM.Graphics.SetFrame(f)
    frameRef = f
end
function VOIDTERM.Graphics.SetRenderArea(x, y, w, h)
    VOIDTERM.Graphics.renderArea = { x = x, y = y, w = w, h = h }
end
function VOIDTERM.Graphics.SetScreenDims(w, h)
    VOIDTERM.Graphics.screenDims = { w = w, h = h }
end
function VOIDTERM.Graphics.GetMousePos()
    local area = VOIDTERM.Graphics.renderArea
    local screen = VOIDTERM.Graphics.screenDims
    if area.w <= 0 or area.h <= 0 then return -1, -1 end
    local mx, my
    if frameRef and IsValid(frameRef) then
        mx, my = frameRef:CursorPos()
    else
        mx = gui.MouseX()
        my = gui.MouseY()
    end
    mx = mx - BEZEL_MARGIN
    my = my - BEZEL_MARGIN
    local gx = math.floor((mx - area.x) / area.w * state.width)
    local gy = math.floor((my - area.y) / area.h * state.height)
    gx = math.Clamp(gx, 0, state.width - 1)
    gy = math.Clamp(gy, 0, state.height - 1)
    return gx, gy
end
function VOIDTERM.Graphics.IsMouseDown()
    return input.IsMouseDown(MOUSE_LEFT)
end
function VOIDTERM.Graphics.IsMouseRightDown()
    return input.IsMouseDown(MOUSE_RIGHT)
end
