---
name: issue
description: Cria issues padronizadas no repositório godot-simulator-game com labels convencionais e campos do GitHub Projects preenchidos. Use ao abrir bug, melhoria ou espelho de plano, em vez de montar gh issue create + item-edit na mão.
---

# Criar issue padronizada

Padroniza a abertura de issues: deriva as labels (`type:*`, `area:*`,
`priority:*`, `effort:*`) dos campos do board, cria a issue, adiciona ao
projeto e preenche `Tipo`, `Area`, `Priority`, `Effort` e `Status`. Os ids do
board são resolvidos em runtime (sem hardcode).

## Uso

```bash
python3 .agents/skills/issue/scripts/new_issue.py \
  --title "Caixa de andabilidade maior que o tile" \
  --tipo Bug --area Player --priority "P2 - Medium" --effort "P (horas)" \
  --body-file /tmp/bug.md
```

Valores válidos (idênticos a `docs/github-projects.md`):

- `--tipo`: Feature · Bug · Tech Debt · Art · Design · Docs · Tooling
- `--area`: World/Terrain · Player · Farming · Machines · Fishing ·
  Inventory/Shop · UI/HUD · Save/Load · Audio · Weather/Time · NPCs ·
  Tests/CI · Tooling
- `--priority`: P0 - Critical · P1 - High · P2 - Medium · P3 - Low
- `--effort`: P (horas) · M (dias) · G (semana+)
- `--status` (padrão `Backlog`): Backlog · Ready · In Progress · In Review · Done

Para espelhar um plano, use `--plan-file plans/NNN-*.md` (gera o corpo com o
link) e `--title "[Plano NNN] ..."`.

Sempre rode `--dry-run` primeiro para conferir labels e campos.

## Regras

- Se o defeito for bug, o corpo deve ter **Sintoma / Reprodução / Causa /
  Verificação** (template 🐛 Bug).
- Plano vai para `plans/NNN-*.md` **antes** da issue; a issue só linka o plano.
- Nunca crie a issue sem `--tipo`: é o campo que define a label `type:*`.
- Se a label derivada não existir, o script falha e sugere criá-la com
  `gh label add`; a label nova também precisa entrar em `docs/github-projects.md`.
