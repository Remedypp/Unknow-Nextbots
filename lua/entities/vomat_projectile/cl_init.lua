include("shared.lua")
local SOUL_MAT = nil
local function GenerateSoulMaterial()
    if SOUL_MAT then return end
    local rtName = "VomatSoulBlob_RT"
    local rt = GetRenderTarget(rtName, 128, 128)
    render.PushRenderTarget(rt)
    cam.Start2D()
    for y = 0, 127 do
        for x = 0, 127 do
            local cx, cy = x - 64, y - 64
            local dist = math.sqrt(cx * cx + cy * cy) / 64
            local n1 = math.sin(x * 0.15 + y * 0.1) * 0.5 + 0.5
            local n2 = math.cos(x * 0.08 - y * 0.12) * 0.5 + 0.5
            local n3 = math.sin((x + y) * 0.2) * 0.3 + 0.5
            local noise = (n1 * 0.4 + n2 * 0.35 + n3 * 0.25)
            local r = math.Clamp(math.floor(180 * noise * (1 - dist * 0.5)), 0, 255)
            local g = math.Clamp(math.floor(30 * noise * (1 - dist)), 0, 255)
            local b = math.Clamp(math.floor(20 * noise * (1 - dist)), 0, 255)
            surface.SetDrawColor(r, g, b, 255)
            surface.DrawRect(x, y, 1, 1)
        end
    end
    for i = 1, 40 do
        local sx, sy = math.random(10, 118), math.random(10, 118)
        local len = math.random(8, 30)
        local ang = math.random() * math.pi * 2
        for j = 0, len do
            local px = math.floor(sx + math.cos(ang) * j)
            local py = math.floor(sy + math.sin(ang) * j)
            if px >= 0 and px < 128 and py >= 0 and py < 128 then
                surface.SetDrawColor(60, 0, 0, 80)
                surface.DrawRect(px, py, 2, 2)
            end
        end
    end
    cam.End2D()
    render.PopRenderTarget()
    SOUL_MAT = CreateMaterial("VomatSoulBlobMat", "VertexLitGeneric", {
        ["$basetexture"] = rtName,
        ["$model"] = 1,
        ["$vertexcolor"] = 1,
        ["$vertexalpha"] = 1,
    })
end
local SEGS = 10
local SIDES = 8
local GRID = {}
for lat = 0, SEGS do
    GRID[lat] = {}
    local theta = (lat / SEGS) * math.pi
    local st = math.sin(theta)
    local ct = math.cos(theta)
    local v = lat / SEGS
    for lon = 0, SIDES do
        local phi = (lon / SIDES) * math.pi * 2
        local dir = Vector(st * math.cos(phi), st * math.sin(phi), ct)
        GRID[lat][lon] = {
            dir = dir,
            vSeed = lat * 13.7 + lon * 7.3,
            u = lon / SIDES,
            v = v,
        }
    end
end
local TOTAL_TRIS = SEGS * SIDES * 2
local PROJ_UNIT_MESH = nil
local PROJ_SMOOTH_SCALE = {}
local function EnsureProjUnitMesh()
    if PROJ_UNIT_MESH then return end
    PROJ_UNIT_MESH = Mesh()
    mesh.Begin(PROJ_UNIT_MESH, MATERIAL_TRIANGLES, TOTAL_TRIS)
    for lat = 0, SEGS - 1 do
        for lon = 0, SIDES - 1 do
            local g1, g2 = GRID[lat][lon],     GRID[lat][lon + 1]
            local g3, g4 = GRID[lat + 1][lon], GRID[lat + 1][lon + 1]
            mesh.Position(g1.dir) mesh.Normal(g1.dir) mesh.TexCoord(0, g1.u, g1.v) mesh.Color(255, 110, 90, 255) mesh.AdvanceVertex()
            mesh.Position(g2.dir) mesh.Normal(g2.dir) mesh.TexCoord(0, g2.u, g2.v) mesh.Color(255, 110, 90, 255) mesh.AdvanceVertex()
            mesh.Position(g3.dir) mesh.Normal(g3.dir) mesh.TexCoord(0, g3.u, g3.v) mesh.Color(255, 100, 80, 255) mesh.AdvanceVertex()
            mesh.Position(g2.dir) mesh.Normal(g2.dir) mesh.TexCoord(0, g2.u, g2.v) mesh.Color(255, 110, 90, 255) mesh.AdvanceVertex()
            mesh.Position(g4.dir) mesh.Normal(g4.dir) mesh.TexCoord(0, g4.u, g4.v) mesh.Color(255, 100, 80, 255) mesh.AdvanceVertex()
            mesh.Position(g3.dir) mesh.Normal(g3.dir) mesh.TexCoord(0, g3.u, g3.v) mesh.Color(255, 100, 80, 255) mesh.AdvanceVertex()
        end
    end
    mesh.End()
