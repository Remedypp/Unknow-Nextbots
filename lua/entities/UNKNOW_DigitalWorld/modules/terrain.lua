local TerrainModule = {}
TerrainModule.isInitialized = false
TerrainModule.terrainHeight = 1.5
TerrainModule.noiseScale = 0.08
TerrainModule.chunkWidth = 16
TerrainModule.chunkLength = 24
TerrainModule.chunkResolution = 0.3
TerrainModule.renderRadius = 3
TerrainModule.lodDistance1 = 1
TerrainModule.lodDistance2 = 2
TerrainModule.visibilityRadius = 80
TerrainModule.enableCircularVisibility = true
TerrainModule.terrainChunks = {}
TerrainModule.chunkPool = {}
TerrainModule.lastPlayerChunkX = nil
TerrainModule.lastPlayerChunkY = nil
TerrainModule.whiteRectangle = nil
TerrainModule.rectangleParticles = {}
TerrainModule.nextRectangleSpawnTime = nil
TerrainModule.rectangleLifetime = 15
TerrainModule.rectangleSpawnDelay = {min = 30, max = 80}
TerrainModule.gameStartTime = nil
TerrainModule.rectangleProbabilityCheck = {
    interval = 5.0,
    probability = 0.15,
    nextCheckTime = nil,
    canSpawn = false,
    isWaitingToSpawn = false
}
function TerrainModule.terrainNoise(x, y)
    local height = 0
    local amplitude = 1
    local frequency = 1
    local maxValue = 0
    for i = 1, 3 do
        local seed = (x * frequency) * 12.9898 + (y * frequency) * 78.233
        local noise = math.sin(seed) * 43758.5453
        noise = noise - math.floor(noise)
        noise = (noise - 0.5) * 2
        height = height + noise * amplitude
        maxValue = maxValue + amplitude
        amplitude = amplitude * 0.5
        frequency = frequency * 2
    end
    height = height / maxValue
    return height * TerrainModule.terrainHeight
end
function TerrainModule.getTerrainHeightAt(worldX, worldY)
    return TerrainModule.terrainNoise(worldX * TerrainModule.noiseScale, worldY * TerrainModule.noiseScale) - 1
end
function TerrainModule.calculateEquidistantPosition(playerX, playerY, enemyX, enemyY)
    if not enemyX or not enemyY then
        local spawnDistance = math.random(80, 120)
        local spawnAngle = math.random() * math.pi * 2
        return playerX + math.cos(spawnAngle) * spawnDistance, playerY + math.sin(spawnAngle) * spawnDistance
    end
    local minDistanceFromPlayer = 70
    local minDistanceFromEnemy = 25
    local maxAttempts = 20
    local dx = enemyX - playerX
    local dy = enemyY - playerY
    local distance = math.sqrt(dx * dx + dy * dy)
    local function isValidPosition(x, y)
        local distFromPlayer = math.sqrt((x - playerX)^2 + (y - playerY)^2)
        local distFromEnemy = math.sqrt((x - enemyX)^2 + (y - enemyY)^2)
        return distFromPlayer >= minDistanceFromPlayer and distFromEnemy >= minDistanceFromEnemy
    end
    for attempt = 1, maxAttempts do
        local rectX, rectY
        if distance < 50 then
            local perpX = -dy / distance
            local perpY = dx / distance
            local offsetDistance = math.random(80, 120)
            local direction = math.random() > 0.5 and 1 or -1
            local midX = (playerX + enemyX) / 2
            local midY = (playerY + enemyY) / 2
            rectX = midX + perpX * offsetDistance * direction
            rectY = midY + perpY * offsetDistance * direction
        else
            local t = math.random(0.6, 0.9)
            local baseX = playerX + (enemyX - playerX) * t
            local baseY = playerY + (enemyY - playerY) * t
            local offsetDistance = math.random(30, 50)
            local offsetAngle = math.random() * math.pi * 2
            rectX = baseX + math.cos(offsetAngle) * offsetDistance
            rectY = baseY + math.sin(offsetAngle) * offsetDistance
        end
        if isValidPosition(rectX, rectY) then
            return rectX, rectY
        end
    end
    local directionAwayFromEnemy = math.atan2(playerY - enemyY, playerX - enemyX)
    local emergencyDistance = math.max(minDistanceFromPlayer + 20, 90)
    local rectX = playerX + math.cos(directionAwayFromEnemy) * emergencyDistance
    local rectY = playerY + math.sin(directionAwayFromEnemy) * emergencyDistance
    return rectX, rectY
