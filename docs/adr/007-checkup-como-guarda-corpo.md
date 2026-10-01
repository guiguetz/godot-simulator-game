# ADR 007 — Checkup de consistência como guarda-corpo

- **Status:** Aceita
- **Data:** 2026-10-01
- **Contexto:** [`plans/005`](../../plans/005-checkup-de-consistencia.md), [`plans/006`](../../plans/006-refinos-agents-e-automacoes.md), [`docs/checkup.md`](../checkup.md), [`.agents/skills/checkup/`](../../.agents/skills/checkup/), [`.github/workflows/checkup.yml`](../../.github/workflows/checkup.yml)

## Contexto

As invariantes de workflow do [`AGENTS.md`](../../AGENTS.md) eram cumpridas "de
memória", sem verificação objetiva. Isso já produziu inconsistências reais:

- issue no board com `Priority`/`Tipo`/`Area`/`Effort` vazios;
- label `area:tooling` documentada e usada no board, mas inexistente no repo;
- `docs/checkup.md` fora do índice de `docs/README.md`;
- a tabela de automações do board dizia "a API não os expõe" (a API lê e
  deleta workflows, só não ativa) e não refletia o estado real dos workflows.

Disciplina manual não pegou nenhum desses casos; um script pegou todos.

## Decisão

- O **checkup** (`.agents/skills/checkup/`) é a verificação oficial de
  consistência do repositório; a lista de verificações vive em
  [`docs/checkup.md`](../checkup.md).
- Roda **no CI** a cada push/PR para `main` via
  [`.github/workflows/checkup.yml`](../../.github/workflows/checkup.yml),
  **sem** o filtro de `docs/**` (ao contrário do `ci.yml`), porque valida
  justamente docs, planos e índices. No CI usa `--no-board` (o token do CI não
  tem escopo de Projects) e `--no-smoke`.
- **Localmente**, a cadência é: checkup completo (com smoke) **antes de abrir
  PR**; `--no-smoke` **ao fim de sessão de gestão**; não a cada edição de
  código.
- **FAIL é corrigido na fonte.** É proibido afrouxar o checkup para mascarar
  uma inconsistência; se a regra mudou, muda-se primeiro o `AGENTS.md` e depois
  o checkup, no mesmo commit.
- **Docs são fonte de verdade verificável:** tabelas e índices (labels, campos
  e workflows do board, índice de `docs/`, de `plans/` e de ADRs) são
  comparados com a realidade pelo checkup, em vez de virarem snapshots que
  envelhecem.

## Consequências

- **Positivas:** inconsistências de gestão são detectadas cedo e de forma
  reproduzível; a doc deixa de ser decorativa e passa a ser contrato; o CI
  impede regressão do próprio processo.
- **Negativas / custos:** cada nova tabela/índice exige um parser correspondente
  no checkup; o smoke test deixa o checkup completo lento (por isso
  `--no-smoke` em sessões de gestão).
- **Em aberto:** verificação que precise de escopo de Projects no CI (hoje
  `--no-board`); validar as **views** do board; rodar o checkup em pre-commit
  hook; cobertura de ADRs individuais (hoje só o índice).

## Alternativas descartadas

- **Só disciplina manual / revisão humana** — foi o que falhou: nada disso era
  detectado antes do script.
- **Apenas Git hooks locais** — não cobrem o estado do GitHub (issues, board,
  labels) nem rodam para quem não instalou o hook.
- **Relaxar o checkup para nunca falhar / "consertar o script"** — mascararia
  exatamente os problemas que ele existe para expor.
