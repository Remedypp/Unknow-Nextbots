AddCSLuaFile("cl_init.lua")
AddCSLuaFile("shared.lua")
AddCSLuaFile("render/render.lua")
AddCSLuaFile("effects/menu_scare.lua")
include("shared.lua")
include("modules/learning.lua")
include("modules/behavior.lua")
include("modules/combat.lua")
include("modules/sounds.lua")
include("modules/stalking.lua")
include("modules/illusions.lua")
local DETECTION_RANGE = 2000
local CAMERA_RANGE = 1500
local CAMERA_FOV = 60
local STATE_LOOKING_AT_PLAYER = 1
local STATE_WAITING = 2
local STATE_LOOKING_AROUND = 3
local STATE_OBSERVING_STILL = 4
local STATE_LOOKING_AT_CAMERA = 5
function ENT:Initialize()
    self:SetModel("models/props_junk/PopCan01a.mdl")
    self:DrawShadow(false)
    self:SetSolid(SOLID_BBOX)
    self:SetCollisionGroup(COLLISION_GROUP_PASSABLE_DOOR)
    self:PhysicsInitBox(Vector(-4, -4, 0), Vector(4, 4, 64))
    self:SetCollisionBounds(Vector(-1, -1, 0), Vector(1, 1, 1))
    self.loco:SetStepHeight(40)
    self.loco:SetJumpHeight(200)
    self.loco:SetDeathDropHeight(500)
    self.loco:SetDesiredSpeed(300)
    self.loco:SetAcceleration(500)
    self:InitializeBehaviorSystem()
    self:InitializeLearningSystem()
    self:InitializeCombatSystem()
    self:InitializeSoundSystem()
    self:InitializeStalkingSystem()
    self:InitializeIllusionSystem()
    self:InitializeBoneDistortionSystem()
    self.eyeState = STATE_LOOKING_AROUND
    self.stateStartTime = CurTime()
    self.lookDirection = self:GetForward()
    self.spottedCamera = nil
    self.spottedCameraPos = nil
    self.cameraSpotTime = 0
    self.knownCameraPos = nil
    self.targetYaw = 0
    self.targetPitch = 0
    self.nextLookTime = 0
    self.lookAroundStartTime = CurTime()
    self:SetNWVector("LookDirection", self.lookDirection)
    self:SetNWInt("EyeState", self.eyeState)
end
function ENT:CanSeePlayer(ply)
    if not IsValid(ply) or not ply:Alive() then return false end
    local selfPos = self:GetPos() + Vector(0, 0, 65)
    local targetPos = ply:EyePos()
    local trace = util.TraceLine({
        start = selfPos,
        endpos = targetPos,
        filter = {ply, self},
        mask = MASK_SHOT
    })
    return not trace.Hit
end
function ENT:FindVisiblePlayer()
    for _, ply in ipairs(player.GetAll()) do
        if self:CanSeePlayer(ply) then
            return ply
        end
    end
    return nil
end
function ENT:CanISeeCamera(camEnt)
    if not IsValid(camEnt) then return false end
    local distanceToEntity = self:GetPos():Distance(camEnt:GetPos())
    if distanceToEntity > CAMERA_RANGE then return false end
    local selfPos = self:GetPos() + Vector(0, 0, 65)
    local entityPos = camEnt:GetPos()
    local aimVector = (entityPos - selfPos):GetNormalized()
    local dotProduct = self.lookDirection:Dot(aimVector)
    local fovCos = math.cos(math.rad(CAMERA_FOV / 2))
    if dotProduct >= fovCos then
        local trace = util.TraceLine({
            start = selfPos,
            endpos = entityPos,
            filter = {camEnt, self},
            mask = MASK_SHOT
        })
        return not trace.Hit
    end
    return false
end
function ENT:FindCameraInView()
    for _, ent in ipairs(ents.GetAll()) do
        if IsValid(ent) then
            local class = ent:GetClass()
            if string.find(class, "camera") or string.find(class, "cctv") then
                if self:CanISeeCamera(ent) then
                    return ent
                end
            end
        end
    end
    return nil
