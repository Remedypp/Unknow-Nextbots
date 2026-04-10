local ENT = ENT
ENT.STATE_DORMANT = 1
ENT.STATE_CURIOUS = 2
ENT.STATE_STALKING = 3
ENT.STATE_HUNTING = 4
ENT.STATE_RETREAT = 5
ENT.StateNames = {
    [1] = "DORMANT",
    [2] = "CURIOUS",
    [3] = "STALKING",
    [4] = "HUNTING",
    [5] = "RETREAT"
}
function ENT:InitializeBehaviorSystem()
    self.baseSpeed = math.random(150, 250)
    self.currentSpeed = self.baseSpeed
    self.maxSpeed = math.random(400, 500)
    self.acceleration = math.random(300, 500)
    self.LoseTargetDist = 9999999
    self.SearchRadius = 9999999
    self.interest = 0
    self.interestDecayRate = 0.5
    self.lastInterestUpdate = CurTime()
    self.interestFactors = {
        playerAlone = 15,
        playerRunning = 10,
        playerInDark = 20,
        playerDistracted = 15,
        playerLooking = -30,
        playerInGroup = -20,
    }
    self.horrorState = self.STATE_DORMANT
    self.stateStartTime = CurTime()
    self.stateMinDuration = 0
    self.stateDurations = {
        [self.STATE_DORMANT] = {5, 15},
        [self.STATE_CURIOUS] = {5, 20},
        [self.STATE_STALKING] = {15, 45},
        [self.STATE_HUNTING] = {10, 30},
        [self.STATE_RETREAT] = {10, 30},
    }
    self.waiting = false
    self.walking = false
    self.stalking = true
    self.chasing = false
    self.stopchasing = false
    self.isStalkingBehind = false
    self.target = nil
    self.path = Path("Follow")
    self.path:SetMinLookAheadDistance(300)
    self.path:SetGoalTolerance(20)
    self.pathCheck = 0
    self.LastPathRecompute = 1
    self.LastPathingInfraction = 0
    self.lastPlayerPosition = nil
    self.lastPlayerDirection = nil
    self.playerPositionHistory = {}
    self.maxPositionHistory = 10
    self.lastPeripheralAppearance = 0
    self.peripheralCooldown = math.random(8, 15)
    self.LastStuck = CurTime()
    self.StuckTries = 0
    self.canWatchEnemy = true
    self:SetNWInt("HorrorState", self.horrorState)
end
function ENT:UpdateInterest()
    local ct = CurTime()
    local dt = ct - self.lastInterestUpdate
    self.lastInterestUpdate = ct
    local enemy = self:GetEnemy()
    if not IsValid(enemy) then
        self.interest = math.max(0, self.interest - self.interestDecayRate * dt * 3)
        return
    end
    local interestChange = self:GetInterestFromEnvironment(enemy)
    self.interest = math.Clamp(self.interest + interestChange * dt, 0, 100)
end
function ENT:GetInterestFromEnvironment(ply)
    if not IsValid(ply) then return -5 end
    local interest = 0
    local alivePlayers = 0
    for _, p in ipairs(player.GetHumans()) do
        if p:Alive() then alivePlayers = alivePlayers + 1 end
    end
    if alivePlayers == 1 then
        interest = interest + self.interestFactors.playerAlone * 0.1
    elseif alivePlayers > 2 then
        interest = interest + self.interestFactors.playerInGroup * 0.1
    end
    if ply:GetVelocity():Length() > 200 then
        interest = interest + self.interestFactors.playerRunning * 0.1
    end
    if self:IsPlayerLookingAtMe(ply) then
        interest = interest + self.interestFactors.playerLooking * 0.1
    else
        interest = interest + self.interestFactors.playerDistracted * 0.05
    end
    local lightLevel = render and render.GetLightColor and render.GetLightColor(ply:GetPos()) or Vector(1,1,1)
    if lightLevel:Length() < 0.3 then
        interest = interest + self.interestFactors.playerInDark * 0.1
    end
    interest = interest - self.interestDecayRate
    return interest
end
function ENT:SetHorrorState(newState)
    if self.horrorState == newState then return end
    local oldState = self.horrorState
    self.horrorState = newState
    self.stateStartTime = CurTime()
    local durations = self.stateDurations[newState]
    if durations then
        self.stateMinDuration = math.random(durations[1], durations[2])
    end
    self:SetNWInt("HorrorState", newState)
    if newState == self.STATE_DORMANT then
        self.walking = true
        self.chasing = false
        self:SetNWBool("IsWalking", true)
        self.interest = 0
    elseif newState == self.STATE_CURIOUS then
        self.walking = false
        self.chasing = false
        self:SetNWBool("IsWalking", false)
    elseif newState == self.STATE_STALKING then
        self.walking = true
        self.chasing = false
        self:SetNWBool("IsWalking", true)
        self.currentSpeed = self.baseSpeed
    elseif newState == self.STATE_HUNTING then
        self.walking = false
        self.chasing = true
        self:SetNWBool("IsWalking", false)
        self:SetNWBool("IsHiding", false)
        self.currentSpeed = self.baseSpeed
    elseif newState == self.STATE_RETREAT then
        self.walking = false
        self.chasing = false
        self:SetNWBool("IsWalking", false)
        self:SetNWBool("IsHiding", true)
        self:TeleportToRandom()
    end
    if newState ~= self.STATE_RETREAT then
        self:SetNWBool("IsHiding", false)
    end
