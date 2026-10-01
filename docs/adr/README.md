# ADRs — decisões de arquitetura

Registro das **decisões** do projeto: por que escolhemos assim, quais
alternativas foram descartadas e o que fica em aberto.

> Um **plano** ([`plans/`](../../plans/README.md)) descreve *trabalho futuro*.
> Um **ADR** descreve uma *decisão tomada* — normalmente continua válido
> mesmo depois que o código muda, e só é substituído por outro ADR.

## Quando escrever um ADR

- Escolha entre duas ou mais alternativas plausíveis (biblioteca, formato de
  save, versão de engine, fluxo de trabalho).
- Decisão que alguém pode querer "melhorar" depois sem saber o motivo
  original.
- Convenção do repositório que precisa ser explícita (idioma, testes, docs).

Não precisa de ADR: correção de bug, refatoração local, ajuste de
balanceamento. Isso vai para issues/planos/código.

## Formato

Um arquivo por decisão: `docs/adr/NNN-titulo-curto.md` (NNN = próximo número
livre, nunca reutilizado). Status seguem `Proposta → Aceita → Substituída`.

```markdown
# ADR NNN — Título curto

- **Status:** Proposta | Aceita | Substituída por [ADR NNN](NNN-*.md)
- **Data:** AAAA-MM-DD
- **Contexto:** links para planos/issues relacionados (ou "—")

## Contexto
Qual problema ou tensão motivou a decisão. Fatos, não opiniões.

## Decisão
O que foi decidido, no imperativo ("Usamos X", "Documentação vive em Y").

## Consequências
- **Positivas:** o que melhora.
- **Negativas / custos:** o que perdemos ou passamos a manter.
- **Em aberto:** o que fica para depois (pode virar plano/issue).

## Alternativas descartadas
- **Alternativa A** — por que não.
- **Alternativa B** — por que não.
```

## Índice

| ADR | Título | Status |
|---|---|---|
| [001](001-versao-do-godot.md) | Versão canônica do Godot | Aceita |
| [002](002-gestao-no-github.md) | Gestão no GitHub Issues + Projects | Aceita |
| [003](003-onde-vive-a-documentacao.md) | Onde vive cada documentação | Aceita |
| [004](004-politica-de-testes.md) | Política de testes | Aceita |
| [005](005-versionamento-de-save.md) | Versionamento do save | Aceita |
| [006](006-addons-de-dev.md) | Addons de dev (gdUnit4, godot_ai) | Aceita |
