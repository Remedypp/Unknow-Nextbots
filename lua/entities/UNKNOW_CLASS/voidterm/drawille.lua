VOIDTERM = VOIDTERM or {}
VOIDTERM.Drawille = {}
local Drawille = {}
Drawille.__index = Drawille
local BRAILLE_BASE = 0x2800
local PIXEL_MAP = {
    {0x1, 0x8},
    {0x2, 0x10},
    {0x4, 0x20},
    {0x40, 0x80}
}
function VOIDTERM.Drawille.New(width, height)
    local obj = setmetatable({}, Drawille)
    obj.width = width or 80
    obj.height = height or 24
    obj.canvas = {}
    return obj
end
function Drawille:Set(x, y)
    if x < 0 or x >= self.width * 2 or y < 0 or y >= self.height * 4 then return end
    local cx = math.floor(x / 2)
    local cy = math.floor(y / 4)
    local px = (x % 2) + 1
    local py = (y % 4) + 1
    local row = self.canvas[cy] or {}
    self.canvas[cy] = row
    row[cx] = bit.bor(row[cx] or 0, PIXEL_MAP[py][px])
end
function Drawille:Unset(x, y)
    if x < 0 or x >= self.width * 2 or y < 0 or y >= self.height * 4 then return end
    local cx = math.floor(x / 2)
    local cy = math.floor(y / 4)
    local px = (x % 2) + 1
    local py = (y % 4) + 1
    local row = self.canvas[cy]
    if not row then return end
    row[cx] = bit.band(row[cx] or 0, bit.bnot(PIXEL_MAP[py][px]))
end
function Drawille:Clear()
    self.canvas = {}
end
function Drawille:DrawLine(x1, y1, x2, y2)
    local x, y = x1, y1
    local dx = math.abs(x2 - x1)
    local dy = math.abs(y2 - y1)
    local sx = (x1 < x2) and 1 or -1
    local sy = (y1 < y2) and 1 or -1
    local err = dx - dy
    while true do
        self:Set(x, y)
        if x == x2 and y == y2 then break end
        local e2 = 2 * err
        if e2 > -dy then
            err = err - dy
            x = x + sx
        end
        if e2 < dx then
            err = err + dx
            y = y + sy
        end
    end
end
local function CodeToChar(code)
    local val = BRAILLE_BASE + code
    local b1 = 0xE0 + bit.rshift(val, 12)
    local b2 = 0x80 + bit.band(bit.rshift(val, 6), 0x3F)
    local b3 = 0x80 + bit.band(val, 0x3F)
    return string.char(b1, b2, b3)
end
function Drawille:Render()
    local buffer = {}
    for y = 0, self.height - 1 do
        local line = ""
        local row = self.canvas[y] or {}
        for x = 0, self.width - 1 do
            local val = row[x]
            if val and val > 0 then
                line = line .. CodeToChar(val)
            else
                line = line .. " "
            end
        end
        table.insert(buffer, line)
    end
    return table.concat(buffer, "\n")
end
function Drawille:DrawToSurface(x, y, color)
    surface.SetFont("Petrov_Console")
    surface.SetTextColor(color or Color(255, 255, 255))
    local h = 14
    for iy = 0, self.height - 1 do
        local row = self.canvas[iy]
        if row then
            local lineStr = ""
             for ix = 0, self.width - 1 do
                local val = row[ix] or 0
                if val == 0 then
                    lineStr = lineStr .. " "
                else
                    lineStr = lineStr .. CodeToChar(val)
                end
            end
            surface.SetTextPos(x, y + iy * h)
            surface.DrawText(lineStr)
        end
    end
end
