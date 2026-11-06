#!/usr/bin/env python3
"""Banc d'émulation mémoire de la box (à lancer dans le conteneur, voir lancer.sh).

Le conteneur joue le rôle de la box : Docker borne sa mémoire à ce que Linux
voit vraiment sur une S905X3 de 2 Go ou de 4 Go. On y lance, palier par
palier, les briques de la télé (interface Flutter, Chromium sur une page
lourde, lecteur vidéo 1080p, hub, mise à jour en fond) et on relève la
mémoire, la pression mémoire (PSI) et les processus tués par l'OOM.

Ce que le banc ne simule pas : le processeur (Cortex-A55) et le GPU. Les
temps et la fluidité ne sont comparables qu'entre les deux profils, jamais
avec la vraie box.
"""

import json
import os
import re
import signal
import subprocess
import sys
import threading
import time

PROFIL = os.environ.get("PROFIL", "inconnu")
LIMITE_MO = int(os.environ.get("LIMITE_MO", "0"))
PALIER_S = int(os.environ.get("PALIER_S", "40"))
CHROME = os.environ.get("CHROME", "/chrome/chrome")
UI = os.environ.get("UI", "/ui/tele")
MEDIAS = os.environ.get("MEDIAS", "/medias")
SORTIE = os.environ.get("SORTIE", "/resultats")

CG2 = "/sys/fs/cgroup"
CG1 = "/sys/fs/cgroup/memory"


def lire(chemin, defaut=None):
    try:
        with open(chemin) as f:
            return f.read()
    except OSError:
        return defaut


def octets_en_mo(valeur):
    return round(int(valeur) / 1048576, 1)


# --- Lecture du cgroup (v2 en priorité, v1 sinon) --------------------------

def memoire_cgroup():
    """Mémoire du conteneur : totale, anonyme (tas), cache de fichiers."""
    if os.path.exists(f"{CG2}/memory.current"):
        stat = dict(l.split() for l in lire(f"{CG2}/memory.stat", "").splitlines())
        return {
            "total": octets_en_mo(lire(f"{CG2}/memory.current")),
            "anon": octets_en_mo(stat.get("anon", 0)),
            "cache": octets_en_mo(stat.get("file", 0)),
        }
    stat = dict(l.split() for l in lire(f"{CG1}/memory.stat", "").splitlines())
    return {
        "total": octets_en_mo(lire(f"{CG1}/memory.usage_in_bytes", "0")),
        "anon": octets_en_mo(stat.get("total_rss", stat.get("rss", 0))),
        "cache": octets_en_mo(stat.get("total_cache", stat.get("cache", 0))),
    }


def pic_cgroup():
    for chemin in (f"{CG2}/memory.peak", f"{CG1}/memory.max_usage_in_bytes"):
        v = lire(chemin)
        if v:
            return octets_en_mo(v)
    return None


def oom_kills():
    for chemin in (f"{CG2}/memory.events", f"{CG1}/memory.oom_control"):
        texte = lire(chemin)
        if texte:
            m = re.search(r"oom_kill (\d+)", texte)
            if m:
                return int(m.group(1))
    return None


def pression():
    """PSI mémoire (avg10, en %) : temps passé à attendre de la mémoire."""
    texte = lire(f"{CG2}/memory.pressure") or lire("/proc/pressure/memory")
    if not texte:
        return None
    res = {}
    for ligne in texte.splitlines():
        genre, *champs = ligne.split()
        res[genre] = float(dict(c.split("=") for c in champs)["avg10"])
    return res


# --- Mémoire par rôle (PSS : la part de chaque processus) -------------------

ROLES = {}  # pid racine -> rôle


def pss_ko(pid):
    texte = lire(f"/proc/{pid}/smaps_rollup")
    if texte:
        m = re.search(r"^Pss:\s+(\d+)", texte, re.M)
        if m:
            return int(m.group(1))
    texte = lire(f"/proc/{pid}/status", "")
    m = re.search(r"^VmRSS:\s+(\d+)", texte, re.M)
    return int(m.group(1)) if m else 0


def arbre():
    parents = {}
    for nom in os.listdir("/proc"):
        if nom.isdigit():
            stat = lire(f"/proc/{nom}/stat")
            if stat:
                parents[int(nom)] = int(stat.rsplit(")", 1)[1].split()[1])
    return parents


