#!/usr/bin/env bash
# Construit l'image du jumeau numérique de la box (ADR 0019) : un système
# Linux arm64 complet (noyau, systemd, Chromium, cage, ffmpeg) avec nos
# scripts système (systeme/) et, si on la donne, l'app Flutter compilée
# pour arm64. demarrer.sh la fait ensuite tourner dans QEMU en 2 Go ou 4 Go.
#
# Usage : scripts/jumeau/construire-image.sh [--appli DOSSIER] [--sortie DOSSIER]
#           [--distribution debian|ubuntu] [--taille 6G]
#   --appli         bundle Linux arm64 de l'app (ui/build/linux/arm64/release/bundle)
#   --distribution  debian (défaut : Chromium inclus) ; ubuntu seulement en
#                   repli quand deb.debian.org est injoignable (pas de Chromium,
#                   Ubuntu ne le livre qu'en snap)
#
# Prérequis : mmdebstrap, e2fsprogs, root (relance sudo tout seul) et, sur
# un poste x86, qemu-user-static + binfmt pour exécuter l'arm64. En CI :
# runner arm64 natif, environ 10 minutes. Rien ne touche la box.
set -euo pipefail

ici="$(cd "$(dirname "$0")" && pwd)"
racine_depot="$(cd "$ici/../.." && pwd)"
appli=""
sortie="$ici/.image"
distribution=debian
taille=6G

while [[ $# -gt 0 ]]; do
  case "$1" in
    --appli) appli="$(cd "$2" && pwd)"; shift 2 ;;
    --sortie) mkdir -p "$2"; sortie="$(cd "$2" && pwd)"; shift 2 ;;
    --distribution) distribution="$2"; shift 2 ;;
    --taille) taille="$2"; shift 2 ;;
    -h|--help) sed -n '2,18p' "$0"; exit 0 ;;
    *) echo "Option inconnue : $1" >&2; exit 2 ;;
  esac
done

if [[ $EUID -ne 0 ]]; then
  args=(--sortie "$sortie" --distribution "$distribution" --taille "$taille")
  [[ -n "$appli" ]] && args+=(--appli "$appli")
  exec sudo -E "$0" "${args[@]}"
fi

# Paquets communs : de quoi faire tourner l'interface (cage + GTK + Mesa en
# rendu logiciel), le lecteur (ffmpeg) et le scénario (python3).
paquets=(
  systemd-sysv udev kmod dbus initramfs-tools util-linux procps iproute2
  e2fsprogs python3 ffmpeg cage seatd fonts-dejavu-core
  libgtk-3-0t64 libegl1 libgles2 libgl1-mesa-dri libegl-mesa0 libgbm1
)
case "$distribution" in
  debian)
    suite=trixie
    miroir=http://deb.debian.org/debian
    composants=main
    paquets+=(linux-image-arm64 chromium)
    ;;
  ubuntu)
    suite=noble
    miroir=http://ports.ubuntu.com/ubuntu-ports
    composants=main,universe
    # linux-image-extra-virtual : modules « extra », dont zram.
    paquets+=(linux-image-virtual linux-image-extra-virtual)
    ;;
  *) echo "Distribution inconnue : $distribution" >&2; exit 2 ;;
esac

travail="$sortie/racine"
rm -rf "$travail"
mkdir -p "$sortie"

echo "== Système $distribution $suite arm64 (mmdebstrap)"
# $1 et $JUMEAU_DEPOT du crochet sont développés par mmdebstrap, pas ici.
# shellcheck disable=SC2016
JUMEAU_DEPOT="$racine_depot" JUMEAU_APPLI="$appli" \
  mmdebstrap --mode=root --arch=arm64 --variant=apt --components="$composants" \
  --include="$(IFS=,; echo "${paquets[*]}")" \
  --customize-hook='"$JUMEAU_DEPOT/scripts/jumeau/personnaliser.sh" "$1"' \
  "$suite" "$travail" "$miroir"

echo "== Noyau et initramfs"
noyau="$(find "$travail/boot" -maxdepth 1 -name 'vmlinuz-*' | sort -V | tail -n1)"
initrd="$(find "$travail/boot" -maxdepth 1 -name 'initrd.img-*' | sort -V | tail -n1)"
[[ -n "$noyau" && -n "$initrd" ]] || { echo "Noyau ou initramfs introuvable dans /boot" >&2; exit 1; }
"$ici/extraire-noyau.sh" "$noyau" "$sortie/Image"
cp "$initrd" "$sortie/initrd.img"

echo "== Disque racine ($taille, ext4)"
rm -f "$sortie/racine.ext4"
mke2fs -q -t ext4 -L racine -d "$travail" "$sortie/racine.ext4" "$taille"

{
  echo "date=$(date -u +%Y-%m-%dT%H:%M:%SZ)"
  echo "distribution=$distribution $suite"
  echo "noyau=$(basename "$noyau")"
  echo "chromium=$([[ -x "$travail/usr/bin/chromium" ]] && echo oui || echo non)"
  echo "interface=$([[ -x "$travail/opt/tele/ui/tele" ]] && echo oui || echo non)"
} >"$sortie/image.txt"
rm -rf "$travail"
chown -R "${SUDO_UID:-0}:${SUDO_GID:-0}" "$sortie"
echo "== Image prête dans $sortie"
cat "$sortie/image.txt"
