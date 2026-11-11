#!/usr/bin/env bash
# Construit l'image de la télé avec Buildroot (ADR 0004, 0023, 0024).
#
# Un build complet prend 30 à 60 minutes et une dizaine de Go : il se lance
# en GitHub Actions (workflow « Image Buildroot ») ou sous WSL2 chez Marius,
# jamais dans le conteneur de l'agent. « --verifier » ne compile rien et
# tient en quelques secondes : il se lance partout.
#
# Usage : scripts/image/construire.sh [options] [cibles make...]
#   --cible NOM       defconfig de buildroot/configs/, sans « _defconfig »
#                     (défaut qemu_aarch64_tv)
#   --sortie DOSSIER  dossier de build (défaut buildroot/output/<cible>)
#   --buildroot DOSSIER  sources de Buildroot (défaut buildroot/output/buildroot-<version>,
#                     clonées à la version de buildroot/version si absentes)
#   --verifier        applique la defconfig et vérifie que Buildroot a gardé
#                     chacune de ses lignes, sans rien compiler
#   cibles make       passées telles quelles à Buildroot (ex. menuconfig,
#                     linux-menuconfig, tele-systeme-rebuild) ; sans cible :
#                     build complet
#
# Variables : BR2_DL_DIR (archives téléchargées, défaut buildroot/output/dl)
# et BR2_CCACHE_DIR (cache de compilation, défaut buildroot/output/ccache),
# à garder d'un build à l'autre.
#
# Résultat : <sortie>/images/Image et rootfs.ext4, plus un dossier
# <sortie>/jumeau/ prêt pour « scripts/jumeau/demarrer.sh --image ».
set -euo pipefail

ici="$(cd "$(dirname "$0")" && pwd)"
depot="$(cd "$ici/../.." && pwd)"
externe="$depot/buildroot"
cible=qemu_aarch64_tv
sortie=""
sources=""
verifier=0
cibles_make=()

while [[ $# -gt 0 ]]; do
  case "$1" in
    --cible) cible="$2"; shift 2 ;;
    --sortie) sortie="$2"; shift 2 ;;
    --buildroot) sources="$2"; shift 2 ;;
    --verifier) verifier=1; shift ;;
    -h|--help) sed -n '2,26p' "$0"; exit 0 ;;
    -*) echo "Option inconnue : $1" >&2; exit 2 ;;
    *) cibles_make+=("$1"); shift ;;
  esac
done

defconfig="$externe/configs/${cible}_defconfig"
[[ -f "$defconfig" ]] || { echo "Cible inconnue : $cible (pas de $defconfig)" >&2; exit 2; }

# shellcheck source-path=SCRIPTDIR source=../../buildroot/version
. "$externe/version"
sortie="${sortie:-$externe/output/$cible}"
sources="${sources:-$externe/output/buildroot-$BUILDROOT_VERSION}"
mkdir -p "$sortie"
sortie="$(cd "$sortie" && pwd)"

# Sources de Buildroot : l'étiquette demandée, et rien d'autre que le commit
# attendu (une étiquette peut être déplacée, pas un commit).
if [[ ! -d "$sources/.git" ]]; then
  echo "== Buildroot $BUILDROOT_VERSION"
  mkdir -p "$(dirname "$sources")"
  git clone --quiet --depth 1 --branch "$BUILDROOT_VERSION" \
    -c advice.detachedHead=false "$BUILDROOT_DEPOT" "$sources"
fi
commit="$(git -C "$sources" rev-parse HEAD)"
if [[ "$commit" != "$BUILDROOT_COMMIT" ]]; then
  echo "Buildroot dans $sources : commit $commit, attendu $BUILDROOT_COMMIT (buildroot/version)" >&2
  exit 1
fi

export BR2_DL_DIR="${BR2_DL_DIR:-$externe/output/dl}"
export BR2_CCACHE_DIR="${BR2_CCACHE_DIR:-$externe/output/ccache}"
br() { make -C "$sources" O="$sortie" BR2_EXTERNAL="$externe" "$@"; }

if [[ ! -f "$sortie/.config" || "$defconfig" -nt "$sortie/.config" || "$verifier" = 1 ]]; then
  br "${cible}_defconfig" >/dev/null
fi

# Buildroot écarte sans rien dire une ligne de defconfig dont le symbole
# n'existe pas (faute de frappe, option renommée) ou dont une dépendance
# manque : on vérifie que chaque ligne a survécu.
perdues=0
while IFS= read -r ligne; do
  if ! grep -qxF -- "$ligne" "$sortie/.config"; then
    echo "Ligne de la defconfig écartée par Buildroot : $ligne" >&2
    perdues=$((perdues + 1))
  fi
done < <(grep -E '^(BR2_[A-Za-z0-9_]+=|# BR2_[A-Za-z0-9_]+ is not set$)' "$defconfig")
[[ "$perdues" -eq 0 ]] || exit 1
# Fichiers nommés par la defconfig : mieux vaut le savoir avant une heure de build.
while IFS= read -r chemin; do
  chemin="${chemin//\$(BR2_EXTERNAL_TELE_PATH)/$externe}"
  [[ "$chemin" = /* ]] || chemin="$sources/$chemin"
  [[ -e "$chemin" ]] || { echo "Fichier de la defconfig introuvable : $chemin" >&2; exit 1; }
done < <(sed -n -E 's/^BR2_(ROOTFS_OVERLAY|ROOTFS_POST_BUILD_SCRIPT|LINUX_KERNEL_CUSTOM_CONFIG_FILE|LINUX_KERNEL_CONFIG_FRAGMENT_FILES|GLOBAL_PATCH_DIR)="(.*)"$/\2/p' "$defconfig" | tr ' ' '\n')

if [[ "$verifier" = 1 ]]; then
  echo "Defconfig $cible : toutes les lignes sont prises en compte par Buildroot $BUILDROOT_VERSION."
  exit 0
fi

if [[ ${#cibles_make[@]} -gt 0 ]]; then
  br "${cibles_make[@]}"
  exit 0
fi

echo "== Build de $cible dans $sortie"
debut=$(date +%s)
br
echo "== Build terminé en $(( ($(date +%s) - debut) / 60 )) min"

# Dossier au format attendu par le jumeau : noyau, racine, fiche d'identité.
if [[ -f "$sortie/images/Image" && -f "$sortie/images/rootfs.ext4" ]]; then
  mkdir -p "$sortie/jumeau"
  ln -f "$sortie/images/Image" "$sortie/jumeau/Image"
  ln -f "$sortie/images/rootfs.ext4" "$sortie/jumeau/racine.ext4"
  {
    cat "$sortie/target/etc/tele/image"
    echo "distribution=buildroot $BUILDROOT_VERSION ($cible)"
    echo "noyau=$(sed -n -E 's/^BR2_LINUX_KERNEL_VERSION="(.*)"$/\1/p' "$sortie/.config")"
    echo "chromium=non"
    echo "interface=non"
    echo "racine_occupee_mo=$(du -sm "$sortie/target" | cut -f1)"
  } >"$sortie/jumeau/image.txt"
  echo "== Image pour le jumeau : $sortie/jumeau"
  cat "$sortie/jumeau/image.txt"
fi
