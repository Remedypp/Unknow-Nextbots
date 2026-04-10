local PhysicsModule = {}
PhysicsModule.DEFAULT_GRAVITY = -18
PhysicsModule.DEFAULT_JUMP_POWER = 12
PhysicsModule.DEFAULT_FRICTION = 0.8
PhysicsModule.DEFAULT_AIR_RESISTANCE = 0.95
PhysicsModule.COLLISION_TOLERANCE = 0.1
function PhysicsModule.createPhysicsObject(x, y, z, size)
    return {
        x = x or 0,
        y = y or 0,
        z = z or 0,
        velocityX = 0,
        velocityY = 0,
        velocityZ = 0,
        size = size or 1,
        mass = 1,
        gravity = PhysicsModule.DEFAULT_GRAVITY,
        jumpPower = PhysicsModule.DEFAULT_JUMP_POWER,
        friction = PhysicsModule.DEFAULT_FRICTION,
        airResistance = PhysicsModule.DEFAULT_AIR_RESISTANCE,
        isOnGround = false,
        groundLevel = 0,
        canJump = true,
        collisionEnabled = true,
        boundingBox = {
            minX = -size/2, maxX = size/2,
            minY = -size/2, maxY = size/2,
            minZ = -size/2, maxZ = size/2
        }
    }
end
function PhysicsModule.applyGravity(physicsObject, deltaTime)
    if not physicsObject.isOnGround then
        physicsObject.velocityZ = physicsObject.velocityZ + physicsObject.gravity * deltaTime
    end
end
function PhysicsModule.applyFriction(physicsObject, deltaTime)
    if physicsObject.isOnGround then
        physicsObject.velocityX = physicsObject.velocityX * physicsObject.friction
        physicsObject.velocityY = physicsObject.velocityY * physicsObject.friction
    else
        physicsObject.velocityX = physicsObject.velocityX * physicsObject.airResistance
        physicsObject.velocityY = physicsObject.velocityY * physicsObject.airResistance
    end
end
function PhysicsModule.updatePosition(physicsObject, deltaTime)
    physicsObject.x = physicsObject.x + physicsObject.velocityX * deltaTime
    physicsObject.y = physicsObject.y + physicsObject.velocityY * deltaTime
    physicsObject.z = physicsObject.z + physicsObject.velocityZ * deltaTime
    local halfSize = physicsObject.size * 0.5
    physicsObject.boundingBox.minX = physicsObject.x - halfSize
    physicsObject.boundingBox.maxX = physicsObject.x + halfSize
    physicsObject.boundingBox.minY = physicsObject.y - halfSize
    physicsObject.boundingBox.maxY = physicsObject.y + halfSize
    physicsObject.boundingBox.minZ = physicsObject.z - halfSize
    physicsObject.boundingBox.maxZ = physicsObject.z + halfSize
end
function PhysicsModule.jump(physicsObject)
    if physicsObject.canJump and physicsObject.isOnGround then
        physicsObject.velocityZ = physicsObject.jumpPower
        physicsObject.isOnGround = false
        physicsObject.canJump = false
        return true
    end
    return false
end
function PhysicsModule.checkTerrainCollision(physicsObject, getTerrainHeightAt)
    if not physicsObject.collisionEnabled then return false end
    local halfSize = physicsObject.size * 0.5
    local cubeBottom = physicsObject.z - halfSize
    local checkPoints = {
        {physicsObject.x - halfSize * 0.8, physicsObject.y - halfSize * 0.8},
        {physicsObject.x + halfSize * 0.8, physicsObject.y - halfSize * 0.8},
        {physicsObject.x - halfSize * 0.8, physicsObject.y + halfSize * 0.8},
        {physicsObject.x + halfSize * 0.8, physicsObject.y + halfSize * 0.8},
        {physicsObject.x, physicsObject.y}
    }
    local maxTerrainHeight = -999999
    for _, point in ipairs(checkPoints) do
        local terrainHeight = getTerrainHeightAt(point[1], point[2])
        maxTerrainHeight = math.max(maxTerrainHeight, terrainHeight)
    end
    if cubeBottom <= maxTerrainHeight + PhysicsModule.COLLISION_TOLERANCE then
        physicsObject.z = maxTerrainHeight + halfSize
        physicsObject.velocityZ = 0
        physicsObject.isOnGround = true
        physicsObject.canJump = true
        physicsObject.groundLevel = maxTerrainHeight
        return true
    else
        physicsObject.isOnGround = false
        return false
    end
