# Plans

Registro das **próximas funcionalidades a implementar** (roadmap). Um arquivo
`.md` por plano, no mesmo espírito de um registro de issues, porém voltado ao
que **ainda não existe** — o que queremos construir, por quê e como.

> Regra: um plano descreve **trabalho futuro**. Bugs corrigidos vão para
> GitHub Issues; decisões de arquitetura de longo prazo podem virar um `ADR` em
> [`docs/adr/`](../docs/adr/README.md) ou dentro
> do próprio plano quando necessário.

> Os planos são espelhados como issues no **GitHub Projects** do projeto
> (campos, labels e fluxo em [`docs/github-projects.md`](../docs/github-projects.md)).

## Índice

| ID | Título | Status | Prioridade | Esforço |
|---|---|---|---|---|
| [001](001-propriedade-tillable.md) | Propriedade `tillable` no terreno | Concluído | Média | P |
| [002](002-menus-de-debug.md) | Menus de debug / controles internos | Proposto | Média | M |
| [003](003-estrutura-de-testes-gdunit.md) | Estrutura de testes com gdUnit4 | Concluído | Alta | M |
| [004](004-dividir-readme-em-docs.md) | Dividir README em docs/ por sistema | Em andamento | Baixa | P |
| [005](005-checkup-de-consistencia.md) | Checkup de consistência (skill + automação) | Concluído | Média | P |
| [006](006-refinos-agents-e-automacoes.md) | Refinos do AGENTS.md e automações de gestão | Concluído | Média | M |
| [007](007-guarda-corpo-fase-2.md) | Guarda-corpo fase 2: pre-commit, ADR e board no CI | Concluído | Média | M |
| [008](008-fluxos-e-skills-de-trabalho.md) | Fluxos de trabalho, skills start/pr e branching | Concluído | Média | M |

## Estrutura de um plano

Todo plano deve seguir o template abaixo (copie, mantendo a ordem):

```markdown
# NNN — Título curto

- **Status:** Proposto | Em design | Em andamento | Concluído | Descartado
- **Prioridade:** Alta | Média | Baixa
- **Esforço:** P (horas) | M (dias) | G (semana+)
- **Depende de:** links para outros planos/issues (ou "—")
- **Arquivos-alvo:** caminhos que devem ser tocados

## Objetivo
Uma frase: o resultado observável para o jogador/dev.

## Motivação / Contexto
Problema atual, por que vale a pena agora, o que existe hoje.

## Comportamento esperado
Descrição do resultado do ponto de vista do jogador/dev, incluindo casos de borda.

## Design técnico
Como implementar: APIs, sinais, dados, autoloads, formato de save, etc.

## Escopo
- **Incluído:** ...
- **Fora do escopo:** ...

## Tarefas
- [ ] item verificável
- [ ] ...

## Critérios de aceite
- [ ] condição objetiva e testável

## Riscos / Notas
- risco + mitigação
```

### Convenções

- **Status** segue o fluxo `Proposto → Em design → Em andamento → Concluído`.
  Ao concluir, mova o aprendizado relevante para `README.md`, GitHub Issues ou
  código, e marque o plano como **Concluído** (não apague o histórico).
- **Esforço** é uma estimativa grosseira de calendário, não de linhas de código.
- **Tarefas** podem ser marcadas progressivamente durante a implementação.
- Planos podem referenciar issues e vice-versa (use URLs do GitHub Issues,
  ex. `https://github.com/guiguetz/godot-simulator-game/issues/NNN`).
- Qualquer decisão não óbvia deve ir em **Design técnico** ou **Riscos / Notas**.
