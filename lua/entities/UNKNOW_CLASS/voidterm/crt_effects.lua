VOIDTERM = VOIDTERM or {}
VOIDTERM.CRT = {}
local PRO_COLOR_BG = Color(0, 0, 0, 255)
local PRO_COLOR_FG = Color(12, 204, 104, 255)
local PRO_CURVATURE = 0.1
local PRO_BLOOM_DARKEN = 0.65
local PRO_BLOOM_MULT = 1.0
local PRO_BLOOM_SIZE = 1.0
local RT_WIDTH = 1024
local RT_HEIGHT = 1024
local MESH_RES_X = 50
local MESH_RES_Y = 50
local rt_Texture = nil
local crt_Material = nil
local screen_Mesh = nil
local last_W, last_H = 0, 0
local last_MX, last_MY = 0, 0
local noise_Texture = nil
local function DistortCoordinates(u, v, curvature)
    local cc_x = u - 0.5
    local cc_y = v - 0.5
    local dist = (cc_x * cc_x + cc_y * cc_y) * curvature
    local scale = 1.0 + dist * (1.0 + dist)
    return (cc_x * scale) + 0.5, (cc_y * scale) + 0.5
end
function VOIDTERM.CRT.Init()
    rt_Texture = GetRenderTarget("VoidTermCRT_Pro", RT_WIDTH, RT_HEIGHT)
    crt_Material = CreateMaterial("VoidTermCRT_Mat", "UnlitGeneric", {
        ["$basetexture"] = "VoidTermCRT_Pro",
        ["$vertexcolor"] = 1,
        ["$vertexalpha"] = 1,
        ["$translucent"] = 1,
        ["$additive"] = 0,
        ["$clamps"] = 1,
        ["$clampt"] = 1
    })
end
local function RebuildMesh(x, y, w, h)
    if not screen_Mesh then
        screen_Mesh = Mesh()
    end
    local verts = {}
    local step_u = 1 / MESH_RES_X
    local step_v = 1 / MESH_RES_Y
    mesh.Begin(screen_Mesh, MATERIAL_QUADS, MESH_RES_X * MESH_RES_Y)
    for j = 0, MESH_RES_Y - 1 do
        for i = 0, MESH_RES_X - 1 do
            local u0, v0 = i * step_u, j * step_v
            local u1, v1 = (i + 1) * step_u, (j + 1) * step_v
            local wx0, wy0 = x + u0 * w, y + v0 * h
            local wx1, wy1 = x + u1 * w, y + v1 * h
            local tu0, tv0 = DistortCoordinates(u0, v0, PRO_CURVATURE)
            local tu1, tv1 = DistortCoordinates(u1, v0, PRO_CURVATURE)
            local tu2, tv2 = DistortCoordinates(u1, v1, PRO_CURVATURE)
            local tu3, tv3 = DistortCoordinates(u0, v1, PRO_CURVATURE)
            local function GetFade(u, v)
                 if u < 0 or u > 1 or v < 0 or v > 1 then return 0 end
                 local margin = 0.02
                 local alpha = 255
                 if u < margin then alpha = math.min(alpha, (u/margin)*255) end
                 if u > 1-margin then alpha = math.min(alpha, ((1-u)/margin)*255) end
                 if v < margin then alpha = math.min(alpha, (v/margin)*255) end
                 if v > 1-margin then alpha = math.min(alpha, ((1-v)/margin)*255) end
                 return alpha
            end
            local a0 = GetFade(tu0, tv0)
            local a1 = GetFade(tu1, tv1)
            local a2 = GetFade(tu2, tv2)
            local a3 = GetFade(tu3, tv3)
            mesh.Position(Vector(wx0, wy0, 0)); mesh.TexCoord(0, tu0, tv0); mesh.Color(255, 255, 255, a0); mesh.AdvanceVertex()
            mesh.Position(Vector(wx1, wy0, 0)); mesh.TexCoord(0, tu1, tv1); mesh.Color(255, 255, 255, a1); mesh.AdvanceVertex()
            mesh.Position(Vector(wx1, wy1, 0)); mesh.TexCoord(0, tu2, tv2); mesh.Color(255, 255, 255, a2); mesh.AdvanceVertex()
            mesh.Position(Vector(wx0, wy1, 0)); mesh.TexCoord(0, tu3, tv3); mesh.Color(255, 255, 255, a3); mesh.AdvanceVertex()
        end
    end
    mesh.End()
