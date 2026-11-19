#!/usr/bin/env bash
# Installe le lanceur « Veilleuse » et le choisit comme écran d'accueil, sans
# root (ADR 0025). Le lanceur d'origine reste installé : il porte peut-être
# le trapèze et la mise au point.
#   projecteur/adb/installer-lanceur.sh chemin/app-release.apk
#   projecteur/adb/installer-lanceur.sh --origine   # revient au lanceur d'origine
set -euo pipefail
# shellcheck source-path=SCRIPTDIR source=commun.sh
source "$(dirname "$0")/commun.sh"
verifier_adb

composant="fr.veilleuse.lanceur/.MainActivity"
fichier_origine="$ETAT/lanceur-origine.txt"

if [[ "${1:-}" == "--origine" ]]; then
  [[ -f "$fichier_origine" ]] || die "lanceur d'origine inconnu ($fichier_origine absent)."
  origine="$(cat "$fichier_origine")"
  if ! sh_proj cmd package set-home-activity "$origine" | grep -qi success; then
    sh_proj cmd role add-role-holder android.app.role.HOME "${origine%%/*}"
  fi
  echo "Écran d'accueil remis sur $origine."
  exit 0
fi

apk="${1:-}"
[[ -f "$apk" ]] || die "donner le chemin de l'APK (artefact « lanceur-veilleuse-apk » de la CI)."

# Retient le lanceur actuel, une seule fois, pour pouvoir y revenir.
if [[ ! -f "$fichier_origine" ]]; then
  sh_proj cmd package resolve-activity --brief \
    -a android.intent.action.MAIN -c android.intent.category.HOME \
    | tail -n 1 >"$fichier_origine"
  echo "Lanceur d'origine noté : $(cat "$fichier_origine")"
fi

adb install -r "$apk"
# Selon les firmwares, l'une ou l'autre commande est acceptée pour « shell ».
if ! sh_proj cmd package set-home-activity "$composant" | grep -qi success; then
  sh_proj cmd role add-role-holder android.app.role.HOME "${composant%%/*}"
fi
sh_proj input keyevent KEYCODE_HOME
echo "Veilleuse est l'écran d'accueil. Retour arrière : $0 --origine"
