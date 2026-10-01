# 007 — Guarda-corpo fase 2: pre-commit, conteúdo de ADR e board no CI

- **Status:** Em andamento
- **Prioridade:** Média
- **Esforço:** M (dias)
- **Depende de:** [005](005-checkup-de-consistencia.md), [006](006-refinos-agents-e-automacoes.md), [ADR 007](../docs/adr/007-checkup-como-guarda-corpo.md)
- **Arquivos-alvo:** `.githooks/`, `tools/setup_hooks.sh`, `.agents/skills/checkup/`, `.github/workflows/checkup.yml`, `docs/checkup.md`, `docs/adr/007-checkup-como-guarda-corpo.md`, `README.md`

## Objetivo
Fechar os itens "em aberto" do ADR 007: rodar o checkup **localmente antes do
commit**, validar o **conteúdo** dos ADRs (não só o índice) e habilitar as
checagens de **board no CI** quando houver token com escopo de Projects.

## Motivação / Contexto
Hoje o checkup só roda sob demanda ou no CI. Um hook local pega
inconsistências antes do push. Os ADRs são validados apenas quanto ao índice —
um ADR sem `Decisão`/`Consequências` passa. E o CI roda `--no-board` porque o
`GITHUB_TOKEN` não acessa Projects v2 de usuário.

## Comportamento esperado
1. `git commit` roda o checkup **offline** e bloqueia só em `FAIL` (WARN/SKIP
   não bloqueiam).
2. ADR sem seção obrigatória gera `FAIL` em `adr-conteudo`.
3. O job `Checkup` usa `--board` quando o secret `PROJECTS_TOKEN` existir;
   senão mantém `--no-board`.
4. Doc do ADR 007 reflete o estado real (views já cobertas por `board-views`).

## Design técnico
- **Hook:** `.githooks/pre-commit` (bash) chama
  `python3 .agents/skills/checkup/scripts/checkup.py --offline`; instalado por
  `tools/setup_hooks.sh` (`git config core.hooksPath .githooks`).
- **`adr-conteudo`:** exige `- **Status:**`, `- **Data:**` e os headings
  `## Contexto`, `## Decisão`, `## Consequências`, `## Alternativas descartadas`.
- **CI:** `GH_TOKEN: ${{ secrets.PROJECTS_TOKEN || secrets.GITHUB_TOKEN }}` e
  passo que decide entre `--board` e `--no-board` conforme o secret existir.
- **Offline:** `check_labels_offline` passa a considerar só labels com prefixo
  (`type:`/`area:`/`priority:`/`effort:`), removendo WARN espúrio de
  `bug`/`enhancement` — importante para o hook não fazer barulho.

## Escopo
- **Incluído:** os 4 itens acima + docs no mesmo commit.
- **Fora do escopo:** hook `pre-push`/CI com checagem de board via GitHub App
  (avaliar depois); o token `PROJECTS_TOKEN` precisa ser criado pelo dono.

## Tarefas
- [x] Ajuste de casa no ADR 007 (remover item já concluído)
- [x] Verificação `adr-conteudo`
- [x] Corrigir WARN espúrio do modo `--offline`
- [x] Hook `.githooks/pre-commit` + `tools/setup_hooks.sh` + doc
- [x] CI: `--board` condicionado ao secret `PROJECTS_TOKEN` + doc
- [ ] Criar o secret `PROJECTS_TOKEN` no repositório (ação do dono) e confirmar CI com board

## Critérios de aceite
- [x] Checkup completo sem FAIL; `--offline` sem WARN
- [x] Hook bloqueia commit com inconsistência (testado) e libera commit limpo
- [x] ADR sem seção obrigatória é detectado
- [x] CI verde **sem** `PROJECTS_TOKEN` (fallback `--no-board`)
- [ ] CI verde **com** `PROJECTS_TOKEN` (checagens de board habilitadas)

## Riscos / Notas
- O hook não se instala sozinho em clones novos — daí o `setup_hooks.sh` e a
  doc; sem `python3`, o hook é inerte (não bloqueia).
- Sem `PROJECTS_TOKEN`, o CI continua sem checar board (comportamento atual).
