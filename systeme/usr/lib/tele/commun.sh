# shellcheck shell=sh
# Fonctions partagées par les scripts système de la box (tele-*).
# POSIX sh : tourne avec le sh de BusyBox (Buildroot) comme avec dash/bash.
#
# TELE_RACINE préfixe tous les chemins système : les tests s'en servent pour
# jouer les scripts sur une fausse racine (systeme/tests/tester.sh).

R="${TELE_RACINE:-}"
CONF="${TELE_CONF:-$R/etc/tele/memoire.conf}"
RUN="$R/run/tele"

journal() {
  # Une ligne horodatée sur la sortie et dans le journal de la box.
  ligne="$(date '+%Y-%m-%dT%H:%M:%S') $*"
  printf '%s\n' "$ligne"
  if [ -d "$R/var/log/tele" ]; then
    printf '%s\n' "$ligne" >>"$R/var/log/tele/${TELE_NOM:-tele}.log"
  fi
}

# Valeur d'un champ de /proc/meminfo, en Mo.
meminfo_mo() {
  awk -v cle="$1:" '$1 == cle { printf "%d\n", $2 / 1024 }' "$R/proc/meminfo"
}

# Choisit le profil (2go ou 4go) et charge ses réglages.
charger_profil() {
  # shellcheck disable=SC1090
  . "$CONF"
  # Profil déjà choisi au démarrage par tele-memoire : on le reprend (une
  # lecture de fichier au lieu d'un calcul).
  if [ -z "${PROFIL:-}" ] && [ -r "$RUN/profil" ]; then
    read -r PROFIL <"$RUN/profil" || true
  fi
  if [ -z "${PROFIL:-}" ]; then
    total="$(meminfo_mo MemTotal)"
    if [ "$total" -lt "$SEUIL_PROFIL_2GO_MO" ]; then
      PROFIL=2go
    else
      PROFIL=4go
    fi
  fi
  case "$PROFIL" in
    2go) profil_2go ;;
    4go) profil_4go ;;
    *) journal "profil inconnu : $PROFIL"; return 1 ;;
  esac
}

# avg10 d'un fichier PSI (/proc/pressure/cpu, io, memory), partie entière.
# Sans sous-processus : lu par le shell lui-même (chemin rapide de l'entretien).
psi_avg10() {
  f="$R/proc/pressure/$1"
  valeur=0
  if [ -r "$f" ]; then
    read -r _ valeur _ <"$f" || true
    valeur="${valeur#avg10=}"
    valeur="${valeur%%.*}"
  fi
  printf '%s\n' "${valeur:-0}"
}

# Écrit une valeur dans un fichier de /proc ou /sys, sans échouer si le
# noyau ne connaît pas le réglage (on le note seulement).
ecrire() {
  if [ -e "$R$1" ]; then
    if printf '%s\n' "$2" >"$R$1" 2>/dev/null; then
      return 0
    fi
  fi
  journal "réglage ignoré (absent ou refusé) : $1 = $2"
  return 0
}

# Taille d'un dossier en Mo (0 s'il n'existe pas).
taille_mo() {
  if [ -d "$R$1" ]; then
    du -sm "$R$1" 2>/dev/null | awk '{ print $1 }'
  else
    echo 0
  fi
}

# Activité courante de la télé, écrite par l'interface dans /run/tele/activite :
# veille, accueil, lecture, youtube, android. Inconnue = on considère
# que la télé sert (prudence).
activite() {
  etat=inconnue
  if [ -r "$RUN/activite" ]; then
    read -r etat <"$RUN/activite" || true
  fi
  printf '%s\n' "${etat:-inconnue}"
}

# Âge du dernier changement d'activité, en minutes.
activite_age_min() {
  if [ -e "$RUN/activite" ]; then
    maintenant="$(date +%s)"
    modif="$(stat -c %Y "$RUN/activite")"
    echo $(((maintenant - modif) / 60))
  else
    echo 0
  fi
}
