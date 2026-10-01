# 002 — Menus de debug / controles internos

- **Status:** Proposto
- **Prioridade:** Média
- **Esforço:** M (dias)
- **Depende de:** — (aproveita `scripts/pause_menu.gd` como referência de UI)
- **Arquivos-alvo:**
  - `scripts/debug_menu.gd` (novo, `CanvasLayer` autocontido)
  - `scripts/debug_state.gd` (novo, autoload opcional ou `static`)
  - `scenes/game.tscn` (adicionar o nó)
  - `scripts/time_manager.gd` (API de velocidade / avançar dia)
  - `scripts/weather.gd` (forçar clima)
  - `scripts/inventory.gd` (dar itens/moedas)
  - `scripts/world.gd` (teleporte, inspecionar célula, overlay de grid)
  - `project.godot` (ação de input `debug_toggle`)

## Objetivo

Ter um **menu de debug em jogo** (tecla `F3` / `~`) que exponha controles
internos — acelerar o tempo, pausar o relógio, avançar de dia, forçar clima,
dar itens/moedas, teleportar e visualizar grades/colisões — sem editar código
nem reiniciar o jogo.

## Motivação / Contexto

Hoje o relógio tem apenas `TimeManager.minutes_per_second = 2.0` (fixo) e nada
na UI permite acelerá-lo; testar crescimento de plantação, virada de dia ou
clima exige esperar minutos reais. Não há ferramenta de inspeção de célula
(qual terreno, andável, arável) nem atalho para pular dias.

O `pause_menu.gd` já monta UI em código (VBox/PanelContainer, `_make_button`,
etc.) e é um bom modelo de estilo, mas o debug **não deve pausar** o jogo —
queremos observar o mundo evoluindo acelerado. Por isso ele fica num
`CanvasLayer` separado, desacoplado do menu de pausa.

## Comportamento esperado

- `F3` abre/fecha um painel de debug **sem pausar** o jogo. Também acessível
  pelo menu de pausa (`Debug`) para quem prefere gamepad.
- Seções:
  1. **Tempo:** multiplicador `1x / 2x / 5x / 10x / 50x`, pausar/retomar o
     relógio, avançar 1 hora, avançar 1 dia (dispara `new_day`).
  2. **Clima:** `Limpo` / `Chuva` (força `Weather.kind`).
  3. **Jogador:** posição atual + célula, teleporte para célula digitada.
  4. **Inventário:** `+100 moedas`, `+1` de cada item, `+1` de cada semente.
  5. **Mundo/Inspeção:** célula sob o mouse (terreno, `walkable`, `tillable`),
     botão "regar/plantar tudo" opcional.
  6. **Render:** toggles para grade dual, grade lógica, labels e colisão.
  7. **Info:** FPS, frame time, versão, `OS.is_debug_build()`.
- Em builds de release (`OS.is_debug_build() == false` e/ou feature
  `debug` ausente), o menu fica indisponível.
- Estado do relógio é restaurado ao valor original quando o menu fecha, exceto
  se o dev marcar "persistir".

## Design técnico

1. **Ação de input.** Em `project.godot`:

   ```
   debug_toggle={
   "deadzone": 0.5,
   "events": [ ... F3 (keycode 4194334) ... ]
   }
   ```

   Usar `_input()` no `DebugMenu` com `event.is_action_pressed("debug_toggle")`
   e `get_viewport().set_input_as_handled()`.

2. **`scripts/debug_menu.gd`** (`CanvasLayer`, `layer = 90`, acima do HUD mas
   abaixo do pause). `_build_ui()` em código espelhando `pause_menu.gd`.
   `process_mode = Node.PROCESS_MODE_ALWAYS` para responder mesmo com o jogo
   pausado. Tabela de multiplicadores, `OptionButton` de clima, `LineEdit` de
   teleporte, `Label` de inspeção atualizada em `_process`.

   ```gdscript
   func open() -> void:
       visible = true
       _capture_original_state()

   func close() -> void:
       visible = false
       _restore_state()
   ```