end
function ENT:CanTransitionState()
    return CurTime() - self.stateStartTime >= self.stateMinDuration
end
function ENT:GetStateDuration()
    return CurTime() - self.stateStartTime
end
function ENT:IsInPlayerPeriphery(ply)
    if not IsValid(ply) then return false end
    local dirToSelf = (self:GetPos() - ply:EyePos()):GetNormalized()
    local plyForward = ply:EyeAngles():Forward()
    local dot = dirToSelf:Dot(plyForward)
    return dot > 0.2 and dot < 0.6
end
function ENT:IsPlayerLookingDirectlyAtMe(ply)
    if not IsValid(ply) then return false end
    local dirToSelf = (self:GetPos() - ply:EyePos()):GetNormalized()
    local plyForward = ply:EyeAngles():Forward()
    local dot = dirToSelf:Dot(plyForward)
    return dot > 0.85
end
function ENT:SetEnemy(ent)
    self.target = ent
    self:SetNWEntity("unknow_target", ent)
end
function ENT:GetEnemy()
    return self.target
end
function ENT:HaveEnemy()
    local enemy = self:GetEnemy()
    if IsValid(enemy) then
        if not self.nextVisionCheck or CurTime() > self.nextVisionCheck then
            self.nextVisionCheck = CurTime() + math.random(3, 8)
            if self:GetRangeTo(enemy:GetPos()) <= self.LoseTargetDist then
                if math.random() < 0.3 then
                    return true
                end
            end
        end
    end
    return self:FindEnemy()
end
function ENT:FindEnemy()
    local players = player.GetHumans()
    if #players == 0 then
        self:SetEnemy(nil)
        return false
    end
    local closest_player = nil
    local closest_distance = math.huge
    for i = 1, #players do
        if players[i]:Alive() then
            local distance = self:GetRangeTo(players[i]:GetPos())
            if distance < closest_distance then
                closest_player = players[i]
                closest_distance = distance
            end
        end
    end
    self:SetEnemy(closest_player)
    return closest_player ~= nil
end
function ENT:TryFindVisibleEnemy()
    local enemies = player.GetAll()
    local closest_enemy = nil
    local closest_distance = math.huge
    for i = 1, #enemies do
        local enemy = enemies[i]
        if enemy:Alive() and self:IsVisible(enemy) then
            local distance = self:GetRangeTo(enemy:GetPos())
            if distance < closest_distance then
                closest_enemy = enemy
                closest_distance = distance
            end
        end
    end
    self:SetEnemy(closest_enemy)
    return closest_enemy ~= nil
end
function ENT:IsVisible(entity)
    if not IsValid(entity) then return false end
    local self_pos = self:GetPos() + Vector(0, 0, 40)
    local enemy_pos = entity:GetPos() + Vector(0, 0, 40)
    local trace = util.TraceLine({
        start = self_pos,
        endpos = enemy_pos,
        filter = {self, entity},
        mask = MASK_SHOT
    })
    return not trace.Hit
end
function ENT:CanPlayerSeeMe(entity)
    local playerToCheck = entity or self:GetEnemy()
    if not IsValid(playerToCheck) or not playerToCheck:IsPlayer() then
        return false
    end
    local playerPos = playerToCheck:EyePos()
    local selfPos = self:GetPos() + Vector(0, 0, 65)
    local aimVector = (selfPos - playerPos):GetNormalized()
    local playerAngles = playerToCheck:EyeAngles()
    local lookVector = playerAngles:Forward()
    local dotProduct = lookVector:Dot(aimVector)
    local fovCos = math.cos(math.rad(110 / 2))
    local isWithinFOV = dotProduct >= fovCos
    if isWithinFOV then
        local traceData = {
            start = playerPos,
            endpos = selfPos,
            filter = {playerToCheck, self},
            mask = MASK_SHOT
        }
        local traceResult = util.TraceLine(traceData)
        return not traceResult.Hit
    end
    return false
end
function ENT:CanISeePlayer(entity)
    local entityToCheck = entity or self:GetEnemy()
    if not IsValid(entityToCheck) then
        return false
    end
    local enemyPos = entityToCheck:GetPos()
    local selfPos = self:GetPos()
    local trace = util.TraceLine({
        start = selfPos + Vector(0, 0, 40),
        endpos = enemyPos + Vector(0, 0, 40),
        filter = {entityToCheck, self},
        mask = MASK_SOLID_BRUSHONLY
    })
    return not trace.Hit
end
function ENT:IsPlayerLookingAtMe(player)
    if not IsValid(player) then return false end
    local myPos = self:GetPos() + Vector(0, 0, 64)
    local playerEyePos = player:EyePos()
    local playerEyeAngles = player:EyeAngles()
    local toEntity = (myPos - playerEyePos):GetNormalized()
    local dot = playerEyeAngles:Forward():Dot(toEntity)
    local trace = util.TraceLine({
        start = playerEyePos,
        endpos = myPos,
        filter = {player, self},
        mask = MASK_SOLID_BRUSHONLY
    })
    return dot > 0.7 and not trace.Hit
