# spz-bomb

> Bomb Tag: pass the bomb before the fuse runs out.

![version](https://img.shields.io/badge/version-1.0.0-ff6200) ![SPiceZ-Core](https://img.shields.io/badge/SPiceZ--Core-beta-18181b)

## Overview

The bomb is handed to a random car each wave; drive through another car to pass it. Whoever holds it when the fuse runs out is out. Everyone gets one jump and one boost per wave.

## Features

- Waves with shrinking fuses
- One jump and one 2 s boost per wave
- Random car category per round

## Requirements

| Resource | Type |
|---|---|
| `ox_lib` | third-party |
| `spz-minigames` | SPiceZ module |
| `oxmysql` | third-party |
| `spz-core` | SPiceZ module |
| `spz-identity` | SPiceZ module |
| `iak_demolition` | third-party |

## Installation

Included in the [txAdmin recipe](https://github.com/SPiceZ21/spz-txrecipe). Manual install:

1. Download `spz-bomb` from GitHub (latest release, or the repository) into your `resources` folder.
2. Add to `server.cfg`, after its requirements:

```cfg
ensure spz-bomb
```

## Configuration

- `config.lua`

See the file for every option.

## Key binds

Rebindable in **Settings → Key Bindings → FiveM**.

| Action | Default |
|---|---|
| Bomb Tag: car jump (once per wave) | `E` |
| Bomb Tag: boost (once per wave) | `LSHIFT` |

## Notes

- Requires the `iak_demolition` arena map (third-party, not included).

---

Part of **SPiceZ-Core** — [documentation](https://github.com/SPiceZ21/Docs) · [all modules](https://github.com/SPiceZ21/Docs/blob/main/modules/README.md)
