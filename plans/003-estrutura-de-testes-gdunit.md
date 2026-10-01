# 003 — Estrutura de testes com gdUnit4

- **Status:** Proposto
- **Prioridade:** Alta
- **Esforço:** M (dias)
- **Depende de:** `addons/gdUnit4` (já instalado, v6.2.0) — nenhum outro plano
- **Arquivos-alvo:** `tests/**`, `project.godot` (`[gdunit4]`), `README.md`,
  possivelmente `tools/smoke_test.gd` (migração futura)

## Objetivo

Criar uma suíte automatizada em `tests/` que cubra **cada sistema**
isoladamente (testes de unidade) e os **fluxos jogáveis** ponta a ponta
(integração), substituindo o `tools/smoke_test.gd` monolítico por testes
organizados, com relatório e execução por comando único.

## Motivação / Contexto

Hoje a única verificação automatizada é `tools/smoke_test.gd`: um script
`SceneTree` que instancia `game.tscn`, roda ~25 `_check()` no mesmo estado e
imprime `PASS/FAIL`. Limitações:

- **Sem isolamento:** tudo compartilha o mesmo mundo/autoloads, então uma falha
  contamina as checagens seguintes.
- **Sem granularidade:** não dá para ver *qual funcionalidade* falhou nem
  rodar só um teste.
- **Sem asserções ricas:** comparações manuais, sem mensagem de diff.
- **Sem CI:** não há relatório (JUnit) nem código de saída por caso.

O gdUnit4 já está instalado e traz `GdUnitTestSuite`, asserts, mocks/spies,
`scene_runner`, `await_signal_on`, temp dirs e relatório. Falta apenas a
estrutura de testes e a convenção de isolamento.

## Comportamento esperado

- Um comando roda a suíte completa e retorna código de saída 0 (sucesso) ou
  ≠0 (falha), com relatório por arquivo/caso.
- Cada arquivo de teste cobre **uma** funcionalidade e pode rodar sozinho.
- Estado global (autoloads `Inventory`, `TimeManager`, `Weather`,
  `GameSettings`, `user://savegame.json`) é **restaurado antes de cada caso**.
- Existem testes de regressão que travam os bugs já corrigidos
  (issues 001/002/003) e o risco aberto (issue 004).
- Testes que não dependem de input real rodam em `--headless`; os que dependem
  de `InputEvent` são executados em modo com display (ver Riscos).

## Design técnico

### Configuração do gdUnit4

O gdUnit busca suítes na pasta configurada em
`gdunit4/settings/test/test_lookup_folder` (padrão `"test"`). Como queremos
`tests/`, adicionar ao `project.godot`:

```ini
[gdunit4]

settings/test/test_lookup_folder="tests"
```

Execução (o runner aceita `-a <dir|suite>` para incluir o alvo):

```bash
# suíte completa
/home/guilherme/godot/Godot_v4.7.2-stable_linux.x86_64 --path . \
  -s addons/gdUnit4/bin/GdUnitCmdTool.gd -a tests --ignoreHeadlessMode

# um arquivo
... -a res://tests/unit/test_inventory.gd

# um caso
... -a "res://tests/unit/test_inventory.gd:test_add_item"
```

> Na primeira execução pode ser necessário abrir o editor com o plugin ativo
> uma vez para o gdUnit registrar as settings. As settings também podem ser
> gravadas pelo menu do plugin (Project > Tools > GdUnit4).

### Estrutura de pastas

```
tests/
  README.md                      # como rodar, convenções e mapa cobertura
  helpers/
    sim_test_suite.gd            # base: reset de autoloads, RNG, save temp
    world_fixture.gd             # boot/teardown de game.tscn para integração
  unit/                          # um sistema por arquivo, sem cena completa
    data/
      test_enums.gd
      test_game_data.gd
    test_inventory.gd
    test_time_manager.gd
    test_weather.gd
    test_settings.gd
    test_crop.gd
    test_prop.gd
    test_machine.gd
    test_critter.gd
    test_dual_grid.gd
    test_house_builder.gd
  world/                         # world.gd quebrado por responsabilidade
    test_world_terrain.gd        # terreno, andabilidade, can_fish
    test_world_tools.gd          # use_tool: enxada/regador/machado/espada/semente
    test_world_machines.gd       # place_machine + efeitos diários
    test_world_decor.gd          # decor_place/remove
    test_world_daily.gd          # _on_new_day: sprinkler, fisher, crescimento
    test_world_serialization.gd  # to_dict/from_dict roundtrip
    test_world_player.gd         # player: facing, animação, colisão, skins
  ui/                            # CanvasLayers e menus
    test_fishing.gd
    test_decor_mode.gd
    test_hud.gd
    test_shop.gd
    test_pause_menu.gd
    test_rain.gd
    test_day_night.gd
    test_audio_manager.gd
  integration/                   # fluxos ponta a ponta sobre game.tscn
    test_boot_game.gd
    test_farming_loop.gd
    test_machine_loop.gd
    test_fishing_flow.gd
    test_save_load_flow.gd
    test_pause_shop_flow.gd
  regression/                    # bugs corrigidos (verificados no GitHub Issues)
    test_issue_001_z_order.gd
    test_issue_002_player_visivel.gd
    test_issue_003_movimento_horizontal.gd
    test_issue_004_walkable_box.gd
```

