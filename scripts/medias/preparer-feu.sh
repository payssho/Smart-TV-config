#!/usr/bin/env bash
# Refait la vidéo, l'affiche et le son du « Feu de cheminée » à partir des
# médias libres d'origine (crédits et licences : ui/assets/CREDITS.md).
# Usage : scripts/medias/preparer-feu.sh   (git, ffmpeg)
set -euo pipefail

racine="$(cd "$(dirname "$0")/../.." && pwd)"
travail="$(mktemp -d)"
trap 'rm -rf "$travail"' EXIT

# Copies de travail des médias, avec leur provenance documentée.
git clone -q --depth 1 https://github.com/jeremykenedy/hearth-presence "$travail/video"
git clone -q --depth 1 https://github.com/Tafazzolian/still-sounds "$travail/son"
video="$travail/video/media/source/wood-fire.webm"
son="$travail/son/files/fireplace-lit-default.ogg"
assets="$racine/ui/assets"

# Vidéo : 22 s bouclées en 20 s (fondu de 2 s entre la fin et le début),
# couleurs un peu adoucies, H.264 1080p30 sans piste son.
ffmpeg -v error -y -i "$video" -i "$video" -filter_complex \
  "[0:v]trim=2:22,setpts=PTS-STARTPTS,fps=30,format=yuv420p[a];\
[1:v]trim=0:2,setpts=PTS-STARTPTS,fps=30,format=yuv420p[b];\
[a][b]xfade=transition=fade:duration=2:offset=18,eq=saturation=0.88:gamma=0.94,format=yuv420p[v]" \
  -map "[v]" -an -c:v libx264 -preset slow -crf 25 -profile:v high -level 4.0 \
  -movflags +faststart "$assets/videos/feu.mp4"

ffmpeg -v error -y -ss 8 -i "$assets/videos/feu.mp4" -frames:v 1 \
  -vf scale=720:-1 -q:v 4 "$assets/images/feu-affiche.jpg"

# Son : 60 s bouclées en 57 s (fondu de 3 s), volume normalisé.
ffmpeg -v error -y -i "$son" -i "$son" -filter_complex \
  "[0:a]atrim=3:60,asetpts=PTS-STARTPTS[a];[1:a]atrim=0:3,asetpts=PTS-STARTPTS[b];\
[a][b]acrossfade=d=3:c1=tri:c2=tri,loudnorm=I=-20:TP=-2[o]" \
  -map "[o]" -ar 44100 -c:a libmp3lame -b:a 128k "$assets/sons/feu.mp3"

echo "Médias du feu refaits dans $assets"
