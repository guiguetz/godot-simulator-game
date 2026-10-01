# ADR 003 — Onde vive cada documentação

- **Status:** Aceita
- **Data:** 2026-10-01
- **Contexto:** [`README.md`](../../README.md), [`docs/`](../), [`plans/`](../../plans/README.md)

## Contexto

Hoje quase toda a documentação do jogo está no `README.md` (controles, sistemas,
mapa de scripts). O diretório `docs/` tinha só `github-projects.md`, e o **wiki
do repositório está habilitado e vazio** (`has_wiki = true`). O `AGENTS.md`
exige que toda implementação gere doc em `docs/`, sem definir a fronteira com o
`README`.

## Decisão

- **`README.md`** — porta de entrada: visão geral, controles, sistemas em uma
  linha, mapa de scripts e gestão. Deve caber numa leitura rápida.
- **`docs/<topico>.md`** — detalhe de um tema (ex.: gestão, save/load, pesca,
  terreno). Toda mudança de comportamento passa por aqui.
- **`docs/adr/`** — decisões (este diretório).
- **`plans/NNN-*.md`** — trabalho futuro.
- **Wiki é mantido, mas é sempre gerado a partir de `docs/`** (CI sincroniza
  via push no repositório do wiki). Nada é editado à mão no wiki — ele é uma
  cópia navegável, nunca a fonte.

## Consequências

- **Positivas:** uma fonte por tipo de conteúdo; doc versionada junto do
  código; o wiki volta a existir sem dividir a fonte de verdade.
- **Negativas / custos:** exige workflow de sincronização (e um PAT com
  permissão de push no wiki, via secret `WIKI_TOKEN`); alterar o wiki é sempre
  em dois passos (doc → sync).
- **Em aberto:** plano de dividir o `README` em `docs/` por sistema (ex.: world,
  player, farming, save) — hoje o README ainda concentra tudo.

## Alternativas descartadas

- **Desabilitar o wiki** — perde a navegação agregada e a visibilidade do
  projeto fora do código.
- **Wiki como doc principal (editado à mão)** — não versiona com o código, não
  passa por PR e fica fora do `AGENTS.md`.