### Base de teste (`tests/helpers/sim_test_suite.gd`)

`extends GdUnitTestSuite` e centraliza o reset de estado para dar isolamento:

```gdscript
class_name SimTestSuite
extends GdUnitTestSuite

func before_test() -> void:
    _reset_inventory()
    _reset_time()
    _reset_weather()
    _reset_settings()
    seed(12345)  # RNG determinístico para sorteios

func _reset_inventory() -> void:
    Inventory.items.clear()
    Inventory.seeds.clear()
    Inventory.coins = 100
    Inventory.selected_seed = Enums.Seed.TOMATO
    Inventory.selected_slot = 0

func _reset_time() -> void:
    TimeManager.day = 1
    TimeManager.minutes = 6.0 * 60.0
    TimeManager.paused = false

func _reset_weather() -> void:
    Weather.kind = Enums.Weather.CLEAR

func _reset_settings() -> void:
    GameSettings.movement_mode = GameSettings.MovementMode.WALK
    GameSettings.skin = 0
```

Convenções:

- **Nomenclatura:** `test_<feature>.gd`, funções `test_<comportamento>()`.
- **Sem input sintético em headless:** chamar métodos públicos/internos
  diretamente. Quando o caminho exige `InputEvent`, marcar o caso com
  `@warning_ignore`/condicional e rodar em modo com display (ver Riscos).
- **Random:** semear com `seed()`/`RandomNumberGenerator.seed` e testar
  invariantes (ex.: `roll_fish()` sempre em `FISH_LOOT`), não valores exatos,
  exceto com RNG controlado.
- **Sem depender de tempo real:** manipular `minutes` e emitir
  `TimeManager.new_day` diretamente; não esperar `_process`.
- **Save:** usar `create_temp_dir()`/`user://tmp` e restaurar/remover
  `user://savegame.json` no `after_test`.
- **Nodes:** usar `auto_free()`/`scene_runner()` para não vazar órfãos (o
  gdUnit reporta órfãos por padrão).

### Mapa de cobertura (funcionalidade → casos-chave)

