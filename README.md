# Simulator Game

Jogo 2D top-down de fazenda no estilo Stardew Valley (Godot 4.6.3). O terreno
usa **dual grid** (folha 4x4 = 16 tiles) e o personagem anda em 8 direções com
modo andar/correr. Inclui **ferramentas, plantações, máquinas, casa,
inventário/hotbar, loja, ciclo dia/noite, chuva e save/load**.

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

### Ferramentas (hotbar)

1. **Enxada** — cava grama/terra em canteiro (solo) e **colhe** cultura pronta.
2. **Regador** — molha o canteiro (necessário para a planta crescer).
3. **Machado** — derruba árvore (madeira); 2º golpe remove o toco.
4. **Espada** — golpe (efeito sonoro).
5. **Vara** — abre um **minigame de pesca** de frente para a água (peixes
   dourado, cinza e prateado).
6. **Semente** — planta a semente selecionada num canteiro vazio.
7. **Aspersor** — rega as plantações ao redor a cada novo dia (custa madeira).
8. **Espantalho** — decorativo.
9. **Pescador** — pesca sozinho se estiver perto da água (custa madeira).

### Menu de pausa (`Esc`)

**Loja** (compra sementes com moedas e vende itens), **Salvar**, **Carregar**,
**Opções > Jogabilidade** (modo padrão andar/correr) e **Opções > Aparência**
(escolhe a skin do personagem). Salvo em `user://settings.cfg`. O save do mundo
fica em `user://savegame.json`.

## Sistemas

- **Mundo dual grid** (`scripts/dual_grid.gd`, `scripts/world.gd`): água,
  trilha e canteiro pintados numa camada lógica; o dual grid e a andabilidade
  são reconstruídos ao vivo (também no editor, via `@tool`).
  Andabilidade e aração (`walkable`/`tillable`) vêm de custom data do TileSet —
  detalhes em [`docs/world.md`](docs/world.md).
- **Colisão do player** (`scripts/player.gd`): caixa de pés com
  `collision_padding` (padrão 2.0), limitada a meio tile para não travar em
  quinas — detalhes em [`docs/player.md`](docs/player.md).
- **Entidades** (`scripts/prop.gd`, `scripts/crop.gd`, `scripts/machine.gd`)
  com **Y-sorting** (`Game/Entities`), plantas em 4 estágios, máquinas animadas.
- **Casa com colisão** (`scripts/house_builder.gd`): bloco 3x3 de paredes +
  telhado, com polígono de física por tile.
- **Ferramentas** (`scripts/player.gd` + `world.gd:use_tool`).
- **Pesca** (`scripts/fishing.gd`): minigame de barra (segurar `Espaço` para
  subir, gastar resistência e manter o peixe na zona) que concede um peixe.
- **Decoração** (`scripts/decor.gd`): modo `B` com paleta de móveis; clique
  esquerdo coloca, direito remove; persiste no save.
- **Criaturas/NPCs** (`scripts/critter.gd`): gato (segue o player), rato
  (foge), moradora e slime (vagam).
- **Inventário/HUD** (`scripts/inventory.gd`, `scripts/hud.gd`).
- **Loja** (`scripts/shop.gd`).
- **Tempo e clima** (`scripts/time_manager.gd`, `scripts/weather.gd`,
  `scripts/day_night.gd`, `scripts/rain.gd`).
- **Áudio** (`scripts/audio_manager.gd`): passos, ferramentas, música e chuva.
- **Save/Load** (`scripts/save_game.gd`): inventário, tempo, clima, terreno,
  props, plantações, máquinas e decorações.

## Estrutura

