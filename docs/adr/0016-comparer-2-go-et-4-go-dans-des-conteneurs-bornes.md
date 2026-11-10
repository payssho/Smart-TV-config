# 0016. Comparer 2 Go et 4 Go dans des conteneurs à mémoire bornée

- Statut : acceptée
- Date : 2026-11-06

## Contexte

La box n'est pas encore achetée : Marius vise une S905X3 2 Go d'occasion, 4 Go en repli (ADR 0017). Marius veut voir la différence avant d'avoir le matériel. L'image Buildroot n'existe pas encore (J5), et le conteneur de l'agent n'a ni KVM ni GPU : une émulation complète en QEMU aarch64 (TCG) serait 10 à 50 fois plus lente qu'un Cortex-A55, donc inutile pour juger la fluidité, et longue à monter pour juger la mémoire.

## Options envisagées

1. **Conteneurs Docker bornés** à ce que Linux voit sur la box (1 700 Mo pour 2 Go, 3 500 Mo pour 4 Go, après la zone CMA, le firmware et le trou d'adressage), avec les vrais programmes : l'app Flutter, Chromium, un décodage 1080p60. Rapide (environ 10 minutes), reproductible sur le poste de Marius, en CI et dans le conteneur de l'agent.
2. QEMU aarch64 `-m 2G` / `-m 4G` avec une distribution générique : fidèle à l'architecture, mais ni notre image ni flutter-pi, et des minutes de démarrage pour peu d'information de plus.
3. Attendre la box et brider sa RAM avec `mem=2G` : la mesure de référence, mais pas avant la phase 1.

## Décision

Option 1 tout de suite (`scripts/emulation/lancer.sh`, rapports dans `scripts/emulation/resultats/`). QEMU arrive avec notre image en J5, et `mem=2G` sur la vraie box en phase 1 (#43) : ces deux mesures remplaceront celles du banc.

## Conséquences

- Les mesures sont des ordres de grandeur. L'interface y passe par GTK et un rendu logiciel, plus gourmands que flutter-pi : ses chiffres sont un plafond haut. Pas de zram dans le banc.
- Le hub et la mise à jour sont simulés par des blocs de mémoire de la bonne taille ; la dérive de Chromium après 2 h est une estimation (600 Mo) à confirmer.
- Le banc applique déjà les règles du plan (un seul processus de rendu Chromium, Chromium premier tué par l'OOM) : il vérifie qu'elles protègent l'interface.
- Premier résultat (2026-11-06) : 4 Go tient tout ; 2 Go tient une soirée normale mais perd l'onglet YouTube après la dérive de Chromium. Détail dans `docs/emulation-memoire.md`. Le 2026-11-10, Marius retient 2 Go d'abord, avec une maintenance mémoire qui ne dégrade jamais l'expérience (ADR 0017).
