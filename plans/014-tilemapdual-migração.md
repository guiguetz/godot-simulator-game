# 014 — Reimplementação do terreno com TileMapDual

- **Status:** Em andamento
- **Prioridade:** Alta
- **Esforço:** M (dias)
- **Depende de:** —
- **Arquivos-alvo:** `scenes/game.tscn`, `scripts/world.gd`, `assets/tiles/`, `tests/world/`, `docs/world.md`, `README.md`

## Objetivo

Reimplementar do zero a integração do dual grid no jogo a partir do contrato e dos exemplos oficiais do TileMapDual v5, mantendo os comportamentos de terreno já usados pelos sistemas do jogo.

## Motivação / Contexto

A integração existente mistura regras de terreno, pintura, tilesets e atualização visual, e não segue de forma confiável o fluxo documentado pelo addon. Esta implementação será feita em um worktree limpo a partir do `main`, sem reaproveitar as alterações locais em andamento nem a arquitetura anterior como requisito.

Referências primárias:

- [TileMapDual — README e documentação](https://github.com/pablogila/TileMapDual)
- [Exemplos oficiais](https://github.com/pablogila/TileMapDual/tree/main/examples), especialmente `MultipleLayers.tscn`, `MultipleAtlases.tscn` e `AllShapes.tscn`.
- [Assets oficiais](https://github.com/pablogila/TileMapDual/tree/main/assets), como referência de layout dos tilesets, tiles lógicos e tiles de exibição; usar somente os recursos necessários e preservar a licença MIT/atribuição.

A implementação copia e usa o asset oficial `assets/tileset_sand.png` como atlas de terra, conforme solicitado. Como seus tiles medem 32×32 e o grid do jogo mede 16×16, o TileMapDual de terra é escalado em 0,5. Água e canteiro mantêm as texturas próprias; a licença MIT e a atribuição do arquivo copiado ficam em `assets/tiles/TILEMAPDUAL-ASSETS-LICENSE.txt`.

## Comportamento esperado

- Terreno quadrado de 16×16 com transições de dual grid corretas em runtime e no editor.
- Água, terra e canteiro permanecem terrenos distintos, sem mistura acidental entre tipos.
- Pintura e remoção de células atualizam as bordas vizinhas em todas as camadas afetadas.
- A consulta de terreno, andabilidade, aração, save/load e sistemas dependentes continuam usando uma única API de mundo, sem depender da representação visual do atlas.
- Cada camada TileMapDual mantém as células lógicas e usa o atlas 4×4 do próprio material para gerar suas camadas de exibição; os dados `walkable`/`tillable` vivem no tile lógico preenchido.

## Design técnico

- Recomeçar a integração em branch/worktree limpo e primeiro validar a API real do addon v5 presente no projeto contra `MultipleLayers.tscn`, `MultipleAtlases.tscn` e `AllShapes.tscn` do upstream.
- Usar um `TileMapDual` por tipo de terreno, seguindo `MultipleLayers.tscn`. Cada node é o mapa lógico pintável; o addon deriva os tiles de exibição do TileSet e dos vizinhos, sem sincronizar com outro mapa.
- Definir uma única fonte de verdade serializável para o terreno. `world.gd` traduz a API de alto nível (`terrain_at`, `set_terrain`, andabilidade/aração) para os mapas lógicos e reconstrói a apresentação após carregar save.
- Configurar os TileSets com o terreno vazio/preenchido e peering bits segundo os exemplos oficiais. A areia usa sua tabela explícita de 16 masks (vazio `(0,3)`, cheio `(2,1)`), tile size 32 e escala 0,5; normalizar células da cena gravadas com o atlas anterior via `draw_cell()`.
- Armazenar `walkable` e `tillable` como custom data no tile lógico cheio do TileSet de cada material. Os dados são lidos da célula do `TileMapDual`, nunca da camada de exibição interna.
- Manter a ordenação visual compatível com chão, entidades, player e água; validar as bordas do mapa e células apagadas.
- Não remover código/recursos até mapear consumidores, formatos de save e testes existentes; a implementação final, porém, não deve preservar caminhos antigos apenas por inércia.

## Escopo

- **Incluído:** refazer configuração de TileMapDual e TileSets; integrar o atlas oficial `tileset_sand.png` para terra com escala compatível; reestruturar nós e sincronização do terreno; preservar gameplay/save; adaptar testes; atualizar docs e atribuição/licença.
- **Fora do escopo:** trocar a direção artística do jogo, migrar para grid isométrico/hexagonal, reescrever farming ou atualizar o addon além do que for necessário à integração.

## Tarefas

- [x] Revisar a API v5 e validar o fluxo de múltiplas camadas com os exemplos oficiais; copiar e usar o atlas oficial de areia para terra.
- [x] Gerar e validar um TileSet por material, incluindo os 16 peering bits oficiais da areia, custom data e tile sizes compatíveis com a grade.
- [x] Refazer a cena de jogo e a API interna de leitura/escrita do terreno sem camada de sincronização paralela.
- [x] Preservar terreno inicial, ferramentas, andabilidade, aração e save/load.
- [x] Adaptar testes de terreno para os 16 peering bits da areia, migração das células iniciais, exclusividade, custom data, remoção e limites.
- [x] Atualizar `docs/world.md`, documentação de save/load e `README.md` com o fluxo e comandos.
- [x] Rodar gdUnit4, smoke test e checkup completo com smoke test.

## Critérios de aceite

- [x] A cena do jogo gera camadas de exibição TileMapDual e usa o atlas demo oficial copiado para renderizar terra alinhada ao grid 16×16.
- [x] No jogo, as transições de água, terra e canteiro são corretas ao pintar, apagar, aração e carregar save.
- [x] `terrain_at`, `is_walkable_cell`, `is_tillable_cell` e a serialização não dependem dos tiles visuais gerados.
- [x] Testes de terreno, todos os testes gdUnit4 e smoke test passam.
- [x] A documentação e a licença/atribuição acompanham o asset de demonstração copiado e usado.

## Riscos / Notas

- TileMapDual v5 foi reescrito e seu comportamento difere de versões anteriores; validar com as cenas oficiais e não inferir a API pelos dados da versão antiga.
- A atualização visual pode ser assíncrona/deferred; testes devem aguardar o frame/sinal apropriado em vez de depender de sincronismo não garantido.
- Múltiplas camadas de material podem se sobrepor; definir ordem e política de exclusividade em um único ponto e testar transições.
- O asset upstream `tileset_sand.png` é redistribuído sob MIT; manter a licença e atribuição junto dos assets copiados.
- O worktree original tem alterações não commitadas do usuário; não copiá-las, apagá-las ou alterá-las durante esta tarefa.
