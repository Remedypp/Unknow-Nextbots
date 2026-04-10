if not CLIENT then return end
function UNKNOW_RequestRandomTeleport()
    if not IsValid(LocalPlayer()) then return false end
    net.Start("UNKNOW_DigitalWorld_RequestTeleport")
    net.SendToServer()
    return true
end
net.Receive("UNKNOW_DigitalWorld_TeleportResult", function()
    local success      = net.ReadBool()
    local teleportType = net.ReadString()
    if success then
        local colors = {
            air       = Color(100, 255, 255),
            ground    = Color(100, 255, 100),
            emergency = Color(255, 255, 100),
        }
        chat.AddText(colors[teleportType] or Color(255,255,255), "[DIGITAL WORLD] ", Color(255,255,255), "Teleportation: " .. teleportType)
        local fx = EffectData()
        fx:SetOrigin(LocalPlayer():GetPos())
        util.Effect("TeslaHitBoxes", fx)
    else
        chat.AddText(Color(255, 100, 100), "[DIGITAL WORLD] ", Color(255,255,255), "Teleportation failed!")
    end
end)
