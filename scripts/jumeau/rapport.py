#!/usr/bin/env python3
"""Rapport Markdown du jumeau : compare les profils 2 Go et 4 Go.

Usage : rapport.py <dossier de résultats>   (écrit sur la sortie standard)
Code de sortie 1 si une règle du plan est violée : interface ou hub tués,
interface absente en fin de scénario, ou entretien qui ne s'efface pas
pendant la lecture.
"""

import json
import os
import sys

dossier = sys.argv[1]
profils = [p for p in ("2go", "4go") if os.path.exists(f"{dossier}/{p}.json")]
if not profils:
    sys.exit(f"Aucun rapport dans {dossier}")
R = {p: json.load(open(f"{dossier}/{p}.json")) for p in profils}
NOMS = {"2go": "2 Go", "4go": "4 Go"}
problemes = []


def cellule(p, nom):
    for pal in R[p]["paliers"]:
        if pal["nom"] == nom:
            morts = [r for r, v in pal["vivants"].items() if not v]
            texte = f"{pal['occupee_mo']} / {pal['min_disponible_mo']}"
            if pal["swap_mo"]:
                texte += f" · zram {pal['swap_mo']}→{pal['zram_ram_mo']}"
            if morts:
                texte += " · **tué : " + ", ".join(morts) + "**"
                if {"interface", "hub"} & set(morts):
                    problemes.append(f"{NOMS[p]}, {nom} : {', '.join(morts)} tué")
            return texte
    return "—"


print("# Jumeau de la box : 2 Go contre 4 Go\n")
r0 = R[profils[0]]
print(f"Noyau {r0['noyau']} ({r0['machine']}), scénario « {r0['scenario']} », "
      f"paliers de {r0['palier_s']} s, Chromium {'présent' if r0['chromium'] else 'absent'}.\n")

print("| | " + " | ".join(NOMS[p] for p in profils) + " |")
print("|---|" + "---:|" * len(profils))
lignes = [
    ("RAM vue par Linux (Mo)", lambda r: r["memtotal_mo"]),
    ("Swap zram (Mo)", lambda r: r["swap_zram_mo"]),
    ("Démarrage jusqu'au scénario (s, émulé)", lambda r: r["demarrage_s"]),
    ("Première image de l'interface (ms, émulé)", lambda r: r.get("ui_premiere_image_ms") or "—"),
    ("OOM au total", lambda r: r["oom_kills_total"]),
]
for titre, f in lignes:
    print(f"| {titre} | " + " | ".join(str(f(R[p])) for p in profils) + " |")

print("\n## Mémoire par palier\n")
print("Occupée / disponible au plus bas, en Mo. « zram A→B » : A Mo de tas "
      "inactif compressés dans B Mo de RAM.\n")
noms = []
for p in profils:
    for pal in R[p]["paliers"]:
        if pal["nom"] not in noms:
            noms.append(pal["nom"])
print("| Palier | " + " | ".join(NOMS[p] for p in profils) + " |")
print("|---|" + "---|" * len(profils))
for nom in noms:
    print(f"| {nom} | " + " | ".join(cellule(p, nom) for p in profils) + " |")

print("\n## Coût de l'entretien\n")
print("Travail de référence : décoder 90 images 1080p, médiane de 3 essais, en "
      "secondes émulées. Seul compte l'écart en %.\n")
print("| | " + " | ".join(NOMS[p] for p in profils) + " |")
print("|---|" + "---:|" * len(profils))
lignes = [
    ("Référence seule (s)", "seul_s"),
    ("Pendant une lecture, entretien en boucle (s)", "pendant_lecture_s"),
    ("Surcoût pendant la lecture (%)", "surcout_lecture_pourcent"),
    ("Durée d'un passage repoussé (ms)", "passage_repousse_ms"),
    ("Garde quand le processeur travaille", "dernier_etat_processeur_occupe"),
    ("Pire cas : ménage forcé en même temps (s)", "pendant_menage_s"),
    ("Surcoût du ménage forcé (%)", "surcout_menage_pourcent"),
    ("Durée du ménage au repos (s)", "menage_duree_s"),
    ("Cache Chromium avant → après (Mo)", None),
]
for titre, cle in lignes:
    if cle:
        vals = [str(R[p]["entretien"].get(cle, "—")) for p in profils]
    else:
        vals = [f"{R[p]['entretien']['cache_avant_mo']} → {R[p]['entretien']['cache_apres_mo']} "
                f"(plafond {R[p]['entretien']['plafond_mo']})" for p in profils]
    print(f"| {titre} | " + " | ".join(vals) + " |")

for p in profils:
    e = R[p]["entretien"]
    if not str(e.get("dernier_etat_lecture", "")).startswith("repousse"):
        problemes.append(f"{NOMS[p]} : l'entretien a travaillé pendant une lecture")
    if not str(e.get("dernier_etat_processeur_occupe", "")).startswith("repousse"):
        problemes.append(f"{NOMS[p]} : l'entretien a travaillé alors que le processeur était occupé")
    if e.get("dernier_etat_repos") != "fait":
        problemes.append(f"{NOMS[p]} : l'entretien n'a pas fait le ménage au repos")
    if e["cache_apres_mo"] > e["plafond_mo"]:
        problemes.append(f"{NOMS[p]} : cache au-dessus du plafond après l'entretien")
    if not R[p].get("interface_vivante_fin"):
        problemes.append(f"{NOMS[p]} : interface absente en fin de scénario")

print("\n## Réglages appliqués par tele-memoire\n")
cles = sorted({k for p in profils for k in R[p]["reglages_fin"]})
print("| | " + " | ".join(NOMS[p] for p in profils) + " |")
print("|---|" + "---:|" * len(profils))
for k in cles:
    print(f"| {k} | " + " | ".join(R[p]["reglages_fin"].get(k, "—") for p in profils) + " |")

captures = sorted(n for n in os.listdir(dossier) if n.endswith(".png"))
if captures:
    print("\n## Captures de l'écran du jumeau\n")
    for n in captures:
        print(f"- [{n}]({n})")

print("\n## Verdict automatique\n")
if problemes:
    for pb in problemes:
        print(f"- ✗ {pb}")
else:
    print("- ✓ Interface et hub jamais tués, entretien effacé pendant la lecture, caches sous plafond.")
sys.exit(1 if problemes else 0)
