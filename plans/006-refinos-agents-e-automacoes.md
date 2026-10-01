# 006 — Refinos do AGENTS.md e automações de gestão

- **Status:** Concluído
- **Prioridade:** Média
- **Esforço:** M (dias)
- **Depende de:** [005](005-checkup-de-consistencia.md) (skill de checkup)
- **Arquivos-alvo:** `AGENTS.md`, `docs/github-projects.md`, `docs/checkup.md`,
  `.github/workflows/ci.yml`, `.agents/skills/checkup/`, `.agents/skills/issue/`,
  `README.md`, `plans/README.md`

## Objetivo
Fechar o ciclo de gestão: o checkup **detecta** inconsistências e novas skills
**executam** o padrão (criar issue + campos do board + labels), com cadência
definida e verificação automática no CI.

## Motivação / Contexto
O plano 005 criou a detecção (checkup). Ainda faltam: regra explícita de
rastreabilidade issue ↔ PR ↔ commit, checkup opcional no CI, remoção de
snapshots que envelhecem, cadência de uso e uma forma ergonômica de abrir
issues já com labels e campos do board preenchidos.

## Comportamento esperado
1. `docs/github-projects.md` sem a seção "Estado atual do board" (o board é a
   fonte da verdade; snapshot apodrece).
2. `AGENTS.md` define a cadência do checkup e a regra issue ↔ PR ↔ commit.
3. CI ganha job `checkup` (checagens locais + Issues/labels via `gh`).
4. Skill `issue` cria issue com labels e campos do board a partir de flags.
5. Checkup passa a verificar se PRs abertos referenciam uma issue.

## Design técnico
- **Cadência (recomendada):** checkup completo (com smoke) **antes de abrir
  PR**; checkup `--no-smoke` **ao fim de sessão de gestão** (que mexeu em
  issues/board/planos). Não rodar a cada edição de código.
- **Rastreabilidade:** PR body com `Fixes #N`; commit com sufixo `(#N)`;
  abrir PR → item do board vai para `In Review`; merge/close → `Done`.
- **Skill `issue`:** `new_issue.py` resolve ids de campo/opção em runtime via
  `gh project field-list` (sem hardcode), cria a issue, adiciona ao board e
  preenche `Tipo`/`Area`/`Priority`/`Effort`/`Status`. Deriva labels
  convencionais (`type:*`, `area:*`, `priority:*`, `effort:*`) dos campos.
  Tem `--dry-run` para inspecionar sem criar.
- **CI:** novo job roda `checkup.py --no-board --no-smoke` com `GH_TOKEN`;
  as checagens de board dependem de escopo de Projects que o token do CI não tem.
- **Checkup:** nova opção `--no-board`; nova verificação `prs-↔-issues`.

## Escopo
- **Incluído:** os 5 itens acima + docs no mesmo commit.
- **Fora do escopo:** automação server-side (GitHub Actions) para mover o board
  em PR aberto. Decisão: o workflow embutido **Pull request linked to issue**
  foi ativado (PR com `Fixes #N` → `Status = In Review`), coberto pela
  verificação `board-workflows` do checkup.

## Tarefas
- [x] Remover "Estado atual do board" de `docs/github-projects.md`
- [x] `AGENTS.md`: cadência do checkup + regra issue ↔ PR ↔ commit
- [x] Checkup: flag `--no-board` + verificação de PRs
- [x] CI: workflow `checkup.yml`
- [x] Skill `issue` (`SKILL.md` + `new_issue.py` com `--dry-run`)
- [x] `docs/checkup.md` e `README.md` atualizados
- [x] Plano espelhado na issue e no board

## Critérios de aceite
- [x] Smoke test e checkup terminam sem FAIL
- [x] `new_issue.py --dry-run` mostra o plano de criação sem efeitos colaterais
- [x] Job `checkup` no CI roda em push/PR na `main`
- [x] Nenhuma referência ativa à seção removida

## Riscos / Notas
- Resolver ids em runtime exige `gh` autenticado com escopo de Projects;
  `--no-board` cobre ambientes sem esse escopo.
- A skill `issue` duplica um pouco da lógica do checkup; ambos devem consultar
  a doc como fonte de nomes canônicos.