end
function TerrainModule.createWhiteRectangle(worldX, worldY)
    local terrainHeight = TerrainModule.getTerrainHeightAt(worldX, worldY)
    local currentTime = CurTime()
    TerrainModule.whiteRectangle = {
        x = worldX,
        y = worldY,
        z = terrainHeight - 2,
        width = 4,
        height = 8,
        depth = 0.5,
        visualWidth = 3,
        visualHeight = 8,
        visualDepth = 0.5,
        baseScale = 1.2,
        maxScale = 3.0,
        scaleDistance = 15,
        lastParticleSpawn = 0,
        spawnTime = currentTime,
        despawnTime = currentTime + TerrainModule.rectangleLifetime,
        isSpawning = true,
        spawnDuration = 2.0,
        isTouchedByEnemy = false,
        isBloodRed = false,
        colorTransitionTime = 0,
        colorTransitionDuration = 1.0,
        bloodRedColor = {255, 0, 0},
        originalColor = {255, 255, 255},
        spawnProgress = 0.0,
        centerY = terrainHeight + 2 + 4
    }
    TerrainModule.rectangleParticles = {}
    for i = 1, 8 do
        table.insert(TerrainModule.rectangleParticles, {
            x = worldX + math.random(-1, 1),
            y = worldY + math.random(-1, 1),
            z = terrainHeight + math.random(2, 10),
            vx = math.random(-0.5, 0.5),
            vy = math.random(-0.5, 0.5),
            vz = math.random(0.1, 0.8),
            life = math.random(2, 5),
            maxLife = math.random(2, 5),
            size = math.random(0.5, 1.5)
        })
    end
end
function TerrainModule.checkRectangleCollision(playerX, playerY, playerZ, playerSize)
    if not TerrainModule.whiteRectangle then return false end
    local rect = TerrainModule.whiteRectangle
    local halfPlayerSize = playerSize * 0.5
    local halfRectWidth = rect.width * 0.5
    local halfRectDepth = rect.depth * 0.5
    local collisionMultiplier = 1.0
    if rect.isChasing then
        collisionMultiplier = 2.0
    end
    local expandedRectWidth = halfRectWidth * collisionMultiplier
    local expandedRectDepth = halfRectDepth * collisionMultiplier
    local expandedRectHeight = rect.height * collisionMultiplier
    local collisionX = (playerX + halfPlayerSize >= rect.x - expandedRectWidth) and
                      (playerX - halfPlayerSize <= rect.x + expandedRectWidth)
    local collisionY = (playerY + halfPlayerSize >= rect.y - expandedRectDepth) and
                      (playerY - halfPlayerSize <= rect.y + expandedRectDepth)
    local collisionZ = (playerZ + halfPlayerSize >= rect.z - expandedRectHeight * 0.5) and
                      (playerZ - halfPlayerSize <= rect.z + expandedRectHeight)
    return collisionX and collisionY and collisionZ
end
function TerrainModule.updateRectangleVisualScale(playerX, playerY, playerZ)
    if not TerrainModule.whiteRectangle then return end
    local rect = TerrainModule.whiteRectangle
    if rect.isCorrupted then
        rect.visualWidth = rect.width * rect.baseScale
        rect.visualHeight = rect.height * rect.baseScale
        rect.visualDepth = rect.depth * rect.baseScale
        return
    end
    local dx = playerX - rect.x
    local dy = playerY - rect.y
    local dz = playerZ - rect.z
    local distance = math.sqrt(dx * dx + dy * dy + dz * dz)
    local scale = rect.baseScale
    if distance <= rect.scaleDistance then
        local distanceRatio = 1 - (distance / rect.scaleDistance)
        scale = rect.baseScale + (rect.maxScale - rect.baseScale) * distanceRatio
        local pulseEffect = 1 + math.sin(CurTime() * 3) * 0.1 * distanceRatio
        scale = scale * pulseEffect
    end
    rect.visualWidth = rect.width * scale
    rect.visualHeight = rect.height * scale
    rect.visualDepth = rect.depth * scale
