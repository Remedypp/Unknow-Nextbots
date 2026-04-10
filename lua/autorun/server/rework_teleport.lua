if not SERVER then return end
util.AddNetworkString("UNKNOW_DigitalWorld_RequestTeleport")
util.AddNetworkString("UNKNOW_DigitalWorld_TeleportResult")
local CFG = {
    MAX_ATTEMPTS          = 100,
    AIR_TELEPORT_CHANCE   = 5,
    PLAYER_MINS           = Vector(-16, -16, 0),
    PLAYER_MAXS           = Vector(16,  16,  72),
    MIN_AIR_HEIGHT        = 100,
    EMERGENCY_HEIGHT      = 200,
    GROUND_OFFSET         = 5,
    CEILING_CHECK_HEIGHT  = 100,
    MIN_CEILING_CLEARANCE = 80,
    MAP_PADDING           = 100,
}
local function GetMapBounds()
    local world = game.GetWorld()
    if not IsValid(world) then
        return Vector(-4096, -4096, -1024), Vector(4096, 4096, 1024)
    end
    local mins, maxs = world:GetModelBounds()
    if not mins or not maxs then
        return Vector(-4096, -4096, -1024), Vector(4096, 4096, 1024)
    end
    return mins, maxs
end
local function IsSafe(pos, ply)
    local hull = util.TraceHull({
        start  = pos, endpos = pos + Vector(0, 0, 1),
        mins   = CFG.PLAYER_MINS, maxs = CFG.PLAYER_MAXS,
        filter = ply,
    })
    if hull.Hit or hull.StartSolid then return false end
    local ceil = util.TraceLine({
        start  = pos, endpos = pos + Vector(0, 0, CFG.CEILING_CHECK_HEIGHT),
        filter = ply,
    })
    if ceil.Hit and ceil.HitPos:Distance(pos) < CFG.MIN_CEILING_CLEARANCE then return false end
    return true
end
local function FindGroundPos(ply, mapMin, mapMax)
    for _ = 1, CFG.MAX_ATTEMPTS do
        local x = math.random(mapMin.x + CFG.MAP_PADDING, mapMax.x - CFG.MAP_PADDING)
        local y = math.random(mapMin.y + CFG.MAP_PADDING, mapMax.y - CFG.MAP_PADDING)
        local z = math.random(mapMin.z + 200,             mapMax.z - 200)
        local tr = util.TraceLine({
            start  = Vector(x, y, z),
            endpos = Vector(x, y, z) + Vector(0, 0, -2000),
            filter = ply,
        })
        if tr.Hit and tr.HitWorld then
            local gp = tr.HitPos + Vector(0, 0, CFG.GROUND_OFFSET)
            if IsSafe(gp, ply) then return gp end
        end
    end
end
local function FindAirPos(ply, mapMin, mapMax)
    for _ = 1, CFG.MAX_ATTEMPTS do
        local x = math.random(mapMin.x + CFG.MAP_PADDING, mapMax.x - CFG.MAP_PADDING)
        local y = math.random(mapMin.y + CFG.MAP_PADDING, mapMax.y - CFG.MAP_PADDING)
        local z = math.random(mapMin.z + 200,             mapMax.z - 200)
        local pos = Vector(x, y, z)
        local hull = util.TraceHull({
            start = pos, endpos = pos,
            mins  = CFG.PLAYER_MINS, maxs = CFG.PLAYER_MAXS,
            filter = ply,
        })
        if not hull.Hit and not hull.StartSolid then
            local tr = util.TraceLine({
                start  = pos, endpos = pos + Vector(0, 0, -200),
                filter = ply,
            })
            if tr.Hit and tr.HitPos:Distance(pos) > CFG.MIN_AIR_HEIGHT then
                return pos
            end
        end
    end
end
net.Receive("UNKNOW_DigitalWorld_RequestTeleport", function(_, ply)
    if not IsValid(ply) then return end
    local mapMin, mapMax = GetMapBounds()
    local isAir = math.random(1, 100) <= CFG.AIR_TELEPORT_CHANCE
    local pos, kind
    if isAir then
        pos  = FindAirPos(ply, mapMin, mapMax)
        kind = "air"
    else
        pos  = FindGroundPos(ply, mapMin, mapMax)
        kind = "ground"
    end
    if not pos then
        pos  = ply:GetPos() + Vector(0, 0, CFG.EMERGENCY_HEIGHT)
        kind = "emergency"
    end
    ply:SetPos(pos)
    ply:EmitSound("ambient/energy/weld1.wav", 75, 100)
    net.Start("UNKNOW_DigitalWorld_TeleportResult")
    net.WriteBool(true)
    net.WriteString(kind)
    net.Send(ply)
end)
