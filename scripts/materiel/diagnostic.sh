#!/usr/bin/env bash
# Diagnostic matériel de la box sous Armbian (phase 1).
#
# Usage : sudo scripts/materiel/diagnostic.sh [--cec] > rapport.txt
#
# Le script est en LECTURE SEULE : il n'écrit sur aucun disque, eMMC comprise
# (Android d'origine, ADR 0003 ; écritures permises après sauvegarde, ADR 0018). Il collecte de quoi remplir
# docs/materiel.md. Les outils absents sont signalés, pas installés.
#
# --cec : en plus, déclare la box comme lecteur CEC (« playback ») et
#         interroge la télé. Cela envoie des messages sur le bus HDMI-CEC,
#         sans rien écrire sur la box.

set -u

AVEC_CEC=0
for arg in "$@"; do
  case "$arg" in
    --cec) AVEC_CEC=1 ;;
    -h|--help)
      sed -n '2,12p' "$0"
      exit 0
      ;;
    *)
      echo "Option inconnue : $arg" >&2
      exit 2
      ;;
  esac
done

section() {
  printf '\n===== %s =====\n' "$1"
}

# Lance une commande si elle existe, sinon le signale.
lancer() {
  if command -v "$1" >/dev/null 2>&1; then
    echo "\$ $*"
    "$@" 2>&1
  else
    echo "(outil absent : $1)"
  fi
}

# Affiche un fichier s'il existe.
afficher() {
  if [ -r "$1" ]; then
    echo "--- $1"
    tr '\0' '\n' <"$1"
    echo
  fi
}

# Filtre le journal noyau sur un motif.
journal() {
  echo "\$ dmesg | grep -iE '$1'"
  dmesg 2>/dev/null | grep -iE "$1" | tail -n 40 || true
}

if [ "$(id -u)" -ne 0 ]; then
  echo "Attention : lancé sans root, dmesg et certaines infos seront incomplets." >&2
fi

section "Date et système"
date -Iseconds
uname -a
afficher /etc/os-release

section "Modèle et DTB"
afficher /proc/device-tree/model
afficher /proc/device-tree/compatible
for f in /boot/uEnv.txt /boot/extlinux/extlinux.conf /boot/armbianEnv.txt; do
  if [ -r "$f" ]; then
    echo "--- $f (lignes FDT/fdt)"
    grep -iE 'fdt|dtb' "$f" || true
  fi
done

section "CPU et mémoire"
lancer lscpu
lancer free -h
for z in /sys/class/thermal/thermal_zone*/temp; do
  [ -r "$z" ] && echo "$z : $(( $(cat "$z") / 1000 )) °C"
done

section "Stockage (lecture seule)"
lancer lsblk -o NAME,SIZE,TYPE,FSTYPE,MOUNTPOINT,MODEL
echo "Rappel : mmcblk* de type eMMC = Android d'origine, à sauvegarder avant toute écriture (ADR 0018)."

section "Réseau"
lancer ip -br link
lancer ip -br addr
for i in /sys/class/net/e*; do
  [ -e "$i" ] && lancer ethtool "$(basename "$i")"
done
journal 'eth|stmmac|dwmac|rtl8211|phy'

section "Wi-Fi et Bluetooth"
for d in /sys/bus/sdio/devices/*; do
  [ -e "$d" ] || continue
  echo "SDIO $(basename "$d") : vendor=$(cat "$d/vendor" 2>/dev/null) device=$(cat "$d/device" 2>/dev/null)"
done
lancer iw dev
lancer rfkill list
lancer bluetoothctl list
journal 'brcmfmac|wlan|wifi|sdio|bluetooth|hci|btbcm|rtw|aic|ssv'

section "Affichage (DRM/KMS) et GPU"
for c in /sys/class/drm/card*-*; do
  [ -e "$c/status" ] || continue
  echo "$(basename "$c") : $(cat "$c/status")"
  [ -r "$c/modes" ] && sed 's/^/  mode /' "$c/modes" | head -n 10
done
lancer lsmod
journal 'panfrost|meson-drm|meson_dw_hdmi|hdmi'
echo "Test GPU à lancer à la main, écran sans bureau : glmark2-es2-drm"

section "HDMI-CEC"
ls -l /dev/cec* 2>/dev/null || echo "(aucun /dev/cec*)"
journal 'cec'
if [ -e /dev/cec0 ]; then
  lancer cec-ctl -d /dev/cec0
  if [ "$AVEC_CEC" -eq 1 ]; then
    lancer cec-ctl -d /dev/cec0 --playback --osd-name SmartTV
    lancer cec-ctl -d /dev/cec0 --to 0 --give-device-power-status
    lancer cec-ctl -d /dev/cec0 -S
  else
    echo "Relancer avec --cec pour interroger la télé."
  fi
fi

section "Infrarouge"
ls -l /sys/class/rc/ 2>/dev/null || echo "(aucun /sys/class/rc)"
lancer ir-keytable
journal 'meson-ir|rc-core|rc rc'

section "Entrées evdev"
afficher /proc/bus/input/devices

section "Vidéo (décodeurs V4L2)"
ls -l /dev/video* 2>/dev/null || echo "(aucun /dev/video*)"
lancer v4l2-ctl --list-devices
journal 'vdec|meson-vdec|v4l2'

section "Audio"
lancer aplay -l

section "Fin"
echo "Rapport terminé. Le joindre à l'issue correspondante ou le versionner dans docs/materiel/."
