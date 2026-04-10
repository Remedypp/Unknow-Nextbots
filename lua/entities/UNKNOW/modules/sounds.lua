local ENT = ENT
local SOUNDS = {
    HORROR = {
        "ambient/atmosphere/cave_hit1.wav",
        "ambient/atmosphere/cave_hit2.wav",
        "ambient/atmosphere/cave_hit3.wav",
        "ambient/atmosphere/cave_hit4.wav",
        "ambient/atmosphere/hole_hit1.wav",
        "ambient/atmosphere/hole_hit2.wav",
        "ambient/atmosphere/hole_hit3.wav",
        "ambient/atmosphere/hole_hit4.wav",
        "ambient/atmosphere/hole_hit5.wav",
        "ambient/creatures/flies1.wav",
        "ambient/creatures/flies2.wav",
        "ambient/creatures/flies3.wav",
        "ambient/creatures/flies4.wav",
        "ambient/creatures/rats2.wav",
        "ambient/creatures/rats3.wav",
        "ambient/energy/weld1.wav",
        "ambient/materials/metal_stress1.wav",
        "ambient/materials/metal_stress2.wav",
        "ambient/materials/metal_stress3.wav",
        "ambient/materials/metal_stress4.wav",
        "ambient/materials/metal_stress5.wav",
        "ambient/voices/playground_memory.wav",
        "npc/fast_zombie/idle1.wav",
        "npc/fast_zombie/idle2.wav",
        "npc/fast_zombie/idle3.wav",
        "npc/zombie_poison/pz_call1.wav"
    },
    STALKER = {
        "npc/stalker/breathing3.wav",
        "npc/stalker/go_alert2.wav"
    },
    STALK = {
        "ambient/levels/citadel/strange_talk1.wav",
        "ambient/levels/citadel/strange_talk2.wav",
        "ambient/levels/citadel/strange_talk3.wav",
        "ambient/levels/citadel/strange_talk4.wav",
        "ambient/levels/citadel/strange_talk5.wav"
    },
    STALK_CLOSE = {
        "ambient/levels/citadel/strange_talk6.wav",
        "ambient/levels/citadel/strange_talk7.wav",
        "ambient/levels/citadel/strange_talk8.wav",
        "ambient/levels/citadel/strange_talk9.wav",
        "ambient/levels/citadel/strange_talk10.wav"
    },
    AMBIENT = {
        "ambient/atmosphere/ambience_base.wav",
        "ambient/atmosphere/hole_hit1.wav",
        "ambient/atmosphere/hole_hit2.wav"
    },
    WATCH = {
        BREATHING = "npc/stalker/breathing3.wav",
        ALERT = "npc/stalker/go_alert2.wav"
    },
    GRAB = {
        GRAB = "npc/barnacle/barnacle_gulp1.wav",
        PAIN = "vo/npc/male01/pain07.wav"
    },
    BONE = {
        CRYING = "ambient/voices/crying_loop1.wav",
        STOP = "ambient/machines/machine1_stop1.wav",
        BREAK = {
            "physics/body/body_medium_break2.wav",
            "physics/body/body_medium_break3.wav",
            "physics/body/body_medium_break4.wav"
        }
    }
}
local function PlaySoundFromEntity(entity, soundPath, volume, pitch, soundLevel)
    if not IsValid(entity) then return end
    if not SERVER then return end
    volume = volume or 1.0
    pitch = pitch or 100
    soundLevel = soundLevel or 75
    if GSoundSystem and GSoundSystem.playsound2 then
        GSoundSystem.playsound2(entity, soundPath, volume, pitch, soundLevel)
    else
        entity:EmitSound(soundPath, soundLevel, pitch, volume)
    end