def memoire_par_role():
    parents = arbre()
    totaux = {}
    for pid in parents:
        role, p = "systeme", pid
        while p in parents:
            if p in ROLES:
                role = ROLES[p]
                break
            p = parents[p]
        totaux[role] = totaux.get(role, 0) + pss_ko(pid)
    return {r: round(k / 1024, 1) for r, k in sorted(totaux.items())}


# --- Briques de la télé ----------------------------------------------------

PROCS = {}


def lancer(role, commande, **kw):
    p = subprocess.Popen(commande, start_new_session=True, **kw)
    ROLES[p.pid] = role
    PROCS[role] = p
    return p


def arreter(role):
    p = PROCS.pop(role, None)
    if p and p.poll() is None:
        try:
            os.killpg(p.pid, signal.SIGTERM)
            p.wait(timeout=10)
        except (ProcessLookupError, subprocess.TimeoutExpired):
            try:
                os.killpg(p.pid, signal.SIGKILL)
            except ProcessLookupError:
                pass
    ROLES.pop(p.pid if p else -1, None)


def vivant(role):
    p = PROCS.get(role)
    return p is not None and p.poll() is None


# Remplit et garde N Mo de mémoire anonyme, comme un service résident.
ALLOUEUR = (
    "import sys,time\n"
    "b=bytearray(int(sys.argv[1])<<20)\n"
    "for i in range(0,len(b),4096): b[i]=1\n"
    "while True:\n"
    "  for i in range(0,len(b),4096): b[i]=(b[i]+1)&255\n"
    "  time.sleep(2)\n"
)

# Mise à jour en fond : un tampon résident et une lecture continue d'un gros
# fichier (cache de pages), comme RAUC qui vérifie puis écrit un bundle.
MISE_A_JOUR = (
    "import sys,time\n"
    "b=bytearray(120<<20)\n"
    "for i in range(0,len(b),4096): b[i]=1\n"
    "while True:\n"
    "  with open(sys.argv[1],'rb') as f:\n"
    "    while f.read(1<<20): pass\n"
)


def lancer_ui():
    """Lance l'interface et renvoie le temps jusqu'à la première image (ms)."""
    t0 = time.time()
    p = lancer("interface", [UI], stdout=subprocess.PIPE, stderr=subprocess.STDOUT,
               text=True, env={**os.environ, "DISPLAY": ":99"})
    resultat = {}

    def lire_sortie():
        for ligne in p.stdout:
            m = re.search(r"premiere-image (\d+)", ligne)
            if m and "ms" not in resultat:
                resultat["ms"] = int(m.group(1)) - int(t0 * 1000)

    threading.Thread(target=lire_sortie, daemon=True).start()
    for _ in range(300):
        if "ms" in resultat or p.poll() is not None:
            break
        time.sleep(0.1)
    return resultat.get("ms")


def plus_tuable():
    """Chromium passe en tête de liste de l'OOM (règle 3 du plan)."""
    with open("/proc/self/oom_score_adj", "w") as f:
        f.write("800")


def lancer_chromium(fuite_mo=0):
    lancer("chromium", [
        CHROME, "--no-sandbox", "--kiosk", "--no-first-run",
        "--no-default-browser-check", "--disable-dev-shm-usage",
        # Règle du plan : un seul processus de rendu.
        "--renderer-process-limit=1",
        "--autoplay-policy=no-user-gesture-required",
        "--user-data-dir=/tmp/chromium", "--window-size=1920,1080",
        f"file://{MEDIAS}/page-youtube.html#fuite={fuite_mo}",
    ], stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL,
        env={**os.environ, "DISPLAY": ":99"}, preexec_fn=plus_tuable)


VITESSES = []


def lancer_lecteur():
    """Décodage logiciel d'un flux 1080p60 à vitesse réelle (Twitch)."""
    p = lancer("lecteur", [
        "ffmpeg", "-hide_banner", "-nostdin", "-re", "-stream_loop", "-1",
        "-threads", "4", "-i", f"{MEDIAS}/twitch-1080p60.mp4", "-f", "null", "-",
    ], stdout=subprocess.DEVNULL, stderr=subprocess.PIPE, text=True)

    def lire_stats():
        tampon = ""
        while True:
            c = p.stderr.read(1)
            if not c:
                break
            tampon += c
            if c == "\r" or c == "\n":
                m = re.search(r"speed=\s*([\d.]+)x", tampon)
                if m:
                    VITESSES.append(float(m.group(1)))
                tampon = ""

    threading.Thread(target=lire_stats, daemon=True).start()


