include("shared.lua")
include("verlet.lua")
function ENT:Draw()
end
local mat_up_front = Material("hide/others/Vomat_Up.png",      "noclamp smooth")
local mat_up_back  = Material("hide/others/Vomat_UP_Back.png", "noclamp smooth")
local mat_down     = Material("hide/others/Vomat_Down.png",    "noclamp smooth")
local mat_up_front_at = Material("hide/others/Vomat_Up.png",      "noclamp smooth alphatest")
local mat_up_back_at  = Material("hide/others/Vomat_UP_Back.png", "noclamp smooth alphatest")
local mat_down_at     = Material("hide/others/Vomat_Down.png",    "noclamp smooth alphatest")
local WORLD_W = 120
local UP_W,   UP_H   = WORLD_W, 64
local DOWN_W, DOWN_H = WORLD_W, 59
local ROOT_UNDERGROUND = 0
local MOUTH_OPEN    = 0.20
local MOUTH_HOLD    = 0.20
local MOUTH_CLOSE   = 0.25
local MOUTH_BOUNCE  = 0.15
local MOUTH_SETTLE  = 0.15
local MOUTH_TOTAL   = MOUTH_OPEN + MOUTH_HOLD + MOUTH_CLOSE + MOUTH_BOUNCE + MOUTH_SETTLE
local MASK_W_PX = 516
local MASK_H_PX = 277
local MASK_CX   = 250.4 / 516
local MASK_CY   = 163.8 / 277
local MASK_R_IN = 25
local MASK_R_OUT= 66
local GRID_RES  = 16
local PX_TO_WORLD       = UP_H / MASK_H_PX
local MOUTH_MAX_DISP_PX = (MASK_R_OUT - MASK_R_IN) * 1.4
local _at = { [mat_up_front] = mat_up_front_at, [mat_up_back] = mat_up_back_at, [mat_down] = mat_down_at }
local function DepthPass(drawFn, mat)
    local at = _at[mat]
    if not at then return end
    render.DepthRange(0.0002, 1)
    render.OverrideColorWriteEnable(true, false)
    render.SetMaterial(at)
    drawFn()
    render.OverrideColorWriteEnable(false, false)
    render.DepthRange(0, 1)
end
local function DrawQuadSingle(pos, dir, w, h, mat, alpha)
    DepthPass(function() render.DrawQuadEasy(pos, dir, -w, -h, Color(255, 255, 255, 255)) end, mat)
    render.SetMaterial(mat)
    render.DrawQuadEasy(pos, dir, -w, -h, Color(255, 255, 255, alpha))
end
local function GetOpenAmount(elapsed)
    if elapsed < MOUTH_OPEN then
        local t = elapsed / MOUTH_OPEN; return 1-(1-t)*(1-t)
    end
    elapsed = elapsed - MOUTH_OPEN
    if elapsed < MOUTH_HOLD then return 1.0 end
    elapsed = elapsed - MOUTH_HOLD
    if elapsed < MOUTH_CLOSE then return 1-(elapsed/MOUTH_CLOSE)^2 end
    elapsed = elapsed - MOUTH_CLOSE
    if elapsed < MOUTH_BOUNCE then return 0.25*math.sin((elapsed/MOUTH_BOUNCE)*math.pi) end
    elapsed = elapsed - MOUTH_BOUNCE
    if elapsed < MOUTH_SETTLE then return 0.25*(1-elapsed/MOUTH_SETTLE) end
    return 0
end
local function GetShapeWeight(angle, shapeID, seed)
    if shapeID == 1 then return 1.0
    elseif shapeID == 2 then return math.abs(math.cos(angle))*0.85+0.15
    elseif shapeID == 3 then return math.abs(math.sin(angle))*0.85+0.15
    elseif shapeID == 4 then return math.Clamp(math.cos(3*angle)*0.55+0.6,0.05,1.0)
    elseif shapeID == 5 then return math.Clamp(math.cos(4*angle)*0.55+0.6,0.05,1.0)
    else
        local v = math.cos(angle+seed*1.0)*0.40 + math.cos(2*angle+seed*2.3)*0.25
                + math.cos(3*angle+seed*0.7)*0.15 + math.cos(5*angle+seed*3.1)*0.10
        return math.Clamp(v+0.65,0.10,1.0)
    end
end
local function GetVertexDisp(u, v, openAmount, shapeID, seed, rightDir)
    if openAmount <= 0 then return vector_origin end
    local px = (u-MASK_CX)*MASK_W_PX; local py = (v-MASK_CY)*MASK_H_PX
    local d  = math.sqrt(px*px+py*py)
    if d < 0.001 or d < MASK_R_IN or d > MASK_R_OUT then return vector_origin end
    local zone_t = (d-MASK_R_IN)/(MASK_R_OUT-MASK_R_IN)
    local ramp   = (1-zone_t)^2
    local shape  = GetShapeWeight(math.atan2(-py,px), shapeID, seed)
    local dispPx = openAmount*ramp*shape*MOUTH_MAX_DISP_PX
    return rightDir*(px/d*dispPx*PX_TO_WORLD) + Vector(0,0,1)*(-(py/d)*dispPx*PX_TO_WORLD)