end
local function PlayRandomSound(entity, category, volume, pitch, soundLevel)
    if not IsValid(entity) then return nil end
    if not category or #category == 0 then return nil end
    local snd = category[math.random(#category)]
    PlaySoundFromEntity(entity, snd, volume, pitch, soundLevel)
    return snd
end
function ENT:InitializeSoundSystem()
    self.soundData = {
        horrorSoundCooldown = 60,
        stalkerSoundCooldown = 30,
        stalkSoundCooldown = 20,
        stalkCloseSoundCooldown = 15,
        ambientSoundCooldown = 45,
        lastHorrorSound = 0,
        lastStalkerSound = 0,
        lastStalkSound = 0,
        lastStalkCloseSound = 0,
        lastAmbientSound = 0,
        closeDistance = 400,
        mediumDistance = 800
    }
end
function ENT:UpdateSounds()
    if not self.soundData then
        self:InitializeSoundSystem()
    end
    local ct = CurTime()
    local enemy = self:GetEnemy()
    local dist = 9999
    if IsValid(enemy) then
        dist = self:GetPos():Distance(enemy:GetPos())
    end
    if IsValid(enemy) then
        if dist < self.soundData.closeDistance then
            if ct - self.soundData.lastStalkCloseSound > self.soundData.stalkCloseSoundCooldown then
                if math.random(1, 100) <= 30 then
                    self:PlayStalkCloseSound()
                    self.soundData.lastStalkCloseSound = ct
                end
            end
        elseif dist < self.soundData.mediumDistance then
            if ct - self.soundData.lastStalkSound > self.soundData.stalkSoundCooldown then
                if math.random(1, 100) <= 25 then
                    self:PlayStalkSound()
                    self.soundData.lastStalkSound = ct
                end
            end
        end
    end
    if ct - self.soundData.lastAmbientSound > self.soundData.ambientSoundCooldown then
        if math.random(1, 100) <= 8 then
            self:PlayAmbientSound()
            self.soundData.lastAmbientSound = ct
        end
    end
end
function ENT:PlayHorrorSound()
    return PlayRandomSound(self, SOUNDS.HORROR, 0.6, math.random(80, 120), 80)
end
function ENT:PlayStalkerSound()
    return PlayRandomSound(self, SOUNDS.STALKER, 0.75, math.random(80, 100), 75)
end
function ENT:PlayStalkSound()
    return PlayRandomSound(self, SOUNDS.STALK, 0.7, math.random(80, 100), 85)
end
function ENT:PlayStalkCloseSound()
    return PlayRandomSound(self, SOUNDS.STALK_CLOSE, 0.9, math.random(70, 90), 90)
end
function ENT:PlayAmbientSound()
    return PlayRandomSound(self, SOUNDS.AMBIENT, 0.5, math.random(80, 120), 70)
end
function ENT:PlayBreathingSound()
    PlaySoundFromEntity(self, SOUNDS.WATCH.BREATHING, 0.75, math.random(80, 100), 75)
end
function ENT:PlayAlertSound(highPitch)
    local pitch = highPitch and math.random(120, 150) or math.random(70, 90)
    PlaySoundFromEntity(self, SOUNDS.WATCH.ALERT, 0.75, pitch, 75)
end
function ENT:PlayGrabSound()
    PlaySoundFromEntity(self, SOUNDS.GRAB.GRAB, 0.8, 90, 80)
end
function ENT:PlayPainSound(player)
    if not IsValid(player) then return end
    if GSoundSystem and GSoundSystem.playsound2 then
        GSoundSystem.playsound2(player, SOUNDS.GRAB.PAIN, 0.7, 100, 70)
    else
        player:EmitSound(SOUNDS.GRAB.PAIN, 70, 100, 0.7)
    end
end
function ENT:PlayBoneCryingSound(player)
    if not IsValid(player) then return end
    if GSoundSystem and GSoundSystem.playsound2 then
        GSoundSystem.playsound2(player, SOUNDS.BONE.CRYING, 0.75, math.random(80, 100), 75)
    else
        player:EmitSound(SOUNDS.BONE.CRYING, 75, math.random(80, 100), 0.75)
    end
end
function ENT:StopBoneCryingSound(player)
    if not IsValid(player) then return end
    if GSoundSystem and GSoundSystem.stopsound then
        GSoundSystem.stopsound(player, SOUNDS.BONE.CRYING)
    end
    player:StopSound(SOUNDS.BONE.CRYING)
end
function ENT:PlayBoneStopSound(player)
    if not IsValid(player) then return end
    if GSoundSystem and GSoundSystem.playsound2 then
        GSoundSystem.playsound2(player, SOUNDS.BONE.STOP, 0.75, math.random(80, 100), 75)
    else
        player:EmitSound(SOUNDS.BONE.STOP, 75, math.random(80, 100), 0.75)
    end
end
function ENT:StopAllSounds()
    if not SERVER then return end
    if not IsValid(self) then return end
    for _, sounds in pairs(SOUNDS) do
        if type(sounds) == "table" then
            for key, snd in pairs(sounds) do
                if type(snd) == "string" then
                    if GSoundSystem and GSoundSystem.stopsound then
                        GSoundSystem.stopsound(self, snd)
                    end
                    self:StopSound(snd)
                end
            end
        end
    end
end
if CLIENT then
    UNKNOW_BoneSounds = {
        CRYING = SOUNDS.BONE.CRYING,
        STOP = SOUNDS.BONE.STOP,
        BREAK = SOUNDS.BONE.BREAK
    }
    function UNKNOW_PlayCryingSound()
        local ply = LocalPlayer()
        if not IsValid(ply) then return nil end
        if GSoundSystem and GSoundSystem.playsound then
            GSoundSystem.playsound(ply, SOUNDS.BONE.CRYING, 0.8, 100, 75)
            return { gsound = true, path = SOUNDS.BONE.CRYING }
        else
            local sound = CreateSound(ply, SOUNDS.BONE.CRYING)
            sound:Play()
            sound:ChangeVolume(0.8, 0)
            return sound
        end
    end
    function UNKNOW_StopCryingSound()
        local ply = LocalPlayer()
        if not IsValid(ply) then return end
        if GSoundSystem and GSoundSystem.stopsound then
            GSoundSystem.stopsound(ply, SOUNDS.BONE.CRYING)
        end
        ply:StopSound(SOUNDS.BONE.CRYING)
    end
    function UNKNOW_PlayBoneBreakSound()
        local ply = LocalPlayer()
        if not IsValid(ply) then return end
        local breakSound = SOUNDS.BONE.BREAK[math.random(1, #SOUNDS.BONE.BREAK)]
        if GSoundSystem and GSoundSystem.playsound then
            GSoundSystem.playsound(ply, breakSound, 0.75, math.random(90, 110), 70)
        else
            ply:EmitSound(breakSound, 70, math.random(90, 110), 0.75)
        end
    end
end
