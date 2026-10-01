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

### Tabela completa de labels convencionais

Toda label com prefixo `type:`, `area:`, `priority:` ou `effort:` deve estar
catalogada aqui — o checkup valida essa correspondência.

| Label | Descrição |
|---|---|
| `type:feature` | Nova funcionalidade / melhoria de jogo |
| `type:bug` | Defeito ou regressão |
| `type:tech-debt` | Refatoração, arquitetura, qualidade interna |
| `type:art` | Arte, sprites, tiles, animações |
| `type:design` | Design de jogo, balanceamento, UX |
| `type:docs` | Documentação |
| `type:tooling` | Scripts, CI, ferramentas de dev |
| `area:world` | Mundo, terreno, dual grid, colisão |
| `area:player` | Player, movimento, ferramentas |
| `area:farming` | Plantações, crescimento, colheita |
| `area:machines` | Aspersor, espantalho, pescador |
| `area:fishing` | Minigame de pesca |
| `area:inventory-shop` | Inventário, hotbar, loja, moedas |
| `area:audio` | SFX, música, chuva |
| `area:save-load` | Persistência e save/load |
| `area:ui` | HUD, menus, pausa, debug |
| `area:npcs` | Criaturas e NPCs |
| `area:tests` | Testes automatizados e smoke test |
| `area:weather` | Clima, dia/noite, relógio |
| `area:tooling` | Scripts, CI, ferramentas de dev |
| `priority:p0` | Urgente / bloqueia jogo (campo `P0 - Critical`) |
| `priority:p1` | Alta prioridade (campo `P1 - High`) |
| `priority:p2` | Média prioridade (campo `P2 - Medium`) |
| `priority:p3` | Baixa prioridade (campo `P3 - Low`) |
| `effort:P` | Esforço P (horas) |
| `effort:M` | Esforço M (dias) |
| `effort:G` | Esforço G (semana+) |

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

- Um **bug** vai para o **GitHub Issues** (template 🐛 Bug: severidade,
  sintoma, reprodução, causa e verificação) e recebe `bug` + `type:bug`.
- Uma **funcionalidade futura** vira um plano em `plans/NNN-*.md` **e** uma
  issue `[Plano NNN] ...` que linka o arquivo. O plano é a fonte de detalhe.
- Ao concluir, a issue é fechada; o aprendizado relevante sobe para o
  `README.md` ou para o próprio plano (marcado como **Concluído**).
- **Rastreabilidade:** o PR referencia a issue com `Fixes #N` no corpo; o
  commit traz o sufixo `(#N)`. Ao abrir o PR, mova o item do board para
  **In Review**; o merge (ou o fechamento da issue) leva a **Done** pelo
  workflow embutido.

## Automações

Os *workflows* embutidos são configurados uma vez em
**Project → ⋯ → Settings → Workflows**. A API **lê** o estado via GraphQL
(`ProjectV2.workflows`) e **deleta** (`deleteProjectV2Workflow`), mas
**não ativa/configura** — isso é só no UI. Estado atual:

| Workflow | Estado | Efeito |
|---|---|---|
| Item closed | ✅ ativo | fecha a issue → `Status = Done` |
| Auto-add to project | ✅ ativo | novas issues do repositório entram no board |
| Auto-add sub-issues to project | ✅ ativo | sub-issues herdam o board |
| Pull request merged | ✅ ativo | PR mesclado → `Status = Done` |
| Auto-close issue | ⬜ inativo | — |
| Item added to project | ⬜ inativo | — |
| Pull request linked to issue | ✅ ativo | PR vinculado à issue (`Fixes #N`) → `Status = In Review` |

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

> Atalho: a skill `issue` (`.agents/skills/issue/`) cria a issue já com
> labels convencionais e campos do board resolvidos em runtime
> (`python3 .agents/skills/issue/scripts/new_issue.py --help`).

## Criação de issues

Use a skill `issue` no pi (`/skill:issue`) ou o script direto. Exemplo:

```bash
python3 .agents/skills/issue/scripts/new_issue.py \
  --title "Caixa de andabilidade maior que o tile" \
  --tipo Bug --area Player --priority "P2 - Medium" --effort "P (horas)" \
  --body-file /tmp/bug.md
```

O script cria a issue, adiciona ao board e preenche `Tipo`, `Area`,
`Priority`, `Effort` e `Status` — sem ids hardcoded (consulta
`gh project field-list`). `--dry-run` mostra o que seria feito.