| Sistema | Arquivo | Casos principais |
|---|---|---|
| Enums | `unit/data/test_enums.gd` | valores/ordem usados no save e hotbar |
| GameData | `unit/data/test_game_data.gd` | `seed_name`/`item_name`/`item_value`; `roll_fish` válido e pesos; `fish_difficulty`; `can_afford`/`pay` com saldo insuficiente |
| Inventory | `unit/test_inventory.gd` | add/remove/count/has; sinal `changed`; moedas; sementes; `seed_next` circular; `set_slot` clamp; `current_entry`; `to_dict`/`from_dict` roundtrip |
| TimeManager | `unit/test_time_manager.gd` | hora/minuto/`time_string`; virada de dia + `new_day`; `daylight` (0/1 e rampas 5–8/18–21); `paused`; serialização |
| Weather | `unit/test_weather.gd` | `roll` só CLEAR/RAIN; `is_raining`; `name_string`; reação a `new_day` |
| GameSettings | `unit/test_settings.gd` | tabela-verdade de `is_running(shift)`; clamp de modo/skin; persistência em `user://settings.cfg` |
| Crop | `unit/test_crop.gd` | `water`; `grow_day` molhado/seco/`auto_water`; teto de estágio 3; `is_ready` em `grow_days`; `harvest` antes/depois; `restore` e `to_dict` |
| Prop | `unit/test_prop.gd` | 1º `chop` vira toco (+2 madeira); 2º remove (+1); `to_dict` |
| Machine | `unit/test_machine.gd` | `setup` por tipo; `_frames_for`/offsets; `to_dict` |
| Critter | `unit/test_critter.gd` | parâmetros por tipo; frames por tipo (incl. `ROWS_BLOB`); `_face`; volta pra casa quando longe |
| DualGrid | `unit/test_dual_grid.gd` | `setup`/`add_terrain`; 16 tiles no atlas; offset `-tile/2`; `_bits_of` (16 combinações); OOB = false; `refresh_all`/`clear_all` |
| HouseBuilder | `unit/test_house_builder.gd` | cria `HouseWalls`+`HouseRoof`; 3x3; porta sem colisão; paredes com physics layer; z 5/20 |
| World terreno | `world/test_world_terrain.gd` | `terrain_at`/`set_terrain`; `is_walkable(_cell)` água/bloqueio; `can_fish`/`_near_water`; `mouse_cell` |
| World ferramentas | `world/test_world_tools.gd` | enxada em grama/terra→SOIL e rejeita água; regador molha crop; machado em árvore/toco; semente só em SOIL, consome e não empilha; colheita com recompensa; sem semente não planta |
| World máquinas | `world/test_world_machines.gd` | `place_machine` valida célula e paga `machine_cost`; falha sem madeira/ocupado; tipos |
| World decoração | `world/test_world_decor.gd` | `decor_place`/`decor_remove`; índice inválido; célula ocupada/não-andável |
| World ciclo diário | `world/test_world_daily.gd` | aspersor rega vizinhos; pescador perto da água (RNG semeado); crop cresce; chuva = `auto_water` |
| World serialização | `world/test_world_serialization.gd` | roundtrip de terreno/props (toco)/crops/máquinas/decor |
| Player | `world/test_world_player.gd` | `facing_cell`/`_facing_vector`; `_direction_name`; `_tool_anim`; `apply_skin`; walk/run; `_area_walkable` e `collision_padding` (issue 004); `_block_unwalkable`; `_clamp_bounds` |
| Fishing | `ui/test_fishing.gd` | `start` ativa/visível/dificuldade; `_update_progress` dentro/fora da zona; `_finish(true)` dá item e emite sinal; `_finish(false)`/`cancel` não dão; stamina drena/regenera; fish fica nos limites |
| Decor (modo) | `ui/test_decor_mode.gd` | toggle/open/close; `_select`; remoção (-1); `_unhandled_input` clique L/R integra com world |
| HUD | `ui/test_hud.gd` | 9 slots; `_refresh` reflete inventário/moeda; `_items_summary`; atalhos 1..9/roda/tool_next/seed_next |
| Shop | `ui/test_shop.gd` | `_buy_seed` debita/credita; sem moeda não compra; `_sell_total`/`_sell_all`; `_on_back`; disabled |
| PauseMenu | `ui/test_pause_menu.gd` | `open_menu` pausa e fecha overlays; `close_menu` despausa; `_show_panel`; `_choose_skin`; `_open_shop`; salvar/carregar |
| Rain | `ui/test_rain.gd` | `visible` segue `Weather`; respingos limitados a 48; overlay segue câmera |
| DayNight | `ui/test_day_night.gd` | cor = lerp NIGHT→DAY conforme `daylight` |
| AudioManager | `ui/test_audio_manager.gd` | `play_sfx` nome inexistente não quebra; `_on_weather_changed` liga/desliga chuva |
| SaveGame | `integration/test_save_load_flow.gd` | `has_save`/`save_game`/`load_game`/`delete_save`; JSON inválido não derruba; restaura inventário/tempo/clima/player/mundo |
| Boot | `integration/test_boot_game.gd` | `game.tscn` instancia; grupos `world`/`player`; HUD/Fishing/Decor/Shop/Pause presentes; sem erros de script |
| Loop fazenda | `integration/test_farming_loop.gd` | cavar→plantar→regar→`new_day`×N→colher ponta a ponta |
| Loop máquinas | `integration/test_machine_loop.gd` | comprar/colocar aspersor e pescador; efeitos no dia seguinte |
| Fluxo pesca | `integration/test_fishing_flow.gd` | player usa Vara perto da água→minigame→item no inventário |
| Fluxo pausa+loja | `integration/test_pause_shop_flow.gd` | Esc pausa→loja compra semente→volta→retoma |
| Regressões | `regression/*` | ordem de z (Ground -10, Entities 10); player visível; movimento horizontal real; caixa de andabilidade ≤ 1 tile (issue 004) |

### Migração do smoke test

`tools/smoke_test.gd` deve continuar funcionando durante a transição. Depois
que a suíte equivalente passar, o smoke test pode ser simplificado ou removido
(tarefa opcional; fora do escopo mínimo).

## Escopo

- **Incluído:**
  - Pasta `tests/` + `tests/README.md` com convenções e comando de execução.
  - Configuração `[gdunit4] test_lookup_folder="tests"` no `project.godot`.
  - Base `SimTestSuite` com reset de autoloads e RNG determinístico.
  - Suítes de unidade de todos os sistemas listados na tabela.
  - Suítes de integração dos fluxos principais sobre `game.tscn`.
  - Testes de regressão das issues 001–004.
  - Atualização do `README.md` com a seção de testes.
