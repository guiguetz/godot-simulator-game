#!/usr/bin/env python3
"""Gera o conteúdo do wiki a partir de ``docs/``.

Conforme o ADR 003, o wiki é sempre derivado de ``docs/``. Este script:

* publica ``docs/*.md`` e ``docs/adr/*.md`` como páginas do wiki
  (``docs/README.md`` -> ``Home``; ``docs/adr/README.md`` -> ``ADR-Home``);
* reescreve links relativos que não resolvem no wiki:
  - links para arquivos dentro de ``docs/`` viram links de página do wiki;
  - links para o restante do repositório viram URLs absolutas do GitHub
    (``blob``/``tree`` na branch alvo);
* adiciona um cabeçalho em cada página apontando a origem e o commit.

Uso:
    python3 tools/wiki_sync.py <repo_root> <wiki_dir> --commit <sha> \
        --repo <owner/name> --branch main

O script é idempotente: reformula todas as páginas ``*.md`` do diretório do wiki
e remove as que não têm mais origem em ``docs/``.
"""
from __future__ import annotations

import argparse
import glob
import os
import posixpath
import re
import sys

SOURCE_PATTERNS = ("docs/*.md", "docs/adr/*.md")
LINK_RE = re.compile(r"\[([^\]]*)\]\(([^)\s]+)\)")
ABSOLUTE_RE = re.compile(r"^(?:https?:|mailto:|#|//)")


def page_name(rel_path: str) -> str:
    """Título da página do wiki (sem ``.md``) para um caminho relativo ao repo."""
    rel_path = rel_path[:-3] if rel_path.endswith(".md") else rel_path
    if rel_path == "docs/README":
        return "Home"
    base = os.path.basename(rel_path)
    if rel_path.startswith("docs/adr/"):
        if base == "README":
            return "ADR-Home"
        return "ADR-" + base[0].upper() + base[1:]
    return base[0].upper() + base[1:]


def _rewrite_link(label: str, target: str, src_rel: str, repo_root: str, repo: str, branch: str) -> str:
    if ABSOLUTE_RE.match(target):
        return f"[{label}]({target})"

    anchor = ""
    if "#" in target:
        target, anchor = target.split("#", 1)
        anchor = "#" + anchor

    resolved = posixpath.normpath(posixpath.join(posixpath.dirname(src_rel), target))
    if resolved.startswith(".."):
        print(f"aviso: link relativo escapa do repositório, mantido como está: {target} (em {src_rel})", file=sys.stderr)
        return f"[{label}]({target}{anchor})"
    if resolved.startswith("docs/"):
        return f"[{label}]({page_name(resolved)}{anchor})"

    full = os.path.join(repo_root, resolved)
    kind = "tree" if os.path.isdir(full) else "blob"
    return f"[{label}](https://github.com/{repo}/{kind}/{branch}/{resolved}{anchor})"


def rewrite_links(text: str, src_rel: str, repo_root: str, repo: str, branch: str) -> str:
    return LINK_RE.sub(
        lambda m: _rewrite_link(m.group(1), m.group(2), src_rel, repo_root, repo, branch),
        text,
    )


def render(src_rel: str, repo_root: str, repo: str, branch: str, commit: str) -> str:
    with open(os.path.join(repo_root, src_rel), encoding="utf-8") as fh:
        body = fh.read()
    header = (
        f"<!-- Gerado a partir de {src_rel} no commit {commit} — "
        "não editar aqui; edite em docs/ e deixe o workflow publicar. -->\n\n"
    )
    return header + rewrite_links(body, src_rel, repo_root, repo, branch)


def collect_sources(repo_root: str) -> list[str]:
    sources: list[str] = []
    for pattern in SOURCE_PATTERNS:
        for full in sorted(glob.glob(os.path.join(repo_root, pattern))):
            sources.append(os.path.relpath(full, repo_root).replace(os.sep, "/"))
    return sources


def sync(repo_root: str, wiki_dir: str, commit: str, repo: str, branch: str) -> int:
    os.makedirs(wiki_dir, exist_ok=True)
    sources = collect_sources(repo_root)
    if "docs/README.md" not in sources:
        print("erro: docs/README.md não existe (a Home do wiki depende dele)", file=sys.stderr)
        return 1

    generated = {page_name(rel) for rel in sources}

    # reformula páginas geradas
    for rel in sources:
        dest = os.path.join(wiki_dir, page_name(rel) + ".md")
        with open(dest, "w", encoding="utf-8") as fh:
            fh.write(render(rel, repo_root, repo, branch, commit))
        print(f"{rel} -> {page_name(rel)}.md")

    # remove páginas que não têm mais origem (mantém arquivos alheios, se houver)
    for name in sorted(os.listdir(wiki_dir)):
        if not name.endswith(".md"):
            continue
        if name[:-3] in generated:
            continue
        os.remove(os.path.join(wiki_dir, name))
        print(f"removido (sem origem em docs/): {name}")
    return 0


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("repo_root")
    parser.add_argument("wiki_dir")
    parser.add_argument("--commit", default="desconhecido")
    parser.add_argument("--repo", required=True, help="owner/name")
    parser.add_argument("--branch", default="main")
    args = parser.parse_args()
    return sync(args.repo_root, args.wiki_dir, args.commit, args.repo, args.branch)


if __name__ == "__main__":
    raise SystemExit(main())
