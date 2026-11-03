#!/usr/bin/env bash
# Crée un milestone GitHub par phase et y range les issues selon leur label
# « phase-N ». Idempotent : un milestone déjà présent est réutilisé.
#
# Usage (avec la CLI gh connectée) : scripts/github/creer-milestones.sh
set -euo pipefail

depot="${DEPOT:-payssho/Smart-TV-config}"

titres=(
  "Phase 0 · Cadrage du dépôt"
  "Phase 1 · Validation du matériel"
  "Phase 2 · Interface sur Armbian"
  "Phase 3 · Image Buildroot"
  "Phase 4 · Lecteur vidéo et premiers usages"
  "Phase 5 · Hub intégré"
  "Phase 6 · Solidité"
  "Phase 7 · Extras"
)

for n in "${!titres[@]}"; do
  titre="${titres[$n]}"
  numero="$(gh api "repos/$depot/milestones?state=all&per_page=100" \
    --jq ".[] | select(.title == \"$titre\") | .number")"
  if [[ -z "$numero" ]]; then
    numero="$(gh api "repos/$depot/milestones" -f title="$titre" \
      -f description="Voir docs/roadmap.md, phase $n." --jq '.number')"
    echo "Créé : $titre (#$numero)"
  else
    echo "Existe déjà : $titre (#$numero)"
  fi

  gh issue list -R "$depot" --label "phase-$n" --state all --limit 200 \
    --json number --jq '.[].number' |
    while read -r issue; do
      gh api -X PATCH "repos/$depot/issues/$issue" -F milestone="$numero" >/dev/null
      echo "  #$issue → $titre"
    done
done
