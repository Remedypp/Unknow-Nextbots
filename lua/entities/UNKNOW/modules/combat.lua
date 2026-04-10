local ENT = ENT
function ENT:InitializeCombatSystem()
    self.combatData = {
        killRadius = 50,
        heightCheck = 150,
        afterKillTeleport = true,
        combatCooldown = 0.5,
        lastKillTime = 0
    }
end
function ENT:InstaGib()
    if not self.combatData then
        self:InitializeCombatSystem()
    end
    if CurTime() - self.combatData.lastKillTime < self.combatData.combatCooldown then
        return
    end
    local myPos = self:GetPos()
    local radius = self.combatData.killRadius
    local heightCheck = self.combatData.heightCheck
    for _, ply in ipairs(player.GetAll()) do
        if IsValid(ply) and ply:Alive() then
            local playerPos = ply:GetPos()
            local horizontalDist = math.sqrt(
                (playerPos.x - myPos.x) * (playerPos.x - myPos.x) +
                (playerPos.y - myPos.y) * (playerPos.y - myPos.y)
            )
            local verticalDist = math.abs(playerPos.z - myPos.z)
            if (horizontalDist < radius and verticalDist < heightCheck) or
               (self:VectorDistance(playerPos, myPos) < radius) then
                local trace = util.TraceLine({
                    start = self:GetPos() + Vector(0, 0, 50),
                    endpos = ply:GetPos() + Vector(0, 0, 32),
                    filter = {self, ply}
                })
                if not trace.Hit then
                    self:KillPlayer(ply)
                    self.combatData.lastKillTime = CurTime()
                    self.lastKillPos = ply:GetPos()
                    if self.IncrementCatchCount then
                        self:IncrementCatchCount(ply)
                    end
                    self.waiting = false
                    self.chasing = false
                    self.stalking = false
                    self.walking = false
                    self.stopchasing = true
                    self:SetNWBool("IsWalking", false)
                    self.canWatchEnemy = true
                    local otherPlayersAlive = false
                    local killedPlayer = ply
                    for _, otherPly in ipairs(player.GetAll()) do
                        if otherPly ~= killedPlayer and IsValid(otherPly) and otherPly:Alive() and otherPly:Health() > 0 then
                            otherPlayersAlive = true
                            break
                        end
                    end
                    if otherPlayersAlive then
                        self.shouldTeleportAfterKill = true
                        self.shouldWatchRagdoll = false
                    else
                        self.shouldWatchRagdoll = true
                        self.shouldTeleportAfterKill = false
                    end
                    return true
                elseif ply:InVehicle() then
                    local vehicle = ply:GetVehicle()
                    if IsValid(vehicle) then
                        ply:ExitVehicle()
                        timer.Simple(0.1, function()
                            if IsValid(ply) and not ply:InVehicle() then
                                self:KillPlayer(ply)
                            end
                        end)
                        return true
                    end
                end
            end
        end
    end
    self:BreakNearbyObjects()
    return false
end
function ENT:KillPlayer(ply)
    if not IsValid(ply) then return end
    if self.SendDeathEffect then
        self:SendDeathEffect(ply)
    end
    ply:Kill()
end
function ENT:BreakNearbyObjects()
    local radius = 60
    local entities = ents.FindInSphere(self:GetPos(), radius)
    local zLimit = self:GetPos().z
    for _, entity in ipairs(entities) do
        if IsValid(entity) and entity:GetPos().z > zLimit then
            local class = entity:GetClass()
            if class == "func_breakable" then
                entity:Fire("Break", "", 0)
            elseif class == "func_reflective_glass" then
                entity:SetNoDraw(true)
                entity:SetSolid(SOLID_NONE)
                timer.Simple(5, function()
                    if IsValid(entity) then
                        entity:SetNoDraw(false)
                        entity:SetSolid(SOLID_VPHYSICS)
                    end
                end)
            elseif class == "prop_physics" then
                local phys = entity:GetPhysicsObject()
                if IsValid(phys) then
                    local pushDir = (entity:GetPos() - self:GetPos()):GetNormalized()
                    phys:ApplyForceCenter(pushDir * 5000)
                end
            end
        end
    end
