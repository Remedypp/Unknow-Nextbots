local EnemiesModule = {}
EnemiesModule.isInitialized = false
EnemiesModule.enemyExists = false
EnemiesModule.enemyX = 0
EnemiesModule.enemyY = 0
EnemiesModule.enemyZ = 0
EnemiesModule.enemySize = 3
EnemiesModule.enemySpeed = 0.08
EnemiesModule.enemyNormalSpeed = 0.08
EnemiesModule.enemyFastSpeed = 0.25
EnemiesModule.fastSpeedDistance = 120
EnemiesModule.normalSpeedDistance = 50
EnemiesModule.enemyRotation = 0
EnemiesModule.enemyRotationX = 0
EnemiesModule.enemyRotationY = 0
EnemiesModule.enemyRotationZ = 0
EnemiesModule.enemyRotationSpeed = 15
EnemiesModule.enemyRotationSpeedX = 12
EnemiesModule.enemyRotationSpeedY = 18
EnemiesModule.enemyRotationSpeedZ = 8
EnemiesModule.enemySpawnChance = 0.40
EnemiesModule.chunkSize = 20
EnemiesModule.spawnTimer = 0
EnemiesModule.spawnDelay = 10
EnemiesModule.hasSpawned = false
EnemiesModule.spawnDistance = 50
EnemiesModule.enemyRings = {
    {
        rotationX = 0, rotationY = 0, rotationZ = 0,
        speedX = 25, speedY = -15, speedZ = 10,
        radius = 2.0, segments = 20, thickness = 0.1
    },
    {
        rotationX = 0, rotationY = 0, rotationZ = 0,
        speedX = -30, speedY = 20, speedZ = -25,
        radius = 1.7, segments = 18, thickness = 0.08
    },
    {
        rotationX = 0, rotationY = 0, rotationZ = 0,
        speedX = 15, speedY = -35, speedZ = 40,
        radius = 1.4, segments = 16, thickness = 0.06
    },
    {
        rotationX = 0, rotationY = 0, rotationZ = 0,
        speedX = -45, speedY = 50, speedZ = -20,
        radius = 1.1, segments = 14, thickness = 0.05
    }
}
EnemiesModule.eyeBlinkTimer = 0
EnemiesModule.aiState = "chase_player"
EnemiesModule.isPlayerSprinting = false
EnemiesModule.rectangleTarget = nil
EnemiesModule.raceSpeed = 0.15
EnemiesModule.lastPlayerSprintState = false
EnemiesModule.eyeIsBlinking = false
function EnemiesModule.spawnEnemy(x, y, getTerrainHeightAt)
    if not EnemiesModule.enemyExists then
        EnemiesModule.enemyExists = true
        EnemiesModule.enemyX = x
        EnemiesModule.enemyY = y
        EnemiesModule.enemyZ = getTerrainHeightAt(x, y) + EnemiesModule.enemySize * 0.5 + 5
        EnemiesModule.enemyRotation = 0
        EnemiesModule.enemyRotationX = 0
        EnemiesModule.enemyRotationY = 0
        EnemiesModule.enemyRotationZ = 0
        EnemiesModule.eyeBlinkTimer = 0
        EnemiesModule.eyeIsBlinking = false
        EnemiesModule.isSpawning = true
        EnemiesModule.spawnTime = CurTime()
        EnemiesModule.spawnDuration = 3.0
        EnemiesModule.spawnProgress = 0.0
        EnemiesModule.corruptionIntensity = 1.0
        for i = 1, #EnemiesModule.enemyRings do
            EnemiesModule.enemyRings[i].rotationX = 0
            EnemiesModule.enemyRings[i].rotationY = 0
            EnemiesModule.enemyRings[i].rotationZ = 0
        end
    end
end
function EnemiesModule.updateSpawnTimer(deltaTime, playerX, playerY, getTerrainHeightAt, isRectangleCorrupted)
    if isRectangleCorrupted then
        return
    end
    if not EnemiesModule.hasSpawned and not EnemiesModule.enemyExists then
        EnemiesModule.spawnTimer = EnemiesModule.spawnTimer + deltaTime
        if EnemiesModule.spawnTimer >= EnemiesModule.spawnDelay then
            local angle = math.random() * 2 * math.pi
            local spawnX = playerX + math.cos(angle) * EnemiesModule.spawnDistance
            local spawnY = playerY + math.sin(angle) * EnemiesModule.spawnDistance
            EnemiesModule.spawnEnemy(spawnX, spawnY, getTerrainHeightAt)
            EnemiesModule.hasSpawned = true
        end
    end