# --- Mesure d'un palier ----------------------------------------------------

def palier(nom, duree, roles_attendus):
    print(f"[{PROFIL}] palier « {nom} » ({duree} s)", flush=True)
    oom_avant = oom_kills() or 0
    VITESSES.clear()
    echantillons, psi_some, psi_full = [], None, None
    debut = time.time()
    while time.time() - debut < duree:
        time.sleep(1)
        m = memoire_cgroup()
        echantillons.append(m)
        p = pression()
        if p:
            psi_some = max(psi_some or 0, p.get("some", 0))
            psi_full = max(psi_full or 0, p.get("full", 0))
    fin = echantillons[-5:]  # régime établi : les 5 dernières secondes
    moyenne = {k: round(sum(e[k] for e in fin) / len(fin), 1) for k in fin[0]}
    vitesses = VITESSES[len(VITESSES) // 3:]  # sans la mise en route
    resultat = {
        "nom": nom,
        "memoire_mo": moyenne["total"],
        "anon_mo": moyenne["anon"],
        "cache_mo": moyenne["cache"],
        "libre_mo": round(LIMITE_MO - moyenne["anon"], 1) if LIMITE_MO else None,
        "pic_mo": max(e["total"] for e in echantillons),
        "psi_some_max": psi_some,
        "psi_full_max": psi_full,
        "oom_kills": (oom_kills() or 0) - oom_avant,
        "roles_mo": memoire_par_role(),
        "vivants": {r: vivant(r) for r in roles_attendus},
        "lecteur_vitesse": round(min(vitesses), 2) if vitesses else None,
    }
    print(json.dumps(resultat, ensure_ascii=False), flush=True)
    return resultat


def main():
    rapport = {"profil": PROFIL, "limite_mo": LIMITE_MO, "palier_s": PALIER_S,
               "debut": time.strftime("%Y-%m-%dT%H:%M:%S%z"), "paliers": []}
    lancer("affichage", ["Xvfb", ":99", "-screen", "0", "1920x1080x24", "-nolisten", "tcp"],
           stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL)
    time.sleep(2)
    lancer("hub", [sys.executable, "-c", ALLOUEUR, "40"])
    rapport["ui_premiere_image_ms"] = lancer_ui()
    P = rapport["paliers"]

    P.append(palier("Accueil", PALIER_S, ["interface", "hub"]))

    lancer_chromium()
    P.append(palier("YouTube (Chromium)", PALIER_S * 2, ["interface", "hub", "chromium"]))
    arreter("chromium")
    P.append(palier("Retour à l'accueil", PALIER_S // 2, ["interface", "hub"]))

    lancer_lecteur()
    P.append(palier("Twitch (lecteur 1080p60)", PALIER_S, ["interface", "hub", "lecteur"]))
    arreter("lecteur")

    # Pire cas : YouTube + lecteur + mise à jour + hub en plein scan Bluetooth.
    arreter("hub")
    lancer("hub", [sys.executable, "-c", ALLOUEUR, "70"])
    lancer("mise_a_jour", [sys.executable, "-c", MISE_A_JOUR, f"{MEDIAS}/bundle.bin"])
    lancer_chromium()
    lancer_lecteur()
    P.append(palier("Pire cas", PALIER_S * 2,
                    ["interface", "hub", "chromium", "lecteur", "mise_a_jour"]))

    # Même chose après une longue soirée : le tas de Chromium a dérivé de
    # 600 Mo (estimation du plan, à confirmer sur la box, issue #43).
    arreter("chromium")
    lancer_chromium(fuite_mo=600)
    P.append(palier("Pire cas après 2 h de YouTube", PALIER_S * 2,
                    ["interface", "hub", "chromium", "lecteur", "mise_a_jour"]))

    rapport["pic_global_mo"] = pic_cgroup()
    rapport["oom_kills_total"] = oom_kills()
    for role in list(PROCS):
        arreter(role)
    os.makedirs(SORTIE, exist_ok=True)
    with open(f"{SORTIE}/{PROFIL}.json", "w") as f:
        json.dump(rapport, f, ensure_ascii=False, indent=2)
    print(f"[{PROFIL}] rapport écrit dans {SORTIE}/{PROFIL}.json", flush=True)


if __name__ == "__main__":
    main()
