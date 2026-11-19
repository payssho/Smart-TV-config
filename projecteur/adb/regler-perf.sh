#!/usr/bin/env bash
# Réglages de performance sans root (ADR 0025), réversibles.
#   projecteur/adb/regler-perf.sh              # montre valeurs actuelles et cibles
#   projecteur/adb/regler-perf.sh --appliquer  # sauvegarde puis applique
#   projecteur/adb/regler-perf.sh --annuler    # remet la dernière sauvegarde
#   projecteur/adb/regler-perf.sh --entretien  # caches + compilation (long)
set -euo pipefail
# shellcheck source-path=SCRIPTDIR source=commun.sh
source "$(dirname "$0")/commun.sh"
verifier_adb

# espace:clé=valeur cible. Animations à 0,5 : l'interface paraît deux fois plus
# vive sans rien couper ; scans permanents coupés : moins de réveils radio.
cibles=(
  global:window_animation_scale=0.5
  global:transition_animation_scale=0.5
  global:animator_duration_scale=0.5
  global:wifi_scan_always_enabled=0
  global:ble_scan_always_enabled=0
)

mode="${1:-}"
case "$mode" in
  "")
    for c in "${cibles[@]}"; do
      cle="${c%%=*}"
      printf '%-40s actuel %-6s cible %s\n' "$cle" \
        "$(sh_proj settings get "${cle%%:*}" "${cle#*:}")" "${c#*=}"
    done
    echo "Simulation seulement. --appliquer pour régler."
    ;;
  --appliquer)
    sauvegarde="$ETAT/reglages-$(horodatage).txt"
    for c in "${cibles[@]}"; do
      cle="${c%%=*}"
      echo "$cle=$(sh_proj settings get "${cle%%:*}" "${cle#*:}")" >>"$sauvegarde"
      sh_proj settings put "${cle%%:*}" "${cle#*:}" "${c#*=}"
      echo "réglé : $cle = ${c#*=}"
    done
    echo "Anciennes valeurs : $sauvegarde"
    ;;
  --annuler)
    sauvegarde="$(find "$ETAT" -maxdepth 1 -name 'reglages-*.txt' | sort | tail -n 1)"
    [[ -f "$sauvegarde" ]] || die "aucune sauvegarde de réglages dans $ETAT."
    while IFS= read -r ligne; do
      cle="${ligne%%=*}"
      valeur="${ligne#*=}"
      if [[ "$valeur" == "null" ]]; then
        sh_proj settings delete "${cle%%:*}" "${cle#*:}" >/dev/null
      else
        sh_proj settings put "${cle%%:*}" "${cle#*:}" "$valeur"
      fi
      echo "remis : $cle = $valeur"
    done <"$sauvegarde"
    ;;
  --entretien)
    # Vide les caches des applis (pas leurs données), puis compile ce qui a
    # tourné (profil) : démarrages d'applis plus rapides. Plusieurs minutes.
    sh_proj pm trim-caches 64G
    echo "caches vidés"
    sh_proj cmd package bg-dexopt-job
    echo "compilation anticipée faite"
    ;;
  *)
    die "option inconnue : $mode"
    ;;
esac
