local PUZZLE = {}
function PUZZLE.Decode(str)
    local b = 'ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/'
    str = string.gsub(str, '[^'..b..'=]', '')
    return (str:gsub('.', function(x)
        if (x == '=') then return '' end
        local r, f = '', (b:find(x) - 1)
        for i = 6, 1, -1 do r = r .. (f % 2 ^ i - f % 2 ^ (i - 1) > 0 and '1' or '0') end
        return r;
    end):gsub('%d%d%d?%d?%d?%d?%d?%d?', function(x)
        if (#x ~= 8) then return '' end
        local c = 0
        for i = 1, 8 do c = c + (x:sub(i, i) == '1' and 2 ^ (8 - i) or 0) end
        return string.char(c)
    end))
end
local Q1 = "Vk9JRFRFUk0gT1MgdjIuMCB8IFBFVFJPViBSRVNFQVJDSCBTWVNURU1TLiBFTlRFUiBGT1VOREFUSU9OIFlFQVI6"
local A1 = "MTk0OA=="
local Q2 = "QVVUSE9SSVpBVElPTiBMRVZFTCAxIEFDQ0VQVEVELiBXSE9TRSBESVZJTkUgQkxPT0QgV0FTIE1PRElGSUVEIElOIDE2NjU/"
local A2 = "Y3Jvbm9z"
local Q3 = "R0VORVRJQyBQUk9UT0NPTCBSRUNPR05JWkVELiBXSEFUIFdBUyBUSEUgT1JJR0lOQUwgTkFNRSBPRiBTVUJKRUNUICdTTUVSVCc/"
local A3 = "a2F6aW1pcg=="
local Q4 = "REFUQSBNQVRDSC4gT05MWSBPTkUgU1VSVklWRUQgVEhFIE9SSUdJTkFMIE1BU1NBQ1JFIEFTIEEgR0hPU1QuIFdIQVQgSVMgSElTIE5BTUU/"
local A4 = "aGlubg=="
local Q5 = "Ly9DUklUSUNBTCBFUlJPUl8gTUVNT1JZIENPUlJVUFRJT04uLi4gVyBIIE8gICBEIE8gICBXIEUgICBQUiBPIFQgRSBDIFQgPw=="
local A5 = "YW5hc3Rhc2lh"
local FINAL = "Code :)"
local STAGES = {
    [1] = { q = Q1, a = A1 },
    [2] = { q = Q2, a = A2 },
    [3] = { q = Q3, a = A3 },
    [4] = { q = Q4, a = A4 },
    [5] = { q = Q5, a = A5 }
}
local function ClientPrint(ply, msg)
    if IsValid(ply) then
        ply:SendLua('MsgC(Color(0, 255, 0), "[ARES TERMINAL] ", Color(255, 255, 255), "' .. msg .. '\\n")')
    end
end
concommand.Add("unknow_get_code", function(ply, cmd, args)
    if not IsValid(ply) then return end
    ply.unknowPuzzleStage = ply.unknowPuzzleStage or 1
    local currentStage = ply.unknowPuzzleStage
    if currentStage > #STAGES then
        ClientPrint(ply, "SYSTEM ALREADY UNLOCKED.")
        ClientPrint(ply, PUZZLE.Decode(FINAL))
        return
    end
    local stageData = STAGES[currentStage]
    local expectedAnswer = PUZZLE.Decode(stageData.a):lower()
    if not ply.unknowPuzzleStarted or #args == 0 then
        ply.unknowPuzzleStarted = true
        ClientPrint(ply, "=================================")
        ClientPrint(ply, "CONNECTION ESTABLISHED...")
        ClientPrint(ply, "INSTRUCTION: TYPE 'unknow_get_code [answer]' TO REPLY.")
        ClientPrint(ply, "=================================")
        ClientPrint(ply, PUZZLE.Decode(STAGES[1].q))
        ply.unknowPuzzleStage = 1
        return
    end
    local userAnswer = string.lower(args[1] or "")
    if userAnswer == expectedAnswer then
        ClientPrint(ply, "ACCEPTED.")
        ply.unknowPuzzleStage = currentStage + 1
        if ply.unknowPuzzleStage > #STAGES then
            ClientPrint(ply, "=================================")
            ClientPrint(ply, "SYSTEM OVERRIDE COMPLETE")
            ClientPrint(ply, PUZZLE.Decode(FINAL))
            ClientPrint(ply, "=================================")
            ply:SendLua('surface.PlaySound("buttons/blip1.wav")')
        else
            local nextStage = STAGES[ply.unknowPuzzleStage]
            ClientPrint(ply, "=================================")
            ClientPrint(ply, "PROCESSING...")
            ClientPrint(ply, PUZZLE.Decode(nextStage.q))
        end
    else
        ClientPrint(ply, "ERR: INCORRECT INPUT. ACCESS DENIED.")
        ClientPrint(ply, "SYSTEM REBOOTING...")
        ClientPrint(ply, "=================================")
        ClientPrint(ply, PUZZLE.Decode(STAGES[1].q))
        ply:SendLua('surface.PlaySound("buttons/button10.wav")')
        ply.unknowPuzzleStage = 1
    end
end)
