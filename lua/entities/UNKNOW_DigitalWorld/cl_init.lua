include("shared.lua")
local PlayerModule = include("modules/player.lua")
local EnemiesModule = include("modules/enemies.lua")
local TerrainModule = include("modules/terrain.lua")
local PhysicsModule = include("modules/physics.lua")
_G.UNKNOW_DigitalWorld_Active = false
local digitalFrame = nil
exitButtonCreated = false
local spawnTime = CurTime()
local gameStartTime = nil
net.Receive("UNKNOW_DigitalWorld_Activate", function()
    CreateDigitalWorldInterface()
end)
function RandomTeleport()
    if UNKNOW_RequestRandomTeleport then
        UNKNOW_RequestRandomTeleport()
    end
end
function CreateDigitalWorldInterface()
    if IsValid(digitalFrame) then
        digitalFrame:Close()
    end
    exitButtonCreated = false
    spawnTime = CurTime()
    gameStartTime = nil
    TerrainModule.reset()
    EnemiesModule.reset()
    local cvar = GetConVar("unknow_DigitalWorld")
    local playerSteamID = cvar and cvar:GetString() or ""
    local currentPlayer = LocalPlayer()
    local playerName = IsValid(currentPlayer) and currentPlayer:Name() or "UNKNOWN"
    if playerSteamID == "" then
        playerSteamID = IsValid(currentPlayer) and currentPlayer:SteamID() or "UNKNOWN"
    elseif playerSteamID ~= currentPlayer:SteamID() then
        return
    end
    digitalFrame = vgui.Create("DFrame")
    _G.UNKNOW_DigitalWorld_Active = true
    local frameW = ScrW() * 0.8
    local frameH = ScrH() * 0.85
    local frameX = (ScrW() - frameW) / 2
    local frameY = (ScrH() - frameH) / 2
    digitalFrame:SetSize(frameW, frameH)
    digitalFrame:SetPos(frameX, frameY)
    digitalFrame:SetTitle("")
    digitalFrame:SetDraggable(true)
    digitalFrame:SetSizable(false)
    digitalFrame:ShowCloseButton(true)
    digitalFrame:MakePopup()
    digitalFrame:SetDeleteOnClose(true)
    digitalFrame.OnClose = function(self)
        _G.UNKNOW_DigitalWorld_Active = false
        gui.EnableScreenClicker(false)
        vgui.CursorVisible(false)
        if IsValid(GetViewEntity()) then
            GetViewEntity():SetNoDraw(false)
        end
        timer.Simple(0.1, function()
            gui.EnableScreenClicker(false)
            vgui.CursorVisible(false)
        end)
    end
    digitalFrame.PlayerSteamID = playerSteamID
    digitalFrame.PlayerName = playerName
    local digitalText = ""
    local chars = "ABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789"
    for i = 1, 8 do
        digitalText = digitalText .. chars[math.random(1, #chars)]
    end
    local connectionPhase = "connecting"
    local connectionStartTime = CurTime()
    local unknowCvarValue = GetConVar("unknow"):GetInt()
    local connectionDuration = 3
    local cubeVertices = {
        {-0.6, -0.6, -0.6}, {0.6, -0.6, -0.6}, {0.6, 0.6, -0.6}, {-0.6, 0.6, -0.6},
        {-0.6, -0.6, 0.6}, {0.6, -0.6, 0.6}, {0.6, 0.6, 0.6}, {-0.6, 0.6, 0.6}
    }
    cubeEdges = {
        {1, 2}, {2, 3}, {3, 4}, {4, 1},
        {5, 6}, {6, 7}, {7, 8}, {8, 5},
        {1, 5}, {2, 6}, {3, 7}, {4, 8}
    }
    local squareInitialized = false
    isPaused = false
    local enemyRings = {
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
    local enemyRotationSpeed = 15
    local enemyRotationSpeedX = 12
    local enemyRotationSpeedY = 18
    local enemyRotationSpeedZ = 8
    local enemySpawnChance = 0.40
    local chunkSize = 20
    local baseSquareVertices = {
        {-1, -1, -1}, {1, -1, -1}, {1, 1, -1}, {-1, 1, -1},
        {-1, -1, 1}, {1, -1, 1}, {1, 1, 1}, {-1, 1, 1}
    }
    local squareEdges = {
        {1, 2}, {2, 3}, {3, 4}, {4, 1},
        {5, 6}, {6, 7}, {7, 8}, {8, 5},
        {1, 5}, {2, 6}, {3, 7}, {4, 8}
    }
    local terrainChunks = {}
    local chunkPool = {}
    local maxRenderChunks = 12
    local chunkSize = 16
    local checkedChunksForEnemy = {}
    local chunkWidth = 16
    local chunkLength = 24
    local chunkResolution = 2
    local renderRadius = 3
    local lodDistance1 = 1
    local lodDistance2 = 2
    local lastPlayerChunkX = nil
    local lastPlayerChunkY = nil
    local lastUpdateTime = 0
    local updateFrequency = 0.1
    local noiseScale = 0.08
    local terrainHeight = 1.5
    local matrixColumns = {}
    local matrixChars = "アイウエオカキクケコサシスセソタチツテトナニヌネノハヒフヘホマミムメモヤユヨラリルレロワヲン0123456789ABCDEFGHIJKLMNOPQRSTUVWXYZ"
    local matrixInitialized = false
    local function initializeMatrix(screenW, screenH)
        matrixColumns = {}
        local columnSpacing = math.max(35, screenW * 0.06)
        local numColumns = math.floor(screenW / columnSpacing)
        numColumns = math.floor(numColumns * (0.3 + math.random() * 0.2))
        numColumns = math.Clamp(numColumns, 5, 30)
        for i = 1, numColumns do
            if math.random() > 0.35 then
                local columnData = {
                    x = math.random(0, screenW),
                    chars = {},
                    speed = math.random(0.5, 4),
                    lastUpdate = 0,
                    density = math.random(0.15, 0.4),
                    nextSpawn = math.random(0, 5),
                    trailLength = math.random(3, 10)
                }
                local charCount = math.floor(columnData.trailLength * columnData.density)
                for j = 1, charCount do
                    columnData.chars[j] = {
                        char = matrixChars[math.random(1, #matrixChars)],
                        y = math.random(-screenH, 0),
                        alpha = math.random(30, 255),
                        brightness = math.random(0.5, 1.0)
                    }
                end
                matrixColumns[i] = columnData
            end
        end
        matrixInitialized = true
    end
    local digitalParticles = {}
    local particlesInitialized = false
    local function initializeParticles(screenW, screenH)
        digitalParticles = {}
        local screenArea = screenW * screenH
        local particleCount = math.floor(screenArea / 35000)
        particleCount = math.Clamp(particleCount, 5, 40)
        for i = 1, particleCount do
            digitalParticles[i] = {
                x = math.random(0, screenW),
                y = math.random(0, screenH),
                vx = math.random(-1, 1),
                vy = math.random(-1, 1),
                life = math.random(3, 8),
                maxLife = math.random(3, 8),
                size = math.random(1, 3),
                pulseSpeed = math.random(0.3, 1),
                pulseOffset = math.random(0, 6.28),
                glowIntensity = math.random(0.3, 0.8)
            }
        end
        particlesInitialized = true
    end
    function project3D(vertex, centerX, centerY, scale, rotX, rotY, rotZ)
        local x, y, z = vertex[1], vertex[2], vertex[3]
        local cosX, sinX = math.cos(rotX), math.sin(rotX)
        local newY = y * cosX - z * sinX
        local newZ = y * sinX + z * cosX
        y, z = newY, newZ
        local cosY, sinY = math.cos(rotY), math.sin(rotY)
        local newX = x * cosY + z * sinY
        newZ = -x * sinY + z * cosY
        x, z = newX, newZ
        local cosZ, sinZ = math.cos(rotZ), math.sin(rotZ)
        newX = x * cosZ - y * sinZ
        newY = x * sinZ + y * cosZ
        x, y = newX, newY
        local distance = 5
        local projectedX = centerX + (x * scale) / (z + distance)
        local projectedY = centerY + (y * scale) / (z + distance)
        return projectedX, projectedY, z
    end
    local lastScreenW, lastScreenH = 0, 0
    local function renderMatrixEffects(w, h, currentTime)
        if not matrixInitialized then
            initializeMatrix(w, h)
        end
        for i, column in ipairs(matrixColumns) do
            if column and currentTime - column.lastUpdate > (0.03 + math.random() * 0.04) then
                if math.random() < 0.1 and column.nextSpawn <= 0 then
                    local newChar = {
                        char = matrixChars[math.random(1, #matrixChars)],
                        y = -20,
                        alpha = math.random(150, 255),
                        brightness = math.random(0.7, 1.0)
                    }
                    table.insert(column.chars, 1, newChar)
                    column.nextSpawn = math.random(1, 5)
                end
                column.nextSpawn = math.max(0, column.nextSpawn - 1)
                for j = #column.chars, 1, -1 do
                    local charData = column.chars[j]
                    charData.y = charData.y + column.speed
                    if charData.y > h + 50 then
                        table.remove(column.chars, j)
                    else
                        local trailPosition = j / #column.chars
                        local baseAlpha = charData.alpha * charData.brightness
                        local trailAlpha = baseAlpha * (1 - trailPosition * 0.7)
                        if math.random() < 0.05 then
                            trailAlpha = trailAlpha * (0.3 + math.random() * 0.7)
                        end
                        if math.random() < 0.02 then
                            charData.char = matrixChars[math.random(1, #matrixChars)]
                        end
                        local greenIntensity = math.max(0, trailAlpha)
                        local blueIntensity = greenIntensity * 0.3
                        local redIntensity = greenIntensity * 0.1
                        if j == 1 then
                            greenIntensity = math.min(255, greenIntensity * 1.5)
                            redIntensity = greenIntensity * 0.8
                            blueIntensity = greenIntensity * 0.8
                        end
                        draw.DrawText(charData.char, "DermaDefault", column.x, charData.y,
                                    Color(redIntensity, greenIntensity, blueIntensity, greenIntensity), TEXT_ALIGN_LEFT)
                    end
                end
                while #column.chars > column.trailLength do
                    table.remove(column.chars, #column.chars)
                end
                column.lastUpdate = currentTime
            end
        end
    end
    local function renderDigitalParticles(w, h)
        if not particlesInitialized then
            initializeParticles(w, h)
        end
        for i, particle in ipairs(digitalParticles) do
            particle.x = particle.x + particle.vx
            particle.y = particle.y + particle.vy
            particle.life = particle.life - FrameTime()
            if particle.life <= 0 or particle.x < -20 or particle.x > w + 20 or particle.y < -20 or particle.y > h + 20 then
                particle.x = math.random(0, w)
                particle.y = math.random(0, h)
                particle.vx = math.random(-1, 1)
                particle.vy = math.random(-1, 1)
                particle.life = particle.maxLife
                particle.size = math.random(1, 4)
                particle.pulseSpeed = math.random(1, 3)
                particle.pulseOffset = math.random(0, 6.28)
                particle.glowIntensity = math.random(0.5, 1.0)
            end
            local pulseValue = math.sin(CurTime() * particle.pulseSpeed + particle.pulseOffset) * 0.5 + 0.5
            local alpha = (particle.life / particle.maxLife) * 255 * particle.glowIntensity * (0.5 + pulseValue * 0.5)
            local color
            if particle.type == "code" then
                color = Color(0, alpha * 0.8, alpha, alpha)
            elseif particle.type == "data" then
                color = Color(alpha * 0.6, alpha, alpha * 0.4, alpha)
            else
                color = Color(alpha * 0.3, alpha * 0.7, alpha, alpha)
            end
            surface.SetDrawColor(color)
            surface.DrawRect(particle.x - particle.size/2, particle.y - particle.size/2, particle.size, particle.size)
            local glowSize = particle.size + 2
            local glowAlpha = alpha * 0.3
            surface.SetDrawColor(color.r, color.g, color.b, glowAlpha)
            surface.DrawRect(particle.x - glowSize/2, particle.y - glowSize/2, glowSize, glowSize)
        end
     end
    function render3DGame(gameViewX, gameViewY, gameViewW, gameViewH, cameraX, cameraY, cameraZ, cameraPitch, cameraYaw, squareX, squareY, squareZ)
         cam.Start3D(Vector(cameraX, cameraY, cameraZ), Angle(cameraPitch, cameraYaw, 0), 85, gameViewX, gameViewY, gameViewW, gameViewH)
         render.Clear(0, 0, 0, 255)
         render.SetColorMaterial()
        local currentTime = CurTime()
        if currentTime - lastUpdateTime >= updateFrequency then
            TerrainModule.updateTerrainChunks(squareX, squareY)
            lastUpdateTime = currentTime
        end
         TerrainModule.renderTerrain(squareX, squareY)
         local cubeVertices = {}
         local yawRad = math.rad(PlayerModule.cubeRotationY)
         local cosYaw = math.cos(yawRad)
         local sinYaw = math.sin(yawRad)
         local squareVertices = PlayerModule.getSquareVertices()
         for i, vertex in ipairs(squareVertices) do
             local localX = vertex[1]
             local localY = vertex[2]
             local localZ = vertex[3]
             local rotatedX = localX * cosYaw - localY * sinYaw
             local rotatedY = localX * sinYaw + localY * cosYaw
             local rotatedZ = localZ
             local x = rotatedX + squareX
             local y = rotatedY + squareY
             local z = rotatedZ + squareZ
             cubeVertices[i] = Vector(x, y, z)
         end
         render.SetColorMaterial()
         local cubeColor = Color(0, 255, 200, 220)
         local cubeFaces = {
             {1, 2, 3, 4},
             {8, 7, 6, 5},
             {1, 4, 8, 5},
             {3, 2, 6, 7},
             {4, 3, 7, 8},
             {2, 1, 5, 6}
         }
         for _, face in ipairs(cubeFaces) do
             local v1 = cubeVertices[face[1]]
             local v2 = cubeVertices[face[2]]
             local v3 = cubeVertices[face[3]]
             local v4 = cubeVertices[face[4]]
             if v1 and v2 and v3 and v4 then
                 render.DrawQuad(v1, v2, v3, v4, cubeColor)
             end
         end
         local edgeColor = Color(0, 255, 200, 255)
         for _, edge in ipairs(squareEdges) do
             local v1 = cubeVertices[edge[1]]
             local v2 = cubeVertices[edge[2]]
             if v1 and v2 then
                 render.DrawLine(v1, v2, edgeColor, false)
             end
         end
         if EnemiesModule.enemyExists then
             local eyeRadius = EnemiesModule.enemySize * 0.6
             local eyeCenter = Vector(EnemiesModule.enemyX, EnemiesModule.enemyY, EnemiesModule.enemyZ)
             local rotXRad = math.rad(EnemiesModule.enemyRotationX)
             local rotYRad = math.rad(EnemiesModule.enemyRotationY)
             local rotZRad = math.rad(EnemiesModule.enemyRotationZ)
             local cosX, sinX = math.cos(rotXRad), math.sin(rotXRad)
             local cosY, sinY = math.cos(rotYRad), math.sin(rotYRad)
             local cosZ, sinZ = math.cos(rotZRad), math.sin(rotZRad)
             render.SetColorMaterial()
             local function rotatePoint(x, y, z)
                 local y1 = y * cosX - z * sinX
                 local z1 = y * sinX + z * cosX
                 local x2 = x * cosY + z1 * sinY
                 local z2 = -x * sinY + z1 * cosY
                 local rotatedX = x2 * cosZ - y1 * sinZ
                 local rotatedY = x2 * sinZ + y1 * cosZ
                 local rotatedZ = z2
                 return rotatedX + EnemiesModule.enemyX, rotatedY + EnemiesModule.enemyY, rotatedZ + EnemiesModule.enemyZ
             end
                 local scleraSegments = 16
                 local baseScleraColor = Color(0, 0, 0, 200)
                 local glitchTime = CurTime() * 3
                 local glitchIntensity = math.sin(glitchTime) * 0.3 + 0.7
                 for i = 0, scleraSegments - 1 do
                 for j = 0, scleraSegments - 1 do
                     local phi1 = (i / scleraSegments) * math.pi
                     local phi2 = ((i + 1) / scleraSegments) * math.pi
                     local theta1 = (j / scleraSegments) * 2 * math.pi
                     local theta2 = ((j + 1) / scleraSegments) * 2 * math.pi
                     local segmentGlitch = math.sin(glitchTime + i * 0.5 + j * 0.3) * 0.1
                     local radiusGlitch = eyeRadius * (1 + segmentGlitch * glitchIntensity)
                     local x1 = radiusGlitch * math.sin(phi1) * math.cos(theta1)
                     local y1 = radiusGlitch * math.sin(phi1) * math.sin(theta1)
                     local z1 = radiusGlitch * math.cos(phi1)
                     local x2 = radiusGlitch * math.sin(phi1) * math.cos(theta2)
                     local y2 = radiusGlitch * math.sin(phi1) * math.sin(theta2)
                     local z2 = radiusGlitch * math.cos(phi1)
                     local x3 = radiusGlitch * math.sin(phi2) * math.cos(theta2)
                     local y3 = radiusGlitch * math.sin(phi2) * math.sin(theta2)
                     local z3 = radiusGlitch * math.cos(phi2)
                     local x4 = radiusGlitch * math.sin(phi2) * math.cos(theta1)
                     local y4 = radiusGlitch * math.sin(phi2) * math.sin(theta1)
                     local z4 = radiusGlitch * math.cos(phi2)
                     local rx1, ry1, rz1 = rotatePoint(x1, y1, z1)
                     local rx2, ry2, rz2 = rotatePoint(x2, y2, z2)
                     local rx3, ry3, rz3 = rotatePoint(x3, y3, z3)
                     local rx4, ry4, rz4 = rotatePoint(x4, y4, z4)
                     local v1 = Vector(rx1, ry1, rz1)
                     local v2 = Vector(rx2, ry2, rz2)
                     local v3 = Vector(rx3, ry3, rz3)
                     local v4 = Vector(rx4, ry4, rz4)
                     local colorGlitch = math.sin(glitchTime * 2 + i + j) > 0.8
                     local scleraColor = baseScleraColor
                     if colorGlitch then
                         if math.random() > 0.5 then
                             scleraColor = Color(255, 100, 100, 200)
                         else
                             scleraColor = Color(100, 100, 255, 200)
                         end
                     end
                     render.DrawQuad(v1, v2, v3, v4, scleraColor)
                 end
             end
             local dx = squareX - EnemiesModule.enemyX
             local dy = squareY - EnemiesModule.enemyY
             local dz = squareZ - EnemiesModule.enemyZ
             local distance = math.sqrt(dx*dx + dy*dy + dz*dz)
             local maxEyeMovement = eyeRadius * 0.5
             local eyeOffsetX = 0
             local eyeOffsetY = 0
             if distance > 0 then
                 local normalizedDx = dx / distance
                 local normalizedDy = dy / distance
                 local normalizedDz = dz / distance
                 local trackingIntensity = 1.2
                 eyeOffsetX = math.max(-maxEyeMovement, math.min(maxEyeMovement, normalizedDx * maxEyeMovement * trackingIntensity))
                 eyeOffsetY = math.max(-maxEyeMovement, math.min(maxEyeMovement, normalizedDy * maxEyeMovement * trackingIntensity))
             end
             local baseRingColors = {
                 Color(255, 200, 150, 255),
                 Color(200, 255, 200, 255),
                 Color(150, 200, 255, 255),
                 Color(255, 255, 255, 255)
             }
             local glitchRingColors = {
                 Color(255, 0, 255, 255),
                 Color(0, 255, 255, 255),
                 Color(255, 255, 0, 255),
                 Color(255, 0, 0, 255),
                 Color(0, 255, 0, 255)
             }
             for ringIndex = 1, #EnemiesModule.enemyRings do
                 local ring = EnemiesModule.enemyRings[ringIndex]
                 local ringGlitchIntensity = math.sin(glitchTime * 2 + ringIndex * 1.5) * 0.3 + 0.7
                 local radiusGlitch = math.sin(glitchTime * 4 + ringIndex * 2) * 0.2
                 local ringRadius = EnemiesModule.enemySize * ring.radius * (1 + radiusGlitch * ringGlitchIntensity)
                 local ringSegments = ring.segments
                 local ringRotXRad = math.rad(ring.rotationX)
                 local ringRotYRad = math.rad(ring.rotationY)
                 local ringRotZRad = math.rad(ring.rotationZ)
                 local cosX = math.cos(ringRotXRad)
                 local sinX = math.sin(ringRotXRad)
                 local cosY = math.cos(ringRotYRad)
                 local sinY = math.sin(ringRotYRad)
                 local cosZ = math.cos(ringRotZRad)
                 local sinZ = math.sin(ringRotZRad)
                 local ringVertices = {}
                 for i = 0, ringSegments - 1 do
                     local angle = (i / ringSegments) * 2 * math.pi
                     local localX = math.cos(angle) * ringRadius
                     local localY = math.sin(angle) * ringRadius
                     local localZ = 0
                     local tempY = localY * cosX - localZ * sinX
                     local tempZ = localY * sinX + localZ * cosX
                     localY = tempY
                     localZ = tempZ
                     local tempX = localX * cosY + localZ * sinY
                     tempZ = -localX * sinY + localZ * cosY
                     localX = tempX
                     localZ = tempZ
                     tempX = localX * cosZ - localY * sinZ
                     tempY = localX * sinZ + localY * cosZ
                     localX = tempX
                     localY = tempY
                     local vertexGlitch = math.sin(glitchTime * 6 + i * 0.5 + ringIndex * 3) * 0.1
                     local jitterX = math.sin(glitchTime * 8 + i * 1.2) * vertexGlitch * EnemiesModule.enemySize
                     local jitterY = math.cos(glitchTime * 7 + i * 0.8) * vertexGlitch * EnemiesModule.enemySize
                     local jitterZ = math.sin(glitchTime * 9 + i * 1.5) * vertexGlitch * EnemiesModule.enemySize
                     local x = localX + EnemiesModule.enemyX + jitterX
                     local y = localY + EnemiesModule.enemyY + jitterY
                     local z = localZ + EnemiesModule.enemyZ + jitterZ
                     ringVertices[i + 1] = Vector(x, y, z)
                 end
                 for i = 1, ringSegments do
                     local v1 = ringVertices[i]
                     local v2 = ringVertices[(i % ringSegments) + 1]
                     if v1 and v2 then
                         local segmentGlitchChance = math.sin(glitchTime * 5 + i * 0.7 + ringIndex * 2) > 0.6
                         local ringColor
                         if segmentGlitchChance then
                             local glitchColorIndex = math.floor(math.sin(glitchTime * 3 + i + ringIndex) * 2.5) % #glitchRingColors + 1
                             ringColor = glitchRingColors[glitchColorIndex]
                         else
                             ringColor = baseRingColors[ringIndex] or Color(255, 255, 255, 255)
                         end
                         render.DrawLine(v1, v2, ringColor, false)
                     end
                 end
             end
         end
         if TerrainModule.whiteRectangle then
             local rect = TerrainModule.whiteRectangle
             render.SetColorMaterial()
             local halfWidth = rect.visualWidth * 0.5
             local halfDepth = rect.visualDepth * 0.5
             local visualHeight = rect.visualHeight
             local spawnScale = 1.0
             local spawnAlpha = 200
             if rect.isSpawning and rect.spawnProgress then
                 spawnScale = rect.spawnProgress
                 spawnAlpha = math.floor(200 * rect.spawnProgress)
                 visualHeight = visualHeight * spawnScale
             end
             local centerZ = rect.centerY or (rect.z + visualHeight * 0.5)
             local bottomZ = centerZ - (visualHeight * 0.5)
             local topZ = centerZ + (visualHeight * 0.5)
             local v1 = Vector(rect.x - halfWidth, rect.y - halfDepth, bottomZ)
             local v2 = Vector(rect.x + halfWidth, rect.y - halfDepth, bottomZ)
             local v3 = Vector(rect.x + halfWidth, rect.y - halfDepth, topZ)
             local v4 = Vector(rect.x - halfWidth, rect.y - halfDepth, topZ)
             local v5 = Vector(rect.x - halfWidth, rect.y + halfDepth, bottomZ)
             local v6 = Vector(rect.x + halfWidth, rect.y + halfDepth, bottomZ)
             local v7 = Vector(rect.x + halfWidth, rect.y + halfDepth, topZ)
             local v8 = Vector(rect.x - halfWidth, rect.y + halfDepth, topZ)
             local currentColor = TerrainModule.getRectangleColor()
             local rectColor = Color(currentColor[1], currentColor[2], currentColor[3], spawnAlpha)
             if rect.isCorrupted then
                 local corruptionIntensity = rect.corruptionIntensity or 0
                 local corruptionPulse = rect.corruptionPulse or 0
                 local corruptionGlitch = rect.corruptionGlitch or 0
                 local proximityIntensity = rect.proximityIntensity or 1.0
                 local currentTime = CurTime()
                 local pulseBoost = math.floor(50 * corruptionPulse * proximityIntensity)
                 rectColor.r = math.min(255, rectColor.r + pulseBoost)
                 if proximityIntensity > 2.8 then
                     local flickerChance = (proximityIntensity - 2.8) * 0.05
                     if math.random() < flickerChance then
                         rectColor.r = math.random(150, 200)
                         rectColor.g = math.random(20, 40)
                         rectColor.b = math.random(20, 40)
                     end
                 end
                 local glitchOffset = corruptionGlitch * proximityIntensity
                 if proximityIntensity > 2.5 then
                     local chaosMultiplier = (proximityIntensity - 2.5) * 0.2
                     local chaosX = math.sin(currentTime * 4) * chaosMultiplier
                     local chaosY = math.cos(currentTime * 5) * chaosMultiplier
                     local chaosZ = math.sin(currentTime * 3) * chaosMultiplier * 0.1
                     glitchOffset = glitchOffset + chaosX * 0.1
                     v1.x = v1.x + glitchOffset + chaosX * 0.1
                     v1.y = v1.y + chaosY * 0.05
                     v1.z = v1.z + chaosZ * 0.2
                     v2.x = v2.x - glitchOffset - chaosX * 0.1
                     v2.y = v2.y - chaosY * 0.05
                     v2.z = v2.z - chaosZ * 0.2
                     v3.y = v3.y + glitchOffset * 0.1 + chaosY * 0.2
                     v3.x = v3.x + chaosX * 0.08
                     v3.z = v3.z + chaosZ * 0.15
                     v4.y = v4.y - glitchOffset * 0.1 - chaosY * 0.2
                     v4.x = v4.x - chaosX * 0.08
                     v4.z = v4.z - chaosZ * 0.15
                     v5.z = v5.z + glitchOffset * 0.08 + chaosZ * 0.15
                     v5.x = v5.x + chaosX * 0.12
                     v5.y = v5.y + chaosY * 0.08
                     v6.z = v6.z - glitchOffset * 0.08 - chaosZ * 0.15
                     v6.x = v6.x - chaosX * 0.12
                     v6.y = v6.y - chaosY * 0.08
                     v7.x = v7.x + glitchOffset * 0.12 + chaosX * 0.15
                     v7.y = v7.y + chaosY * 0.12
                     v7.z = v7.z + chaosZ * 0.08
                     v8.x = v8.x - glitchOffset * 0.12 - chaosX * 0.15
                     v8.y = v8.y - chaosY * 0.12
                     v8.z = v8.z - chaosZ * 0.08
                 else
                     v1.x = v1.x + glitchOffset
                     v2.x = v2.x - glitchOffset
                     v3.y = v3.y + glitchOffset * 0.5
                     v4.y = v4.y - glitchOffset * 0.5
                     v5.z = v5.z + glitchOffset * 0.3
                     v6.z = v6.z - glitchOffset * 0.3
                     v7.x = v7.x + glitchOffset * 0.7
                     v8.x = v8.x - glitchOffset * 0.7
                 end
             end
             render.DrawQuad(v1, v2, v3, v4, rectColor)
             render.DrawQuad(v6, v5, v8, v7, rectColor)
             render.DrawQuad(v5, v1, v4, v8, rectColor)
             render.DrawQuad(v2, v6, v7, v3, rectColor)
             render.DrawQuad(v4, v3, v7, v8, rectColor)
             render.DrawQuad(v1, v5, v6, v2, rectColor)
             if rect.isCorrupted and rect.corruptedRings then
                 render.SetColorMaterial()
                 local proximityIntensity = rect.proximityIntensity or 1.0
                 local currentTime = CurTime()
                 for ringIndex, ring in ipairs(rect.corruptedRings) do
                     local vertices = {}
                     for i = 1, ring.segments do
                         local angle = (i - 1) * (360 / ring.segments)
                         local x = math.cos(math.rad(angle)) * ring.radius
                         local y = math.sin(math.rad(angle)) * ring.radius
                         local z = 0
                         if proximityIntensity > 1.0 then
                             local chaosIntensity = (proximityIntensity - 1.0) * 0.5
                             local chaosX = math.sin(currentTime * 10 + i + ringIndex) * chaosIntensity * ring.radius * 0.2
                             local chaosY = math.cos(currentTime * 12 + i + ringIndex) * chaosIntensity * ring.radius * 0.2
                             local chaosZ = math.sin(currentTime * 8 + i + ringIndex) * chaosIntensity * ring.radius * 0.1
                             x = x + chaosX
                             y = y + chaosY
                             z = z + chaosZ
                         end
                         local rotX, rotY, rotZ = math.rad(ring.rotationX), math.rad(ring.rotationY), math.rad(ring.rotationZ)
                         local tempY = y * math.cos(rotX) - z * math.sin(rotX)
                         local tempZ = y * math.sin(rotX) + z * math.cos(rotX)
                         y, z = tempY, tempZ
                         local tempX = x * math.cos(rotY) + z * math.sin(rotY)
                         tempZ = -x * math.sin(rotY) + z * math.cos(rotY)
                         x, z = tempX, tempZ
                         tempX = x * math.cos(rotZ) - y * math.sin(rotZ)
                         tempY = x * math.sin(rotZ) + y * math.cos(rotZ)
                         x, y = tempX, tempY
                         vertices[i] = Vector(rect.x + x, rect.y + y, centerZ + z)
                     end
                     for i = 1, ring.segments do
                         local nextI = (i % ring.segments) + 1
                         local isRed = (ringIndex + i) % 2 == 0
                         local ringColor
                         if isRed then
                             local redIntensity = math.min(255, 255 * proximityIntensity)
                             ringColor = Color(redIntensity, 0, 0, 200)
                         else
                             local blackIntensity = math.min(100, 20 + 30 * (proximityIntensity - 1.0))
                             ringColor = Color(blackIntensity, blackIntensity, blackIntensity, 200)
                         end
                         if proximityIntensity > 2.0 and math.random() < 0.3 then
                             ringColor.a = math.random(100, 255)
                         end
                         render.DrawLine(vertices[i], vertices[nextI], ringColor, false)
                     end
                 end
             end
         end
         if TerrainModule.rectangleParticles then
             render.SetColorMaterial()
             local currentColor = TerrainModule.getRectangleColor()
             for _, particle in ipairs(TerrainModule.rectangleParticles) do
                 local alpha = math.max(0, (particle.life / particle.maxLife) * 255)
                 local particleColor = Color(currentColor[1], currentColor[2], currentColor[3], alpha)
                 local size = particle.size * 0.5
                 local pos = Vector(particle.x, particle.y, particle.z)
                 local v1 = pos + Vector(-size, -size, 0)
                 local v2 = pos + Vector(size, -size, 0)
                 local v3 = pos + Vector(size, size, 0)
                 local v4 = pos + Vector(-size, size, 0)
                 render.DrawQuad(v1, v2, v3, v4, particleColor)
             end
         end
         cam.End3D()
        if isPaused then
            local currentTime = CurTime()
             local pausedOffsetX = -192.5
             local pausedOffsetY = -80
             local fadeAlpha = 200 + math.sin(currentTime * 2) * 30
             surface.SetDrawColor(0, 0, 0, fadeAlpha)
             surface.DrawRect(gameViewX + pausedOffsetX, gameViewY + pausedOffsetY, gameViewW, gameViewH)
             local borderGlow = 100 + math.sin(currentTime * 3) * 50
             surface.SetDrawColor(0, 255, 255, borderGlow)
             surface.DrawOutlinedRect(gameViewX + pausedOffsetX - 2, gameViewY + pausedOffsetY - 2, gameViewW + 4, gameViewH + 4)
             surface.DrawOutlinedRect(gameViewX + pausedOffsetX - 1, gameViewY + pausedOffsetY - 1, gameViewW + 2, gameViewH + 2)
             local panelW = 350
             local panelH = 140
             local panelX = gameViewX + pausedOffsetX + (gameViewW - panelW) / 2
             local panelY = gameViewY + pausedOffsetY + (gameViewH - panelH) / 2 - 20
             surface.SetDrawColor(5, 5, 15, 240)
             surface.DrawRect(panelX, panelY, panelW, panelH)
             local panelGlow = 180 + math.sin(currentTime * 4) * 75
             surface.SetDrawColor(0, 255, 255, panelGlow)
             surface.DrawOutlinedRect(panelX - 1, panelY - 1, panelW + 2, panelH + 2)
             surface.SetDrawColor(0, 200, 255, panelGlow * 0.6)
             surface.DrawOutlinedRect(panelX - 2, panelY - 2, panelW + 4, panelH + 4)
             surface.SetDrawColor(0, 150, 255, panelGlow * 0.3)
             surface.DrawOutlinedRect(panelX - 3, panelY - 3, panelW + 6, panelH + 6)
             surface.SetFont("DermaLarge")
             local pauseText = "PAUSED"
             local textW, textH = surface.GetTextSize(pauseText)
             local textX = panelX + (panelW - textW) / 2
             local textY = panelY + 30
             local textAlpha = 200 + math.sin(currentTime * 6) * 55
             surface.SetTextColor(0, 0, 0, 255)
             surface.SetTextPos(textX + 3, textY + 3)
             surface.DrawText(pauseText)
             surface.SetTextPos(textX + 2, textY + 2)
             surface.DrawText(pauseText)
             surface.SetTextColor(0, 255, 255, textAlpha)
             surface.SetTextPos(textX, textY)
             surface.DrawText(pauseText)
             surface.SetFont("DermaDefault")
             local instructionText = "Press ESC to resume"
             local instrW, instrH = surface.GetTextSize(instructionText)
             local instrX = panelX + (panelW - instrW) / 2
             local instrY = textY + textH + 20
             local instrAlpha = 180 + math.sin(currentTime * 3) * 40
             surface.SetTextColor(0, 0, 0, 200)
             surface.SetTextPos(instrX + 1, instrY + 1)
             surface.DrawText(instructionText)
             surface.SetTextColor(200, 220, 255, instrAlpha)
             surface.SetTextPos(instrX, instrY)
             surface.DrawText(instructionText)
             local lineY1 = panelY + 18
             local lineY2 = panelY + panelH - 18
             local lineAlpha = 120 + math.sin(currentTime * 5) * 70
             surface.SetDrawColor(0, 255, 255, lineAlpha)
             surface.DrawRect(panelX + 25, lineY1, panelW - 50, 2)
             surface.DrawRect(panelX + 25, lineY2, panelW - 50, 2)
             surface.SetDrawColor(0, 200, 255, lineAlpha * 0.5)
             surface.DrawRect(panelX + 30, lineY1 + 3, panelW - 60, 1)
             surface.DrawRect(panelX + 30, lineY2 - 3, panelW - 60, 1)
         end
     end
     digitalFrame.Paint = function(self, w, h)
        local currentTime = CurTime()
        local timeSinceSpawn = currentTime - spawnTime
        local connectionTime = currentTime - connectionStartTime
        if w ~= lastScreenW or h ~= lastScreenH then
            matrixInitialized = false
            particlesInitialized = false
            lastScreenW, lastScreenH = w, h
        end
        surface.SetDrawColor(0, 5, 15, 255)
        surface.DrawRect(0, 0, w, h)
        renderMatrixEffects(w, h, currentTime)
        renderDigitalParticles(w, h, currentTime)
        if connectionPhase == "connecting" then
            local progress = math.min(1, connectionTime / connectionDuration)
            local glitchX = math.random() < 0.1 and math.random(-5, 5) or 0
            draw.DrawText("DIGITAL PRISION", "DermaLarge", w/2 + glitchX, 50, Color(0, 255, 255), TEXT_ALIGN_CENTER)
            draw.DrawText("ACCESSING DETENTION PROTOCOLS...", "DermaDefault", w/2, 90, Color(0, 200, 255), TEXT_ALIGN_CENTER)
            local barWidth = 600
            local barX = (w - barWidth) / 2
            local barY = 120
            surface.SetDrawColor(0, 50, 100, 200)
            surface.DrawRect(barX, barY, barWidth, 30)
            surface.SetDrawColor(0, 150, 255, 255)
            surface.DrawRect(barX, barY, barWidth * progress, 30)
            surface.SetDrawColor(0, 255, 255, 255)
            surface.DrawOutlinedRect(barX, barY, barWidth, 30)
            draw.DrawText(math.floor(progress * 100) .. "%", "DermaDefault", w/2, barY + 8, Color(255, 255, 255), TEXT_ALIGN_CENTER)
            if progress >= 1 then
                if unknowCvarValue == 1 then
                    connectionPhase = "success"
                else
                    connectionPhase = "failed"
                end
            end
        elseif connectionPhase == "success" then
            draw.DrawText("DETENTION PROTOCOLS ACTIVE", "DermaDefault", w/2, 50, Color(0, 255, 0), TEXT_ALIGN_CENTER)
            draw.DrawText("DIGITAL PRISION ACCESS GRANTED", "DermaDefault", w/2, 80, Color(0, 255, 0), TEXT_ALIGN_CENTER)
            timer.Simple(1, function()
                if IsValid(digitalFrame) then
                    connectionPhase = "main"
                    gameStartTime = CurTime()
                    TerrainModule.initialize()
                    EnemiesModule.initialize()
                end
            end)
        elseif connectionPhase == "failed" then
            draw.DrawText("CONNECTION FAILED", "DermaLarge", w/2, 50, Color(255, 0, 0), TEXT_ALIGN_CENTER)
            draw.DrawText("ACCESS DENIED - INSUFFICIENT PRIVILEGES", "DermaDefault", w/2, 90, Color(255, 100, 100), TEXT_ALIGN_CENTER)
            local errorMessages = {
                "ERROR 0x2F4A: AUTHENTICATION FAILURE",
                "ERROR 0x1B3C: SECURITY PROTOCOL VIOLATION",
                "ERROR 0x4E7D: UNAUTHORIZED ACCESS ATTEMPT",
                "ERROR 0x9A2B: CONNECTION TERMINATED"
            }
            for i, msg in ipairs(errorMessages) do
                local errorY = 200 + (i * 25)
                local glitchX = math.random() < 0.2 and math.random(-10, 10) or 0
                draw.DrawText(msg, "DermaDefault", w/2 + glitchX, errorY, Color(255, 100, 100), TEXT_ALIGN_CENTER)
            end
            timer.Simple(4, function()
                if IsValid(digitalFrame) then
                    digitalFrame:Close()
                    _G.UNKNOW_DigitalWorld_Active = false
                end
            end)
        elseif connectionPhase == "main" then
            if isPaused then
                gui.HideGameUI()
            end
            if not squareInitialized then
                PlayerModule.initializePosition(TerrainModule.getTerrainHeightAt)
                squareInitialized = true
            end
            local deltaTime = FrameTime()
            local isShiftPressed = input.IsKeyDown(KEY_LSHIFT) or input.IsKeyDown(KEY_RSHIFT)
            local isMoving = PlayerModule.currentMovementSpeed > 0.1
            local currentSpeed = PlayerModule.isSprinting and PlayerModule.sprintSpeed or PlayerModule.squareSpeed
            if not isPaused then
                local isRectangleCorrupted = TerrainModule.whiteRectangle and TerrainModule.whiteRectangle.isCorrupted or false
                EnemiesModule.updateSpawnTimer(deltaTime, PlayerModule.squareX, PlayerModule.squareY, TerrainModule.getTerrainHeightAt, isRectangleCorrupted)
                EnemiesModule.updateEnemy(deltaTime, PlayerModule.squareX, PlayerModule.squareY, PlayerModule.squareZ)
                EnemiesModule.updateAI(PlayerModule.isSprinting, TerrainModule.whiteRectangle)
            else
                EnemiesModule.updateEnemyWithSpeedMultiplier(deltaTime, PlayerModule.squareX, PlayerModule.squareY, PlayerModule.squareZ, 0.05)
            end
            if not isPaused then
                PlayerModule.update(isPaused, TerrainModule.getTerrainHeightAt, deltaTime)
            end
            TerrainModule.updateRectangleTiming(PlayerModule.squareX, PlayerModule.squareY, EnemiesModule.enemyX, EnemiesModule.enemyY, EnemiesModule.enemyExists)
            if EnemiesModule.enemyExists then
                local collision = TerrainModule.checkEnemyRectangleCollision(EnemiesModule.enemyX, EnemiesModule.enemyY, EnemiesModule.enemyZ, EnemiesModule.enemySize)
                if collision then
                    local enemyRings = EnemiesModule.getOrbitalRings()
                    local enemyPos = EnemiesModule.getEnemyPosition()
                    TerrainModule.corruptRectangle(enemyRings, enemyPos)
                    EnemiesModule.handleRectangleCorruption()
                    PlayerModule.setTrappedMovementCheck(TerrainModule.canPlayerExit)
                end
            end
            TerrainModule.updateColorTransition()
            TerrainModule.updateRectangleVisualScale(PlayerModule.squareX, PlayerModule.squareY, PlayerModule.squareZ)
            TerrainModule.updateRectangleParticles(deltaTime)
            TerrainModule.updateCorruption(deltaTime, PlayerModule.squareX, PlayerModule.squareY, PlayerModule.squareZ)
            TerrainModule.updateChaseAlways(deltaTime, PlayerModule.squareX, PlayerModule.squareY, PlayerModule.squareZ)
            if not isPaused then
                PlayerModule.detectRectangleChase(TerrainModule.whiteRectangle)
                PlayerModule.updateChaseEffects(deltaTime)
            end
            if TerrainModule.checkRectangleCollision(PlayerModule.squareX, PlayerModule.squareY, PlayerModule.squareZ, PlayerModule.squareSize) then
                if not TerrainModule.whiteRectangle.isCorrupted then
                    digitalFrame:Close()
                elseif TerrainModule.whiteRectangle.isChasing then
                    digitalFrame:Close()
                end
            end
            local cameraX, cameraY, cameraZ = PlayerModule.getCameraPosition()
            draw.DrawText("DIGITAL PRISION", "DermaLarge", w/2, 30, Color(0, 255, 255), TEXT_ALIGN_CENTER)
            draw.DrawText("STATUS: ONLINE", "DermaDefault", w/2, 65, Color(0, 255, 0), TEXT_ALIGN_CENTER)
            local chaseStatus = PlayerModule.getChaseStatus()
            if chaseStatus.isBeingChased then
                local warningColor = Color(255, 0, 0)
                local warningText = "RUN! RUN! RUN!"
                local blinkSpeed = 3 + chaseStatus.chaseIntensity * 5
                local blinkAlpha = math.abs(math.sin(currentTime * blinkSpeed)) * 255
                warningColor.a = blinkAlpha
                draw.DrawText(warningText, "DermaLarge", w/2, 90, warningColor, TEXT_ALIGN_CENTER)
                local distanceText = string.format("DISTANCE: %.1f units", chaseStatus.lastDistance)
                local distanceColor = Color(255, 255 - chaseStatus.chaseIntensity * 255, 0)
                draw.DrawText(distanceText, "DermaDefault", w/2, 120, distanceColor, TEXT_ALIGN_CENTER)
            end
            local cubeCenter = {x = w - math.max(120, w * 0.08), y = math.max(80, h * 0.08)}
            local baseScale = math.max(90, math.min(120, w * 0.06))
            local proximityIntensity = 0
            local gameTime = gameStartTime and (currentTime - gameStartTime) or 0
            local baseDistortionTime = gameTime * 0.5
            if EnemiesModule.enemyExists then
                local dx = PlayerModule.squareX - EnemiesModule.enemyX
                local dy = PlayerModule.squareY - EnemiesModule.enemyY
                local dz = PlayerModule.squareZ - EnemiesModule.enemyZ
                local enemyDistance = math.sqrt(dx*dx + dy*dy + dz*dz)
                local maxDistance = 50
                local normalizedDistance = math.min(enemyDistance / maxDistance, 1)
                proximityIntensity = 1 - normalizedDistance
            end
            local distortionTime = baseDistortionTime
            local scaleAnimation = 1 + math.sin(gameTime * 0.2) * 0.05
            local scaleDistortion = 1 + math.sin(distortionTime * 1.5) * proximityIntensity * 0.2
            local cubeScale = baseScale * scaleAnimation * scaleDistortion
            local centerJitterX = math.sin(distortionTime * (2 + proximityIntensity * 1.0)) * proximityIntensity * 8
            local centerJitterY = math.cos(distortionTime * (2.5 + proximityIntensity * 1.2)) * proximityIntensity * 6
            cubeCenter.x = cubeCenter.x + centerJitterX
            cubeCenter.y = cubeCenter.y + centerJitterY
            local projectedVertices = {}
            local baseRotationSpeed = 1.0
            local proximityRotationSpeed = proximityIntensity * 2.0
            local menuRotationX = gameTime * (0.5 * baseRotationSpeed + 0.3 * proximityRotationSpeed) + math.sin(distortionTime * (1 + proximityIntensity)) * proximityIntensity * 0.5
            local menuRotationY = gameTime * (0.8 * baseRotationSpeed + 0.5 * proximityRotationSpeed) + math.cos(distortionTime * (1.2 + proximityIntensity * 0.8)) * proximityIntensity * 0.5
            local menuRotationZ = gameTime * (0.3 * baseRotationSpeed + 0.2 * proximityRotationSpeed) + math.sin(distortionTime * (1.5 + proximityIntensity * 1.2)) * proximityIntensity * 0.5
            for i, vertex in ipairs(cubeVertices) do
                local vertexDistortionX = math.sin(distortionTime * (2 + proximityIntensity * 1.5) + i) * proximityIntensity * 0.15
                local vertexDistortionY = math.cos(distortionTime * (2.2 + proximityIntensity * 1.8) + i) * proximityIntensity * 0.15
                local vertexDistortionZ = math.sin(distortionTime * (2.5 + proximityIntensity * 2.0) + i) * proximityIntensity * 0.15
                local distortedVertex = {
                    vertex[1] + vertexDistortionX,
                    vertex[2] + vertexDistortionY,
                    vertex[3] + vertexDistortionZ
                }
                local px, py, pz = project3D(distortedVertex, cubeCenter.x, cubeCenter.y, cubeScale, menuRotationX, menuRotationY, menuRotationZ)
                projectedVertices[i] = {x = px, y = py, z = pz}
            end
            for edgeIndex, edge in ipairs(cubeEdges) do
                local v1 = projectedVertices[edge[1]]
                local v2 = projectedVertices[edge[2]]
                local avgZ = (v1.z + v2.z) / 2
                local baseIntensity = math.max(100, 255 - avgZ * 30)
                local colorGlitch = math.sin(distortionTime * 10 + edgeIndex) * proximityIntensity
                local redComponent = math.max(0, colorGlitch * 255 * proximityIntensity)
                local greenComponent = baseIntensity * (1 - proximityIntensity * 0.5)
                local blueComponent = baseIntensity
                local flickerChance = math.sin(distortionTime * 15 + edgeIndex * 2) > (0.8 - proximityIntensity * 0.6)
                if flickerChance and proximityIntensity > 0.3 then
                    redComponent = 255
                    greenComponent = 0
                    blueComponent = 0
                end
                local alpha = 200 + math.sin(distortionTime * 3 + edgeIndex) * proximityIntensity * 55
                surface.SetDrawColor(redComponent, greenComponent, blueComponent, alpha)
                surface.DrawLine(v1.x, v1.y, v2.x, v2.y)
                if proximityIntensity > 0.5 then
                    local offset = math.sin(distortionTime * 4 + edgeIndex) * 2
                    surface.SetDrawColor(redComponent * 0.5, greenComponent * 0.5, blueComponent * 0.5, alpha * 0.5)
                    surface.DrawLine(v1.x + offset, v1.y + offset, v2.x + offset, v2.y + offset)
                end
            end
            for i, vertex in ipairs(projectedVertices) do
                local baseIntensity = math.max(150, 255 - vertex.z * 20)
                local colorShift = math.sin(distortionTime * 4 + i * 2) * proximityIntensity
                local redComponent = math.max(0, colorShift * 255 * proximityIntensity)
                local greenComponent = baseIntensity * (1 - proximityIntensity * 0.3)
                local blueComponent = baseIntensity
                local sizeMultiplier = 1 + math.sin(distortionTime * 3 + i) * proximityIntensity * 0.6
                local pointSize = 3 * sizeMultiplier
                local haloSize = 6 * sizeMultiplier
                local vertexFlicker = math.sin(distortionTime * 6 + i * 3) > (0.7 - proximityIntensity * 0.5)
                if vertexFlicker and proximityIntensity > 0.4 then
                    redComponent = 255
                    greenComponent = 50
                    blueComponent = 50
                    pointSize = pointSize * 1.5
                end
                surface.SetDrawColor(redComponent, greenComponent, blueComponent, 255)
                surface.DrawRect(vertex.x - pointSize, vertex.y - pointSize, pointSize * 2, pointSize * 2)
                surface.SetDrawColor(redComponent * 0.5, greenComponent * 0.5, blueComponent * 0.5, 100 + proximityIntensity * 100)
                surface.DrawRect(vertex.x - haloSize, vertex.y - haloSize, haloSize * 2, haloSize * 2)
                if proximityIntensity > 0.6 then
                    local trailOffset = math.sin(distortionTime * 5 + i) * 3
                    surface.SetDrawColor(redComponent * 0.3, greenComponent * 0.3, blueComponent * 0.3, 80)
                    surface.DrawRect(vertex.x - pointSize + trailOffset, vertex.y - pointSize + trailOffset, pointSize * 2, pointSize * 2)
                end
            end
            local gameWindowW = math.min(1000, w * 0.75)
            local gameWindowH = math.min(600, h * 0.65)
            local gameWindowX = (w - gameWindowW) / 2
            local gameWindowY = 120
            surface.SetDrawColor(0, 20, 40, 200)
            surface.DrawRect(gameWindowX, gameWindowY, gameWindowW, gameWindowH)
            surface.SetDrawColor(0, 255, 255, 255)
            surface.DrawOutlinedRect(gameWindowX, gameWindowY, gameWindowW, gameWindowH)
            surface.DrawOutlinedRect(gameWindowX + 1, gameWindowY + 1, gameWindowW - 2, gameWindowH - 2)
            local controlsY = gameWindowY + gameWindowH - 50
            local currentTerrainHeight = TerrainModule.getTerrainHeightAt(PlayerModule.squareX, PlayerModule.squareY)
            local groundStatus = PlayerModule.isOnGround and "On Ground" or "In Air"
            local statusColor = PlayerModule.isOnGround and Color(0, 255, 0) or Color(255, 255, 0)
            local cubeBottom = PlayerModule.squareZ - PlayerModule.squareSize * 0.5
            local distanceToGround = cubeBottom - currentTerrainHeight
            local gameViewX = gameWindowX + 215
            local gameViewY = gameWindowY + 95
            local gameViewW = gameWindowW - 50
            local gameViewH = gameWindowH - 70
            render3DGame(gameViewX, gameViewY, gameViewW, gameViewH, cameraX, cameraY, cameraZ, PlayerModule.cameraPitch, PlayerModule.cameraYaw, PlayerModule.squareX, PlayerModule.squareY, PlayerModule.squareZ)
            if not exitButtonCreated then
                exitButtonCreated = true
                local exitButton = vgui.Create("DButton", digitalFrame)
                exitButton:SetPos(w/2 - 150, h - 80)
                exitButton:SetSize(300, 50)
                exitButton:SetText("")
                exitButton:SetFont("DermaLarge")
                exitButton.Paint = function(self, w, h)
                    local hovered = self:IsHovered()
                    local time = CurTime()
                    local bgAlpha = hovered and 150 or 100
                    local pulseIntensity = math.sin(time * 4) * 20 + 80
                    surface.SetDrawColor(pulseIntensity, 0, 0, bgAlpha)
                    surface.DrawRect(0, 0, w, h)
                    local borderColor = hovered and Color(255, 100, 100) or Color(255, 0, 0)
                    surface.SetDrawColor(borderColor)
                    surface.DrawOutlinedRect(0, 0, w, h)
                    surface.DrawOutlinedRect(1, 1, w-2, h-2)
                    local textColor = hovered and Color(255, 255, 255) or Color(255, 200, 200)
                    draw.DrawText("EXIT", "DermaLarge", w/2, h/2 - 10, textColor, TEXT_ALIGN_CENTER)
                    if hovered then
                        surface.SetDrawColor(255, 150, 150, 100)
                        surface.DrawRect(0, 0, 10, 10)
                        surface.DrawRect(w-10, 0, 10, 10)
                        surface.DrawRect(0, h-10, 10, 10)
                        surface.DrawRect(w-10, h-10, 10, 10)
                    end
                end
                exitButton.DoClick = function()
                    surface.PlaySound("buttons/button14.wav")
                    digitalFrame:Close()
                    _G.UNKNOW_DigitalWorld_Active = false
                    RandomTeleport()
                end
            end
        end
        surface.SetDrawColor(0, 100, 200, 100)
        surface.DrawOutlinedRect(0, 0, w, h)
        surface.DrawOutlinedRect(1, 1, w-2, h-2)
        surface.DrawOutlinedRect(2, 2, w-4, h-4)
    end
    gui.EnableScreenClicker(false)
    vgui.CursorVisible(false)
    return digitalFrame
end
hook.Add("OnPauseMenuShow", "DigitalWorldBlockPauseMenu", function()
    if _G.UNKNOW_DigitalWorld_Active then
        isPaused = not isPaused
        if isPaused then
            gui.EnableScreenClicker(true)
            vgui.CursorVisible(true)
        else
            gui.EnableScreenClicker(false)
            vgui.CursorVisible(false)
        end
        return false
    end
    return true
end)
