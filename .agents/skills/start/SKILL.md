---
name: start
description: Assume uma issue aberta no godot-simulator-game — move o item do board para In Progress, cria a branch padronizada <tipo>/<n>-slug e mostra o contexto (plano linkado). Use quando o usuário disser "vamos atacar a #N", "pegar a issue N" ou iniciar trabalho numa issue existente.
---

# Assumir uma issue

`/skill:start <N>` faz o começo do Fluxo A (ver `docs/workflow.md`):
valida que a issue está aberta, move o item do board para **In Progress**, cria
e faz checkout da branch `<tipo>/<N>-slug` e imprime o contexto.

## Uso

```bash
python3 .agents/skills/start/scripts/start.py 4
python3 .agents/skills/start/scripts/start.py 4 --dry-run   # só mostra o plano
```

O prefixo da branch sai das labels: `type:bug`→`fix`, `type:feature`→`feat`,
`type:tech-debt`→`refactor`, `type:docs`→`docs`, `type:tooling`→`chore`,
`type:art`→`art`, `type:design`→`design`.

## Regras

- Rode `--dry-run` primeiro se quiser conferir branch/board antes.
- Exige árvore de trabalho limpa o suficiente para trocar de branch; o script
  **não commita nada**.
- Se a issue não estiver no board, avisa (não inventa item).
- Depois de assumir: implemente, rode o checkup (`--no-smoke`) e o smoke test,
  e abra o PR com `/skill:pr`.
