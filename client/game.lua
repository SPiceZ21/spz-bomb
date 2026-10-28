-- client/game.lua — Bomb Tag visuals (see client/base.lua for the shared core)
-- The server decides every tag and every blast; this file only shows them.

local holders = {}      -- [serverId] = true
local iHold = false

local function carOf(serverId)
    local pl = GetPlayerFromServerId(serverId)
    if pl == -1 then return 0 end
    local ped = GetPlayerPed(pl)
    if ped == 0 then return 0 end
    local veh = GetVehiclePedIsIn(ped, false)
    return veh ~= 0 and veh or ped
end

local function setHolding(on)
    if on == iHold then return end
    iHold = on
    local v = Base.veh
    if v ~= 0 and DoesEntityExist(v) then
        SetVehicleCheatPowerIncrease(v, on and (Config.HolderPower or 1.0) or 1.0)
    end
    if on then
        PlaySoundFrontend(-1, "Bomb_Disarmed", "GTAO_Speed_Convoy_Soundset", true)
        lib.notify({ title = "YOU HAVE THE BOMB", description = "Drive through another car to pass it on!", type = "error", duration = 3000 })
    end
end

function Game.onStart() holders = {}; iHold = false end

-- Cars can't be wrecked here: only the bomb eliminates.
function Game.onCar(veh)
    SetEntityInvincible(veh, true)
    SetVehicleCanBeVisiblyDamaged(veh, false)
    SetVehicleTyresCanBurst(veh, false)
    SetVehicleWheelsCanBreak(veh, false)
end

function Game.onGo()
    lib.notify({ title = "BOMB TAG", description = "Don't be holding the bomb when the fuse runs out.", type = "inform", duration = 5000 })
end

function Game.onOver() holders = {}; setHolding(false) end

RegisterNetEvent(Base.E("bombs"), function(d)
    if not Base.active then return end
    holders = {}
    for _, s in ipairs(d.holders or {}) do holders[s] = true end
    setHolding(holders[GetPlayerServerId(PlayerId())] == true)

    if d.fresh then
        Base.flash(("Wave %d"):format(d.wave or 0), "warn", 1200)
    elseif d.toName and d.fromName then
        lib.notify({ description = ("💣 %s → %s"):format(d.fromName, d.toName), type = "warning", duration = 2000 })
    end
end)

RegisterNetEvent(Base.E("blast"), function(d)
    if not Base.active then return end
    -- Local, visual-only explosion (damage scale 0; cars here are invincible).
    AddExplosion(d.x, d.y, d.z + 0.5, 7, 0.0, true, false, 1.5)
    if d.src == GetPlayerServerId(PlayerId()) then
        local v = Base.veh
        if v ~= 0 and DoesEntityExist(v) then
            local vel = GetEntityVelocity(v)
            SetEntityVelocity(v, vel.x, vel.y, 12.0)          -- launched by the blast
            SetVehicleUndriveable(v, true)
        end
        ShakeGameplayCam("LARGE_EXPLOSION_SHAKE", 1.2)
    end
end)

-- Ghost cars: players drive through each other (no collision), every frame,
-- both ways, for the whole match. The bomb passes on overlap instead (below).
CreateThread(function()
    while true do
        if Base.active and Base.veh ~= 0 and DoesEntityExist(Base.veh) then
            local me = GetPlayerServerId(PlayerId())
            local mine = Base.veh
            for _, pl in ipairs(GetActivePlayers()) do
                local sid = GetPlayerServerId(pl)
                if sid ~= me then
                    local other = carOf(sid)
                    if other ~= 0 and DoesEntityExist(other) then
                        SetEntityNoCollisionEntity(mine, other, true)
                        SetEntityNoCollisionEntity(other, mine, true)
                    end
                end
            end
            Wait(0)
        else
            Wait(250)
        end
    end
end)

-- Half extents of an entity's model (x = width, y = length, z = height).
local halfCache = {}
local function halfSize(e)
    local m = GetEntityModel(e)
    local h = halfCache[m]
    if not h then
        local mn, mx = GetModelDimensions(m)
        h = vector3((mx.x - mn.x) / 2, (mx.y - mn.y) / 2, (mx.z - mn.z) / 2)
        halfCache[m] = h
    end
    return h
