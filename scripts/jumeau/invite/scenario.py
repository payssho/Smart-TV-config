#!/usr/bin/env python3
"""Scénario joué dans le jumeau de la box (ADR 0019), lancé par tele-jumeau.

Contrairement au banc Docker (ADR 0016), on est ici dans une vraie machine
arm64 : vrai noyau, vraie RAM bornée comme sur la box, zram et réglages de
tele-memoire actifs, carte SD bridée à la vitesse d'une microSD A1. On lance
les briques de la télé avec tele-role (scores OOM du plan) et on relève la
mémoire du système entier, le swap compressé, la pression et les OOM.

Puis on mesure le coût de l'entretien (tele-entretien) sur un travail de
référence : seul, pendant une lecture (l'entretien doit s'effacer), et au
repos (le vrai ménage, priorité minimale).

Le processeur est émulé (QEMU) : les temps ne valent qu'en relatif, entre
deux mesures du même jumeau, jamais comme temps de la vraie box.
"""

import json
import os
import re
import signal
import statistics
import subprocess
import sys
import threading
import time

PROFIL = os.environ.get("PROFIL", "inconnu")
SCENARIO = os.environ.get("SCENARIO", "complet")
PALIER_S = int(os.environ.get("PALIER_S") or "60")
MEDIAS = "/medias"
SORTIE = "/resultats"
UI = "/opt/tele/ui/tele"
CHROME = "/usr/bin/chromium"
RUN = "/run/tele"
XDG = f"{RUN}/xdg"


def lire(chemin, defaut=None):
    try:
        with open(chemin) as f:
            return f.read()
    except OSError:
        return defaut


def journal(texte):
    print(f"[jumeau {PROFIL}] {texte}", flush=True)


# --- Mesures système --------------------------------------------------------

def meminfo():
    infos = {}
    for ligne in (lire("/proc/meminfo") or "").splitlines():
        cle, valeur = ligne.split(":", 1)
        infos[cle] = int(valeur.split()[0]) // 1024  # Mo
    return infos


def zram():
    """mm_stat : données d'origine, compressées, RAM réellement prise (octets)."""
    texte = lire("/sys/block/zram0/mm_stat")
    if not texte:
        return None
    champs = [int(c) for c in texte.split()]
    return {"donnees_mo": champs[0] >> 20, "compresse_mo": champs[1] >> 20,
            "ram_mo": champs[2] >> 20}


def vmstat(cle):
    m = re.search(rf"^{cle} (\d+)$", lire("/proc/vmstat", ""), re.M)
    return int(m.group(1)) if m else 0


def psi(ressource):
    texte = lire(f"/proc/pressure/{ressource}")
    if not texte:
        return {}
    res = {}
    for ligne in texte.splitlines():
        genre, *champs = ligne.split()
        res[genre] = float(dict(c.split("=") for c in champs)["avg10"])
    return res


def echantillon():
    m = meminfo()
    z = zram() or {}
    return {
        "occupee": m["MemTotal"] - m["MemAvailable"],
        "disponible": m["MemAvailable"],
        "anon": m.get("AnonPages", 0),
        "cache": m.get("Cached", 0),
        "swap": m.get("SwapTotal", 0) - m.get("SwapFree", 0),
        "zram_ram": z.get("ram_mo", 0),
    }


# --- Briques de la télé -----------------------------------------------------

PROCS = {}


def lancer(role, commande, **kw):
    """Lance une brique via tele-role (score OOM, pid noté pour l'entretien)."""
    env = {**os.environ, "XDG_RUNTIME_DIR": XDG, **kw.pop("env", {})}
    p = subprocess.Popen(["tele-role", role, "--"] + commande, start_new_session=True,
                         env=env, **kw)
    PROCS[role] = p
    return p


