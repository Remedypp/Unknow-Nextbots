VOIDTERM = VOIDTERM or {}
VOIDTERM.Experiments = {}
VOIDTERM.Experiments.Active = nil
VOIDTERM.Experiments.State = {}
VOIDTERM.Experiments.StartTime = 0
local function SmoothCircle(x, y, r, color, segments)
    segments = segments or 32
    if r < 1 then return end
    local poly = {}
    for i = 0, segments do
        local a = (i / segments) * math.pi * 2
        poly[#poly + 1] = { x = x + math.cos(a) * r, y = y + math.sin(a) * r }
    end
    draw.NoTexture()
    surface.SetDrawColor(color)
    surface.DrawPoly(poly)
end
local function SmoothRing(x, y, r, thickness, color, segments)
    segments = segments or 32
    if r < 1 then return end
    draw.NoTexture()
    surface.SetDrawColor(color)
    local inner = math.max(0, r - thickness)
    local poly = {}
    for i = 0, segments do
        local a = (i / segments) * math.pi * 2
        local cx, cy = math.cos(a), math.sin(a)
        if i > 0 then
            local pa = ((i-1) / segments) * math.pi * 2
            local pcx, pcy = math.cos(pa), math.sin(pa)
            local quad = {
                { x = x + pcx * inner, y = y + pcy * inner },
                { x = x + pcx * r,     y = y + pcy * r },
                { x = x + cx * r,      y = y + cy * r },
                { x = x + cx * inner,  y = y + cy * inner },
            }
            surface.DrawPoly(quad)
        end
    end
end
local function SmoothLine(x1, y1, x2, y2, thickness, color)
    surface.SetDrawColor(color)
    local dx = x2 - x1
    local dy = y2 - y1
    local len = math.sqrt(dx*dx + dy*dy)
    if len < 0.5 then return end
    local nx = -dy / len * (thickness / 2)
    local ny = dx / len * (thickness / 2)
    draw.NoTexture()
    surface.DrawPoly({
        { x = x1 + nx, y = y1 + ny },
        { x = x1 - nx, y = y1 - ny },
        { x = x2 - nx, y = y2 - ny },
        { x = x2 + nx, y = y2 + ny },
    })
end
local function GlowCircle(x, y, r, color, layers)
    layers = layers or 4
    for i = layers, 1, -1 do
        local alpha = math.floor(color.a * (i / layers) * 0.4)
        local gr = r + (layers - i + 1) * 2
        SmoothCircle(x, y, gr, Color(color.r, color.g, color.b, alpha))
    end
    SmoothCircle(x, y, r, color)
end
local function Lerp(t, a, b)
    return a + (b - a) * t
end
VOIDTERM.Experiments.List = {
    {
        id = "EXP-001",
        name = "CRONOS BLOOD ANALYSIS",
        status = "ACTIVE",
        date = "1665-XX-XX",
        desc="[REDACTED EXPERIMENT]",
        color = Color(180, 0, 0),
    },
    {
        id = "EXP-002",
        name = "DNA HELIX VISUALIZER",
        status = "ACTIVE",
        date = "1953-03-12",
        desc="[REDACTED EXPERIMENT]",
        color = Color(0, 200, 100),
    },
    {
        id = "EXP-003",
        name = "SUBJECT CELL MUTATION",
        status = "CLASSIFIED",
        date = "2008-09-03",
        desc="[REDACTED EXPERIMENT]",
        color = Color(200, 50, 50),
    },
    {
        id = "EXP-004",
        name = "DIMENSIONAL RIFT SCAN",
        status = "ACTIVE",
        date = "1991-02-14",
        desc="[REDACTED EXPERIMENT]",
        color = Color(140, 0, 200),
    },
    {
        id = "EXP-005",
        name = "NEURAL WAVE MONITOR",
        status = "CLASSIFIED",
        date = "2010-XX-XX",
        desc="[REDACTED EXPERIMENT]",
        color = Color(0, 180, 220),
    },
    {
        id = "EXP-006",
        name = "GRAVITATIONAL ANOMALY",
        status = "TERMINATED",
        date = "1985-01-10",
        desc="[REDACTED EXPERIMENT]",
        color = Color(0, 200, 80),
    },
}
local function DrawRBC(x, y, r, corruption, phase)
    local corr = corruption or 0
    local baseR = math.max(0, math.floor(180 - corr * 140))
    local baseG = math.max(0, math.floor(40 - corr * 40))
    local baseB = math.max(0, math.floor(40 - corr * 30))
    local memAlpha = math.floor(160 + corr * 60)
    SmoothCircle(x, y, r, Color(baseR, baseG, baseB, memAlpha))
    local centerR = r * 0.45
    if corr < 0.5 then
        SmoothCircle(x, y, centerR, Color(
            math.min(255, baseR + 60),
            math.min(255, baseG + 30),
            math.min(255, baseB + 30),
            math.floor(100 - corr * 80)
        ))
    else
        SmoothCircle(x, y, centerR * (1 + (corr - 0.5) * 0.6), Color(
            math.floor(20 * (1 - corr)),
            0,
            math.floor(10 * (1 - corr)),
            math.floor(200 + corr * 55)
        ))
        local voidPulse = math.sin(phase * 3) * 0.3
        SmoothCircle(x, y, centerR * 0.3 * (1 + voidPulse), Color(80, 0, 20, math.floor(180 * corr)))
    end
    if corr < 0.7 then
        SmoothCircle(x - r * 0.25, y - r * 0.25, r * 0.15, Color(255, 200, 200, math.floor(80 * (1 - corr))))
    end
    if corr > 0.2 then
        local tendrils = math.floor(corr * 5)
        for t = 1, tendrils do
            local ta = (t / tendrils) * math.pi * 2 + phase * 0.5
            local tx = x + math.cos(ta) * r * 0.7
            local ty = y + math.sin(ta) * r * 0.7
            SmoothCircle(tx, ty, 1.5 * corr, Color(20, 0, 5, math.floor(200 * corr)))
        end
    end
end
local function DrawWBC(x, y, r, wbcType, phase)
    SmoothCircle(x, y, r, Color(180, 190, 210, 100))
    SmoothRing(x, y, r, 1.5, Color(140, 160, 200, 150))
    if wbcType == "neutrophil" then
        local lobes = 3
        for l = 1, lobes do
            local la = (l / lobes) * math.pi * 2 + phase * 0.2
            local lr = r * 0.25
            local lx = x + math.cos(la) * r * 0.3
            local ly = y + math.sin(la) * r * 0.3
            SmoothCircle(lx, ly, lr, Color(80, 40, 120, 200))
            if l > 1 then
                local pla = ((l-1) / lobes) * math.pi * 2 + phase * 0.2
                local plx = x + math.cos(pla) * r * 0.3
                local ply = y + math.sin(pla) * r * 0.3
                SmoothLine(plx, ply, lx, ly, 2, Color(80, 40, 120, 150))
            end
        end
        for g = 1, 8 do
            local ga = (g / 8) * math.pi * 2 + phase
            local gd = r * 0.5 * math.abs(math.sin(ga * 3 + phase))
            local gx = x + math.cos(ga) * gd
            local gy = y + math.sin(ga) * gd
            SmoothCircle(gx, gy, 1, Color(200, 160, 180, 80))
        end
    elseif wbcType == "lymphocyte" then
        SmoothCircle(x, y, r * 0.75, Color(60, 30, 100, 220))
        SmoothCircle(x - r * 0.15, y - r * 0.1, r * 0.15, Color(100, 60, 140, 180))
    end
    local pods = 2 + math.floor(math.sin(phase) + 1.5)
    for p = 1, pods do
        local pa = (p / pods) * math.pi * 2 + phase * 0.3
        local ext = r * 0.2 * (1 + math.sin(phase * 2 + p) * 0.5)
        local px2 = x + math.cos(pa) * (r + ext)
        local py2 = y + math.sin(pa) * (r + ext)
        SmoothCircle(px2, py2, 3, Color(180, 190, 210, 60))
    end
end
local function InitCronos(s)
    s.rbcs = {}
    for i = 1, 25 do
        s.rbcs[i] = {
            rx = 0.1 + math.random() * 0.8,
            ry = 0.1 + math.random() * 0.8,
            r = 6 + math.random() * 5,
            drift_speed = 0.002 + math.random() * 0.005,
            drift_angle = math.random() * math.pi * 2,
            corruption = 0,
            corrupt_rate = 0.01 + math.random() * 0.03,
            phase = math.random() * math.pi * 2,
        }
    end
    s.wbcs = {}
    for i = 1, 3 do
        s.wbcs[i] = {
            rx = 0.2 + math.random() * 0.6,
            ry = 0.2 + math.random() * 0.6,
            r = 14 + math.random() * 4,
            wtype = (i <= 2) and "neutrophil" or "lymphocyte",
            drift_speed = 0.001 + math.random() * 0.003,
            drift_angle = math.random() * math.pi * 2,
            phase = math.random() * math.pi * 2,
        }
    end
    s.platelets = {}
    for i = 1, 12 do
        s.platelets[i] = {
            rx = 0.15 + math.random() * 0.7,
            ry = 0.15 + math.random() * 0.7,
            size = 1.5 + math.random() * 1.5,
            drift_angle = math.random() * math.pi * 2,
        }
    end
    s.voidCenter = { rx = 0.5, ry = 0.5 }
    s.voidRadius = 0
    s.voidPulse = 0
    s.tendrils = {}
    for i = 1, 8 do
        local a = (i / 8) * math.pi * 2
        s.tendrils[i] = {
            angle = a,
            length = 0,
            maxLen = 40 + math.random() * 80,
            speed = 15 + math.random() * 25,
            segments = {},
        }
    end
    s.phase = 0
    s.elapsed = 0
end
local function DrawCronos(s, sx, sy, w, h, dt)
    local cx, cy = sx + w/2, sy + h/2
    s.phase = s.phase + dt * 2
    s.elapsed = s.elapsed + dt
    local fovR = math.min(w, h) * 0.44
    SmoothCircle(cx, cy, fovR, Color(30, 15, 10, 180))
    for i = 1, 4 do
        local fa = (i / 4) * math.pi * 2 + s.phase * 0.1
        local fr = fovR * 0.6
        local fx = cx + math.cos(fa) * fr * 0.3
        local fy = cy + math.sin(fa) * fr * 0.3
        SmoothCircle(fx, fy, fovR * 0.5, Color(35, 18, 12, 30))
    end
    for _, pl in ipairs(s.platelets) do
        local px = sx + pl.rx * w
        local py = sy + pl.ry * h
        local dx = px - cx
        local dy = py - cy
        if math.sqrt(dx*dx + dy*dy) < fovR - 5 then
            SmoothCircle(px, py, pl.size, Color(200, 180, 220, 120))
            SmoothCircle(px + 0.5, py - 0.5, pl.size * 0.5, Color(230, 210, 240, 80))
        end
        pl.rx = pl.rx + math.cos(pl.drift_angle) * 0.001 * dt
        pl.ry = pl.ry + math.sin(pl.drift_angle) * 0.001 * dt
        if pl.rx < 0.1 or pl.rx > 0.9 then pl.drift_angle = math.pi - pl.drift_angle end
        if pl.ry < 0.1 or pl.ry > 0.9 then pl.drift_angle = -pl.drift_angle end
    end
    for _, rbc in ipairs(s.rbcs) do
        local px = sx + rbc.rx * w
        local py = sy + rbc.ry * h
        local dx = px - cx
        local dy = py - cy
        if math.sqrt(dx*dx + dy*dy) < fovR - rbc.r then
            DrawRBC(px, py, rbc.r, rbc.corruption, s.phase + rbc.phase)
        end
        rbc.rx = rbc.rx + math.cos(rbc.drift_angle) * rbc.drift_speed * dt
        rbc.ry = rbc.ry + math.sin(rbc.drift_angle) * rbc.drift_speed * dt
        rbc.drift_angle = rbc.drift_angle + (math.random() - 0.5) * 0.5
        if rbc.rx < 0.08 or rbc.rx > 0.92 then rbc.drift_angle = math.pi - rbc.drift_angle end
        if rbc.ry < 0.08 or rbc.ry > 0.92 then rbc.drift_angle = -rbc.drift_angle end
        if s.elapsed > 2 then
            local vdx = rbc.rx - s.voidCenter.rx
            local vdy = rbc.ry - s.voidCenter.ry
            local vdist = math.sqrt(vdx*vdx + vdy*vdy)
            local corruptReach = (s.elapsed - 2) * 0.04
            if vdist < corruptReach then
                rbc.corruption = math.min(1, rbc.corruption + rbc.corrupt_rate * dt)
            end
        end
    end
    for _, wbc in ipairs(s.wbcs) do
        local px = sx + wbc.rx * w
        local py = sy + wbc.ry * h
        local dx = px - cx
        local dy = py - cy
        if math.sqrt(dx*dx + dy*dy) < fovR - wbc.r then
            DrawWBC(px, py, wbc.r, wbc.wtype, s.phase + wbc.phase)
        end
        if s.elapsed > 3 then
            local tdx = s.voidCenter.rx - wbc.rx
            local tdy = s.voidCenter.ry - wbc.ry
            local td = math.sqrt(tdx*tdx + tdy*tdy)
            if td > 0.05 then
                wbc.rx = wbc.rx + (tdx / td) * 0.008 * dt
                wbc.ry = wbc.ry + (tdy / td) * 0.008 * dt
            end
        else
            wbc.rx = wbc.rx + math.cos(wbc.drift_angle) * wbc.drift_speed * dt
            wbc.ry = wbc.ry + math.sin(wbc.drift_angle) * wbc.drift_speed * dt
            wbc.drift_angle = wbc.drift_angle + (math.random() - 0.5) * 0.3
        end
    end
    local vcx = sx + s.voidCenter.rx * w
    local vcy = sy + s.voidCenter.ry * h
    s.voidPulse = s.voidPulse + dt
    if s.elapsed > 1.5 then
        local growFactor = math.min(1, (s.elapsed - 1.5) * 0.3)
        s.voidRadius = 12 * growFactor
        local vPulse = 1 + math.sin(s.voidPulse * 3) * 0.15
        SmoothCircle(vcx, vcy, s.voidRadius * vPulse, Color(5, 0, 5, 250))
        SmoothCircle(vcx, vcy, s.voidRadius * 0.5 * vPulse, Color(0, 0, 0, 255))
        SmoothRing(vcx, vcy, s.voidRadius * vPulse + 3, 2, Color(120, 0, 20, math.floor(100 + math.sin(s.voidPulse * 5) * 50)))
        SmoothRing(vcx, vcy, s.voidRadius * vPulse + 7, 1.5, Color(80, 0, 10, math.floor(50 + math.sin(s.voidPulse * 3) * 30)))
        for _, t in ipairs(s.tendrils) do
            t.length = math.min(t.maxLen * growFactor, t.length + t.speed * dt * growFactor)
            local segs = math.floor(t.length / 4)
            local prevX, prevY = vcx, vcy
            for seg = 1, segs do
                local sf = seg / math.max(1, segs)
                local wobble = math.sin(s.voidPulse * 4 + seg * 0.8 + t.angle * 3) * 5 * sf
                local nx = vcx + math.cos(t.angle + wobble * 0.02) * t.length * sf
                local ny = vcy + math.sin(t.angle + wobble * 0.02) * t.length * sf + wobble
                local thick = math.max(0.5, 2.5 * (1 - sf))
                local alpha = math.floor(200 * (1 - sf * 0.7))
                SmoothLine(prevX, prevY, nx, ny, thick, Color(30, 0, 8, alpha))
                prevX, prevY = nx, ny
            end
        end
    end
    SmoothRing(cx, cy, fovR, 3, Color(60, 50, 40, 200))
    SmoothRing(cx, cy, fovR + 3, 2, Color(30, 25, 20, 150))
    for corner = 0, 3 do
        local ccx = (corner % 2 == 0) and sx or (sx + w)
        local ccy = (corner < 2) and sy or (sy + h)
        SmoothCircle(ccx, ccy, 60, Color(0, 0, 0, 200))
    end
end
local function InitDNA(s)
    s.angle = 0
    s.rungs = 30
    s.elapsed = 0
    s.basePairs = {}
    local bpTypes = {"AT", "GC", "AT", "GC", "GC", "AT", "AT", "GC", "AT", "GC",
                     "GC", "AT", "GC", "AT", "AT", "GC", "AT", "GC", "GC", "AT",
                     "AT", "GC", "AT", "AT", "GC", "GC", "AT", "GC", "AT", "GC"}
    for i = 1, s.rungs do
        s.basePairs[i] = {
            type = bpTypes[i] or "AT",
            corruption = 0,
        }
    end
    s.corruptionWave = -0.2
end
local function DrawDNA(s, sx, sy, w, h, dt)
    local cx = sx + w/2
    s.angle = s.angle + dt * 30
    s.elapsed = s.elapsed + dt
    if s.elapsed > 4 then
        s.corruptionWave = s.corruptionWave + dt * 0.06
    end
    local helixR = 65
    local points = {}
    for i = 0, s.rungs - 1 do
        local t = i / s.rungs
        local baseAngle = t * math.pi * 4 + math.rad(s.angle)
        local yPos = sy + 25 + t * (h - 50)
        local xA = cx + math.cos(baseAngle) * helixR
        local zA = math.sin(baseAngle)
        local xB = cx + math.cos(baseAngle + math.pi) * helixR
        local zB = math.sin(baseAngle + math.pi)
        local corr = 0
        if s.basePairs[i+1] then
            local dist = math.abs(t - s.corruptionWave)
            if t < s.corruptionWave then
                corr = math.min(1, (s.corruptionWave - t) * 5)
            end
            s.basePairs[i+1].corruption = corr
        end
        points[#points + 1] = {
            xA = xA, xB = xB, y = yPos, zA = zA, zB = zB,
            t = t, angle = baseAngle, idx = i + 1, corr = corr
        }
    end
    for i = 2, #points do
        local p1 = points[i-1]
        local p2 = points[i]
        if p1.zA < 0 and p2.zA < 0 then
            local c = p1.corr > 0.3 and Color(80, 0, 20, 80) or Color(0, 120, 60, 80)
            SmoothLine(p1.xA, p1.y, p2.xA, p2.y, 2.5, c)
        end
        if p1.zB < 0 and p2.zB < 0 then
            local c = p1.corr > 0.3 and Color(60, 0, 15, 80) or Color(0, 60, 120, 80)
            SmoothLine(p1.xB, p1.y, p2.xB, p2.y, 2.5, c)
        end
    end
    for i, p in ipairs(points) do
        local backAlpha = 90
        if p.zA < 0 then
            local nc = p.corr > 0.3 and Color(60, 0, 15, backAlpha) or Color(0, 80, 40, backAlpha)
            SmoothCircle(p.xA, p.y, 3, nc)
        end
        if p.zB < 0 then
            local nc = p.corr > 0.3 and Color(50, 0, 10, backAlpha) or Color(0, 40, 80, backAlpha)
            SmoothCircle(p.xB, p.y, 3, nc)
        end
        if p.zA < 0 or p.zB < 0 then
            local rungA = math.floor(35 + 25 * math.min(math.abs(p.zA), math.abs(p.zB)))
            local rc = p.corr > 0.3 and Color(50, 0, 10, rungA) or Color(0, 60, 40, rungA)
            SmoothLine(p.xA, p.y, p.xB, p.y, 1, rc)
        end
    end
    for i, p in ipairs(points) do
        if p.zA >= 0 and p.zB >= 0 then
            local bp = s.basePairs[p.idx]
            local corr = p.corr
            local mx = (p.xA + p.xB) / 2
            local bondCount = (bp and bp.type == "GC") and 3 or 2
            local rungLen = math.abs(p.xB - p.xA)
            if corr < 0.5 then
                for b = 1, bondCount do
                    local bf = b / (bondCount + 1)
                    local bx = p.xA + (p.xB - p.xA) * bf
                    local bLen = rungLen * 0.06
                    SmoothLine(bx - bLen, p.y, bx + bLen, p.y, 1.5, Color(0, 150, 100, 120))
                end
            else
                for b = 1, bondCount do
                    local bf = b / (bondCount + 1)
                    local bx = p.xA + (p.xB - p.xA) * bf
                    local wobble = math.sin(s.elapsed * 4 + i + b) * 3 * corr
                    SmoothLine(bx - 2, p.y + wobble, bx + 2, p.y - wobble, 1,
                        Color(80, 0, 20, math.floor(100 * (1 - corr))))
                end
            end
            local colA, colB
            if bp and bp.type == "AT" then
                colA = corr > 0.3 and Color(180, 40, 40, 200) or Color(200, 80, 80, 220)
                colB = corr > 0.3 and Color(40, 40, 120, 200) or Color(80, 80, 220, 220)
            else
                colA = corr > 0.3 and Color(40, 120, 40, 200) or Color(80, 220, 80, 220)
                colB = corr > 0.3 and Color(140, 140, 20, 200) or Color(220, 220, 80, 220)
            end
            local nodeSize = 3 + p.zA * 1.5
            SmoothCircle(p.xA + (p.xB > p.xA and 8 or -8), p.y, nodeSize * 0.7, colA)
            SmoothCircle(p.xB + (p.xA > p.xB and 8 or -8), p.y, nodeSize * 0.7, colB)
            if i % 4 == 1 and p.zA > 0.5 then
                surface.SetFont("Petrov_Console")
                local label = bp and bp.type or "??"
                local labelA = label:sub(1,1)
                local labelB = label:sub(2,2)
                local labelCol = corr > 0.3 and Color(120, 40, 40, 150) or Color(150, 200, 150, 150)
                surface.SetTextColor(labelCol)
                surface.SetTextPos(mx - 8, p.y - 7)
                surface.DrawText(labelA .. "-" .. labelB)
            end
            if corr > 0.2 then
                local voidX = mx + math.sin(s.elapsed * 3 + i) * 5
                SmoothCircle(voidX, p.y, 2 * corr, Color(10, 0, 5, math.floor(200 * corr)))
            end
        end
    end
    for i = 2, #points do
        local p1 = points[i-1]
        local p2 = points[i]
        if p1.zA >= 0 and p2.zA >= 0 then
            local thick = 2.5 + p1.zA * 1.5
            local c = p1.corr > 0.3
                and Color(150, 20, 40, math.floor(180 + p1.zA * 60))
                or Color(0, 200 + math.floor(p1.zA * 55), 80 + math.floor(p1.zA * 40), math.floor(180 + p1.zA * 60))
            SmoothLine(p1.xA, p1.y, p2.xA, p2.y, thick, c)
            SmoothLine(p1.xA, p1.y, p2.xA, p2.y, thick + 3, Color(c.r, c.g, c.b, 30))
        end
        if p1.zB >= 0 and p2.zB >= 0 then
            local thick = 2.5 + p1.zB * 1.5
            local c = p1.corr > 0.3
                and Color(120, 15, 30, math.floor(180 + p1.zB * 60))
                or Color(0, 80 + math.floor(p1.zB * 40), 200 + math.floor(p1.zB * 55), math.floor(180 + p1.zB * 60))
            SmoothLine(p1.xB, p1.y, p2.xB, p2.y, thick, c)
            SmoothLine(p1.xB, p1.y, p2.xB, p2.y, thick + 3, Color(c.r, c.g, c.b, 30))
        end
    end
    for i, p in ipairs(points) do
        if p.zA >= 0 then
            local brt = 150 + math.floor(p.zA * 105)
            local size = 4 + p.zA * 2.5
            if p.corr > 0.3 then
                GlowCircle(p.xA, p.y, size, Color(brt, math.floor(brt * 0.2), math.floor(brt * 0.2), 255), 2)
                SmoothCircle(p.xA, p.y, size * 0.3, Color(40, 0, 10, math.floor(220 * p.corr)))
            else
                GlowCircle(p.xA, p.y, size, Color(0, brt, math.floor(brt * 0.6), 255), 2)
                SmoothCircle(p.xA, p.y, size * 0.3, Color(200, 255, 220, 120))
            end
        end
        if p.zB >= 0 then
            local brt = 150 + math.floor(p.zB * 105)
            local size = 4 + p.zB * 2.5
            if p.corr > 0.3 then
                GlowCircle(p.xB, p.y, size, Color(brt, math.floor(brt * 0.15), math.floor(brt * 0.15), 255), 2)
            else
                GlowCircle(p.xB, p.y, size, Color(0, math.floor(brt * 0.6), brt, 255), 2)
                SmoothCircle(p.xB, p.y, size * 0.3, Color(200, 220, 255, 120))
            end
        end
    end
    if s.corruptionWave > 0 and s.corruptionWave < 1 then
        local waveY = sy + 25 + s.corruptionWave * (h - 50)
        SmoothLine(sx + 15, waveY, sx + w - 15, waveY, 1, Color(120, 0, 20, 60))
        surface.SetFont("Petrov_Console")
        surface.SetTextColor(Color(120, 0, 20, 100))
        surface.SetTextPos(sx + w - 85, waveY - 14)
        surface.DrawText("MUTATION")
    end
end
local function DrawOrganelles(px, py, r, phase, corruption)
    local corr = corruption or 0
    local erSegments = 5
    for i = 1, erSegments do
        local erAngle = (i / erSegments) * math.pi * 1.4 + 0.3
        local erDist = r * 0.5
        local erx = px + math.cos(erAngle) * erDist
        local ery = py + math.sin(erAngle) * erDist
        local erx2 = px + math.cos(erAngle + 0.3) * erDist * 0.8
        local ery2 = py + math.sin(erAngle + 0.3) * erDist * 0.8
        local erAlpha = math.max(0, math.floor(60 * (1 - corr)))
        SmoothLine(erx, ery, erx2, ery2, 1, Color(100, 180, 120, erAlpha))
        if corr < 0.5 then
            SmoothCircle(erx, ery, 1, Color(140, 200, 160, math.floor(80 * (1 - corr * 2))))
        end
    end
    local mitoCount = 3
    for i = 1, mitoCount do
        local ma = (i / mitoCount) * math.pi * 2 + phase * 0.1 + 1
        local md = r * 0.55
        local mx = px + math.cos(ma) * md
        local my = py + math.sin(ma) * md
        local mSize = r * 0.12
        local mAlpha = math.max(0, math.floor(120 * (1 - corr * 0.8)))
        if corr < 0.6 then
            SmoothCircle(mx, my, mSize, Color(180, 100, 60, mAlpha))
            SmoothLine(mx - mSize * 0.5, my, mx + mSize * 0.3, my - mSize * 0.3,
                1, Color(200, 130, 80, math.floor(mAlpha * 0.7)))
            SmoothLine(mx - mSize * 0.3, my + mSize * 0.2, mx + mSize * 0.5, my,
                1, Color(200, 130, 80, math.floor(mAlpha * 0.7)))
        else
            SmoothCircle(mx, my, mSize * (1 + corr * 0.3), Color(40, 0, 10, math.floor(180 * corr)))
        end
    end
    local ga = phase * 0.05 + 2.5
    local gx = px + math.cos(ga) * r * 0.35
    local gy = py + math.sin(ga) * r * 0.35
    if corr < 0.7 then
        for stack = -2, 2 do
            local sy2 = gy + stack * 2.5
            local sWidth = (r * 0.15) * (1 - math.abs(stack) * 0.15)
            SmoothLine(gx - sWidth, sy2, gx + sWidth, sy2, 1.5,
                Color(200, 180, 80, math.max(0, math.floor(80 * (1 - corr)))))
        end
    end
    if corr > 0.3 then
        local voidN = math.floor(corr * 6)
        for v = 1, voidN do
            local va = (v / voidN) * math.pi * 2 + phase * 0.8
            local vd = r * 0.4 * corr
            local vx = px + math.cos(va) * vd
            local vy = py + math.sin(va) * vd
            local vSize = 1.5 + corr * 2
            SmoothCircle(vx, vy, vSize, Color(10, 0, 5, math.floor(200 * corr)))
            if math.sin(phase * 5 + v * 2) > 0.3 then
                SmoothCircle(vx, vy, vSize * 0.4, Color(80, 0, 20, math.floor(150 * corr)))
            end
        end
    end
end
local function DrawNucleus(px, py, r, nucleusR, phase, state, corruption)
    local corr = corruption or 0
    if state == "prophase" then
        SmoothCircle(px, py, nucleusR, Color(50, 80, 60, 150))
        SmoothRing(px, py, nucleusR, 1.5, Color(80, 120, 90, 180))
        local chroms = 4
        for c = 1, chroms do
            local ca = (c / chroms) * math.pi * 2 + phase * 0.3
            local cd = nucleusR * 0.5
            local cx2 = px + math.cos(ca) * cd * 0.5
            local cy2 = py + math.sin(ca) * cd * 0.5
            local cx3 = px + math.cos(ca + 0.5) * cd
            local cy3 = py + math.sin(ca + 0.5) * cd
            SmoothLine(cx2, cy2, cx3, cy3, 2, Color(100, 200, 140, 200))
            SmoothLine(cx2 + 1.5, cy2 + 1, cx3 + 1.5, cy3 + 1, 1.5, Color(80, 160, 120, 160))
        end
    elseif state == "metaphase" then
        SmoothCircle(px, py, nucleusR, Color(50, 80, 60, 100))
        for c = 1, 5 do
            local cy2 = py - nucleusR * 0.5 + (c / 6) * nucleusR
            SmoothCircle(px, cy2, 2, Color(120, 220, 160, 220))
            SmoothCircle(px + 1.5, cy2, 1.5, Color(100, 180, 140, 180))
        end
        for c = 1, 5 do
            local cy2 = py - nucleusR * 0.5 + (c / 6) * nucleusR
            SmoothLine(px, cy2, px, py - nucleusR * 0.9, 0.5, Color(0, 150, 80, 60))
            SmoothLine(px, cy2, px, py + nucleusR * 0.9, 0.5, Color(0, 150, 80, 60))
        end
        SmoothCircle(px, py - nucleusR * 0.9, 2, Color(200, 200, 100, 180))
        SmoothCircle(px, py + nucleusR * 0.9, 2, Color(200, 200, 100, 180))
    elseif state == "anaphase" then
        SmoothCircle(px, py, nucleusR, Color(50, 80, 60, 80))
        local sep = math.abs(math.sin(phase * 0.5)) * nucleusR * 0.6
        for c = 1, 4 do
            local cx2 = px - nucleusR * 0.3 + (c / 5) * nucleusR * 0.6
            SmoothCircle(cx2, py - sep, 1.5, Color(120, 220, 160, 220))
            SmoothCircle(cx2, py + sep, 1.5, Color(120, 220, 160, 220))
            SmoothLine(cx2, py - sep, cx2, py + sep, 0.5, Color(0, 120, 60, 40))
        end
    elseif state == "corrupted" then
        local dissolve = corr
        SmoothCircle(px, py, nucleusR * (1 + dissolve * 0.3), Color(
            math.floor(30 * (1 - dissolve)),
            math.floor(60 * (1 - dissolve)),
            math.floor(40 * (1 - dissolve)),
            math.floor(180 * (1 - dissolve * 0.5))
        ))
        SmoothCircle(px, py, nucleusR * dissolve * 0.8, Color(5, 0, 5, math.floor(250 * dissolve)))
        local fragments = math.floor((1 - dissolve) * 6)
        for f = 1, fragments do
            local fa = (f / fragments) * math.pi * 2 + phase
            local fd = nucleusR * 0.4 * (1 + dissolve * 0.5)
            local fx = px + math.cos(fa) * fd
            local fy = py + math.sin(fa) * fd
            SmoothCircle(fx, fy, 1.5 * (1 - dissolve), Color(80, 150, 100, math.floor(150 * (1 - dissolve))))
        end
    else
        SmoothCircle(px, py, nucleusR, Color(40, 80, 60, 180))
        SmoothRing(px, py, nucleusR, 1.5, Color(60, 120, 80, 200))
        SmoothRing(px, py, nucleusR - 2, 0.8, Color(50, 100, 70, 120))
        local chromatinN = 6
        for c = 1, chromatinN do
            local ca = (c / chromatinN) * math.pi * 2 + phase * 0.1
            local cd = nucleusR * 0.5 * math.abs(math.sin(ca * 2 + phase * 0.2))
            local cx2 = px + math.cos(ca) * cd
            local cy2 = py + math.sin(ca) * cd
            SmoothCircle(cx2, cy2, 1.5, Color(80, 160, 100, 100))
        end
        SmoothCircle(px - nucleusR * 0.15, py + nucleusR * 0.1, nucleusR * 0.25, Color(30, 60, 40, 200))
        SmoothCircle(px - nucleusR * 0.15, py + nucleusR * 0.1, nucleusR * 0.1, Color(50, 80, 60, 180))
    end
end
local function InitCells(s)
    s.cells = {}
    local cellData = {
        {x=0.22, y=0.35, r=28, state="interphase", corruption=0},
        {x=0.55, y=0.25, r=24, state="prophase", corruption=0},
        {x=0.78, y=0.38, r=22, state="metaphase", corruption=0},
        {x=0.35, y=0.62, r=26, state="anaphase", corruption=0},
        {x=0.60, y=0.55, r=25, state="corrupted", corruption=0.3},
        {x=0.45, y=0.75, r=20, state="corrupted", corruption=0.7},
        {x=0.75, y=0.70, r=18, state="dead", corruption=1.0},
        {x=0.20, y=0.72, r=21, state="interphase", corruption=0},
    }
    for _, c in ipairs(cellData) do
        s.cells[#s.cells + 1] = {
            rx = c.x, ry = c.y, baseR = c.r,
            state = c.state, corruption = c.corruption,
            corrupt_rate = 0.005 + math.random() * 0.015,
            phase = math.random() * math.pi * 2,
            membrane_wobble = {},
        }
        local cell = s.cells[#s.cells]
        for i = 1, 12 do
            cell.membrane_wobble[i] = {
                offset = (math.random() - 0.5) * 3,
                speed = 0.5 + math.random() * 1.5,
            }
        end
    end
    s.phase = 0
    s.elapsed = 0
    s.injectionPoint = { rx = 0.55, ry = 0.60 }
end
local function DrawCells(s, sx, sy, w, h, dt)
    s.phase = s.phase + dt * 1.5
    s.elapsed = s.elapsed + dt
    local cx, cy = sx + w/2, sy + h/2
    local fovR = math.min(w, h) * 0.44
    SmoothCircle(cx, cy, fovR, Color(8, 20, 12, 200))
    for i = 1, 3 do
        local fa = (i / 3) * math.pi * 2 + s.phase * 0.05
        local fx = cx + math.cos(fa) * fovR * 0.3
        local fy = cy + math.sin(fa) * fovR * 0.3
        SmoothCircle(fx, fy, fovR * 0.4, Color(10, 25, 15, 25))
    end
    for i = 1, #s.cells do
        for j = i+1, #s.cells do
            local c1 = s.cells[i]
            local c2 = s.cells[j]
            local x1 = sx + c1.rx * w
            local y1 = sy + c1.ry * h
            local x2 = sx + c2.rx * w
            local y2 = sy + c2.ry * h
            local dist = math.sqrt((x2-x1)^2 + (y2-y1)^2)
            if dist < 100 and c1.state ~= "dead" and c2.state ~= "dead" then
                local alpha = math.max(0, math.floor(25 * (1 - dist / 100)))
                SmoothLine(x1, y1, x2, y2, 0.5, Color(60, 100, 70, alpha))
                local mx, my = (x1 + x2) / 2, (y1 + y2) / 2
                SmoothCircle(mx, my, 1, Color(80, 120, 90, math.floor(alpha * 0.8)))
            end
        end
    end
    for _, c in ipairs(s.cells) do
        local px = sx + c.rx * w
        local py = sy + c.ry * h
        local pulse = math.sin(s.phase + c.phase)
        local r = c.baseR + pulse * 1.5
        local corr = c.corruption
        local dx = px - cx
        local dy = py - cy
        if math.sqrt(dx*dx + dy*dy) > fovR - r then
        elseif c.state == "dead" then
            for frag = 1, 8 do
                local fa = (frag / 8) * math.pi * 2 + c.phase
                local fd = r * 0.8 + math.sin(fa * 3) * 3
                local fx = px + math.cos(fa) * fd
                local fy = py + math.sin(fa) * fd
                local fLen = r * 0.25
                local fx2 = fx + math.cos(fa + 0.5) * fLen
                local fy2 = fy + math.sin(fa + 0.5) * fLen
                SmoothLine(fx, fy, fx2, fy2, 1, Color(60, 80, 60, 80))
            end
            SmoothCircle(px, py, r * 1.2, Color(20, 10, 15, 40))
            SmoothCircle(px, py, r * 0.6, Color(15, 5, 10, 60))
            local voidPulse = math.sin(s.phase * 2 + c.phase)
            SmoothCircle(px, py, 4 + voidPulse, Color(5, 0, 5, 200))
            SmoothCircle(px, py, 2, Color(0, 0, 0, 255))
        elseif c.state == "anaphase" then
            local sep = 3 + math.abs(math.sin(s.phase * 0.3 + c.phase)) * (r * 0.35)
            local elongation = 1 + sep / (r * 2)
            SmoothCircle(px - sep * 0.5, py, r * 0.85, Color(30, 60, 40, 140))
            SmoothCircle(px + sep * 0.5, py, r * 0.85, Color(30, 60, 40, 140))
            SmoothRing(px - sep * 0.5, py, r * 0.85, 2, Color(60, 140, 80, 180))
            SmoothRing(px + sep * 0.5, py, r * 0.85, 2, Color(60, 140, 80, 180))
            local pinch = math.max(2, r * 0.3 - sep * 0.3)
            SmoothLine(px, py - pinch, px, py + pinch, 2, Color(80, 160, 100, 150))
            DrawNucleus(px - sep * 0.5, py, r * 0.85, r * 0.35, s.phase + c.phase, "anaphase", 0)
            DrawNucleus(px + sep * 0.5, py, r * 0.85, r * 0.35, s.phase + c.phase, "anaphase", 0)
            SmoothCircle(px, py - pinch, 1.5, Color(200, 100, 100, 120))
            SmoothCircle(px, py + pinch, 1.5, Color(200, 100, 100, 120))
        else
            local memColor
            if corr > 0.5 then
                memColor = Color(
                    math.floor(60 + 80 * corr),
                    math.max(0, math.floor(140 * (1 - corr))),
                    math.max(0, math.floor(80 * (1 - corr))),
                    200
                )
            else
                memColor = Color(60, 140, 80, 200)
            end
            local cytoAlpha = math.floor(140 + corr * 40)
            SmoothCircle(px, py, r, Color(
                math.floor(25 + 20 * corr),
                math.max(5, math.floor(55 * (1 - corr * 0.7))),
                math.max(5, math.floor(35 * (1 - corr * 0.7))),
                cytoAlpha
            ))
            SmoothRing(px, py, r, 2, memColor)
            SmoothRing(px, py, r - 2.5, 0.8, Color(memColor.r, memColor.g, memColor.b, 100))
            DrawOrganelles(px, py, r, s.phase + c.phase, corr)
            local nucleusR = r * 0.38
            local nucState = c.state
            if corr > 0.3 then nucState = "corrupted" end
            DrawNucleus(px, py, r, nucleusR, s.phase + c.phase, nucState, corr)
            if corr > 0.1 then
                local injX = sx + s.injectionPoint.rx * w
                local injY = sy + s.injectionPoint.ry * h
                local tdx = px - injX
                local tdy = py - injY
                local tAngle = math.atan2(tdy, tdx)
                local tendrils = math.floor(corr * 4) + 1
                for t = 1, tendrils do
                    local ta = tAngle + (t - tendrils / 2) * 0.3
                    local startX = px + math.cos(ta + math.pi) * r
                    local startY = py + math.sin(ta + math.pi) * r
                    local endX = px + math.cos(ta + math.pi) * r * (1 - corr * 0.8)
                    local endY = py + math.sin(ta + math.pi) * r * (1 - corr * 0.8)
                    local wobble = math.sin(s.phase * 3 + t * 1.7) * 3 * corr
                    endY = endY + wobble
                    SmoothLine(startX, startY, endX, endY,
                        math.max(0.5, 2 * corr), Color(20, 0, 5, math.floor(200 * corr)))
                end
                local breachX = px + math.cos(tAngle + math.pi) * r
                local breachY = py + math.sin(tAngle + math.pi) * r
                SmoothCircle(breachX, breachY, 2.5 * corr, Color(80, 0, 15, math.floor(200 * corr)))
            end
        end
        if s.elapsed > 3 and corr < 1 and c.state ~= "dead" then
            local injX = s.injectionPoint.rx
            local injY = s.injectionPoint.ry
            local vdx = c.rx - injX
            local vdy = c.ry - injY
            local vdist = math.sqrt(vdx*vdx + vdy*vdy)
            local corruptReach = (s.elapsed - 3) * 0.025
            if vdist < corruptReach then
                c.corruption = math.min(1, c.corruption + c.corrupt_rate * dt)
                if c.corruption > 0.9 and c.state ~= "corrupted" then
                    c.state = "corrupted"
                end
            end
        end
    end
    local ipx = sx + s.injectionPoint.rx * w
    local ipy = sy + s.injectionPoint.ry * h
    if s.elapsed > 2 then
        local ipPulse = math.sin(s.phase * 3) * 0.2
        SmoothCircle(ipx, ipy, 4 * (1 + ipPulse), Color(10, 0, 5, 200))
        SmoothCircle(ipx, ipy, 2, Color(0, 0, 0, 255))
        SmoothRing(ipx, ipy, 6 * (1 + ipPulse), 1, Color(60, 0, 15, math.floor(80 + math.sin(s.phase * 4) * 40)))
    end
    SmoothRing(cx, cy, fovR, 3, Color(50, 60, 50, 200))
    SmoothRing(cx, cy, fovR + 3, 2, Color(25, 30, 25, 150))
    for corner = 0, 3 do
        local ccx = (corner % 2 == 0) and sx or (sx + w)
        local ccy = (corner < 2) and sy or (sy + h)
        SmoothCircle(ccx, ccy, 60, Color(0, 0, 0, 200))
    end
end
local function InitRift(s)
    s.phase = 0
    s.elapsed = 0
    s.debris = {}
    for i = 1, 20 do
        local a = (i / 20) * math.pi * 2
        s.debris[i] = {
            angle = a,
            dist = 40 + math.random() * 80,
            speed = 0.2 + math.random() * 0.6,
            size = 0.8 + math.random() * 2,
            brightness = 0.5 + math.random() * 0.5,
            layer = math.random() > 0.5 and 1 or -1,
        }
    end
    s.trails = {}
    for i = 1, 20 do s.trails[i] = {} end
    s.gwaves = {}
    s.gwaveTimer = 0
    s.diskParticles = {}
    for i = 1, 40 do
        s.diskParticles[i] = {
            angle = math.random() * math.pi * 2,
            dist = 30 + math.random() * 55,
            speed = 0.8 + math.random() * 1.2,
            size = 0.5 + math.random() * 1.5,
        }
    end
end
local function DrawRift(s, sx, sy, w, h, dt)
    local cx, cy = sx + w/2, sy + h/2
    s.phase = s.phase + dt
    s.elapsed = s.elapsed + dt
    local eventHorizonR = 22
    local photonSphereR = eventHorizonR * 1.5
    local gridSize = 18
    for gx = 0, w, gridSize do
        for gy = 0, h, gridSize do
            local px, py = sx + gx, sy + gy
            local dx, dy = px - cx, py - cy
            local dist = math.sqrt(dx*dx + dy*dy)
            if dist > eventHorizonR + 5 then
                local schwarzschild = eventHorizonR * 2
                local force = (schwarzschild * schwarzschild) / (dist * dist) * 25
                local dispX = dx / dist * force
                local dispY = dy / dist * force
                local finalX = px - dispX
                local finalY = py - dispY
                local alpha
                local dotR, dotG, dotB
                if dist < photonSphereR * 1.5 then
                    local proximity = 1 - (dist - eventHorizonR) / (photonSphereR * 1.5 - eventHorizonR)
                    proximity = math.max(0, math.min(1, proximity))
                    dotR = math.floor(80 + 120 * proximity)
                    dotG = math.floor(20 * (1 - proximity))
                    dotB = math.floor(120 + 80 * proximity)
                    alpha = math.floor(40 + 80 * proximity)
                else
                    dotR = 0
                    dotG = 50
                    dotB = 35
                    alpha = math.min(50, math.floor(20 + dist * 0.15))
                end
                SmoothCircle(finalX, finalY, 1, Color(dotR, dotG, dotB, alpha))
                if gx < w then
                    local nx, ny = sx + gx + gridSize, sy + gy
                    local ndx, ndy = nx - cx, ny - cy
                    local ndist = math.sqrt(ndx*ndx + ndy*ndy)
                    if ndist > eventHorizonR + 5 then
                        local nForce = (schwarzschild * schwarzschild) / (ndist * ndist) * 25
                        local nfx = nx - ndx / ndist * nForce
                        local nfy = ny - ndy / ndist * nForce
                        SmoothLine(finalX, finalY, nfx, nfy, 0.5, Color(dotR, dotG, dotB, math.floor(alpha * 0.3)))
                    end
                end
            end
        end
    end
    s.gwaveTimer = s.gwaveTimer + dt
    if s.gwaveTimer > 2 then
        s.gwaveTimer = 0
        s.gwaves[#s.gwaves + 1] = { radius = eventHorizonR + 5, alpha = 100 }
    end
    for i = #s.gwaves, 1, -1 do
        local gw = s.gwaves[i]
        gw.radius = gw.radius + dt * 60
        gw.alpha = gw.alpha - dt * 30
        if gw.alpha > 1 then
            SmoothRing(cx, cy, gw.radius, 1, Color(80, 0, 160, math.floor(gw.alpha)))
        else
            table.remove(s.gwaves, i)
        end
    end
    for i, dp in ipairs(s.diskParticles) do
        dp.angle = dp.angle + dt * dp.speed * (80 / math.max(30, dp.dist))
        local diskX = cx + math.cos(dp.angle) * dp.dist
        local diskY = cy + math.sin(dp.angle) * dp.dist * 0.25
        if math.sin(dp.angle) < 0 then
            local temp = 1 - (dp.dist - 30) / 55
            temp = math.max(0, math.min(1, temp))
            local tr = math.floor(255 * (1 - temp * 0.3))
            local tg = math.floor(100 + 150 * temp)
            local tb = math.floor(50 + 200 * temp)
            local ta = math.floor(60 + 80 * temp)
            SmoothCircle(diskX, diskY, dp.size, Color(tr, tg, tb, ta))
        end
    end
    for ring = 5, 1, -1 do
        local r = 25 + ring * 10
        local temp = 1 - ring / 5
        local tr = math.floor(200 + 55 * temp)
        local tg = math.floor(50 + 180 * temp)
        local tb = math.floor(20 + 230 * temp)
        for seg = 0, 15 do
            local a1 = math.pi + (seg / 16) * math.pi
            local a2 = math.pi + ((seg + 1) / 16) * math.pi
            local x1 = cx + math.cos(a1) * r
            local y1 = cy + math.sin(a1) * r * 0.25
            local x2 = cx + math.cos(a2) * r
            local y2 = cy + math.sin(a2) * r * 0.25
            SmoothLine(x1, y1, x2, y2, 2, Color(tr, tg, tb, math.floor(30 + 20 * temp)))
        end
    end
    local pulse = 1 + math.sin(s.phase * 2.5) * 0.05
    SmoothCircle(cx, cy, eventHorizonR * pulse, Color(0, 0, 0, 255))
    SmoothCircle(cx, cy, eventHorizonR * pulse * 0.8, Color(0, 0, 0, 255))
    local photonPulse = 1 + math.sin(s.phase * 4) * 0.05
    SmoothRing(cx, cy, photonSphereR * photonPulse, 1.5, Color(200, 150, 255, 80))
    local hotAngle = s.phase * 1.5
    local hotX = cx + math.cos(hotAngle) * photonSphereR * photonPulse
    local hotY = cy + math.sin(hotAngle) * photonSphereR * photonPulse * 0.25
    SmoothCircle(hotX, hotY, 2, Color(255, 200, 255, 150))
    for hr = 1, 6 do
        local ha = (hr / 6) * math.pi * 2 + s.phase * 3 + math.sin(s.phase + hr) * 0.5
        local hDist = eventHorizonR * pulse + 2 + math.sin(s.phase * 5 + hr * 2) * 3
        local hx = cx + math.cos(ha) * hDist
        local hy = cy + math.sin(ha) * hDist
        local hAlpha = math.floor(80 + math.sin(s.phase * 8 + hr) * 60)
        SmoothCircle(hx, hy, 0.8, Color(200, 180, 255, math.max(0, hAlpha)))
    end
    SmoothRing(cx, cy, eventHorizonR * pulse, 2.5, Color(140, 0, 40, 120))
    SmoothRing(cx, cy, eventHorizonR * pulse + 3, 1.5, Color(180, 30, 60, 60))
    for i, dp in ipairs(s.diskParticles) do
        local diskX = cx + math.cos(dp.angle) * dp.dist
        local diskY = cy + math.sin(dp.angle) * dp.dist * 0.25
        if math.sin(dp.angle) >= 0 then
            local temp = 1 - (dp.dist - 30) / 55
            temp = math.max(0, math.min(1, temp))
            local tr = math.floor(255 * (1 - temp * 0.3))
            local tg = math.floor(100 + 155 * temp)
            local tb = math.floor(50 + 200 * temp)
            local ta = math.floor(100 + 120 * temp)
            SmoothCircle(diskX, diskY, dp.size * 1.2, Color(tr, tg, tb, ta))
            SmoothCircle(diskX, diskY, dp.size * 0.4, Color(255, 255, 255, math.floor(ta * 0.5)))
        end
    end
    for ring = 5, 1, -1 do
        local r = 25 + ring * 10
        local temp = 1 - ring / 5
        local tr = math.floor(200 + 55 * temp)
        local tg = math.floor(50 + 180 * temp)
        local tb = math.floor(20 + 230 * temp)
        for seg = 0, 15 do
            local a1 = (seg / 16) * math.pi
            local a2 = ((seg + 1) / 16) * math.pi
            local x1 = cx + math.cos(a1) * r
            local y1 = cy + math.sin(a1) * r * 0.25
            local x2 = cx + math.cos(a2) * r
            local y2 = cy + math.sin(a2) * r * 0.25
            SmoothLine(x1, y1, x2, y2, 2.5, Color(tr, tg, tb, math.floor(50 + 40 * temp)))
        end
    end
    local jetIntensity = 0.5 + math.sin(s.phase * 1.5) * 0.3
    for jet = -1, 1, 2 do
        local jetLen = 70 * jetIntensity
        local jBaseY = cy + jet * (eventHorizonR * 0.3)
        local jEndY = cy + jet * jetLen
        SmoothLine(cx, jBaseY, cx, jEndY, 2, Color(120, 80, 255, math.floor(180 * jetIntensity)))
        SmoothLine(cx - 2, jBaseY, cx - 4, jEndY, 3, Color(80, 40, 200, math.floor(60 * jetIntensity)))
        SmoothLine(cx + 2, jBaseY, cx + 4, jEndY, 3, Color(80, 40, 200, math.floor(60 * jetIntensity)))
        for k = 1, 3 do
            local kf = k / 4
            local ky = jBaseY + (jEndY - jBaseY) * kf
            local kPulse = math.sin(s.phase * 6 + k * 2 + jet) * 0.5
            SmoothCircle(cx, ky, 2 + kPulse, Color(180, 140, 255, math.floor(160 * jetIntensity * (1 - kf))))
        end
    end
    for i, d in ipairs(s.debris) do
        d.angle = d.angle + dt * d.speed * (100 / math.max(20, d.dist))
        d.dist = d.dist - dt * (3 + 20 / math.max(20, d.dist))
        if d.dist < eventHorizonR then
            d.dist = 50 + math.random() * 70
            d.angle = math.random() * math.pi * 2
            s.trails[i] = {}
        end
        local px = cx + math.cos(d.angle) * d.dist
        local py = cy + math.sin(d.angle) * d.dist * 0.4 * d.layer
        local trail = s.trails[i]
        table.insert(trail, 1, {x = px, y = py})
        if #trail > 20 then table.remove(trail) end
        local heating = math.max(0, 1 - (d.dist - eventHorizonR) / 60)
        local dR = math.floor(160 + 95 * heating)
        local dG = math.floor(50 * heating)
        local dB = math.floor(200 * (1 - heating) + 100)
        for ti = 2, #trail do
            local alpha = math.floor((100 + 80 * heating) * (1 - ti / #trail))
            SmoothLine(trail[ti-1].x, trail[ti-1].y, trail[ti].x, trail[ti].y,
                math.max(0.5, d.size * (1 - ti / #trail)), Color(dR, dG, dB, alpha))
        end
        GlowCircle(px, py, d.size * (1 + heating * 0.5), Color(dR, dG, dB, 200), 2)
        if heating > 0.5 then
            SmoothCircle(px, py, d.size * 0.4, Color(255, 255, 255, math.floor(200 * heating)))
        end
    end
    SmoothCircle(cx, cy, 3, Color(20, 0, 30, 255))
    if math.sin(s.phase * 10) > 0.7 then
        SmoothCircle(cx, cy, 1, Color(255, 200, 255, 200))
    end
end
local function InitNeural(s)
    s.phase = 0
    s.channels = {
        {name = "ALPHA", freq = 3, amp = 0.6, color = Color(0, 200, 255), secondary = nil},
        {name = "BETA",  freq = 7, amp = 0.4, color = Color(0, 220, 100), secondary = nil},
        {name = "GAMMA", freq = 13, amp = 0.25, color = Color(220, 200, 0), secondary = {freq = 20, amp = 0.1}},
        {name = "DELTA", freq = 1.5, amp = 0.8, color = Color(220, 50, 50), secondary = {freq = 8, amp = 0.15}},
    }
end
local function DrawNeural(s, sx, sy, w, h, dt)
    s.phase = s.phase + dt * 3
    local channelH = (h - 40) / 4
    for ci, ch in ipairs(s.channels) do
        local baseY = sy + 20 + (ci - 1) * channelH + channelH / 2
        local topY = sy + 20 + (ci - 1) * channelH
        if ci > 1 then
            SmoothLine(sx + 10, topY, sx + w - 10, topY, 1, Color(ch.color.r, ch.color.g, ch.color.b, 30))
        end
        surface.SetFont("Petrov_Console")
        surface.SetTextColor(Color(ch.color.r, ch.color.g, ch.color.b, 150))
        surface.SetTextPos(sx + w - 65, topY + 2)
        surface.DrawText(ch.name)
        local prevX, prevY = nil, nil
        local waveW = w - 80
        local steps = math.floor(waveW / 2)
        for i = 0, steps do
            local t = i / steps
            local px = sx + 10 + t * waveW
            local waveval = math.sin(t * ch.freq * math.pi * 2 + s.phase) * ch.amp
            if ch.secondary then
                waveval = waveval + math.sin(t * ch.secondary.freq * math.pi * 2 + s.phase * 1.5) * ch.secondary.amp
            end
            waveval = waveval + math.sin(t * 37 + s.phase * 5) * 0.03
            local py = baseY - waveval * (channelH * 0.4)
            if prevX then
                SmoothLine(prevX, prevY, px, py, 2, Color(ch.color.r, ch.color.g, ch.color.b, 200))
                SmoothLine(prevX, prevY, px, py, 4, Color(ch.color.r, ch.color.g, ch.color.b, 40))
            end
            prevX, prevY = px, py
        end
        local scanX = sx + 10 + ((s.phase * 30) % waveW)
        SmoothLine(scanX, topY + 5, scanX, topY + channelH - 5, 1, Color(ch.color.r, ch.color.g, ch.color.b, 80))
    end
end
local function InitGravity(s)
    s.particles = {}
    local bodies = {
        {name="ALPHA",  color=Color(0, 220, 100),  mass=2.0, dist=75, speed=35},
        {name="BETA",   color=Color(0, 180, 255),  mass=1.5, dist=55, speed=45},
        {name="GAMMA",  color=Color(220, 200, 0),  mass=1.0, dist=90, speed=28},
        {name="DELTA",  color=Color(200, 80, 255), mass=1.8, dist=65, speed=38},
        {name="EPSILON",color=Color(255, 120, 0),  mass=0.7, dist=100, speed=25},
        {name="ZETA",   color=Color(100, 255, 180),mass=1.2, dist=45, speed=50},
        {name="ETA",    color=Color(255, 80, 80),  mass=0.5, dist=110, speed=22},
        {name="THETA",  color=Color(180, 180, 255),mass=0.8, dist=85, speed=32},
    }
    for i, b in ipairs(bodies) do
        local a = (i / #bodies) * math.pi * 2
        s.particles[i] = {
            x = math.cos(a) * b.dist,
            y = math.sin(a) * b.dist,
            vx = -math.sin(a) * b.speed,
            vy = math.cos(a) * b.speed,
            color = b.color,
            mass = b.mass,
            name = b.name,
            trail = {},
        }
    end
    s.phase = 0
    s.elapsed = 0
    s.corePulse = 0
end
local function DrawGravity(s, sx, sy, w, h, dt)
    local cx, cy = sx + w/2, sy + h/2
    s.phase = s.phase + dt
    s.elapsed = s.elapsed + dt
    s.corePulse = s.corePulse + dt
    local contours = 6
    for c = 1, contours do
        local r = c * 20
        local wobble = math.sin(s.corePulse * 2 + c * 0.5) * 2
        local alpha = math.floor(25 - c * 3)
        if alpha > 0 then
            SmoothRing(cx, cy, r + wobble, 1, Color(0, 80 + c * 10, 40 + c * 5, alpha))
        end
    end
    for fl = 0, 11 do
        local fa = (fl / 12) * math.pi * 2 + s.phase * 0.05
        local innerR = 15
        local outerR = 120
        for seg = 0, 5 do
            local sf = seg / 6
            local r1 = innerR + sf * (outerR - innerR)
            local r2 = r1 + (outerR - innerR) / 12
            local x1 = cx + math.cos(fa) * r1
            local y1 = cy + math.sin(fa) * r1
            local x2 = cx + math.cos(fa) * r2
            local y2 = cy + math.sin(fa) * r2
            local alpha = math.floor(20 * (1 - sf))
            SmoothLine(x1, y1, x2, y2, 0.5, Color(0, 80, 50, alpha))
        end
    end
    local corePulseVal = 1 + math.sin(s.corePulse * 2.5) * 0.15
    local coreR = 10 * corePulseVal
    SmoothRing(cx, cy, coreR + 8, 1.5, Color(0, 150, 80, math.floor(40 + math.sin(s.corePulse * 3) * 20)))
    SmoothRing(cx, cy, coreR + 5, 1, Color(0, 200, 100, math.floor(60 + math.sin(s.corePulse * 4) * 30)))
    GlowCircle(cx, cy, coreR, Color(0, 180, 80, 200), 5)
    SmoothCircle(cx, cy, coreR * 0.7, Color(50, 255, 120, 230))
    SmoothCircle(cx, cy, coreR * 0.3, Color(200, 255, 220, 255))
    for t = 1, 4 do
        local ta = (t / 4) * math.pi * 2 + s.corePulse * 1.5
        local tLen = 12 + math.sin(s.corePulse * 3 + t * 2) * 5
        local tx = cx + math.cos(ta) * tLen
        local ty = cy + math.sin(ta) * tLen
        SmoothLine(cx, cy, tx, ty, 1, Color(0, 200, 100, 80))
        SmoothCircle(tx, ty, 1.5, Color(100, 255, 150, 120))
    end
    SmoothLine(cx - 18, cy, cx - 8, cy, 1, Color(0, 120, 60, 60))
    SmoothLine(cx + 8, cy, cx + 18, cy, 1, Color(0, 120, 60, 60))
    SmoothLine(cx, cy - 18, cx, cy - 8, 1, Color(0, 120, 60, 60))
    SmoothLine(cx, cy + 8, cx, cy + 18, 1, Color(0, 120, 60, 60))
    for i, p in ipairs(s.particles) do
        local dx = -p.x
        local dy = -p.y
        local dist = math.sqrt(dx*dx + dy*dy)
        if dist > 8 then
            local force = 3000 * p.mass / (dist * dist) * dist
            local ax = dx / dist * force
            local ay = dy / dist * force
            p.vx = p.vx + ax * dt
            p.vy = p.vy + ay * dt
        end
        for j, p2 in ipairs(s.particles) do
            if i ~= j then
                local pdx = p2.x - p.x
                local pdy = p2.y - p.y
                local pdist = math.sqrt(pdx*pdx + pdy*pdy)
                if pdist > 10 then
                    local pforce = 200 * p2.mass / (pdist * pdist)
                    p.vx = p.vx + (pdx / pdist) * pforce * dt
                    p.vy = p.vy + (pdy / pdist) * pforce * dt
                end
            end
        end
        p.vx = p.vx * 0.9995
        p.vy = p.vy * 0.9995
        p.x = p.x + p.vx * dt
        p.y = p.y + p.vy * dt
        local maxR = math.min(w, h) / 2 - 15
        local pDist = math.sqrt(p.x*p.x + p.y*p.y)
        if pDist > maxR then
            local bounce = maxR / pDist
            p.x = p.x * bounce
            p.y = p.y * bounce
            p.vx = p.vx * -0.3
            p.vy = p.vy * -0.3
        end
        table.insert(p.trail, 1, {x = cx + p.x, y = cy + p.y})
        if #p.trail > 50 then table.remove(p.trail) end
    end
    for _, p in ipairs(s.particles) do
        for ti = 2, #p.trail do
            local trailFade = 1 - ti / #p.trail
            local alpha = math.floor(120 * trailFade)
            local thick = (2 + p.mass) * trailFade
            SmoothLine(p.trail[ti-1].x, p.trail[ti-1].y, p.trail[ti].x, p.trail[ti].y,
                math.max(0.5, thick), Color(p.color.r, p.color.g, p.color.b, alpha))
        end
        for ti = 2, math.min(10, #p.trail) do
            local trailFade = 1 - ti / 10
            SmoothLine(p.trail[ti-1].x, p.trail[ti-1].y, p.trail[ti].x, p.trail[ti].y,
                (3 + p.mass) * trailFade, Color(p.color.r, p.color.g, p.color.b, math.floor(20 * trailFade)))
        end
    end
    for _, p in ipairs(s.particles) do
        local px, py = cx + p.x, cy + p.y
        local dist = math.sqrt(p.x*p.x + p.y*p.y)
        local segs = math.floor(dist / 8)
        for seg = 0, segs - 1 do
            if seg % 2 == 0 then
                local f1 = seg / math.max(1, segs)
                local f2 = math.min(1, (seg + 1) / math.max(1, segs))
                local lx1 = cx + p.x * f1
                local ly1 = cy + p.y * f1
                local lx2 = cx + p.x * f2
                local ly2 = cy + p.y * f2
                SmoothLine(lx1, ly1, lx2, ly2, 0.5, Color(p.color.r, p.color.g, p.color.b, 25))
            end
        end
    end
    for _, p in ipairs(s.particles) do
        local px, py = cx + p.x, cy + p.y
        local size = 3 + p.mass * 2.5
        local influenceR = size + p.mass * 8
        SmoothRing(px, py, influenceR, 0.5, Color(p.color.r, p.color.g, p.color.b, 15))
        GlowCircle(px, py, size, Color(p.color.r, p.color.g, p.color.b, 220), 3)
        SmoothCircle(px, py, size * 0.5, Color(
            math.min(255, p.color.r + 80),
            math.min(255, p.color.g + 80),
            math.min(255, p.color.b + 80), 200))
        SmoothCircle(px, py, size * 0.2, Color(255, 255, 255, 180))
        local speed = math.sqrt(p.vx*p.vx + p.vy*p.vy)
        if speed > 5 then
            local vnx = p.vx / speed
            local vny = p.vy / speed
            local arrowLen = math.min(20, speed * 0.3)
            local ax = px + vnx * arrowLen
            local ay = py + vny * arrowLen
            SmoothLine(px, py, ax, ay, 1, Color(p.color.r, p.color.g, p.color.b, 80))
            SmoothCircle(ax, ay, 1.5, Color(p.color.r, p.color.g, p.color.b, 100))
        end
    end
    local heaviest = nil
    local secondHeaviest = nil
    for _, p in ipairs(s.particles) do
        if not heaviest or p.mass > heaviest.mass then
            secondHeaviest = heaviest
            heaviest = p
        elseif not secondHeaviest or p.mass > secondHeaviest.mass then
            secondHeaviest = p
        end
    end
    if heaviest and secondHeaviest then
        local lx = (cx + heaviest.x + cx + secondHeaviest.x) / 2
        local ly = (cy + heaviest.y + cy + secondHeaviest.y) / 2
        SmoothCircle(lx, ly, 2, Color(255, 255, 100, math.floor(40 + math.sin(s.phase * 4) * 20)))
        SmoothRing(lx, ly, 4, 0.5, Color(255, 255, 100, 20))
    end
    surface.SetFont("Petrov_Console")
    surface.SetTextColor(Color(0, 120, 60, 80))
    surface.SetTextPos(sx + 5, sy + h - 16)
    surface.DrawText(string.format("N=%d", #s.particles))
end
local InitFuncs = { InitCronos, InitDNA, InitCells, InitRift, InitNeural, InitGravity }
local DrawFuncs = { DrawCronos, DrawDNA, DrawCells, DrawRift, DrawNeural, DrawGravity }
function VOIDTERM.Experiments.Launch(index)
    if not VOIDTERM.Experiments.List[index] then return false end
    VOIDTERM.Experiments.Active = index
    VOIDTERM.Experiments.State = {}
    VOIDTERM.Experiments.StartTime = CurTime()
    if InitFuncs[index] then
        InitFuncs[index](VOIDTERM.Experiments.State)
    end
    return true
end
function VOIDTERM.Experiments.Stop()
    VOIDTERM.Experiments.Active = nil
    VOIDTERM.Experiments.State = {}
end
function VOIDTERM.Experiments.IsRunning()
    return VOIDTERM.Experiments.Active ~= nil
end
function VOIDTERM.Experiments.DrawActive(sx, sy, w, h)
    local idx = VOIDTERM.Experiments.Active
    if not idx then return end
    local dt = FrameTime()
    local exp = VOIDTERM.Experiments.List[idx]
    surface.SetDrawColor(Color(5, 5, 10, 255))
    surface.DrawRect(sx, sy, w, h)
    if DrawFuncs[idx] then
        DrawFuncs[idx](VOIDTERM.Experiments.State, sx, sy, w, h, dt)
    end
    surface.SetFont("Petrov_Console")
    surface.SetTextColor(Color(exp.color.r, exp.color.g, exp.color.b, 180))
    surface.SetTextPos(sx + 8, sy + 5)
    surface.DrawText(exp.id)
    surface.SetTextPos(sx + 8, sy + 18)
    surface.DrawText(exp.name)
    local elapsed = CurTime() - VOIDTERM.Experiments.StartTime
    local timeStr = string.format("T+%.1fs", elapsed)
    surface.SetTextColor(Color(100, 100, 100, 150))
    surface.SetTextPos(sx + w - 70, sy + 5)
    surface.DrawText(timeStr)
    local statusColor = Color(0, 200, 80)
    if exp.status == "CLASSIFIED" then statusColor = Color(200, 150, 0) end
    if exp.status == "TERMINATED" then statusColor = Color(120, 120, 120) end
    surface.SetTextColor(statusColor)
    surface.SetTextPos(sx + w - 90, sy + h - 18)
    surface.DrawText("[" .. exp.status .. "]")
    surface.SetTextColor(Color(80, 80, 80, 120))
    surface.SetTextPos(sx + 8, sy + h - 18)
    surface.DrawText("[TAB] Stop")
    surface.SetDrawColor(Color(exp.color.r, exp.color.g, exp.color.b, 60))
    surface.DrawOutlinedRect(sx, sy, w, h)
end
function VOIDTERM.Experiments.Install()
end