end
function ENT:RunBehaviour()
    self:SetHorrorState(self.STATE_DORMANT)
    while true do
        self:UpdateInterest()
        if self.shouldWatchRagdoll then
            self.shouldWatchRagdoll = false
            self:WatchRagdoll()
        end
        if self.shouldTeleportAfterKill then
            self.shouldTeleportAfterKill = false
            self:SetHorrorState(self.STATE_RETREAT)
        end
        if not IsValid(self:GetEnemy()) then
            self:FindEnemy()
        end
        local enemy = self:GetEnemy()
        local state = self.horrorState
        if state == self.STATE_DORMANT then
            self:ExecuteDormantState(enemy)
        elseif state == self.STATE_CURIOUS then
            self:ExecuteCuriousState(enemy)
        elseif state == self.STATE_STALKING then
            self:ExecuteStalkingState(enemy)
        elseif state == self.STATE_HUNTING then
            self:ExecuteHuntingState(enemy)
        elseif state == self.STATE_RETREAT then
            self:ExecuteRetreatState()
        end
        coroutine.yield()
    end
end
function ENT:ExecuteDormantState(enemy)
    self:WanderAimlessly()
    if not IsValid(enemy) then
        return
    end
    local distance = self:GetPos():Distance(enemy:GetPos())
    local playerRunning = enemy:GetVelocity():Length() > 200
    if playerRunning and distance < 1000 then
        self.interest = self.interest + 3
    end
    if distance < 400 then
        self.interest = self.interest + 2
    end
    if self.interest > 15 and self:CanTransitionState() then
        self:SetHorrorState(self.STATE_CURIOUS)
        return
    end
    if distance < 600 and math.random() < 0.05 and self:CanTransitionState() then
        self:SetHorrorState(self.STATE_CURIOUS)
        return
    end
end
function ENT:ExecuteCuriousState(enemy)
    if not IsValid(enemy) then
        self:SetHorrorState(self.STATE_DORMANT)
        return
    end
    local dirToPlayer = (enemy:GetPos() - self:GetPos()):GetNormalized()
    local angleToPlayer = dirToPlayer:Angle()
    self:SetAngles(Angle(0, angleToPlayer.y, 0))
    self:RecordPlayerPosition(enemy)
    local distance = self:GetPos():Distance(enemy:GetPos())
    local isLooking = self:IsPlayerLookingDirectlyAtMe(enemy)
    self:SetNWFloat("CuriousDistance", distance)
    if distance < 150 then
        self:SetNWBool("IsTeleporting", true)
        self:TeleportToRandom()
        timer.Simple(0.1, function()
            if IsValid(self) then
                self:SetNWBool("IsTeleporting", false)
            end
        end)
        self.interest = self.interest + 15
        if self.interest > 40 then
            self:SetHorrorState(self.STATE_STALKING)
        else
            self.stateStartTime = CurTime()
        end
        return
    end
    if isLooking then
        self.interest = self.interest - 1
        if self.interest < 5 and self:CanTransitionState() then
            self:TeleportToRandom()
            self:SetHorrorState(self.STATE_DORMANT)
            return
        end
    else
        self.interest = self.interest + 1.5
    end
    if self.interest > 30 and self:CanTransitionState() then
        self:SetHorrorState(self.STATE_STALKING)
        return
    end
    if self:GetStateDuration() > 10 and math.random() < 0.03 then
        self:SetHorrorState(self.STATE_STALKING)
        return
    end
    if self.interest < 3 and self:CanTransitionState() then
        self:SetHorrorState(self.STATE_DORMANT)
        return
    end
end
function ENT:ExecuteStalkingState(enemy)
    if not IsValid(enemy) then
        self:SetHorrorState(self.STATE_DORMANT)
        return
    end
    local distance = self:GetPos():Distance(enemy:GetPos())
    local isLooking = self:IsPlayerLookingDirectlyAtMe(enemy)
    local inPeriphery = self:IsInPlayerPeriphery(enemy)
    local idealDistance = math.random(300, 600)
    if isLooking and distance < 500 then
        local ct = CurTime()
        if ct > self.lastPeripheralAppearance + 3 then
            self:TeleportToPeriphery(enemy)
            self.lastPeripheralAppearance = ct
            return
        end
    end
    if distance > idealDistance + 100 then
        self:MoveTowardsPlayer(enemy, self.baseSpeed)
    elseif distance < idealDistance - 100 then
        if isLooking then
            self:MoveAwayFromPlayer(enemy)
        end
    else
        self:FollowAtDistance(enemy, idealDistance)
    end
    self:RecordPlayerPosition(enemy)
    self.interest = self.interest + 0.3
    if self.interest > 50 and self:CanTransitionState() then
        self:SetHorrorState(self.STATE_HUNTING)
        return
    end
    if self.interest < 15 and self:CanTransitionState() then
        self:SetHorrorState(self.STATE_CURIOUS)
        return
    end
    if self:GetStateDuration() > 20 and math.random() < 0.03 then
        self:SetHorrorState(self.STATE_HUNTING)
        return
    end
end
function ENT:ExecuteHuntingState(enemy)
    if not IsValid(enemy) then
        self:SetHorrorState(self.STATE_RETREAT)
        return
    end
    local playerVel = 0
    if enemy:InVehicle() then
        local vehicle = enemy:GetVehicle()
        if IsValid(vehicle) then
            playerVel = vehicle:GetVelocity():Length()
        else
            playerVel = enemy:GetVelocity():Length()
        end
    else
        playerVel = enemy:GetVelocity():Length()
    end
    local stateDuration = self:GetStateDuration()
    local speedOffset = Lerp(math.Clamp(stateDuration / 15, 0, 1), 100, 200)
    self.currentSpeed = math.max(self.baseSpeed, playerVel + speedOffset)
    self.loco:SetDesiredSpeed(self.currentSpeed)
    self.loco:SetAcceleration(self.currentSpeed + 100)
    self:ChasePlayerNatural(enemy)
    if self.InstaGib then
        self:InstaGib()
    end
    local distance = self:GetPos():Distance(enemy:GetPos())
    if distance > 1500 and self:GetStateDuration() > 10 then
        self:SetHorrorState(self.STATE_RETREAT)
        return
    end
    if self:CanTransitionState() and self:GetStateDuration() > 30 then
        self:SetHorrorState(self.STATE_RETREAT)
        return
    end
