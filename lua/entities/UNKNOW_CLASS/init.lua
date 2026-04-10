AddCSLuaFile("cl_init.lua")
AddCSLuaFile("shared.lua")
include("shared.lua")
util.AddNetworkString("UNKNOW_CodeMenu")
util.AddNetworkString("UNKNOW_CodeResponse")
util.AddNetworkString("UNKNOW_SubmitCode")
util.AddNetworkString("UNKNOW_ComputerAction")
local VALID_PASSWORD = "[REDACTED_CODE]"
function ENT:PhysgunPickup(ply, ent)
    return false
end
function ENT:GravGunPickupAllowed(ply)
    return false
end
function ENT:Initialize()
    local existingEnts = ents.FindByClass("UNKNOW_CLASS")
    if #existingEnts > 1 then
        self:Remove()
        return
    end
    self:SetModel("models/Gibs/HGIBS.mdl")
    self:SetNoDraw(true)
    self:SetNotSolid(true)
    local creator = IsValid(self:GetCreator()) and self:GetCreator() or self:GetOwner()
    if not IsValid(creator) then
        for _, ply in ipairs(player.GetAll()) do
            if ply:IsAdmin() then
                creator = ply
                break
            end
        end
    end
    self.Creator = creator
    if IsValid(creator) then
        timer.Simple(0.5, function()
            if IsValid(self) and IsValid(creator) then
                net.Start("UNKNOW_CodeMenu")
                net.Send(creator)
            end
        end)
    end
end
function ENT:RunBehaviour()
    while true do
        coroutine.wait(1)
        coroutine.yield()
    end
end
net.Receive("UNKNOW_SubmitCode", function(len, ply)
    local password = net.ReadString()
    if password == VALID_PASSWORD then
        net.Start("UNKNOW_CodeResponse")
        net.WriteBool(true)
        net.WriteString("ACCESS_GRANTED")
        net.Send(ply)
    else
        net.Start("UNKNOW_CodeResponse")
        net.WriteBool(false)
        net.WriteString("INVALID_PASSWORD")
        net.Send(ply)
    end
end)
net.Receive("UNKNOW_ComputerAction", function(len, ply)
    local action = net.ReadString()
    local data = net.ReadString()
    if action == "SPAWN_UNKNOW" then
        for _, ent in ipairs(ents.FindByClass("UNKNOW")) do
            if IsValid(ent) then
                ply:ChatPrint("[PETROV-OS] ERROR: Entity already exists")
                return
            end
        end
        local spawns = ents.FindByClass("info_player_start")
        if #spawns > 0 then
            local spawn = spawns[math.random(1, #spawns)]
            local unknowEnt = ents.Create("UNKNOW")
            if IsValid(unknowEnt) then
                unknowEnt:SetSpawnedByUnknowClass(true)
                unknowEnt:SetPos(spawn:GetPos() + Vector(0, 0, 5))
                unknowEnt:Spawn()
                ply:ChatPrint("[PETROV-OS] WARNING: CONTAINMENT BREACH DETECTED.")
                for _, p in ipairs(player.GetAll()) do
                    if IsValid(p) then
                        p:SendLua('surface.PlaySound("Unknow_Computer/Alert.wav")')
                    end
                end
            end
        end
        for _, ent in ipairs(ents.FindByClass("UNKNOW_CLASS")) do
            if ent.Creator == ply then
                timer.Simple(1, function()
                    if IsValid(ent) then ent:Remove() end
                end)
            end
        end
    elseif action == "CLOSE" then
        for _, ent in ipairs(ents.FindByClass("UNKNOW_CLASS")) do
            if ent.Creator == ply then
                ent:Remove()
            end
        end
    end
end)
