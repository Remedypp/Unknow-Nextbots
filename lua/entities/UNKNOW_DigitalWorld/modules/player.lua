local PlayerModule = {}
PlayerModule.squareX = 3
PlayerModule.squareY = 0
PlayerModule.squareZ = 0
PlayerModule.squareSpeed = 0.15
PlayerModule.sprintSpeed = 0.3
PlayerModule.squareSize = 0.5
PlayerModule.squareInitialized = false
PlayerModule.cubeRotationY = 0
PlayerModule.gameRotationX = 0
PlayerModule.gameRotationY = 0
PlayerModule.gameRotationZ = 0
PlayerModule.maxStamina = 100
PlayerModule.currentStamina = 100
PlayerModule.staminaDrainRate = 20
PlayerModule.staminaRegenRate = 12
PlayerModule.minStaminaToSprint = 15
PlayerModule.isSprinting = false
PlayerModule.staminaCooldownTime = 2
PlayerModule.staminaCooldownTimer = 0
PlayerModule.isStaminaOnCooldown = false
PlayerModule.staminaRegenDelay = 1.5
PlayerModule.staminaRegenDelayTimer = 0
PlayerModule.isStaminaRegenerating = true
PlayerModule.breathingHeavy = false
PlayerModule.breathingTimer = 0
PlayerModule.squareVelocityZ = 0
PlayerModule.jumpPower = 12
PlayerModule.gravity = -18
PlayerModule.isOnGround = true
PlayerModule.groundLevel = 0
PlayerModule.coyoteTime = 0.15
PlayerModule.coyoteTimer = 0
PlayerModule.jumpBuffer = 0.1
PlayerModule.jumpBufferTimer = 0
PlayerModule.lastJumpTime = 0
PlayerModule.jumpCooldown = 0.1
PlayerModule.jumpStartTime = 0
PlayerModule.cameraDistance = 10
PlayerModule.cameraHeight = 6
PlayerModule.cameraYaw = 45
PlayerModule.cameraPitch = 25
PlayerModule.targetCameraYaw = 45
PlayerModule.targetCameraPitch = 25
PlayerModule.mouseSensitivity = 0.2
PlayerModule.cameraSmoothing = 0.12
PlayerModule.lastMouseX = 0
PlayerModule.lastMouseY = 0
PlayerModule.smoothMoveX = 0
PlayerModule.smoothMoveY = 0
PlayerModule.currentMovementSpeed = 0
PlayerModule.baseSquareVertices = {
    {-1, -1, -1}, {1, -1, -1}, {1, 1, -1}, {-1, 1, -1},
    {-1, -1, 1}, {1, -1, 1}, {1, 1, 1}, {-1, 1, 1}
}
function PlayerModule.getSquareVertices()
    local vertices = {}
    for i, vertex in ipairs(PlayerModule.baseSquareVertices) do
        vertices[i] = {
            vertex[1] * PlayerModule.squareSize,
            vertex[2] * PlayerModule.squareSize,
            vertex[3] * PlayerModule.squareSize
        }
    end
    return vertices
end
function PlayerModule.initializePosition(getTerrainHeightAt)
    if not PlayerModule.squareInitialized then
        local initialTerrainHeight = getTerrainHeightAt(PlayerModule.squareX, PlayerModule.squareY)
        PlayerModule.squareZ = initialTerrainHeight + PlayerModule.squareSize * 0.5
        PlayerModule.squareInitialized = true
    end
