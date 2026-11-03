#!/usr/bin/env bash
# Rejoue localement les vérifications de la CI (hors Flutter).
set -euo pipefail
cd "$(dirname "$0")/../.."

echo "== shellcheck"
mapfile -t scripts < <(git ls-files '*.sh')
shellcheck "${scripts[@]}"

echo "== markdownlint"
npx --yes markdownlint-cli2@0.18.1 "**/*.md"

echo "== actionlint"
actionlint

echo "== ADR"
scripts/ci/verifier-adr.sh
