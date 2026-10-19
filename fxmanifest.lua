fx_version 'cerulean'
game 'gta5'

name 'spz-bomb'
description 'SPiceZ Minigame — Bomb Tag. Pass the bomb by ramming another car; whoever holds it when the fuse runs out is out. Waves until one is left.'
version '1.0.0'
author 'SPiceZ-Core'
lua54 'yes'

shared_scripts {
  '@ox_lib/init.lua',
  'config.lua',
}

client_scripts {
  'client/base.lua',
  'client/game.lua',
}

server_scripts {
  '@oxmysql/lib/MySQL.lua',
  'server/base.lua',
  'server/game.lua',
}

dependencies {
  'ox_lib',
  'spz-minigames',   -- shared in-game HUD
  'oxmysql',
  'spz-core',
  'spz-identity',
  'iak_demolition',     -- the arena map
}
