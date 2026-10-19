-- config.lua — Bomb Tag
-- Same iak_demolition bowl, in cars. Each wave the bomb is handed to a random
-- player. Touch another car and it's theirs. When the fuse runs out, whoever is
-- holding it blows up and is out. New wave, new bomb, until one player is left.

Config = {}

Config.Key          = "spz-bomb"           -- event prefix / bucket name (don't change)
Config.Title        = "Bomb Tag"
Config.MenuTitle    = "💣 Bomb Tag"
Config.Blurb        = "Drive through a car to pass the bomb — don't hold it when it blows"
Config.Command      = "bombtag"            -- join / leave the lobby
Config.StartCommand = "btstart"            -- start the lobby now
Config.MenuCommand  = "bombtagmenu"        -- queue menu (radial → Minigames)
Config.PlatePrefix  = "BMB"

-- ── Lobby ───────────────────────────────────────────────────────────────────
Config.MinPlayers   = 2
Config.MaxPlayers   = 16
Config.LobbyWaitSec = 45
Config.MaxRooms     = 8      -- rooms that can exist (and play) at the same time

-- ── Rewards ─────────────────────────────────────────────────────────────────
Config.WinReward    = 1500     -- the last player standing
Config.WaveBonus    = 50       -- every survivor, every wave survived
Config.RoundWinBonus = 150     -- the last player in each round

-- One join = a MATCH of this many rounds. Each round runs waves until one car
-- is left; then everyone respawns. Most round wins takes the match (WinReward).
Config.Rounds       = 3

-- ── Arena (iak_demolition — same bowl as spz-demolition) ────────────────────
Config.Center      = vector3(2035.0, 2818.0, 49.0)
Config.SpawnRadius = 38.0
Config.ArenaRadius = 92.0
Config.OutGraceSec = 5
Config.FallDepth   = 15.0
Config.OutOfCarSec = 6
Config.SpectateDelaySec = 2.5

-- ── Bomb ────────────────────────────────────────────────────────────────────
Config.FuseSec        = 45.0   -- wave 1 fuse
Config.FuseStep       = 2.0    -- shaved off every wave
Config.FuseMin        = 25.0
Config.BreatherSec    = 5.0    -- between the blast and the next bomb
Config.PassDistance   = 2.0    -- backup sweep: car centres this close on the server = a tag
                               -- (cars ghost through each other, so only a real overlap counts)
Config.ReportDistance = 15.0   -- a client-reported bump is accepted within this (server lag)
Config.PassCooldownSec = 1.5   -- no instant tag-back: the new holder can't pass, and the
                               -- old one can't be tagged, for this long
-- More players, more bombs: one bomb per this many players alive (min 1, and
-- never so many that everyone holds one).
Config.PlayersPerBomb = 6
Config.HolderPower    = 1.25   -- the bomb carrier's car is a bit quicker (catch-up)

-- ── Cars ────────────────────────────────────────────────────────────────────
-- No damage here: only the bomb eliminates.
Config.VehicleDamage = false
Config.Cars = {
    "blista", "futo", "kuruma", "sultan", "issi2", "brioso",
    "rhapsody", "panto", "prairie", "dilettante",
}
