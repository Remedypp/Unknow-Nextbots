AddCSLuaFile("cl_init.lua")
AddCSLuaFile("shared.lua")
include("shared.lua")
function ENT:Initialize()
    self:SetModel("models/hunter/blocks/cube025x025x025.mdl")
    self:PhysicsInit(SOLID_VPHYSICS)
    self:SetMoveType(MOVETYPE_VPHYSICS)
    self:SetSolid(SOLID_VPHYSICS)
    self:SetUseType(SIMPLE_USE)
    self:SetNoDraw(true)
    self:SetNotSolid(true)
    local phys = self:GetPhysicsObject()
    if IsValid(phys) then
        phys:Wake()
        phys:EnableMotion(false)
    end
    self:SetMaxHealth(100)
    self:SetHealth(100)
    self:SetupCvarSecurity()
end
function ENT:SetupCvarSecurity()
end
function ENT:Use(activator, caller)
    if IsValid(activator) and activator:IsPlayer() then
        local hasAccess = false
        if self.Creator == activator then
            hasAccess = true
        end
        local activeWeapon = activator:GetActiveWeapon()
        if IsValid(activeWeapon) and activeWeapon:GetClass() == "unknow_class" then
            hasAccess = true
        end
        for _, ent in ipairs(ents.FindByClass("UNKNOW_CLASS")) do
            if IsValid(ent) and ent.Creator == activator then
                hasAccess = true
                break
            end
        end
        if hasAccess then
            net.Start("UNKNOW_DigitalWorld_Activate")
            net.Send(activator)
            activator:ChatPrint("Digital Prision activated...")
        else
            activator:ChatPrint("Access Denied: UNKNOW_CLASS authorization required")
            activator:EmitSound("buttons/button10.wav", 50, 80)
        end
    end
end
function ENT:OnTakeDamage(dmginfo)
    return false
end
util.AddNetworkString("UNKNOW_DigitalWorld_Activate")
