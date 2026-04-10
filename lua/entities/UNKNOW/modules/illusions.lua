local ENT = ENT
function ENT:InitializeIllusionSystem()
    self.illusionData = {
        lastIllusionTime = 0,
        illusionCooldown = 15,
        maxIllusions = 3,
        illusionDuration = 3,
        activeIllusions = {},
        spawnDistanceMin = 400,
        spawnDistanceMax = 800,
        angleVariation = 45
    }
end
function ENT:CreateIllusions()
    if not self.illusionData then
        self:InitializeIllusionSystem()
    end
    if CurTime() - self.illusionData.lastIllusionTime < self.illusionData.illusionCooldown then
        return false
    end
    self:CleanupIllusions()
    local enemy = self:GetEnemy()
    if not IsValid(enemy) then return false end
    local illusionCount = math.random(1, self.illusionData.maxIllusions)
    local created = 0
    for i = 1, illusionCount do
        local illusion = self:CreateFakeAppearance(enemy)
        if IsValid(illusion) then
            table.insert(self.illusionData.activeIllusions, {
                ent = illusion,
                expireTime = CurTime() + self.illusionData.illusionDuration
            })
            created = created + 1
        end
    end
    if created > 0 then
        self.illusionData.lastIllusionTime = CurTime()
        return true
    end
    return false
end
function ENT:CreateFakeAppearance(target)
    if not IsValid(self) or not IsValid(target) then return nil end
    local fake = ents.Create("UNKNOW")
    if not IsValid(fake) then return nil end
    local playerEyePos = target:EyePos()
    local playerViewAngle = target:EyeAngles()
    local playerForward = playerViewAngle:Forward()
    local spawnDistance = math.random(
        self.illusionData.spawnDistanceMin,
        self.illusionData.spawnDistanceMax
    )
    local randomAngle = math.random(
        -self.illusionData.angleVariation,
        self.illusionData.angleVariation
    )
    local rotatedForward = playerForward:Angle()
    rotatedForward.y = rotatedForward.y + randomAngle
    rotatedForward = rotatedForward:Forward()
    local initialSpawnPos = playerEyePos + rotatedForward * spawnDistance
    local groundTrace = util.TraceLine({
        start = initialSpawnPos + Vector(0, 0, 100),
        endpos = initialSpawnPos - Vector(0, 0, 50),
        mask = MASK_SOLID_BRUSHONLY
    })
    if not groundTrace.Hit then
        fake:Remove()
        return nil
    end
    local finalPos = groundTrace.HitPos + Vector(0, 0, 1)
    local visibilityTrace = util.TraceLine({
        start = playerEyePos,
        endpos = finalPos + Vector(0, 0, 64),
        mask = MASK_SOLID_BRUSHONLY
    })
    if visibilityTrace.Hit then
        fake:Remove()
        return nil
    end
    local toFake = (finalPos - playerEyePos):GetNormalized()
    local dotProduct = playerForward:Dot(toFake)
    if dotProduct < math.cos(math.rad(90)) then
        fake:Remove()
        return nil
    end
    fake:SetPos(finalPos)
    local angleToPlayer = (target:GetPos() - finalPos):Angle()
    fake:SetAngles(angleToPlayer)
    fake:SetCollisionGroup(COLLISION_GROUP_NONE)
    fake:SetSolid(SOLID_NONE)
    fake.TargetPlayer = target
    fake.IsIllusion = true
    fake.CreatorEntity = self
    if SERVER then
        fake:SetPreventTransmit(target, false)
        for _, ply in pairs(player.GetAll()) do
            if ply ~= target then
                fake:SetPreventTransmit(ply, true)
            end
        end
    end
    fake:Spawn()
    local phys = fake:GetPhysicsObject()
    if IsValid(phys) then
        phys:EnableMotion(false)
    end
    local duration = self.illusionData.illusionDuration + math.random() * 2
    timer.Simple(duration, function()
        if IsValid(fake) then
            fake:Remove()
        end
    end)
    return fake
end
function ENT:CleanupIllusions()
    if not self.illusionData then return end
    local ct = CurTime()
    for i = #self.illusionData.activeIllusions, 1, -1 do
        local illusion = self.illusionData.activeIllusions[i]
        if ct > illusion.expireTime or not IsValid(illusion.ent) then
            if IsValid(illusion.ent) then
                illusion.ent:Remove()
            end
            table.remove(self.illusionData.activeIllusions, i)
        end
    end
end
function ENT:RemoveAllIllusions()
    if not self.illusionData then return end
    for _, illusion in ipairs(self.illusionData.activeIllusions) do
        if IsValid(illusion.ent) then
            illusion.ent:Remove()
        end
    end
    self.illusionData.activeIllusions = {}
end
function ENT:GetActiveIllusionCount()
    if not self.illusionData then return 0 end
    local count = 0
    for _, illusion in ipairs(self.illusionData.activeIllusions) do
        if IsValid(illusion.ent) then
            count = count + 1
        end
    end
    return count
end
function ENT:UpdateIllusions()
    if not self.illusionData then return end
    self:CleanupIllusions()
    for _, illusion in ipairs(self.illusionData.activeIllusions) do
        if IsValid(illusion.ent) and IsValid(illusion.ent.TargetPlayer) then
            local dirToPlayer = (illusion.ent.TargetPlayer:GetPos() - illusion.ent:GetPos()):GetNormalized()
            local angleToPlayer = dirToPlayer:Angle()
            illusion.ent:SetAngles(angleToPlayer)
        end
    end
end
function ENT:ShouldCreateIllusion()
    if not self.illusionData then return false end
    if CurTime() - self.illusionData.lastIllusionTime < self.illusionData.illusionCooldown then
        return false
    end
    local chance = 5
    if self.stalking then
        chance = 15
    elseif self.chasing then
        chance = 10
    end
    return math.random(1, 100) <= chance
end