end
function PlayerModule.updateStamina(deltaTime, isShiftPressed, isMoving)
    if PlayerModule.isStaminaOnCooldown then
        PlayerModule.staminaCooldownTimer = PlayerModule.staminaCooldownTimer - deltaTime
        if PlayerModule.staminaCooldownTimer <= 0 then
            PlayerModule.isStaminaOnCooldown = false
            PlayerModule.staminaCooldownTimer = 0
            PlayerModule.staminaRegenDelayTimer = PlayerModule.staminaRegenDelay
        end
    end
    if PlayerModule.staminaRegenDelayTimer > 0 then
        PlayerModule.staminaRegenDelayTimer = PlayerModule.staminaRegenDelayTimer - deltaTime
        if PlayerModule.staminaRegenDelayTimer <= 0 then
            PlayerModule.isStaminaRegenerating = true
        end
    end
    if isShiftPressed and isMoving and PlayerModule.currentStamina >= PlayerModule.minStaminaToSprint and not PlayerModule.isStaminaOnCooldown then
        PlayerModule.isSprinting = true
        PlayerModule.isStaminaRegenerating = false
        PlayerModule.staminaRegenDelayTimer = PlayerModule.staminaRegenDelay
        local drainMultiplier = 1.0
        if PlayerModule.currentStamina < 30 then
            drainMultiplier = 1.5
        end
        PlayerModule.currentStamina = math.max(0, PlayerModule.currentStamina - PlayerModule.staminaDrainRate * deltaTime * drainMultiplier)
        if PlayerModule.currentStamina <= 0 then
            PlayerModule.isSprinting = false
            PlayerModule.isStaminaOnCooldown = true
            PlayerModule.staminaCooldownTimer = PlayerModule.staminaCooldownTime
            PlayerModule.breathingHeavy = true
            PlayerModule.breathingTimer = 5.0
        end
    else
        PlayerModule.isSprinting = false
        if PlayerModule.currentStamina < PlayerModule.maxStamina and not PlayerModule.isStaminaOnCooldown and PlayerModule.isStaminaRegenerating then
            local regenMultiplier = 1.0
            if PlayerModule.breathingHeavy then
                regenMultiplier = 0.5
            end
            if PlayerModule.currentStamina < 20 then
                regenMultiplier = regenMultiplier * 0.7
            end
            PlayerModule.currentStamina = math.min(PlayerModule.maxStamina, PlayerModule.currentStamina + PlayerModule.staminaRegenRate * deltaTime * regenMultiplier)
        end
    end
    if PlayerModule.breathingHeavy then
        PlayerModule.breathingTimer = PlayerModule.breathingTimer - deltaTime
        if PlayerModule.breathingTimer <= 0 then
            PlayerModule.breathingHeavy = false
            PlayerModule.breathingTimer = 0
        end
    end
end
function PlayerModule.processInput(isPaused)
    if isPaused then return 0, 0, false end
    local inputForward = 0
    local inputRight = 0
    if input.IsKeyDown(KEY_W) then inputForward = inputForward + 1 end
    if input.IsKeyDown(KEY_S) then inputForward = inputForward - 1 end
    if input.IsKeyDown(KEY_A) then inputRight = inputRight - 1 end
    if input.IsKeyDown(KEY_D) then inputRight = inputRight + 1 end
    local hasMovementInput = (inputForward ~= 0 or inputRight ~= 0)
    return inputForward, inputRight, hasMovementInput