end

-- With collision off, IsEntityTouchingEntity never fires: two cars count as
-- touching only when they actually overlap - the other car's centre inside my
-- car's own box (plus a small margin), checked from both cars' point of view.
local MARGIN = 0.3
local function centreInside(a, b)
    local o = GetOffsetFromEntityGivenWorldCoords(a, GetEntityCoords(b))
    local h = halfSize(a)
    return math.abs(o.x) < h.x + MARGIN and math.abs(o.y) < h.y + MARGIN and math.abs(o.z) < h.z + 1.0
end
local function overlapping(mine, other)
    return centreInside(mine, other) or centreInside(other, mine)
end

-- Contact detection: the server can't see a bump (its positions lag the hit),
-- so each client watches its own car overlapping the others and reports it.
-- Only holder <-> non-holder contacts matter; the server checks the rest.
CreateThread(function()
    local sent = {}                 -- [serverId] = time last reported
    while true do
        local s = Base.state or {}
        local me = GetPlayerServerId(PlayerId())
        if Base.active and Base.alive and s.phase == "fuse" and next(holders) and Base.veh ~= 0 then
            local mine = Base.veh
            local now = GetGameTimer()
            for _, pl in ipairs(GetActivePlayers()) do
                local sid = GetPlayerServerId(pl)
                if sid ~= me and (holders[sid] or holders[me]) and not (holders[sid] and holders[me]) then
                    local other = carOf(sid)
                    if other ~= 0 and DoesEntityExist(other)
                        and #(GetEntityCoords(other) - GetEntityCoords(mine)) < 9.0
                        and overlapping(mine, other)
                        and now - (sent[sid] or 0) > 400 then
                        sent[sid] = now
                        TriggerServerEvent(Base.E("touch"), sid)
                    end
                end
            end
            Wait(0)
        else
            Wait(200)
        end
    end
end)

-- Markers over every bomb carrier + the fuse beep.
CreateThread(function()
    local nextBeep = 0
    while true do
        if Base.active and next(holders) then
            local now = GetGameTimer()
            local s = Base.state or {}
            local pulse = math.abs(math.sin(now / 160.0))
            for sid in pairs(holders) do
                local e = carOf(sid)
                if e ~= 0 and DoesEntityExist(e) then
                    local c = GetEntityCoords(e)
                    DrawMarker(2, c.x, c.y, c.z + 2.4, 0, 0, 0, 180.0, 0, 0, 1.0, 1.0, 1.0,
                        255, math.floor(60 + 120 * pulse), 40, 230, true, true, 2, false, nil, nil, false)
                    DrawLightWithRange(c.x, c.y, c.z + 1.5, 255, 40, 20, 6.0, 4.0 + 6.0 * pulse)
                end
            end
            -- Beep faster as the fuse burns down (holders only).
            if iHold and s.phase == "fuse" and s.remain and now >= nextBeep then
                PlaySoundFrontend(-1, "Beep_Red", "DLC_HEIST_HACKING_SNAKE_SOUNDS", true)
                nextBeep = now + math.floor(math.max(120, math.min(1000, s.remain * 70)))
            end
            Wait(0)
        else
            Wait(250)
        end
    end
end)

-- ── Per-wave jump + boost ───────────────────────────────────────────────────
-- One of each per wave, keyed "round:wave" so a wave-1 jump spent in round 1
-- doesn't read as used in round 2 wave 1 (same as Color Rush).
local jumpUsed, boostUsed = nil, nil
local boostUntil = 0

local function waveKey()
    local s = Base.state or {}
    return (s.round or 1) .. ":" .. (s.wave or 0)
end

local function canUse()
    local s = Base.state or {}
    local v = Base.veh
    return Base.active and Base.alive and (s.wave or 0) > 0 and s.phase == "fuse"
        and v ~= 0 and DoesEntityExist(v) and GetPedInVehicleSeat(v, -1) == PlayerPedId()
end

