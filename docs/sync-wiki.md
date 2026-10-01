# Sincronização do wiki

Conforme [ADR 003](adr/003-onde-vive-a-documentacao.md), o wiki é **sempre
gerado a partir de `docs/`** — nunca editado à mão.

## Como funciona

O workflow [`sync-wiki.yml`](../.github/workflows/sync-wiki.yml) roda a cada
push na `main` que altere `docs/**` e publica o conteúdo de `docs/` no
repositório do wiki (`guiguetz/godot-simulator-game.wiki.git`):

- cada `docs/<topico>.md` vira uma página `<Topico>.md` no wiki;
- `docs/README.md` vira a página **Home**;
- nomes de página: primeiras letras em maiúsculas e `_` como separador
  (`github-projects.md` → `Github-projects.md`);
- um rodapé identifica a origem ("Gerado a partir de `docs/` no commit X —
  não editar aqui").

## Requisitos

- Secret **`WIKI_TOKEN`**: um Personal Access Token (fine-grained, escopo
  `Contents: read/write` no repositório). O `GITHUB_TOKEN` padrão **não**
  consegue push no wiki, por isso o secret é necessário.
  Configure em: **Repo → Settings → Secrets and variables → Actions →
  New repository secret**.

## Rodar manualmente

Actions → **Sync wiki** → Run workflow (também disponível para testar sem
mudar `docs/`).

## Notas

- O wiki ganha páginas conforme `docs/` cresce; o plano de dividir o README
  por sistema (`plans/004`) vai popular o wiki automaticamente.
- Arquivos não-`.md` de `docs/` (se existirem) não são publicados.