end
function EnemiesModule.resetSpawnSystem()
    EnemiesModule.spawnTimer = 0
    EnemiesModule.hasSpawned = false
    EnemiesModule.enemyExists = false
end
function EnemiesModule.updateEnemySpawnAnimation()
    if not EnemiesModule.enemyExists or not EnemiesModule.isSpawning then
        return
    end
    local currentTime = CurTime()
    local timeSinceSpawn = currentTime - EnemiesModule.spawnTime
    local progress = math.min(timeSinceSpawn / EnemiesModule.spawnDuration, 1.0)
    local easedProgress = 1 - math.pow(1 - progress, 2)
    EnemiesModule.spawnProgress = easedProgress
    EnemiesModule.corruptionIntensity = 1.0 - easedProgress
    if progress >= 1.0 then
        EnemiesModule.isSpawning = false
        EnemiesModule.corruptionIntensity = 0.0
    end
end
function EnemiesModule.updateEnemy(deltaTime, playerX, playerY, playerZ)
    EnemiesModule.updateEnemyWithSpeedMultiplier(deltaTime, playerX, playerY, playerZ, 1.0)
end
function EnemiesModule.updateEnemyWithSpeedMultiplier(deltaTime, playerX, playerY, playerZ, speedMultiplier)
    if not EnemiesModule.isInitialized then
        EnemiesModule.initialize()
    end
    if not EnemiesModule.enemyExists then return end
    EnemiesModule.updateEnemySpawnAnimation()
    speedMultiplier = speedMultiplier or 1.0
    EnemiesModule.enemyRotation = EnemiesModule.enemyRotation + EnemiesModule.enemyRotationSpeed * deltaTime * speedMultiplier
    EnemiesModule.enemyRotationX = EnemiesModule.enemyRotationX + EnemiesModule.enemyRotationSpeedX * deltaTime * speedMultiplier
    EnemiesModule.enemyRotationY = EnemiesModule.enemyRotationY + EnemiesModule.enemyRotationSpeedY * deltaTime * speedMultiplier
    EnemiesModule.enemyRotationZ = EnemiesModule.enemyRotationZ + EnemiesModule.enemyRotationSpeedZ * deltaTime * speedMultiplier
    for i = 1, #EnemiesModule.enemyRings do
        local ring = EnemiesModule.enemyRings[i]
        ring.rotationX = ring.rotationX + ring.speedX * deltaTime * speedMultiplier
        ring.rotationY = ring.rotationY + ring.speedY * deltaTime * speedMultiplier
        ring.rotationZ = ring.rotationZ + ring.speedZ * deltaTime * speedMultiplier
        if ring.rotationX >= 360 then ring.rotationX = ring.rotationX - 360 end
        if ring.rotationY >= 360 then ring.rotationY = ring.rotationY - 360 end
        if ring.rotationZ >= 360 then ring.rotationZ = ring.rotationZ - 360 end
    end
    if EnemiesModule.enemyRotation >= 360 then EnemiesModule.enemyRotation = EnemiesModule.enemyRotation - 360 end
    if EnemiesModule.enemyRotationX >= 360 then EnemiesModule.enemyRotationX = EnemiesModule.enemyRotationX - 360 end
    if EnemiesModule.enemyRotationY >= 360 then EnemiesModule.enemyRotationY = EnemiesModule.enemyRotationY - 360 end
    if EnemiesModule.enemyRotationZ >= 360 then EnemiesModule.enemyRotationZ = EnemiesModule.enemyRotationZ - 360 end
    local targetX, targetY, targetZ = playerX, playerY, playerZ
    local currentSpeed = EnemiesModule.enemyNormalSpeed
    if EnemiesModule.aiState == "chase_rectangle" and EnemiesModule.rectangleTarget then
        targetX = EnemiesModule.rectangleTarget.x
        targetY = EnemiesModule.rectangleTarget.y
        targetZ = EnemiesModule.rectangleTarget.z
        if EnemiesModule.isPlayerSprinting then
            currentSpeed = EnemiesModule.enemyFastSpeed
        else
            currentSpeed = EnemiesModule.raceSpeed
        end
    else
        local dx = playerX - EnemiesModule.enemyX
        local dy = playerY - EnemiesModule.enemyY
        local dz = playerZ - EnemiesModule.enemyZ
        local distance = math.sqrt(dx*dx + dy*dy + dz*dz)
        if distance > EnemiesModule.fastSpeedDistance then
            currentSpeed = EnemiesModule.enemyFastSpeed
        elseif distance <= EnemiesModule.normalSpeedDistance then
            currentSpeed = EnemiesModule.enemyNormalSpeed
        else
            local transitionFactor = (distance - EnemiesModule.normalSpeedDistance) /
                                   (EnemiesModule.fastSpeedDistance - EnemiesModule.normalSpeedDistance)
            currentSpeed = EnemiesModule.enemyNormalSpeed +
                          (EnemiesModule.enemyFastSpeed - EnemiesModule.enemyNormalSpeed) * transitionFactor
        end
    end
    local dx = targetX - EnemiesModule.enemyX
    local dy = targetY - EnemiesModule.enemyY
    local dz = targetZ - EnemiesModule.enemyZ
    local distance = math.sqrt(dx*dx + dy*dy + dz*dz)
    if distance > 0.1 then
        currentSpeed = currentSpeed * speedMultiplier
        EnemiesModule.enemySpeed = currentSpeed
        local moveX = (dx / distance) * currentSpeed
        local moveY = (dy / distance) * currentSpeed
        local moveZ = (dz / distance) * currentSpeed
        EnemiesModule.enemyX = EnemiesModule.enemyX + moveX
        EnemiesModule.enemyY = EnemiesModule.enemyY + moveY
        EnemiesModule.enemyZ = EnemiesModule.enemyZ + moveZ
    end
