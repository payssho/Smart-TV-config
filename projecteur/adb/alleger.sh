#!/usr/bin/env bash
# Désactive les paquets de paquets-a-alleger.txt pour l'utilisateur 0, sans
# root et de façon réversible (ADR 0025). Par défaut, simule seulement.
#   projecteur/adb/alleger.sh              # montre ce qui serait fait
#   projecteur/adb/alleger.sh --appliquer  # le fait, et tient un journal
# Annuler : projecteur/adb/restaurer.sh
set -euo pipefail
# shellcheck source-path=SCRIPTDIR source=commun.sh
source "$(dirname "$0")/commun.sh"

appliquer=false
[[ "${1:-}" == "--appliquer" ]] && appliquer=true
liste="${LISTE_ALLEGER:-$(dirname "$0")/paquets-a-alleger.txt}"
verifier_adb

mapfile -t paquets < <(lire_liste "$liste")
[[ ${#paquets[@]} -gt 0 ]] || die "$liste est vide : la remplir après inventaire.sh."

installes="$(sh_proj pm list packages | sed 's/^package://')"
journal="$ETAT/journal-allegement-$(horodatage).txt"
$appliquer && echo "# Paquets désactivés le $(date -Iseconds)" >"$journal"

for p in "${paquets[@]}"; do
  if est_protege "$p"; then
    echo "protégé, ignoré : $p"
  elif ! grep -qxF "$p" <<<"$installes"; then
    echo "absent           : $p"
  elif ! $appliquer; then
    echo "à désactiver     : $p"
  elif sh_proj pm disable-user --user 0 "$p" | grep -q 'disabled-user'; then
    echo "$p" >>"$journal"
    echo "désactivé        : $p"
  else
    echo "refusé           : $p (le système l'interdit, on passe)"
  fi
done

if $appliquer; then
  echo "Journal : $journal (restaurer.sh $journal pour revenir en arrière)"
else
  echo "Simulation seulement. Relancer avec --appliquer pour désactiver."
fi
