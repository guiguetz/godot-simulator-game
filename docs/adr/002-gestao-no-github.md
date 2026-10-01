# ADR 002 — Gestão no GitHub Issues + Projects

- **Status:** Aceita
- **Data:** 2026-10-01
- **Contexto:** [`docs/github-projects.md`](../github-projects.md), [`plans/README.md`](../../plans/README.md), commit `e226974` (removido `issues/`)

## Contexto

Originalmente bugs eram arquivos em `issues/*.md`. O diretório foi removido no
commit `e226974` e os bugs migraram para o **GitHub Issues**, com o backlog
gerenciado no **GitHub Projects v2** (<https://github.com/users/guiguetz/projects/1>).
A migração deixou referências obsoletas a `issues/` (issue
[#8](https://github.com/guiguetz/godot-simulator-game/issues/8)) e a fronteira
entre "bug", "plano" e "board" não estava registrada como decisão.

## Decisão

- **Bugs e regressões** vivem no GitHub Issues (template 🐛 Bug), com as seções
  *Sintoma / Reprodução / Causa / Verificação* e labels `bug` + `type:bug`.
- **Features futuras** viram `plans/NNN-*.md` (fonte de detalhe) **e** uma issue
  espelho `[Plano NNN] ...` no Projects (template 🗺️ Plano).
- O **board é a fonte única de priorização** (`Status`, `Priority`, `Tipo`,
  `Area`, `Effort`); a issue é o veículo, o arquivo/board é a verdade.
- O diretório `issues/` é **deprecado**; textos e templates passam a apontar
  para o GitHub Issues (correção da #8).
- Fluxo de status: `Backlog → Ready → In Progress → In Review → Done`.

## Consequências

- **Positivas:** uma única fonte de verdade, automações do GitHub (auto-add,
  fechar→Done) funcionam, histórico preservado no repositório via `plans/`.
- **Negativas / custos:** exige rede/permissão para consultar o backlog;
  alterar campos do board depende do `gh project`/API.
- **Em aberto:** quando um bug "grande" deve virar plano em vez de issue;
  hoje a regra é qualitativa ("defeito → issue, trabalho futuro → plano").

## Alternativas descartadas

- **Manter `issues/` em arquivo** — duplicaria a fonte de verdade e perderia as
  automações do Projects.
- **Usar só o Projects, sem issues no repositório** — perderia templates,
  labels e a ligação PR↔issue.
