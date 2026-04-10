if not CLIENT then return end
local iconStatic = Material("hide/ICONS/hide_icon.png")
local iconAnim   = Material("hide/ICONS/hide_icon.vtf")
local totalFrames     = 35
local blinkDuration   = 1.5
local currentFrame    = 0
local isBlinking      = false
local nextBlinkTime   = 0
local iconNodes       = {}
local function SetNodeIcon(node)
    if not IsValid(node) then return end
    if node:GetText() == "Unknown Nextbot's" and IsValid(node.Icon) then
        node.Icon:SetMaterial(iconStatic)
        node.IsReworkIcon = true
        table.insert(iconNodes, node)
    end
end
local function AnimateIcons()
    if CurTime() < nextBlinkTime and not isBlinking then return end
    if currentFrame == 0 and not isBlinking then
        nextBlinkTime = CurTime() + math.random(15, 30)
        currentFrame  = 1
        isBlinking    = true
        for _, node in ipairs(iconNodes) do
            if IsValid(node) and IsValid(node.Icon) then
                node.Icon:SetMaterial(iconAnim)
            end
        end
    end
    if isBlinking then
        iconAnim:SetInt("$frame", currentFrame - 1)
        currentFrame = currentFrame + 1
        if currentFrame >= totalFrames then
            currentFrame = 0
            isBlinking   = false
            for _, node in ipairs(iconNodes) do
                if IsValid(node) and IsValid(node.Icon) then
                    node.Icon:SetMaterial(iconStatic)
                end
            end
        else
            timer.Simple(blinkDuration / totalFrames, AnimateIcons)
        end
    end
end
hook.Add("PopulateEntities", "REWORK_SpawnMenuIcon", function(_, tree)
    timer.Simple(0.1, function()
        if not IsValid(tree) or type(tree.Root) ~= "function" then return end
        local root = tree:Root()
        if not root then return end
        for _, node in pairs(root:GetChildNodes()) do
            SetNodeIcon(node)
        end
    end)
end)
hook.Add("PopulateNPCs", "REWORK_SpawnMenuIcon", function(_, tree)
    timer.Simple(0.1, function()
        if not IsValid(tree) or type(tree.Root) ~= "function" then return end
        local root = tree:Root()
        if not root then return end
        for _, node in pairs(root:GetChildNodes()) do
            SetNodeIcon(node)
        end
    end)
end)
hook.Add("Think", "REWORK_IconAnimation", AnimateIcons)
