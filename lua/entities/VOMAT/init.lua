AddCSLuaFile("shared.lua")
AddCSLuaFile("cl_init.lua")
AddCSLuaFile("verlet.lua")
include("shared.lua")
function ENT:Initialize()
    self:SetModel("models/props_junk/PopCan01a.mdl")
    self:SetSpawnEffect(false)
    self:DrawShadow(false)
    self:SetCollisionBounds(Vector(-1, -1, 0), Vector(1, 1, 1))
    self:SetSolid(SOLID_BBOX)
    self:SetCollisionGroup(COLLISION_GROUP_PASSABLE_DOOR)
    self:PhysicsInitBox(Vector(-4, -4, 0), Vector(4, 4, 64))
    self:SetHealth(10)
    self:SetMaxHealth(10)
    self.loco:SetStepHeight(40)
    self.loco:SetJumpHeight(200)
    self.loco:SetDeathDropHeight(500)
    self.loco:SetDesiredSpeed(500)
    self.loco:SetAcceleration(300)
    self.target = nil
    self.LoseTargetDist = 9999999
    self.MissedShots = 0
    self.AcidThrowCount = 0
    self.LastStuck = CurTime()
    self.StuckTries = 0
    self.LastAnimationState = false
    self.IsAnimating = false
    self.OneTime = 0
    self.chasing = false
    self.stalking = true
    self.waiting = false
    self.walking = false
    self.stopchasing = false
    self.pathCheck = 0
    self.LastPathingInfraction = 0
    self.path = Path("Chase")
    self.path:SetMinLookAheadDistance(300)
    self.loaded_sounds = {}
    self.loaded_sounds[1] = CreateSound(self, "help.wav")
end
function ENT:SetEnemy(ent)
    self.target = ent
end
function ENT:GetEnemy()
    return self.target
end
function ENT:HaveEnemy()
    local enemy = self:GetEnemy()
    if IsValid(enemy) and enemy:IsPlayer() and enemy:Alive() then
        return true
    end
    return self:FindEnemy()
end
function ENT:FindEnemy()
    local current = self.target
    local closest = current
    local currentDist = math.huge
    if IsValid(current) and current:Alive() then
        currentDist = self:GetRangeTo(current:GetPos())
    else
        closest = nil
    end
    for _, ply in ipairs(player.GetHumans()) do
        if ply:Alive() and ply ~= current then
            local dist = self:GetRangeTo(ply:GetPos())
            if not IsValid(closest) or dist < currentDist - 250 then
                closest = ply
                currentDist = dist
            end
        end
    end
    self:SetEnemy(closest)
    return IsValid(closest)
end
function ENT:CanISeePlayer(entity)
    local playerToCheck = entity or self:GetEnemy()
    if not IsValid(playerToCheck) then return false end
    local selfPos = self:GetPos() + Vector(0, 0, 90)
    local playerPos = playerToCheck:GetPos() + playerToCheck:OBBCenter()
    local aimVector = (playerPos - selfPos):GetNormalized()
    local selfForward = self:GetForward()
    local dotProduct = selfForward:Dot(aimVector)
    local fovCos = math.cos(math.rad(50))
    if dotProduct >= fovCos then
        local tr = util.TraceLine({
            start = selfPos,
            endpos = playerPos,
            filter = {self, playerToCheck},
            mask = bit.bor(MASK_SOLID, MASK_OPAQUE)
        })
        if not tr.Hit or tr.Entity == playerToCheck then
            return true
        end
    end
    return false
end
function ENT:HasLOS(target)
    if not IsValid(target) then return false end
    local tr = util.TraceLine({
        start = self:GetPos() + Vector(0, 0, 64),
        endpos = target:EyePos(),
        filter = {self, target},
        mask = MASK_SHOT
    })
    return not tr.Hit
end
function ENT:OnStuck()
    if self:IsPlayerAbove() then return end
    local curPos = self:GetPos()
    local lastPos = self.LastPos or curPos
    self.LastPos = curPos
    local distance = (curPos - lastPos):Length()
    if distance < 10 then
        self.StuckTries = self.StuckTries + 1
    else
        self.StuckTries = 0
    end
    self.LastStuck = CurTime()
    self:UnstickFromCeiling()
    self:PhaseThroughObjects()
    if self.StuckTries >= 3 then
        self:UnstickByMoving()
    elseif self.StuckTries >= 5 then
        if not self.chasing then
            self:TeleportToRandom()
        end
        self.LastStuck = 0
        self.StuckTries = 0
    else
        self.loco:ClearStuck()
    end
