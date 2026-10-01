# Sincronização do wiki

Conforme [ADR 003](adr/003-onde-vive-a-documentacao.md), o wiki é **sempre
gerado a partir de `docs/`** — nunca editado à mão.

## Como funciona

O workflow [`sync-wiki.yml`](../.github/workflows/sync-wiki.yml) roda a cada
push na `main` que altere `docs/**` (ou manualmente, via **Run workflow**) e
publica o conteúdo de `docs/` no repositório do wiki
(`guiguetz/godot-simulator-game.wiki.git`), usando
[`tools/wiki_sync.py`](../tools/wiki_sync.py):

- cada `docs/<topico>.md` vira uma página `<Topico>.md` no wiki;
- `docs/README.md` vira a página **Home**;
- `docs/adr/README.md` vira **ADR-Home**; cada ADR vira **ADR-NNN-titulo**;
- cada página recebe um cabeçalho com a origem e o commit
  ("Gerado a partir de `docs/` no commit X — não editar aqui");
- páginas do wiki sem origem em `docs/` são removidas no sync.

## Reescrevendo links

Links relativos do Markdown não resolvem no wiki (lá as páginas são planas e o
repositório é outro). O `tools/wiki_sync.py` reescreve na publicação:

| Link em `docs/` | No wiki |
|---|---|
| para outro arquivo dentro de `docs/` (ex.: `adr/003-...md`) | vira link de página (ex.: `ADR-003-...`) |
| para algo fora de `docs/` (ex.: `../README.md`, `../../scripts/player.gd`) | URL absoluta `github.com/<repo>/blob/main/...` |
| para um diretório (ex.: `../plans/`) | URL absoluta `.../tree/main/...` |
| absolutos (`https://`, `mailto:`, `#ancora`) | inalterados |
| relativo que escaparia do repositório | mantido como está + aviso no log |

Assim o wiki fica navegável sem virar fonte de verdade.

## Requisitos

- Secret **`WIKI_TOKEN`**: um Personal Access Token (fine-grained, escopo
  `Contents: read/write` no repositório). O `GITHUB_TOKEN` padrão **não**
  consegue push no wiki, por isso o secret é necessário.
  Configure em: **Repo → Settings → Secrets and variables → Actions →
  New repository secret**.
- O wiki precisa ter **ao menos uma página** criada pela interface antes do
  primeiro sync: o GitHub só materializa o repositório `...wiki.git` depois
  disso (do contrário o clone falha com "Repository not found").

## Rodar localmente

```bash
# Gera as páginas em /tmp/wikigen a partir do docs/ atual
python3 tools/wiki_sync.py . /tmp/wikigen \
  --commit local --repo guiguetz/godot-simulator-game --branch main
```

Útil para conferir nomes de página e links antes de subir.
