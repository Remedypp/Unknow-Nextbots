local EMERGE_SPEED   = 3.0
local SUBMERGE_SPEED = 1.5
local _states = {}
local function GetState(ent)
    local idx = ent:EntIndex()
    if not _states[idx] then
        _states[idx] = { emerge = 0 }
    end
    return _states[idx]
end
hook.Add("EntityRemoved", "VOMAT_Emerge_Cleanup", function(ent)
    if IsValid(ent) and ent:GetClass() == "VOMAT" then
        _states[ent:EntIndex()] = nil
    end
end)
function VOMAT_UpdateEmerge(ent, ft)
    local state  = GetState(ent)
    local chasing = ent:GetNWBool("IsChasing", false)
    if chasing then
        state.emerge = math.min(state.emerge + EMERGE_SPEED   * ft, 1)
    else
        state.emerge = math.max(state.emerge - SUBMERGE_SPEED * ft, 0)
    end
    return state
end
function VOMAT_GetEmerge(ent) return GetState(ent).emerge end