end
function ENT:IsPlayerAbove()
    local target = self.target
    if not IsValid(target) then return false end
    local myPos = self:GetPos()
    local playerPos = target:GetPos()
    return math.abs(playerPos.x - myPos.x) <= 20
       and math.abs(playerPos.y - myPos.y) <= 20
       and math.abs(playerPos.z - myPos.z) <= 50
end
function ENT:UnstickFromCeiling()
    if self:IsOnGround() or self:IsPlayerAbove() then return end
    local myPos = self:GetPos()
    local tr = util.TraceLine({
        start = myPos,
        endpos = myPos + Vector(0, 0, 72),
        filter = self
    })
    if tr.Hit and tr.HitNormal ~= vector_origin and tr.Fraction > 0.5 then
        self:SetPos(myPos + tr.HitNormal * (72 * (1 - tr.Fraction)))
    end
end
function ENT:PhaseThroughObjects()
    if self:IsPlayerAbove() then return end
    local tr = util.TraceLine({
        start = self:GetPos(),
        endpos = self:GetPos() + self:GetForward() * 100,
        filter = function(ent) return ent:IsPlayer() or (ent:IsNPC() and ent:Health() > 0) end,
        mask = MASK_SHOT_HULL
    })
    if tr.Hit then
        self:SetPos(tr.HitPos + self:GetForward() * 10)
    end
end
function ENT:UnstickByMoving()
    if self:IsPlayerAbove() then return end
    if math.random() < 0.5 then
        local randomDir = Vector(math.random(-1, 1), math.random(-1, 1), 0):GetNormalized()
        self:SetPos(self:GetPos() + randomDir * math.random(50, 100))
        self.loco:ClearStuck()
    end
end
function ENT:TeleportToRandom()
    if not IsValid(self) then return end
    local spot_options = {
        pos = IsValid(self:GetEnemy()) and self:GetEnemy():GetPos() or self:GetPos(),
        radius = 10000,
        stepup = 5000,
        stepdown = 5000
    }
    local spot = nil
    self.path = Path("Chase")
    self.path:SetMinLookAheadDistance(300)
    for i = 1, 10 do
        spot = self:FindSpot("random", spot_options)
        if spot and util.IsInWorld(spot) then
            local tr = util.TraceLine({
                start = spot + Vector(0, 0, 64),
                endpos = spot,
                mask = MASK_SOLID_BRUSHONLY
            })
            if not tr.Hit then
                break
            end
        end
        spot = nil
    end
    if IsValid(self) and spot then
        self:SetPos(spot)
        self.waiting = false
        self.walking = false
        self.chasing = false
        self.stalking = false
    end
end
function ENT:Randomm()
    local pos = self:GetPos()
    for i = 0, 360, 45 do
        local rad = math.rad(i)
        local checkDir = Vector(math.cos(rad), math.sin(rad), 0)
        local traceStart = pos + checkDir * 30
        local tr = util.TraceLine({
            start = traceStart + Vector(0, 0, 5),
            endpos = traceStart + Vector(0, 0, -50),
            mask = MASK_SOLID_BRUSHONLY
        })
        if tr.Hit then
            local heightDiff = math.abs(tr.HitPos.z - pos.z)
            local baseHeight = math.Clamp(heightDiff + 10, 20, 65)
            self.loco:SetStepHeight(math.Clamp(baseHeight + math.random(-5, 5), 20, 65))
        end
    end
    self:PhysicsInitBox(Vector(-4, -4, 0), Vector(4, 4, 64))
    self:SetCollisionBounds(Vector(-1, -1, 0), Vector(1, 1, 1))
