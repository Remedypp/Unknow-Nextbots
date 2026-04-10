if not CLIENT then return end
unknow = CreateClientConVar("unknow", "0", FCVAR_ARCHIVE)
local unknowAvatar  = Material("hide/ERROR/unknow_pic.png")
local entryAdded    = false
local entryPanel    = nil
local unknowExists  = false
local function CreateScoreboardEntry()
    if not IsValid(g_Scoreboard) or not IsValid(g_Scoreboard.Scores) or entryAdded then return end
    local panel = vgui.Create("DPanel")
    panel:SetSize(g_Scoreboard:GetWide() - 20, 38)
    panel:DockPadding(3, 3, 3, 3)
    panel:Dock(TOP)
    panel:DockMargin(2, 0, 2, 2)
    local avatar = vgui.Create("DImage", panel)
    avatar:Dock(LEFT)
    avatar:SetSize(32, 32)
    avatar:SetMaterial(unknowAvatar)
    local nameLabel = vgui.Create("DLabel", panel)
    nameLabel:Dock(FILL)
    nameLabel:SetText("UNKNOW")
    nameLabel:SetFont("TerrorFonts_Small")
    nameLabel:SetTextColor(Color(0, 0, 0))
    nameLabel:DockMargin(8, 0, 8, 0)
    local kills = vgui.Create("DLabel", panel)
    kills:Dock(RIGHT)
    kills:SetWidth(50)
    kills:SetFont("ScoreboardDefault")
    kills:SetTextColor(Color(93, 93, 93))
    kills:SetContentAlignment(5)
    local nextUpdate = 0
    kills.Think = function(self)
        if CurTime() > nextUpdate then
            local glitch = math.random(-5, 5)
            if math.random() < 0.2 then
                local chars = { "", "@", "#", "$", "%" }
                self:SetText(math.random(900, 999) .. chars[math.random(#chars)])
            else
                self:SetText(999 + glitch)
            end
            nextUpdate = CurTime() + math.Rand(0.1, 0.3)
        end
    end
    panel.Paint = function(self, w, h)
        draw.RoundedBox(4, 0, 0, w, h, Color(180, 180, 180, 255))
    end
    g_Scoreboard.Scores:AddItem(panel)
    panel:SetZPos(-1)
    entryAdded = true
    entryPanel = panel
end
local function RemoveScoreboardEntry()
    timer.Remove("REWORK_WaitForScoreboard")
    if IsValid(entryPanel) then
        entryPanel:Remove()
        entryPanel = nil
    end
    entryAdded = false
end
hook.Add("ScoreboardShow", "REWORK_UNKNOW_Scoreboard", function()
    if not unknowExists then
        for _, ent in ipairs(ents.FindByClass("UNKNOW")) do
            if IsValid(ent) then
                unknowExists = true
                break
            end
        end
    end
    if unknowExists then CreateScoreboardEntry() end
end)
hook.Add("ScoreboardHide", "REWORK_UNKNOW_Scoreboard", RemoveScoreboardEntry)
hook.Add("EntityRemoved", "REWORK_UNKNOW_EntityRemoved", function(ent)
    if ent:GetClass() == "UNKNOW" then
        unknowExists = false
        RemoveScoreboardEntry()
    end
end)
net.Receive("UNKNOW_EntityCreated", function()
    unknowExists = true
end)
net.Receive("UNKNOW_JoinMessage", function()
    chat.AddText(
        Color(255, 255, 255), "UNKNOW ",
        Color(200, 0, 0),     "has joined the game"
    )
end)
