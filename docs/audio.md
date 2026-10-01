# Áudio

Sons, música e ambiente de chuva via autoload `scripts/audio_manager.gd`, com
três players: **SFX**, **música** (loop, −12 dB) e **chuva** (loop, −8 dB).
Assets em `assets/audio/`.

## Sons

| Nome (`play_sfx`) | Arquivo | Onde toca |
|---|---|---|
| `hoe` | `hoe.wav` | enxada (arar e colher) |
| `axe` | `axe.wav` | machado em árvore/toco |
| `water` | `water.ogg` | regador |
| `fish` | `fish.wav` | peixe pego no minigame |
| `step` | `step.mp3` | passos (a cada ~0,34 s andando, −8 dB) |
| `slime` | `slime.ogg` | espada |

- A **música** (`music.mp3`) começa uma vez no `_ready` e toca em loop.
- A **chuva** (`rain.mp3`) inicia/para conforme `Weather.changed`
  ([`time-weather.md`](time-weather.md)).

## Como tocar um som novo

1. Coloque o arquivo em `assets/audio/`;
2. adicione à constante `SFX` de `audio_manager.gd`;
3. chame `AudioManager.play_sfx("nome", volume_db)`.

## Integrações

`world.gd:use_tool` (ferramentas), `player.gd:_footsteps` (passos),
`fishing.gd` (pegar/escapar), `weather.gd`→`AudioManager` (chuva).