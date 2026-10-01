# ADR 001 — Versão canônica do Godot

- **Status:** Proposta
- **Data:** 2026-10-01
- **Contexto:** [`project.godot`](../../project.godot), [`.github/workflows/ci.yml`](../../.github/workflows/ci.yml), [`README.md`](../../README.md)

## Contexto

O repositório não fixava uma versão de referência, e três fontes divergiam:

- `project.godot` traz `config/features = ("4.6")` — tag de compatibilidade
  mínima gravada pela engine, não a versão de desenvolvimento.
- `README.md` diz "Godot 4.6+".
- O CI usava `vars.GODOT_VERSION || '4.7.2'`, mas a variável **não existia** —
  logo rodava 4.7.2 por acidente do fallback.

O ambiente local de desenvolvimento é **4.7.2**
(`~/godot/Godot_v4.7.2-stable_linux.x86_64`).

## Decisão

- A versão canônica de desenvolvimento e CI é **Godot 4.7.2**.
- O CI resolve a versão por `vars.GODOT_VERSION`, agora definida como `4.7.2`
  no repositório (`gh variable set`). O literal do `ci.yml` permanece apenas
  como fallback.
- `config/features = ("4.6")` é mantido: expressa a compatibilidade mínima do
  projeto, não a versão de uso.
- O `README.md` passa a declarar "Godot **4.7.2** (compatível com 4.6+)".

## Consequências

- **Positivas:** CI e máquina local rodam a mesma engine; upgrade é uma
  mudança explícita (editar a variável e o README no mesmo PR).
- **Negativas / custos:** a versão vira parte do estado do repositório e
  precisa ser atualizada quando a engine subir.
- **Em aberto:** política de upgrade (quando subir e quem decide) — pode virar
  item de plano separado se o projeto crescer.

## Alternativas descartadas

- **Fixar 4.6** — contraria o ambiente local e o CI já em 4.7.2; forçaria
  downgrade sem motivo.
- **Seguir "4.x mais recente" sem pin** — builds não reproduzíveis e quebras
  silenciosas no CI.