def arreter(role):
    p = PROCS.pop(role, None)
    if p and p.poll() is None:
        try:
            os.killpg(p.pid, signal.SIGTERM)
            p.wait(timeout=20)
        except (ProcessLookupError, subprocess.TimeoutExpired):
            try:
                os.killpg(p.pid, signal.SIGKILL)
            except ProcessLookupError:
                pass


def vivant(role):
    p = PROCS.get(role)
    return p is not None and p.poll() is None


def activite(etat, age_min=0):
    """Ce que l'interface écrira dans /run/tele/activite sur la vraie box."""
    os.makedirs(RUN, exist_ok=True)
    with open(f"{RUN}/activite", "w") as f:
        f.write(etat + "\n")
    t = time.time() - age_min * 60
    os.utime(f"{RUN}/activite", (t, t))


ALLOUEUR = (
    "import sys,time\n"
    "b=bytearray(int(sys.argv[1])<<20)\n"
    "for i in range(0,len(b),4096): b[i]=1\n"
    "while True:\n"
    "  for i in range(0,len(b),4096): b[i]=(b[i]+1)&255\n"
    "  time.sleep(2)\n"
)

MISE_A_JOUR = (
    "import sys,time\n"
    "b=bytearray(120<<20)\n"
    "for i in range(0,len(b),4096): b[i]=1\n"
    "while True:\n"
    "  with open(sys.argv[1],'rb') as f:\n"
    "    while f.read(1<<20): pass\n"
)


def compositeur():
    """cage : compositeur Wayland plein écran, comme le repli de l'ADR 0008."""
    os.makedirs(XDG, mode=0o700, exist_ok=True)
    env = {"WLR_RENDERER": "pixman", "WLR_LIBINPUT_NO_DEVICES": "1",
           "WLR_NO_HARDWARE_CURSORS": "1"}
    return env


def lancer_ui():
    """Interface Flutter sous cage. Renvoie le temps jusqu'à la première image."""
    if not os.access(UI, os.X_OK):
        # Le substitut tourne quand même sous cage : sans compositeur, pas de
        # wayland-0, et Chromium (--ozone-platform=wayland) s'arrête aussitôt.
        journal("pas d'app Flutter dans l'image : substitut de 150 Mo sous cage")
        lancer("interface", ["seatd-launch", "--", "cage", "-s", "--",
                             sys.executable, "-c", ALLOUEUR, "150"],
               stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL, env=compositeur())
        return None
    t0 = time.time()
    p = lancer("interface", ["seatd-launch", "--", "cage", "-s", "--", UI],
               stdout=subprocess.PIPE, stderr=subprocess.STDOUT, text=True,
               env=compositeur())
    resultat = {}

    def suivre():
        for ligne in p.stdout:
            m = re.search(r"premiere-image (\d+)", ligne)
            if m and "ms" not in resultat:
                resultat["ms"] = int(m.group(1)) - int(t0 * 1000)
            elif "error" in ligne.lower() or "erreur" in ligne.lower():
                journal("interface : " + ligne.strip()[:200])

    threading.Thread(target=suivre, daemon=True).start()
    for _ in range(3000):  # jusqu'à 5 min : le processeur est émulé
        if "ms" in resultat or p.poll() is not None:
            break
        time.sleep(0.1)
    if p.poll() is not None:
        journal(f"l'interface s'est arrêtée (code {p.returncode})")
    return resultat.get("ms")


def chromium_present():
    return os.access(CHROME, os.X_OK)


# Journal de Chromium, copié avec les résultats : s'il s'arrête seul, on sait pourquoi.
CHROMIUM_LOG = None


def lancer_chromium(fuite_mo=0):
    global CHROMIUM_LOG
    if CHROMIUM_LOG is None:
        CHROMIUM_LOG = open(f"{SORTIE}/chromium-{PROFIL}.log", "a")
    lancer("chromium", [
        CHROME, "--no-sandbox", "--kiosk", "--no-first-run", "--ozone-platform=wayland",
        "--no-default-browser-check", "--disable-dev-shm-usage",
        "--renderer-process-limit=1",
        "--autoplay-policy=no-user-gesture-required",
        "--user-data-dir=/data/chromium", "--disk-cache-size=268435456",
        f"file://{MEDIAS}/page-youtube.html#fuite={fuite_mo}",
    ], stdout=CHROMIUM_LOG, stderr=subprocess.STDOUT,
        env={"WAYLAND_DISPLAY": "wayland-0"})


