#!/usr/bin/env bash
# Génère les médias du scénario du jumeau (une fois, réutilisés ensuite) :
# flux 1080p60 H.264 façon Twitch, vidéo VP9 et vignettes pour la page
# façon YouTube TV du banc (scripts/emulation/page-youtube.html), faux
# bundle de mise à jour. Tout est synthétique : aucun contenu tiers.
#
# Usage : medias.sh <dossier>
set -euo pipefail

dossier="$1"
page="$(cd "$(dirname "$0")/../emulation" && pwd)/page-youtube.html"
mkdir -p "$dossier/vignettes"
cp "$page" "$dossier/"
[[ -f "$dossier/pret" ]] && exit 0
command -v ffmpeg >/dev/null || { echo "ffmpeg manquant" >&2; exit 1; }

echo "== Génération des médias du jumeau"
ff() { ffmpeg -hide_banner -loglevel error -y "$@"; }
ff -f lavfi -i testsrc2=size=1920x1080:rate=60 -vf "noise=alls=18:allf=t" -t 20 \
  -c:v libx264 -preset veryfast -profile:v high -b:v 8M -maxrate 8M -bufsize 16M \
  -pix_fmt yuv420p "$dossier/twitch-1080p60.mp4"
ff -f lavfi -i testsrc2=size=1920x1080:rate=30 -vf "noise=alls=12:allf=t" -t 20 \
  -c:v libvpx-vp9 -deadline realtime -cpu-used 8 -b:v 4M -row-mt 1 "$dossier/youtube-1080p.webm"
for i in $(seq -w 1 40); do
  ff -f lavfi -i "testsrc2=size=640x360:rate=1,hue=h=$((10#$i * 9))" -frames:v 1 -q:v 3 \
    "$dossier/vignettes/$i.jpg"
done
head -c 600M /dev/urandom >"$dossier/bundle.bin"
touch "$dossier/pret"
