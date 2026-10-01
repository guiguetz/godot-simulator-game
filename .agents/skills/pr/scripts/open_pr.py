#!/usr/bin/env python3
"""`/skill:pr` — publica a branch atual e abre o PR com `Fixes #N`.

Uso (raiz do repositório):
    python3 .agents/skills/pr/scripts/open_pr.py            # infere a issue da branch
    python3 .agents/skills/pr/scripts/open_pr.py --issue 4
    python3 .agents/skills/pr/scripts/open_pr.py --dry-run
"""
from __future__ import annotations

import argparse
import re
import subprocess
import sys

REPO = "guiguetz/godot-simulator-game"
BASE = "main"


def sh(cmd: list[str], *, check: bool = True) -> subprocess.CompletedProcess:
    return subprocess.run(cmd, text=True, capture_output=True, check=check)


def out(cmd: list[str]) -> str:
    return sh(cmd).stdout.strip()


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__,
                                     formatter_class=argparse.RawDescriptionHelpFormatter)
    parser.add_argument("--issue", type=int, help="número da issue (padrão: da branch)")
    parser.add_argument("--base", default=BASE)
    parser.add_argument("--title", help="título do PR (padrão: assunto do último commit)")
    parser.add_argument("--body-file", help="corpo do PR")
    parser.add_argument("--draft", action="store_true")
    parser.add_argument("--dry-run", action="store_true")
    args = parser.parse_args()

    branch = out(["git", "rev-parse", "--abbrev-ref", "HEAD"])
    if branch in ("main", "master", "HEAD"):
        raise SystemExit(f"não abra PR a partir de '{branch}'")

    issue = args.issue
    if issue is None:
        m = re.search(r"(\d+)", branch)
        if not m:
            raise SystemExit("não consegui inferir a issue da branch; use --issue N")
        issue = int(m.group(1))

    title = args.title or out(["git", "log", "-1", "--pretty=%s"])
    if args.body_file:
        with open(args.body_file, encoding="utf-8") as fh:
            body = fh.read()
    else:
        commits = out(["git", "log", f"{args.base}..HEAD", "--pretty=- %s"])
        body = f"Fixes #{issue}\n"
        if commits:
            body += f"\n{commits}\n"

    create = ["gh", "pr", "create", "--repo", REPO, "--base", args.base,
              "--head", branch, "--title", title, "--body", body]
    if args.draft:
        create.append("--draft")

    print("== Plano do PR ==")
    print(f"branch : {branch} -> {args.base}")
    print(f"issue  : #{issue} (corpo contém 'Fixes #{issue}')")
    print(f"título : {title}")
    print("push   : git push -u origin HEAD")
    if args.dry_run:
        print("\n(dry-run: nada foi publicado)")
        return 0

    sh(["git", "push", "-u", "origin", "HEAD"])
    url = sh(create).stdout.strip().splitlines()[-1]
    print(f"\nPR aberto: {url}")
    print("board   : o workflow 'Pull request linked to issue' deve mover para In Review")
    return 0


if __name__ == "__main__":
    try:
        sys.exit(main())
    except subprocess.CalledProcessError as exc:
        print(f"erro: comando falhou: {' '.join(exc.cmd)}\n{exc.stderr}", file=sys.stderr)
        sys.exit(1)
