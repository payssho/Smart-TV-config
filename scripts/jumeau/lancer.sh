#!/usr/bin/env bash
# Joue le scénario du jumeau sur les profils demandés (2 Go d'abord, la
# cible prioritaire), puis écrit le rapport comparatif.
#
# Usage : scripts/jumeau/lancer.sh [--profils "2go 4go"] [--scenario complet|fumee]
#           [--palier S] [--image DOSSIER] [--sortie DOSSIER]
# L'image doit exister (construire-image.sh). Code de sortie non nul si un
# profil plante ou si le rapport relève une règle violée.
set -euo pipefail

ici="$(cd "$(dirname "$0")" && pwd)"
profils="2go 4go"
scenario=complet
palier=60
image="$ici/.image"
sortie="$ici/resultats/$(date +%Y-%m-%d)"

while [[ $# -gt 0 ]]; do
  case "$1" in
    --profils) profils="$2"; shift 2 ;;
    --scenario) scenario="$2"; shift 2 ;;
    --palier) palier="$2"; shift 2 ;;
    --image) image="$2"; shift 2 ;;
    --sortie) sortie="$2"; shift 2 ;;
    -h|--help) sed -n '2,9p' "$0"; exit 0 ;;
    *) echo "Option inconnue : $1" >&2; exit 2 ;;
  esac
done

echec=0
for profil in $profils; do
  "$ici/demarrer.sh" --profil "$profil" --scenario "$scenario" --palier "$palier" \
    --image "$image" --sortie "$sortie" || echec=1
done
python3 "$ici/rapport.py" "$sortie" >"$sortie/rapport.md" || echec=1
cat "$sortie/rapport.md"
exit "$echec"