end
function EnemiesModule.shouldSpawnEnemyInChunk()
    return math.random() < EnemiesModule.enemySpawnChance
end
function EnemiesModule.getDistanceToPlayer(playerX, playerY, playerZ)
    if not EnemiesModule.enemyExists then
        return math.huge
    end
    local dx = playerX - EnemiesModule.enemyX
    local dy = playerY - EnemiesModule.enemyY
    local dz = playerZ - EnemiesModule.enemyZ
    return math.sqrt(dx*dx + dy*dy + dz*dz)
end
function EnemiesModule.getProximityIntensity(playerX, playerY, playerZ, maxDistance)
    if not EnemiesModule.enemyExists then
        return 0
    end
    maxDistance = maxDistance or 50
    local distance = EnemiesModule.getDistanceToPlayer(playerX, playerY, playerZ)
    local normalizedDistance = math.min(distance / maxDistance, 1)
    return 1 - normalizedDistance
end
function EnemiesModule.renderRing(ring, centerX, centerY, centerZ)
    local segments = ring.segments
    local radius = ring.radius
    local thickness = ring.thickness
    local rotX = math.rad(ring.rotationX)
    local rotY = math.rad(ring.rotationY)
    local rotZ = math.rad(ring.rotationZ)
    local cosX, sinX = math.cos(rotX), math.sin(rotX)
    local cosY, sinY = math.cos(rotY), math.sin(rotY)
    local cosZ, sinZ = math.cos(rotZ), math.sin(rotZ)
    local vertices = {}
    for i = 0, segments - 1 do
        local angle = (i / segments) * 2 * math.pi
        local x = radius * math.cos(angle)
        local y = radius * math.sin(angle)
        local z = 0
        local y1 = y * cosX - z * sinX
        local z1 = y * sinX + z * cosX
        y, z = y1, z1
        local x1 = x * cosY + z * sinY
        local z2 = -x * sinY + z * cosY
        x, z = x1, z2
        local x2 = x * cosZ - y * sinZ
        local y2 = x * sinZ + y * cosZ
        x, y = x2, y2
        vertices[i + 1] = Vector(centerX + x, centerY + y, centerZ + z)
    end
    render.SetColorMaterial()
    for i = 1, segments do
        local nextI = (i % segments) + 1
        local color = Color(255, 100 + math.sin(CurTime() * 2 + i) * 50, 255, 200)
        render.DrawLine(vertices[i], vertices[nextI], color, false)
    end