end
function ENT:RandomCompute()
    local randum = math.random(1, 3)
    if not IsValid(self:GetEnemy()) then return end
    local targetPos = self:GetEnemy():GetPos()
    if randum == 1 then
        self.path:Compute(self, targetPos)
    elseif randum == 2 then
        self.path:Compute(self, targetPos, function(area, fromArea, ladder, elevator, length)
            if not IsValid(fromArea) then return 0 end
            if not self.loco:IsAreaTraversable(area) then return -1 end
            local dist = IsValid(ladder) and ladder:GetLength() or (length > 0 and length) or (area:GetCenter() - fromArea:GetCenter()):GetLength()
            local cost = dist + fromArea:GetCostSoFar()
            local deltaZ = fromArea:ComputeAdjacentConnectionHeightChange(area)
            if deltaZ >= self.loco:GetMaxJumpHeight() then return -1 end
            if deltaZ < -self.loco:GetDeathDropHeight() then return -1 end
            return cost
        end)
    else
        self.path:Compute(self, targetPos)
    end
    self:UnstickFromCeiling()
end
function ENT:ThrowBallAtPlayer()
    if not IsValid(self:GetEnemy()) then return end
    local target = self:GetEnemy()
    local basePos = self:GetPos() + Vector(0, 0, 90)
    local spread = 20
    self.AcidThrowCount = self.AcidThrowCount + 1
    local throwType = math.random(1, 100)
    local isAggressiveThrow = throwType <= 30
    local isWeakThrow = throwType >= 80
    local numBalls = 1
    local shouldChase = false
    local despawnTime = 10
    if self.MissedShots >= 5 and self.MissedShots < 19 then
        shouldChase = true
    elseif self.MissedShots >= 19 then
        if self.MissedShots >= 25 then
            numBalls = 8
            despawnTime = 25
        else
            numBalls = 4
        end
        shouldChase = true
        self.MissedShots = 0
        self.AcidThrowCount = 0
    end
    self:SetNWFloat("LastThrowTime", CurTime())
    self:SetNWInt("MouthShape", math.random(1, 6))
    local spitSound = "Vomat/spit" .. math.random(1, 10) .. ".wav"
    if isAggressiveThrow then
        self:EmitSound(spitSound, 85, math.random(70, 80))
    elseif isWeakThrow then
        self:EmitSound(spitSound, 65, math.random(110, 120))
    else
        self:EmitSound(spitSound, 75, math.random(90, 110))
    end
    local directions = {}
    if numBalls == 8 then
        directions = {
            Vector(1, 0, 0.3), Vector(1, 0, 0.4),
            Vector(-1, 0, 0.3), Vector(-1, 0, 0.4),
            Vector(0, 1, 0.3), Vector(0, 1, 0.4),
            Vector(0, -1, 0.3), Vector(0, -1, 0.4)
        }
    end
    for i = 1, numBalls do
        local offset = Vector(math.random(-spread, spread), math.random(-spread, spread), 0)
        if isAggressiveThrow then offset = offset * 1.5
        elseif isWeakThrow then offset = offset * 0.5 end
        local acidPos = basePos + offset
        local acid = ents.Create("vomat_projectile")
        if not IsValid(acid) then continue end
        acid:SetPos(acidPos)
        acid:SetAngles(Angle(0, 0, 0))
        acid:SetOwner(self)
        acid:Spawn()
        acid:SetNWBool("IsAggressiveThrow", isAggressiveThrow)
        acid:SetNWBool("IsWeakThrow", isWeakThrow)
        local phys = acid:GetPhysicsObject()
        if IsValid(phys) then
            local direction
            if numBalls == 8 then
                direction = directions[i]:GetNormalized()
                phys:SetMass(3)
            else
                direction = (target:GetPos() + target:OBBCenter() - acidPos):GetNormalized()
                phys:SetMass(1)
            end
            local force = 800
            if isAggressiveThrow then
                force = force * 1.75
                phys:SetMass(2)
            elseif isWeakThrow then
                force = force * 0.5
                phys:SetMass(0.5)
            end
            phys:SetVelocity(direction * force)
            phys:EnableGravity(true)
            phys:EnableCollisions(true)
            phys:EnableMotion(true)
            phys:Wake()
        end
        acid.TargetPlayer = target
        acid.StartPos = acid:GetPos()
        acid.HitTarget = false
        acid.IsAggressiveThrow = isAggressiveThrow
        acid.IsWeakThrow = isWeakThrow
        acid.MoveToPlayer = false
        acid.OwnerVomat = self
        if shouldChase then
            timer.Simple(4.7, function()
                if IsValid(acid) and not acid.HitTarget then
                    acid.MoveToPlayer = true
                    acid.ChaseSound = CreateSound(acid, "Vomat/Soul.wav")
                    acid.ChaseSound:Play()
                    acid.ChaseSound:ChangePitch(100, 0)
                end
            end)
        end
        timer.Simple(despawnTime, function()
            if IsValid(acid) then acid:Remove() end
        end)
    end
