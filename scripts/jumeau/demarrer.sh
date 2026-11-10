#!/usr/bin/env bash
# Démarre le jumeau numérique de la box dans QEMU (ADR 0019).
#
# La machine imite la S905X3 là où ça compte pour nos tests : 4 cœurs
# Cortex-A55, la RAM que Linux voit vraiment sur une box de 2 Go ou 4 Go,
# une carte microSD A1 (débit et IOPS bridés), un écran 1080p (virtio-gpu),
# un clavier (la future télécommande evdev). Elle n'imite pas le GPU Mali,
# le décodeur vidéo, le CEC, l'infrarouge ni l'eMMC (voir ADR 0019).
#
# Usage : scripts/jumeau/demarrer.sh --profil 2go|4go [options]
#   --scenario NOM   complet | fumee : joue le scénario puis s'éteint.
#                    Sans scénario : console série interactive (root sans
#                    mot de passe), Ctrl-a x pour quitter.
#   --palier S       durée d'un palier du scénario, en secondes (défaut 60)
#   --image DOSSIER  image de construire-image.sh (défaut scripts/jumeau/.image)
#   --sortie DOSSIER rapports et captures (défaut scripts/jumeau/resultats/AAAA-MM-JJ)
#   --accel MODE     auto | kvm | tcg (défaut auto : KVM si hôte arm64 avec /dev/kvm)
#   --delai MIN      arrêt forcé au bout de MIN minutes (défaut 120)
set -euo pipefail

ici="$(cd "$(dirname "$0")" && pwd)"
profil=""
scenario=""
palier=60
image="$ici/.image"
sortie="$ici/resultats/$(date +%Y-%m-%d)"
accel=auto
delai=120

while [[ $# -gt 0 ]]; do
  case "$1" in
    --profil) profil="$2"; shift 2 ;;
    --scenario) scenario="$2"; shift 2 ;;
    --palier) palier="$2"; shift 2 ;;
    --image) image="$2"; shift 2 ;;
    --sortie) sortie="$2"; shift 2 ;;
    --accel) accel="$2"; shift 2 ;;
    --delai) delai="$2"; shift 2 ;;
    -h|--help) sed -n '2,22p' "$0"; exit 0 ;;
    *) echo "Option inconnue : $1" >&2; exit 2 ;;
  esac
done

# RAM physique, et mémoire laissée à Linux (mem=) une fois retirés :
#   - la zone CMA du décodeur vidéo et de l'affichage (256 Mo, comptée
#     comme toujours prise : le cas défavorable) ;
#   - le firmware de démarrage et du moniteur sécurisé (~64 Mo) ;
#   - sur 4 Go, le trou d'adressage des registres (~256 Mo).
# À recaler sur la vraie box avec scripts/materiel/diagnostic.sh (#43).
case "$profil" in
  2go) ram=2048; mem_linux=1728 ;;
  4go) ram=4096; mem_linux=3520 ;;
  *) echo "Profil attendu : --profil 2go ou --profil 4go" >&2; exit 2 ;;
esac

for f in Image initrd.img racine.ext4; do
  [[ -f "$image/$f" ]] || { echo "Image incomplète ($image/$f) : lancer construire-image.sh" >&2; exit 1; }
done
command -v qemu-system-aarch64 >/dev/null || { echo "qemu-system-aarch64 manquant (paquet qemu-system-arm)" >&2; exit 1; }

if [[ "$accel" = auto ]]; then
  if [[ "$(uname -m)" = aarch64 && -w /dev/kvm ]]; then accel=kvm; else accel=tcg; fi
fi
if [[ "$accel" = kvm ]]; then
  # KVM ne sait pas déguiser le processeur hôte en Cortex-A55.
  cpu=(-accel kvm -cpu host)
else
  # shellcheck disable=SC2054 # les virgules font partie des options QEMU.
  cpu=(-accel tcg,thread=multi -cpu cortex-a55)
fi

mkdir -p "$sortie"
sortie="$(cd "$sortie" && pwd)"
travail="$(mktemp -d)"
trap 'rm -rf "$travail"' EXIT

# Chaque démarrage part d'une racine neuve : les écritures vont dans une
# surcouche jetable, l'image construite reste intacte.
qemu-img create -q -f qcow2 -F raw -b "$(cd "$image" && pwd)/racine.ext4" "$travail/racine.qcow2"
# /data (caches, issue #45) : disque séparé, neuf à chaque fois.
truncate -s 2G "$travail/data.ext4"
mke2fs -q -t ext4 -L data "$travail/data.ext4"

# microSD A1 dans le lecteur SD de la S905X3 : ~22 Mo/s en lecture,
# ~10 Mo/s en écriture, 1 500 / 500 IOPS (minimums de la classe A1).
# Les deux disques partagent la même carte, donc le même budget.
sd="throttling.group=sd,throttling.bps-read=23068672,throttling.bps-write=10485760"
sd="$sd,throttling.iops-read=1500,throttling.iops-write=500"

medias="${MEDIAS:-$ici/.medias}"
[[ -n "$scenario" ]] && "$ici/medias.sh" "$medias"
mkdir -p "$medias"

cmdline="root=/dev/vda rw console=ttyAMA0 mem=${mem_linux}M tele.profil=$profil"
[[ -n "$scenario" ]] && cmdline="$cmdline quiet tele.scenario=$scenario tele.palier=$palier"

# shellcheck disable=SC2054 # idem.
qemu=(
  qemu-system-aarch64 -machine virt "${cpu[@]}" -smp 4 -m "$ram"
  -kernel "$image/Image" -initrd "$image/initrd.img" -append "$cmdline"
  -drive "file=$travail/racine.qcow2,if=none,id=racine,format=qcow2,$sd"
  -device virtio-blk-pci,drive=racine
  -drive "file=$travail/data.ext4,if=none,id=data,format=raw,$sd"
  -device virtio-blk-pci,drive=data
  -device virtio-gpu-pci,xres=1920,yres=1080 -display none
  -device virtio-keyboard-pci
  -device virtio-rng-pci
  -nic user,model=virtio-net-pci
  -virtfs "local,path=$medias,mount_tag=medias,security_model=none,readonly=on"
  -virtfs "local,path=$sortie,mount_tag=resultats,security_model=none"
  -qmp "unix:$travail/qmp.sock,server=on,wait=off"
  -no-reboot
)

echo "== Jumeau $profil : $ram Mo de RAM, $mem_linux Mo laissés à Linux, accélération $accel"
if [[ -z "$scenario" ]]; then
  exec "${qemu[@]}" -serial mon:stdio
fi

journal="$sortie/serie-$profil.txt"
rm -f "$sortie/$profil.json" "$sortie/code-sortie-$profil"
python3 "$ici/captures.py" "$travail/qmp.sock" "$sortie" &
captures=$!
debut=$(date +%s)
code=0
timeout "${delai}m" "${qemu[@]}" -serial "file:$journal" -monitor none || code=$?
kill "$captures" 2>/dev/null || true
echo "== Jumeau $profil arrêté après $(( ($(date +%s) - debut) / 60 )) min (code QEMU $code)"

if [[ ! -f "$sortie/$profil.json" ]]; then
  echo "Pas de rapport : voir $journal" >&2
  tail -n 40 "$journal" >&2 || true
  exit 1
fi
exit "$(cat "$sortie/code-sortie-$profil" 2>/dev/null || echo 1)"