3. **APIs mínimas a adicionar** (evitar mexer direto nas variáveis):
   - `TimeManager`:
     - `set_speed(multiplier: float)` → ajusta `minutes_per_second`.
     - `set_clock_paused(v: bool)` → hoje `paused` existe, expor setter.
     - `advance_hours(h: float)` e `advance_day()` (dispara `new_day`).
   - `Weather`: `force(kind: int)` → seta `kind` e emite `changed`.
   - `Inventory`: `debug_grant(items: Dictionary)` / `debug_grant_coins(n)`.
   - `World`: `cell_at_mouse()` (usa `get_global_mouse_position()`),
     `teleport_player(cell)`, `debug_cell_info(cell) -> Dictionary`.

4. **Overlay de grades.** O `DualGrid` já tem `editor_show_grid`,
   `editor_show_dual`, `editor_show_labels`, `editor_show_legend`, mas o
   overlay só é criado em `Engine.is_editor_hint()`. Duas opções:
   - **(a)** Reaproveitar `paint_overlay()` criando o `_EditorOverlay` também
     em runtime quando `debug_render` estiver ligado.
   - **(b)** Novo desenho de debug simples (`draw_rect` por célula) no próprio
     `DebugMenu`, sem tocar no `DualGrid`.
   Preferir **(b)** por isolamento; registrar **(a)** como nota de melhoria.

5. **Segurança.** Guardar tudo atrás de:

   ```gdscript
   static func is_enabled() -> bool:
       return OS.is_debug_build() or OS.has_feature("debug")
   ```

   Não persistir nada em `user://savegame.json`. Opcionalmente, adicionar
   `debug = true` em `Project Settings > Feature Tags` para testes.

## Escopo

- **Incluído:** painel `F3`, seções Tempo/Clima/Inventário/Inspeção/Render,
  APIs de debug nos autoloads, bloqueio em release.
- **Fora do escopo:** console de comandos, cheats por chat, menu de
  teleporte visual, edição de save em disco, relatórios de performance.

## Tarefas

- [ ] Criar ação `debug_toggle` (F3) no Input Map
- [ ] Criar `scripts/debug_menu.gd` com abrir/fechar e `_build_ui()`
- [ ] Adicionar o nó à `scenes/game.tscn`
- [ ] `TimeManager`: `set_speed`, `set_clock_paused`, `advance_hours`, `advance_day`
- [ ] `Weather`: `force(kind)`
- [ ] `Inventory`: `debug_grant` / `debug_grant_coins`
- [ ] `World`: `debug_cell_info`, teleporte, overlay simples
- [ ] Guardar tudo com `is_enabled()` (release desligado)
- [ ] Botão "Debug" no `pause_menu.gd` abrindo o painel
- [ ] Documentar em `README.md` (seção Controles / Dev)

## Critérios de aceite

- [ ] `F3` abre/fecha o painel sem pausar (`get_tree().paused` continua igual).
- [ ] Multiplicadores alteram a velocidade real do relógio (verificável no HUD).
- [ ] "Avançar 1 dia" muda o dia, dispara `new_day` e faz plantações crescerem.
- [ ] Forçar clima muda chuva/tint imediatamente.
- [ ] Teleporte move o player e a câmera sem atravessar colisão de forma estranha.
- [ ] Painel não aparece em build de release.
- [ ] Abrir/fechar o menu restaura a velocidade do relógio.

## Riscos / Notas

- **Ordem dos autoloads:** `TimeManager`, `Weather`, `Inventory` já existem;
  o `DebugMenu` deve referenciá-los preguiçosamente (`get_node_or_null`) para
  não quebrar cenas que não os tenham (ex.: smoke test).
- **Velocidade extrema:** `50x` com `_process` pode causar vários `new_day` num
  único frame se o delta for grande; `TimeManager` usa `if`, não `while`, então
  o excedente se acumula corretamente ao longo dos frames — validar.
- **F3 no editor:** o Godot pode consumir F3; testar com a janela focada e,
  se necessário, mapear também `~` (acento grave / `quoteleft`) ou `F10`.
- **Não vazar para o save:** nenhum valor de debug deve entrar em `to_dict()`.
- **Dual grid em runtime:** a opção (a) exige revisar `_ensure_overlay()` que
  hoje retorna cedo fora do editor; não quebrar o caminho @tool.
