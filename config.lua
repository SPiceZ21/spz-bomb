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

-- ── Per-wave abilities ──────────────────────────────────────────────────────
-- Every player gets ONE jump and ONE boost per wave (keys rebindable in
-- Settings > Key Bindings > FiveM).
Config.JumpKey      = "E"
Config.JumpVelocity = 9.0      -- m/s straight up
Config.JumpForward  = 3.0      -- m/s extra along the car's nose
Config.BoostKey     = "LSHIFT"
Config.BoostSec     = 2.0      -- how long the boost pushes
Config.BoostAccel   = 18.0     -- m/s per second added while boosting
Config.BoostMaxMs   = 55.0     -- the boost stops adding speed past this (m/s)

-- ── Cars ────────────────────────────────────────────────────────────────────
-- No damage here: only the bomb eliminates.
Config.VehicleDamage = false
-- ── Cars ────────────────────────────────────────────────────────────────────
-- Each ROUND one category is drawn at random and every player gets a random
-- car from it, so the field is matched but different every round. Base-game
-- models only. Drop a category or a car to take it out of the draw.
Config.CarClasses = {
    { name = "Super", cars = {
        "adder", "zentorno", "t20", "osiris", "entityxf", "cheetah", "turismor", "reaper",
        "fmj", "pfister811", "tempesta", "italigtb", "nero", "vagner", "xa21", "tyrus",
        "sc1", "cyclone", "visione", "autarch", "krieger", "emerus", "thrax", "zorrusso", "furia" } },
    { name = "Sports", cars = {
        "comet2", "comet5", "comets2r", "carbonizzare", "elegy", "elegy2", "feltzer2",
        "furoregt", "jester", "jester3", "jugular", "kuruma", "massacro", "neon",
        "pariah", "penumbra2", "rapidgt", "schafter3", "schlagen", "schwarzer",
        "specter", "sultan2", "vstr", "banshee", "buffalo2", "italigto",
        "ninef", "omnis", "growler", "calico", "euros", "zr350", "remus" } },
    { name = "Muscle", cars = {
        "dominator", "dominator3", "gauntlet", "gauntlet4", "buccaneer2", "dukes", "sabregt2",
        "vigero", "phoenix", "blade", "ruiner", "stalion", "ellie", "impaler", "yosemite",
        "deviant", "vamos", "clique", "tulip", "hermes" } },
    { name = "Sports Classics", cars = {
        "ztype", "stinger", "monroe", "jb700", "cheetah2", "infernus2", "torero", "turismo2",
        "gt500", "savestra", "viseris", "z190", "michelli", "fagaloa", "cheburek", "rapidgt3",
        "retinue", "ardent", "mamba", "coquette2" } },
    { name = "Coupes", cars = {
        "cogcabrio", "exemplar", "f620", "felon", "jackal", "oracle2", "sentinel", "sentinel2",
        "windsor", "zion", "previon", "kanjosj" } },
    { name = "Sedans", cars = {
        "asea", "fugitive", "glendale", "ingot", "intruder", "premier", "primo", "schafter2",
        "stanier", "stratum", "sultan", "tailgater", "washington", "warrener", "cinquemila", "deity" } },
    { name = "Compacts", cars = {
        "blista", "brioso", "dilettante", "issi2", "panto", "prairie", "rhapsody", "asbo",
        "kanjo", "club", "weevil", "brioso2" } },
    { name = "SUVs", cars = {
        "baller2", "cavalcade2", "dubsta", "granger", "gresley", "huntley", "landstalker2",
        "mesa", "patriot", "rocoto", "seminole2", "toros", "xls", "rebla", "novak" } },
    { name = "Off-road", cars = {
        "sandking", "rebel2", "bifta", "brawler", "dubsta3", "kamacho", "mesa3", "riata",
        "trophytruck", "caracara2", "everon", "winky", "hellion" } },
}
