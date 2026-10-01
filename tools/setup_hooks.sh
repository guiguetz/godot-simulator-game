#!/usr/bin/env bash
# Instala os hooks locais do repositório (checkup de consistência no pre-commit).
set -euo pipefail

cd "$(git rev-parse --show-toplevel)"
git config core.hooksPath .githooks
chmod +x .githooks/pre-commit
echo "hooks instalados: core.hooksPath=$(git config core.hooksPath)"
echo "teste: python3 .agents/skills/checkup/scripts/checkup.py --offline"