end
function ENT:RunBehaviour()
    while true do
        local creationTime = self:GetCreationTime()
        local delay = 5 + (self:EntIndex() % 16)
        if creationTime and CurTime() - creationTime < delay then
            coroutine.wait(2)
        else
            if self:HaveEnemy() then
                if self.OneTime == 0 then
                    self:TeleportToRandom()
                    self.OneTime = 1
                else
                    self:ChasePlayer()
                end
            end
            coroutine.wait(2)
        end
    end
end
function ENT:ChasePlayer()
    local target = self:GetEnemy()
    if not IsValid(target) then
        self:TeleportToRandom()
        return
    end
    self.waiting = true
    self.chasing = true
    self.stalking = false
    self.walking = false
    self.stopchasing = false
    local targetPos = target:GetPos()
    if not targetPos or not util.IsInWorld(targetPos) then
        self:TeleportToRandom()
        return
    end
    self.path:Compute(self, targetPos)
    local attackCooldown = 0
    while self.path:IsValid() and not self.stopchasing and IsValid(target) and target:Alive() do
        local dt = FrameTime()
        local isTargetWeak = target:IsPlayer() and target:Health() <= 20
        self:Randomm()
        local canSee = self:HasLOS(target)
        local distToTarget = self:GetPos():Distance(target:GetPos())
        if canSee and distToTarget <= 700 then
            self.loco:SetAcceleration(0)
            self.loco:SetDesiredSpeed(0)
            local lookDir = (target:GetPos() - self:GetPos())
            lookDir.z = 0
            if lookDir:LengthSqr() > 1 then
                self.loco:FaceTowards(target:GetPos())
            end
            attackCooldown = attackCooldown - dt
            if attackCooldown <= 0 then
                if isTargetWeak then
                    self:ThrowBallAtPlayer()
                    timer.Simple(0.5, function()
                        if IsValid(self) and IsValid(target) and target:Alive() and target:Health() <= 20 then
                            self:ThrowBallAtPlayer()
                        end
                    end)
                    attackCooldown = 3.5
                else
                    self:ThrowBallAtPlayer()
                    attackCooldown = 5
                end
            end
        else
            attackCooldown = math.max(attackCooldown - dt, 1.5)
            if isTargetWeak then
                self.loco:SetAcceleration(450)
                self.loco:SetDesiredSpeed(750)
            else
                self.loco:SetAcceleration(300)
                self.loco:SetDesiredSpeed(500)
            end
            self:RandomCompute()
            if self.path:GetAge() > 0.5 then
                self.path:Compute(self, target:GetPos())
            end
            self.path:Update(self)
        end
        if not target:Alive() then
            self.stopchasing = true
        end
        coroutine.yield()
    end
    self:TeleportToRandom()
end
function ENT:Think()
    local creationTime = self:GetCreationTime()
    local delay = 5 + (self:EntIndex() % 16)
    if creationTime and CurTime() - creationTime < delay then
        self:SetNWBool("IsChasing", false)
        self:NextThink(CurTime() + 1)
        return true
    end
    self:FindEnemy()
    local inRange = false
    for _, ply in ipairs(player.GetHumans()) do
        if ply:Alive() and self:GetPos():Distance(ply:GetPos()) <= 700 then
            inRange = true
            break
        end
    end
    if not inRange and not self.IsAnimating then
        if math.random() < 0.08 then
            local fx = EffectData()
            fx:SetOrigin(self:GetPos())
            fx:SetScale(0.3)
            fx:SetColor(1)
            util.Effect("bloodspray", fx)
        end
    end
    if inRange ~= self.LastAnimationState then
        if inRange then
            self:EmergingAnimation()
        else
            self:SubmergeAnimation()
            if math.random() < 0.10 then
                timer.Simple(0.8, function()
                    if IsValid(self) and not self:GetNWBool("IsChasing", false) then
                        self:TeleportToRandom()
                    end
                end)
            end
        end
        self.LastAnimationState = inRange
    end
    if self.chasing and self.loaded_sounds[1] then
        self.loaded_sounds[1]:SetSoundLevel(70)
        if not self.loaded_sounds[1]:IsPlaying() then
            self.loaded_sounds[1]:Play()
        end
    end
    self:SetAbsVelocity(self.loco:GetVelocity())
    self:SetNWBool("IsChasing", inRange)
    self:NextThink(CurTime())
    return true
