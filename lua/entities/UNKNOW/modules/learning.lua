local ENT = ENT
function ENT:InitializeLearningSystem()
    self.learningData = {
        playerPatterns = {},
        escapeRoutes = {},
        commonSpots = {},
        successfulTactics = {},
        lastAnalysis = 0,
        analysisCooldown = 5
    }
    self.playerMovementHistory = {}
    self.lastPlayerPos = Vector(0, 0, 0)
    self.predictedPosition = Vector(0, 0, 0)
end
function ENT:UpdateLearningSystem()
    if CurTime() - self.learningData.lastAnalysis < self.learningData.analysisCooldown then
        return
    end
    local enemy = self:GetEnemy()
    if not IsValid(enemy) then return end
    self:AnalyzePlayerMovement(enemy)
    self:UpdateEscapeRoutes(enemy)
    self:UpdateSuccessfulTactics()
    self.learningData.lastAnalysis = CurTime()
end
function ENT:AnalyzePlayerMovement(player)
    if not IsValid(player) then return end
    local pos = player:GetPos()
    local vel = player:GetVelocity()
    table.insert(self.learningData.playerPatterns, {
        pos = pos,
        vel = vel,
        time = CurTime()
    })
    if #self.learningData.playerPatterns > 20 then
        table.remove(self.learningData.playerPatterns, 1)
    end
    self:AnalyzePatterns()
end
function ENT:UpdateEscapeRoutes(player)
    if not IsValid(player) then return end
    if not self.lastPlayerPos or self.lastPlayerPos:LengthSqr() == 0 then
        self.lastPlayerPos = player:GetPos()
        return
    end
    local currentPos = player:GetPos()
    local distance = self:GetPos():Distance(currentPos)
    if distance > self:GetPos():Distance(self.lastPlayerPos) then
        table.insert(self.learningData.escapeRoutes, {
            start = self.lastPlayerPos,
            direction = (currentPos - self.lastPlayerPos):GetNormalized(),
            success = true
        })
        if #self.learningData.escapeRoutes > 10 then
            table.remove(self.learningData.escapeRoutes, 1)
        end
    end
    self.lastPlayerPos = currentPos
end
function ENT:AnalyzePatterns()
    if #self.learningData.playerPatterns < 5 then return end
    local patterns = {}
    for i = 1, #self.learningData.playerPatterns - 1 do
        local current = self.learningData.playerPatterns[i]
        local next = self.learningData.playerPatterns[i + 1]
        if current and next then
            local moveDir = (next.pos - current.pos):GetNormalized()
            local pattern = {
                direction = moveDir,
                speed = current.vel:Length(),
                time = next.time
            }
            table.insert(patterns, pattern)
        end
    end
    self:UpdateTacticsBasedOnPatterns(patterns)
end
function ENT:UpdateTacticsBasedOnPatterns(patterns)
    local commonPatterns = {}
    for _, pattern in ipairs(patterns) do
        local patternKey = string.format("%.2f,%.2f,%.2f",
            pattern.direction.x,
            pattern.direction.y,
            pattern.speed
        )
        commonPatterns[patternKey] = (commonPatterns[patternKey] or 0) + 1
    end
    for pattern, count in pairs(commonPatterns) do
        if count > 3 then
            self.learningData.successfulTactics[pattern] = {
                count = count,
                lastSuccess = CurTime()
            }
        end
    end
end
function ENT:UpdateSuccessfulTactics()
    local now = CurTime()
    for pattern, data in pairs(self.learningData.successfulTactics) do
        if now - data.lastSuccess > 300 then
            self.learningData.successfulTactics[pattern] = nil
        end
    end
end
function ENT:CalculatePatternCost(areaCenter)
    local cost = 1.0
    for _, pattern in ipairs(self.learningData.playerPatterns) do
        local dist = areaCenter:Distance(pattern.pos)
        if dist < 200 then
            cost = cost * 0.8
        end
    end
    return cost
end
function ENT:PredictPlayerMovement(player)
    if not IsValid(player) then return player and player:GetPos() or self:GetPos() end
    if #self.playerMovementHistory < 2 then
        return player:GetPos()
    end
    local velocitySum = Vector(0, 0, 0)
    local count = 0
    for i = 1, #self.playerMovementHistory - 1 do
        local current = self.playerMovementHistory[i]
        local next = self.playerMovementHistory[i + 1]
        if current and next then
            local moveVec = (next.pos - current.pos)
            velocitySum = velocitySum + moveVec
            count = count + 1
        end
    end
    if count == 0 then return player:GetPos() end
    local avgVelocity = velocitySum / count
    return player:GetPos() + (avgVelocity * 0.5)
end
function ENT:PredictLandingPosition(player)
    if not IsValid(player) then return nil end
    local pos = player:GetPos()
    local vel = player:GetVelocity()
    if player:IsOnGround() or vel.z >= 0 then
        return nil
    end
    local trace = util.TraceLine({
        start = pos,
        endpos = pos + Vector(0, 0, -1000),
        filter = player,
        mask = MASK_SOLID_BRUSHONLY
    })
    if trace.Hit then
        return trace.HitPos + Vector(0, 0, 10)
    end
    return nil
end
function ENT:DetectFeint(player)
    if not IsValid(player) then return false end
    if #self.playerMovementHistory < 3 then return false end
    local angleChanges = 0
    for i = 1, #self.playerMovementHistory - 1 do
        local current = self.playerMovementHistory[i]
        local next = self.playerMovementHistory[i + 1]
        if current and next then
            local dir1 = (next.pos - current.pos):GetNormalized()
            local dir2 = next.vel:GetNormalized()
            if dir1:LengthSqr() > 0 and dir2:LengthSqr() > 0 then
                local angle = math.deg(math.acos(math.Clamp(dir1:Dot(dir2), -1, 1)))
                if angle > 90 then
                    angleChanges = angleChanges + 1
                end
            end
        end
    end
    return angleChanges >= 2
end
function ENT:GetAlternativeRoute(player)
    if not IsValid(player) then return self:GetPos() end
    local currentPos = player:GetPos()
    local possibleRoutes = {}
    for i = 0, 360, 45 do
        local rad = math.rad(i)
        local checkPos = currentPos + Vector(
            math.cos(rad) * 200,
            math.sin(rad) * 200,
            0
        )
        local trace = util.TraceLine({
            start = checkPos + Vector(0, 0, 50),
            endpos = checkPos,
            mask = MASK_SOLID_BRUSHONLY
        })
        if trace.Hit then
            table.insert(possibleRoutes, trace.HitPos + Vector(0, 0, 10))
        end
    end
    if #possibleRoutes > 0 then
        table.sort(possibleRoutes, function(a, b)
            return self:GetPos():Distance(a) < self:GetPos():Distance(b)
        end)
        return possibleRoutes[1]
    end
    return currentPos
end
function ENT:RecordPlayerMovement(player)
    if not IsValid(player) then return end
    table.insert(self.playerMovementHistory, {
        pos = player:GetPos(),
        vel = player:GetVelocity(),
        time = CurTime()
    })
    if #self.playerMovementHistory > 10 then
        table.remove(self.playerMovementHistory, 1)
    end
end
