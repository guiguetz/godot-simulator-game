# Documentação

Índice da documentação detalhada do jogo. A porta de entrada do projeto é o
[`README.md`](../README.md) na raiz; aqui fica o detalhe por tema.

O **wiki** do repositório é gerado automaticamente a partir desta pasta
([ADR 003](adr/003-onde-vive-a-documentacao.md)) — edite sempre em `docs/`,
nunca no wiki.

## Conteúdo

| Documento | Assunto |
|---|---|
| [`world.md`](world.md) | Terreno, `walkable`/`tillable` e aração |
| [`player.md`](player.md) | Movimento, colisão de pés e skins |
| [`farming.md`](farming.md) | Aração, plantio, crescimento e colheita |
| [`machines.md`](machines.md) | Aspersor, espantalho e pescador |
| [`fishing.md`](fishing.md) | Minigame de pesca e peixes |
| [`inventory-shop.md`](inventory-shop.md) | Inventário, hotbar, HUD e loja |
| [`time-weather.md`](time-weather.md) | Relógio, dia/noite e clima |
| [`save-load.md`](save-load.md) | Save/load do mundo e preferências |
| [`audio.md`](audio.md) | SFX, música e chuva |
| [`npcs.md`](npcs.md) | Criaturas e NPCs ambientais |
| [`decor.md`](decor.md) | Modo decoração, casa e cenário |
| [`github-projects.md`](github-projects.md) | Board, campos, labels, views e fluxo de trabalho |
| [`workflow.md`](workflow.md) | Fluxos do dia a dia: assumir issue, criar novo, automações |
| [`checkup.md`](checkup.md) | Checkup de consistência (planos, issues, board, labels) |
| [`sync-wiki.md`](sync-wiki.md) | Como o wiki é gerado a partir de `docs/` |
| [`adr/`](adr/README.md) | Decisões de arquitetura (ADRs) |

## Onde fica cada coisa

- **`README.md`** (raiz) — visão geral, controles, sistemas em uma linha, mapa
  de scripts, como rodar/testar.
- **`docs/<topico>.md`** — detalhe de um tema (save/load, pesca, terreno, …).
- **`docs/adr/`** — decisões tomadas, com contexto e alternativas descartadas.
- **`plans/NNN-*.md`** — trabalho futuro (roadmap), espelhado em issues no
  GitHub Projects.

> Regras de contribuição (bug → issue, funcionalidade → plano, implementação →
> doc) estão no [`AGENTS.md`](../AGENTS.md) da raiz.
