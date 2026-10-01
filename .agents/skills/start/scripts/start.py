#!/usr/bin/env python3
"""`/skill:start N` — assume uma issue: valida, move o board para In Progress,
cria a branch padronizada e mostra o contexto.

Uso (raiz do repositório):
    python3 .agents/skills/start/scripts/start.py 4
    python3 .agents/skills/start/scripts/start.py 4 --dry-run
"""
from __future__ import annotations

import argparse
import json
import re
import subprocess
import sys

REPO = "guiguetz/godot-simulator-game"
OWNER = "guiguetz"
PROJECT = 1

TYPE_PREFIX = {
    "type:bug": "fix",
    "type:feature": "feat",
    "type:tech-debt": "refactor",
    "type:docs": "docs",
    "type:tooling": "chore",
    "type:art": "art",
    "type:design": "design",
}
STATUS_FIELD = "Status"
TARGET_STATUS = "In Progress"


def sh(cmd: list[str], *, check: bool = True) -> subprocess.CompletedProcess:
    return subprocess.run(cmd, text=True, capture_output=True, check=check)


def gh_json(cmd: list[str]) -> dict:
    out = sh(cmd).stdout
    return json.loads(out)


def graphql(query: str, *fields: str) -> dict:
    cmd = ["gh", "api", "graphql", "-f", f"query={query}", *fields]
    return json.loads(sh(cmd).stdout)


def branch_prefix(labels: list[str]) -> str:
    for name in labels:
        if name in TYPE_PREFIX:
            return TYPE_PREFIX[name]
    return "feat"


def slugify(title: str, limit: int = 40) -> str:
    slug = re.sub(r"[^a-z0-9]+", "-", title.lower()).strip("-")
    return slug[:limit].rstrip("-")


def resolve_board() -> tuple[str, str, str]:
    """Retorna (project_id, status_field_id, in_progress_option_id)."""
    data = graphql('query { user(login: "%s") { projectV2(number: %d) { id } } }'
                   % (OWNER, PROJECT))
    project_id = data["data"]["user"]["projectV2"]["id"]
    fields = graphql(
        'query { node(id: "%s") { ... on ProjectV2 { fields(first: 50) { nodes {'
        '  ... on ProjectV2SingleSelectField { name options { id name } } } } } } }' % project_id)
    for field in fields["data"]["node"]["fields"]["nodes"]:
        if field.get("name") == STATUS_FIELD:
            for opt in field.get("options") or []:
                if opt["name"] == TARGET_STATUS:
                    return project_id, field["id"], opt["id"]
    raise SystemExit(f"campo/opção não encontrado: {STATUS_FIELD}={TARGET_STATUS}")


def find_item_id(project_id: str, number: int) -> str | None:
    data = graphql(
        'query { node(id: "%s") { ... on ProjectV2 { items(first: 100) { nodes {'
        '  id content { ... on Issue { number } } } } } } }' % project_id)
    for node in data["data"]["node"]["items"]["nodes"]:
        if (node.get("content") or {}).get("number") == number:
            return node["id"]
    return None


def move_to_in_progress(project_id: str, field_id: str, option_id: str, item_id: str) -> None:
    query = ("mutation($input: UpdateProjectV2ItemFieldValueInput!) {"
             " updateProjectV2ItemFieldValue(input: $input) { projectV2Item { id } } }")
    graphql(query,
            f"input[projectId]={project_id}",
            f"input[itemId]={item_id}",
            f"input[fieldId]={field_id}",
            f"input[value][singleSelectOptionId]={option_id}")


def current_branch() -> str:
    return sh(["git", "rev-parse", "--abbrev-ref", "HEAD"]).stdout.strip()


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__,
                                     formatter_class=argparse.RawDescriptionHelpFormatter)
    parser.add_argument("number", type=int)
    parser.add_argument("--dry-run", action="store_true")
    args = parser.parse_args()

    issue = gh_json(["gh", "issue", "view", str(args.number), "--repo", REPO,
                     "--json", "number,title,labels,body,state,url"])
    if issue["state"] != "OPEN":
        raise SystemExit(f"issue #{args.number} não está aberta (state={issue['state']})")

    labels = [l["name"] for l in issue["labels"]]
    branch = f"{branch_prefix(labels)}/{args.number}-{slugify(issue['title'])}"

    plan_match = re.search(r"(plans/\d+-[\w-]+\.md)", issue["body"] or "")
    plan = plan_match.group(1) if plan_match else None

    print(f"issue  : #{issue['number']} {issue['title']}")
    print(f"labels : {', '.join(labels) or '(nenhuma)'}")
    print(f"branch : {branch}")
    print(f"plano  : {plan or '(sem plano linkado)'}")
    print(f"board  : {STATUS_FIELD} -> {TARGET_STATUS}")

    if args.dry_run:
        print("\n(dry-run: nada foi alterado)")
        return 0

    project_id, field_id, option_id = resolve_board()
    item_id = find_item_id(project_id, args.number)
    if item_id:
        move_to_in_progress(project_id, field_id, option_id, item_id)
        print("board  : movido para In Progress")
    else:
        print("board  : AVISO — issue não encontrada no board; mova manualmente", file=sys.stderr)

    if current_branch() == branch:
        print(f"git    : já está em {branch}")
    else:
        sh(["git", "fetch", "origin"])
        sh(["git", "checkout", "main"])
        sh(["git", "pull", "--ff-only"])
        existing = sh(["git", "branch", "--list", branch]).stdout.strip()
        sh(["git", "checkout", branch] if existing else ["git", "checkout", "-b", branch])
        print(f"git    : branch {branch} pronta")

    print(f"\ncontexto da issue:\n{issue['body']}")
    return 0


if __name__ == "__main__":
    try:
        sys.exit(main())
    except subprocess.CalledProcessError as exc:
        print(f"erro: comando falhou: {' '.join(exc.cmd)}\n{exc.stderr}", file=sys.stderr)
        sys.exit(1)