end
function ENT:FindCameraInRange()
    local selfPos = self:GetPos() + Vector(0, 0, 65)
    for _, ent in ipairs(ents.GetAll()) do
        if IsValid(ent) then
            local class = ent:GetClass()
            if string.find(class, "camera") or string.find(class, "cctv") then
                if ent:GetPos():Distance(selfPos) < CAMERA_RANGE then
                    return ent
                end
            end
        end
    end
    return nil
end
function ENT:UpdateLookDirection()
    local curTime = CurTime()
    local selfPos = self:GetPos() + Vector(0, 0, 65)
    local target = self:GetEnemy()
    if self.chasing and IsValid(target) then
        self.lookDirection = (target:EyePos() - selfPos):GetNormalized()
        self.eyeState = STATE_LOOKING_AT_PLAYER
        self:SetNWVector("LookDirection", self.lookDirection)
        self:SetNWInt("EyeState", self.eyeState)
        return
    end
    if self.spottedCameraPos then
        self.lookDirection = (self.spottedCameraPos - selfPos):GetNormalized()
        self.eyeState = STATE_LOOKING_AT_CAMERA
        self:SetNWVector("LookDirection", self.lookDirection)
        self:SetNWInt("EyeState", self.eyeState)
        return
    end
    if self.stalking and IsValid(target) then
        self.lookDirection = (target:EyePos() - selfPos):GetNormalized()
        self.eyeState = STATE_LOOKING_AT_PLAYER
        self:SetNWVector("LookDirection", self.lookDirection)
        self:SetNWInt("EyeState", self.eyeState)
        return
    end
    if self.walking then
        self:UpdateRandomLook()
        self.eyeState = STATE_LOOKING_AROUND
        self:SetNWVector("LookDirection", self.lookDirection)
        self:SetNWInt("EyeState", self.eyeState)
        return
    end
    self.lookDirection = self:GetForward()
    self.eyeState = STATE_OBSERVING_STILL
    self:SetNWVector("LookDirection", self.lookDirection)
    self:SetNWInt("EyeState", self.eyeState)
end
function ENT:UpdateRandomLook()
    local curTime = CurTime()
    local selfPos = self:GetPos() + Vector(0, 0, 65)
    if curTime > self.nextLookTime then
        if self.knownCameraPos and math.random(1, 100) <= 30 then
            local dirToCamera = (self.knownCameraPos - selfPos):GetNormalized()
            local camAng = dirToCamera:Angle()
            local offsetYaw = math.random(-30, 30)
            local offsetPitch = math.random(-15, 15)
            local newAng = Angle(camAng.p + offsetPitch, camAng.y + offsetYaw, 0)
            self.lookDirection = newAng:Forward()
            self.nextLookTime = curTime + math.Rand(0.8, 2.5)
            return self.lookDirection
        end
        self.targetYaw = math.random(-180, 180)
        local pitchRoll = math.random()
        if pitchRoll < 0.2 then
            self.targetPitch = math.random(-25, -5)
        elseif pitchRoll < 0.6 then
            self.targetPitch = math.random(-5, 10)
        else
            self.targetPitch = math.random(10, 30)
        end
        self.nextLookTime = curTime + math.Rand(0.8, 2.5)
    end
    local baseAng = self:GetAngles()
    local ang = Angle(self.targetPitch, baseAng.y + self.targetYaw, 0)
    self.lookDirection = ang:Forward()
    return self.lookDirection
end
function ENT:UpdateCameraDetection()
    local curTime = CurTime()
    if not self.knownCameraPos then
        local cam = self:FindCameraInRange()
        if IsValid(cam) then
            self.knownCameraPos = cam:GetPos()
        end
    end
    if not self.spottedCamera then
        local cam = self:FindCameraInView()
        if IsValid(cam) then
            self.spottedCamera = cam
            self.spottedCameraPos = cam:GetPos()
            self.cameraSpotTime = curTime
        end
    end
    if IsValid(self.spottedCamera) then
        self.spottedCameraPos = self.spottedCamera:GetPos()
    else
        self.spottedCamera = nil
        self.spottedCameraPos = nil
    end
