# 004 — Dividir README em docs/ por sistema

- **Status:** Proposto
- **Prioridade:** Baixa
- **Esforço:** P (horas)
- **Depende de:** [ADR 003](../docs/adr/003-onde-vive-a-documentacao.md)
- **Arquivos-alvo:** `README.md`, `docs/*.md`

## Objetivo
`README.md` volta a ser uma porta de entrada rápida; o detalhe de cada sistema
fica em `docs/<sistema>.md` (e o wiki gerado acompanha).

## Motivação / Contexto
O README concentra controles, sistemas, mapa de scripts e gestão — já passou de
130 linhas e cresce a cada feature. [ADR 003] definiu a fronteira
(README = visão geral; `docs/` = detalhe), mas o conteúdo ainda não foi movido.

## Comportamento esperado
- README mantém: visão geral (1 parágrafo), controles, lista de sistemas com
  link para a doc, mapa de scripts resumido, gestão e rodar/testar.
- `docs/` ganha uma página por sistema: `world.md`, `player.md`, `farming.md`,
  `machines.md`, `fishing.md`, `inventory-shop.md`, `time-weather.md`,
  `save-load.md`, `audio.md`, `npcs.md`, `decor.md` — cada uma com como usar,
  referência de script e exemplos.
- O wiki (gerado) reflete automaticamente as novas páginas.

## Design técnico
- Extração do conteúdo atual do README, expandindo cada sistema com o que já
  existe no código (`scripts/*.gd` como referência de verdade).
- Seções "Sistemas" e "Estrutura" do README passam a apontar para `docs/`.
- Nenhuma mudança de código; risco baixo.

## Escopo
- **Incluído:** mover/reorganizar documentação; links; sync de wiki.
- **Fora do escopo:** mudar comportamento do jogo; criar conteúdo novo de
  gameplay.

## Tarefas
- [ ] Criar `docs/<sistema>.md` para cada item da lista "Sistemas" do README
- [ ] Encurtar a seção "Sistemas" do README para lista + links
- [ ] Verificar links internos (docs ↔ README ↔ AGENTS.md)
- [ ] Validar geração do wiki (workflow Sync wiki)

## Critérios de aceite
- [ ] README ≤ ~80 linhas, sem perder informação (tudo disponível via links)
- [ ] Cada sistema do jogo tem uma página em `docs/`
- [ ] Wiki reflete as páginas após o sync

## Riscos / Notas
- Risco de conteúdo duplicado entre README e docs → README mantém só resumo +
  link.
