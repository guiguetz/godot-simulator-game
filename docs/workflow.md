# Fluxos de trabalho

Como trabalhar neste repositório sem depender de memória: **como assumir uma
issue existente** (Fluxo A) e **como criar algo novo** (Fluxo B), garantindo
que todas as automações rodem. As regras obrigatórias estão no
[`AGENTS.md`](../AGENTS.md); aqui está o passo a passo.

## Fluxo A — assumir uma issue existente

```bash
/skill:start 4        # (ou: python3 .agents/skills/start/scripts/start.py 4)
```

O `start` valida a issue, move o board para **In Progress**, cria a branch
`<tipo>/<4>-slug` e mostra o contexto (inclusive o plano linkado). Depois:

1. implemente (lendo o plano `plans/NNN-*.md` e o código envolvido);
2. rode o checkup e o smoke test:
   ```bash
   python3 .agents/skills/checkup/scripts/checkup.py --no-smoke
   godot --headless --path . --script tools/smoke_test.gd
   ```
3. commite com o sufixo `(#N)` (o hook de pre-commit roda o checkup offline);
4. abra o PR:
   ```bash
   /skill:pr            # (ou: python3 .agents/skills/pr/scripts/open_pr.py)
   ```
   O corpo ganha `Fixes #N`, o board vai para **In Review** (automático) e, no
   merge, para **Done**.

## Fluxo B — criar algo novo

| Situação | Vira | Como |
|---|---|---|
| **Defeito/regressão** (mesmo hipótese) | Issue (template 🐛 Bug) | `/skill:issue --tipo Bug` |
| **Qualquer outro trabalho** (feature, tooling, docs, refactor, arte, design) | **Plano** `plans/NNN-*.md` + issue espelho | escrever o plano e `/skill:issue --plan-file plans/NNN-*.md --title "[Plano NNN] ..."` |
| **Decisão de arquitetura/processo** | ADR em `docs/adr/` | seguir `docs/adr/README.md` |
| **Dúvida/exploração** | nada | — |

> Regra: **bug vira issue; o que não é bug vira plano** (+ issue espelho).
> Decisões podem virar ADR; correções triviais (typo/link) podem ir num PR
> direto, sem plano.

## Branching

Trunk-based, branch curta por issue (ver `AGENTS.md`, invariante 6):

```
main ──┬────────┬────────┬────▶  (protegida: só via PR)
       │        │        │
   fix/4-*  feat/3-*  docs/9-*
```

- nome: `<tipo>/<N>-slug`, `<tipo>` ∈ `feat|fix|docs|chore|refactor|art|design`;
- 1 branch = 1 issue = 1 PR; branch morre no merge;
- **nunca** commitar direto na `main` (protegida; exige PR).

## O que roda sozinho

| Gatilho | Automação |
|---|---|
| `git commit` | **pre-commit** → checkup `--offline` (bloqueia só em `FAIL`) |
| push / PR | **CI** (smoke + gdUnit4) e **Checkup** (com board, se houver token) |
| push na `main` | **Sync wiki** (`docs/` → wiki) |
| issue criada | **auto-add** ao board |
| PR com `Fixes #N` | **Status → `In Review`** |
| PR mergeado / issue fechada | **Status → `Done`** |

O que **não** é automático (e as skills cobrem): escolher a issue, movê-la para
`In Progress`, criar a branch e abrir o PR.

## Definição de pronto

- checkup sem `FAIL` e smoke test `PASS`;
- commit com `(#N)`, PR com `Fixes #N`;
- doc atualizada no mesmo PR (invariante 3);
- issue fechada e board em `Done`.
