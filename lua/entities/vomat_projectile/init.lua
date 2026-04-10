AddCSLuaFile("shared.lua")
AddCSLuaFile("cl_init.lua")
include("shared.lua")
util.AddNetworkString("VomatBlobHit")
util.AddNetworkString("VomatImpactFX")
function ENT:Initialize()
    self:SetModel("models/props_junk/watermelon01.mdl")
    self:SetMoveType(MOVETYPE_VPHYSICS)
    self:SetSolid(SOLID_VPHYSICS)
    self:SetCollisionGroup(COLLISION_GROUP_PROJECTILE)
    self:SetCustomCollisionCheck(true)
    self:SetTrigger(true)
    self:DrawShadow(false)
    self:SetNoDraw(true)
    self:SetUnFreezable(true)
    self:AddEFlags(EFL_NO_PHYSCANNON_INTERACTION)
    self:PhysicsInit(SOLID_VPHYSICS)
    self:SetCollisionBounds(Vector(-5, -5, 0), Vector(5, 5, 10))
    local phys = self:GetPhysicsObject()
    if IsValid(phys) then
        phys:SetMass(1)
        phys:EnableGravity(true)
        phys:EnableCollisions(true)
        phys:EnableMotion(true)
        phys:Wake()
    end
    self.TargetPlayer = nil
    self.StartPos = self:GetPos()
    self.HitTarget = false
    self.LastHitTime = 0
    self.IsAggressiveThrow = false
    self.IsWeakThrow = false
    self.MoveToPlayer = false
    self.OwnerVomat = nil
end
function ENT:Think()
    local target = self.TargetPlayer
    if not IsValid(target) or not target:Alive() then
        self:StopSounds()
        self:Remove()
        return
    end
    if self.MoveToPlayer then
        local targetPos = target:GetPos() + target:OBBCenter()
        local direction = (targetPos - self:GetPos()):GetNormalized()
        local phys = self:GetPhysicsObject()
        if IsValid(phys) then
            local chaseSpeed = self.IsAggressiveThrow and 400 or (self.IsWeakThrow and 200 or 300)
            phys:SetVelocity(direction * chaseSpeed)
            phys:Wake()
            phys:EnableMotion(true)
        end
    end
    if self:GetPos():Distance(target:GetPos()) <= 50 then
        self:HitEntity(target)
    end
    self:NextThink(CurTime())
    return true
end
function ENT:Touch(ent)
    if self.HitTarget then return end
    if not IsValid(ent) then return end
    if ent:IsPlayer() and (not ent:Alive() or ent == self:GetOwner()) then return end
    if ent:IsPlayer() or ent:IsNPC() then
        self:HitEntity(ent)
    end
end
function ENT:PhysicsCollide(data, phys)
    if self.HitTarget then return end
    local hit = data.HitEntity
    if not IsValid(hit) then return end
    if hit:IsPlayer() and (not hit:Alive() or hit == self:GetOwner()) then return end
    if hit:IsPlayer() or hit:IsNPC() then
        self:HitEntity(hit)
    end
