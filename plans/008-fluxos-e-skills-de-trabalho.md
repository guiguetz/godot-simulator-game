# 008 — Fluxos de trabalho, skills start/pr e branching

- **Status:** Concluído
- **Prioridade:** Média
- **Esforço:** M (dias)
- **Depende de:** [005](005-checkup-de-consistencia.md), [006](006-refinos-agents-e-automacoes.md), [007](007-guarda-corpo-fase-2.md)
- **Arquivos-alvo:** `AGENTS.md`, `docs/workflow.md`, `.agents/skills/start/`, `.agents/skills/pr/`, `.agents/skills/checkup/`, `docs/checkup.md`, `README.md`

## Objetivo
Tornar explícito e repetível o fluxo de trabalho: **como atacar uma issue
existente** e **como criar algo novo**, garantindo que todas as automações
(board, CI, checkup, wiki) rodem sem depender de memória. Formaliza também a
estratégia de branching.

## Motivação / Contexto
As skills `issue` e `checkup` existem, mas o "meio do caminho" (pegar a issue,
mover para `In Progress`, criar a branch, abrir o PR com `Fixes #N`) era
manual e nebuloso. Também não havia regra de branching — todo commit ia direto
na `main`, o que esvazia as automações de PR do board.

## Comportamento esperado
1. **Branching:** nunca commitar na `main`; branch `<tipo>/<N>-slug` por issue;
   1 branch = 1 issue = 1 PR; branch morre no merge; `main` protegida (exige PR).
2. **`/skill:start <N>`:** pega a issue, move o board para `In Progress`, cria e
   faz checkout da branch com nome padronizado, e mostra o contexto (plano linkado).
3. **`/skill:pr`:** faz push da branch e abre PR com `Fixes #N` (→ `In Review`).
4. **Fluxos documentados** em `AGENTS.md` (seção Fluxos) e `docs/workflow.md`,
   com o mapa de "o que roda sozinho".
5. **Checkup:** valida o nome da branch quando não está na `main`.

## Design técnico
- **Branching:** trunk-based; `<tipo>` ∈ `feat|fix|docs|chore|refactor|test|ci`
  derivado das labels (`type:bug`→`fix`, `type:feature`→`feat`, `type:docs`→`docs`,
  `type:tooling`→`chore`, `type:tech-debt`→`refactor`).
- **`start`/`pr`:** scripts em Python usando `gh` (GraphQL para o board, evitando
  `gh project`/`read:org`); `start` tem `--dry-run`.
- **Proteção da `main`:** via API de branch protection (exige PR; sem exigir
  aprovação; sem force-push/deleção).
- **Classificação:** defeito → issue; **qualquer outro trabalho → plano + issue
  espelho**; decisão → ADR.

## Escopo
- **Incluído:** branching, skills `start`/`pr`, docs de fluxo, validação no checkup.
- **Fora do escopo:** hook `pre-push`; exigir status checks na proteção da `main`
  (avaliar depois, os nomes dos jobs podem mudar).

## Tarefas
- [x] Plano 008 + issue espelho
- [x] `AGENTS.md`: invariante de branching + seção Fluxos
- [x] `docs/workflow.md`
- [x] Skill `/skill:start` (`start.py` com `--dry-run`)
- [x] Skill `/skill:pr` (`open_pr.py`)
- [x] Checkup: verificação `git-branch`
- [x] Proteção da `main` via API
- [x] Smoke test + checkup verdes

## Critérios de aceite
- [x] `start.py --dry-run` mostra branch/board sem efeitos colaterais
- [x] PR aberto com `Fixes #N` move o item para `In Review`
- [x] Commit na `main` é rejeitado pela proteção
- [x] Checkup reprova branch fora do padrão (testado)

## Riscos / Notas
- Proteção da `main` com `enforce_admins` impede push direto até do dono — é o
  objetivo, mas exige usar PR sempre (ex.: emergências via UI).
- A skill `issue` ainda usa `gh project` (funciona localmente com `read:org`);
  migrar para GraphQL se for usada em ambientes sem esse escopo.