end
function PlayerModule.updateMovement(inputForward, inputRight, hasMovementInput, cameraYaw, deltaTime)
    local characterRotationSpeed = 0.08
    local visualEffectSmoothing = 0.12
    local movementAcceleration = 0.15
    local movementDeceleration = 0.12
    local targetWorldMoveX = 0
    local targetWorldMoveY = 0
    if hasMovementInput then
        local inputMagnitude = math.sqrt(inputForward * inputForward + inputRight * inputRight)
        if inputMagnitude > 0 then
            inputForward = inputForward / inputMagnitude
            inputRight = inputRight / inputMagnitude
        end
        local cameraYawRad = math.rad(cameraYaw)
        local cameraForwardX = math.cos(cameraYawRad)
        local cameraForwardY = math.sin(cameraYawRad)
        local cameraRightX = math.sin(cameraYawRad)
        local cameraRightY = -math.cos(cameraYawRad)
        targetWorldMoveX = (cameraForwardX * inputForward) + (cameraRightX * inputRight)
        targetWorldMoveY = (cameraForwardY * inputForward) + (cameraRightY * inputRight)
        local worldMoveMagnitude = math.sqrt(targetWorldMoveX * targetWorldMoveX + targetWorldMoveY * targetWorldMoveY)
        if worldMoveMagnitude > 0 then
            targetWorldMoveX = targetWorldMoveX / worldMoveMagnitude
            targetWorldMoveY = targetWorldMoveY / worldMoveMagnitude
        end
    end
    if hasMovementInput then
        PlayerModule.currentMovementSpeed = math.min(1.0, PlayerModule.currentMovementSpeed + movementAcceleration * FrameTime() * 60)
    else
        PlayerModule.currentMovementSpeed = math.max(0.0, PlayerModule.currentMovementSpeed - movementDeceleration * FrameTime() * 60)
    end
    PlayerModule.smoothMoveX = PlayerModule.smoothMoveX + (targetWorldMoveX - PlayerModule.smoothMoveX) * movementAcceleration
    PlayerModule.smoothMoveY = PlayerModule.smoothMoveY + (targetWorldMoveY - PlayerModule.smoothMoveY) * movementAcceleration
    if PlayerModule.currentMovementSpeed > 0.1 then
        local targetCharacterAngle = math.atan2(PlayerModule.smoothMoveY, PlayerModule.smoothMoveX) * (180 / math.pi)
        local angleDiff = targetCharacterAngle - PlayerModule.cubeRotationY
        while angleDiff > 180 do angleDiff = angleDiff - 360 end
        while angleDiff < -180 do angleDiff = angleDiff + 360 end
        local rotationSpeedAdjusted = characterRotationSpeed * PlayerModule.currentMovementSpeed
        PlayerModule.cubeRotationY = PlayerModule.cubeRotationY + angleDiff * rotationSpeedAdjusted
        local targetTiltZ = inputRight * 8 * PlayerModule.currentMovementSpeed
        local targetTiltX = -inputForward * 3 * PlayerModule.currentMovementSpeed
        PlayerModule.gameRotationZ = PlayerModule.gameRotationZ + (targetTiltZ - PlayerModule.gameRotationZ) * visualEffectSmoothing
        PlayerModule.gameRotationX = PlayerModule.gameRotationX + (targetTiltX - PlayerModule.gameRotationX) * visualEffectSmoothing
    else
        PlayerModule.gameRotationZ = PlayerModule.gameRotationZ * 0.9
        PlayerModule.gameRotationX = PlayerModule.gameRotationX * 0.9
    end
    local currentSpeed = PlayerModule.isSprinting and PlayerModule.sprintSpeed or PlayerModule.squareSpeed
    local moveX = PlayerModule.smoothMoveX * PlayerModule.currentMovementSpeed
    local moveY = PlayerModule.smoothMoveY * PlayerModule.currentMovementSpeed
    local newX = PlayerModule.squareX + moveX * currentSpeed
    local newY = PlayerModule.squareY + moveY * currentSpeed
    if PlayerModule.checkTrappedMovement then
        local canMove = PlayerModule.checkTrappedMovement(newX, newY, PlayerModule.squareZ)
        if canMove then
            PlayerModule.squareX = newX
            PlayerModule.squareY = newY
        end
    else
        PlayerModule.squareX = newX
        PlayerModule.squareY = newY
    end
end
function PlayerModule.handleJump(isPaused, deltaTime)
    if isPaused then return end
    local currentTime = CurTime()
    if PlayerModule.coyoteTimer > 0 then
        PlayerModule.coyoteTimer = PlayerModule.coyoteTimer - deltaTime
    end
    if PlayerModule.jumpBufferTimer > 0 then
        PlayerModule.jumpBufferTimer = PlayerModule.jumpBufferTimer - deltaTime
    end
    if input.IsKeyDown(KEY_SPACE) then
        PlayerModule.jumpBufferTimer = PlayerModule.jumpBuffer
    end
    local canJump = false
    local timeSinceLastJump = currentTime - PlayerModule.lastJumpTime
    if timeSinceLastJump >= PlayerModule.jumpCooldown then
        if PlayerModule.isOnGround then
            canJump = true
        elseif PlayerModule.coyoteTimer > 0 then
            canJump = true
        end
    end
    if PlayerModule.jumpBufferTimer > 0 and canJump then
        PlayerModule.squareVelocityZ = PlayerModule.jumpPower
        PlayerModule.isOnGround = false
        PlayerModule.coyoteTimer = 0
        PlayerModule.jumpBufferTimer = 0
        PlayerModule.lastJumpTime = currentTime
        PlayerModule.jumpStartTime = currentTime
    end
end
function PlayerModule.handleSizeChange(isPaused)
    if isPaused then return end
    if input.IsKeyDown(KEY_EQUAL) then
        PlayerModule.squareSize = math.min(PlayerModule.squareSize + 0.02, 5.0)
    end
    if input.IsKeyDown(KEY_MINUS) then
        PlayerModule.squareSize = math.max(PlayerModule.squareSize - 0.02, 0.2)
    end
