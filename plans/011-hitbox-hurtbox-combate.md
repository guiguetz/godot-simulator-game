# 011 — Sistema de combate com Hitbox/Hurtbox

- **Status:** Proposto
- **Prioridade:** Média
- **Esforço:** M (dias)
- **Depende de:** —
- **Arquivos-alvo:** `scripts/combat/` (novo), `scripts/enemies/` (novo), `docs/combat.md` (novo)

## Objetivo

Player pode lutar contra inimigos na caverna usando a espada, com detecção de
colisão por hitbox/hurtbox, vida, dano e knockback.

## Motivação / Contexto

A espada já está na hotbar (slot 4), mas não faz nada. A caverna é um dos
pontos centrais do jogo — precisa de combate funcional. Hitbox/hurtbox é o
padrão para jogos 2D: áreas de colisão separadas para atacar e receber dano.

## Comportamento esperado

- Player ataca com espada → hitbox aparece na direção do player por ~0.2s.
- Se hitbox encosta em hurtbox de inimigo → inimigo recebe dano e knockback.
- Inimigos têm vida; quando chega a 0, morrem e dropam loot.
- Player tem vida; se hurtbox do player encosta em hitbox de inimigo →
  player recebe dano e invulnerabilidade temporária (i-frames).
- Inimigos na caverna: Slime (básico), Morcego (voador), Boss (futuro).
- HUD mostra vida do player e, opcionalmente, vida do inimigo atingido.

## Design técnico

- **Hitbox:** `Area2D` com `CollisionShape2D`, filho da espada/ataque.
  Ativada apenas durante o frame de ataque.
- **Hurtbox:** `Area2D` com `CollisionShape2D`, filho do player/inimigo.
  Sempre ativa, detecta hitboxes.
- **Sinais:**
  - `Hitbox.area_entered(hurtbox)` → aplica dano.
  - `Hurtbox.received_damage(amount, source)` → processa dano.
- **Dano:** tabela em `GameDamage` (autoload ou resource):
  ```
  espada: 2
  slime_touch: 1
  bat_dive: 1
  ```
- **Knockback:** `velocity += (position - source.position).normalized() * force`
  por ~0.2s, ignorando input do player.
- **I-frames:** timer de ~1s onde hurtbox do player fica invulnerável
  (piscar sprite como feedback visual).
- **Vida do player:** integrar com `PlayerData` (novo autoload) ou expandir
  `Inventory` para incluir HP.
- **Vida dos inimigos:** `EnemyHealth` (Resource ou propriedade no script).
- **Inimigos:**
  - `Slime` — vagueia, persegue player num raio, ataque corpo a corpo.
  - `Bat` — voa em padrão senoidal, mergulha no player.
  - Ambos usam `LimboAI` (plano 010) para comportamento.

## Escopo

- **Incluído:** hitbox/hurtbox, sistema de vida, dano, knockback, i-frames,
  2 tipos de inimigos (slime, bat), HUD de vida, drop de loot.
- **Fora do escopo:** boss, sistema de habilidades, armas diferentes,
  sistema de level/XP.

## Tarefas

- [ ] Criar `Hitbox` e `Hurtbox` como cenas reutilizáveis (Area2D)
- [ ] Implementar ataque da espada com hitbox direcional
- [ ] Criar `PlayerData` com HP, dano recebido e i-frames
- [ ] Implementar knockback no player e nos inimigos
- [ ] Criar `EnemyBase` com vida, hurtbox e drop de loot
- [ ] Implementar `Slime` com perseguição e ataque corpo a corpo
- [ ] Implementar `Bat` com voo senoidal e mergulho
- [ ] Integrar com HUD: barra de vida do player
- [ ] Adicionar feedback visual: piscar sprite no dano, screen shake leve
- [ ] Criar tabela de dano em `GameDamage` ou Resource
- [ ] Documentar em `docs/combat.md`

## Critérios de aceite

- [ ] Espada causa dano ao slime e o mata em 2 golpes.
- [ ] Player recebe dano ao tocar no slime e fica invulnerável por 1s.
- [ ] Knockback empurra player/inimigo ao receber dano.
- [ ] Inimigo morre e dropa item.
- [ ] HUD mostra HP atual do player.
- [ ] Smoke test cobre ataque básico e dano recebido.

## Riscos / Notas

- **Balanceamento:** dano e HP precisam de ajuste fino. Mitigar: tudo
  em tabelas/config, fácil de tunar.
- **Hitbox direcional:** a hitbox precisa mudar de posição conforme a
  direção do player. Mitigar: usar `Marker2D` para cada direção ou
  rotacionar a hitbox.
- **Integração com LimboAI:** se o plano 010 não estiver pronto, inimigos
  podem ter IA simples (wander + chase) temporariamente.