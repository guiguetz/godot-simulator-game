#!/usr/bin/env python3
"""Checkup de consistência do repositório godot-simulator-game.

Uso (a partir da raiz do repositório):
    python3 .agents/skills/checkup/scripts/checkup.py
    python3 .agents/skills/checkup/scripts/checkup.py --offline   # pula checagens de rede

Saída: linhas `OK | WARN | FAIL | SKIP` com um veredito final.
Exit code: 0 sem FAIL, 1 com FAIL.
"""
from __future__ import annotations

import argparse
import json
import os
import re
import shutil
import subprocess
import sys
from pathlib import Path

REPO = "guiguetz/godot-simulator-game"
OWNER = "guiguetz"
PROJECT = 1

ROOT = Path.cwd()
results: list[tuple[str, str, str]] = []  # (level, check, message)


def record(level: str, check: str, message: str) -> None:
    results.append((level, check, message))
    print(f"{level:<4} [{check}] {message}")


def run(cmd: list[str], check_desc: str) -> str | None:
    try:
        proc = subprocess.run(cmd, capture_output=True, text=True, timeout=120)
    except FileNotFoundError:
        record("SKIP", check_desc, f"comando não encontrado: {cmd[0]}")
        return None
    if proc.returncode != 0:
        record("FAIL", check_desc, f"comando falhou ({cmd[0]}): {proc.stderr.strip()[:300]}")
        return None
    return proc.stdout


def parse_gh_json(out: str | None, check: str) -> object | None:
    if out is None:
        return None
    try:
        return json.loads(out)
    except json.JSONDecodeError as exc:
        record("FAIL", check, f"JSON inválido: {exc}")
        return None


# ---------------------------------------------------------------- local checks

def check_docs_and_templates() -> None:
    must_exist = [
        "AGENTS.md",
        "README.md",
        "docs/github-projects.md",
        "docs/adr/README.md",
        "plans/README.md",
        ".github/ISSUE_TEMPLATE/bug.yml",
        ".github/ISSUE_TEMPLATE/plano.yml",
        ".github/ISSUE_TEMPLATE/config.yml",
        ".github/workflows/ci.yml",
        "tools/smoke_test.gd",
    ]
    missing = [p for p in must_exist if not (ROOT / p).is_file()]
    if missing:
        record("FAIL", "arquivos-base", f"ausentes: {', '.join(missing)}")
    else:
        record("OK", "arquivos-base", "todos os arquivos referenciados pelo AGENTS.md existem")


def check_plans_index() -> None:
    files = sorted(
        p for p in (ROOT / "plans").glob("*.md") if p.name != "README.md"
    )
    index_text = (ROOT / "plans/README.md").read_text(encoding="utf-8")
    index_ids = set(re.findall(r"\[(\d+)\]\((\d+[^)]*\.md)\)", index_text))
    file_ids = {re.match(r"(\d+)-", p.name).group(1): p.name for p in files if re.match(r"(\d+)-", p.name)}
    index_only = {i for i, _ in index_ids} - set(file_ids)
    file_only = set(file_ids) - {i for i, _ in index_ids}
    link_mismatch = {i for i, f in index_ids if i in file_ids and file_ids[i] != f}
    problems = []
    if index_only:
        problems.append(f"no índice mas sem arquivo: {sorted(index_only)}")
    if file_only:
        problems.append(f"arquivo sem linha no índice: {sorted(file_only)}")
    if link_mismatch:
        problems.append(f"link do índice aponta p/ nome errado: {sorted(link_mismatch)}")
    if problems:
        record("FAIL", "índice-de-planos", "; ".join(problems))
    else:
        record("OK", "índice-de-planos", f"{len(file_ids)} planos indexados e consistentes")


def check_plan_template() -> None:
    required = ["## Objetivo", "## Critérios de aceite", "- **Status:**", "- **Prioridade:**", "- **Esforço:**"]
    bad = []
    for p in sorted((ROOT / "plans").glob("[0-9]*-*.md")):
        text = p.read_text(encoding="utf-8")
        missing = [s for s in required if s not in text]
        if missing:
            bad.append(f"{p.name}: faltam {missing}")
    if bad:
        record("FAIL", "template-de-planos", "; ".join(bad))
    else:
        record("OK", "template-de-planos", "todos os planos seguem o template")