end
function PlayerModule.updatePhysics(deltaTime)
    local currentTime = CurTime()
    local gravity = PlayerModule.gravity
    if PlayerModule.jumpStartTime and (currentTime - PlayerModule.jumpStartTime) < 0.2 then
        if PlayerModule.squareVelocityZ > 0 then
            gravity = gravity * 0.8
        end
    end
    PlayerModule.squareVelocityZ = PlayerModule.squareVelocityZ + gravity * deltaTime
    PlayerModule.squareZ = PlayerModule.squareZ + PlayerModule.squareVelocityZ * deltaTime
end
function PlayerModule.handleTerrainCollision(getTerrainHeightAt)
    local halfSize = PlayerModule.squareSize * 0.5
    local cornerOffsets = {
        {-halfSize, -halfSize}, {halfSize, -halfSize},
        {-halfSize, halfSize}, {halfSize, halfSize},
        {0, 0}
    }
    local maxTerrainHeight = -999999
    for _, offset in ipairs(cornerOffsets) do
        local checkX = PlayerModule.squareX + offset[1]
        local checkY = PlayerModule.squareY + offset[2]
        local terrainHeight = getTerrainHeightAt(checkX, checkY)
        maxTerrainHeight = math.max(maxTerrainHeight, terrainHeight)
    end
    local cubeBottom = PlayerModule.squareZ - halfSize
    local wasOnGround = PlayerModule.isOnGround
    if cubeBottom <= maxTerrainHeight then
        PlayerModule.squareZ = maxTerrainHeight + halfSize
        PlayerModule.squareVelocityZ = 0
        PlayerModule.isOnGround = true
        PlayerModule.coyoteTimer = 0
    else
        PlayerModule.isOnGround = false
        if wasOnGround and PlayerModule.coyoteTimer <= 0 then
            PlayerModule.coyoteTimer = PlayerModule.coyoteTime
        end
    end
end
PlayerModule.mouseCaptured = false
function PlayerModule.updateCamera(isPaused)
    if not isPaused then
        local screenW, screenH = ScrW(), ScrH()
        local centerX, centerY = screenW / 2, screenH / 2
        local mouseX, mouseY = input.GetCursorPos()
        if not PlayerModule.mouseCaptured then
            input.SetCursorPos(centerX, centerY)
            PlayerModule.lastMouseX = centerX
            PlayerModule.lastMouseY = centerY
            PlayerModule.mouseCaptured = true
        else
            local deltaX = mouseX - centerX
            local deltaY = mouseY - centerY
            if math.abs(deltaX) > 1 or math.abs(deltaY) > 1 then
                PlayerModule.targetCameraYaw = PlayerModule.targetCameraYaw - deltaX * PlayerModule.mouseSensitivity
                PlayerModule.targetCameraPitch = PlayerModule.targetCameraPitch + deltaY * PlayerModule.mouseSensitivity
                PlayerModule.targetCameraPitch = math.Clamp(PlayerModule.targetCameraPitch, -89, 89)
                input.SetCursorPos(centerX, centerY)
            end
        end
    else
        PlayerModule.mouseCaptured = false
    end
    PlayerModule.cameraYaw = PlayerModule.cameraYaw + (PlayerModule.targetCameraYaw - PlayerModule.cameraYaw) * PlayerModule.cameraSmoothing
    PlayerModule.cameraPitch = PlayerModule.cameraPitch + (PlayerModule.targetCameraPitch - PlayerModule.cameraPitch) * PlayerModule.cameraSmoothing
    local wheelDelta = input.GetAnalogValue(ANALOG_JOY_Z)
    if wheelDelta ~= 0 then
        PlayerModule.cameraDistance = PlayerModule.cameraDistance - wheelDelta * 2
        PlayerModule.cameraDistance = math.Clamp(PlayerModule.cameraDistance, 5, 25)
    end
end
function PlayerModule.getCameraPosition()
    local yawRad = math.rad(PlayerModule.cameraYaw)
    local pitchRad = math.rad(PlayerModule.cameraPitch)
    local cameraX = PlayerModule.squareX - PlayerModule.cameraDistance * math.cos(pitchRad) * math.cos(yawRad)
    local cameraY = PlayerModule.squareY - PlayerModule.cameraDistance * math.cos(pitchRad) * math.sin(yawRad)
    local cameraZ = PlayerModule.squareZ + PlayerModule.cameraHeight + PlayerModule.cameraDistance * math.sin(pitchRad)
    return cameraX, cameraY, cameraZ
