---
name: pr
description: Publica a branch atual e abre o pull request no godot-simulator-game com "Fixes #N" no corpo. Use ao terminar uma issue, quando o usuário pedir "abra o PR", "manda o PR" ou antes de encerrar o Fluxo A (ver docs/workflow.md).
---

# Abrir o pull request

`/skill:pr` faz o fim do Fluxo A: publica a branch atual (`git push -u`) e abre
o PR contra a `main` com `Fixes #N` no corpo — o que dispara a automação
**PR vinculado → `In Review`** no board.

## Uso

```bash
python3 .agents/skills/pr/scripts/open_pr.py                 # infere a issue da branch
python3 .agents/skills/pr/scripts/open_pr.py --issue 4
python3 .agents/skills/pr/scripts/open_pr.py --draft --dry-run
```

O número da issue é inferido do nome da branch (`<tipo>/<N>-slug`). O título
padrão é o assunto do último commit.

## Regras

- **Nunca** abra PR a partir de `main`/`master`.
- O corpo **precisa** conter `Fixes #N` para o board ir a `In Review` e a issue
  fechar no merge.
- Rode `--dry-run` para conferir título/corpo antes de publicar.
- Depois do merge: o board vai a `Done` (automático) e a branch pode ser apagada.
