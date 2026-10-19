-- server/game.lua — Bomb Tag rules (see server/base.lua for the shared core)
-- Tags are decided here from real car positions; the client only draws.

local function holderList(r)
    local out = {}
    for src in pairs(r.holders or {}) do out[#out + 1] = src end
    return out
end

local function broadcastHolders(r, extra)
    local payload = extra or {}
    payload.holders = holderList(r)
    Base.toAll(r, "bombs", payload)
end

local function nearestNonHolder(r, from)
    local fc = GetEntityCoords(Base.entityOf(from))
    local best, bestD
    for _, src in ipairs(Base.aliveList(r)) do
        if src ~= from and not r.holders[src] then
            local d = #(GetEntityCoords(Base.entityOf(src)) - fc)
            if not bestD or d < bestD then best, bestD = src, d end
        end
    end
    return best
end

local function give(r, src, now)
    r.holders[src] = true
    r.players[src].canPassAt = now + Config.PassCooldownSec * 1000
end

-- One tag, holder h -> o. Every rule in one place; returns true if it happened.
-- `maxDist` is generous for client-reported hits (positions on the server lag
-- the real contact by a few hundred ms, cars bounce apart in less).
local function tryPass(r, h, o, now, maxDist)
    if r.phase ~= "fuse" or h == o then return false end
    local hp, op = r.players[h], r.players[o]
    if not (hp and op and hp.alive and op.alive) then return false end
    if not r.holders[h] or r.holders[o] then return false end
    if now < (hp.canPassAt or 0) or now < (op.immuneUntil or 0) then return false end
    if #(GetEntityCoords(Base.entityOf(o)) - GetEntityCoords(Base.entityOf(h))) > maxDist then return false end
    r.holders[h] = nil
    hp.immuneUntil = now + Config.PassCooldownSec * 1000
    give(r, o, now)
    broadcastHolders(r, { from = h, to = o, fromName = hp.name, toName = op.name })
    return true
end

-- A client saw its car touch another one (IsEntityTouchingEntity, every frame).
-- Either side may report; the server applies the same rules either way.
RegisterNetEvent(Base.E("touch"), function(other)
    local src = source
    local r = Base.roundOf(src)
    other = tonumber(other)
    if not (r and r.live and other and r.players[src] and r.players[other]) then return end
    local now = GetGameTimer()
    if r.holders[src] then tryPass(r, src, other, now, Config.ReportDistance or 15.0)
    elseif r.holders[other] then tryPass(r, other, src, now, Config.ReportDistance or 15.0) end
end)

local function runWave(r)
    r.wave = (r.wave or 0) + 1
    local alive = Base.aliveList(r)
    local bombs = math.max(1, math.min(#alive - 1, math.floor(#alive / (Config.PlayersPerBomb or 6))))
    local now = GetGameTimer()

    r.holders = {}
    Base.shuffle(alive)
    for i = 1, bombs do give(r, alive[i], now) end

    local fuse = math.max(Config.FuseMin, Config.FuseSec - (r.wave - 1) * Config.FuseStep)
    r.phase = "fuse"
    r.endsAt = now + math.floor(fuse * 1000)
    broadcastHolders(r, { wave = r.wave, fuse = fuse, fresh = true })
    Base.log(("wave %d: %d bomb(s), %.1fs fuse, %d alive"):format(r.wave, bombs, fuse, #alive))

    -- Tagging: clients report real contact (the "touch" event above). This
    -- proximity sweep is the backup for a touch the clients missed.
    while r.active and GetGameTimer() < r.endsAt do
        Wait(100)
        now = GetGameTimer()
        local hs = holderList(r)            -- snapshot: tryPass edits r.holders
        for _, h in ipairs(hs) do
            for _, o in ipairs(Base.aliveList(r)) do
                if tryPass(r, h, o, now, Config.PassDistance) then break end
            end
        end
        if #Base.aliveList(r) <= 1 then return end
    end
    if not r.active then return end

    -- Boom.
    r.phase = "blast"
    for h in pairs(r.holders) do
        local p = r.players[h]
        if p and p.alive then
            local c = GetEntityCoords(Base.entityOf(h))
            Base.toAll(r, "blast", { src = h, x = c.x, y = c.y, z = c.z })
            Base.eliminate(h, "the bomb went off")
        end
    end
    r.holders = {}
    broadcastHolders(r, {})

    for _, src in ipairs(Base.aliveList(r)) do
        local p = r.players[src]
        p.bonus = (p.bonus or 0) + (Config.WaveBonus or 0)
    end

    r.phase = "breather"
    r.endsAt = GetGameTimer() + math.floor(Config.BreatherSec * 1000)
    while r.active and GetGameTimer() < r.endsAt do Wait(100) end
end

-- A match of Config.Rounds rounds. Each round: waves until one car is left,
-- who takes the round. Most round wins takes the match.
function Game.run(r)
    local rounds = Config.Rounds or 1
    for n = 1, rounds do
        r.roundNo, r.wave = n, 0
        r.holders = {}
        while r.active and #Base.aliveList(r) > 1 do
            runWave(r)
        end
        if not r.active then return end

        for _, src in ipairs(Base.aliveList(r)) do
            local p = r.players[src]
            p.roundWins = (p.roundWins or 0) + 1
            p.bonus = (p.bonus or 0) + (Config.RoundWinBonus or 0)
        end

        local standings = {}
        for _, p in pairs(r.players) do standings[#standings + 1] = { name = p.name, wins = p.roundWins or 0 } end
        table.sort(standings, function(a, b) return a.wins > b.wins end)
        Base.toAll(r, "roundOver", { round = n, rounds = rounds, standings = standings })

        if n < rounds then
            r.phase = "intermission"
            r.endsAt = nil
            Wait(5000)
            if not r.active then return end
            Base.respawnAll(r)
        end
    end

    -- The match winners are "alive" for the shared payout in Base.endRound.
    local best = 0
    for _, p in pairs(r.players) do best = math.max(best, p.roundWins or 0) end
    for _, p in pairs(r.players) do p.alive = best > 0 and (p.roundWins or 0) == best end
end

-- A holder knocked out some other way (left the arena, quit): the bomb jumps
-- to the nearest player so the wave still has one.
local function rehome(r, src)
    if not (r.holders and r.holders[src]) or r.phase ~= "fuse" then return end
    r.holders[src] = nil
    local to = nearestNonHolder(r, src)
    if to then give(r, to, GetGameTimer()) end
    broadcastHolders(r, { to = to, toName = to and r.players[to].name or nil, rehome = true })
end

function Game.onEliminated(r, src) rehome(r, src) end
function Game.onLeave(r, src) rehome(r, src) end

Game.boardTitle = "Standings"

function Game.boardRow(r, src, p, row)
    local wins = p.roundWins or 0
    row.value, row.valueColor = ("%d W"):format(wins), wins > 0 and "ok" or "dim"
    row.score = wins
    if r.holders and r.holders[src] then row.icon, row.color, row.sub = "bomb", "bad", "has the bomb" end
end

function Game.hud(r, src, p)
    return { holder = (r.holders and r.holders[src]) and true or false,
             round = r.roundNo, rounds = Config.Rounds, wins = p.roundWins or 0 }
end