end
function TerrainModule.updateRectangleParticles(deltaTime)
    if not TerrainModule.whiteRectangle then return end
    local rect = TerrainModule.whiteRectangle
    for i = #TerrainModule.rectangleParticles, 1, -1 do
        local particle = TerrainModule.rectangleParticles[i]
        particle.x = particle.x + particle.vx * deltaTime
        particle.y = particle.y + particle.vy * deltaTime
        particle.z = particle.z + particle.vz * deltaTime
        particle.life = particle.life - deltaTime
        if particle.life <= 0 then
            table.remove(TerrainModule.rectangleParticles, i)
        end
    end
    if CurTime() - rect.lastParticleSpawn > 0.5 then
        if #TerrainModule.rectangleParticles < 8 then
            table.insert(TerrainModule.rectangleParticles, {
                x = rect.x + math.random(-1, 1),
                y = rect.y + math.random(-1, 1),
                z = rect.z + math.random(0, rect.height),
                vx = math.random(-0.5, 0.5),
                vy = math.random(-0.5, 0.5),
                vz = math.random(0.1, 0.8),
                life = math.random(2, 5),
                maxLife = math.random(2, 5),
                size = math.random(0.5, 1.5)
            })
        end
        rect.lastParticleSpawn = CurTime()
    end
end
function TerrainModule.initializeRectangleSystem()
    if TerrainModule.gameStartTime == nil then
        TerrainModule.gameStartTime = CurTime()
        local probCheck = TerrainModule.rectangleProbabilityCheck
        if not probCheck.nextCheckTime then
            probCheck.nextCheckTime = TerrainModule.gameStartTime + probCheck.interval
            probCheck.canSpawn = false
            probCheck.isWaitingToSpawn = false
        end
    end
end
function TerrainModule.removeWhiteRectangle()
    TerrainModule.whiteRectangle = nil
    TerrainModule.rectangleParticles = {}
end
function TerrainModule.updateRectangleSpawnAnimation()
    if not TerrainModule.whiteRectangle or not TerrainModule.whiteRectangle.isSpawning then
        return
    end
    local currentTime = CurTime()
    local timeSinceSpawn = currentTime - TerrainModule.whiteRectangle.spawnTime
    local progress = math.min(timeSinceSpawn / TerrainModule.whiteRectangle.spawnDuration, 1.0)
    local easedProgress = 1 - math.pow(1 - progress, 3)
    TerrainModule.whiteRectangle.spawnProgress = easedProgress
    if progress >= 1.0 then
        TerrainModule.whiteRectangle.isSpawning = false
    end
end
function TerrainModule.updateRectangleTiming(playerX, playerY, enemyX, enemyY, enemyExists)
    if not TerrainModule.isInitialized then
        TerrainModule.initialize()
    end
    TerrainModule.initializeRectangleSystem()
    local currentTime = CurTime()
    local probCheck = TerrainModule.rectangleProbabilityCheck
    if not probCheck.nextCheckTime then
        probCheck.nextCheckTime = currentTime + probCheck.interval
    end
    if TerrainModule.whiteRectangle then
        TerrainModule.updateRectangleSpawnAnimation()
    end
    if TerrainModule.whiteRectangle and currentTime >= TerrainModule.whiteRectangle.despawnTime and not TerrainModule.whiteRectangle.isCorrupted then
        TerrainModule.removeWhiteRectangle()
        probCheck.canSpawn = false
        probCheck.isWaitingToSpawn = false
        probCheck.nextCheckTime = currentTime + probCheck.interval
    end
    if not TerrainModule.whiteRectangle and not probCheck.isWaitingToSpawn and currentTime >= probCheck.nextCheckTime and enemyExists then
        local randomValue = math.random()
        if randomValue <= probCheck.probability then
            probCheck.canSpawn = true
            probCheck.isWaitingToSpawn = true
        end
        probCheck.nextCheckTime = currentTime + probCheck.interval
    end
    if not TerrainModule.whiteRectangle and probCheck.canSpawn and probCheck.isWaitingToSpawn and enemyExists then
        local rectX, rectY = TerrainModule.calculateEquidistantPosition(playerX, playerY, enemyX, enemyY)
        TerrainModule.createWhiteRectangle(rectX, rectY)
        probCheck.canSpawn = false
        probCheck.isWaitingToSpawn = false
    end
    if TerrainModule.whiteRectangle and not enemyExists and not TerrainModule.whiteRectangle.isCorrupted then
        TerrainModule.removeWhiteRectangle()
        probCheck.canSpawn = false
        probCheck.isWaitingToSpawn = false
        probCheck.nextCheckTime = currentTime + probCheck.interval
    end
