#!/usr/bin/env bash
# Fonctions partagées des scripts adb du projecteur (ADR 0025).
# À sourcer, pas à lancer. Aucun script n'a besoin du root.

# Dossier où chaque script range rapports, sauvegardes et journaux.
ETAT="${ETAT:-$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/etat}"
LISTE_PROTEGEE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/paquets-proteges.txt"

die() {
  echo "Erreur : $*" >&2
  exit 1
}

# Lance une commande dans le shell du projecteur et retire les \r d'Android.
sh_proj() {
  adb shell "$@" | tr -d '\r'
}

# Vérifie qu'un seul appareil est branché et autorisé.
verifier_adb() {
  command -v adb >/dev/null || die "adb introuvable (paquet android-tools ou platform-tools)."
  local n
  n="$(adb devices | awk 'NR > 1 && $2 == "device"' | wc -l)"
  if [[ "$n" -eq 0 ]]; then
    die "aucun appareil autorisé. Activer le débogage USB/réseau, puis : adb connect <ip>:5555"
  elif [[ "$n" -gt 1 ]]; then
    [[ -n "${ANDROID_SERIAL:-}" ]] || die "plusieurs appareils : préciser ANDROID_SERIAL."
  fi
  mkdir -p "$ETAT"
}

# Lit une liste de paquets : un par ligne, « # » commente, motifs glob permis
# dans la liste protégée.
lire_liste() {
  sed -e 's/#.*//' -e 's/[[:space:]]//g' "$1" | grep -v '^$' || true
}

# Vrai si le paquet correspond à un motif de la liste protégée.
est_protege() {
  local paquet="$1" motif
  while IFS= read -r motif; do
    # shellcheck disable=SC2053 # le motif est un glob voulu
    [[ "$paquet" == $motif ]] && return 0
  done < <(lire_liste "$LISTE_PROTEGEE")
  return 1
}

horodatage() {
  date +%Y%m%d-%H%M%S
}