end
function EnemiesModule.renderEnemy()
    if not EnemiesModule.enemyExists then return end
    local enemyVertices = {}
    local baseVertices = {
        {-1, -1, -1}, {1, -1, -1}, {1, 1, -1}, {-1, 1, -1},
        {-1, -1, 1}, {1, -1, 1}, {1, 1, 1}, {-1, 1, 1}
    }
    local rotX = math.rad(EnemiesModule.enemyRotationX)
    local rotY = math.rad(EnemiesModule.enemyRotationY)
    local rotZ = math.rad(EnemiesModule.enemyRotationZ)
    local cosX, sinX = math.cos(rotX), math.sin(rotX)
    local cosY, sinY = math.cos(rotY), math.sin(rotY)
    local cosZ, sinZ = math.cos(rotZ), math.sin(rotZ)
    local corruptionFactor = EnemiesModule.corruptionIntensity or 0.0
    local spawnAlpha = 180
    if EnemiesModule.isSpawning then
        spawnAlpha = math.floor(180 * EnemiesModule.spawnProgress)
    end
    for i, vertex in ipairs(baseVertices) do
        local x = vertex[1] * EnemiesModule.enemySize
        local y = vertex[2] * EnemiesModule.enemySize
        local z = vertex[3] * EnemiesModule.enemySize
        if corruptionFactor > 0 then
            local noiseX = math.sin(CurTime() * 10 + i * 0.5) * corruptionFactor * 0.3
            local noiseY = math.cos(CurTime() * 8 + i * 0.7) * corruptionFactor * 0.3
            local noiseZ = math.sin(CurTime() * 12 + i * 0.3) * corruptionFactor * 0.3
            x = x + noiseX
            y = y + noiseY
            z = z + noiseZ
        end
        local y1 = y * cosX - z * sinX
        local z1 = y * sinX + z * cosX
        y, z = y1, z1
        local x1 = x * cosY + z * sinY
        local z2 = -x * sinY + z * cosY
        x, z = x1, z2
        local x2 = x * cosZ - y * sinZ
        local y2 = x * sinZ + y * cosZ
        x, y = x2, y2
        enemyVertices[i] = Vector(EnemiesModule.enemyX + x, EnemiesModule.enemyY + y, EnemiesModule.enemyZ + z)
    end
    render.SetColorMaterial()
    local baseRed, baseGreen, baseBlue = 255, 50, 50
    if corruptionFactor > 0 then
        local flickerR = math.sin(CurTime() * 15) * corruptionFactor * 100
        local flickerG = math.cos(CurTime() * 20) * corruptionFactor * 150
        local flickerB = math.sin(CurTime() * 25) * corruptionFactor * 200
        baseRed = math.max(0, math.min(255, baseRed + flickerR))
        baseGreen = math.max(0, math.min(255, baseGreen + flickerG))
        baseBlue = math.max(0, math.min(255, baseBlue + flickerB))
    end
    local enemyColor = Color(baseRed, baseGreen, baseBlue, spawnAlpha)
    local faces = {
        {1, 2, 3, 4}, {8, 7, 6, 5}, {1, 5, 6, 2},
        {3, 7, 8, 4}, {1, 4, 8, 5}, {2, 6, 7, 3}
    }
    for _, face in ipairs(faces) do
        render.DrawQuad(enemyVertices[face[1]], enemyVertices[face[2]],
                       enemyVertices[face[3]], enemyVertices[face[4]], enemyColor)
    end
    for _, ring in ipairs(EnemiesModule.enemyRings) do
        EnemiesModule.renderRing(ring, EnemiesModule.enemyX, EnemiesModule.enemyY, EnemiesModule.enemyZ)
    end
end
function EnemiesModule.removeEnemy()
    EnemiesModule.enemyExists = false
    EnemiesModule.enemyX = 0
    EnemiesModule.enemyY = 0
    EnemiesModule.enemyZ = 0
end
function EnemiesModule.getEnemyInfo()
    return {
        exists = EnemiesModule.enemyExists,
        x = EnemiesModule.enemyX,
        y = EnemiesModule.enemyY,
        z = EnemiesModule.enemyZ,
        size = EnemiesModule.enemySize,
        rotation = EnemiesModule.enemyRotation,
        rotationX = EnemiesModule.enemyRotationX,
        rotationY = EnemiesModule.enemyRotationY,
        rotationZ = EnemiesModule.enemyRotationZ
    }
end
function EnemiesModule.setEnemyProperties(properties)
    if properties.speed then EnemiesModule.enemySpeed = properties.speed end
    if properties.size then EnemiesModule.enemySize = properties.size end
    if properties.spawnChance then EnemiesModule.enemySpawnChance = properties.spawnChance end
    if properties.rotationSpeed then EnemiesModule.enemyRotationSpeed = properties.rotationSpeed end
    if properties.rotationSpeedX then EnemiesModule.enemyRotationSpeedX = properties.rotationSpeedX end
    if properties.rotationSpeedY then EnemiesModule.enemyRotationSpeedY = properties.rotationSpeedY end
    if properties.rotationSpeedZ then EnemiesModule.enemyRotationSpeedZ = properties.rotationSpeedZ end