end
function ENT:ExecuteRetreatState()
    self.walking = false
    self.chasing = false
    self:SetNWBool("IsWalking", false)
    if self:CanTransitionState() then
        self.interest = 0
        self:SetHorrorState(self.STATE_DORMANT)
    end
end
function ENT:WanderAimlessly()
    self.walking = true
    self:SetNWBool("IsWalking", true)
    local randomAngle = math.random() * math.pi * 2
    local randomDist = math.random(200, 500)
    local targetPos = self:GetPos() + Vector(
        math.cos(randomAngle) * randomDist,
        math.sin(randomAngle) * randomDist,
        0
    )
    local tr = util.TraceLine({
        start = targetPos + Vector(0, 0, 100),
        endpos = targetPos - Vector(0, 0, 100),
        mask = MASK_SOLID_BRUSHONLY
    })
    if tr.Hit then
        targetPos = tr.HitPos + Vector(0, 0, 10)
    end
    self.loco:SetDesiredSpeed(self.baseSpeed * 0.5)
    self.loco:SetAcceleration(200)
    if not self.path:IsValid() or self.path:GetAge() > 3 then
        self.path:Compute(self, targetPos, {area_avoidance = true})
    end
    self.path:Update(self)
end
function ENT:TeleportToPeriphery(ply)
    if not IsValid(ply) then return end
    local playerPos = ply:GetPos()
    local playerForward = ply:EyeAngles():Forward()
    local playerRight = ply:EyeAngles():Right()
    local side = math.random() > 0.5 and 1 or -1
    local distance = math.random(300, 500)
    local angle = math.rad(60 * side)
    local direction = playerForward * math.cos(angle) + playerRight * math.sin(angle)
    local targetPos = playerPos + direction * distance
    local tr = util.TraceLine({
        start = targetPos + Vector(0, 0, 100),
        endpos = targetPos - Vector(0, 0, 100),
        mask = MASK_SOLID_BRUSHONLY
    })
    if tr.Hit then
        self:SetNWBool("IsTeleporting", true)
        self:SetPos(tr.HitPos + Vector(0, 0, 10))
        timer.Simple(0.1, function()
            if IsValid(self) then
                self:SetNWBool("IsTeleporting", false)
            end
        end)
    end
end
function ENT:MoveTowardsPlayer(ply, speed)
    if not IsValid(ply) then return end
    self.walking = true
    self:SetNWBool("IsWalking", true)
    self.loco:SetDesiredSpeed(speed or self.baseSpeed)
    self.loco:SetAcceleration(self.acceleration)
    if not self.path:IsValid() or self.path:GetAge() > 0.5 then
        self.path:Compute(self, ply:GetPos(), {area_avoidance = true})
    end
    self.path:Update(self)
end
function ENT:MoveAwayFromPlayer(ply)
    if not IsValid(ply) then return end
    local awayDir = (self:GetPos() - ply:GetPos()):GetNormalized()
    local targetPos = self:GetPos() + awayDir * 300
    local tr = util.TraceLine({
        start = targetPos + Vector(0, 0, 100),
        endpos = targetPos - Vector(0, 0, 100),
        mask = MASK_SOLID_BRUSHONLY
    })
    if tr.Hit then
        targetPos = tr.HitPos + Vector(0, 0, 10)
    end
    self.walking = true
    self:SetNWBool("IsWalking", true)
    self.loco:SetDesiredSpeed(self.baseSpeed)
    if not self.path:IsValid() or self.path:GetAge() > 1 then
        self.path:Compute(self, targetPos, {area_avoidance = true})
    end
    self.path:Update(self)
end
function ENT:FollowAtDistance(ply, distance)
    if not IsValid(ply) then return end
    local currentDist = self:GetPos():Distance(ply:GetPos())
    if math.abs(currentDist - distance) > 50 then
        if currentDist > distance then
            self:MoveTowardsPlayer(ply, self.baseSpeed * 0.7)
        else
            self:MoveAwayFromPlayer(ply)
        end
    else
        local dirToPlayer = (ply:GetPos() - self:GetPos()):GetNormalized()
        local angleToPlayer = dirToPlayer:Angle()
        self:SetAngles(Angle(0, angleToPlayer.y, 0))
    end
end
function ENT:RecordPlayerPosition(ply)
    if not IsValid(ply) then return end
    local currentPos = ply:GetPos()
    table.insert(self.playerPositionHistory, {
        pos = currentPos,
        time = CurTime(),
        direction = ply:GetVelocity():GetNormalized()
    })
    while #self.playerPositionHistory > self.maxPositionHistory do
        table.remove(self.playerPositionHistory, 1)
    end
    self.lastPlayerPosition = currentPos
    self.lastPlayerDirection = ply:GetVelocity():GetNormalized()
end
function ENT:ChasePlayerNatural(ply)
    if not IsValid(ply) then return end
    self.walking = false
    self.chasing = true
    self:SetNWBool("IsWalking", false)
    if not self.path:IsValid() or self.path:GetAge() > 0.3 then
        self.path:Compute(self, ply:GetPos(), {area_avoidance = true})
    end
    self.path:Update(self)