def lancer_lecteur():
    lancer("lecteur", [
        "ffmpeg", "-hide_banner", "-nostdin", "-loglevel", "error", "-re",
        "-stream_loop", "-1", "-threads", "4", "-i", f"{MEDIAS}/twitch-1080p60.mp4",
        "-f", "null", "-",
    ], stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL)


# --- Capture d'écran par l'hôte (QMP) ---------------------------------------

def capture(nom):
    """Demande à l'hôte une capture de l'écran 1080p du jumeau."""
    demande = f"{SORTIE}/capture-{PROFIL}-{nom}.demande"
    with open(demande, "w") as f:
        f.write(nom)
    for _ in range(60):
        if not os.path.exists(demande):
            return True
        time.sleep(0.5)
    journal(f"capture « {nom} » sans réponse de l'hôte")
    os.remove(demande)
    return False


# --- Paliers ----------------------------------------------------------------

def palier(nom, duree, roles):
    journal(f"palier « {nom} » ({duree} s)")
    oom_avant = vmstat("oom_kill")
    swap_in_avant, swap_out_avant = vmstat("pswpin"), vmstat("pswpout")
    echantillons, psi_some, psi_full = [], 0.0, 0.0
    debut = time.time()
    while time.time() - debut < duree:
        time.sleep(1)
        echantillons.append(echantillon())
        p = psi("memory")
        psi_some = max(psi_some, p.get("some", 0))
        psi_full = max(psi_full, p.get("full", 0))
    fin = echantillons[-5:]
    moyenne = {k: round(sum(e[k] for e in fin) / len(fin)) for k in fin[0]}
    resultat = {
        "nom": nom,
        **{f"{k}_mo": v for k, v in moyenne.items()},
        "pic_occupee_mo": max(e["occupee"] for e in echantillons),
        "min_disponible_mo": min(e["disponible"] for e in echantillons),
        "psi_memoire_some_max": psi_some,
        "psi_memoire_full_max": psi_full,
        "pages_swap_entrees": vmstat("pswpin") - swap_in_avant,
        "pages_swap_sorties": vmstat("pswpout") - swap_out_avant,
        "oom_kills": vmstat("oom_kill") - oom_avant,
        "vivants": {r: vivant(r) for r in roles},
    }
    journal(json.dumps(resultat, ensure_ascii=False))
    return resultat


# --- Coût de l'entretien ----------------------------------------------------

def reference():
    """Travail de référence : décoder 90 images 1080p le plus vite possible."""
    t = time.monotonic()
    subprocess.run(["ffmpeg", "-hide_banner", "-nostdin", "-loglevel", "error",
                    "-threads", "4", "-i", f"{MEDIAS}/twitch-1080p60.mp4",
                    "-frames:v", "90", "-f", "null", "-"], check=True)
    return time.monotonic() - t


def mesurer(fois=3):
    return round(statistics.median(reference() for _ in range(fois)), 2)


def remplir_cache(mo):
    dossier = "/data/chromium/Default/Cache"
    os.makedirs(dossier, exist_ok=True)
    bloc = os.urandom(1 << 20)
    for i in range(mo):
        with open(f"{dossier}/f{i:04d}", "wb") as f:
            f.write(bloc)
    return dossier


def taille_mo(dossier):
    total = 0
    for base, _, fichiers in os.walk(dossier):
        for nom in fichiers:
            total += os.path.getsize(os.path.join(base, nom))
    return total >> 20


