local ENT = ENT
local function SafeMaterial(path, params)
    local mat = Material(path, params)
    if mat:IsError() then
        return Material("models/debug/debugwhite")
    end
    return mat
end
local unknow_body = SafeMaterial("hide/ERROR/unknow.png", "noclamp smooth")
local unknow_body_back = SafeMaterial("hide/ERROR/unknow_back.png", "noclamp smooth")
local unknow_eye = SafeMaterial("hide/ERROR/unknow_eye.png", "noclamp smooth")
local unknow_eye_back = SafeMaterial("hide/ERROR/unknow_eye_back.png", "noclamp smooth")
local unknow_pupil = SafeMaterial("hide/ERROR/unknow_eye1.png", "noclamp smooth")
local portal_material = Material("models/effects/portalrift_sheet", "smooth mips")
local blink_materials = {}
for i = 1, 5 do
    blink_materials[i] = SafeMaterial("hide/ERROR/blink/unknow_blink" .. i .. ".png", "noclamp smooth")
end
local BODY_OFFSET = Vector(0, 0, 64)
local EYE_OFFSET = Vector(0, 0, 110)
local BODY_SIZE = 128
local HEAD_WIDTH = 60
local HEAD_HEIGHT = 40
local PUPIL_WIDTH = 60
local PUPIL_HEIGHT = 40
local PUPIL_MAX_X = 18
local PUPIL_MAX_Y = 12
local MASK_W = 30
local MASK_H = 20
local BLINK_FRAME_TIME = 0.05
local BLINK_HOLD_TIME = 0.09
local BLINK_INTERVAL_MIN = 3
local BLINK_INTERVAL_MAX = 8
local EYE_SHAPE = {
    {-0.153, 0.767}, {-0.261, 0.712}, {-0.342, 0.658}, {-0.405, 0.603},
    {-0.45, 0.548}, {-0.495, 0.493}, {-0.532, 0.438}, {-0.559, 0.384},
    {-0.586, 0.329}, {-0.613, 0.274}, {-0.64, 0.219}, {-0.658, 0.164},
    {-0.676, 0.11}, {-0.694, 0.055}, {-0.694, 0.0}, {-0.676, -0.055},
    {-0.658, -0.11}, {-0.631, -0.164}, {-0.595, -0.219}, {-0.559, -0.274},
    {-0.505, -0.329}, {-0.468, -0.384}, {-0.414, -0.438}, {-0.351, -0.493},
    {-0.279, -0.548}, {-0.207, -0.603}, {-0.108, -0.658}, {0.099, -0.658},
    {0.216, -0.603}, {0.297, -0.548}, {0.36, -0.493}, {0.423, -0.438},
    {0.468, -0.384}, {0.505, -0.329}, {0.55, -0.274}, {0.586, -0.219},
    {0.622, -0.164}, {0.649, -0.11}, {0.667, -0.055}, {0.667, 0.0},
    {0.658, 0.055}, {0.64, 0.11}, {0.622, 0.164}, {0.586, 0.219},
    {0.559, 0.274}, {0.532, 0.329}, {0.495, 0.384}, {0.468, 0.438},
    {0.423, 0.493}, {0.378, 0.548}, {0.324, 0.603}, {0.261, 0.658},
    {0.18, 0.712}, {0.045, 0.767}
}
local function DrawEyeMask(center, direction, halfW, halfH)
    local ang = direction:Angle()
    local right = ang:Right()
    local up = ang:Up()
    render.SetColorMaterial()
    mesh.Begin(MATERIAL_TRIANGLES, #EYE_SHAPE)
    for i = 1, #EYE_SHAPE do
        local next_i = (i % #EYE_SHAPE) + 1
        local pt1 = EYE_SHAPE[i]
        local pt2 = EYE_SHAPE[next_i]
        local p1 = center
        local p2 = center + right * (-pt1[1] * halfW) + up * (pt1[2] * halfH)
        local p3 = center + right * (-pt2[1] * halfW) + up * (pt2[2] * halfH)
        mesh.Position(p1) mesh.Color(255, 255, 255, 255) mesh.AdvanceVertex()
        mesh.Position(p3) mesh.Color(255, 255, 255, 255) mesh.AdvanceVertex()
        mesh.Position(p2) mesh.Color(255, 255, 255, 255) mesh.AdvanceVertex()
    end
    mesh.End()
end
function ENT:UpdateBlink()
    local ct = CurTime()
    if not self.blinking and ct > self.nextBlink then
        self.blinking = true
        self.blinkFrame = 1
        self.blinkDir = 1
        self.blinkHold = false
        self.lastBlink = ct
    end
    if not self.blinking then return end
    if self.blinkHold then
        if ct - self.lastBlink > BLINK_HOLD_TIME then
            self.blinkHold = false
            self.blinkDir = -1
            self.lastBlink = ct
        end
        return
    end
    if ct - self.lastBlink > BLINK_FRAME_TIME then
        self.blinkFrame = self.blinkFrame + self.blinkDir
        self.lastBlink = ct
        if self.blinkFrame >= 5 then
            self.blinkFrame = 5
            self.blinkHold = true
        elseif self.blinkFrame <= 1 and self.blinkDir == -1 then
            self.blinking = false
            self.blinkFrame = 1
            self.nextBlink = ct + math.random(BLINK_INTERVAL_MIN, BLINK_INTERVAL_MAX)
        end
    end
end
function ENT:CanISeePlayer(player)
    if not IsValid(player) then return false end
    local selfPos = self:GetPos() + Vector(0, 0, 65)
    local targetPos = player:EyePos()
    local aimVector = (targetPos - selfPos):GetNormalized()
    local lookVector = self:GetForward()
    local dotProduct = lookVector:Dot(aimVector)
    local fovCos = math.cos(math.rad(140 / 2))
    local isWithinFOV = dotProduct >= fovCos
    if isWithinFOV then
        local tr = util.TraceLine({
            start = selfPos,
            endpos = targetPos,
            filter = {player, self},
            mask = MASK_SHOT
        })
        if not tr.Hit then
            self.lastKnownPlayerPos = targetPos
            return true
        end
    end
    return false
end
function ENT:GetTargetLookDirection()
    local selfPos = self:GetPos() + Vector(0, 0, 65)
    local ply = LocalPlayer()
    local forwardDirection = self:GetForward()
    if IsValid(ply) and self:CanISeePlayer(ply) then
        return (ply:EyePos() - selfPos):GetNormalized()
    end
    if self.lastKnownPlayerPos then
        local dirToLastKnown = (self.lastKnownPlayerPos - selfPos):GetNormalized()
        if dirToLastKnown:Dot(self.frontEyeDir or forwardDirection) > 0.99 then
            self.lastKnownPlayerPos = nil
        end
        return dirToLastKnown
    end
    return forwardDirection
end
local PUPIL_TRACK_DISTANCE = 600
function ENT:GetPupilOffset(targetDir, eyeDir)
    local eyeAng = eyeDir:Angle()
    local right = eyeAng:Right()
    local up = eyeAng:Up()
    local fwd = eyeAng:Forward()
    local dotFwd = targetDir:Dot(fwd)
    if dotFwd < 0.1 then
        local t = CurTime() * 1.5
        return math.sin(t) * 0.5, math.cos(t * 0.7) * 0.3
    end
    local hDot = targetDir:Dot(right)
    local vDot = targetDir:Dot(up)
    local angleH = math.atan2(hDot, dotFwd)
    local angleV = math.atan2(vDot, dotFwd)
    local maxAngle = 2.8
    local normH = math.Clamp(angleH / maxAngle, -1, 1)
    local normV = math.Clamp(angleV / maxAngle, -1, 1)
    local t = CurTime() * 2
    local microX = math.sin(t * 1.3) * 0.1
    local microY = math.cos(t * 0.9) * 0.08
    return normH * PUPIL_MAX_X + microX, normV * PUPIL_MAX_Y + microY
end
function ENT:GetLookAroundPupil()
    local ct = CurTime()
    if ct > self.nextPupilTime then
        self.pupilTargetX = math.random(-PUPIL_MAX_X, PUPIL_MAX_X) * 0.8
        self.pupilTargetY = math.random(-PUPIL_MAX_Y, PUPIL_MAX_Y) * 0.8
        self.nextPupilTime = ct + math.random() * 0.8 + 0.4
    end
    return self.pupilTargetX, self.pupilTargetY
end
function ENT:UpdateCameraGlance()
    local ct = CurTime()
    if not self.isGlancing and ct > self.nextGlanceTime then
        self.isGlancing = true
        self.glanceStartTime = ct
        local moveType = math.random(1, 5)
        if moveType == 1 then
            self.glanceDuration = 0.15 + math.random() * 0.15
            local dir = math.random() > 0.5 and 1 or -1
            self.glanceX = dir * (10 + math.random() * 5)
            self.glanceY = 0
        elseif moveType == 2 then
            self.glanceDuration = 0.2 + math.random() * 0.2
            local dir = math.random() > 0.5 and 1 or -1
            self.glanceX = dir * (6 + math.random() * 4)
            self.glanceY = 4 + math.random() * 3
        elseif moveType == 3 then
            self.glanceDuration = 0.1 + math.random() * 0.1
            self.glanceX = (math.random() - 0.5) * 4
            self.glanceY = -2 - math.random() * 2
        elseif moveType == 4 then
            self.glanceDuration = 0.4
            self.glanceX = 12
            self.glanceY = 0
            self.isDoubleTake = true
        else
            self.glanceDuration = 0.2 + math.random() * 0.15
            self.glanceX = (math.random() - 0.5) * 6
            self.glanceY = -5 - math.random() * 3
        end
    end
    if self.isGlancing then
        local elapsed = ct - self.glanceStartTime
        if elapsed < self.glanceDuration then
            local progress = elapsed / self.glanceDuration
            if self.isDoubleTake then
                if progress < 0.5 then
                    local ease = math.sin(progress * 2 * math.pi)
                    return self.glanceX * ease, 0
                else
                    local ease = math.sin((progress - 0.5) * 2 * math.pi)
                    return -self.glanceX * ease, 0
                end
            else
                local ease = math.sin(progress * math.pi)
                return self.glanceX * ease, self.glanceY * ease
            end
        else
            self.isGlancing = false
            self.isDoubleTake = false
            self.nextGlanceTime = ct + math.random(4, 8)
        end
    end
    return nil, nil
end
function ENT:DrawEntity()
    render.SetStencilEnable(false)
    render.OverrideColorWriteEnable(false)
    render.SetBlend(1)
    render.OverrideAlphaWriteEnable(false)
    self:UpdateBlink()
    local isWalking = self:GetNWBool("IsWalking", false)
    local eyeState = self:GetNWInt("EyeState", 1)
    local serverHeadDir = self:GetNWVector("LookDirection", self:GetForward())
    local creationTime = self:GetCreationTime()
    if creationTime and CurTime() - creationTime < 2 then
        return
    end
    local isTeleporting = self:GetNWBool("IsTeleporting", false)
    if isTeleporting then
        self.smoothPos = nil
        self.lastServerPos = nil
        self.velocity = nil
        self.frontEyeDir = nil
        self.backEyeDir = nil
        self.bodyFrontDir = nil
        self.bodyBackDir = nil
        return
    end
    local isHiding = self:GetNWBool("IsHiding", false)
    if isHiding then
        return
    end
    local isInReflection = render.GetRenderTarget() ~= nil
    if (isWalking and not isInReflection) or (not isWalking and isInReflection) then
        return
    end
    local serverPos = self:GetPos()
    local ft = FrameTime()
    if ft <= 0 then ft = 0.016 end
    if not self.smoothPos then
        self.smoothPos = serverPos
        self.lastServerPos = serverPos
        self.velocity = Vector(0, 0, 0)
    end
    local posDelta = serverPos - self.lastServerPos
    if posDelta:LengthSqr() > 0.01 then
        local newVelocity = posDelta / ft
        self.velocity = LerpVector(0.2, self.velocity, newVelocity)
        self.lastServerPos = serverPos
    else
        self.velocity = self.velocity * 0.98
    end
    local predictedPos = serverPos + self.velocity * ft * 2
    local smoothFactor = 4
    local alpha = 1 - math.exp(-smoothFactor * ft)
    self.smoothPos = LerpVector(alpha, self.smoothPos, predictedPos)
    local pos = self.smoothPos
    local eyePos = pos + EYE_OFFSET
    local headDir
    local pupilTargetDir
    local ply = LocalPlayer()
    if isWalking then
        local forwardDir = self:GetForward()
        forwardDir.z = 0
        forwardDir:Normalize()
        headDir = forwardDir
        if IsValid(ply) and self:CanISeePlayer(ply) then
            local dist = pos:Distance(ply:GetPos())
            if dist < PUPIL_TRACK_DISTANCE then
                pupilTargetDir = self:GetTargetLookDirection()
            else
                pupilTargetDir = forwardDir
            end
        elseif self.lastKnownPlayerPos then
            pupilTargetDir = (self.lastKnownPlayerPos - (pos + Vector(0, 0, 65))):GetNormalized()
        else
            pupilTargetDir = forwardDir
        end
    else
        local isWatchingRagdoll = self:GetNWBool("IsWatchingRagdoll", false)
        local horrorState = self:GetNWInt("HorrorState", 1)
        if isWatchingRagdoll then
            local ragdollPos = self:GetNWVector("RagdollPosition", pos)
            local dirToRagdoll = (ragdollPos - pos):GetNormalized()
            headDir = Vector(dirToRagdoll.x, dirToRagdoll.y, 0)
            if headDir:LengthSqr() > 0.01 then
                headDir:Normalize()
            else
                headDir = self:GetForward()
            end
            pupilTargetDir = (ragdollPos - (pos + Vector(0, 0, 65))):GetNormalized()
        elseif horrorState >= 2 and horrorState <= 4 and IsValid(ply) then
            local dirToPlayer = (ply:GetPos() - pos):GetNormalized()
            headDir = Vector(dirToPlayer.x, dirToPlayer.y, 0)
            if headDir:LengthSqr() > 0.01 then
                headDir:Normalize()
            else
                headDir = self:GetForward()
            end
            pupilTargetDir = (ply:EyePos() - (pos + Vector(0, 0, 65))):GetNormalized()
        else
            headDir = serverHeadDir
            if not headDir or headDir:LengthSqr() < 0.01 then
                headDir = self:GetForward()
            end
            pupilTargetDir = headDir
        end
    end
    local originalHeadDir = pupilTargetDir
    local PITCH_MIN = -42
    local PITCH_MAX = 17
    local headAng = headDir:Angle()
    local originalPitch = headAng.p
    if originalPitch > 180 then
        originalPitch = originalPitch - 360
    end
    if originalPitch < PITCH_MIN then
        headAng.p = PITCH_MIN
        headDir = headAng:Forward()
    elseif originalPitch > PITCH_MAX then
        headAng.p = PITCH_MAX
        headDir = headAng:Forward()
    end
    self.originalTargetDir = originalHeadDir
    local entityForward = self:GetForward()
    entityForward.z = 0
    entityForward:Normalize()
    local bodyDir = entityForward
    local hHead = Vector(headDir.x, headDir.y, 0)
    hHead:Normalize()
    if not self.bodyFrontDir then self.bodyFrontDir = bodyDir end
    if not self.bodyBackDir then self.bodyBackDir = -bodyDir end
    if not self.frontEyeDir then self.frontEyeDir = headDir end
    if not self.backEyeDir then self.backEyeDir = -headDir end
    self.bodyFrontDir = LerpVector(0.03, self.bodyFrontDir, bodyDir)
    self.bodyBackDir = LerpVector(0.03, self.bodyBackDir, -bodyDir)
    local eyeLerpSpeed = isWalking and 0.06 or 0.03
    self.frontEyeDir = LerpVector(eyeLerpSpeed, self.frontEyeDir, headDir)
    self.backEyeDir = LerpVector(eyeLerpSpeed, self.backEyeDir, -headDir)
    render.FogMode(MATERIAL_FOG_NONE)
    render.SetMaterial(unknow_body)
    render.DrawQuadEasy(pos + BODY_OFFSET, self.bodyFrontDir, -BODY_SIZE, -BODY_SIZE, Color(255, 255, 255, 255))
    render.SetMaterial(unknow_body_back)
    render.DrawQuadEasy(pos + BODY_OFFSET, self.bodyBackDir, -BODY_SIZE, -BODY_SIZE, Color(255, 255, 255, 255))
    if self.blinking and self.blinkFrame > 1 then
        render.SetMaterial(blink_materials[self.blinkFrame])
    else
        render.SetMaterial(unknow_eye)
    end
    render.DrawQuadEasy(eyePos, self.frontEyeDir, -HEAD_WIDTH, -HEAD_HEIGHT, Color(255, 255, 255, 255))
    render.SetMaterial(unknow_eye_back)
    render.DrawQuadEasy(eyePos, self.backEyeDir, -HEAD_WIDTH, -HEAD_HEIGHT, Color(255, 255, 255, 255))
    local targetX, targetY
    local isWatchingRagdoll = self:GetNWBool("IsWatchingRagdoll", false)
    if isWatchingRagdoll then
        local ragdollPos = self:GetNWVector("RagdollPosition", pos)
        local ragdollDir = (ragdollPos - (pos + Vector(0, 0, 65))):GetNormalized()
        targetX, targetY = self:GetPupilOffset(ragdollDir, self.frontEyeDir)
    elseif isWalking then
        if IsValid(ply) and self:CanISeePlayer(ply) then
            local dist = pos:Distance(ply:GetPos())
            if dist < PUPIL_TRACK_DISTANCE then
                targetX, targetY = self:GetPupilOffset(self.originalTargetDir, self.frontEyeDir)
            else
                local t = CurTime() * 1.2
                targetX = math.sin(t) * 3
                targetY = math.cos(t * 0.7) * 2
            end
        else
            local t = CurTime() * 0.8
            targetX = math.sin(t * 1.3) * 2
            targetY = math.cos(t * 0.9) * 1.5
        end
    else
        local horrorState = self:GetNWInt("HorrorState", 1)
        if horrorState >= 2 and horrorState <= 4 then
            if IsValid(ply) then
                local playerDir = (ply:EyePos() - (pos + Vector(0, 0, 65))):GetNormalized()
                targetX, targetY = self:GetPupilOffset(playerDir, self.frontEyeDir)
            else
                targetX, targetY = 0, 0
            end
        elseif eyeState == 3 then
            targetX, targetY = self:GetPupilOffset(self.originalTargetDir, self.frontEyeDir)
        elseif eyeState == 4 then
            targetX, targetY = self:GetLookAroundPupil()
        elseif eyeState == 5 then
            local glanceX, glanceY = self:UpdateCameraGlance()
            if glanceX then
                targetX, targetY = glanceX, glanceY
            else
                targetX, targetY = self:GetPupilOffset(self.originalTargetDir, self.frontEyeDir)
            end
        else
            targetX, targetY = self:GetPupilOffset(self.originalTargetDir, self.frontEyeDir)
        end
    end
    targetX = targetX or 0
    targetY = targetY or 0
    self.pupilX = Lerp(0.15, self.pupilX, targetX)
    self.pupilY = Lerp(0.15, self.pupilY, targetY)
    local frontAng = self.frontEyeDir:Angle()
    local frontPupil = eyePos + (frontAng:Right() * self.pupilX) + (frontAng:Up() * self.pupilY)
    local backAng = self.backEyeDir:Angle()
    local backPupil = eyePos + (backAng:Right() * -self.pupilX) + (backAng:Up() * self.pupilY)
    render.ClearStencil()
    render.SetStencilEnable(true)
    render.SetStencilWriteMask(255)
    render.SetStencilTestMask(255)
    render.SetStencilReferenceValue(1)
    render.SetStencilCompareFunction(STENCIL_ALWAYS)
    render.SetStencilPassOperation(STENCIL_REPLACE)
    render.SetStencilFailOperation(STENCIL_KEEP)
    render.SetStencilZFailOperation(STENCIL_KEEP)
    render.OverrideColorWriteEnable(true, false)
    DrawEyeMask(eyePos + self.frontEyeDir * 0.3, self.frontEyeDir, MASK_W, MASK_H)
    render.OverrideColorWriteEnable(false)
    render.SetStencilCompareFunction(STENCIL_EQUAL)
    render.SetMaterial(unknow_pupil)
    render.DrawQuadEasy(frontPupil + self.frontEyeDir * 0.5, self.frontEyeDir, -PUPIL_WIDTH, -PUPIL_HEIGHT, Color(255, 255, 255, 255))
    render.ClearStencil()
    render.SetStencilCompareFunction(STENCIL_ALWAYS)
    render.SetStencilPassOperation(STENCIL_REPLACE)
    render.OverrideColorWriteEnable(true, false)
    DrawEyeMask(eyePos + self.backEyeDir * 0.3, self.backEyeDir, MASK_W, MASK_H)
    render.OverrideColorWriteEnable(false)
    render.SetStencilCompareFunction(STENCIL_EQUAL)
    render.SetMaterial(unknow_pupil)
    render.DrawQuadEasy(backPupil + self.backEyeDir * 0.5, self.backEyeDir, -PUPIL_WIDTH, -PUPIL_HEIGHT, Color(255, 255, 255, 255))
    render.SetStencilEnable(false)
    local tr = util.TraceLine({
        start = pos + Vector(0, 0, 10),
        endpos = pos + Vector(0, 0, -10),
        filter = self,
        mask = MASK_SOLID
    })
    if tr.Hit then
        render.SetMaterial(portal_material)
        if not self.touchGround then
            self.spawnTime = CurTime()
            self.portalScale = 0.1
        end
        self.touchGround = true
        local t = CurTime() - self.spawnTime
        if t < 0.3 then
            self.portalScale = Lerp(t / 0.3, 0.1, 1)
        else
            self.portalScale = 1
        end
        local size = 130 * self.portalScale
        local portalPos = tr.HitPos + (tr.HitNormal * 1)
        local ang = tr.HitNormal:Angle()
        ang:RotateAroundAxis(tr.HitNormal, math.random(0, 360))
        render.DrawQuadEasy(portalPos, tr.HitNormal, size, size, Color(0, 0, 0, 150), ang.y)
    else
        self.touchGround = false
    end
end
function ENT:RenderOverride()
    self:SetRenderBounds(Vector(-1024, -1024, -512), Vector(1024, 1024, 512))
    self:SetRenderClipPlaneEnabled(false)
    self:DrawEntity()
end
hook.Add("PostDrawTranslucentRenderables", "UNKNOW_Render", function(bDrawingDepth, bDrawingSkybox)
    if bDrawingSkybox then return end
    for _, ent in ipairs(ents.FindByClass("UNKNOW")) do
        if IsValid(ent) and ent.DrawEntity then
            ent:DrawEntity()
        end
    end
end)
local curiousFogDensity = 0
local curiousDesaturation = 0
local curiousFogColor = Color(0, 0, 0)
local STATE_CURIOUS = 2
hook.Add("RenderScreenspaceEffects", "UNKNOW_CuriousEffects", function()
    local ply = LocalPlayer()
    if not IsValid(ply) then return end
    local closestEntity = nil
    local closestDist = math.huge
    local isCurious = false
    for _, ent in ipairs(ents.FindByClass("UNKNOW")) do
        if IsValid(ent) then
            local state = ent:GetNWInt("HorrorState", 1)
            local dist = ply:GetPos():Distance(ent:GetPos())
            if state == STATE_CURIOUS and dist < closestDist then
                closestDist = dist
                closestEntity = ent
                isCurious = true
            end
        end
    end
    local targetFog = 0
    local targetDesat = 0
    if isCurious and closestDist < 800 then
        local intensity = 1 - math.Clamp((closestDist - 100) / 700, 0, 1)
        targetFog = intensity * 0.8
        targetDesat = intensity * 0.9
    end
    local lerpSpeed = (targetFog > curiousFogDensity) and 2 or 5
    curiousFogDensity = Lerp(FrameTime() * lerpSpeed, curiousFogDensity, targetFog)
    curiousDesaturation = Lerp(FrameTime() * lerpSpeed, curiousDesaturation, targetDesat)
    if curiousFogDensity < 0.01 then curiousFogDensity = 0 end
    if curiousDesaturation < 0.01 then curiousDesaturation = 0 end
    if curiousDesaturation > 0.01 then
        DrawColorModify({
            ["$pp_colour_addr"] = 0,
            ["$pp_colour_addg"] = 0,
            ["$pp_colour_addb"] = 0,
            ["$pp_colour_brightness"] = -0.02 * curiousDesaturation,
            ["$pp_colour_contrast"] = 1 - (0.2 * curiousDesaturation),
            ["$pp_colour_colour"] = 1 - curiousDesaturation,
            ["$pp_colour_mulr"] = 0,
            ["$pp_colour_mulg"] = 0,
            ["$pp_colour_mulb"] = 0,
        })
    end
end)
hook.Add("SetupWorldFog", "UNKNOW_CuriousFog", function()
    if curiousFogDensity < 0.01 then return end
    local ply = LocalPlayer()
    if not IsValid(ply) then return end
    local fogStart = Lerp(curiousFogDensity, 2000, 50)
    local fogEnd = Lerp(curiousFogDensity, 4000, 300)
    render.FogMode(MATERIAL_FOG_LINEAR)
    render.FogStart(fogStart)
    render.FogEnd(fogEnd)
    render.FogColor(5, 5, 8)
    render.FogMaxDensity(curiousFogDensity)
    return true
end)
hook.Add("SetupSkyboxFog", "UNKNOW_CuriousSkyFog", function(scale)
    if curiousFogDensity < 0.01 then return end
    local fogStart = Lerp(curiousFogDensity, 2000, 50) * scale
    local fogEnd = Lerp(curiousFogDensity, 4000, 300) * scale
    render.FogMode(MATERIAL_FOG_LINEAR)
    render.FogStart(fogStart)
    render.FogEnd(fogEnd)
    render.FogColor(5, 5, 8)
    render.FogMaxDensity(curiousFogDensity)
    return true
end)
