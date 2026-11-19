#!/usr/bin/env bash
# Réactive les paquets d'un journal d'allègement (ADR 0025).
#   projecteur/adb/restaurer.sh                 # dernier journal
#   projecteur/adb/restaurer.sh etat/journal-…  # journal précis
#   projecteur/adb/restaurer.sh --tout          # tout paquet désactivé
set -euo pipefail
# shellcheck source-path=SCRIPTDIR source=commun.sh
source "$(dirname "$0")/commun.sh"
verifier_adb

if [[ "${1:-}" == "--tout" ]]; then
  mapfile -t paquets < <(sh_proj pm list packages -d | sed 's/^package://')
else
  journal="${1:-$(find "$ETAT" -maxdepth 1 -name 'journal-allegement-*.txt' | sort | tail -n 1)}"
  [[ -f "$journal" ]] || die "aucun journal d'allègement trouvé dans $ETAT."
  echo "Journal : $journal"
  mapfile -t paquets < <(lire_liste "$journal")
fi

for p in "${paquets[@]}"; do
  sh_proj pm enable "$p" >/dev/null || true
  # Si le paquet a été retiré pour l'utilisateur (pm uninstall -k --user 0)
  # à la main, cette commande le remet.
  sh_proj cmd package install-existing --user 0 "$p" >/dev/null 2>&1 || true
  echo "réactivé : $p"
done
echo "${#paquets[@]} paquet(s) réactivé(s)."