def entretien_comme_service(*args):
    """tele-entretien avec les priorités de son unité systemd (ADR 0020)."""
    try:
        return subprocess.run(["chrt", "--idle", "0", "nice", "-n", "19", "ionice", "-c", "3",
                               "tele-entretien", *args], stdout=subprocess.DEVNULL, timeout=900)
    except subprocess.TimeoutExpired:
        journal("tele-entretien : délai de 15 min dépassé")
        return None


def dernier_etat():
    return (lire(f"{RUN}/entretien-dernier") or "").strip()


def pendant(action, fois=3):
    """Mesure la référence pendant qu'action() tourne en boucle à côté."""
    arret = threading.Event()
    durees = []

    def boucle():
        while not arret.is_set():
            t = time.monotonic()
            action()
            durees.append(time.monotonic() - t)
            time.sleep(1)

    th = threading.Thread(target=boucle)
    th.start()
    resultat = mesurer(fois)
    arret.set()
    th.join()
    return resultat, durees


def cout_entretien():
    journal("coût de l'entretien")
    res = {}
    res["seul_s"] = mesurer()
    cap = 256 if PROFIL == "2go" else 512

    # 1. Pendant une lecture : l'entretien passe en boucle (600 fois plus
    # souvent que sur la box) et doit repartir aussitôt.
    activite("lecture")
    res["pendant_lecture_s"], durees = pendant(entretien_comme_service)
    res["passage_repousse_ms"] = round(statistics.median(durees) * 1000) if durees else None
    # Fréquence de la boucle (un passage + 1 s de pause) contre 1 passage
    # toutes les 600 s sur la box : on ramène le surcoût à la réalité.
    res["frequence_boucle_facteur"] = round(600 / (statistics.mean(durees) + 1)) if durees else None
    res["dernier_etat_lecture"] = dernier_etat()

    # 2. Accueil laissé depuis 30 min, mais les 4 cœurs décodent en continu :
    # la garde processeur doit le faire repartir.
    journal("entretien : garde processeur")
    activite("accueil", age_min=30)
    charge = subprocess.Popen(["ffmpeg", "-hide_banner", "-nostdin", "-loglevel", "error",
                               "-stream_loop", "-1", "-threads", "4",
                               "-i", f"{MEDIAS}/twitch-1080p60.mp4", "-f", "null", "-"])
    time.sleep(5)
    entretien_comme_service()
    charge.terminate()
    charge.wait()
    res["dernier_etat_processeur_occupe"] = dernier_etat()

    journal("entretien : pire cas du ménage forcé")
    # 3. Pire cas : le ménage forcé tourne en même temps que la référence
    # (n'arrive pas sur la box grâce à la garde) ; coût en priorité minimale.
    dossier = remplir_cache(cap + 200)
    res["pendant_menage_s"], _ = pendant(lambda: entretien_comme_service("--forcer"))

    journal("entretien : ménage au repos par l'unité systemd")
    # 4. Au repos et sans charge, l'unité systemd fait le vrai ménage. On
    # laisse d'abord la SD souffler : on vient d'y écrire des centaines de Mo.
    remplir_cache(cap + 200)
    os.sync()
    for _ in range(180):
        if psi("io").get("some", 100) < 4 and psi("cpu").get("some", 100) < 8:
            break
        time.sleep(1)
    activite("accueil", age_min=30)
    res["cache_avant_mo"] = taille_mo(dossier)
    t = time.monotonic()
    try:
        subprocess.run(["systemctl", "start", "tele-entretien.service"], timeout=900)
    except subprocess.TimeoutExpired:
        journal("unité tele-entretien : délai de 15 min dépassé")
    res["menage_duree_s"] = round(time.monotonic() - t, 1)
    res["cache_apres_mo"] = taille_mo(dossier)
    res["plafond_mo"] = cap
    res["dernier_etat_repos"] = dernier_etat()

    seul = res["seul_s"]
    res["surcout_lecture_pourcent"] = round((res["pendant_lecture_s"] / seul - 1) * 100, 1)
    if res["frequence_boucle_facteur"]:
        res["surcout_lecture_reel_pourcent"] = round(
            res["surcout_lecture_pourcent"] / res["frequence_boucle_facteur"], 3)
    res["surcout_menage_pourcent"] = round((res["pendant_menage_s"] / seul - 1) * 100, 1)
    journal(json.dumps(res, ensure_ascii=False))
    return res