end
function TerrainModule.getChunkCoords(worldX, worldY)
    return math.floor(worldX / TerrainModule.chunkWidth), math.floor(worldY / TerrainModule.chunkLength)
end
function TerrainModule.generateTerrainChunk(chunkX, chunkY, playerChunkX, playerChunkY)
    local distance = math.max(math.abs(chunkX - playerChunkX), math.abs(chunkY - playerChunkY))
    local resolution = TerrainModule.chunkResolution
    if distance >= TerrainModule.lodDistance2 then
        resolution = math.max(1, TerrainModule.chunkResolution)
    elseif distance >= TerrainModule.lodDistance1 then
        resolution = math.max(1, TerrainModule.chunkResolution - 1)
    end
    local chunk = table.remove(TerrainModule.chunkPool)
    if not chunk then
        chunk = {
            vertices = {},
            triangles = {}
        }
    else
        table.Empty(chunk.vertices)
        table.Empty(chunk.triangles)
    end
    chunk.x = chunkX
    chunk.y = chunkY
    chunk.lod = resolution
    local vertexIndex = 1
    for i = 0, resolution do
        for j = 0, resolution do
            local worldX = chunkX * TerrainModule.chunkWidth + (i / resolution) * TerrainModule.chunkWidth
            local worldY = chunkY * TerrainModule.chunkLength + (j / resolution) * TerrainModule.chunkLength
            local height = TerrainModule.terrainNoise(worldX * TerrainModule.noiseScale, worldY * TerrainModule.noiseScale)
            chunk.vertices[vertexIndex] = Vector(worldX, worldY, height - 1)
            vertexIndex = vertexIndex + 1
        end
    end
    for i = 0, resolution - 1 do
        for j = 0, resolution - 1 do
            local v1 = i * (resolution + 1) + j + 1
            local v2 = v1 + 1
            local v3 = v1 + (resolution + 1)
            local v4 = v3 + 1
            table.insert(chunk.triangles, {v1, v2, v3})
            table.insert(chunk.triangles, {v2, v4, v3})
        end
    end
    return chunk
end
function TerrainModule.updateTerrainChunks(playerX, playerY)
    if not TerrainModule.isInitialized then
        TerrainModule.initialize()
    end
    local playerChunkX, playerChunkY = TerrainModule.getChunkCoords(playerX, playerY)
    if playerChunkX == TerrainModule.lastPlayerChunkX and playerChunkY == TerrainModule.lastPlayerChunkY then
        return
    end
    TerrainModule.lastPlayerChunkX = playerChunkX
    TerrainModule.lastPlayerChunkY = playerChunkY
    for key, chunk in pairs(TerrainModule.terrainChunks) do
        local dx = chunk.x - playerChunkX
        local dy = chunk.y - playerChunkY
        if dx < -TerrainModule.renderRadius or dx >= TerrainModule.renderRadius or
           dy < -TerrainModule.renderRadius or dy >= TerrainModule.renderRadius then
            if #TerrainModule.chunkPool < 50 then
                table.insert(TerrainModule.chunkPool, chunk)
            end
            TerrainModule.terrainChunks[key] = nil
        end
    end
    for dx = -TerrainModule.renderRadius, TerrainModule.renderRadius - 1 do
        for dy = -TerrainModule.renderRadius, TerrainModule.renderRadius - 1 do
            local chunkX = playerChunkX + dx
            local chunkY = playerChunkY + dy
            local key = chunkX .. "," .. chunkY
            if not TerrainModule.terrainChunks[key] then
                TerrainModule.terrainChunks[key] = TerrainModule.generateTerrainChunk(chunkX, chunkY, playerChunkX, playerChunkY)
            end
        end
    end
end
function TerrainModule.isChunkVisible(chunk, playerX, playerY)
    if not TerrainModule.enableCircularVisibility then
        return true
    end
    local chunkCenterX = chunk.x * TerrainModule.chunkWidth + TerrainModule.chunkWidth * 0.5
    local chunkCenterY = chunk.y * TerrainModule.chunkLength + TerrainModule.chunkLength * 0.5
    local dx = chunkCenterX - playerX
    local dy = chunkCenterY - playerY
    local distance = math.sqrt(dx * dx + dy * dy)
    return distance <= TerrainModule.visibilityRadius