def check_template_labels(template_labels: dict[str, list[str]]) -> set[str]:
    all_needed: set[str] = set()
    bad = []
    for name, labels in template_labels.items():
        for label in labels:
            all_needed.add(label)
            if not LABELS_IN_REPO:
                continue
            if label not in LABELS_IN_REPO:
                bad.append(f"{name}: label '{label}' não existe no repo")
    if bad:
        record("FAIL", "labels-de-template", "; ".join(bad))
    else:
        record("OK", "labels-de-template", f"{len(all_needed)} labels usadas nos templates existem no repo")
    return all_needed


def check_docs_index() -> None:
    docs_dir = ROOT / "docs"
    index_path = docs_dir / "README.md"
    if not index_path.is_file():
        record("FAIL", "docs-↔-índice", "docs/README.md não encontrado")
        return
    text = index_path.read_text(encoding="utf-8")
    links = re.findall(r"\]\(([^)]+)\)", text)
    linked: set[str] = set()
    dead: list[str] = []
    for link in links:
        if link.startswith(("http://", "https://", "#")):
            continue
        target = link.split("#", 1)[0]
        linked.add(target.lstrip("./") if target.startswith("./") else target)
        if not (docs_dir / target).exists():
            dead.append(link)
    files = {p.name for p in docs_dir.glob("*.md") if p.name != "README.md"}
    missing = sorted(f for f in files if f not in linked)
    problems = []
    if missing:
        problems.append(f"sem link no índice de docs/README.md: {missing}")
    if dead:
        problems.append(f"links mortos no índice: {dead}")
    if problems:
        record("FAIL", "docs-↔-índice", "; ".join(problems))
    else:
        record("OK", "docs-↔-índice", f"{len(files)} docs indexados e links válidos")


# --------------------------------------------------------------- github checks

LABELS_IN_REPO: set[str] = set()


def check_labels(needed: set[str]) -> None:
    global LABELS_IN_REPO
    out = run(["gh", "label", "list", "--repo", REPO, "--limit", "200", "--json", "name"], "labels-do-repo")
    data = parse_gh_json(out, "labels-do-repo")
    if data is None:
        return
    LABELS_IN_REPO = {item["name"] for item in data}
    conventional = [l for l in LABELS_IN_REPO if re.match(r"^(type|area|priority|effort):", l)]
    record("OK", "labels-do-repo", f"{len(LABELS_IN_REPO)} labels ({len(conventional)} convencionais)")


def check_labels_documented() -> None:
    doc = (ROOT / "docs/github-projects.md").read_text(encoding="utf-8")
    undocumented = sorted(
        l for l in LABELS_IN_REPO
        if re.match(r"^(type|area|priority|effort):", l) and f"`{l}`" not in doc
    )
    if undocumented:
        record("FAIL", "labels-documentadas", f"labels sem doc em docs/github-projects.md: {undocumented}")
    else:
        record("OK", "labels-documentadas", "todas as labels convencionais estão em docs/github-projects.md")

    documented = set(re.findall(r"`((?:type|area|priority|effort):[\w-]+)`", doc))
    missing = sorted(l for l in documented if l not in LABELS_IN_REPO)
    if missing:
        record("FAIL", "labels-catalogadas", f"documentadas mas ausentes no repo: {missing}")
    else:
        record("OK", "labels-catalogadas", "todas as labels catalogadas existem no repo")


def check_issues() -> tuple[dict[int, dict], list[dict]]:
    out = run(
        ["gh", "issue", "list", "--repo", REPO, "--state", "all", "--limit", "200",
         "--json", "number,title,state,labels,body,url"],
        "issues-do-repo",
    )
    data = parse_gh_json(out, "issues-do-repo")
    if data is None:
        return {}, []
    open_no_type = [i["number"] for i in data if i["state"] == "OPEN" and not any(
        l["name"].startswith("type:") for l in i["labels"])]
    if open_no_type:
        record("WARN", "issue-type-label", f"issues abertas sem label type:*: {open_no_type}")
    else:
        record("OK", "issue-type-label", "todas as issues abertas têm label type:*")
    return {i["number"]: i for i in data}, data


