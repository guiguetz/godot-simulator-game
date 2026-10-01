# 005 — Checkup de consistência (skill + automação)

- **Status:** Concluído
- **Prioridade:** Média
- **Esforço:** P (horas)
- **Depende de:** —
- **Arquivos-alvo:** `.agents/skills/checkup/`, `docs/checkup.md`, `AGENTS.md`, `docs/github-projects.md`

## Objetivo
Um comando (`/skill:checkup`) que valida se as regras do `AGENTS.md` estão
sendo cumpridas — issues abertas, board atualizado, planos espelhados, labels
documentadas — mantendo a casa organizada com verificação mecânica.

## Motivação / Contexto
As invariantes de workflow do `AGENTS.md` são cumpridas "de memória" pelo
agente, sem verificação objetiva. Inconsistências reais (issue sem campos no
board, label não documentada) já surgiram e não eram detectadas.

## Comportamento esperado
Script CLI + skill do pi que roda as verificações de `docs/checkup.md`,
reporta OK/WARN/FAIL/SKIP e exit code 1 com FAIL. O agente corrige os FAILs
na fonte e re-roda até zerar.

## Design técnico
Skill em `.agents/skills/checkup/` (spec Agent Skills, descoberta por
`.agents/skills/`) com `SKILL.md` (roteiro de correção) e
`scripts/checkup.py` (checagens locais via filesystem + `gh` para
issues/board/labels, opcionalmente o smoke test).

## Escopo
- **Incluído:** script de verificação, skill, doc, invariantes no `AGENTS.md`.
- **Fora do escopo:** rodar o checkup em CI como job obrigatório (avaliar depois).

## Tarefas
- [x] Script `checkup.py` com as verificações de `docs/checkup.md`
- [x] Skill `checkup` (`SKILL.md`) com roteiro de ação sobre FAILs
- [x] `docs/checkup.md` documentando verificações e fluxo
- [x] Invariantes 4 e linha no Mapa rápido do `AGENTS.md`
- [x] Checkup rodando sem FAILs (corrigidas: labels não documentadas, campos vazios da issue #8)

## Critérios de aceite
- [x] `python3 .agents/skills/checkup/scripts/checkup.py` termina sem FAIL
- [x] `/skill:checkup` carrega no pi (descoberta por `.agents/skills/`)
- [x] Correções de FAIL são na fonte, com doc atualizada no mesmo commit

## Riscos / Notas
- Checagens de rede dependem de `gh` autenticado; `--offline` cobre ambiente sem auth.
- O smoke test é lento; `--no-smoke` para iteração rápida.