end
function ENT:HitEntity(ent)
    if self.HitTarget then return end
    self.HitTarget = true
    if ent:IsPlayer() then
        local hitPos = self:GetPos()
        local boneID = ent:GetHitBoxBone(0, 0) or 0
        local closestBone = 0
        local closestDist = math.huge
        for b = 0, ent:GetBoneCount() - 1 do
            local bonePos = ent:GetBonePosition(b)
            if bonePos then
                local d = bonePos:DistToSqr(hitPos)
                if d < closestDist then
                    closestDist = d
                    closestBone = b
                end
            end
        end
        net.Start("VomatBlobHit")
            net.WriteEntity(ent)
            net.WriteUInt(closestBone, 8)
            net.WriteFloat(CurTime())
        net.Broadcast()
    end
    net.Start("VomatImpactFX")
        net.WriteVector(self:GetPos())
        net.WriteBool(self.IsAggressiveThrow or false)
        net.WriteBool(self.IsWeakThrow or false)
    net.Broadcast()
    local volume = self.IsAggressiveThrow and 85 or (self.IsWeakThrow and 65 or 75)
    local pitch = self.IsAggressiveThrow and math.random(70, 80) or
                  (self.IsWeakThrow and math.random(110, 120) or math.random(90, 110))
    self:EmitSound("physics/flesh/flesh_bloody_break.wav", volume, pitch)
    self:EmitSound("physics/flesh/flesh_squishy_impact_hard" .. math.random(1, 4) .. ".wav", volume, pitch)
    if ent:IsPlayer() then
        local baseDamage = self.IsAggressiveThrow and 20 or (self.IsWeakThrow and 10 or 15)
        local dmg = DamageInfo()
        dmg:SetDamage(baseDamage)
        dmg:SetDamageType(DMG_ACID)
        dmg:SetAttacker(IsValid(self:GetOwner()) and self:GetOwner() or self)
        dmg:SetInflictor(self)
        ent:TakeDamageInfo(dmg)
        ent:ScreenFade(SCREENFADE.IN, Color(255, 0, 0, 100), 0.5, 0.1)
        local steamID = ent:SteamID()
        local hitUID = string.format("%.4f", CurTime()) .. "_" .. math.random(1000, 9999)
        ent.VomatTimers = ent.VomatTimers or {}
        local ownerEnt = IsValid(self:GetOwner()) and self:GetOwner() or self.OwnerVomat
        for i = 1, 4 do
            local tName = "vomat_dot_" .. steamID .. "_" .. hitUID .. "_" .. i
            ent.VomatTimers[tName] = ownerEnt
            timer.Create(tName, math.random(i, i * 7), 1, function()
                if IsValid(ent) and ent:Alive() then
                    local dotDmg = math.random(3, 8)
                    ent:TakeDamage(dotDmg)
                    local dotFx = EffectData()
                    dotFx:SetOrigin(ent:GetPos() + Vector(0, 0, 30))
                    dotFx:SetScale(2)
                    util.Effect("bloodspray", dotFx)
                    util.Effect("blood_impact_red_01", dotFx)
                    ent:EmitSound("physics/flesh/flesh_bloody_impact_hard" .. math.random(1, 4) .. ".wav", 75, math.random(90, 110))
                end
            end)
        end
    elseif ent:IsNPC() then
        local dmg = DamageInfo()
        dmg:SetDamage(25)
        dmg:SetDamageType(DMG_ACID)
        dmg:SetAttacker(IsValid(self:GetOwner()) and self:GetOwner() or self)
        dmg:SetInflictor(self)
        ent:TakeDamageInfo(dmg)
    end
    self:StopSounds()
    self:Remove()
end
function ENT:StopSounds()
    if self.ChaseSound then self.ChaseSound:Stop() end
end
function ENT:OnRemove()
    if not self.HitTarget and IsValid(self.OwnerVomat) then
        self.OwnerVomat.MissedShots = (self.OwnerVomat.MissedShots or 0) + 1
    end
    self:StopSounds()
end
hook.Add("PhysgunPickup", "PreventVomatProjectilePickup", function(ply, ent)
    if ent:GetClass() == "vomat_projectile" then return false end
end)
hook.Add("GravGunPickupAllowed", "PreventVomatProjectileGravGun", function(ply, ent)
    if ent:GetClass() == "vomat_projectile" then return false end
end)
util.AddNetworkString("VomatClearBlobs")
local function ClearPlayerBlobs(ply)
    for _, proj in ipairs(ents.FindByClass("vomat_projectile")) do
        if IsValid(proj) and proj.TargetPlayer == ply then
            proj:StopSounds()
            proj:Remove()
        end
    end
    if ply.VomatTimers then
        for timerName, _ in pairs(ply.VomatTimers) do
            timer.Remove(timerName)
        end
        ply.VomatTimers = {}
    end
    net.Start("VomatClearBlobs")
        net.WriteEntity(ply)
    net.Broadcast()
end
hook.Add("PlayerDeath", "VomatClearBlobsOnDeath", function(ply)
    ClearPlayerBlobs(ply)
end)
hook.Add("PlayerSpawn", "VomatClearBlobsOnSpawn", function(ply)
    ClearPlayerBlobs(ply)
end)
hook.Add("ShouldCollide", "VomatProjectileCollisions", function(ent1, ent2)
    if ent1:GetClass() == "vomat_projectile" and ent2:GetClass() == "vomat_projectile" then
        return false
    end
end)