# --- Déroulé ----------------------------------------------------------------

def etat_memoire():
    sortie = subprocess.run(["tele-memoire", "etat"], capture_output=True, text=True).stdout
    return dict(l.split("=", 1) for l in sortie.splitlines() if "=" in l)


def main():
    journal(f"scénario {SCENARIO}, paliers de {PALIER_S} s")
    m = meminfo()
    rapport = {
        "profil": PROFIL, "scenario": SCENARIO, "palier_s": PALIER_S,
        "noyau": os.uname().release, "machine": os.uname().machine,
        "memtotal_mo": m["MemTotal"], "swap_zram_mo": m.get("SwapTotal", 0),
        "demarrage_s": round(float(lire("/proc/uptime").split()[0]), 1),
        "reglages": etat_memoire(),
        "chromium": chromium_present(),
        "paliers": [],
    }
    P = rapport["paliers"]

    lancer("hub", [sys.executable, "-c", ALLOUEUR, "40"])
    activite("accueil")
    rapport["ui_premiere_image_ms"] = lancer_ui()
    P.append(palier("Accueil", PALIER_S, ["interface", "hub"]))
    rapport["capture_accueil"] = capture("accueil")

    if SCENARIO == "complet":
        if chromium_present():
            activite("youtube")
            lancer_chromium()
            P.append(palier("YouTube (Chromium)", PALIER_S * 2, ["interface", "hub", "chromium"]))
            capture("youtube")
            arreter("chromium")
            activite("accueil")
            P.append(palier("Retour à l'accueil", PALIER_S // 2, ["interface", "hub"]))

        activite("lecture")
        lancer_lecteur()
        P.append(palier("Twitch (lecteur 1080p60)", PALIER_S, ["interface", "hub", "lecteur"]))
        arreter("lecteur")

        arreter("hub")
        lancer("hub", [sys.executable, "-c", ALLOUEUR, "70"])
        lancer("mise_a_jour", [sys.executable, "-c", MISE_A_JOUR, f"{MEDIAS}/bundle.bin"])
        roles = ["interface", "hub", "lecteur", "mise_a_jour"]
        if chromium_present():
            activite("youtube")
            lancer_chromium()
            roles.append("chromium")
        lancer_lecteur()
        P.append(palier("Pire cas", PALIER_S * 2, roles))

        if chromium_present():
            arreter("chromium")
            lancer_chromium(fuite_mo=600)
            P.append(palier("Pire cas après 2 h de YouTube", PALIER_S * 2, roles))

        for role in ("chromium", "lecteur", "mise_a_jour"):
            arreter(role)
        activite("accueil")

    rapport["entretien"] = cout_entretien()
    rapport["reglages_fin"] = etat_memoire()
    rapport["oom_kills_total"] = vmstat("oom_kill")
    rapport["interface_vivante_fin"] = vivant("interface")
    for role in list(PROCS):
        arreter(role)
    # Journaux de nos scripts système, pour comprendre un échec.
    for nom in ("memoire", "entretien"):
        texte = lire(f"/var/log/tele/{nom}.log")
        if texte:
            with open(f"{SORTIE}/{PROFIL}-{nom}.log", "w") as f:
                f.write(texte)
    with open(f"{SORTIE}/{PROFIL}.json", "w") as f:
        json.dump(rapport, f, ensure_ascii=False, indent=2)
    journal(f"rapport écrit : {SORTIE}/{PROFIL}.json")


if __name__ == "__main__":
    main()
