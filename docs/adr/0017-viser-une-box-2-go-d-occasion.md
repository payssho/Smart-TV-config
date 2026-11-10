# 0017. Viser d'abord une box S905X3 2 Go d'occasion, 4 Go en repli

- Statut : acceptée
- Date : 2026-11-10

## Contexte

L'ADR 0001 retenait une box S905X3 en 4/32 Go, et une HK1 4/32 Go avait été choisie le 2026-11-03. Elle n'a finalement **pas été commandée**. Le 2026-11-10, Marius décide de faire une première version sur **2 Go de RAM**, qu'il juge suffisants avec une bonne optimisation, et de préférence sur un appareil **d'occasion**.

Le banc mémoire du 2026-11-06 (ADR 0016, [résultats](../emulation-memoire.md)) montre que 2 Go tiennent une soirée normale (930 Mo libres sous YouTube) mais que le pire cas (2 h de YouTube, mise à jour en fond, scan Bluetooth) remplit la mémoire et finit par faire tuer l'onglet YouTube, sans toucher à l'interface. Le banc ne faisait tourner ni zram ni aucune maintenance mémoire.

## Options envisagées

1. **S905X3 2 Go d'occasion d'abord**, optimisée (zram, Chromium fermé au retour à l'accueil, maintenance mémoire régulière), 4 Go si l'expérience se dégrade. Moins cher, et le même SoC : le DTB, le noyau et l'image restent les mêmes.
2. S905X3 4 Go neuve tout de suite (HK1 ou H96 Max X3) : plus de marge, mais Marius préfère prouver que 2 Go suffisent.
3. Amlogic S905X (plan B de l'ADR 0001) : moins chère encore, mais GPU et processeur plus anciens. Reste le plan B si aucune S905X3 ne démarre.

## Décision

Option 1. On cherche une box **S905X3 2 Go** d'occasion (X96 Max+, HK1, H96 Max X3 ou équivalent), avec une S905X3 **4 Go** en repli. Tout le reste de l'ADR 0001 tient : même SoC, Ethernet d'abord, mêmes modèles rejetés. Les specs du hub et la checklist de la phase 1 ne se figent pas sur un modèle tant que la box n'est pas achetée.

## Conséquences

- L'interface, Chromium et le hub se conçoivent pour 2 Go : un seul processus de rendu Chromium, miniatures libérées pendant la vidéo, zram, Chromium premier tué par l'OOM.
- La maintenance mémoire tourne quand rien n'est à l'écran ou pendant les temps morts, **jamais au prix de la fluidité ni de l'expérience** : pas de vidage de cache pendant une lecture, pas de saccade à l'accueil.
- Tout s'avance sans matériel, sur une copie émulée de la box en 2 Go et en 4 Go ; le test physique vient à la réception.
- On passe en 4 Go si, sur la box ou la copie émulée, une soirée normale saccade, ou si l'onglet YouTube est tué alors que les règles ci-dessus sont en place. Le changement ne touche ni le code ni l'image.
- Une box d'occasion peut avoir un Android modifié ou une eMMC usée : on vérifie Android et on sauvegarde l'eMMC à la réception (ADR 0018).
