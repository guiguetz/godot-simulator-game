# Checkup de consistência

Ferramenta que valida se as regras de [`AGENTS.md`](../AGENTS.md) estão sendo
cumpridas na prática: planos espelhados em issues, board do
[GitHub Projects](https://github.com/users/guiguetz/projects/1) atualizado,
labels documentadas, templates e arquivos-base no lugar.

Faz parte da skill `checkup` do pi
(`.agents/skills/checkup/`) — no pi, rode `/skill:checkup`. Fora do pi, o
script funciona sozinho:

```bash
python3 .agents/skills/checkup/scripts/checkup.py           # checkup completo
python3 .agents/skills/checkup/scripts/checkup.py --offline # sem rede/GitHub
python3 .agents/skills/checkup/scripts/checkup.py --no-smoke # pula o smoke test
```

## O que é verificado

| Verificação | O que confere |
|---|---|
| `arquivos-base` | Arquivos referenciados pelo `AGENTS.md` existem |
| `índice-de-planos` | Cada `plans/NNN-*.md` tem linha no índice e vice-versa |
| `template-de-planos` | Planos têm Objetivo, Status, Prioridade, Esforço, Critérios de aceite |
| `labels-do-repo` / `labels-de-template` | Labels usadas nos templates existem no repo |
| `labels-documentadas` | Toda label convencional está em `docs/github-projects.md` |
| `issue-type-label` | Issues abertas têm label `type:*` |
| `planos-↔-issues` | Todo plano tem issue `[Plano NNN]` linkando o arquivo, e vice-versa |
| `board-↔-issues` | Issues estão no board, com `Priority`/`Tipo`/`Area`/`Effort` preenchidos e `Status` coerente com o estado da issue |
| `board-campos-documentados` | Opções dos campos do board batem com a doc |
| `smoke-test` | Roda o smoke test headless do Godot |

Níveis: `OK` (consistente), `WARN` (provável problema), `FAIL` (violação de
regra — corrija), `SKIP` (não executado). O exit code é 1 se houver FAIL, o que
permite usar o script em CI ou em hooks.

## Fluxo recomendado

1. Rode `/skill:checkup` no fim de uma sessão de trabalho (ou antes de abrir PR).
2. Corrija os FAILs **na fonte** — por exemplo, crie a issue espelho que faltou
   em vez de relaxar a verificação.
3. Re rode até zerar os FAILs.
4. Se uma regra do `AGENTS.md` deixou de fazer sentido, atualize `AGENTS.md` e
   o checkup **no mesmo commit** — nunca ajuste o script para mascarar um FAIL.