end
function TerrainModule.renderTerrain(playerX, playerY)
    render.SetColorMaterial()
    local terrainColor = Color(0, 80, 40, 200)
    local wireframeColor = Color(0, 200, 150, 80)
    for key, chunk in pairs(TerrainModule.terrainChunks) do
        if TerrainModule.isChunkVisible(chunk, playerX, playerY) then
            for _, triangle in ipairs(chunk.triangles) do
                local v1 = chunk.vertices[triangle[1]]
                local v2 = chunk.vertices[triangle[2]]
                local v3 = chunk.vertices[triangle[3]]
                if v1 and v2 and v3 then
                    render.DrawQuad(v1, v2, v3, v1, terrainColor)
                end
            end
        end
    end
    local wireframeSkip = 2
    local lineCount = 0
    for key, chunk in pairs(TerrainModule.terrainChunks) do
        if TerrainModule.isChunkVisible(chunk, playerX, playerY) then
            for _, triangle in ipairs(chunk.triangles) do
                lineCount = lineCount + 1
                if lineCount % wireframeSkip == 0 then
                    local v1 = chunk.vertices[triangle[1]]
                    local v2 = chunk.vertices[triangle[2]]
                    local v3 = chunk.vertices[triangle[3]]
                    if v1 and v2 and v3 then
                        render.DrawLine(v1, v2, wireframeColor, false)
                        render.DrawLine(v2, v3, wireframeColor, false)
                        render.DrawLine(v3, v1, wireframeColor, false)
                    end
                end
            end
        end
    end
end
function TerrainModule.getTerrainInfo()
    return {
        chunkCount = table.Count(TerrainModule.terrainChunks),
        poolSize = #TerrainModule.chunkPool,
        lastPlayerChunk = {TerrainModule.lastPlayerChunkX, TerrainModule.lastPlayerChunkY}
    }
end
function TerrainModule.clearTerrain()
    TerrainModule.terrainChunks = {}
    TerrainModule.chunkPool = {}
    TerrainModule.lastPlayerChunkX = nil
    TerrainModule.lastPlayerChunkY = nil
end
function TerrainModule.setTerrainConfig(config)
    if config.terrainHeight then TerrainModule.terrainHeight = config.terrainHeight end
    if config.noiseScale then TerrainModule.noiseScale = config.noiseScale end
    if config.chunkWidth then TerrainModule.chunkWidth = config.chunkWidth end
    if config.chunkLength then TerrainModule.chunkLength = config.chunkLength end
    if config.chunkResolution then TerrainModule.chunkResolution = config.chunkResolution end
    if config.renderRadius then TerrainModule.renderRadius = config.renderRadius end
    if config.lodDistance1 then TerrainModule.lodDistance1 = config.lodDistance1 end
    if config.lodDistance2 then TerrainModule.lodDistance2 = config.lodDistance2 end
end
function TerrainModule.initialize()
    if TerrainModule.isInitialized then return end
    TerrainModule.terrainChunks = {}
    TerrainModule.chunkPool = {}
    TerrainModule.lastPlayerChunkX = nil
    TerrainModule.lastPlayerChunkY = nil
    TerrainModule.whiteRectangle = nil
    TerrainModule.rectangleParticles = {}
    TerrainModule.nextRectangleSpawnTime = nil
    TerrainModule.gameStartTime = CurTime()
    TerrainModule.rectangleProbabilityCheck.nextCheckTime = nil
    TerrainModule.rectangleProbabilityCheck.canSpawn = false
    TerrainModule.rectangleProbabilityCheck.isWaitingToSpawn = false
    TerrainModule.isInitialized = true
end
function TerrainModule.triggerBloodRedEffect()
    if not TerrainModule.whiteRectangle then return end
    if TerrainModule.whiteRectangle.isTouchedByEnemy then return end
    local currentTime = CurTime()
    TerrainModule.whiteRectangle.isTouchedByEnemy = true
    TerrainModule.whiteRectangle.isBloodRed = false
    TerrainModule.whiteRectangle.colorTransitionTime = currentTime