end
function ENT:TransitionBehavior(newBehavior)
    self.waiting = false
    self.walking = false
    self.stalking = false
    self.chasing = false
    if newBehavior == "wander" then
        self.walking = true
    elseif newBehavior == "stalk" then
        self.stalking = true
    elseif newBehavior == "chase" then
        self.chasing = true
    end
    self.currentBehavior = newBehavior
end
function ENT:ChasePlayer()
    if self.isStalkingBehind then return end
    if self.isGrabbingPlayer then return end
    local velocity_num = 200
    self.waiting = true
    self.chasing = true
    self.stalking = false
    self.walking = false
    self.stopchasing = false
    self:SetNWBool("IsWalking", false)
    self.loco:SetAcceleration(700)
    local target = self:GetEnemy()
    if not IsValid(target) then return "failed" end
    local chasing_timer = 0
    local chasing_time = 9999999
    local pathOptions = {
        area_avoidance = true,
        repath = 0.5
    }
    self.path:Compute(self, target:GetPos(), pathOptions)
    self.LastPathRecompute = 1
    local chaseTimeLimit = math.random(30, 50)
    local chaseStartTime = CurTime()
    local lastPos = self:GetPos()
    local stuckCheckTime = CurTime()
    local stuckAttempts = 0
    while not self.stopchasing and IsValid(target) and target:Alive() do
        local playerVel = 0
        if target:InVehicle() then
            local vehicle = target:GetVehicle()
            if IsValid(vehicle) then
                playerVel = vehicle:GetVelocity():Length()
            else
                playerVel = target:GetVelocity():Length()
            end
        else
            playerVel = target:GetVelocity():Length()
        end
        self.loco:SetDesiredSpeed(playerVel + velocity_num)
        self.loco:SetAcceleration(playerVel + velocity_num + velocity_num)
        if self.InstaGib then
            self:InstaGib()
        end
        if self.Randomm then
            self:Randomm()
        end
        if self.RecordPlayerMovement then
            self:RecordPlayerMovement(target)
        end
        local currentPos = self:GetPos()
        local currentTime = CurTime()
        if currentTime - stuckCheckTime > 2 then
            local distanceMoved = currentPos:Distance(lastPos)
            if distanceMoved < 10 then
                stuckAttempts = stuckAttempts + 1
                if stuckAttempts == 1 then
                    self.path:Compute(self, target:GetPos(), pathOptions)
                    self.loco:ClearStuck()
                elseif stuckAttempts == 2 then
                    local angle = math.random() * math.pi * 2
                    local teleportPos = target:GetPos() + Vector(
                        math.cos(angle) * 300,
                        math.sin(angle) * 300,
                        0
                    )
                    local tr = util.TraceLine({
                        start = teleportPos + Vector(0, 0, 100),
                        endpos = teleportPos,
                        mask = MASK_SOLID_BRUSHONLY
                    })
                    if tr.Hit then
                        self:SetPos(tr.HitPos + Vector(0, 0, 10))
                    end
                    self.loco:ClearStuck()
                elseif stuckAttempts >= 3 then
                    self:TeleportToRandom()
                    return "stuck"
                end
            else
                stuckAttempts = 0
            end
            lastPos = currentPos
            stuckCheckTime = currentTime
        end
        if self:RandomCompute() then
            self.path:Compute(self, target:GetPos(), pathOptions)
        end
        chasing_timer = chasing_timer + FrameTime()
        if self.path:GetAge() > 0.1 then
            self:RecomputeTargetPath(target:GetPos())
        end
        self.path:Update(self)
        if chasing_timer > chasing_time and not self:CanPlayerSeeMe() then
            self.stopchasing = true
            self:TeleportToRandom()
        end
        coroutine.yield()
        if CurTime() - chaseStartTime > chaseTimeLimit then
            if math.random() < 0.5 then
                self:WatchEnemy()
            else
                self:GoToRandomPoint()
            end
            return "ok"
        end
    end
    if self.shouldWatchRagdoll then
        return "watchragdoll"
    end
    self:TeleportToRandom()
    return "ok"
