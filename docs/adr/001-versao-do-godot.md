# ADR 001 — Versão canônica do Godot

- **Status:** Aceita
- **Data:** 2026-10-01
- **Contexto:** [`project.godot`](../../project.godot), [`.github/workflows/ci.yml`](../../.github/workflows/ci.yml), [`README.md`](../../README.md)

## Contexto

O repositório não fixava uma versão de referência, e três fontes divergiam:

- `project.godot` traz `config/features = ("4.6")` — tag de compatibilidade
  gravada pela engine.
- `README.md` dizia "Godot 4.6+", mas os comandos de exemplo usavam o binário
  4.7.2 do ambiente local.
- O CI usava `vars.GODOT_VERSION || '4.7.2'`, mas a variável **não existia** —
  logo rodava 4.7.2 por acidente do fallback.

O desenvolvimento do jogo acontece no **Godot 4.6**; a intenção é migrar para
4.7 (ou superior) **somente quando a série estiver estável**.

## Decisão

- A versão canônica de desenvolvimento e CI é **Godot 4.6.3** (último patch da
  série 4.6).
- O CI resolve a versão por `vars.GODOT_VERSION`, definida como `4.6.3` no
  repositório. O literal do `ci.yml` permanece apenas como fallback.
- `config/features = ("4.6")` é mantido — e agora coincide com a versão em uso.
- O `README.md` declara "Godot **4.6.3**" nos comandos de rodar/testar.
- **Upgrade para 4.7+ é planejado, não imediato:** só quando a série 4.7 estiver
  estável, atualizando `GODOT_VERSION` e o README no mesmo PR (idealmente via
  plano/issue).

## Consequências

- **Positivas:** CI, máquina local e `config/features` coerentes; upgrade vira
  uma mudança explícita e rastreável.
- **Negativas / custos:** correções de engine mais recentes (4.7.x) não são
  aproveitadas até a migração.
- **Em aberto:** critérios objetivos para considerar a 4.7 "estável" (ex.:
  N meses sem patch crítico) — decidir na hora da migração.

## Alternativas descartadas

- **Fixar 4.7.2** — antecipa a migração que o projeto decidiu postergar até a
  série estar estável.
- **Seguir "4.x mais recente" sem pin** — builds não reproduzíveis e quebras
  silenciosas no CI.