end
function PhysicsModule.checkObjectCollision(obj1, obj2)
    if not obj1.collisionEnabled or not obj2.collisionEnabled then return false end
    local bb1 = obj1.boundingBox
    local bb2 = obj2.boundingBox
    return not (bb1.maxX < bb2.minX or bb1.minX > bb2.maxX or
                bb1.maxY < bb2.minY or bb1.minY > bb2.maxY or
                bb1.maxZ < bb2.minZ or bb1.minZ > bb2.maxZ)
end
function PhysicsModule.resolveObjectCollision(obj1, obj2)
    if not PhysicsModule.checkObjectCollision(obj1, obj2) then return end
    local dx = obj2.x - obj1.x
    local dy = obj2.y - obj1.y
    local dz = obj2.z - obj1.z
    local distance = math.sqrt(dx*dx + dy*dy + dz*dz)
    if distance == 0 then return end
    dx = dx / distance
    dy = dy / distance
    dz = dz / distance
    local overlap = (obj1.size + obj2.size) * 0.5 - distance
    if overlap > 0 then
        local separation = overlap * 0.5
        obj1.x = obj1.x - dx * separation
        obj1.y = obj1.y - dy * separation
        obj1.z = obj1.z - dz * separation
        obj2.x = obj2.x + dx * separation
        obj2.y = obj2.y + dy * separation
        obj2.z = obj2.z + dz * separation
    end
    local v1n = obj1.velocityX * dx + obj1.velocityY * dy + obj1.velocityZ * dz
    local v2n = obj2.velocityX * dx + obj2.velocityY * dy + obj2.velocityZ * dz
    obj1.velocityX = obj1.velocityX - v1n * dx + v2n * dx
    obj1.velocityY = obj1.velocityY - v1n * dy + v2n * dy
    obj1.velocityZ = obj1.velocityZ - v1n * dz + v2n * dz
    obj2.velocityX = obj2.velocityX - v2n * dx + v1n * dx
    obj2.velocityY = obj2.velocityY - v2n * dy + v1n * dy
    obj2.velocityZ = obj2.velocityZ - v2n * dz + v1n * dz
end
function PhysicsModule.applyForce(physicsObject, forceX, forceY, forceZ, deltaTime)
    local accelerationX = forceX / physicsObject.mass
    local accelerationY = forceY / physicsObject.mass
    local accelerationZ = forceZ / physicsObject.mass
    physicsObject.velocityX = physicsObject.velocityX + accelerationX * deltaTime
    physicsObject.velocityY = physicsObject.velocityY + accelerationY * deltaTime
    physicsObject.velocityZ = physicsObject.velocityZ + accelerationZ * deltaTime
end
function PhysicsModule.setVelocity(physicsObject, velocityX, velocityY, velocityZ)
    physicsObject.velocityX = velocityX or physicsObject.velocityX
    physicsObject.velocityY = velocityY or physicsObject.velocityY
    physicsObject.velocityZ = velocityZ or physicsObject.velocityZ
end
function PhysicsModule.getDistance(obj1, obj2)
    local dx = obj2.x - obj1.x
    local dy = obj2.y - obj1.y
    local dz = obj2.z - obj1.z
    return math.sqrt(dx*dx + dy*dy + dz*dz)
end
function PhysicsModule.updatePhysics(physicsObject, deltaTime, getTerrainHeightAt)
    PhysicsModule.applyGravity(physicsObject, deltaTime)
    PhysicsModule.applyFriction(physicsObject, deltaTime)
    PhysicsModule.updatePosition(physicsObject, deltaTime)
    if getTerrainHeightAt then
        PhysicsModule.checkTerrainCollision(physicsObject, getTerrainHeightAt)
    end
end
function PhysicsModule.getPhysicsInfo(physicsObject)
    return {
        position = {physicsObject.x, physicsObject.y, physicsObject.z},
        velocity = {physicsObject.velocityX, physicsObject.velocityY, physicsObject.velocityZ},
        isOnGround = physicsObject.isOnGround,
        groundLevel = physicsObject.groundLevel,
        canJump = physicsObject.canJump
    }
end
function PhysicsModule.resetPhysics(physicsObject, x, y, z)
    physicsObject.x = x or physicsObject.x
    physicsObject.y = y or physicsObject.y
    physicsObject.z = z or physicsObject.z
    physicsObject.velocityX = 0
    physicsObject.velocityY = 0
    physicsObject.velocityZ = 0
    physicsObject.isOnGround = false
    physicsObject.canJump = true
end
return PhysicsModule