end
function ENT:EmergingAnimation()
    self.IsAnimating = true
    local effectdata = EffectData()
    effectdata:SetOrigin(self:GetPos())
    effectdata:SetScale(1.5)
    util.Effect("BloodImpact", effectdata)
    for i = 1, 6 do
        local offset = VectorRand() * 25
        offset.z = 0
        local bloodSpray = EffectData()
        bloodSpray:SetOrigin(self:GetPos() + offset)
        bloodSpray:SetScale(0.7)
        bloodSpray:SetColor(1)
        util.Effect("bloodspray", bloodSpray)
        local bloodSplatter = EffectData()
        bloodSplatter:SetOrigin(self:GetPos() + offset)
        bloodSplatter:SetScale(0.8)
        bloodSplatter:SetColor(1)
        util.Effect("BloodImpact", bloodSplatter)
    end
    local growthWave = EffectData()
    growthWave:SetOrigin(self:GetPos())
    growthWave:SetScale(2)
    growthWave:SetMagnitude(1)
    util.Effect("WheelDust", growthWave)
    self:EmitSound("npc/antlion/attack_single" .. math.random(1, 3) .. ".wav", 50, 150)
    self:EmitSound("physics/flesh/flesh_bloody_impact_hard1.wav", 60, 120)
end
function ENT:SubmergeAnimation()
    self.IsAnimating = true
    local effectdata = EffectData()
    effectdata:SetOrigin(self:GetPos())
    effectdata:SetScale(1.2)
    util.Effect("BloodImpact", effectdata)
    for i = 1, 4 do
        local offset = VectorRand() * 15
        offset.z = 0
        local bloodSpray = EffectData()
        bloodSpray:SetOrigin(self:GetPos() + offset)
        bloodSpray:SetScale(0.5)
        bloodSpray:SetColor(1)
        util.Effect("bloodspray", bloodSpray)
        if math.random() > 0.5 then
            local bloodDrop = EffectData()
            bloodDrop:SetOrigin(self:GetPos() + offset)
            bloodDrop:SetScale(0.4)
            util.Effect("BloodImpact", bloodDrop)
        end
    end
    local sinkEffect = EffectData()
    sinkEffect:SetOrigin(self:GetPos())
    sinkEffect:SetScale(1.5)
    sinkEffect:SetMagnitude(0.7)
    util.Effect("WheelDust", sinkEffect)
    self:EmitSound("physics/flesh/flesh_bloody_break.wav", 50, 120)
    self:EmitSound("npc/antlion/digdown1.wav", 60, 150)
end
function ENT:OnTakeDamage(dmginfo)
    if self:Health() <= 0 then return end
    if dmginfo:IsBulletDamage() or dmginfo:IsExplosionDamage() then
        self:SetHealth(0)
    else
        self:SetHealth(self:Health() - dmginfo:GetDamage())
    end
    if self:Health() <= 0 then
        local target = self:GetEnemy()
        if IsValid(target) and self.loaded_sounds[1] then
            self.loaded_sounds[1]:Stop()
        end
        self:Remove()
    end
end
function ENT:PhysgunPickup() return false end
function ENT:GravGunPickupAllowed() return false end
function ENT:OnRemove()
    if self.loaded_sounds and self.loaded_sounds[1] then
        self.loaded_sounds[1]:Stop()
    end
    for _, proj in ipairs(ents.FindByClass("vomat_projectile")) do
        if IsValid(proj) and proj:GetOwner() == self then
            proj:Remove()
        end
    end
    for _, ply in ipairs(player.GetHumans()) do
        if ply.VomatTimers then
            for tName, ownerEnt in pairs(ply.VomatTimers) do
                if ownerEnt == self then
                    timer.Remove(tName)
                    ply.VomatTimers[tName] = nil
                end
            end
        end
    end
end
hook.Add("ShouldCollide", "VOMAT_NoProjectileCollision", function(ent1, ent2)
    if ent1:GetClass() == "VOMAT" and ent2:GetClass() == "vomat_projectile" then return false end
    if ent2:GetClass() == "VOMAT" and ent1:GetClass() == "vomat_projectile" then return false end
end)
