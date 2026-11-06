#!/usr/bin/env python3
"""Met en forme les rapports JSON du banc (un par profil) en Markdown."""

import json
import pathlib
import sys

dossier = pathlib.Path(sys.argv[1])
rapports = [json.loads(p.read_text()) for p in sorted(dossier.glob("*go.json"))]
if not rapports:
    sys.exit(f"Aucun rapport dans {dossier}")

ROLES = [
    ("interface", "Interface Flutter"),
    ("chromium", "Chromium"),
    ("lecteur", "Lecteur 1080p60"),
    ("hub", "Hub (simulé)"),
    ("mise_a_jour", "Mise à jour (simulée)"),
    ("affichage", "Xvfb (absent sur la box)"),
    ("systeme", "Banc et système"),
]


def nombre(v, unite=""):
    return "n/a" if v is None else f"{v:g}{unite}"


print(f"# Banc mémoire du {rapports[0]['debut'][:10]}\n")
print("Profils : " + ", ".join(
    f"{r['profil']} ({r['limite_mo']} Mo vus par Linux)" for r in rapports) + ".")
print(f"Paliers de {rapports[0]['palier_s']} s ; valeurs en Mo, régime établi.\n")

print("## Vue d'ensemble\n")
entete = "| Palier | " + " | ".join(
    f"{r['profil']} : utilisée / libre | {r['profil']} : pic | {r['profil']} : tués (OOM)"
    for r in rapports) + " |"
print(entete)
print("|---|" + "---:|---:|---:|" * len(rapports))
for i, p in enumerate(rapports[0]["paliers"]):
    cellules = []
    for r in rapports:
        q = r["paliers"][i]
        cellules += [
            f"{q['anon_mo']:g} / {nombre(q['libre_mo'])}",
            nombre(q.get("pic_mo")) + (" (plein)" if q.get("pic_mo", 0) >= r["limite_mo"] - 5 else ""),
            str(q["oom_kills"]),
        ]
    print(f"| {p['nom']} | " + " | ".join(cellules) + " |")

print("\n« Utilisée » = mémoire anonyme (tas, piles), non récupérable sans tuer. "
      "Le cache de fichiers vient en plus mais se libère sous pression. "
      "« Pic » = mémoire totale la plus haute du palier, cache compris ; "
      "« plein » = le plafond de la box a été atteint.\n")

print("## Détail par brique")
for r in rapports:
    print(f"\n### {r['profil']}\n")
    print(f"- Première image de l'interface : {nombre(r.get('ui_premiere_image_ms'), ' ms')}")
    print(f"- Pic mémoire du conteneur : {nombre(r.get('pic_global_mo'), ' Mo')}")
    print(f"- Processus tués par l'OOM : {nombre(r.get('oom_kills_total'))}\n")
    print("| Palier | " + " | ".join(n for _, n in ROLES) + " | Lecteur (vitesse) | Survivants |")
    print("|---|" + "---:|" * len(ROLES) + "---:|---|")
    for p in r["paliers"]:
        roles = p["roles_mo"]
        morts = [k for k, v in p["vivants"].items() if not v]
        print(f"| {p['nom']} | " + " | ".join(nombre(roles.get(k)) for k, _ in ROLES)
              + f" | {nombre(p.get('lecteur_vitesse'), ' x')}"
              + f" | {'tous' if not morts else 'tués : ' + ', '.join(morts)} |")
