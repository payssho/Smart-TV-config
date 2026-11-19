#!/usr/bin/env bash
# Inventaire du projecteur, en LECTURE SEULE (ADR 0025) : firmware, mémoire,
# paquets, lanceur, réglages qu'on touchera plus tard. Rien n'est modifié.
# Usage : projecteur/adb/inventaire.sh   (puis envoyer le dossier produit)
set -euo pipefail
# shellcheck source-path=SCRIPTDIR source=commun.sh
source "$(dirname "$0")/commun.sh"
verifier_adb

dossier="$ETAT/inventaire-$(horodatage)"
mkdir -p "$dossier"
echo "Inventaire dans $dossier"

{
  echo "== Firmware"
  for p in ro.product.manufacturer ro.product.model ro.product.device \
    ro.board.platform ro.hardware ro.soc.model ro.build.version.release \
    ro.build.version.sdk ro.build.display.id ro.build.fingerprint \
    ro.build.version.security_patch ro.config.low_ram ro.sf.lcd_density \
    ro.product.cpu.abilist; do
    printf '%s = %s\n' "$p" "$(sh_proj getprop "$p")"
  done
  echo
  echo "== Écran"
  sh_proj wm size
  sh_proj wm density
  echo
  echo "== Mémoire"
  sh_proj cat /proc/meminfo | head -n 6
  sh_proj cat /proc/swaps
  echo
  echo "== Stockage"
  sh_proj df -h /data
  echo
  echo "== Lanceur par défaut"
  sh_proj cmd package resolve-activity --brief \
    -a android.intent.action.MAIN -c android.intent.category.HOME | tail -n 1
  echo
  echo "== DRM (Widevine)"
  sh_proj dumpsys media.drm 2>/dev/null | grep -iE 'widevine|securityLevel' | head -n 5 || true
} >"$dossier/resume.txt"

sh_proj pm list packages -s | sed 's/^package://' | sort >"$dossier/paquets-systeme.txt"
sh_proj pm list packages -3 | sed 's/^package://' | sort >"$dossier/paquets-tiers.txt"
sh_proj pm list packages -d | sed 's/^package://' | sort >"$dossier/paquets-desactives.txt"

# Qui mange la mémoire au repos (les 40 premiers par PSS).
sh_proj dumpsys meminfo | sed -n '/Total PSS by process/,/Total PSS by OOM/p' \
  | head -n 42 >"$dossier/memoire-par-processus.txt"

# Applis lancées au démarrage : candidates naturelles à l'allègement.
sh_proj cmd package query-receivers --brief \
  -a android.intent.action.BOOT_COMPLETED 2>/dev/null \
  | grep -v '^Receiver' | sort -u >"$dossier/demarrage-automatique.txt" || true

# Valeurs actuelles des réglages que regler-perf.sh sait changer.
{
  for cle in global:window_animation_scale global:transition_animation_scale \
    global:animator_duration_scale global:wifi_scan_always_enabled \
    global:ble_scan_always_enabled secure:screensaver_enabled; do
    printf '%s = %s\n' "$cle" "$(sh_proj settings get "${cle%%:*}" "${cle#*:}")"
  done
} >"$dossier/reglages.txt"

# Paquets système qui ne sont pas protégés : la liste où piocher.
while IFS= read -r p; do
  est_protege "$p" || echo "$p"
done <"$dossier/paquets-systeme.txt" >"$dossier/candidats-allegement.txt"

cat "$dossier/resume.txt"
echo
echo "$(wc -l <"$dossier/paquets-systeme.txt") paquets système, dont" \
  "$(wc -l <"$dossier/candidats-allegement.txt") non protégés (candidats-allegement.txt)."
