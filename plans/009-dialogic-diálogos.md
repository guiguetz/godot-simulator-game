# 009 — Sistema de diálogos com Dialogic 2

- **Status:** Proposto
- **Prioridade:** Alta
- **Esforço:** M (dias)
- **Depende de:** —
- **Arquivos-alvo:** `scripts/npc_dialogue.gd` (novo), `docs/npcs.md`, `docs/dialogue.md` (novo)

## Objetivo

NPCs falam com o player usando um sistema de diálogos com árvores de escolhas,
condições baseadas em relacionamento e eventos customizados.

## Motivação / Contexto

Hoje os NPCs são criaturas ambientais sem interação. O jogo precisa de NPCs
com conversas, quests e relacionamento — isso exige um sistema de diálogo
robusto. Dialogic 2 é o mais maduro no ecossistema Godot, com editor visual,
variáveis, condições e integração via sinais.

## Comportamento esperado

- Player aproxima de NPC e vê ícone/botão de interação.
- Diálogo abre com texto do NPC e opções de resposta (quando houver).
- Respostas podem mudar com base em relacionamento, hora do dia, estação,
  clima ou flags de quest.
- Eventos customizados tocam ações no jogo (dar item, mudar relacionamento,
  abrir loja, iniciar quest).
- Diálogos são salvos como recursos `.dtl` no editor visual do Dialogic.
- Suporte a múltiplos idiomas (pelo menos pt-BR e en).

## Design técnico

- **Addon:** Dialogic 2 (`nicedialog` ou `dialogic` no Godot Asset Library).
- **Autoload:** Dialogic já cria seus próprios autoloads.
- **Integração:** `NPCDialogueManager` (autoload) escuta o sinal
  `Dialogic.timeline_ended` e gerencia estado.
- **Variáveis do Dialogic:**
  - `relationship_<npc>` (int) — lida pelo `RelationshipManager`.
  - `season`, `day_of_week`, `hour`, `is_raining` — lidas do `TimeManager`
    e `Weather` via custom events.
- **Custom events:** `give_item`, `modify_relationship`, `open_shop`,
  `start_quest` — implementados em GDScript e registrados no Dialogic.
- **Save:** Dialogic tem sistema próprio de save/load; integrar com
  `SaveGame.gd` chamando `Dialogic.Save.save()` e `Dialogic.Save.load()`.
- **Formato:** timelines `.dtl` (JSON interno do Dialogic), personagens `.dch`.

## Escopo

- **Incluído:** instalação do Dialogic 2, diálogos com escolhas, variáveis de
  relacionamento, custom events básicos, save/load, ao menos 2 NPCs com
  diálogos de exemplo.
- **Fora do escopo:** sistema completo de quests, localização completa,
  diálogos de todos os NPCs (futuro).

## Tarefas

- [ ] Instalar Dialogic 2 como addon
- [ ] Criar `NPCDialogueManager` com integração ao TimeManager/Weather
- [ ] Implementar custom events (`give_item`, `modify_relationship`, `open_shop`)
- [ ] Criar diálogos de exemplo para 2 NPCs (ex.: vendedor da loja, morador)
- [ ] Integrar save/load do Dialogic com SaveGame.gd
- [ ] Documentar em `docs/dialogue.md` e atualizar `docs/npcs.md`

## Critérios de aceite

- [ ] Player interage com NPC e abre diálogo com texto e opções.
- [ ] Respostas mudam com base em relacionamento (ex.: >= 50 pontos).
- [ ] Custom event `give_item` adiciona item ao inventário.
- [ ] Diálogo é salvo e restaurado corretamente no save/load.
- [ ] Smoke test cobre interação básica.

## Riscos / Notas

- **Peso do Dialogic:** é um addon grande; pode impactar tempo de build.
  Mitigar: desativar módulos não usados (voz, glossary).
- **Compatibilidade Godot 4.6:** verificar se Dialogic 2 está compatível
  com a versão do projeto.
- **Curva de aprendizado:** o editor visual tem conceitos próprios
  (timelines, characters, portraits). Reserve tempo para explorar.