RegisterCommand("+bomb_jump", function()
    if not canUse() or jumpUsed == waveKey() then return end
    local v = Base.veh
    jumpUsed = waveKey()
    local vel, f = GetEntityVelocity(v), GetEntityForwardVector(v)
    local fwd = Config.JumpForward or 0.0
    SetEntityVelocity(v, vel.x + f.x * fwd, vel.y + f.y * fwd, vel.z + (Config.JumpVelocity or 9.0))
    PlaySoundFrontend(-1, "Jump", "DLC_Stunt_Race_Sounds", true)
end, false)
RegisterCommand("-bomb_jump", function() end, false)
RegisterKeyMapping("+bomb_jump", "Bomb Tag: car jump (once per wave)", "keyboard", Config.JumpKey or "E")
RegisterKeyMapping("+bomb_jump", "Bomb Tag: car jump (controller)", "PAD_DIGITALBUTTON", "RLEFT_INDEX")

RegisterCommand("+bomb_boost", function()
    if not canUse() or boostUsed == waveKey() then return end
    boostUsed = waveKey()
    boostUntil = GetGameTimer() + math.floor((Config.BoostSec or 2.0) * 1000)
    SetVehicleBoostActive(Base.veh, true)
    AnimpostfxPlay("RaceTurbo", 0, false)
end, false)
RegisterCommand("-bomb_boost", function() end, false)
RegisterKeyMapping("+bomb_boost", "Bomb Tag: boost (once per wave)", "keyboard", Config.BoostKey or "LSHIFT")
RegisterKeyMapping("+bomb_boost", "Bomb Tag: boost (controller)", "PAD_DIGITALBUTTON", "LUP_INDEX")

-- While boosting: push the car forward every frame, capped.
CreateThread(function()
    while true do
        if boostUntil > 0 then
            local v = Base.veh
            if GetGameTimer() >= boostUntil or not Base.active or v == 0 or not DoesEntityExist(v) then
                if v ~= 0 and DoesEntityExist(v) then SetVehicleBoostActive(v, false) end
                boostUntil = 0
            else
                local speed = GetEntitySpeed(v)
                if speed < (Config.BoostMaxMs or 55.0) then
                    SetVehicleForwardSpeed(v, speed + (Config.BoostAccel or 18.0) * GetFrameTime())
                end
            end
            Wait(0)
        else
            Wait(100)
        end
    end
end)

RegisterNetEvent(Base.E("roundOver"), function(d)
    if not Base.active then return end
    holders = {}; setHolding(false)
    local lines = {}
    for i, st in ipairs(d.standings or {}) do
        if i > 5 then break end
        lines[#lines + 1] = ("%d. %s — %d"):format(i, st.name, st.wins)
    end
    lib.notify({ title = ("ROUND %d / %d OVER"):format(d.round or 0, d.rounds or 0),
                 description = table.concat(lines, "\n"), type = "success", duration = 5000 })
end)

function Game.hud(s, hud)
    if Base.alive and (s.wave or 0) > 0 then
        local k = waveKey()
        local jr, br = jumpUsed ~= k, boostUsed ~= k
        hud.keys = hud.keys or {}
        hud.keys[#hud.keys + 1] = { cmd = "+bomb_jump", default = Config.JumpKey or "E", pad = "RLEFT_INDEX", label = "Jump", hot = jr, dim = not jr }
        hud.keys[#hud.keys + 1] = { cmd = "+bomb_boost", default = Config.BoostKey or "LSHIFT", pad = "LUP_INDEX", label = "Boost", hot = br, dim = not br }
    end
    if s.round then
        table.insert(hud.chips, 1, ("Round %d / %d"):format(s.round, s.rounds or 0))
        hud.chips[#hud.chips + 1] = { text = ("Your wins %d"):format(s.wins or 0), hot = (s.wins or 0) > 0 }
    end
    if s.phase == "fuse" and s.remain then
        local hot = s.remain < 5.0
        hud.status = { label = "Fuse", value = ("%.1f"):format(s.remain), color = hot and "bad" or "warn" }
        if s.holder then
            hud.alert = "You have the bomb — ram someone!"
        elseif Base.alive then
            local n = 0; for _ in pairs(holders) do n = n + 1 end
            hud.status.sub = ("Stay away from the %s"):format(n > 1 and ("%d bombs"):format(n) or "bomb")
        end
    elseif s.phase == "breather" and s.remain then
        hud.status = { label = "Next bomb in", value = tostring(math.ceil(s.remain)), color = "dim" }
    end
end
