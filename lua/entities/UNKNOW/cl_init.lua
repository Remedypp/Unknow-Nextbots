include("shared.lua")
include("render/render.lua")
include("effects/menu_scare.lua")
include("modules/sounds.lua")
function ENT:Initialize()
    self:DrawShadow(false)
    self:SetNoDraw(true)
    self:SetRenderBounds(Vector(-1024, -1024, -512), Vector(1024, 1024, 512))
    self:SetRenderClipPlaneEnabled(false)
    self:DestroyShadow()
    self.frontEyeDir = self:GetForward()
    self.backEyeDir = -self:GetForward()
    self.bodyFrontDir = self:GetForward()
    self.bodyBackDir = -self:GetForward()
    self.pupilX = 0
    self.pupilY = 0
    self.blinking = false
    self.blinkFrame = 1
    self.blinkDir = 1
    self.blinkHold = false
    self.lastBlink = 0
    self.nextBlink = CurTime() + math.random(3, 8)
    self.portalScale = 0.1
    self.spawnTime = CurTime()
    self.touchGround = false
    self.pupilTargetX = 0
    self.pupilTargetY = 0
    self.nextPupilTime = 0
    self.isGlancing = false
    self.glanceX = 0
    self.glanceY = 0
    self.glanceStartTime = 0
    self.glanceDuration = 0
    self.nextGlanceTime = CurTime() + math.random(8, 15)
end
local boneDistortionActive = false
local blackEffectActive = false
local jitterEnabled = false
local jitterIntensity = 0
local jitterStartTime = 0
local originalBonePositions = {}
local originalBoneAngles = {}
local targetBonePositions = {}
local targetBoneAngles = {}
local distortionSounds = {}
local playerRagdolls = {}
local originalPlayerColor = nil
local function CreateBlackMaterial()
    return Material("models/debug/debugwhite")
end
local function ApplyBlackEffect(ply)
    if not IsValid(ply) then return end
    local blackMat = CreateBlackMaterial()
    hook.Add("PrePlayerDraw", "UNKNOW_BlackEffect", function(player)
        if player == LocalPlayer() and blackEffectActive then
            render.SetColorModulation(0, 0, 0)
            render.SetBlend(1)
            player:SetMaterial(blackMat:GetName())
            player:SetColor(Color(0, 0, 0, 255))
            player:SetRenderMode(RENDERMODE_TRANSALPHA)
        end
    end)
    hook.Add("PostPlayerDraw", "UNKNOW_BlackEffect", function(player)
        if player == LocalPlayer() and blackEffectActive then
            render.SetColorModulation(1, 1, 1)
        end
    end)
end
local function RemoveBlackEffectHooks()
    hook.Remove("PrePlayerDraw", "UNKNOW_BlackEffect")
    hook.Remove("PostPlayerDraw", "UNKNOW_BlackEffect")
    local ply = LocalPlayer()
    if IsValid(ply) then
        ply:SetMaterial("")
        if originalPlayerColor then
            ply:SetColor(originalPlayerColor)
        else
            ply:SetColor(Color(255, 255, 255, 255))
        end
        ply:SetRenderMode(RENDERMODE_NORMAL)
    end
end
local function RestoreBones()
    local ply = LocalPlayer()
    if not IsValid(ply) then return end
    for i, pos in pairs(originalBonePositions) do
        ply:ManipulateBonePosition(i, pos or Vector(0, 0, 0))
        ply:ManipulateBoneAngles(i, originalBoneAngles[i] or Angle(0, 0, 0))
    end
    originalBonePositions = {}
    originalBoneAngles = {}
    targetBonePositions = {}
    targetBoneAngles = {}
end
local function ApplyBoneDistortion()
    local ply = LocalPlayer()
    if not IsValid(ply) or not boneDistortionActive then return end
    local boneCount = ply:GetBoneCount()
    for i = 0, boneCount - 1 do
        local boneName = ply:GetBoneName(i):lower()
        if not (boneName:find("head") or boneName:find("neck") or boneName:find("spine1")) then
            targetBonePositions[i] = VectorRand() * math.random(2, 5)
            targetBoneAngles[i] = Angle(
                math.random(-40, 40),
                math.random(-40, 40),
                math.random(-40, 40)
            )
        end
    end
    if boneDistortionActive then
        timer.Simple(math.Rand(0.8, 1.5), function()
            if boneDistortionActive then
                ApplyBoneDistortion()
            end
        end)
    end
