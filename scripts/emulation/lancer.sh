#!/usr/bin/env bash
# Banc d'émulation mémoire : compare la box à 2 Go et à 4 Go.
#
# Chaque profil tourne dans un conteneur Docker dont la mémoire est bridée à
# ce que Linux voit vraiment sur la S905X3 (RAM moins la zone CMA vidéo, les
# réservations du firmware et, sur 4 Go, le trou d'adressage des registres).
# Le conteneur lance la vraie app Flutter (build Linux), Chromium sur une page
# lourde façon YouTube TV, un décodage logiciel 1080p60 façon Twitch, le hub
# et une mise à jour en fond, puis écrit un rapport JSON par profil.
#
# Usage : scripts/emulation/lancer.sh [--palier SECONDES] [--profils "2go 4go"]
# Prérequis : Docker, Flutter (build Linux), ffmpeg, un Chromium (variable
# CHROME, sinon celui de Playwright est cherché).
# Aucun accès à la box : tout se passe sur le poste ou en CI.
set -euo pipefail

ici="$(cd "$(dirname "$0")" && pwd)"
racine="$(cd "$ici/../.." && pwd)"
palier=40
profils="2go 4go"

while [[ $# -gt 0 ]]; do
  case "$1" in
    --palier) palier="$2"; shift 2 ;;
    --profils) profils="$2"; shift 2 ;;
    -h|--help) sed -n '2,16p' "$0"; exit 0 ;;
    *) echo "Option inconnue : $1" >&2; exit 2 ;;
  esac
done

# Mémoire vue par Linux, en Mo (détail dans docs/emulation-memoire.md).
limite_mo() {
  case "$1" in
    2go) echo 1700 ;;  # 2048 - 256 (CMA) - ~90 (firmware, noyau)
    4go) echo 3500 ;;  # 4096 - 256 (CMA) - ~90 - ~250 (trou d'adressage)
    *) echo "Profil inconnu : $1" >&2; exit 2 ;;
  esac
}

chrome="${CHROME:-}"
if [[ -z "$chrome" ]]; then
  chrome="$(find /opt/pw-browsers "$HOME/.cache/ms-playwright" -type f -name chrome \
    -path '*chrome-linux*' 2>/dev/null | grep -v headless | head -n1 || true)"
fi
if [[ ! -x "$chrome" ]]; then
  echo "Chromium introuvable : définir CHROME=/chemin/vers/chrome" >&2
  echo "(par exemple après « npx playwright install chromium »)." >&2
  exit 1
fi

bundle="$racine/ui/build/linux/x64/release/bundle"
echo "== Build Linux de l'interface (avec repère de première image)"
(cd "$racine/ui" && flutter build linux --release --dart-define=TRACE_DEMARRAGE=true)

medias="$ici/.medias"
mkdir -p "$medias/vignettes"
if [[ ! -f "$medias/twitch-1080p60.mp4" ]]; then
  echo "== Génération des médias de test"
  # Flux 1080p60 H.264 à ~8 Mbit/s, comme un direct Twitch « Source ».
  ffmpeg -hide_banner -loglevel error -y -f lavfi -i testsrc2=size=1920x1080:rate=60 \
    -vf "noise=alls=18:allf=t" -t 20 -c:v libx264 -preset veryfast -profile:v high \
    -b:v 8M -maxrate 8M -bufsize 16M -pix_fmt yuv420p "$medias/twitch-1080p60.mp4"
  # Vidéo VP9 1080p30 (le codec de YouTube) pour Chromium.
  ffmpeg -hide_banner -loglevel error -y -f lavfi -i testsrc2=size=1920x1080:rate=30 \
    -vf "noise=alls=12:allf=t" -t 20 -c:v libvpx-vp9 -deadline realtime -cpu-used 8 \
    -b:v 4M -row-mt 1 "$medias/youtube-1080p.webm"
  for i in $(seq -w 1 40); do
    ffmpeg -hide_banner -loglevel error -y -f lavfi \
      -i "testsrc2=size=640x360:rate=1,hue=h=$((10#$i * 9))" -frames:v 1 -q:v 3 \
      "$medias/vignettes/$i.jpg"
  done
  cp "$ici/page-youtube.html" "$medias/"
  # Faux bundle de mise à jour (600 Mo), lu en boucle pendant le pire cas.
  head -c 600M /dev/urandom >"$medias/bundle.bin"
fi
cp "$ici/page-youtube.html" "$medias/"

# Image reconstruite seulement si absente ou si le Dockerfile a changé.
empreinte="$(sha256sum "$ici/Dockerfile" | cut -c1-12)"
if [[ "$(docker image inspect -f '{{index .Config.Labels "empreinte"}}' tele-banc 2>/dev/null)" != "$empreinte" ]]; then
  echo "== Image Docker du banc"
  if ! docker build --network host -q --label "empreinte=$empreinte" -t tele-banc "$ici" >/dev/null; then
    docker image inspect tele-banc >/dev/null 2>&1 || exit 1
    echo "Reconstruction impossible (registre ?) : on garde l'image existante." >&2
  fi
fi

sortie="$ici/resultats/$(date +%Y-%m-%d)"
mkdir -p "$sortie"
for profil in $profils; do
  limite="$(limite_mo "$profil")"
  echo "== Profil $profil : ${limite} Mo vus par Linux, paliers de ${palier} s"
  docker run --rm --name "tele-banc-$profil" \
    --memory="${limite}m" --memory-swap="${limite}m" --cpus=4 --shm-size=64m \
    -e PROFIL="$profil" -e LIMITE_MO="$limite" -e PALIER_S="$palier" \
    -e CHROME="/chrome/$(basename "$chrome")" \
    -v "$(dirname "$chrome"):/chrome:ro" \
    -v "$bundle:/ui:ro" \
    -v "$medias:/medias:ro" \
    -v "$ici/banc.py:/banc/banc.py:ro" \
    -v "$sortie:/resultats" \
    tele-banc
done

python3 "$ici/rapport.py" "$sortie" >"$sortie/rapport.md"
echo "== Rapport : $sortie/rapport.md"
