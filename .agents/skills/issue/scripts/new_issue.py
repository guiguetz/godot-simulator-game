#!/usr/bin/env python3
"""Cria issues já padronizadas: labels convencionais + campos do GitHub Projects.

Resolve ids de campo/opção em runtime via `gh project field-list` (sem hardcode).
Uso (raiz do repositório):

    python3 .agents/skills/issue/scripts/new_issue.py --help
    python3 .agents/skills/issue/scripts/new_issue.py \
        --title "Caixa de andabilidade maior que o tile" \
        --tipo Bug --area Player --priority "P2 - Medium" --effort "P (horas)" \
        --body-file /tmp/bug.md
    python3 .agents/skills/issue/scripts/new_issue.py ... --dry-run
"""
from __future__ import annotations

import argparse
import json
import subprocess
import sys

REPO = "guiguetz/godot-simulator-game"
OWNER = "guiguetz"
PROJECT = 1

# Nomes canônicos dos campos/opções (fonte: docs/github-projects.md).
TIPO_LABELS = {
    "Feature": "type:feature",
    "Bug": "type:bug",
    "Tech Debt": "type:tech-debt",
    "Art": "type:art",
    "Design": "type:design",
    "Docs": "type:docs",
    "Tooling": "type:tooling",
}
AREA_LABELS = {
    "World/Terrain": "area:world",
    "Player": "area:player",
    "Farming": "area:farming",
    "Machines": "area:machines",
    "Fishing": "area:fishing",
    "Inventory/Shop": "area:inventory-shop",
    "UI/HUD": "area:ui",
    "Save/Load": "area:save-load",
    "Audio": "area:audio",
    "Weather/Time": "area:weather",
    "NPCs": "area:npcs",
    "Tests/CI": "area:tests",
    "Tooling": "area:tooling",
}
PRIORITY_LABELS = {
    "P0 - Critical": "priority:p0",
    "P1 - High": "priority:p1",
    "P2 - Medium": "priority:p2",
    "P3 - Low": "priority:p3",
}
EFFORT_LABELS = {
    "P (horas)": "effort:P",
    "M (dias)": "effort:M",
    "G (semana+)": "effort:G",
}


def sh(cmd: list[str], *, capture: bool = True) -> str:
    return subprocess.run(cmd, check=True, text=True,
                          capture_output=capture).stdout


def gh_json(cmd: list[str]) -> dict:
    return json.loads(sh(cmd))


def board_metadata() -> tuple[str, dict[str, str], dict[str, dict[str, str]]]:
    project_id = gh_json(["gh", "project", "view", str(PROJECT), "--owner", OWNER,
                          "--format", "json"])["id"]
    fields = gh_json(["gh", "project", "field-list", str(PROJECT), "--owner", OWNER,
                      "--format", "json"])["fields"]
    field_ids: dict[str, str] = {}
    option_ids: dict[str, dict[str, str]] = {}
    for field in fields:
        field_ids[field["name"]] = field["id"]
        if field.get("options"):
            option_ids[field["name"]] = {o["name"]: o["id"] for o in field["options"]}
    return project_id, field_ids, option_ids


def existing_labels() -> set[str]:
    data = gh_json(["gh", "label", "list", "--repo", REPO, "--limit", "300",
                    "--json", "name"])
    return {item["name"] for item in data}


def derive_labels(args: argparse.Namespace) -> list[str]:
    labels: list[str] = []
    for value, mapping in (
        (args.tipo, TIPO_LABELS),
        (args.area, AREA_LABELS),
        (args.priority, PRIORITY_LABELS),
        (args.effort, EFFORT_LABELS),
    ):
        if value and value in mapping:
            labels.append(mapping[value])
    labels.extend(l for l in (args.label or []) if l)
    # dedupe preservando ordem
    seen: set[str] = set()
    return [l for l in labels if not (l in seen or seen.add(l))]


def build_body(args: argparse.Namespace) -> str:
    if args.body_file:
        with open(args.body_file, encoding="utf-8") as fh:
            return fh.read()
    if args.body:
        return args.body
    if args.plan_file:
        return (f"Plano de implementação completo em "
                f"[`{args.plan_file}`](../blob/main/{args.plan_file}).")
    return ""


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__,
                                     formatter_class=argparse.RawDescriptionHelpFormatter)
    parser.add_argument("--title", required=True)
    parser.add_argument("--body", help="corpo da issue")
    parser.add_argument("--body-file", help="arquivo com o corpo da issue")
    parser.add_argument("--plan-file", help="caminho do plano (ex.: plans/006-foo.md)")
    parser.add_argument("--tipo", choices=sorted(TIPO_LABELS))
    parser.add_argument("--area", choices=sorted(AREA_LABELS))
    parser.add_argument("--priority", choices=sorted(PRIORITY_LABELS))
    parser.add_argument("--effort", choices=sorted(EFFORT_LABELS))
    parser.add_argument("--status", default="Backlog")
    parser.add_argument("--label", action="append",
                        help="label extra (repetível ou separada por vírgula)")
    parser.add_argument("--dry-run", action="store_true",
                        help="mostra o plano de criação sem efeitos colaterais")
    args = parser.parse_args()

    labels: list[str] = []
    for raw in args.label or []:
        labels.extend(p.strip() for p in raw.split(",") if p.strip())
    args.label = labels

    if args.body_file and args.body:
        parser.error("use --body OU --body-file, não ambos")

    project_id, field_ids, option_ids = board_metadata()

    derived = derive_labels(args)
    missing = [l for l in derived if l not in existing_labels()]
    if missing:
        parser.error(f"labels inexistentes no repo: {missing} (crie com gh label add)")
    if derived:
        # reatribui a lista final (derivadas + extras) para uso no gh
        args.label = derived

    body = build_body(args)
    create_cmd = ["gh", "issue", "create", "--repo", REPO, "--title", args.title]
    if body:
        create_cmd += ["--body", body]
    if derived:
        create_cmd += ["--label", ",".join(derived)]

    field_values = {
        "Tipo": args.tipo,
        "Area": args.area,
        "Priority": args.priority,
        "Effort": args.effort,
        "Status": args.status,
    }
    field_values = {k: v for k, v in field_values.items() if v}
    for name, value in field_values.items():
        if name not in field_ids or name not in option_ids or value not in option_ids[name]:
            parser.error(f"campo/opção do board inválido: {name}={value}")

    print("== Plano de criação ==")
    print("issue :", " ".join(create_cmd))
    print("labels:", ", ".join(derived) or "(nenhuma)")
    print("board :", ", ".join(f"{k}={v}" for k, v in field_values.items()))

    if args.dry_run:
        print("\n(dry-run: nada foi criado)")
        return 0

    url = sh(create_cmd).strip().splitlines()[-1]
    number = url.rstrip("/").rsplit("/", 1)[-1]
    print(f"\nissue criada: {url}")

    item = gh_json(["gh", "project", "item-add", str(PROJECT), "--owner", OWNER,
                    "--url", url, "--format", "json"])["id"]
    for name, value in field_values.items():
        sh(["gh", "project", "item-edit", "--id", item, "--project-id", project_id,
            "--field-id", field_ids[name],
            "--single-select-option-id", option_ids[name][value]])
    print(f"board   : item {item} preenchido ({', '.join(field_values)})")
    return 0


if __name__ == "__main__":
    try:
        sys.exit(main())
    except subprocess.CalledProcessError as exc:
        print(f"erro: comando falhou: {' '.join(exc.cmd)}\n{exc.stderr}", file=sys.stderr)
        sys.exit(1)
