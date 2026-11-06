#!/usr/bin/env bash
# Construit la prévisualisation de l'interface, publiable comme page Claude :
# la vraie app Flutter compilée pour le web (CanvasKit embarqué, aucune
# ressource externe), la page hôte (télé 1080p + télécommande) et les
# dernières mesures du banc mémoire.
#
# Usage : scripts/previsu/construire.sh   → build/previsu/
# Publier : page build/previsu/index.html, fichiers listés dans
# build/previsu/fichiers.txt (voir maquette/README.md).
set -euo pipefail

ici="$(cd "$(dirname "$0")" && pwd)"
racine="$(cd "$ici/../.." && pwd)"
sortie="$racine/build/previsu"

echo "== Build web de l'interface"
(cd "$racine/ui" && flutter build web --release --no-web-resources-cdn)

rm -rf "$sortie"
mkdir -p "$sortie/app"
web="$racine/ui/build/web"
# Seulement ce qui sert au rendu CanvasKit : pas de symboles de débogage ni
# des variantes skwasm/wimp (build JS, pas wasm).
(cd "$web" && find . -type f \
  ! -name '*.symbols' ! -path './canvaskit/skwasm*' ! -path './canvaskit/wimp*' \
  ! -path './canvaskit/webparagraph/*' ! -name 'flutter_service_worker.js' \
  ! -name 'NOTICES' ! -name '.last_build_id' -print0 | cpio -0pdm --quiet "$sortie/app")
# Chemins relatifs : la page est servie sous une adresse inconnue d'avance.
sed -i 's|<base href="/">|<base href="./">|' "$sortie/app/index.html"
cp "$ici/page.html" "$sortie/index.html"

dernier="$(find "$racine/scripts/emulation/resultats" -mindepth 1 -maxdepth 1 -type d 2>/dev/null | sort | tail -n1)"
if [[ -n "$dernier" ]]; then
  python3 - "$dernier" "$sortie/banc.json" <<'PY'
import json, pathlib, sys
dossier = pathlib.Path(sys.argv[1])
profils = [json.loads(p.read_text()) for p in sorted(dossier.glob("*go.json"))]
verdict = dossier / "verdict.md"
lignes = [l.strip() for l in verdict.read_text().split("\n\n") if l.strip()] if verdict.exists() else []
json.dump({"date": dossier.name, "profils": profils, "verdict": lignes},
          open(sys.argv[2], "w"), ensure_ascii=False)
PY
fi

(cd "$sortie" && find . -type f ! -name index.html ! -name fichiers.txt | sed 's|^\./||' | sort >fichiers.txt)
echo "== Prévisu prête : $sortie ($(du -sh "$sortie" | cut -f1))"
