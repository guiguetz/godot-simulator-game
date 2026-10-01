# Issues

Registro dos problemas encontrados, com sintoma, causa raiz, correção e
verificação. Um arquivo `.md` por issue.

| ID | Título | Status | Severidade |
|---|---|---|---|
| [001](001-chao-acima-de-tudo.md) | Chão renderizado por cima de tudo | Corrigido | Alta |
| [002](002-player-invisivel.md) | Player não aparece | Corrigido | Alta |
| [003](003-movimento-so-vertical.md) | Movimento percebido apenas na vertical | Corrigido | Média |
| [004](004-caixa-andabilidade-maior-que-tile.md) | Caixa de andabilidade maior que o tile | Aberto (melhoria) | Baixa/Média |

> As issues 001 e 002 e 003 têm a **mesma causa raiz**: ordem de desenho
> (z-order) do chão/terreno vs. as entidades. Foram separadas por serem
> sintomas distintos para o jogador.
