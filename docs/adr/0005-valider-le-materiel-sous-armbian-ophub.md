# 0005. Valider le matériel et prototyper sous Armbian ophub

- Statut : acceptée
- Date : 2026-11-03

## Contexte

Avant d'écrire notre image, il faut savoir ce que la box reçue sait faire en mainline (DTB, CEC, IR, GPU, vidéo, Wi‑Fi). Une erreur de démarrage dans notre image serait difficile à distinguer d'un problème matériel.

## Options envisagées

1. **Armbian ophub** : images prêtes pour S905X3, DTB par modèle, même mécanisme d'amorçage depuis la SD que celui visé.
2. LibreELEC : très bon support AMLGX, mais système figé sur Kodi, peu pratique pour installer des outils.
3. Partir directement sur Buildroot : trop d'inconnues à la fois.

## Décision

Phases 1 et 2 sur Armbian ophub, démarré depuis la SD. Les résultats sont consignés dans `docs/materiel.md`.

## Conséquences

- La config noyau et le DTB de notre image s'inspireront de ceux d'ophub et de LibreELEC.
- Script de diagnostic en lecture seule : `scripts/materiel/diagnostic.sh`.