end
function EnemiesModule.initialize()
    if EnemiesModule.isInitialized then return end
    EnemiesModule.enemyExists = false
    EnemiesModule.enemyX = 0
    EnemiesModule.enemyY = 0
    EnemiesModule.enemyZ = 0
    EnemiesModule.enemyRotation = 0
    EnemiesModule.enemyRotationX = 0
    EnemiesModule.enemyRotationY = 0
    EnemiesModule.enemyRotationZ = 0
    EnemiesModule.spawnTimer = 0
    EnemiesModule.hasSpawned = false
    EnemiesModule.eyeBlinkTimer = 0
    EnemiesModule.eyeIsBlinking = false
    EnemiesModule.isSpawning = false
    EnemiesModule.spawnTime = 0
    EnemiesModule.spawnProgress = 0.0
    EnemiesModule.corruptionIntensity = 0.0
    for i = 1, #EnemiesModule.enemyRings do
        EnemiesModule.enemyRings[i].rotationX = 0
        EnemiesModule.enemyRings[i].rotationY = 0
        EnemiesModule.enemyRings[i].rotationZ = 0
    end
    EnemiesModule.aiState = "chase_player"
    EnemiesModule.isPlayerSprinting = false
    EnemiesModule.rectangleTarget = nil
    EnemiesModule.lastPlayerSprintState = false
    EnemiesModule.isInitialized = true
end
function EnemiesModule.reset()
    EnemiesModule.isInitialized = false
    EnemiesModule.initialize()
end
function EnemiesModule.updatePlayerSprintState(isPlayerSprinting)
    EnemiesModule.isPlayerSprinting = isPlayerSprinting
    EnemiesModule.lastPlayerSprintState = isPlayerSprinting
end
function EnemiesModule.updateRectangleState(whiteRectangle)
    if whiteRectangle then
        EnemiesModule.rectangleTarget = {
            x = whiteRectangle.x,
            y = whiteRectangle.y,
            z = whiteRectangle.z
        }
        EnemiesModule.aiState = "chase_rectangle"
    else
        EnemiesModule.rectangleTarget = nil
        EnemiesModule.aiState = "chase_player"
    end
end
function EnemiesModule.updateAI(isPlayerSprinting, whiteRectangle)
    if not EnemiesModule.enemyExists then return end
    EnemiesModule.updatePlayerSprintState(isPlayerSprinting)
    EnemiesModule.updateRectangleState(whiteRectangle)
end
function EnemiesModule.getAIState()
    return {
        aiState = EnemiesModule.aiState,
        isPlayerSprinting = EnemiesModule.isPlayerSprinting,
        hasRectangleTarget = EnemiesModule.rectangleTarget ~= nil,
        rectangleTarget = EnemiesModule.rectangleTarget
    }
end
function EnemiesModule.handleRectangleCorruption()
    if not EnemiesModule.enemyExists then return false end
    local ringsToTransfer = {}
    for i, ring in ipairs(EnemiesModule.enemyRings) do
        ringsToTransfer[i] = {
            rotationX = ring.rotationX,
            rotationY = ring.rotationY,
            rotationZ = ring.rotationZ,
            speedX = ring.speedX,
            speedY = ring.speedY,
            speedZ = ring.speedZ,
            radius = ring.radius,
            segments = ring.segments,
            thickness = ring.thickness
        }
    end
    EnemiesModule.enemyExists = false
    EnemiesModule.aiState = "chase_player"
    EnemiesModule.rectangleTarget = nil
    EnemiesModule.spawnTimer = 0
    EnemiesModule.hasSpawned = false
    return ringsToTransfer
end
function EnemiesModule.getEnemyPosition()
    if not EnemiesModule.enemyExists then return nil end
    return {
        x = EnemiesModule.enemyX,
        y = EnemiesModule.enemyY,
        z = EnemiesModule.enemyZ,
        size = EnemiesModule.enemySize
    }
end
function EnemiesModule.getOrbitalRings()
    if not EnemiesModule.enemyExists then return {} end
    local ringsToTransfer = {}
    for i, ring in ipairs(EnemiesModule.enemyRings) do
        ringsToTransfer[i] = {
            rotationX = ring.rotationX,
            rotationY = ring.rotationY,
            rotationZ = ring.rotationZ,
            speedX = ring.speedX,
            speedY = ring.speedY,
            speedZ = ring.speedZ,
            radius = ring.radius,
            segments = ring.segments,
            thickness = ring.thickness
        }
    end
    return ringsToTransfer
end
return EnemiesModule
