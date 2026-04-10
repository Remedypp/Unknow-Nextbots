local eye_material = Material("hide/ERROR/unknow_eye.png", "noclamp smooth")
local pupil_material = Material("hide/ERROR/unknow_eye1.png", "noclamp smooth")
local blink_materials = {}
for i = 1, 5 do
    blink_materials[i] = Material("hide/ERROR/blink/unknow_blink" .. i .. ".png", "noclamp smooth")
end
local menuScareActive = false
local menuScareStartTime = 0
local menuScareY = 0
local targetY = 0
local currentPupilX = 0
local currentPupilY = 0
local currentBlinkFrame = 5
local ANIMATION_DURATION = 0.8
local EYE_OPEN_DURATION = 0.4
local BLINK_FRAME_TIME = 0.12
local EYE_SIZE = 300
local PUPIL_SIZE = 280
local PUPIL_RANGE_X = 40
local PUPIL_RANGE_Y = 25
local EYE_MASK_POINTS = 32
local function IsBeingChased()
    for _, ent in ipairs(ents.FindByClass("UNKNOW")) do
        if IsValid(ent) then
            local state = ent:GetNWInt("EyeState", 1)
            if state == 1 then
                return true, ent
            end
        end
    end
    return false, nil
end
local function StartMenuScare()
    if menuScareActive then return end
    local isChased, ent = IsBeingChased()
    if not isChased then return end
    menuScareActive = true
    menuScareStartTime = RealTime()
    menuScareY = ScrH() + EYE_SIZE
    targetY = ScrH() * 0.5
    surface.PlaySound("ambient/levels/citadel/strange_talk" .. math.random(1, 11) .. ".wav")
end
local function StopMenuScare()
    if not menuScareActive then return end
    menuScareActive = false
end
local function DrawEyeMask(centerX, centerY, width, height)
    local points = {}
    for i = 0, EYE_MASK_POINTS - 1 do
        local angle = (i / EYE_MASK_POINTS) * math.pi * 2
        local x = centerX + math.cos(angle) * (width / 2)
        local y = centerY + math.sin(angle) * (height / 2)
        table.insert(points, {x = x, y = y})
    end
    surface.SetDrawColor(255, 255, 255, 255)
    draw.NoTexture()
    surface.DrawPoly(points)
end
local function DrawMenuScare()
    if not menuScareActive then return end
    local ct = RealTime()
    local elapsed = ct - menuScareStartTime
    local progress = math.Clamp(elapsed / ANIMATION_DURATION, 0, 1)
    local easeProgress = 1 - math.pow(1 - progress, 3)
    local startY = ScrH() + EYE_SIZE
    menuScareY = Lerp(easeProgress, startY, targetY)
    local frameTime = elapsed / BLINK_FRAME_TIME
    local frameNumber = math.floor(frameTime)
    if frameNumber >= 4 then
        currentBlinkFrame = 1
    else
        currentBlinkFrame = 5 - frameNumber
    end
    currentBlinkFrame = math.Clamp(currentBlinkFrame, 1, 5)
    local centerX = ScrW() * 0.5
    local centerY = menuScareY
    local mouseX, mouseY = gui.MousePos()
    local deltaX = (mouseX - centerX) / (ScrW() * 0.5)
    local deltaY = (mouseY - centerY) / (ScrH() * 0.5)
    local targetPupilX = math.Clamp(deltaX, -1, 1) * PUPIL_RANGE_X
    local targetPupilY = math.Clamp(deltaY, -1, 1) * PUPIL_RANGE_Y
    currentPupilX = Lerp(0.15, currentPupilX, targetPupilX)
    currentPupilY = Lerp(0.15, currentPupilY, targetPupilY)
    local eyeW = EYE_SIZE
    local eyeH = EYE_SIZE * 0.65
    surface.SetDrawColor(255, 255, 255, 255)
    if currentBlinkFrame > 1 then
        surface.SetMaterial(blink_materials[currentBlinkFrame])
    else
        surface.SetMaterial(eye_material)
    end
    surface.DrawTexturedRect(
        centerX - eyeW / 2,
        centerY - eyeH / 2,
        eyeW,
        eyeH
    )
    render.ClearStencil()
    render.SetStencilEnable(true)
    render.SetStencilWriteMask(255)
    render.SetStencilTestMask(255)
    render.SetStencilReferenceValue(1)
    render.SetStencilCompareFunction(STENCIL_ALWAYS)
    render.SetStencilPassOperation(STENCIL_REPLACE)
    render.SetStencilFailOperation(STENCIL_KEEP)
    render.SetStencilZFailOperation(STENCIL_KEEP)
    render.OverrideColorWriteEnable(true, false)
    DrawEyeMask(centerX, centerY, eyeW * 0.85, eyeH * 0.75)
    render.OverrideColorWriteEnable(false, false)
    render.SetStencilCompareFunction(STENCIL_EQUAL)
    local pupilW = PUPIL_SIZE
    local pupilH = PUPIL_SIZE * 0.65
    surface.SetMaterial(pupil_material)
    surface.DrawTexturedRect(
        centerX - pupilW / 2 + currentPupilX,
        centerY - pupilH / 2 + currentPupilY,
        pupilW,
        pupilH
    )
    render.SetStencilEnable(false)
end
hook.Add("DrawOverlay", "UNKNOW_MenuScare", function()
    DrawMenuScare()
end)
hook.Add("OnPauseMenuShow", "UNKNOW_MenuScareStart", function()
    StartMenuScare()
end)
hook.Add("OnPauseMenuHide", "UNKNOW_MenuScareStop", function()
    StopMenuScare()
end)
local wasMenuOpen = false
hook.Add("Think", "UNKNOW_MenuScareThink", function()
    local isMenuOpen = gui.IsGameUIVisible()
    if isMenuOpen and not wasMenuOpen then
        StartMenuScare()
    elseif not isMenuOpen and wasMenuOpen then
        StopMenuScare()
    end
    wasMenuOpen = isMenuOpen
end)