def check_plans_issues(issues_by_number: dict[int, dict], issues: list[dict]) -> None:
    plan_files = {re.match(r"(\d+)-", p.name).group(1): p.name for p in (ROOT / "plans").glob("[0-9]*-*.md")}
    plan_issues: dict[str, int] = {}
    for issue in issues:
        m = re.match(r"\[Plano (\d+)\]", issue["title"])
        if m:
            plan_issues[m.group(1)] = issue["number"]
    problems = []
    for pid, fname in sorted(plan_files.items()):
        if pid not in plan_issues:
            problems.append(f"plano {pid} ({fname}) sem issue espelho")
        else:
            body = issues_by_number[plan_issues[pid]]["body"] or ""
            if fname not in body:
                problems.append(f"issue [Plano {pid}] não linka {fname}")
    descarted = [p for p in (ROOT / "plans").glob("[0-9]*-*.md")
                 if re.search(r"^- \*\*Status:\*\*.*Descartado", p.read_text(encoding="utf-8"), re.M)]
    known_desc = {re.match(r"(\d+)-", p.name).group(1) for p in descarted}
    orphan = [pid for pid in plan_issues if pid not in plan_files and pid not in known_desc]
    if orphan:
        problems.append(f"issue [Plano {'/'.join(sorted(orphan))}] sem arquivo em plans/")
    if problems:
        record("FAIL", "planos-↔-issues", "; ".join(problems))
    else:
        record("OK", "planos-↔-issues", f"{len(plan_files)} planos com issues espelho consistentes")


def check_board(issues: list[dict]) -> None:
    out = run(["gh", "project", "item-list", str(PROJECT), "--owner", OWNER,
               "--limit", "500", "--format", "json"], "board-itens")
    data = parse_gh_json(out, "board-itens")
    if data is None:
        return
    items = data.get("items", [])
    issues_in_board = {}
    problems = []
    for item in items:
        content = item.get("content", {})
        if content.get("type") != "Issue":
            continue
        repo_full = content.get("repository", "")
        if repo_full and not repo_full.endswith(REPO):
            continue
        issues_in_board[content.get("number")] = item
    for issue in issues:
        n = issue["number"]
        item = issues_in_board.get(n)
        if item is None:
            problems.append(f"issue #{n} fora do board")
            continue
        status = item.get("status") or ""
        if issue["state"] == "OPEN" and status == "Done":
            problems.append(f"issue #{n} aberta com Status=Done")
        if issue["state"] == "CLOSED" and status != "Done":
            problems.append(f"issue #{n} fechada com Status={status or 'vazio'}")
        for field in ("priority", "tipo", "area", "effort"):
            if not item.get(field):
                problems.append(f"issue #{n}: campo '{field.capitalize()}' vazio")
    if problems:
        record("FAIL", "board-↔-issues", "; ".join(problems[:12]) + (" …" if len(problems) > 12 else ""))
    else:
        record("OK", "board-↔-issues", f"{len(issues_in_board)} itens no board com campos preenchidos e Status coerente")


def check_board_fields_documented() -> None:
    out = run(["gh", "project", "field-list", str(PROJECT), "--owner", OWNER,
               "--format", "json"], "board-campos")
    data = parse_gh_json(out, "board-campos")
    if data is None:
        return
    doc = (ROOT / "docs/github-projects.md").read_text(encoding="utf-8")
    problems = []
    for field in data.get("fields", []):
        name = field.get("name", "")
        if name not in ("Status", "Priority", "Area", "Effort", "Tipo"):
            continue
        for opt in field.get("options", []):
            val = opt.get("name", "")
            if val and f"`{val}`" not in doc and val not in doc:
                problems.append(f"opção '{name}: {val}' não documentada")
    if problems:
        record("FAIL", "board-campos-documentados", "; ".join(problems))
    else:
        record("OK", "board-campos-documentados", "opções dos campos do board batem com docs/github-projects.md")


def check_board_workflows() -> None:
    doc = (ROOT / "docs/github-projects.md").read_text(encoding="utf-8")
    expected: dict[str, bool] = {}
    for line in doc.splitlines():
        m = re.match(r"^\|\s*([^|]+?)\s*\|\s*(✅|⬜)", line)
        if m:
            expected[m.group(1).strip()] = m.group(2) == "✅"
    if not expected:
        record("WARN", "board-workflows", "tabela de automações não encontrada em docs/github-projects.md")
        return
    view = parse_gh_json(
        run(["gh", "project", "view", str(PROJECT), "--owner", OWNER, "--format", "json"],
            "board-workflows"), "board-workflows")
    if view is None:
        return
    query = ('query { node(id: "%s") { ... on ProjectV2 { workflows(first: 20) '
             '{ nodes { name enabled } } } } }' % view["id"])
    data = parse_gh_json(run(["gh", "api", "graphql", "-f", f"query={query}"],
                             "board-workflows"), "board-workflows")
    if data is None:
        return
    actual = {w["name"]: w["enabled"] for w in data["data"]["node"]["workflows"]["nodes"]}
    problems = []
    for name, exp in sorted(expected.items()):
        if name not in actual:
            problems.append(f"'{name}' documentado mas inexistente no board")
        elif actual[name] != exp:
            state = lambda on: "ativo" if on else "inativo"
            problems.append(f"'{name}': doc={state(exp)} real={state(actual[name])}")
    problems += [f"'{n}' no board mas não documentado" for n in sorted(actual) if n not in expected]
    if problems:
        record("FAIL", "board-workflows", "; ".join(problems))
    else:
        record("OK", "board-workflows", f"{len(expected)} workflows batem com docs/github-projects.md")


