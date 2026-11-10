#!/usr/bin/env bash
# Tests des scripts système de la box (tele-memoire, tele-entretien,
# tele-role), joués sur une fausse racine : faux /proc, faux /sys et
# commandes système remplacées par des doublures. Rapide (quelques
# secondes), sans root, sans la box ni le jumeau.
#
# Usage : systeme/tests/tester.sh
#         TELE_SH="busybox sh" PATH=<outils BusyBox>:$PATH systeme/tests/tester.sh
set -euo pipefail

ici="$(cd "$(dirname "$0")" && pwd)"
systeme="$(cd "$ici/.." && pwd)"
reussis=0
rates=0

ok() { reussis=$((reussis + 1)); echo "  ok   $1"; }
ko() { rates=$((rates + 1)); echo "  RATÉ $1" >&2; }
verifier() { # verifier "description" commande...
  local d="$1"; shift
  if "$@"; then ok "$d"; else ko "$d"; fi
}

# Fausse racine d'une box avec une RAM donnée (Mo de MemTotal).
fausse_racine() {
  local total_mo="$1"
  racine="$(mktemp -d)"
  mkdir -p "$racine"/{proc/sys/vm,proc/pressure,proc/self,sys/kernel/mm/lru_gen,dev,run,var/log/tele,data,bin}
  mkdir -p "$racine/etc/tele" "$racine/usr/lib/tele"
  cp "$systeme/etc/tele/memoire.conf" "$racine/etc/tele/"
  cp "$systeme/usr/lib/tele/commun.sh" "$racine/usr/lib/tele/"
  cat >"$racine/proc/meminfo" <<EOF
MemTotal:       $((total_mo * 1024)) kB
MemFree:        $((total_mo * 512)) kB
MemAvailable:   $((total_mo * 700)) kB
EOF
  for r in swappiness page-cluster watermark_scale_factor dirty_background_bytes dirty_bytes compact_memory; do
    echo 0 >"$racine/proc/sys/vm/$r"
  done
  echo n >"$racine/sys/kernel/mm/lru_gen/enabled"
  echo 0 >"$racine/sys/kernel/mm/lru_gen/min_ttl_ms"
  echo 0 >"$racine/proc/self/oom_score_adj"
  echo "Filename Type Size Used Priority" >"$racine/proc/swaps"
  for p in cpu io memory; do
    echo "some avg10=0.00 avg60=0.00 avg300=0.00 total=0" >"$racine/proc/pressure/$p"
  done

  # Doublures des commandes système : elles écrivent dans la fausse racine
  # et notent leur appel dans appels.log.
  local b="$racine/bin"
  cat >"$b/modprobe" <<EOF
#!/bin/sh
echo "modprobe \$*" >>"$racine/appels.log"
mkdir -p "$racine/sys/block/zram0"
: >"$racine/sys/block/zram0/comp_algorithm"
: >"$racine/sys/block/zram0/disksize"
EOF
  cat >"$b/mkswap" <<EOF
#!/bin/sh
echo "mkswap \$*" >>"$racine/appels.log"
EOF
  cat >"$b/swapon" <<EOF
#!/bin/sh
echo "swapon \$*" >>"$racine/appels.log"
echo "/dev/zram0 partition 0 0 100" >>"$racine/proc/swaps"
EOF
  for c in journalctl fstrim; do
    printf '#!/bin/sh\necho "%s $*" >>"%s/appels.log"\n' "$c" "$racine" >"$b/$c"
  done
  # df : renvoie l'usage fixé dans le fichier usage-data (en %).
  cat >"$b/df" <<EOF
#!/bin/sh
echo "Filesystem 1024-blocks Used Available Capacity Mounted"
echo "/dev/vda2 1000 0 1000 \$(cat "$racine/usage-data" 2>/dev/null || echo 10)% /data"
EOF
  chmod +x "$b"/*
  : >"$racine/appels.log"
}

lancer() { # lancer <script> args... (dans la fausse racine)
  local s="$1"; shift
  # TELE_SH="busybox sh" : joue les scripts avec le sh de BusyBox (Buildroot).
  # shellcheck disable=SC2086 # TELE_SH peut contenir une commande et son argument.
  TELE_RACINE="$racine" TELE_LIB="$racine/usr/lib/tele" PATH="$racine/bin:$PATH" \
    ${TELE_SH:-} "$systeme/usr/sbin/$s" "$@"
}

lire() { cat "$racine$1"; }

# Remplit un dossier avec N fichiers de 1 Mo, du plus vieux au plus récent.
remplir() {
  local dossier="$racine$1" n="$2" i
  mkdir -p "$dossier"
  for ((i = 1; i <= n; i++)); do
    head -c 1048576 /dev/zero >"$dossier/f$i"
    touch -a -d "@$((1700000000 + i))" "$dossier/f$i"
  done
}

activite() { # activite <état> <âge en minutes>
  mkdir -p "$racine/run/tele"
  echo "$1" >"$racine/run/tele/activite"
  touch -d "@$(($(date +%s) - $2 * 60))" "$racine/run/tele/activite"
}

echo "== tele-memoire, box 2 Go"
fausse_racine 1700
lancer tele-memoire appliquer >/dev/null
verifier "profil 2go détecté" test "$(lire /run/tele/profil)" = 2go
verifier "swappiness 100" test "$(lire /proc/sys/vm/swappiness)" = 100
verifier "page-cluster 0" test "$(lire /proc/sys/vm/page-cluster)" = 0
verifier "watermark 125" test "$(lire /proc/sys/vm/watermark_scale_factor)" = 125
verifier "MGLRU activé, min_ttl 1000" test "$(lire /sys/kernel/mm/lru_gen/enabled)$(lire /sys/kernel/mm/lru_gen/min_ttl_ms)" = y1000
verifier "zram lz4" test "$(lire /sys/block/zram0/comp_algorithm)" = lz4
verifier "zram 75 % de 1700 Mo" test "$(lire /sys/block/zram0/disksize)" = 1275M
verifier "swap zram en priorité 100" grep -q "swapon -p 100" "$racine/appels.log"
lancer tele-memoire appliquer >/dev/null
verifier "deuxième passage : zram pas recréé" test "$(grep -c mkswap "$racine/appels.log")" = 1
verifier "état lisible" bash -c "TELE_RACINE='$racine' TELE_LIB='$racine/usr/lib/tele' '$systeme/usr/sbin/tele-memoire' etat | grep -q profil=2go"

echo "== tele-memoire, box 4 Go"
fausse_racine 3500
lancer tele-memoire appliquer >/dev/null
verifier "profil 4go détecté" test "$(lire /run/tele/profil)" = 4go
verifier "swappiness 60" test "$(lire /proc/sys/vm/swappiness)" = 60
verifier "zram 25 % de 3500 Mo" test "$(lire /sys/block/zram0/disksize)" = 875M
verifier "min_ttl 0" test "$(lire /sys/kernel/mm/lru_gen/min_ttl_ms)" = 0

echo "== tele-memoire, noyau sans zram ni MGLRU"
fausse_racine 1700
rm -rf "$racine/sys/kernel/mm/lru_gen"
printf '#!/bin/sh\nexit 1\n' >"$racine/bin/modprobe"
verifier "ne plante pas" lancer tele-memoire appliquer >/dev/null
verifier "swappiness quand même réglée" test "$(lire /proc/sys/vm/swappiness)" = 100

echo "== tele-entretien : la télé sert, il ne touche à rien"
for etat in lecture youtube android inconnue; do
  fausse_racine 1700
  remplir /data/chromium/Default/Cache 300
  [[ "$etat" = inconnue ]] || activite "$etat" 60
  lancer tele-entretien >/dev/null
  verifier "$etat : repoussé" test "$(lire /run/tele/entretien-dernier)" = repousse
  verifier "$etat : cache intact" test "$(find "$racine/data/chromium/Default/Cache" -type f | wc -l)" = 300
done

echo "== tele-entretien : accueil touché il y a 2 min, pas encore au repos"
fausse_racine 1700
remplir /data/chromium/Default/Cache 300
activite accueil 2
lancer tele-entretien >/dev/null
verifier "repoussé" test "$(lire /run/tele/entretien-dernier)" = repousse

echo "== tele-entretien : au repos mais processeur occupé"
fausse_racine 1700
activite accueil 30
echo "some avg10=42.00 avg60=0.00 avg300=0.00 total=0" >"$racine/proc/pressure/cpu"
lancer tele-entretien >/dev/null
verifier "repoussé" test "$(lire /run/tele/entretien-dernier)" = repousse

echo "== tele-entretien : au repos, caches au-dessus des plafonds (2 Go)"
fausse_racine 1700
remplir /data/chromium/Default/Cache 300
remplir /data/miniatures 20
activite accueil 30
lancer tele-entretien >/dev/null
verifier "fait" test "$(lire /run/tele/entretien-dernier)" = fait
verifier "cache Chromium ramené à 256 Mo" test "$(du -sm "$racine/data/chromium/Default/Cache" | cut -f1)" -le 256
verifier "les plus vieux partis en premier" test ! -e "$racine/data/chromium/Default/Cache/f1" -a -e "$racine/data/chromium/Default/Cache/f300"
verifier "miniatures sous le plafond : intactes" test "$(find "$racine/data/miniatures" -type f | wc -l)" = 20
verifier "journal plafonné à 64 Mo" grep -q "journalctl --vacuum-size=64M" "$racine/appels.log"
verifier "pas de fstrim hors veille" bash -c "! grep -q fstrim '$racine/appels.log'"

echo "== tele-entretien : veille, Chromium oublié, stockage à 80 %"
fausse_racine 1700
remplir /data/chromium/Default/Cache 10
activite veille 30
echo 80 >"$racine/usage-data"
sleep 300 &
mkdir -p "$racine/run/tele/roles"
echo $! >"$racine/run/tele/roles/chromium.pid"
lancer tele-entretien >/dev/null
verifier "Chromium fermé" bash -c "! kill -0 $! 2>/dev/null"
verifier "caches vidés au-delà de 75 %" test "$(find "$racine/data/chromium/Default/Cache" -type f | wc -l)" = 0
verifier "mémoire compactée" test "$(lire /proc/sys/vm/compact_memory)" = 1
verifier "fstrim fait" grep -q "fstrim -a" "$racine/appels.log"
lancer tele-entretien >/dev/null
verifier "fstrim pas refait la même semaine" test "$(grep -c fstrim "$racine/appels.log")" = 1

echo "== tele-entretien : stockage à 92 %, même pendant la lecture"
fausse_racine 1700
activite lecture 1
echo 92 >"$racine/usage-data"
lancer tele-entretien >/dev/null
verifier "alerte posée" test "$(lire /run/tele/alerte-stockage)" = 92
verifier "mises à jour refusées" test -e "$racine/run/tele/maj-refusee"
echo 50 >"$racine/usage-data"
lancer tele-entretien >/dev/null
verifier "alerte levée quand ça redescend" test ! -e "$racine/run/tele/alerte-stockage"

echo "== tele-entretien --forcer ignore la garde"
fausse_racine 1700
remplir /data/chromium/Default/Cache 300
activite lecture 0
lancer tele-entretien --forcer >/dev/null
verifier "fait" test "$(lire /run/tele/entretien-dernier)" = fait

echo "== tele-role"
fausse_racine 1700
lancer tele-role chromium -- true
verifier "Chromium marqué tuable en premier" test "$(lire /proc/self/oom_score_adj)" = 800
verifier "pid noté" test -s "$racine/run/tele/roles/chromium.pid"
verifier "rôle inconnu refusé" bash -c "! TELE_RACINE='$racine' TELE_LIB='$racine/usr/lib/tele' '$systeme/usr/sbin/tele-role' pirate -- true 2>/dev/null"

echo
echo "$reussis réussis, $rates ratés"
[[ "$rates" -eq 0 ]]
