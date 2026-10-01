---
name: checkup
description: Checkup de consistência do repositório godot-simulator-game. Use quando o usuário pedir "checkup", "verificar consistência", "organizar a casa", ou antes de fechar sessões de trabalho — valida planos, issues, board do GitHub Projects, labels, templates e o smoke test.
---

# Checkup de consistência

Verifica se as regras de `AGENTS.md` estão de fato sendo cumpridas: issues
abertas, board atualizado, planos espelhados, labels documentadas.

## Como rodar

Na raiz do repositório, execute:

```bash
python3 .agents/skills/checkup/scripts/checkup.py
```

Opções: `--offline` (sem rede/GitHub), `--no-smoke` (pula o smoke test do Godot,
que é lento).

## Como interpretar

- **OK** — consistente; nada a fazer.
- **WARN** — provável inconsistência; investigue com o agente.
- **FAIL** — violação de uma regra do `AGENTS.md`; corrija.
- **SKIP** — verificação não executada (ex.: `gh` sem auth, `--offline`).

## Como agir sobre os resultados

1. Corrija os FAILs **na fonte** (não "conserte o checkup para passar"):
   - plano sem issue espelho → crie a issue com `--template plano.yml`;
   - issue fora do board ou com campo vazio → `gh project item-edit`
     (ids em `docs/github-projects.md`);
   - label não documentada → atualize `docs/github-projects.md` (crie a label
     com `gh label add` se necessário);
   - plano sem seção do template → complete o arquivo seguindo `plans/README.md`.
2. Re rode o script até zerar os FAILs.
3. Reporte um resumo em português: o que passou, o que corrigiu, o que ficou
   WARN/SKIP e por quê.

Não altere o script para mascarar um FAIL — se a regra do AGENTS.md mudou,
mude primeiro o AGENTS.md e depois o checkup, no mesmo commit.
