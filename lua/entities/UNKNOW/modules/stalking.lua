local ENT = ENT
function ENT:InitializeStalkingSystem()
    self.stalkingData = {
        lastStalkPosition = Vector(0, 0, 0),
        stalkingTime = 0,
        stalkStartTime = 0,
        minStalkTime = 10,
        maxStalkTime = 30,
        lastVisibleCheck = 0,
        visibilityCheckInterval = 0.5,
        wasVisible = false,
        visibleCount = 0,
        stalkingDistance = {min = 300, max = 1000},
        preferredDistance = 500,
        isCurrentlyStalking = false,
        stalkPhase = 1,
        lastBehindCheck = 0,
        behindCheckInterval = 2,
        appearBehindChance = 15
    }
end
function ENT:StartStalking()
    if not self.stalkingData then
        self:InitializeStalkingSystem()
    end
    self.stalkingData.isCurrentlyStalking = true
    self.stalkingData.stalkStartTime = CurTime()
    self.stalkingData.stalkingTime = math.random(
        self.stalkingData.minStalkTime,
        self.stalkingData.maxStalkTime
    )
    self.stalkingData.stalkPhase = 1
    self.stalking = true
    self.chasing = false
    self.walking = true
end
function ENT:StopStalking()
    if not self.stalkingData then return end
    self.stalkingData.isCurrentlyStalking = false
    self.stalking = false
end
function ENT:UpdateStalking()
    if not self.stalkingData then
        self:InitializeStalkingSystem()
    end
    if not self.stalkingData.isCurrentlyStalking then return end
    local ct = CurTime()
    local enemy = self:GetEnemy()
    if not IsValid(enemy) then
        self:StopStalking()
        return
    end
    local elapsed = ct - self.stalkingData.stalkStartTime
    if elapsed > self.stalkingData.stalkingTime then
        if math.random(1, 100) <= 60 then
            self:StopStalking()
            self.chasing = true
            return
        else
            self.stalkingData.stalkStartTime = ct
            self.stalkingData.stalkingTime = math.random(
                self.stalkingData.minStalkTime,
                self.stalkingData.maxStalkTime
            )
        end
    end
    self:CheckStalkVisibility(enemy)
    self:UpdateStalkPhase(enemy)
    self:TryAppearBehind(enemy)
end
function ENT:CheckStalkVisibility(enemy)
    local ct = CurTime()
    if ct - self.stalkingData.lastVisibleCheck < self.stalkingData.visibilityCheckInterval then
        return
    end
    self.stalkingData.lastVisibleCheck = ct
    local isVisible = self:IsVisibleToPlayer(enemy)
    if isVisible then
        self.stalkingData.visibleCount = self.stalkingData.visibleCount + 1
        if self.stalkingData.visibleCount > 3 then
            if self.TeleportToRandom then
                self:TeleportToRandom()
            end
            self.stalkingData.visibleCount = 0
        end
    else
        self.stalkingData.visibleCount = math.max(0, self.stalkingData.visibleCount - 1)
    end
    self.stalkingData.wasVisible = isVisible
end
function ENT:UpdateStalkPhase(enemy)
    local dist = self:GetPos():Distance(enemy:GetPos())
    if dist > self.stalkingData.stalkingDistance.max then
        self.stalkingData.stalkPhase = 1
    elseif dist > self.stalkingData.stalkingDistance.min then
        self.stalkingData.stalkPhase = 2
    else
        self.stalkingData.stalkPhase = 3
    end
end
function ENT:TryAppearBehind(enemy)
    local ct = CurTime()
    if ct - self.stalkingData.lastBehindCheck < self.stalkingData.behindCheckInterval then
        return
    end
    self.stalkingData.lastBehindCheck = ct
    if math.random(1, 100) <= self.stalkingData.appearBehindChance then
        local behindPos = self:GetPositionBehindPlayer(enemy)
        if behindPos then
            local trace = util.TraceLine({
                start = behindPos + Vector(0, 0, 50),
                endpos = behindPos,
                filter = self,
                mask = MASK_SOLID_BRUSHONLY
            })
            if trace.Hit then
                self:SetPos(trace.HitPos + Vector(0, 0, 5))
            end
        end
    end
end
function ENT:GetPositionBehindPlayer(player)
    if not IsValid(player) then return nil end
    local playerPos = player:GetPos()
    local playerForward = player:EyeAngles():Forward()
    local distance = math.random(150, 300)
    local behindPos = playerPos - (playerForward * distance)
    behindPos = behindPos + Vector(
        math.random(-50, 50),
        math.random(-50, 50),
        0
    )
    local groundTrace = util.TraceLine({
        start = behindPos + Vector(0, 0, 100),
        endpos = behindPos - Vector(0, 0, 100),
        mask = MASK_SOLID_BRUSHONLY
    })
    if groundTrace.Hit then
        return groundTrace.HitPos
    end
    return nil
end
function ENT:IsVisibleToPlayer(player)
    if not IsValid(player) then return false end
    local playerEyePos = player:EyePos()
    local playerForward = player:EyeAngles():Forward()
    local toEntity = (self:GetPos() + Vector(0, 0, 50) - playerEyePos):GetNormalized()
    local dot = playerForward:Dot(toEntity)
    if dot < 0.5 then
        return false
    end
    local trace = util.TraceLine({
        start = playerEyePos,
        endpos = self:GetPos() + Vector(0, 0, 50),
        filter = {self, player},
        mask = MASK_SHOT
    })
    return not trace.Hit
end
function ENT:GetPreferredStalkPosition(enemy)
    if not IsValid(enemy) then return nil end
    local enemyPos = enemy:GetPos()
    local enemyForward = enemy:EyeAngles():Forward()
    local angles = {90, -90, 135, -135, 180}
    local bestPos = nil
    local bestScore = 0
    for _, ang in ipairs(angles) do
        local rotated = Angle(0, ang, 0):Forward()
        rotated = (enemyForward + rotated):GetNormalized()
        local testPos = enemyPos + rotated * self.stalkingData.preferredDistance
        local groundTrace = util.TraceLine({
            start = testPos + Vector(0, 0, 100),
            endpos = testPos - Vector(0, 0, 100),
            mask = MASK_SOLID_BRUSHONLY
        })
        if groundTrace.Hit then
            testPos = groundTrace.HitPos
            local visTrace = util.TraceLine({
                start = enemy:EyePos(),
                endpos = testPos + Vector(0, 0, 50),
                filter = {self, enemy},
                mask = MASK_SHOT
            })
            local score = visTrace.Hit and 10 or 0
            score = score + (180 - math.abs(ang)) / 20
            if score > bestScore then
                bestScore = score
                bestPos = testPos
            end
        end
    end
    return bestPos
end
