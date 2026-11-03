#!/usr/bin/env bash
# Vérifie que chaque ADR de docs/adr/ est bien numérotée, unique, et listée
# dans l'index docs/adr/README.md avec un statut valide.
set -euo pipefail

racine="$(cd "$(dirname "$0")/../.." && pwd)"
dossier="$racine/docs/adr"
index="$dossier/README.md"
erreurs=0

declare -A vus=()
for f in "$dossier"/[0-9][0-9][0-9][0-9]-*.md; do
  nom="$(basename "$f")"
  num="${nom:0:4}"
  if [[ -n "${vus[$num]:-}" ]]; then
    echo "Numéro d'ADR en double : $num ($nom et ${vus[$num]})"
    erreurs=$((erreurs + 1))
  fi
  vus[$num]="$nom"

  if ! grep -q "($nom)" "$index"; then
    echo "ADR absente de l'index : $nom"
    erreurs=$((erreurs + 1))
  fi

  if ! head -n 1 "$f" | grep -q "^# $num\. "; then
    echo "Titre attendu « # $num. … » dans $nom"
    erreurs=$((erreurs + 1))
  fi

  if ! grep -qE '^- Statut : (proposée|acceptée|abandonnée|remplacée par [0-9]{4})$' "$f"; then
    echo "Statut manquant ou invalide dans $nom"
    erreurs=$((erreurs + 1))
  fi
done

# Les liens de l'index pointent vers des fichiers existants.
while IFS= read -r lien; do
  if [[ ! -f "$dossier/$lien" ]]; then
    echo "Lien cassé dans l'index : $lien"
    erreurs=$((erreurs + 1))
  fi
done < <(grep -oE '\([0-9]{4}-[^)]+\.md\)' "$index" | tr -d '()')

if [[ "$erreurs" -gt 0 ]]; then
  echo "$erreurs erreur(s) dans les ADR."
  exit 1
fi
echo "ADR : ${#vus[@]} décisions, index cohérent."
