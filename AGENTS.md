# AGENTS.md — instruções do agente para este repositório

Estas regras valem para **toda** sessão neste repositório. Leia-as antes de
agir. As fontes de detalhe são [`docs/github-projects.md`](docs/github-projects.md)
e [`plans/README.md`](plans/README.md) — em caso de conflito, elas vencem.

## Invariantes de workflow

1. **Bug discutido → abrir issue imediatamente.**
   Sempre que uma conversa identificar um defeito ou regressão, crie a issue
   **antes** de propor a correção:
   ```bash
   gh issue create --repo guiguetz/godot-simulator-game \
     --template bug.yml --title "..." --body "..."
   ```
   Se o template não for aplicável via CLI, use as seções **Sintoma /
   Reprodução / Causa / Verificação** no corpo e as labels `bug` e `type:bug`.
   Ao corrigir, atualize a issue com causa e verificação e só então feche.
   Bug em promise/hipótese ainda não confirmada: abra como issue com status
   *Em investigação* em vez de afirmar a causa.

2. **Plano discutido → criar `plans/NNN-*.md` *e* a issue espelho no Projects.**
   Ao decidir construir algo novo:
   - crie `plans/NNN-titulo-curto.md` seguindo o template de `plans/README.md`
     (NNN = próximo número livre), atualize o índice do `plans/README.md`;
   - abra a issue `[Plano NNN] ...` com `--template plano.yml` linkando o arquivo;
   - garanta que o item entrou no board (<https://github.com/users/guiguetz/projects/1>)
     e preencha `Status`, `Priority`, `Tipo`, `Area`, `Effort`
     (ids/CLI em `docs/github-projects.md`).
   Bugs **não** viram plano — bugs vão para o Issues.

3. **Implementação → documentação em `docs/`.**
   Toda funcionalidade ou mudança de comportamento implementada exige:
   - um `docs/<topico>.md` (ou seção nova no doc existente) descrevendo o que
     mudou, como usar e exemplos — em português, no estilo dos docs atuais;
   - atualização do `README.md` quando a mudança afetar controles, sistemas,
     estrutura de arquivos ou fluxo de gestão;
   - a doc entra no **mesmo** commit/PR da implementação, não "depois".

4. **Checkup de consistência antes de encerrar.**
   Antes de encerrar uma sessão ou abrir PR, rode o checkup
   (`/skill:checkup` no pi, ou `python3 .agents/skills/checkup/scripts/checkup.py`)
   e corrija os FAILs na fonte. Detalhes em [`docs/checkup.md`](docs/checkup.md).
   Se uma regra deixar de fazer sentido, atualize `AGENTS.md` e o checkup no
   mesmo commit — nunca ajuste o checkup para mascarar um FAIL.

## Regras de trabalho

- **Idioma:** responda e escreva docs em **português (pt-BR)**. Identificadores
  de código permanecem em inglês.
- **Antes de codar:** leia os arquivos envolvidos; não invente APIs/sinais.
  Consulte `README.md` (mapa dos scripts) e `plans/NNN-*.md` (design acordado).
- **Um escopo por PR:** vincule o PR à issue correspondente.
- **Verificação:** rode o smoke test headless antes de declarar concluído:
  ```bash
  godot --headless --path . --script tools/smoke_test.gd
  ```
  Testes automatizados (gdUnit4) estão descritos em
  [`plans/003-estrutura-de-testes-gdunit.md`](plans/003-estrutura-de-testes-gdunit.md).
- **Git:** commits no imperativo, com prefixo de tipo (`feat:`, `fix:`,
  `docs:`, `ci:`, `chore:`), seguindo o histórico (`git log --oneline`).
- **Não** feche issue de bug sem verificação registrada; **não** mova plano
  para *Concluído* sem cumprir os critérios de aceite do próprio plano.
- Se uma operação exigir permissão que você não tem (ex.: editar views do
  Projects via API, publicar wiki), **peça** em vez de contornar.

## Mapa rápido

| Assunto | Onde |
|---|---|
| Board, campos, labels, views, automações | `docs/github-projects.md` |
| Decisões de arquitetura (ADRs) | `docs/adr/README.md` |
| Template e índice de planos | `plans/README.md` |
| Visão geral do jogo, controles, scripts | `README.md` |
| Templates de issue | `.github/ISSUE_TEMPLATE/` |
| CI | `.github/workflows/ci.yml` |
| Checkup de consistência | `docs/checkup.md`, `.agents/skills/checkup/` |