end
function TerrainModule.updateColorTransition()
    if not TerrainModule.whiteRectangle then return end
    if not TerrainModule.whiteRectangle.isTouchedByEnemy then return end
    if TerrainModule.whiteRectangle.isBloodRed then return end
    local currentTime = CurTime()
    local rect = TerrainModule.whiteRectangle
    local elapsed = currentTime - rect.colorTransitionTime
    if elapsed >= rect.colorTransitionDuration then
        rect.isBloodRed = true
    end
end
function TerrainModule.getRectangleColor()
    if not TerrainModule.whiteRectangle then return {255, 255, 255} end
    local rect = TerrainModule.whiteRectangle
    if not rect.isTouchedByEnemy then
        return rect.originalColor
    end
    if rect.isBloodRed then
        return rect.bloodRedColor
    end
    local currentTime = CurTime()
    local elapsed = currentTime - rect.colorTransitionTime
    local progress = math.min(elapsed / rect.colorTransitionDuration, 1.0)
    local r = rect.originalColor[1] + (rect.bloodRedColor[1] - rect.originalColor[1]) * progress
    local g = rect.originalColor[2] + (rect.bloodRedColor[2] - rect.originalColor[2]) * progress
    local b = rect.originalColor[3] + (rect.bloodRedColor[3] - rect.originalColor[3]) * progress
    return {math.floor(r), math.floor(g), math.floor(b)}
end
function TerrainModule.checkEnemyRectangleCollision(enemyX, enemyY, enemyZ, enemySize)
    if not TerrainModule.whiteRectangle then return false end
    if TerrainModule.whiteRectangle.isCorrupted then return false end
    local rect = TerrainModule.whiteRectangle
    local halfEnemySize = enemySize * 0.5
    local halfRectWidth = rect.width * 0.5
    local halfRectDepth = rect.depth * 0.5
    local collisionX = (enemyX + halfEnemySize >= rect.x - halfRectWidth) and
                      (enemyX - halfEnemySize <= rect.x + halfRectWidth)
    local collisionY = (enemyY + halfEnemySize >= rect.y - halfRectDepth) and
                      (enemyY - halfEnemySize <= rect.y + halfRectDepth)
    local collisionZ = (enemyZ + halfEnemySize >= rect.z) and
                      (enemyZ - halfEnemySize <= rect.z + rect.height)
    return collisionX and collisionY and collisionZ
end
function TerrainModule.corruptRectangle(enemyRings)
    if not TerrainModule.whiteRectangle then return end
    if TerrainModule.whiteRectangle.isCorrupted then return end
    local rect = TerrainModule.whiteRectangle
    rect.isCorrupted = true
    rect.playerTrapped = false
    rect.corruptionStartTime = CurTime()
    rect.corruptionDuration = 3.0
    rect.isChasing = false
    rect.chaseStartTime = CurTime() + 20.0
    rect.chaseSpeed = 50.0
    rect.originalX = rect.x
    rect.originalY = rect.y
    rect.originalZ = rect.z
    rect.rotationToPlayer = 0
    rect.lastPlayerX = 0
    rect.lastPlayerY = 0
    rect.corruptedRings = {}
    for i, ring in ipairs(enemyRings) do
        rect.corruptedRings[i] = {
            rotationX = ring.rotationX,
            rotationY = ring.rotationY,
            rotationZ = ring.rotationZ,
            speedX = ring.speedX * 0.7,
            speedY = ring.speedY * 0.7,
            speedZ = ring.speedZ * 0.7,
            radius = ring.radius + 5.0,
            segments = ring.segments,
            thickness = ring.thickness * 1.5
        }
    end
    rect.isBloodRed = true
    rect.colorTransitionTime = CurTime()
    rect.corruptionIntensity = 0
    rect.corruptionPulse = 0
    rect.corruptionGlitch = 0
