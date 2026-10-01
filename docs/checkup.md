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
python3 .agents/skills/checkup/scripts/checkup.py --no-board # pula o GitHub Projects (CI)
```

## O que é verificado

| Verificação | O que confere |
|---|---|
| `arquivos-base` | Arquivos referenciados pelo `AGENTS.md` existem |
| `índice-de-planos` | Cada `plans/NNN-*.md` tem linha no índice e vice-versa |
| `template-de-planos` | Planos têm Objetivo, Status, Prioridade, Esforço, Critérios de aceite |
| `docs-↔-índice` | Todo doc em `docs/` está no índice e os links do índice não estão mortos |
| `adr-↔-índice` | Todo ADR está no índice de `docs/adr/README.md`, e vice-versa |
| `labels-do-repo` / `labels-de-template` | Labels usadas nos templates existem no repo |
| `labels-documentadas` | Toda label convencional do repo está em `docs/github-projects.md` |
| `labels-catalogadas` | Toda label catalogada na doc existe no repo |
| `issue-type-label` | Issues abertas têm label `type:*` |
| `planos-↔-issues` | Todo plano tem issue `[Plano NNN]` linkando o arquivo, e vice-versa |
| `prs-↔-issues` | PRs abertos referenciam alguma issue (`#N`) |
| `board-↔-issues` | Issues estão no board, com `Priority`/`Tipo`/`Area`/`Effort` preenchidos e `Status` coerente com o estado da issue |
| `board-campos-documentados` | Opções dos campos do board batem com a doc |
| `board-views` | Nome, layout e filtro das views batem com a doc |
| `board-workflows` | Workflows ativos no board batem com a tabela da doc |
| `smoke-test` | Roda o smoke test headless do Godot |

Níveis: `OK` (consistente), `WARN` (provável problema), `FAIL` (violação de
regra — corrija), `SKIP` (não executado) — **inclusive falha transitória da API**
(rate limit/rede): ela vira `SKIP`, não `FAIL`, e as verificações dependentes
também são puladas, evitando cascata de falsos positivos. O exit code é 1 se
houver FAIL, o que permite usar o script em CI ou em hooks.

## Fluxo recomendado

1. Rode `/skill:checkup` no fim de uma sessão de trabalho (ou antes de abrir PR).
2. Corrija os FAILs **na fonte** — por exemplo, crie a issue espelho que faltou
   em vez de relaxar a verificação.
3. Re rode até zerar os FAILs.
4. Se uma regra do `AGENTS.md` deixou de fazer sentido, atualize `AGENTS.md` e
   o checkup **no mesmo commit** — nunca ajuste o script para mascarar um FAIL.

## Cadência

- **Antes de abrir PR:** checkup completo (com smoke test).
- **Fim de sessão de gestão** (issues/board/planos): `--no-smoke`.
- **Cada edição de código:** não é necessário rodar.

## No CI

O workflow [`checkup.yml`](../.github/workflows/checkup.yml) roda o checkup a
cada push/PR na `main`, **sem** o filtro de `docs/**` (ao contrário do
`ci.yml`), e usa `--no-board` porque o token do CI não tem escopo de Projects.
