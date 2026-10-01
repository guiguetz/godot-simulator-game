# ADR 006 — Addons de dev: gdUnit4 e godot_ai

- **Status:** Aceita
- **Data:** 2026-10-01
- **Contexto:** [`addons/`](../../addons/), [`project.godot`](../../project.godot), [`plans/003-estrutura-de-testes-gdunit.md`](../../plans/003-estrutura-de-testes-gdunit.md)

## Contexto

`addons/` contém dois addons de desenvolvimento, versionados no repositório:

- **`gdUnit4`** — framework de testes usado pelo CI (plano 003).
- **`godot_ai`** — integração agente↔editor; injeta o autoload
  `_mcp_game_helper` no `project.godot`.

O projeto ainda **não tem preset de export** (`export_presets.cfg` não
existe), então não havia registro do que deve ir no build final.

## Decisão

- **Ambos são addons de dev** e versionados no repositório (sem git submodule,
  para simplificar o clone e o CI).
- **Nenhum vai para o build de produção.** Quando um export preset for criado,
  `addons/gdUnit4`, `addons/godot_ai` e o autoload `_mcp_game_helper` devem
  estar **excluídos do export** (e o `project.godot` de export sem esse
  autoload, por script de export ou exclusão de diretório).
- Quem cria o primeiro export preset **deve** abrir PR também com um
  `docs/export.md` registrando as exclusões (obrigação coberta pelo
  `AGENTS.md`).

## Consequências

- **Positivas:** CI e testes funcionam em qualquer clone; decisões de export
  ficam explícitas antes de existir build.
- **Negativas / custos:** ~5,5 MB de addons de dev no clone; o autoload
  `_mcp_game_helper` fica ativo ao rodar no editor (custo desprezível, mas
  precisa sair no export).
- **Em aberto:** momento de criar o preset de export (pode virar plano).

## Alternativas descartadas

- **Addons como submodule** — CI e agente dependem de rede/persistência a mais
  para pouco ganho.
- **Manter godot_ai só fora do versionamento** — quebraria a integração
  agente↔editor em outros clones/máquinas.
