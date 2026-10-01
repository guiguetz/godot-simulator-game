# 010 — Rotinas de NPCs com LimboAI

- **Status:** Proposto
- **Prioridade:** Alta
- **Esforço:** G (semana+)
- **Depende de:** [009](009-dialogic-diálogos.md) (diálogos integrados às rotinas)
- **Arquivos-alvo:** `scripts/npc/` (novo diretório), `scripts/npc_schedule.gd` (novo), `docs/npcs.md`

## Objetivo

NPCs têm rotinas diárias baseadas em hora, dia da semana, estação e clima —
indo a locais diferentes, interagindo entre si e reagindo ao mundo.

## Motivação / Contexto

Stardew Valley vive das rotinas dos NPCs: sábado de manhã na praia, verão no
píer ao pôr do sol, dia de chuva em casa. Hoje nossos NPCs são criaturas
ambientais com wander aleatório. Implementar rotinas é o que transforma NPCs
em personagens. LimboAI combina behavior trees com hierarchical state machines,
ideal para decisões contextuais com estados persistentes.

## Comportamento esperado

- Cada NPC tem uma **schedule table** que mapeia (estação, dia, hora, clima) →
  local de destino.
- O NPC se locomove até o local e executa comportamentos (sentar, pescar,
  conversar com outro NPC, olhar o mar).
- Quando a condição muda (ex.: começa a chover), o NPC recalcula destino.
- NPCs podem se encontrar e ter interações entre si (ex.: dois NPCs no mesmo
  local触发am uma animação de conversa).
- Horários de loja/interações seguem a rotina do NPC (vendedor não vende às 2h).
- Rotinas são data-driven: editar um recurso `.tres` muda o comportamento,
  sem tocar em código.

## Design técnico

- **Addon:** LimboAI (`limbonaut/limboai` no GitHub).
- **Estrutura por NPC:**
  - `NPCBrain` (root node com `BHTree`) — behavior tree que decide o que fazer.
  - `NPCStateMachine` (LimboAI HSM) — estados: `IDLE`, `WALKING`,
    `AT_LOCATION`, `INTERACTING`, `SLEEPING`.
  - `NPCSchedule` (Resource) — tabela de horários em formato `.tres`.
- **Schedule format:**
  ```tres
  [resource]
  rules = [
    { "season": "summer", "day": "saturday", "hour_range": [8, 12],
      "weather": "any", "location": "beach", "activity": "fishing" },
    { "season": "any", "day": "any", "hour_range": [0, 6],
      "weather": "any", "location": "home", "activity": "sleeping" },
  ]
  fallback = { "location": "home", "activity": "idle" }
  ```
- **Locais:** `Marker2D` ou `NavigationLink2D` no mapa, nomeados
  (`beach`, `home`, `shop`, `pier`).
- **Pathfinding:** `NavigationAgent2D` para locomoção (já suportado pelo Godot).
- **Integração com Dialogic:** NPC no estado `INTERACTING` abre diálogo
  se o player se aproximar.
- **Integração com TimeManager:** `NPCScheduleManager` (autoload) dispara
  reavaliação a cada mudança de hora.
- **Save:** posição do NPC e estado atual (não a schedule, que é constante).

## Escopo

- **Incluído:** sistema de schedule, locomoção com pathfinding, estados
  básicos (idle, walking, at_location, sleeping), reação a clima, 3 NPCs
  com rotinas distintas, integração com diálogo.
- **Fora do escopo:** interações entre NPC-NPC (fase 2), animações complexas
  de atividade, sistema de empregos.

## Tarefas

- [ ] Instalar LimboAI como addon
- [ ] Criar `NPCSchedule` como Resource com tabela de regras
- [ ] Implementar `NPCStateMachine` com estados básicos
- [ ] Criar behavior tree raiz (`NPCBrain`) com decisão de schedule
- [ ] Implementar `NPCScheduleManager` que reavalia a cada hora
- [ ] Adicionar `NavigationAgent2D` aos NPCs e configurar locomoção
- [ ] Definir locais no mapa (Marker2D para beach, home, shop, etc.)
- [ ] Criar rotinas para 3 NPCs (ex.: vendedor, pescador, moradora)
- [ ] Integrar com Dialogic: NPC no local + player perto = diálogo
- [ ] Reação a clima: NPC vai pra casa quando chove
- [ ] Save/load de posição e estado dos NPCs
- [ ] Documentar em `docs/npcs.md` (seção de rotinas)

## Critérios de aceite

- [ ] NPC se move para o local correto conforme hora/estação/clima.
- [ ] Editar `.tres` de schedule muda o comportamento sem código.
- [ ] NPC reage a chuva indo para casa em < 30s.
- [ ] Player interage com NPC no local correto via Dialogic.
- [ ] Posição e estado dos NPCs são salvos e restaurados.
- [ ] Smoke test cobre NPC indo para local agendado.

## Riscos / Notas

- **Complexidade:** é o sistema mais complexo do jogo. Mitigar: começar
  com 1 NPC e 2 locais, expandir depois.
- **Performance:** muitos NPCs recalculando pathfinding. Mitigar: só
  calcular para NPCs visíveis ou próximos do player.
- **Debug:** comportamentos imprevisíveis são difíceis de debugar.
  Mitigar: overlay no editor mostrando schedule atual de cada NPC.