end
function PlayerModule.getRotationIndicator()
    local rotationIndicator = "Idle"
    local indicatorColor = Color(255, 255, 255)
    if input.IsKeyDown(KEY_W) then
        rotationIndicator = "Rolling Forward"
        indicatorColor = Color(0, 255, 0)
    elseif input.IsKeyDown(KEY_S) then
        rotationIndicator = "Rolling Backward"
        indicatorColor = Color(255, 100, 0)
    elseif input.IsKeyDown(KEY_A) then
        rotationIndicator = "Rolling Left"
        indicatorColor = Color(0, 100, 255)
    elseif input.IsKeyDown(KEY_D) then
        rotationIndicator = "Rolling Right"
        indicatorColor = Color(255, 0, 255)
    end
    return rotationIndicator, indicatorColor
end
function PlayerModule.update(isPaused, getTerrainHeightAt, deltaTime)
    PlayerModule.initializePosition(getTerrainHeightAt)
    local inputForward, inputRight, hasMovementInput = PlayerModule.processInput(isPaused)
    local isShiftPressed = input.IsKeyDown(KEY_LSHIFT) or input.IsKeyDown(KEY_RSHIFT)
    local isMoving = PlayerModule.currentMovementSpeed > 0.1
    PlayerModule.updateCamera(isPaused)
    PlayerModule.updateStamina(deltaTime, isShiftPressed, isMoving)
    PlayerModule.updateMovement(inputForward, inputRight, hasMovementInput, PlayerModule.cameraYaw, deltaTime)
    PlayerModule.handleJump(isPaused, deltaTime)
    PlayerModule.handleSizeChange(isPaused)
    PlayerModule.updatePhysics(deltaTime)
    PlayerModule.handleTerrainCollision(getTerrainHeightAt)
end
function PlayerModule.setTrappedMovementCheck(checkFunction)
    PlayerModule.checkTrappedMovement = checkFunction
end
function PlayerModule.getPlayerPosition()
    return {
        x = PlayerModule.squareX,
        y = PlayerModule.squareY,
        z = PlayerModule.squareZ,
        size = PlayerModule.squareSize
    }
end
PlayerModule.isBeingChased = false
PlayerModule.chaseWarningTime = 0
PlayerModule.lastChaseDistance = 0
PlayerModule.chaseIntensity = 0
function PlayerModule.detectRectangleChase(whiteRectangle)
    if not whiteRectangle or not whiteRectangle.isCorrupted then
        PlayerModule.isBeingChased = false
        PlayerModule.chaseIntensity = 0
        return false
    end
    if whiteRectangle.isChasing then
        PlayerModule.isBeingChased = true
        local dx = PlayerModule.squareX - whiteRectangle.x
        local dy = PlayerModule.squareY - whiteRectangle.y
        local distance = math.sqrt(dx * dx + dy * dy)
        if distance <= 10 then
            PlayerModule.chaseIntensity = 1.0
        elseif distance <= 20 then
            PlayerModule.chaseIntensity = 0.7
        elseif distance <= 30 then
            PlayerModule.chaseIntensity = 0.4
        else
            PlayerModule.chaseIntensity = 0.2
        end
        PlayerModule.lastChaseDistance = distance
        return true
    else
        PlayerModule.isBeingChased = false
        PlayerModule.chaseIntensity = 0
        return false
    end
end
function PlayerModule.getChaseStatus()
    return {
        isBeingChased = PlayerModule.isBeingChased,
        chaseIntensity = PlayerModule.chaseIntensity,
        lastDistance = PlayerModule.lastChaseDistance
    }
end
function PlayerModule.updateChaseEffects(deltaTime)
    if PlayerModule.isBeingChased then
        PlayerModule.chaseWarningTime = PlayerModule.chaseWarningTime + deltaTime
        if PlayerModule.chaseIntensity > 0.5 then
            PlayerModule.staminaRegenRate = 18
        else
            PlayerModule.staminaRegenRate = 12
        end
    else
        PlayerModule.chaseWarningTime = 0
        PlayerModule.staminaRegenRate = 12
    end
end
return PlayerModule
