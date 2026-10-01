# Simulator Game

Jogo 2D top-down de fazenda (Stardew Valley) em Godot 4.6.3: terreno em dual
grid, personagem em 8 direções (andar/correr) e sistemas de ferramentas,
plantações, máquinas, casa, inventário/hotbar, loja, dia/noite, chuva e
save/load.

## Controles

| Ação | Tecla / Gamepad |
|---|---|
| Mover | `WASD` / setas / d-pad / analógico |
| Correr / andar | `Shift` / botão B |
| Usar ferramenta (ação) | `Espaço` / botão A |
| Selecionar hotbar | `1`..`9` / roda do mouse |
| Ferramenta anterior/próxima | `Q`/`E` / L1/R1 |
| Trocar semente | `C` / botão X |
| Modo decoração | `B` |
| Pausar | `Esc` / Start |

**Hotbar** (9 slots): 1 Enxada · 2 Regador · 3 Machado · 4 Espada · 5 Vara ·
6 Semente · 7 Aspersor · 8 Espantalho · 9 Pescador — detalhes nas docs abaixo.

## Sistemas

- **Mundo** ([`docs/world.md`](docs/world.md)) — terreno, dual grid, `walkable`/`tillable`, aração.
- **Player** ([`docs/player.md`](docs/player.md)) — movimento, colisão de pés e skins.
- **Fazenda** ([`docs/farming.md`](docs/farming.md)) — plantio, crescimento, colheita e árvores.
- **Máquinas** ([`docs/machines.md`](docs/machines.md)) — aspersor, espantalho e pescador.
- **Pesca** ([`docs/fishing.md`](docs/fishing.md)) — minigame da vara e peixes.
- **Inventário / HUD / Loja** ([`docs/inventory-shop.md`](docs/inventory-shop.md)).
- **Tempo e clima** ([`docs/time-weather.md`](docs/time-weather.md)) — relógio, dia/noite, chuva.
- **Save / Load** ([`docs/save-load.md`](docs/save-load.md)).
- **Áudio** ([`docs/audio.md`](docs/audio.md)).
- **NPCs** ([`docs/npcs.md`](docs/npcs.md)) — criaturas ambientais.
- **Decoração e casa** ([`docs/decor.md`](docs/decor.md)) — modo `B`, móveis e construções.

## Estrutura (mapa de scripts)

```
scenes/ · scripts/    game.tscn · player.gd, world.gd, dual_grid.gd,
                      terrain_layer.gd, crop.gd, prop.gd, machine.gd,
                      house_builder.gd, fishing.gd, decor.gd, critter.gd,
                      inventory.gd, hud.gd, shop.gd, pause_menu.gd,
                      settings.gd, time_manager.gd, weather.gd, rain.gd,
                      day_night.gd, audio_manager.gd, save_game.gd
scripts/data/         enums.gd, game_data.gd (dados e preços)
assets/               graphics/, audio/, tiles/, sprites/
tools/                gen_player_frames.py, smoke_test.gd, wiki_sync.py
docs/ · plans/        documentação por sistema (docs/README.md) · roadmap (plans/)
```

## Personagem (skins)

6 skins geradas por `tools/gen_player_frames.py`; troque em
**Esc > Opções > Aparência** (`user://settings.cfg`) — [`docs/player.md`](docs/player.md).

## Gestão do projeto

Board, labels e fluxos no [GitHub Projects](https://github.com/users/guiguetz/projects/1);
bugs → issue 🐛, features → plano em [`plans/`](plans/README.md) + issue 🗺️ —
regras em [`docs/github-projects.md`](docs/github-projects.md) e [`AGENTS.md`](AGENTS.md).
**CI** ([`ci.yml`](.github/workflows/ci.yml)) roda smoke test + gdUnit4;
**Checkup** ([`checkup.yml`](.github/workflows/checkup.yml)) valida planos,
issues, board, labels e docs — [`docs/checkup.md`](docs/checkup.md).

## Rodar / testar

```bash
/home/guilherme/godot/Godot_v4.6.3-stable_linux.x86_64 --path .   # jogo
bash tools/setup_hooks.sh                                          # hooks de git
python3 tools/gen_player_frames.py                                 # skins
godot --headless --path . --script tools/smoke_test.gd             # smoke test
```

## Configuração

Resolução interna 640x360 (janela 1280x720), filtro *nearest*; fonte
`PixeloidSans`; ações no Project Settings > Input Map.