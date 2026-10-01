# ADR 003 — Onde vive cada documentação

- **Status:** Proposta
- **Data:** 2026-10-01
- **Contexto:** [`README.md`](../../README.md), [`docs/`](../), [`plans/`](../../plans/README.md)

## Contexto

Hoje quase toda a documentação do jogo está no `README.md` (controles, sistemas,
mapa de scripts). O diretório `docs/` tem só `github-projects.md`, e o **wiki do
repositório está habilitado mas vazio** (`has_wiki = true`). O `AGENTS.md` exige
que toda implementação gere doc em `docs/`, sem definir a fronteira com o
`README`.

## Decisão

- **`README.md`** — porta de entrada: visão geral, controles, sistemas em uma
  linha, mapa de scripts e gestão. Deve caber numa leitura rápida.
- **`docs/<topico>.md`** — detalhe de um tema (ex.: gestão, save/load, pesca,
  terreno). Toda mudança de comportamento passa por aqui.
- **`docs/adr/`** — decisões (este diretório).
- **`plans/NNN-*.md`** — trabalho futuro.
- **Wiki desabilitado** como fonte de verdade: `docs/` versionado é a única
  documentação. Se o wiki voltar, será gerado a partir de `docs/`, nunca
  editado à mão.

## Consequências

- **Positivas:** uma fonte por tipo de conteúdo; doc versionada junto do código;
  sem wiki fantasma.
- **Negativas / custos:** exige disciplina para mover conteúdo do README para
  `docs/` quando crescer; desabilitar o wiki requer permissão de admin.
- **Em aberto:** plano de dividir o `README` em `docs/` por sistema (ex.: world,
  player, farming, save) — hoje o README ainda concentra tudo.

## Alternativas descartadas

- **Wiki como doc principal** — não versiona com o código, não passa por PR e
  fica fora do `AGENTS.md`.
- **Só README** — vira um arquivo único difícil de navegar conforme o jogo
  cresce.