end
function ENT:WatchEnemy()
    if self.isGrabbingPlayer then return "failed" end
    if not IsValid(self:GetEnemy()) then return "failed" end
    if not self.canWatchEnemy then
        return self:GoToRandomPoint()
    end
    self.canWatchEnemy = false
    self.walking = false
    self:SetNWBool("IsWalking", false)
    local enemy = self:GetEnemy()
    local watchDuration = math.random(10, 28)
    local startTime = CurTime()
    local hidingSpot = self:FindHidingSpot(enemy)
    local lastTeleport = CurTime()
    local teleportCooldown = math.random(2, 4)
    local wasSpotted = false
    local spottedStareTime = 0
    if hidingSpot then
        local effectData = EffectData()
        effectData:SetOrigin(self:GetPos())
        util.Effect("portal_spark", effectData)
        self:SetPos(hidingSpot.pos)
        if self.PlayBreathingSound then
            self:PlayBreathingSound()
        end
        effectData = EffectData()
        effectData:SetOrigin(self:GetPos())
        util.Effect("portal_spark", effectData)
        local enemyPos = enemy:EyePos()
        local dirToPlayer = (enemyPos - self:GetPos()):GetNormalized()
        local angleToPlayer = dirToPlayer:Angle()
        self:SetAngles(Angle(0, angleToPlayer.y, 0))
    end
    while IsValid(enemy) and CurTime() < startTime + watchDuration do
        local visCheck = util.TraceLine({
            start = self:GetPos() + Vector(0, 0, 60),
            endpos = enemy:EyePos(),
            filter = {enemy, self},
            mask = MASK_SOLID_BRUSHONLY
        })
        if not visCheck.Hit then
            local enemyPos = enemy:EyePos()
            local dirToPlayer = (enemyPos - self:GetPos()):GetNormalized()
            local angleToPlayer = dirToPlayer:Angle()
            self:SetAngles(Angle(0, angleToPlayer.y, 0))
            if self:IsPlayerLookingAtMe(enemy) then
                if not wasSpotted then
                    wasSpotted = true
                    spottedStareTime = CurTime()
                    if self.PlayAlertSound then
                        self:PlayAlertSound(false)
                    end
                end
                if CurTime() > lastTeleport + teleportCooldown then
                    if IsValid(enemy) and enemy:IsPlayer() then
                        util.ScreenShake(enemy:GetPos(), 0.5, 5, 0.5, 100)
                    end
                    local decisionRoll = math.random(1, 100)
                    if decisionRoll <= 60 then
                        if self.PlayAlertSound then
                            self:PlayAlertSound(true)
                        end
                        self.chasing = true
                        return self:ChasePlayer()
                    elseif decisionRoll <= 85 then
                        local effectData = EffectData()
                        effectData:SetOrigin(self:GetPos())
                        util.Effect("portal_spark", effectData)
                        local newSpot = self:FindHidingSpot(enemy)
                        if newSpot and newSpot.pos:Distance(enemy:GetPos()) > 300 then
                            self:SetPos(newSpot.pos)
                            effectData = EffectData()
                            effectData:SetOrigin(self:GetPos())
                            util.Effect("portal_spark", effectData)
                            hidingSpot = newSpot
                            wasSpotted = false
                        else
                            return self:GoToRandomPoint()
                        end
                    else
                        return self:GoToRandomPoint()
                    end
                    lastTeleport = CurTime()
                    teleportCooldown = math.random(2, 4)
                end
            else
                wasSpotted = false
            end
        end
        if CurTime() > lastTeleport + teleportCooldown then
            local newSpot = self:FindHidingSpot(enemy)
            if newSpot then
                self:SetPos(newSpot.pos)
                hidingSpot = newSpot
                lastTeleport = CurTime()
                teleportCooldown = math.random(2, 4)
            end
        end
        coroutine.yield()
    end
    return self:GoToRandomPoint()
end
function ENT:GoToRandomPoint()
    self.canWatchEnemy = true
    local enemy = self:GetEnemy()
    if IsValid(enemy) then
        local baseChance = 0.15
        if math.random() < baseChance then
            if self:StalkBehindPlayer(enemy) then
                return "ok"
            end
        end
    end
    self.walking = true
    self:SetNWBool("IsWalking", true)
    self.chasing = false
    self.stalking = false
    self.waiting = false
    local options = {
        lookahead = 500,
        tolerance = 10
    }
    self.path = Path("Chase")
    self.path:SetMinLookAheadDistance(options.lookahead)
    self.path:SetGoalTolerance(options.tolerance)
    local spot
    if IsValid(enemy) then
        local enemyPos = enemy:GetPos()
        local angle = math.random() * math.pi * 2
        local radius = math.random(200, 600)
        spot = enemyPos + Vector(
            math.cos(angle) * radius,
            math.sin(angle) * radius,
            0
        )
    else
        spot = self:GetPos() + Vector(
            math.random(-500, 500),
            math.random(-500, 500),
            0
        )
    end
    local trace = util.TraceLine({
        start = spot + Vector(0, 0, 500),
        endpos = spot,
        mask = MASK_SOLID_BRUSHONLY
    })
    if trace.Hit then
        spot = trace.HitPos + Vector(0, 0, 10)
    else
        self:TeleportToRandom()
        return "failed"
    end
    self.loco:SetAcceleration(math.random(800, 1200))
    self.loco:SetDesiredSpeed(math.random(200, 400))
    local watchTimer = 0
    local watchInterval = math.random(5, 15)
    local pathOptions = {
        area_avoidance = true,
        repath = 0.5
    }
    self.path:Compute(self, spot, pathOptions)
    local lastPos = self:GetPos()
    local stuckCheckTime = CurTime()
    local stuckAttempts = 0
    local maxStuckAttempts = 3
    local pathStartTime = CurTime()
    local maxPathTime = 30
    while self.path:IsValid() and self.walking do
        if IsValid(enemy) and self.RecordPlayerMovement then
            self:RecordPlayerMovement(enemy)
        end
        local currentPos = self:GetPos()
        local currentTime = CurTime()
        if currentTime - stuckCheckTime > 2 then
            local distanceMoved = currentPos:Distance(lastPos)
            if distanceMoved < 10 then
                stuckAttempts = stuckAttempts + 1
                if stuckAttempts == 1 then
                    self.path:Compute(self, spot, pathOptions)
                    self.loco:ClearStuck()
                elseif stuckAttempts == 2 then
                    local newAngle = math.random() * math.pi * 2
                    local newRadius = math.random(100, 300)
                    spot = currentPos + Vector(
                        math.cos(newAngle) * newRadius,
                        math.sin(newAngle) * newRadius,
                        0
                    )
                    self.path:Compute(self, spot, pathOptions)
                    self.loco:ClearStuck()
                elseif stuckAttempts >= maxStuckAttempts then
                    self:TeleportToRandom()
                    return "stuck"
                end
            else
                stuckAttempts = 0
            end
            lastPos = currentPos
            stuckCheckTime = currentTime
        end
        if currentTime - pathStartTime > maxPathTime then
            self:TeleportToRandom()
            return "timeout"
        end
        if self.path:GetAge() > 0.1 then
            self.path:Compute(self, spot, pathOptions)
        end
        self.path:Update(self)
        if self:GetPos():Distance(spot) < 50 then
            local choice = math.random(1, 100)
            if choice <= 30 then
                if IsValid(self:GetEnemy()) then
                    self.watching = true
                    return self:WatchEnemy()
                end
            elseif choice <= 70 then
                return self:GoToRandomPoint()
            else
                return self:WatchEnemy()
            end
        end
        coroutine.yield()
    end
    if not self.path:IsValid() and stuckAttempts < maxStuckAttempts then
        return self:GoToRandomPoint()
    end
    return "ok"
