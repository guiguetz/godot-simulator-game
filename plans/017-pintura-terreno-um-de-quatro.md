# 017 — Pintura de terreno em grupos 2×2

- **Status:** Em design
- **Prioridade:** Média
- **Esforço:** M (dias)
- **Depende de:** [#40](https://github.com/guiguetz/godot-simulator-game/issues/40)
- **Arquivos-alvo:** `scripts/world.gd`, `scenes/game.tscn`, `assets/tiles/terrain_*.tres`, `tests/world/`, `docs/world.md`

## Objetivo

Permitir pintar apenas uma célula de cada grupo 2×2, em vez de preencher as quatro, para formar curvas de terreno visualmente maiores.

## Motivação / Contexto

O TileMapDual passou a renderizar corretamente os quadrantes, mas a densidade resultante ainda parece pequena: blocos 2×2 ficam preenchidos e as bordas fazem curvas curtas. O comportamento desejado é mais espaçado, com apenas uma das quatro unidades do grupo recebendo o terreno.

## Comportamento esperado

- Cada grupo 2×2 de células lógicas pode conter no máximo uma célula pintada.
- A célula escolhida mantém a posição efetivamente pintada; as outras três não recebem cópias do material.
- Ao pintar outra célula do mesmo grupo, a recém-selecionada substitui a anterior; as outras três células ficam vazias.
- O resultado vale para água, terra e canteiro; terreno sem célula pintada continua sendo grama.
- A andabilidade, ferramentas, pesca e persistência devem consultar o mesmo resultado exibido.
- Grupos na borda do mapa e carregamento de saves antigos não podem perder terreno silenciosamente.

## Design técnico

- Definir a unidade do grupo 2×2 nas camadas lógicas `TerrainWater`, `TerrainDirt` e `TerrainSoil` (cada unidade mede 16×16).
- Sincronizar editor e runtime pelo mesmo caminho, sem replicar uma pintura às três células vizinhas.
- `set_terrain()` deve limpar as quatro células do grupo em todas as camadas e então pintar a célula selecionada. No editor, identificar a camada/célula recém-pintada e aplicar a mesma regra sem espelhar uma fonte lógica obsoleta.
- Definir normalização determinística para saves/mapas antigos que já tenham várias células pintadas no mesmo grupo, evitando escolher um vencedor por ordem não determinística do dicionário.
- Preservar `TileMapDual` para gerar as transições; alterar a densidade da amostragem lógica, não remover as regras de autotiling.
- Criar testes para grupo vazio, uma célula, conflito no grupo, bordas e round-trip de save/load.

## Escopo

- **Incluído:** pintura esparsa em grupos 2×2 nos três materiais; consistência entre editor, runtime, gameplay e save/load; documentação e regressões.
- **Fora do escopo:** alterar as texturas de terreno, aumentar o tamanho da janela ou trocar o addon TileMapDual.

## Tarefas

- [x] Definir política para nova pintura: a célula recém-selecionada substitui as demais do grupo.
- [ ] Definir migração determinística para grupos conflitantes em mapas/saves antigos.
- [ ] Implementar a política na camada lógica e sincronização de display.
- [ ] Preservar comportamento de ferramentas e save/load.
- [ ] Cobrir autotiling e células na borda com testes.
- [ ] Atualizar `docs/world.md` e README.
- [ ] Rodar gdUnit4, smoke test e checkup.

## Critérios de aceite

- [ ] Cada grupo 2×2 exibe no máximo uma célula pintada.
- [ ] Pintar em qualquer uma das quatro posições segue a política definida, sem preencher automaticamente as outras três.
- [ ] Editor e runtime mostram o mesmo resultado para água, terra e canteiro.
- [ ] Save/load e propriedades de terreno continuam coerentes.
- [ ] Smoke test, gdUnit4 e checkup passam.

## Riscos / Notas

- Uma célula por grupo reduz a densidade lógica do terreno e pode alterar andabilidade, colisões de água, aração, pesca e compatibilidade com saves existentes. Manter essas regras explícitas e testar uma migração determinística antes de concluir.