end
function VOIDTERM.CRT.DrawMonitorBezel(x, y, w, h)
    local bezelColor = Color(200, 200, 200)
    local bezelSize = 10
    draw.RoundedBox(8, x - bezelSize, y - bezelSize, w + bezelSize*2, h + bezelSize*2, bezelColor)
    surface.SetDrawColor(20, 20, 20)
    surface.DrawRect(x - 2, y - 2, w + 4, h + 4)
    surface.SetDrawColor(255, 255, 255, 100)
    surface.DrawRect(x - bezelSize, y - bezelSize, w + bezelSize*2, 1)
    surface.DrawRect(x - bezelSize, y - bezelSize, 1, h + bezelSize*2)
end
function VOIDTERM.CRT.BeginCapture()
    if not rt_Texture then VOIDTERM.CRT.Init() end
    render.PushRenderTarget(rt_Texture)
    render.Clear(0, 0, 0, 255)
    cam.Start2D()
end
function VOIDTERM.CRT.EndCapture()
    cam.End2D()
    render.PopRenderTarget()
end
function VOIDTERM.CRT.DrawScreenEffects(x, y, w, h, absX, absY)
    if not rt_Texture or not crt_Material then return end
    local mx, my = absX or x, absY or y
    if w ~= last_W or h ~= last_H or mx ~= last_MX or my ~= last_MY then
        RebuildMesh(mx, my, w, h)
        last_W, last_H = w, h
        last_MX, last_MY = mx, my
    end
    render.SetMaterial(crt_Material)
    crt_Material:SetTexture("$basetexture", rt_Texture)
    if screen_Mesh then
        screen_Mesh:Draw()
    end
    surface.SetDrawColor(0, 0, 0, 30)
    for ly = y, y + h, 4 do
        surface.DrawRect(x, ly, w, 2)
    end
    local sweep = (CurTime() * 0.2) % 1.2 - 0.1
    local sweepY = y + sweep * h
    if sweep >= 0 and sweep <= 1 then
        surface.SetDrawColor(255, 255, 255, 5)
        surface.DrawRect(x, sweepY, w, 20)
    end
    surface.SetDrawColor(0, 0, 0, 200)
    surface.DrawRect(x, y, w, 4)
    surface.DrawRect(x, y + h - 4, w, 4)
    surface.DrawRect(x, y, 4, h)
    surface.DrawRect(x + w - 4, y, 4, h)
end
function VOIDTERM.CRT.GetProfileColor()
    return PRO_COLOR_FG
end
function VOIDTERM.CRT.ScreenToContent(mouseX, mouseY, screenX, screenY, screenW, screenH)
    local u = (mouseX - screenX) / screenW
    local v = (mouseY - screenY) / screenH
    local du, dv = DistortCoordinates(u, v, PRO_CURVATURE)
    return du * screenW, dv * screenH
end
function VOIDTERM.CRT.DrawCornerMask(x, y, w, h, radius, color)
    surface.SetDrawColor(color or Color(20, 20, 20))
    radius = radius or 20
    local function DrawInverseCorner(cx, cy, r, rotation)
        local verts = {}
        local cornerX, cornerY = cx, cy
        table.insert(verts, { x = cornerX, y = cornerY })
        local ox, oy = 0, 0
        if rotation == 0 then ox, oy = r, r end
        if rotation == 1 then ox, oy = -r, r end
        if rotation == 2 then ox, oy = -r, -r end
        if rotation == 3 then ox, oy = r, -r end
        local centerX, centerY = cx + ox, cy + oy
        local startAngle = 0
        if rotation == 0 then startAngle = 180 end
        if rotation == 1 then startAngle = 270 end
        if rotation == 2 then startAngle = 0 end
        if rotation == 3 then startAngle = 90 end
        local segs = 16
        for i = 0, segs do
            local perc = i / segs
            local a = math.rad(startAngle + 90 * perc)
            table.insert(verts, { x = centerX + math.cos(a)*r, y = centerY + math.sin(a)*r })
        end
        draw.NoTexture()
        surface.DrawPoly(verts)
    end
    DrawInverseCorner(x, y, radius, 0)
    DrawInverseCorner(x + w, y, radius, 1)
    DrawInverseCorner(x + w, y + h, radius, 2)
    DrawInverseCorner(x, y + h, radius, 3)
end