end
function ENT:CanAttack()
    if not self.combatData then return true end
    return CurTime() - self.combatData.lastKillTime >= self.combatData.combatCooldown
end
function ENT:GetNearestPlayerInRange(range)
    local nearestPly = nil
    local nearestDist = range or 1000
    local myPos = self:GetPos()
    for _, ply in ipairs(player.GetAll()) do
        if IsValid(ply) and ply:Alive() then
            local dist = ply:GetPos():Distance(myPos)
            if dist < nearestDist then
                nearestDist = dist
                nearestPly = ply
            end
        end
    end
    return nearestPly, nearestDist
end
function ENT:InitializeBoneDistortionSystem()
    self.boneDistortionData = {
        lastDistortionTime = 0,
        distortionCooldown = 480,
        distortionChance = 0.008,
        affectedPlayers = {},
        catchCount = {},
        systemActivated = false
    }
end
function ENT:IncrementCatchCount(player)
    if not IsValid(player) then return end
    if not self.boneDistortionData then self:InitializeBoneDistortionSystem() end
    local steamID = player:SteamID()
    self.boneDistortionData.catchCount[steamID] = (self.boneDistortionData.catchCount[steamID] or 0) + 1
    local catchCount = self.boneDistortionData.catchCount[steamID]
    self.boneDistortionData.distortionChance = 0.008 + (catchCount * 0.002)
    if catchCount >= 3 and not self.boneDistortionData.systemActivated then
        self.boneDistortionData.systemActivated = true
    end
    return catchCount
end
function ENT:ApplyBoneDistortion(player)
    if not IsValid(player) or not player:Alive() then return end
    if not self.boneDistortionData then self:InitializeBoneDistortionSystem() end
    local steamID = player:SteamID()
    if self.boneDistortionData.affectedPlayers[steamID] then return end
    local storedWeapons = {}
    for _, weapon in ipairs(player:GetWeapons()) do
        table.insert(storedWeapons, weapon:GetClass())
    end
    player:StripWeapons()
    self.boneDistortionData.affectedPlayers[steamID] = {
        active = true,
        weapons = storedWeapons
    }
    player:SetNWBool("UNKNOW_BoneDistortionActive", true)
    if net then
        net.Start("UNKNOW_BoneDistortion")
        net.WriteBool(true)
        net.Send(player)
    end
    if self.PlayBoneCryingSound then
        self:PlayBoneCryingSound(player)
    end
    if math.random() < 0.5 then
        util.ScreenShake(player:GetPos(), 2, 5, 2, 500)
    end
    timer.Simple(120, function()
        if IsValid(player) and IsValid(self) then
            self:RestoreBoneDistortion(player)
        end
    end)
end
function ENT:RestoreBoneDistortion(player)
    if not IsValid(player) then return end
    if not self.boneDistortionData then return end
    local steamID = player:SteamID()
    if self.StopBoneCryingSound then
        self:StopBoneCryingSound(player)
    end
    if net then
        net.Start("UNKNOW_BoneDistortion")
        net.WriteBool(false)
        net.Send(player)
    end
    local playerData = self.boneDistortionData.affectedPlayers[steamID]
    if playerData and playerData.weapons then
        for _, weaponClass in ipairs(playerData.weapons) do
            player:Give(weaponClass)
        end
    end
    self.boneDistortionData.affectedPlayers[steamID] = nil
    player:SetNWBool("UNKNOW_BoneDistortionActive", false)
    if self.isGrabbingPlayer and self.grabbedPlayer == player then
        self:ReleasePlayer(player)
    end
    if self.PlayBoneStopSound then
        self:PlayBoneStopSound(player)
    end
    self.boneDistortionData.lastDistortionTime = CurTime()
    self.boneDistortionData.distortionCooldown = 480