end
local function DrawBlackCircle(center, radius, rightDir, alpha)
    local segs = 24
    render.SetColorMaterial(); render.SetBlend(alpha/255)
    mesh.Begin(MATERIAL_TRIANGLES, segs)
    for i = 0, segs-1 do
        local a1 = (i/segs)*math.pi*2; local a2 = ((i+1)/segs)*math.pi*2
        mesh.Position(center) mesh.Color(0,0,0,255) mesh.AdvanceVertex()
        mesh.Position(center+rightDir*math.cos(a1)*radius+Vector(0,0,math.sin(a1)*radius))
            mesh.Color(0,0,0,255) mesh.AdvanceVertex()
        mesh.Position(center+rightDir*math.cos(a2)*radius+Vector(0,0,math.sin(a2)*radius))
            mesh.Color(0,0,0,255) mesh.AdvanceVertex()
    end
    mesh.End(); render.SetBlend(1)
end
local function DrawDisplacedHead(pos, mat, facingDir, openAmount, shapeID, seed, alpha)
    local rightRaw = Vector(0,0,1):Cross(facingDir)
    if rightRaw:LengthSqr() < 0.001 then
        DrawQuadSingle(pos, facingDir, UP_W, UP_H, mat, alpha); return
    end
    local rightDir = rightRaw:GetNormalized()
    if openAmount > 0.08 then
        local mouthCenter = pos + Vector(0,0,-(MASK_CY-0.5)*UP_H)
        DrawBlackCircle(mouthCenter, openAmount*(MASK_R_IN+MOUTH_MAX_DISP_PX*0.7)*PX_TO_WORLD, rightDir, alpha)
    end
    local function buildMesh()
        mesh.Begin(MATERIAL_TRIANGLES, GRID_RES*GRID_RES*2)
        for gj = 0, GRID_RES-1 do
            for gi = 0, GRID_RES-1 do
                local u0,v0 = gi/GRID_RES, gj/GRID_RES
                local u1,v1 = (gi+1)/GRID_RES, gj/GRID_RES
                local u2,v2 = gi/GRID_RES, (gj+1)/GRID_RES
                local u3,v3 = (gi+1)/GRID_RES, (gj+1)/GRID_RES
                local function UV2W(u,v) return pos+rightDir*((u-0.5)*UP_W)+Vector(0,0,(0.5-v)*UP_H) end
                local p0=UV2W(u0,v0)+GetVertexDisp(u0,v0,openAmount,shapeID,seed,rightDir)
                local p1=UV2W(u1,v1)+GetVertexDisp(u1,v1,openAmount,shapeID,seed,rightDir)
                local p2=UV2W(u2,v2)+GetVertexDisp(u2,v2,openAmount,shapeID,seed,rightDir)
                local p3=UV2W(u3,v3)+GetVertexDisp(u3,v3,openAmount,shapeID,seed,rightDir)
                mesh.Position(p0) mesh.TexCoord(0,u0,v0) mesh.Color(255,255,255,255) mesh.AdvanceVertex()
                mesh.Position(p1) mesh.TexCoord(0,u1,v1) mesh.Color(255,255,255,255) mesh.AdvanceVertex()
                mesh.Position(p3) mesh.TexCoord(0,u3,v3) mesh.Color(255,255,255,255) mesh.AdvanceVertex()
                mesh.Position(p0) mesh.TexCoord(0,u0,v0) mesh.Color(255,255,255,255) mesh.AdvanceVertex()
                mesh.Position(p3) mesh.TexCoord(0,u3,v3) mesh.Color(255,255,255,255) mesh.AdvanceVertex()
                mesh.Position(p2) mesh.TexCoord(0,u2,v2) mesh.Color(255,255,255,255) mesh.AdvanceVertex()
            end
        end
        mesh.End()
    end
    DepthPass(buildMesh, mat)
    render.SetMaterial(mat); render.SetBlend(alpha/255)
    mesh.Begin(MATERIAL_TRIANGLES, GRID_RES*GRID_RES*2)
    for gj = 0, GRID_RES-1 do
        for gi = 0, GRID_RES-1 do
            local u0,v0 = gi/GRID_RES, gj/GRID_RES
            local u1,v1 = (gi+1)/GRID_RES, gj/GRID_RES
            local u2,v2 = gi/GRID_RES, (gj+1)/GRID_RES
            local u3,v3 = (gi+1)/GRID_RES, (gj+1)/GRID_RES
            local function UV2W(u,v) return pos+rightDir*((u-0.5)*UP_W)+Vector(0,0,(0.5-v)*UP_H) end
            local p0=UV2W(u0,v0)+GetVertexDisp(u0,v0,openAmount,shapeID,seed,rightDir)
            local p1=UV2W(u1,v1)+GetVertexDisp(u1,v1,openAmount,shapeID,seed,rightDir)
            local p2=UV2W(u2,v2)+GetVertexDisp(u2,v2,openAmount,shapeID,seed,rightDir)
            local p3=UV2W(u3,v3)+GetVertexDisp(u3,v3,openAmount,shapeID,seed,rightDir)
            mesh.Position(p0) mesh.TexCoord(0,u0,v0) mesh.Color(255,255,255,255) mesh.AdvanceVertex()
            mesh.Position(p1) mesh.TexCoord(0,u1,v1) mesh.Color(255,255,255,255) mesh.AdvanceVertex()
            mesh.Position(p3) mesh.TexCoord(0,u3,v3) mesh.Color(255,255,255,255) mesh.AdvanceVertex()
            mesh.Position(p0) mesh.TexCoord(0,u0,v0) mesh.Color(255,255,255,255) mesh.AdvanceVertex()
            mesh.Position(p3) mesh.TexCoord(0,u3,v3) mesh.Color(255,255,255,255) mesh.AdvanceVertex()
            mesh.Position(p2) mesh.TexCoord(0,u2,v2) mesh.Color(255,255,255,255) mesh.AdvanceVertex()
        end
    end
    mesh.End(); render.SetBlend(1)