end
local function ApplyBoneJitter(entity, intensity)
    if not IsValid(entity) then return end
    local boneCount = entity:GetBoneCount()
    for i = 0, boneCount - 1 do
        local boneName = entity:GetBoneName(i):lower()
        if not (boneName:find("head") or boneName:find("neck") or boneName:find("spine")) then
            local scaledIntensity = math.pow(intensity, 1.5) * 0.8
            local boneVariation = (i % 5) * 0.2 + 0.5
            local jitterPos = VectorRand() * scaledIntensity * math.Rand(0.1, 0.6) * boneVariation
            local jitterAng = Angle(
                math.Rand(-0.5, 0.5) * scaledIntensity * 8 * boneVariation,
                math.Rand(-0.5, 0.5) * scaledIntensity * 8 * boneVariation,
                math.Rand(-0.5, 0.5) * scaledIntensity * 8 * boneVariation
            )
            local currentPos = targetBonePositions[i] or Vector(0, 0, 0)
            local currentAng = targetBoneAngles[i] or Angle(0, 0, 0)
            entity:ManipulateBonePosition(i, currentPos + jitterPos)
            entity:ManipulateBoneAngles(i, currentAng + jitterAng)
        end
    end
end
hook.Add("Think", "UNKNOW_BoneDistortion", function()
    local ply = LocalPlayer()
    if not IsValid(ply) then return end
    if boneDistortionActive then
        for i, targetPos in pairs(targetBonePositions) do
            local currentPos = ply:GetManipulateBonePosition(i)
            local newPos = LerpVector(0.1, currentPos, targetPos)
            ply:ManipulateBonePosition(i, newPos)
            if targetBoneAngles[i] then
                local currentAng = ply:GetManipulateBoneAngles(i)
                local newAng = LerpAngle(0.1, currentAng, targetBoneAngles[i])
                ply:ManipulateBoneAngles(i, newAng)
            end
        end
        if jitterEnabled then
            local elapsed = CurTime() - jitterStartTime
            jitterIntensity = math.Clamp(elapsed / 10, 0, 1)
            ApplyBoneJitter(ply, jitterIntensity)
        end
    end
end)
net.Receive("UNKNOW_BoneDistortion", function()
    local activate = net.ReadBool()
    if activate then
        boneDistortionActive = true
        blackEffectActive = true
        jitterEnabled = false
        jitterIntensity = 0
        if table.IsEmpty(originalBonePositions) then
            local ply = LocalPlayer()
            if not IsValid(ply) then return end
            local boneCount = ply:GetBoneCount()
            for i = 0, boneCount - 1 do
                originalBonePositions[i] = ply:GetManipulateBonePosition(i)
                originalBoneAngles[i] = ply:GetManipulateBoneAngles(i)
            end
        end
        ApplyBoneDistortion()
        local ply = LocalPlayer()
        if IsValid(ply) then
            originalPlayerColor = ply:GetColor()
            local headBoneId = ply:LookupBone("ValveBiped.Bip01_Head1")
            if headBoneId then
                ply:ManipulateBoneScale(headBoneId, Vector(1, 1, 1))
            end
            ApplyBlackEffect(ply)
        end
        local sound = UNKNOW_PlayCryingSound()
        if sound then
            table.insert(distortionSounds, sound)
        end
        timer.Simple(5, function()
            if boneDistortionActive then
                jitterEnabled = true
                jitterStartTime = CurTime()
                UNKNOW_PlayBoneBreakSound()
            end
        end)
    else
        boneDistortionActive = false
        blackEffectActive = false
        jitterEnabled = false
        RemoveBlackEffectHooks()
        RestoreBones()
        for _, sound in pairs(distortionSounds) do
            if sound then
                sound:Stop()
            end
        end
        distortionSounds = {}
        local ply = LocalPlayer()
        if IsValid(ply) then
            UNKNOW_StopCryingSound()
        end
    end
end)
