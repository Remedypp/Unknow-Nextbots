ENT.Base            = "base_nextbot"
ENT.PrintName       = "CODE"
ENT.RealName        = "CODE"
ENT.NameColor       = Color(255, 0, 0)
ENT.Author          = "Remedy"
ENT.Class           = "UNKNOW_CLASS"
ENT.Category        = "Unknown Nextbot's"
ENT.Spawnable       = true
ENT.AdminSpawnable  = true
if CLIENT then
    function ENT:Initialize()
        if not self.SoundsLoaded then
            self.SoundsLoaded = true
            util.PrecacheSound("ambient/machines/machine1_hit1.wav")
            util.PrecacheSound("player/heartbeat1.wav")
            util.PrecacheSound("npc/scanner/scanner_pain2.wav")
            util.PrecacheSound("ambient/atmosphere/cave_hit1.wav")
            util.PrecacheSound("ambient/atmosphere/cave_hit2.wav")
        end
    end
end
if SERVER then
    util.AddNetworkString("UNKNOW_CodeMenu")
    util.AddNetworkString("UNKNOW_CodeResponse")
    util.AddNetworkString("UNKNOW_SubmitCode")
    util.AddNetworkString("UNKNOW_TeleportPlayer")
end
function ENT:SetupDataTables()
end
function ENT:Initialize()
    if SERVER then
        self:SetModel("models/props_c17/oildrum001.mdl")
        self:SetHullType(HULL_HUMAN)
        self:SetHullSizeNormal()
        self:SetNPCState(NPC_STATE_SCRIPT)
        self:SetSolid(SOLID_BBOX)
        self:CapabilitiesAdd(CAP_ANIMATEDFACE)
        self:CapabilitiesAdd(CAP_TURN_HEAD)
        self:SetUseType(SIMPLE_USE)
        self:DropToFloor()
        self.LastUse = 0
        self.UseDelay = 1
    end
    if CLIENT then
        if not self.SoundsLoaded then
            self.SoundsLoaded = true
            util.PrecacheSound("ambient/machines/machine1_hit1.wav")
            util.PrecacheSound("player/heartbeat1.wav")
            util.PrecacheSound("npc/scanner/scanner_pain2.wav")
            util.PrecacheSound("ambient/atmosphere/cave_hit1.wav")
            util.PrecacheSound("ambient/atmosphere/cave_hit2.wav")
        end
    end
end
function ENT:Use(activator, caller)
    if SERVER then
        if not IsValid(activator) or not activator:IsPlayer() then return end
        if CurTime() - self.LastUse < self.UseDelay then return end
        self.LastUse = CurTime()
        net.Start("UNKNOW_CodeMenu")
        net.Send(activator)
    end
end
function ENT:Think()
    if SERVER then
        self:NextThink(CurTime() + 0.1)
        return true
    end
end
function ENT:OnRemove()
    if SERVER then
    end
    if CLIENT then
    end
end
UNKNOW_MAX_ATTEMPTS = 3
UNKNOW_USE_DELAY = 1