end
hook.Add("PostDrawTranslucentRenderables", "VOMAT_Draw", function(bDrawingDepth, bDrawingSkybox)
    if bDrawingDepth or bDrawingSkybox then return end
    local ply = LocalPlayer()
    if not IsValid(ply) then return end
    local time = CurTime()
    local ft   = FrameTime()
    if ft <= 0 then ft = 0.016 end
    for _, ent in ipairs(ents.FindByClass("VOMAT")) do
        if not IsValid(ent) then continue end
        local creationTime = ent:GetCreationTime()
        local delay = 5 + (ent:EntIndex() % 16)
        if creationTime and CurTime() - creationTime < delay then continue end
        local entPos = ent:GetPos()
        local state  = VOMAT_UpdateEmerge(ent, ft)
        local em     = state.emerge
        if em <= 0 then continue end
        local alpha = 255
        local forward = ent:GetForward()
        forward.z = 0
        if forward:LengthSqr() < 0.001 then forward = Vector(1,0,0) end
        forward:Normalize()
        render.FogMode(0)
        local total_h  = DOWN_H + ROOT_UNDERGROUND
        local center_z = entPos.z + DOWN_H * em - total_h * 0.5
        local rootPos  = Vector(entPos.x, entPos.y, center_z)
        DrawQuadSingle(rootPos,  forward, DOWN_W, total_h, mat_down, alpha)
        DrawQuadSingle(rootPos, -forward, DOWN_W, total_h, mat_down, alpha)
        local SEAM_COVER  = 0.25
        local rootTop     = entPos.z + DOWN_H * em
        local headCenterZ = rootTop + UP_H * 0.5 - SEAM_COVER
        local headPos     = Vector(entPos.x, entPos.y, headCenterZ)
        local lastThrow    = ent:GetNWFloat("LastThrowTime", 0)
        local throwElapsed = time - lastThrow
        local openAmount   = 0
        local shapeID      = ent:GetNWInt("MouthShape", 1)
        local seed         = (lastThrow * 7.3) % (math.pi * 2)
        if throwElapsed >= 0 and throwElapsed < MOUTH_TOTAL then
            openAmount = GetOpenAmount(throwElapsed)
        end
        if openAmount > 0 then
            DrawDisplacedHead(headPos, mat_up_front,  forward, openAmount, shapeID, seed, alpha)
            DrawDisplacedHead(headPos, mat_up_back,  -forward, openAmount, shapeID, seed, alpha)
        else
            DrawQuadSingle(headPos,  forward, UP_W, UP_H, mat_up_front, alpha)
            DrawQuadSingle(headPos, -forward, UP_W, UP_H, mat_up_back,  alpha)
        end
        render.FogMode(1)
        if em < 0.7 then
            if not ent._nextBlood or time > ent._nextBlood then
                ent._nextBlood = time + 0.1
                if math.random() < 0.05 then
                    local fx = EffectData()
                    fx:SetOrigin(entPos); fx:SetScale(0.25)
                    util.Effect("bloodspray", fx)
                end
            end
        end
    end
end)
function ENT:OnRemove()
    local fx = EffectData()
    fx:SetOrigin(self:GetPos() + Vector(0,0,32)); fx:SetScale(3)
    util.Effect("bloodspray", fx)
end
