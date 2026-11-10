# Banc mémoire : box 2 Go contre 4 Go

Le banc fait tourner les briques de la télé dans un conteneur dont la mémoire est bornée à ce que Linux voit sur la box, puis relève la mémoire occupée, le pic et les processus tués par le noyau (OOM). Choix et limites : [ADR 0016](adr/0016-comparer-2-go-et-4-go-dans-des-conteneurs-bornes.md). Mesures réelles sur la box : #43.

## Le lancer

```sh
scripts/emulation/lancer.sh                 # les deux profils, paliers de 40 s (≈ 12 min)
scripts/emulation/lancer.sh --palier 10     # essai rapide
scripts/emulation/lancer.sh --profils 2go   # un seul profil
```

Prérequis : Docker, Flutter (build Linux), ffmpeg et un Chromium (variable `CHROME`, sinon celui de Playwright). En CI : workflow « Banc mémoire », lancé à la main, rapport en artefact. Les rapports vont dans `scripts/emulation/resultats/AAAA-MM-JJ/` : un JSON par profil, `rapport.md`, et `verdict.md` écrit à la main après lecture. `scripts/previsu/construire.sh` reprend le dernier dossier pour le graphique de la prévisu.

## Les profils

| Profil | RAM | Vu par Linux | D'où vient l'écart |
|---|---:|---:|---|
| 2 Go | 2 048 Mo | 1 700 Mo | zone CMA vidéo (256 Mo), firmware et noyau (~90 Mo) |
| 4 Go | 4 096 Mo | 3 500 Mo | idem, plus le trou d'adressage des registres (~250 Mo) |

## Les paliers

1. **Accueil** : interface Flutter, hub (40 Mo).
2. **YouTube** : plus Chromium en kiosque, un seul processus de rendu, sur une page hors ligne façon YouTube TV (vidéo VP9 1080p, vignettes qui défilent, ~60 Mo de tas JS).
3. **Retour à l'accueil** : Chromium fermé, la mémoire doit revenir.
4. **Twitch** : décodage logiciel d'un flux H.264 1080p60 à 8 Mbit/s, à vitesse réelle.
5. **Pire cas** : YouTube, lecteur, hub en scan Bluetooth (70 Mo), mise à jour en fond (120 Mo et lecture continue d'un fichier de 600 Mo).
6. **Pire cas après 2 h** : la même chose quand le tas de Chromium a dérivé de 600 Mo.

## Résultats du 2026-11-06

Mémoire anonyme occupée / restante, en Mo :

| Palier | 2 Go | 4 Go |
|---|---:|---:|
| Accueil | 409 / 1 291 | 406 / 3 094 |
| YouTube | 768 / 932 | 759 / 2 741 |
| Retour à l'accueil | 414 / 1 286 | 415 / 3 085 |
| Twitch | 481 / 1 219 | 479 / 3 021 |
| Pire cas | 1 039 / 662, mémoire pleine | 1 083 / 2 417 |
| Pire cas après 2 h | onglet YouTube tué | 1 679 / 1 821 |

- **4 Go tient tout**, il reste 1,8 Go dans le pire des cas.
- **2 Go tient une soirée normale**, mais le pire cas remplit la mémoire (le noyau vide le cache de fichiers), et après la dérive de Chromium le noyau tue l'onglet YouTube. L'interface, le lecteur et le hub survivent : la règle « Chromium premier tué » marche.
- Retour à l'accueil : la mémoire de Chromium revient entièrement, ce qui justifie de le fermer en quittant YouTube.
- Le lecteur 1080p60 garde la vitesse réelle (1,0 x) dans tous les paliers, mais sur un processeur x86 : rien à en conclure pour la box.
- L'interface pèse ~420 Mo ici, rendu logiciel GTK compris. Sur la box avec flutter-pi, on attend bien moins : à mesurer en J4.

Rapport complet : [`scripts/emulation/resultats/2026-11-06/rapport.md`](../scripts/emulation/resultats/2026-11-06/rapport.md).