end
function TerrainModule.updateCorruption(deltaTime, playerX, playerY, playerZ)
    if not TerrainModule.whiteRectangle then return end
    if not TerrainModule.whiteRectangle.isCorrupted then return end
    local rect = TerrainModule.whiteRectangle
    local currentTime = CurTime()
    local elapsed = currentTime - rect.corruptionStartTime
    local progress = math.min(elapsed / rect.corruptionDuration, 1.0)
    if currentTime >= rect.chaseStartTime and not rect.isChasing then
        rect.isChasing = true
    end
    if rect.isChasing and playerX and playerY and playerZ then
        local dx = playerX - rect.x
        local dy = playerY - rect.y
        local distance = math.sqrt(dx * dx + dy * dy)
        rect.lastPlayerX = playerX
        rect.lastPlayerY = playerY
        rect.rotationToPlayer = math.atan2(dy, dx)
        if distance > 1.0 then
            local dirX = dx / distance
            local dirY = dy / distance
            local speedMultiplier = 1.0
            if distance < 20.0 then
                speedMultiplier = 2.0
            end
            local actualSpeed = rect.chaseSpeed * speedMultiplier
            rect.x = rect.x + dirX * actualSpeed * deltaTime
            rect.y = rect.y + dirY * actualSpeed * deltaTime
            rect.z = rect.originalZ + math.sin(currentTime * 3) * 2.0
        else
            rect.x = playerX
            rect.y = playerY
        end
    end
    local proximityIntensity = 1.0
    if playerX and playerY and playerZ then
        local dx = playerX - rect.x
        local dy = playerY - rect.y
        local dz = playerZ - rect.z
        local distance = math.sqrt(dx * dx + dy * dy + dz * dz)
        local maxProximityDistance = 40
        local minProximityDistance = 15
        if distance <= maxProximityDistance then
            if distance <= minProximityDistance then
                proximityIntensity = 2.0
            else
                local proximityRatio = 1 - ((distance - minProximityDistance) / (maxProximityDistance - minProximityDistance))
                proximityIntensity = 1.0 + proximityRatio * 1.0
            end
        end
    end
    rect.corruptionIntensity = progress * proximityIntensity
    local pulseSpeed = 6 + proximityIntensity * 2
    rect.corruptionPulse = math.sin(currentTime * pulseSpeed) * 0.2 * progress * proximityIntensity
    local glitchChance = 0.05 * progress * proximityIntensity
    if math.random() < glitchChance then
        rect.corruptionGlitch = math.random(-1, 1) * progress * proximityIntensity
    else
        rect.corruptionGlitch = rect.corruptionGlitch * 0.95
    end
    if rect.corruptedRings then
        local speedMultiplier = proximityIntensity
        for i, ring in ipairs(rect.corruptedRings) do
            ring.rotationX = ring.rotationX + ring.speedX * deltaTime * speedMultiplier
            ring.rotationY = ring.rotationY + ring.speedY * deltaTime * speedMultiplier
            ring.rotationZ = ring.rotationZ + ring.speedZ * deltaTime * speedMultiplier
        end
    end
    rect.proximityIntensity = proximityIntensity
end
function TerrainModule.updateChaseAlways(deltaTime, playerX, playerY, playerZ)
    if not TerrainModule.whiteRectangle then return end
    if not TerrainModule.whiteRectangle.isCorrupted then return end
    local rect = TerrainModule.whiteRectangle
    local currentTime = CurTime()
    if currentTime >= rect.chaseStartTime and not rect.isChasing then
        rect.isChasing = true
    end
    if rect.isChasing and playerX and playerY and playerZ then
        local dx = playerX - rect.x
        local dy = playerY - rect.y
        local distance = math.sqrt(dx * dx + dy * dy)
        rect.lastPlayerX = playerX
        rect.lastPlayerY = playerY
        rect.rotationToPlayer = math.atan2(dy, dx)
        if distance > 0.5 then
            local dirX = dx / distance
            local dirY = dy / distance
            local speedMultiplier = 1.0
            if distance < 30.0 then
                speedMultiplier = 3.0
            end
            if distance < 10.0 then
                speedMultiplier = 5.0
            end
            local actualSpeed = rect.chaseSpeed * speedMultiplier
            rect.x = rect.x + dirX * actualSpeed * deltaTime
            rect.y = rect.y + dirY * actualSpeed * deltaTime
            rect.z = rect.originalZ + math.sin(currentTime * 5) * 3.0
        else
            rect.x = playerX
            rect.y = playerY
        end
    end
end
function TerrainModule.canPlayerExit()
    if not TerrainModule.whiteRectangle then return true end
    return not TerrainModule.whiteRectangle.playerTrapped
end
function TerrainModule.reset()
    TerrainModule.isInitialized = false
    TerrainModule.initialize()
end
return TerrainModule