end
function ENT:Think()
    self:UpdateLookDirection()
    self:UpdateCameraDetection()
    self:UpdateLearningSystem()
    if self.UpdateSounds then
        self:UpdateSounds()
    end
    if self.UpdateStalking then
        self:UpdateStalking()
    end
    if self.UpdateIllusions then
        self:UpdateIllusions()
    end
    if self.CheckBoneDistortion then
        self:CheckBoneDistortion()
    end
    self:NextThink(CurTime() + 0.05)
    return true
end
function ENT:OnTakeDamage(dmginfo)
    dmginfo:SetDamage(0)
    return 0
end
function ENT:PhysgunPickup(ply, ent)
    return false
end
function ENT:GravGunPickupAllowed(ply)
    return false
end
function ENT:UnstickFromCeiling()
    if self:IsOnGround() then return end
    local myPos = self:GetPos()
    local trace = util.TraceLine({
        start = myPos,
        endpos = myPos + Vector(0, 0, 72),
        filter = self
    })
    if trace.Hit and trace.Fraction > 0.5 then
        local unstuckPos = myPos + trace.HitNormal * (72 * (1 - trace.Fraction))
        self:SetPos(unstuckPos)
    end
end
function ENT:UnstickByMoving()
    if math.random() < 0.5 then
        local randomDirection = Vector(math.random(-1, 1), math.random(-1, 1), 0):GetNormalized()
        local unstuckPos = self:GetPos() + randomDirection * math.random(50, 100)
        self:SetPos(unstuckPos)
        self.loco:ClearStuck()
    end
end
function ENT:VectorDistance(v1, v2)
    return v1:Distance(v2)
end
concommand.Add("unknow_dormant", function(ply)
    for _, ent in ipairs(ents.FindByClass("unknow_fake")) do
        ent:SetEnemy(ply)
        ent:SetHorrorState(ent.STATE_DORMANT)
    end
end)
concommand.Add("unknow_curious", function(ply)
    for _, ent in ipairs(ents.FindByClass("unknow_fake")) do
        ent:SetEnemy(ply)
        ent:SetHorrorState(ent.STATE_CURIOUS)
    end
end)
concommand.Add("unknow_stalk", function(ply)
    for _, ent in ipairs(ents.FindByClass("unknow_fake")) do
        ent:SetEnemy(ply)
        ent:SetHorrorState(ent.STATE_STALKING)
    end
end)
concommand.Add("unknow_hunt", function(ply)
    for _, ent in ipairs(ents.FindByClass("unknow_fake")) do
        ent:SetEnemy(ply)
        ent:SetHorrorState(ent.STATE_HUNTING)
    end
end)
concommand.Add("unknow_retreat", function(ply)
    for _, ent in ipairs(ents.FindByClass("unknow_fake")) do
        ent:SetHorrorState(ent.STATE_RETREAT)
    end
end)
concommand.Add("unknow_watchragdoll", function(ply)
    for _, ent in ipairs(ents.FindByClass("unknow_fake")) do
        ent.shouldWatchRagdoll = true
        ent.shouldTeleportAfterKill = false
        ent.lastKillPos = ply:GetPos()
    end
end)
concommand.Add("unknow_tpme", function(ply)
    for _, ent in ipairs(ents.FindByClass("unknow_fake")) do
        ent:SetPos(ply:GetPos() + ply:GetForward() * 150)
    end
end)
concommand.Add("unknow_interest", function(ply, cmd, args)
    local value = tonumber(args[1]) or 50
    for _, ent in ipairs(ents.FindByClass("unknow_fake")) do
        ent.interest = value
    end
end)
concommand.Add("unknow_status", function(ply)
    for _, ent in ipairs(ents.FindByClass("unknow_fake")) do
    end
end)