- **Fora do escopo:**
  - Alterar lógica de jogo para "facilitar teste" (priorizar testar o
    comportamento atual; ajustes só se virarem bug).
  - Cobertura 1:1 de cada linha; foco é comportamento observável.
  - Editor (`@tool`): overlay do dual grid e `terrain_layer` em modo editor
    (complexo e pouco valioso em headless).
  - Testes visuais/pixel-perfect de arte.
  - Pipeline de CI externo (o plano deixa os comandos prontos, sem configurar
    GitHub Actions).

## Tarefas

- [ ] Adicionar `[gdunit4] test_lookup_folder="tests"` ao `project.godot`.
- [ ] Criar `tests/README.md` (como rodar, convenções, mapa de cobertura).
- [ ] Criar `tests/helpers/sim_test_suite.gd` e validar reset/semeadura.
- [ ] Implementar `unit/data/` (Enums, GameData).
- [ ] Implementar `unit/` de autoloads (Inventory, TimeManager, Weather,
      Settings).
- [ ] Implementar `unit/` de entidades (Crop, Prop, Machine, Critter).
- [ ] Implementar `unit/` de render/estruturas (DualGrid, HouseBuilder).
- [ ] Implementar `world/` (terreno, ferramentas, máquinas, decoração, dia,
      serialização, player).
- [ ] Implementar `ui/` (Fishing, Decor, HUD, Shop, PauseMenu, Rain, DayNight,
      AudioManager).
- [ ] Criar `tests/helpers/world_fixture.gd` e implementar `integration/`.
- [ ] Implementar `regression/` (issues 001–004).
- [ ] Rodar a suíte inteira e corrigir flakiness/órfãos.
- [ ] Atualizar `README.md` (comandos de teste) e `plans/README.md`.
- [ ] (Opcional) Aposentar/simplificar `tools/smoke_test.gd`.

## Critérios de aceite

- [ ] `--path . -s addons/gdUnit4/bin/GdUnitCmdTool.gd -a tests
      --ignoreHeadlessMode` roda a suíte e sai com código 0 em `main` limpo.
- [ ] Cada arquivo listado na tabela existe e passa isoladamente (`-a` no
      arquivo).
- [ ] Nenhum teste depende de ordem de execução nem de tempo real.
- [ ] `before_test` restaura inventário/tempo/clima/settings/save; rodar a
      suíte duas vezes seguidas dá o mesmo resultado.
- [ ] Testes de regressão falham se a correção da issue correspondente for
      revertida (verificado manualmente ao menos para 001/002).
- [ ] Sem nós órfãos reportados pelo gdUnit na suíte de integração.
- [ ] `README.md` documenta o comando e a existência de `tests/`.

## Riscos / Notas

- **Headless + InputEvent:** o gdUnit bloqueia `--headless` por padrão e avisa
  que eventos de input não são transportados nesse modo. Mitigação: (1) testar
  a lógica chamando métodos diretamente em headless; (2) manter, para os
  poucos casos que exigem `InputEvent` real, uma execução separada com display
  (`xvfb-run` ou sessão gráfica). Casos que usam `Input.is_action_pressed`
  (pesca, player) devem ser estruturados com a lógica extraída em funções
  puras para testar sem input.
- **Autoloads compartilhados:** `Inventory` etc. persistem entre suítes. Sem o
  reset do `SimTestSuite` há vazamento de estado e flakiness. É a peça mais
  crítica do plano.
- **`GameSettings` guarda em disco:** `set_movement_mode`/`set_skin` escrevem
  `user://settings.cfg`. Testes devem restaurar/limpar o arquivo para não
  poluir a configuração do desenvolvedor.
- **`SaveGame.PATH` fixo:** testes precisam salvar/restaurar um save real do
  usuário, ou operar em `user://` isolado. Decidir no `world_fixture`.
- **RNG global:** `randf()`/`randi_range()` são globais; outros nós podem
  consumir a sequência. Usar `seed()` no `before_test` e/ou injetar
  `RandomNumberGenerator` controlado.
- **Custo de manter testes:** mundo (`world.gd`) é o mais acoplado. Evitar
  testar detalhes internos privados em excesso; priorizar a API (`use_tool`,
  `place_machine`, `to_dict`/`from_dict`, `is_walkable`).
- **Ordem de execução do plano:** começar por `unit/data` e autoloads (mais
  baratos e dão confiança no reset) antes de `integration/`.
