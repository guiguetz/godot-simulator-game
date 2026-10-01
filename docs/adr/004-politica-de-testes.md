# ADR 004 — Política de testes

- **Status:** Aceita
- **Data:** 2026-10-01
- **Contexto:** [`plans/003-estrutura-de-testes-gdunit.md`](../../plans/003-estrutura-de-testes-gdunit.md), [`tools/smoke_test.gd`](../../tools/smoke_test.gd), [`.github/workflows/ci.yml`](../../.github/workflows/ci.yml)

## Contexto

O CI roda o **smoke test headless** (`tools/smoke_test.gd`) e um step de
**gdUnit4** condicional (`if: hashFiles('tests/**/*.gd') != ''`). Como
`tests/` ainda **não existe**, o step nunca executa. O plano 003 descreve a
estrutura de testes desejada, mas a política (o que é obrigatório e quando)
não estava registrada.

## Decisão

- **Smoke test é obrigatório** e roda em todo push/PR para `main` (exceto
  mudanças apenas em `docs/**` e `**.md`, já ignoradas pelo CI).
- **gdUnit4 é o alvo** para testes de regressão e unidade; passa a obrigatório
  quando o plano 003 for concluído e existirem testes em `tests/`.
- Enquanto `tests/` estiver vazio, o step condicional do CI é esperado — não é
  bug do CI.
- Toda correção de bug registra a verificação (issue, seção *Verificação*);
  bugs com teste de regressão viram caso em `tests/regression/`.

## Consequências

- **Positivas:** regressões cobertas cedo; o CI já está pronto para receber os
  testes sem mudança de workflow.
- **Negativas / custos:** manter dois níveis de teste (smoke + gdUnit4) exige
  disciplina de onde cada caso vive.
- **Em aberto:** cobertura-alvo e se o smoke test é substituído/absorvido pelo
  gdUnit4.

## Alternativas descartadas

- **Tornar gdUnit4 obrigatório já** — falharia o CI enquanto não há testes.
- **Só smoke test, sem testes unitários** — não cobre regressões pontuais
  (ex.: colisão, crescimento de plantação).