def find_godot() -> str | None:
    env = os.environ.get("GODOT")
    if env and Path(env).is_file():
        return env
    if shutil.which("godot"):
        return "godot"
    for candidate in sorted(Path.home().glob("godot*/Godot_v*_linux.x86_64")):
        return str(candidate)
    return None


def check_smoke_test() -> None:
    godot = find_godot()
    if godot is None:
        record("SKIP", "smoke-test", "binário do Godot não encontrado (use GODOT=/caminho/godot)")
        return
    out = run([godot, "--headless", "--path", str(ROOT), "--script", "tools/smoke_test.gd"], "smoke-test")
    if out is None:
        return
    fails = out.count("FAIL")
    passes = out.count("PASS")
    if fails:
        record("FAIL", "smoke-test", f"{fails} ocorrências de FAIL ({passes} PASS)")
    else:
        record("OK", "smoke-test", f"PASS ({passes} verificações)")


def check_prs() -> None:
    out = run(["gh", "pr", "list", "--repo", REPO, "--state", "open", "--limit", "100",
               "--json", "number,title,body,url"], "prs-↔-issues")
    data = parse_gh_json(out, "prs-↔-issues")
    if data is None:
        return
    if not data:
        record("OK", "prs-↔-issues", "nenhum PR aberto")
        return
    problems = [f"PR #{pr['number']} não referencia nenhuma issue" for pr in data
                if not re.search(r"#\d+", pr.get("body") or "")]
    if problems:
        record("FAIL", "prs-↔-issues", "; ".join(problems))
    else:
        record("OK", "prs-↔-issues", f"{len(data)} PR(s) aberto(s) com issue vinculada")


def main() -> int:
    parser = argparse.ArgumentParser()
    parser.add_argument("--offline", action="store_true", help="pula checagens que usam gh/rede e o smoke test")
    parser.add_argument("--no-smoke", action="store_true", help="não roda o smoke test do Godot")
    parser.add_argument("--no-board", action="store_true", help="pula checagens do GitHub Projects (útil no CI)")
    args = parser.parse_args()

    print(f"== Checkup de consistência — {REPO} ==")

    check_docs_and_templates()
    check_plans_index()
    check_plan_template()
    check_docs_index()

    template_labels = {
        "bug.yml": ["bug", "type:bug"],
        "plano.yml": ["enhancement", "type:feature"],
    }

    if args.offline:
        record("SKIP", "github", "--offline: checagens de rede ignoradas")
        check_labels_offline(template_labels)
    else:
        check_labels(set())
        needed = check_template_labels(template_labels)
        check_labels_documented()
        issues_by_number, issues = check_issues()
        check_plans_issues(issues_by_number, issues)
        check_prs()
        if args.no_board:
            record("SKIP", "board", "--no-board")
        else:
            check_board(issues)
            check_board_fields_documented()
            check_board_workflows()
        if args.no_smoke:
            record("SKIP", "smoke-test", "--no-smoke")
        else:
            check_smoke_test()

    counts = {}
    for level, _, _ in results:
        counts[level] = counts.get(level, 0) + 1
    print(f"\n== Resumo: {counts.get('OK',0)} OK · {counts.get('WARN',0)} WARN · "
          f"{counts.get('FAIL',0)} FAIL · {counts.get('SKIP',0)} SKIP ==")
    return 1 if counts.get("FAIL") else 0


def check_labels_offline(template_labels: dict[str, list[str]]) -> None:
    labels_doc = set(re.findall(r"`((?:type|area|priority|effort):[\w-]+)`",
                                (ROOT / "docs/github-projects.md").read_text(encoding="utf-8")))
    missing = [l for ls in template_labels.values() for l in ls if l not in labels_doc]
    if missing:
        record("WARN", "labels-documentadas (offline)", f"usadas em templates mas não no doc: {missing}")
    else:
        record("OK", "labels-documentadas (offline)", "labels dos templates estão no doc")


if __name__ == "__main__":
    sys.exit(main())