end
function ENT:StalkBehindPlayer(enemy)
    if not IsValid(enemy) then return false end
    local stalkChance = 0.15
    if math.random() < stalkChance then
        self.isStalkingBehind = true
        local behindPos = enemy:GetPos()
        local trace = util.TraceLine({
            start = behindPos + Vector(0, 0, 100),
            endpos = behindPos,
            mask = MASK_SOLID_BRUSHONLY
        })
        if trace.Hit then
            self:SetPos(trace.HitPos + Vector(0, 0, 10))
            self:SetNWBool("IsWalking", true)
            self.walking = true
            self.chasing = false
            local stalkDuration = math.random(8, 15)
            local stalkStart = CurTime()
            local fadeOutStart = false
            while CurTime() < stalkStart + stalkDuration do
                if not IsValid(enemy) then break end
                self.isStalkingBehind = true
                if self:IsPlayerLookingAtMe(enemy) then
                    fadeOutStart = true
                    break
                end
                local newBehindPos = enemy:GetPos()
                self:SetPos(LerpVector(0.1, self:GetPos(), newBehindPos))
                self:SetAngles((enemy:GetPos() - self:GetPos()):Angle())
                coroutine.yield()
            end
            timer.Simple(0.5, function()
                if IsValid(self) then
                    self.isStalkingBehind = false
                    self:SetNWBool("IsWalking", false)
                    self.walking = false
                    self:TeleportToRandom()
                end
            end)
            return true
        end
    end
    return false
end
function ENT:TeleportToRandom()
    self:SetNWBool("IsTeleporting", true)
    while not self:ArePlayersAlive() do
        coroutine.yield()
    end
    if not IsValid(self) then return end
    local spot_options = {
        pos = self:GetEnemy() and self:GetEnemy():GetPos() or self:GetPos(),
        radius = 10000,
        stepup = 5000,
        stepdown = 5000
    }
    local spot = nil
    local lookForSpot = true
    self.path = Path("Chase")
    self.path:SetMinLookAheadDistance(300)
    while lookForSpot do
        spot = self:FindSpot('random', spot_options)
        if spot and util.IsInWorld(spot) then
            local traceData = {
                start = spot + Vector(0, 0, 64),
                endpos = spot,
                mask = MASK_SOLID_BRUSHONLY
            }
            local trace = util.TraceLine(traceData)
            if not trace.Hit then
                lookForSpot = false
            end
        end
        coroutine.wait(0.1)
    end
    if IsValid(self) and spot then
        self:SetPos(spot)
        self.waiting = false
        self.walking = false
        self.chasing = false
        self.stalking = false
        self:SetNWBool("IsTeleporting", false)
    end
end
function ENT:WatchRagdoll()
    local ragdollPos = self.lastKillPos or self:GetPos()
    for _, ent in ipairs(ents.FindInSphere(ragdollPos, 200)) do
        if IsValid(ent) and ent:GetClass() == "prop_ragdoll" then
            ragdollPos = ent:GetPos()
            break
        end
    end
    self.walking = false
    self.chasing = false
    self.stalking = false
    self.waiting = true
    self:SetNWBool("IsWalking", false)
    self:SetNWBool("IsWatchingRagdoll", true)
    self:SetNWVector("RagdollPosition", ragdollPos)
    while true do
        local dirToRagdoll = (ragdollPos - self:GetPos()):GetNormalized()
        local angleToRagdoll = dirToRagdoll:Angle()
        self:SetAngles(Angle(0, angleToRagdoll.y, 0))
        for _, ply in ipairs(player.GetAll()) do
            if IsValid(ply) and ply:Alive() then
                self:SetNWBool("IsWatchingRagdoll", false)
                self:SetEnemy(ply)
                self:TeleportToRandom()
                return
            end
        end
        coroutine.yield()
    end
end
function ENT:ArePlayersAlive()
    local target = self:GetEnemy()
    if IsValid(target) and target:Alive() then
        return true
    end
    for _, ply in ipairs(player.GetAll()) do
        if ply:Alive() then
            return true
        end
    end
    return false
