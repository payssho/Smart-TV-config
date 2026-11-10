#!/usr/bin/env bash
# Copie le noyau arm64 sous une forme que QEMU sait charger avec -kernel :
# Image brute, Image gzip, ou noyau « EFI zboot » (PE dont la charge utile
# est compressée), que QEMU 8 ne sait pas ouvrir et qu'on décompresse ici.
#
# Usage : extraire-noyau.sh <vmlinuz> <Image de sortie>
set -euo pipefail

entree="$1"
sortie="$2"

if [[ "$(head -c 2 "$entree" | od -An -tx1 | tr -d ' ')" = 1f8b ]]; then
  gzip -dc "$entree" >"$sortie"
elif [[ "$(dd if="$entree" bs=1 skip=4 count=4 2>/dev/null)" = zimg ]]; then
  # En-tête zboot : décalage (octet 8) et taille (octet 12) de la charge,
  # puis le nom du compresseur (octet 24).
  decalage="$(od -An -t u4 -j 8 -N 4 "$entree" | tr -d ' ')"
  longueur="$(od -An -t u4 -j 12 -N 4 "$entree" | tr -d ' ')"
  compression="$(dd if="$entree" bs=1 skip=24 count=8 2>/dev/null | tr -d '\0')"
  charge() { tail -c +"$((decalage + 1))" "$entree" | head -c "$longueur"; }
  case "$compression" in
    gzip) charge | gzip -dc >"$sortie" ;;
    zstd|zstd22) charge | zstd -dc >"$sortie" ;;
    xz) charge | xz -dc >"$sortie" ;;
    *) echo "Compression zboot inconnue : $compression" >&2; exit 1 ;;
  esac
else
  cp "$entree" "$sortie"
fi