end
function ENT:CheckBoneDistortion()
    if not IsValid(self) then return end
    if not self.boneDistortionData then self:InitializeBoneDistortionSystem() end
    if not self.boneDistortionData.systemActivated then return end
    if CurTime() - self.boneDistortionData.lastDistortionTime < self.boneDistortionData.distortionCooldown then
        return
    end
    if math.random() > self.boneDistortionData.distortionChance then
        self.boneDistortionData.lastDistortionTime = CurTime()
        self.boneDistortionData.distortionCooldown = 480
        return
    end
    local candidates = {}
    for _, ply in ipairs(player.GetAll()) do
        if IsValid(ply) and ply:Alive() and
           not self.boneDistortionData.affectedPlayers[ply:SteamID()] then
            table.insert(candidates, ply)
        end
    end
    if #candidates > 0 then
        local victim = candidates[math.random(#candidates)]
        if IsValid(victim) then
            self:ApplyBoneDistortion(victim)
        end
    else
        self.boneDistortionData.lastDistortionTime = CurTime()
        self.boneDistortionData.distortionCooldown = 480
    end
end
function ENT:IsPlayerUnderBoneEffect(player)
    if not IsValid(player) then return false end
    return player:GetNWBool("UNKNOW_BoneDistortionActive", false)
end
function ENT:GrabPlayer(player)
    if not IsValid(player) then return end
    self.isGrabbingPlayer = true
    self.grabbedPlayer = player
    self.grabStartTime = CurTime()
    self.waiting = false
    self.chasing = false
    self.stalking = false
    self.walking = false
    self.stopchasing = true
    self:SetNWBool("IsWalking", false)
    if self.path then
        self.path:Invalidate()
    end
    player:SetNWBool("UNKNOW_Grabbed", true)
    player.UNKNOW_OriginalVelocity = player:GetVelocity()
    player:SetVelocity(Vector(0, 0, 0))
    local unknowPos = self:GetPos()
    local unknowAngles = self:GetAngles()
    local grabOffset = unknowAngles:Forward() * 40
    local grabPosition = unknowPos + grabOffset
    player:SetPos(grabPosition)
    player:SetEyeAngles(Angle(0, unknowAngles.y + 180, 0))
    if self.PlayGrabSound then
        self:PlayGrabSound()
    end
    if self.PlayPainSound then
        self:PlayPainSound(player)
    end
    local steamID = player:SteamID()
    timer.Create("UNKNOW_GrabHold_" .. steamID, 0.1, 0, function()
        if not IsValid(self) or not IsValid(player) or not self.isGrabbingPlayer then
            timer.Remove("UNKNOW_GrabHold_" .. steamID)
            return
        end
        local currentPos = self:GetPos()
        local currentAngles = self:GetAngles()
        local currentOffset = currentAngles:Forward() * 40
        local currentGrabPos = currentPos + currentOffset
        player:SetPos(currentGrabPos)
        player:SetVelocity(Vector(0, 0, 0))
        if not self:IsPlayerUnderBoneEffect(player) then
            self:ReleasePlayer(player)
        end
    end)
end
function ENT:ReleasePlayer(player)
    if not IsValid(player) then return end
    self.isGrabbingPlayer = false
    self.grabbedPlayer = nil
    self.grabStartTime = nil
    player:SetNWBool("UNKNOW_Grabbed", false)
    if player.UNKNOW_OriginalVelocity then
        player:SetVelocity(player.UNKNOW_OriginalVelocity)
        player.UNKNOW_OriginalVelocity = nil
    end
    timer.Remove("UNKNOW_GrabHold_" .. player:SteamID())
    self.waiting = false
    self.chasing = false
    self.stalking = true
    self.walking = true
    self.stopchasing = true
end
