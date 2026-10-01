# GitHub Projects — gestão do jogo

O desenvolvimento do jogo é gerenciado no GitHub Projects v2:

> **Board:** <https://github.com/users/guiguetz/projects/1>
> **Repositório:** <https://github.com/guiguetz/godot-simulator-game>

O board é a visão única de **bugs**, **features** e **roadmap**. Issues de bug
e melhorias vivem no GitHub Issues; os planos detalhados continuam em
[`plans/`](../plans/README.md) e cada plano tem uma issue correspondente.

## Campos customizados

| Campo | Valores | Para que serve |
|---|---|---|
| **Status** | Backlog · Ready · In Progress · In Review · Done | Fluxo de trabalho |
| **Priority** | `P0 - Critical` · `P1 - High` · `P2 - Medium` · `P3 - Low` | Ordenação do backlog |
| **Tipo** | Feature · Bug · Tech Debt · Art · Design · Docs · Tooling | Natureza do trabalho |
| **Area** | World/Terrain · Player · Farming · Machines · Fishing · Inventory/Shop · UI/HUD · Save/Load · Audio · Weather/Time · NPCs · Tests/CI · Tooling | Sistema afetado |
| **Effort** | `P (horas)` · `M (dias)` · `G (semana+)` | Estimativa de calendário |

> `Type` e `Status` são nomes reservados pelo GitHub Projects; por isso o campo
> de natureza do trabalho chama-se **Tipo**.

## Labels do repositório

As labels espelham os campos do board para permitir filtros rápidos no Issues
e nas buscas. Convenções: `type:`, `area:`, `priority:`, `effort:`.

Exemplos:

```
type:bug        area:world      priority:p1     effort:P
type:feature    area:player     priority:p2     effort:M
type:tech-debt  area:tests      priority:p3     effort:G
```

Labels genéricas herdadas do GitHub (`bug`, `enhancement`, `good first issue`)
continuam válidas e podem ser combinadas.

## Views

| View | Layout | Filtro |
|---|---|---|
| 📋 Tabela (Tudo) | Tabela | — |
| 🗂️ Board por Status | Board (agrupa por Status) | — |
| 🐛 Bugs | Tabela | `label:bug` |
| 🔥 Alta prioridade | Tabela | `-status:Done priority:"P0 - Critical","P1 - High"` |

A criação/edição de views usa a API GraphQL
(`createProjectV2View` / `updateProjectV2View`), pois o `gh project` ainda não
cobre views pela CLI.

## Fluxo de trabalho

```
Backlog → Ready → In Progress → In Review → Done
```

- **Backlog** — ideias, bugs sem triagem, planos propostos.
- **Ready** — priorizado e sem bloqueios; pronto para alguém pegar.
- **In Progress** — em desenvolvimento (ideal: uma issue por vez por pessoa).
- **In Review** — aguardando review/teste (ex.: smoke test + gdUnit4).
- **Done** — concluído; a issue é fechada.

Regras do projeto:

- Um **bug** vai para `issues/` do GitHub (corpo com Sintoma, Causa,
  Reprodução e Verificação) e recebe `type:bug`.
- Uma **funcionalidade futura** vira um plano em `plans/NNN-*.md` **e** uma
  issue `[Plano NNN] ...` que linka o arquivo. O plano é a fonte de detalhe.
- Ao concluir, a issue é fechada; o aprendizado relevante sobe para o
  `README.md` ou para o próprio plano (marcado como **Concluído**).

## Automações (ativar na UI)

A API não expõe os *workflows* embutidos. Ative uma vez em
**Project → ⋯ → Settings → Workflows**:

1. **Item closed** → definir `Status = Done`.
2. **Auto-add to project** → filtro `label:bug,enhancement` no repositório,
   para novas issues entrarem no board automaticamente.
3. **Pull request merged** → `Status = Done` (quando houver PRs).

## Adicionar/editar itens pela CLI

```bash
REPO=guiguetz/godot-simulator-game

# 1. adiciona uma issue ao project (retorna o item id)
gh project item-add 1 --owner guiguetz \
  --url "https://github.com/$REPO/issues/123" --format json

# 2. preenche um campo (obtenha os ids com field-list)
gh project field-list 1 --owner guiguetz --format json
gh project item-edit --id <ITEM_ID> \
  --project-id PVT_kwHOAGAypc4BlSGq \
  --field-id <FIELD_ID> --single-select-option-id <OPTION_ID>
```

## Estado atual do board

Bugs #1/#2/#3 foram corrigidos e fechados (z-order do mundo) → `Done`.
O bug #4 (caixa de andabilidade) segue em `Backlog`.
Os planos 001–003 estão como issues #5–#7:
[#5](../../issues/5) `Backlog`, [#6](../../issues/6) `Backlog`,
[#7](../../issues/7) `Ready`.