end
function ENT:Randomm()
    local pos = self:GetPos()
    local forward = self:GetForward()
    local maxHeight = 0
    for i = 0, 360, 45 do
        local rad = math.rad(i)
        local checkDir = Vector(math.cos(rad), math.sin(rad), 0)
        local traceStart = pos + checkDir * 30
        local trace = util.TraceLine({
            start = traceStart + Vector(0, 0, 5),
            endpos = traceStart + Vector(0, 0, -50),
            mask = MASK_SOLID_BRUSHONLY
        })
        if trace.Hit then
            local heightDiff = math.abs(trace.HitPos.z - pos.z)
            maxHeight = math.max(maxHeight, heightDiff)
        end
    end
    local baseHeight = math.Clamp(maxHeight + 10, 20, 65)
    local randomVariation = math.random(-5, 5)
    local finalStepHeight = math.Clamp(baseHeight + randomVariation, 20, 65)
    self.loco:SetStepHeight(finalStepHeight)
    local minBounds = Vector(math.random(-13, 2), math.random(-13, 2), 0)
    local maxBounds = Vector(math.random(13, -1), math.random(13, -1), math.random(72, -5))
    self:SetCollisionBounds(minBounds, maxBounds)
    self:PhysicsInitBox(Vector(-4, -4, 0), Vector(4, 4, 64))
    self:SetCollisionBounds(Vector(-1, -1, 0), Vector(1, 1, 1))
    self:SetCollisionGroup(COLLISION_GROUP_PASSABLE_DOOR)
end
function ENT:RandomCompute()
    self.lastRandomChange = self.lastRandomChange or CurTime()
    self.lastRandum = self.lastRandum or 0
    if CurTime() - self.lastRandomChange > 5 then
        local possibleRandoms = {1, 2, 3, 4}
        for i, v in ipairs(possibleRandoms) do
            if v == self.lastRandum then
                table.remove(possibleRandoms, i)
                break
            end
        end
        self.randum = possibleRandoms[math.random(#possibleRandoms)]
        self.lastRandum = self.randum
        self.lastRandomChange = CurTime()
    end
    local enemy = self:GetEnemy()
    if not IsValid(enemy) then return false end
    local pathOptions = {
        area_avoidance = true,
        repath = 0.5
    }
    local randum = self.randum or 1
    if randum == 1 then
        if self.RecordPlayerMovement then
            self:RecordPlayerMovement(enemy)
        end
        local predictedPos = self:PredictPlayerMovement(enemy)
        if predictedPos then
            self.path:Compute(self, predictedPos, pathOptions)
        end
    elseif randum == 2 then
        local landingPos = self:PredictLandingPosition(enemy)
        if landingPos then
            self.path:Compute(self, landingPos, pathOptions)
        else
            self.path:Compute(self, enemy:GetPos(), pathOptions)
        end
    elseif randum == 3 then
        local isFeint = self:DetectFeint(enemy)
        if isFeint then
            local altRoute = self:GetAlternativeRoute(enemy)
            if altRoute then
                self.path:Compute(self, altRoute, pathOptions)
            end
        else
            self.path:Compute(self, enemy:GetPos(), pathOptions)
        end
        self.loco:SetDesiredSpeed(self.speed * 1.2)
    else
        self.path:Compute(self, enemy:GetPos(), pathOptions)
    end
    return true
end
function ENT:RecomputeTargetPath(path_target)
    if not self.pathCheck then return end
    if CurTime() - self.LastPathingInfraction < 5 then return end
    local rTime = SysTime()
    self.path:Compute(self, path_target)
    if SysTime() - rTime > 0.005 then
        self.LastPathingInfraction = CurTime()
    end
end
function ENT:FindHidingSpot(enemy)
    if not IsValid(enemy) then return nil end
    local enemyPos = enemy:GetPos()
    local bestSpot = nil
    local bestScore = 0
    for i = 0, 360, 15 do
        local rad = math.rad(i)
        local checkDist = math.random(150, 400)
        local basePos = enemyPos + Vector(
            math.cos(rad) * checkDist,
            math.sin(rad) * checkDist,
            0
        )
        local objectTrace = util.TraceLine({
            start = basePos + Vector(0, 0, 80),
            endpos = basePos,
            mask = MASK_SOLID_BRUSHONLY
        })
        if objectTrace.Hit then
            local sidePos = objectTrace.HitPos + objectTrace.HitNormal * 30
            local peekTrace = util.TraceLine({
                start = sidePos + Vector(0, 0, 60),
                endpos = enemy:EyePos(),
                filter = {enemy, self},
                mask = MASK_SOLID_BRUSHONLY
            })
            if not peekTrace.Hit then
                local distScore = 1 - (sidePos:Distance(enemyPos) / 500)
                if distScore > bestScore then
                    bestScore = distScore
                    bestSpot = {
                        pos = sidePos,
                        normal = objectTrace.HitNormal
                    }
                end
            end
        end
    end
    return bestSpot
end
function ENT:GetRandomPosition()
    local pos = self:GetPos()
    local radius = math.random(500, 1000)
    local attempts = 0
    local maxAttempts = 20
    while attempts < maxAttempts do
        local angle = math.random() * math.pi * 2
        local randomPos = pos + Vector(
            math.cos(angle) * radius,
            math.sin(angle) * radius,
            0
        )
        local trace = util.TraceLine({
            start = randomPos + Vector(0, 0, 500),
            endpos = randomPos,
            mask = MASK_SOLID_BRUSHONLY
        })
        if trace.Hit then
            local groundPos = trace.HitPos + Vector(0, 0, 10)
            local headTrace = util.TraceLine({
                start = groundPos,
                endpos = groundPos + Vector(0, 0, 70),
                mask = MASK_SOLID_BRUSHONLY
            })
            if not headTrace.Hit then
                return groundPos
            end
        end
        attempts = attempts + 1
    end
    return nil
end
