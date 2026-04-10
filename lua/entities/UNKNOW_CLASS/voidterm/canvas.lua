VOIDTERM = VOIDTERM or {}
VOIDTERM.Drawille = {}
local bit = bit or bit32
local band, bor, bnot, bxor = bit.band, bit.bor, bit.bnot, bit.bxor
local pixel_map = {
    {0x01, 0x08},
    {0x02, 0x10},
    {0x04, 0x20},
    {0x40, 0x80}
}
local braille = {}
local braille_offset = 0x2800
for i = 0, 255 do
    local codepoint = braille_offset + i
    local b1 = 128 + 64 + 32 + bit.rshift(bit.band(codepoint, 0xF000), 12)
    local b2 = 128 + bit.band(bit.rshift(codepoint, 6), 0x3F)
    local b3 = 128 + bit.band(codepoint, 0x3F)
    braille[i] = string.char(b1, b2, b3)
end
local EMPTY_BRAILLE = braille[0]
local Canvas = {}
Canvas.__index = Canvas
function Canvas.new(width, height)
    local self = setmetatable({}, Canvas)
    self.charWidth = width or 40
    self.charHeight = height or 25
    self.pixelWidth = self.charWidth * 2
    self.pixelHeight = self.charHeight * 4
    self.matrix = {}
    self:clear()
    return self
end
function Canvas:clear()
    self.matrix = {}
    for row = 0, self.charHeight - 1 do
        self.matrix[row] = {}
        for col = 0, self.charWidth - 1 do
            self.matrix[row][col] = {braille_rep = 0, r = 0, g = 255, b = 65}
        end
    end
end
function Canvas:set(x, y, r, g, b)
    x = math.floor(x)
    y = math.floor(y)
    if x < 0 or x >= self.pixelWidth or y < 0 or y >= self.pixelHeight then
        return
    end
    local row = math.floor(y / 4)
    local col = math.floor(x / 2)
    local dotRow = band(y, 3) + 1
    local dotCol = band(x, 1) + 1
    local cell = self.matrix[row][col]
    cell.braille_rep = bor(cell.braille_rep, pixel_map[dotRow][dotCol])
    cell.r = r or cell.r
    cell.g = g or cell.g
    cell.b = b or cell.b
end
function Canvas:unset(x, y)
    x = math.floor(x)
    y = math.floor(y)
    if x < 0 or x >= self.pixelWidth or y < 0 or y >= self.pixelHeight then
        return
    end
    local row = math.floor(y / 4)
    local col = math.floor(x / 2)
    local dotRow = band(y, 3) + 1
    local dotCol = band(x, 1) + 1
    local cell = self.matrix[row][col]
    cell.braille_rep = band(cell.braille_rep, bnot(pixel_map[dotRow][dotCol]))
end
function Canvas:toggle(x, y, r, g, b)
    x = math.floor(x)
    y = math.floor(y)
    if x < 0 or x >= self.pixelWidth or y < 0 or y >= self.pixelHeight then
        return
    end
    local row = math.floor(y / 4)
    local col = math.floor(x / 2)
    local dotRow = band(y, 3) + 1
    local dotCol = band(x, 1) + 1
    local cell = self.matrix[row][col]
    cell.braille_rep = bxor(cell.braille_rep, pixel_map[dotRow][dotCol])
    cell.r = r or cell.r
    cell.g = g or cell.g
    cell.b = b or cell.b
end
function Canvas:get(x, y)
    x = math.floor(x)
    y = math.floor(y)
    if x < 0 or x >= self.pixelWidth or y < 0 or y >= self.pixelHeight then
        return false
    end
    local row = math.floor(y / 4)
    local col = math.floor(x / 2)
    local dotRow = band(y, 3) + 1
    local dotCol = band(x, 1) + 1
    local cell = self.matrix[row][col]
    return band(cell.braille_rep, pixel_map[dotRow][dotCol]) ~= 0
end
function Canvas:line(x1, y1, x2, y2, r, g, b)
    x1, y1 = math.floor(x1 + 0.5), math.floor(y1 + 0.5)
    x2, y2 = math.floor(x2 + 0.5), math.floor(y2 + 0.5)
    local dx = math.abs(x2 - x1)
    local dy = -math.abs(y2 - y1)
    local sx = x1 < x2 and 1 or -1
    local sy = y1 < y2 and 1 or -1
    local err = dx + dy
    while true do
        self:set(x1, y1, r, g, b)
        if x1 == x2 and y1 == y2 then break end
        local e2 = 2 * err
        if e2 >= dy then
            err = err + dy
            x1 = x1 + sx
        end
        if e2 <= dx then
            err = err + dx
            y1 = y1 + sy
        end
    end
end
function Canvas:ellipse(xm, ym, a, b, r, g, blue)
    a = math.floor(a + 0.5)
    b = math.floor(b + 0.5)
    local dx, dy = 0, b
    local a2, b2 = a * a, b * b
    local err = b2 - (2 * b - 1) * a2
    while dy >= 0 do
        self:set(xm + dx, ym + dy, r, g, blue)
        self:set(xm - dx, ym + dy, r, g, blue)
        self:set(xm - dx, ym - dy, r, g, blue)
        self:set(xm + dx, ym - dy, r, g, blue)
        local e2 = 2 * err
        if e2 < (2 * dx + 1) * b2 then
            dx = dx + 1
            err = err + (2 * dx + 1) * b2
        end
        if e2 > -(2 * dy - 1) * a2 then
            dy = dy - 1
            err = err - (2 * dy - 1) * a2
        end
    end
end
function Canvas:circle(x, y, radius, r, g, b)
    self:ellipse(x, y, radius, radius, r, g, b)
end
function Canvas:rect(x1, y1, x2, y2, r, g, b)
    for y = y1, y2 do
        for x = x1, x2 do
            self:set(x, y, r, g, b)
        end
    end
end
function Canvas:text(x, y, str, r, g, b)
    local col = math.floor(x / 2)
    local row = math.floor(y / 4)
    for i = 1, #str do
        local c = str:sub(i, i)
        if self.matrix[row] and self.matrix[row][col] then
            local cell = self.matrix[row][col]
            cell.char = c
            cell.r = r or 0
            cell.g = g or 255
            cell.b = b or 65
        end
        col = col + 1
    end
end
function Canvas:getChar(row, col)
    local cell = self.matrix[row] and self.matrix[row][col]
    if not cell then return EMPTY_BRAILLE end
    if cell.char then
        return cell.char
    end
    return braille[cell.braille_rep] or EMPTY_BRAILLE
end
function Canvas:getColor(row, col)
    local cell = self.matrix[row] and self.matrix[row][col]
    if not cell then return Color(0, 255, 65) end
    return Color(cell.r, cell.g, cell.b)
end
function Canvas:getBuffer()
    local buffer = {}
    for row = 0, self.charHeight - 1 do
        buffer[row + 1] = {}
        for col = 0, self.charWidth - 1 do
            buffer[row + 1][col + 1] = {
                char = self:getChar(row, col),
                color = self:getColor(row, col)
            }
        end
    end
    return buffer
end
VOIDTERM.Drawille.Canvas = Canvas
function VOIDTERM.Drawille.new(width, height)
    return Canvas.new(width, height)
end