end
local function CleanupMesh(entIdx)
    PROJ_SMOOTH_SCALE[entIdx] = nil
end
function ENT:Initialize()
    self.seed = math.random(1, 1000)
    self:SetRenderBounds(Vector(-64, -64, -64), Vector(64, 64, 64))
    PROJ_SMOOTH_SCALE[self:EntIndex()] = 10
end
function ENT:OnRemove()
    CleanupMesh(self:EntIndex())
end
hook.Add("PostDrawOpaqueRenderables", "VomatProjectile_Draw", function(bDrawingDepth)
    if bDrawingDepth then return end
    local ply = LocalPlayer()
    if not IsValid(ply) then return end
    GenerateSoulMaterial()
    if not SOUL_MAT then return end
    EnsureProjUnitMesh()
    local projectiles = ents.FindByClass("vomat_projectile")
    if #projectiles == 0 then return end
    local plyPos = ply:GetPos()
    local time = CurTime()
    local ft = FrameTime()
    if ft <= 0 then ft = 0.016 end
    render.SetMaterial(SOUL_MAT)
    render.SuppressEngineLighting(true)
    render.SetColorModulation(0.8, 0, 0)
    render.OverrideDepthEnable(true, true)
    for _, ent in ipairs(projectiles) do
        if not IsValid(ent) then continue end
        local currentPos = ent:GetPos()
        if currentPos:DistToSqr(plyPos) > 4000000 then continue end
        if not ent.NextBloodTime or time > ent.NextBloodTime then
            ent.NextBloodTime = time + 0.15
            local isAggressive = ent:GetNWBool("IsAggressiveThrow", false)
            local isWeak = ent:GetNWBool("IsWeakThrow", false)
            local fx = EffectData()
            fx:SetOrigin(currentPos)
            fx:SetScale(isAggressive and 1.5 or (isWeak and 0.5 or 1))
            util.Effect("bloodspray", fx)
        end
        local seed = ent.seed or 0
        local entIdx = ent:EntIndex()
        local targetRadius = 10 + math.sin(time * 2.5 + seed) * 2.5
        if not PROJ_SMOOTH_SCALE[entIdx] then
            PROJ_SMOOTH_SCALE[entIdx] = targetRadius
        end
        PROJ_SMOOTH_SCALE[entIdx] = PROJ_SMOOTH_SCALE[entIdx] + (targetRadius - PROJ_SMOOTH_SCALE[entIdx]) * (1 - math.exp(-12 * ft))
        local r = PROJ_SMOOTH_SCALE[entIdx]
        local wx = r * (1 + math.sin(time * 3.0 + seed * 2.1) * 0.20)
        local wy = r * (1 + math.sin(time * 5.5 + seed * 3.7) * 0.15)
        local wz = r * (1 + math.cos(time * 8.0 + seed * 1.3) * 0.18)
        local mat = Matrix()
        mat:Translate(currentPos)
        mat:Scale(Vector(wx, wy, wz))
        cam.PushModelMatrix(mat)
        PROJ_UNIT_MESH:Draw()
        cam.PopModelMatrix()
    end
    render.OverrideDepthEnable(false)
    render.SetColorModulation(1, 1, 1)
    render.SuppressEngineLighting(false)
end)
hook.Add("PostCleanupMap", "VomatProjectile_CleanupMeshes", function()
    PROJ_SMOOTH_SCALE = {}
    if PROJ_UNIT_MESH then
        PROJ_UNIT_MESH:Destroy()
        PROJ_UNIT_MESH = nil
    end
end)
local BLOB_DATA = {}
local BLOB_DURATION = 8
net.Receive("VomatBlobHit", function()
    local ply = net.ReadEntity()
    local boneID = net.ReadUInt(8)
    local hitTime = net.ReadFloat()
    if not IsValid(ply) then return end
    local spreadBones = {boneID}
    local hitPos = ply:GetBonePosition(boneID) or ply:GetPos()
    local boneNames = {
        "ValveBiped.Bip01_Spine", "ValveBiped.Bip01_Spine1",
        "ValveBiped.Bip01_Spine2", "ValveBiped.Bip01_L_UpperArm",
        "ValveBiped.Bip01_R_UpperArm", "ValveBiped.Bip01_L_Thigh",
        "ValveBiped.Bip01_R_Thigh", "ValveBiped.Bip01_Head1",
        "ValveBiped.Bip01_Pelvis",
    }
    local candidates = {}
    for _, name in ipairs(boneNames) do
        local bID = ply:LookupBone(name)
        if bID and bID ~= boneID then
            local bPos = ply:GetBonePosition(bID)
            if bPos then
                table.insert(candidates, {id = bID, dist = bPos:DistToSqr(hitPos)})
            end
        end
    end
    table.sort(candidates, function(a, b) return a.dist < b.dist end)
    local numExtra = math.random(1, 2)
    for i = 1, math.min(numExtra, #candidates) do
        table.insert(spreadBones, candidates[i].id)
    end
    for i, bID in ipairs(spreadBones) do
        local tracker = ClientsideModel("models/dav0r/hoverball.mdl")
        if not IsValid(tracker) then continue end
        tracker:SetNoDraw(true)
        tracker:SetModelScale(0.01, 0)
        tracker:FollowBone(ply, bID)
        local id = "blob_" .. tostring(ply) .. "_" .. bID .. "_" .. CurTime()
        table.insert(BLOB_DATA, {
            id = id,
            player = ply,
            tracker = tracker,
            boneID = bID,
            startTime = CurTime(),
            seed = math.random(1, 1000),
            radius = (i == 1) and math.Rand(5, 7) or math.Rand(3, 5),
        })
    end
end)
local BLOB_UNIT_MESH = nil
local function EnsureBlobUnitMesh()
    if BLOB_UNIT_MESH then return end
    BLOB_UNIT_MESH = Mesh()
    mesh.Begin(BLOB_UNIT_MESH, MATERIAL_TRIANGLES, TOTAL_TRIS)
    for lat = 0, SEGS - 1 do
        for lon = 0, SIDES - 1 do
            local g1, g2 = GRID[lat][lon],     GRID[lat][lon + 1]
            local g3, g4 = GRID[lat + 1][lon], GRID[lat + 1][lon + 1]
            mesh.Position(g1.dir) mesh.Normal(g1.dir) mesh.TexCoord(0, g1.u, g1.v) mesh.Color(255, 110, 90, 255) mesh.AdvanceVertex()
            mesh.Position(g2.dir) mesh.Normal(g2.dir) mesh.TexCoord(0, g2.u, g2.v) mesh.Color(255, 110, 90, 255) mesh.AdvanceVertex()
            mesh.Position(g3.dir) mesh.Normal(g3.dir) mesh.TexCoord(0, g3.u, g3.v) mesh.Color(255, 100, 80, 255) mesh.AdvanceVertex()
            mesh.Position(g2.dir) mesh.Normal(g2.dir) mesh.TexCoord(0, g2.u, g2.v) mesh.Color(255, 110, 90, 255) mesh.AdvanceVertex()
            mesh.Position(g4.dir) mesh.Normal(g4.dir) mesh.TexCoord(0, g4.u, g4.v) mesh.Color(255, 100, 80, 255) mesh.AdvanceVertex()
            mesh.Position(g3.dir) mesh.Normal(g3.dir) mesh.TexCoord(0, g3.u, g3.v) mesh.Color(255, 100, 80, 255) mesh.AdvanceVertex()
        end
    end
    mesh.End()
end
hook.Add("PostDrawOpaqueRenderables", "VomatBlob_OnPlayer", function(bDrawingDepth)
    if bDrawingDepth then return end
    if #BLOB_DATA == 0 then return end
    GenerateSoulMaterial()
    if not SOUL_MAT then return end
    EnsureBlobUnitMesh()
    local time = CurTime()
    render.SetMaterial(SOUL_MAT)
    render.SuppressEngineLighting(true)
    render.SetColorModulation(0.8, 0, 0)
    render.OverrideDepthEnable(true, true)
    local localPly = LocalPlayer()
    for i = #BLOB_DATA, 1, -1 do
        local data = BLOB_DATA[i]
        if not IsValid(data.player) or not data.player:Alive()
           or (time - data.startTime) > BLOB_DURATION then
            if IsValid(data.tracker) then data.tracker:Remove() end
            table.remove(BLOB_DATA, i)
            continue
        end
        if data.player == localPly and not localPly:ShouldDrawLocalPlayer() then continue end
        data.player:SetupBones()
        local boneMat = data.player:GetBoneMatrix(data.boneID)
        local center = boneMat and boneMat:GetTranslation() or (data.player:GetPos() + Vector(0, 0, 40))
        local seed = data.seed
        local wx = data.radius * (1 + math.sin(time * 3.0 + seed * 2.1) * 0.20)
        local wy = data.radius * (1 + math.sin(time * 5.5 + seed * 3.7) * 0.15)
        local wz = data.radius * (1 + math.cos(time * 8.0 + seed * 1.3) * 0.18)
        local mat = Matrix()
        mat:Translate(center)
        mat:Scale(Vector(wx, wy, wz))
        cam.PushModelMatrix(mat)
        BLOB_UNIT_MESH:Draw()
        cam.PopModelMatrix()
    end
    render.OverrideDepthEnable(false)
    render.SetColorModulation(1, 1, 1)
    render.SuppressEngineLighting(false)
end)
net.Receive("VomatImpactFX", function()
    local pos = net.ReadVector()
    local isAggressive = net.ReadBool()
    local isWeak = net.ReadBool()
    local effectScale = isAggressive and 4 or (isWeak and 2 or 3)
    local fx = EffectData()
    fx:SetOrigin(pos)
    fx:SetScale(effectScale)
    util.Effect("bloodspray", fx)
    util.Effect("bloodimpact", fx)
    util.Effect("blood_impact_red", fx)
end)
net.Receive("VomatClearBlobs", function()
    local ply = net.ReadEntity()
    if not IsValid(ply) then return end
    for i = #BLOB_DATA, 1, -1 do
        if BLOB_DATA[i].player == ply then
            if IsValid(BLOB_DATA[i].tracker) then BLOB_DATA[i].tracker:Remove() end
            table.remove(BLOB_DATA, i)
        end
    end
end)
hook.Add("PostCleanupMap", "VomatBlob_CleanupAll", function()
    for _, data in ipairs(BLOB_DATA) do
        if IsValid(data.tracker) then data.tracker:Remove() end
    end
    BLOB_DATA = {}
    if BLOB_UNIT_MESH then
        BLOB_UNIT_MESH:Destroy()
        BLOB_UNIT_MESH = nil
    end
end)