```
scenes/game.tscn          Cena principal
scenes/player.tscn        Player (CharacterBody2D + AnimatedSprite2D + Camera2D)
scripts/world.gd          Monta o mundo, entidades e expõe use_tool/save
scripts/dual_grid.gd      Renderizador dual grid + overlay de editor
scripts/player.gd         Movimento, animação e uso de ferramentas
scripts/crop.gd           Plantação (4 estágios + crescimento)
scripts/prop.gd           Árvore/toco
scripts/machine.gd        Aspersor / espantalho / pescador
scripts/fishing.gd        Minigame de pesca (UI + lógica)
scripts/decor.gd          Modo decoração (paleta + colocar/remover)
scripts/critter.gd        Criaturas/NPCs ambientais
scripts/house_builder.gd  Casa 3x3 com colisão
scripts/inventory.gd      Inventário, sementes, moedas, hotbar (autoload)
scripts/hud.gd            HUD (hotbar, itens, relógio)
scripts/shop.gd           Loja
scripts/time_manager.gd   Relógio/dia (autoload)
scripts/weather.gd        Clima (autoload)
scripts/rain.gd           Overlay de chuva
scripts/day_night.gd      Tint de dia/noite
scripts/audio_manager.gd  SFX/música/chuva (autoload)
scripts/save_game.gd      Persistência (autoload)
scripts/pause_menu.gd     Menu de pausa
scripts/settings.gd       Modo andar/correr
scripts/data/enums.gd     Enums (class_name Enums)
scripts/data/game_data.gd Dados/itens/preços/ícones (autoload GameData)
scripts/terrain_layer.gd  Camada de pintura do terreno
assets/graphics/          Arte do jogo (personagens, tilesets, ícones, plantas...)
assets/audio/             Sons e música
assets/tiles/             Tiles do dual grid + TileSet de pintura
assets/sprites/           SpriteFrames do personagem
plans/                    Roadmap de próximas funcionalidades (um .md por plano)
docs/README.md            Índice da documentação detalhada
docs/player.md            Movimento do personagem e caixa de andabilidade
docs/github-projects.md   Board do GitHub Projects: campos, labels e fluxo
docs/adr/                 Decisões de arquitetura (ADRs) e template
tools/gen_player_frames.py     Gera as skins do personagem
tools/generate_placeholders.py Gera os PNGs placeholder
tools/smoke_test.gd            Smoke test headless
.agents/skills/                Skills do pi (checkup, issue, start, pr) e scripts de gestão
.githooks/pre-commit           Checkup offline antes do commit
tools/setup_hooks.sh           Instala os hooks locais (core.hooksPath)
docs/checkup.md                Checkup de consistência do repositório
docs/workflow.md               Fluxos de trabalho (assumir issue, criar novo)
```

## Personagem (skins)

`assets/sprites/player_<skin>_frames.tres` (basic, blue, cowboy, grey, red,
straw) — geradas por `tools/gen_player_frames.py` a partir do sheet base de
48x48, incluindo `idle`/`walk` + as ferramentas
`hoe/water/axe/sword/fish/seed`. Troque de skin no jogo em
**Esc > Opções > Aparência** (a escolha fica em `user://settings.cfg`).

## Gestão do projeto

Bugs, features e roadmap são gerenciados no **GitHub Projects**:
<https://github.com/users/guiguetz/projects/1>. Campos (`Status`, `Priority`,
`Tipo`, `Area`, `Effort`), convenção de labels e fluxo de trabalho estão em
[`docs/github-projects.md`](docs/github-projects.md).

- **Issues de bug** usem o template 🐛 Bug (severidade, sintoma, reprodução,
  causa e verificação).
- **Issues de plano** usem o template 🗺️ Plano e linkam o arquivo de `plans/`.
- **CI** (`.github/workflows/ci.yml`): roda o smoke test headless e, quando
  existir `tests/`, a suíte gdUnit4, a cada push/PR na `main`.
- **Checkup** (`.github/workflows/checkup.yml`): valida planos, issues, labels
  e docs a cada push/PR; detalhes em [`docs/checkup.md`](docs/checkup.md).

## Rodar / testar

```bash
# Rodar o jogo (Godot 4.6.3 neste ambiente; ver docs/adr/001-versao-do-godot.md)
/home/guilherme/godot/Godot_v4.6.3-stable_linux.x86_64 --path .

# Instalar os hooks de git (checkup de consistência no pre-commit)
bash tools/setup_hooks.sh

# Regenerar as skins do personagem
python3 tools/gen_player_frames.py

# Smoke test headless (ferramentas, plantio, colheita, máquinas, save/load)
/home/guilherme/godot/Godot_v4.6.3-stable_linux.x86_64 --headless --path . \
  --script tools/smoke_test.gd
```

## Configuração

- Resolução interna: 640x360 (janela 1280x720), filtro nearest (pixel art).
- Fonte: `PixeloidSans` (`[gui] theme/custom_font`).
- Ações de input no `Project Settings > Input Map`.
