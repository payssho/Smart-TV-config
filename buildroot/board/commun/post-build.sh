#!/usr/bin/env bash
# Derniers réglages de la racine, communs à la box et au jumeau. Appelé par
# Buildroot après l'installation des paquets ; $1 = dossier de la racine.
set -euo pipefail

racine="$1"

# /data : caches et réglages, sur sa propre partition pour qu'un cache qui
# déborde ne remplisse jamais la racine (issue #45). Repérée par son
# étiquette, donc au même endroit sur la carte SD de la box et sur le
# deuxième disque du jumeau. « nofail » : la télé démarre même sans elle.
if ! grep -q '[[:space:]]/data[[:space:]]' "$racine/etc/fstab"; then
  printf 'LABEL=data\t/data\text4\tdefaults,noatime,nofail,x-systemd.device-timeout=10s\t0\t2\n' \
    >>"$racine/etc/fstab"
fi

# Trace de ce qui a été construit, lisible sur la box (cat /etc/tele/image).
mkdir -p "$racine/etc/tele"
{
  echo "date=$(date -u +%Y-%m-%dT%H:%M:%SZ)"
  echo "depot=$(git -C "$(dirname "$0")" describe --always --dirty 2>/dev/null || echo inconnu)"
  echo "buildroot=${BR2_VERSION_FULL:-inconnue}"
} >"$racine/etc/tele/image"
