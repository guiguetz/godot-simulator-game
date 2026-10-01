# ADR 005 — Versionamento do save

- **Status:** Aceita
- **Data:** 2026-10-01
- **Contexto:** [`scripts/save_game.gd`](../../scripts/save_game.gd)

## Contexto

O save do mundo é JSON em `user://savegame.json` e já traz `"version": 1`
(`scripts/save_game.gd`), mas não há política para quando/como incrementar a
versão nem como carregar saves antigos. Sem isso, uma mudança de formato quebra
saves existentes silenciosamente.

## Decisão

- Todo save gravado inclui `version` (inteiro), começando em `1`.
- **Incrementa-se `version` sempre que uma mudança for incompatível** (campo
  removido/renomeado, tipo alterado, nova estrutura obrigatória). Mudanças
  aditivas com valor padrão não exigem bump.
- O carregamento trata saves com `version` menor pela **migração sequencial**
  (`_migrate_vN_to_vN1`), preservando o máximo de progresso.
- Save com `version` **maior** que o suportado é recusado com aviso claro, em
  vez de carregar parcialmente.

## Consequências

- **Positivas:** saves de jogadores sobrevivem a mudanças de formato; o
  formato se torna um contrato explícito.
- **Negativas / custos:** cada mudança de formato exige escrever e manter a
  migração correspondente.
- **Em aberto:** se/quando implementar o mecanismo de migração — hoje existe
  só o campo `version`, sem código de migração. Decidir se entra agora ou junto
  da próxima mudança incompatível.

## Alternativas descartadas

- **Sem versão, "quebra e refaz o save"** — aceitável em protótipo, ruim a
  partir do momento em que há progresso de jogador a preservar.
- **Sempre bump + descartar save antigo** — perde progresso sem necessidade
  quando a mudança é aditiva.
