# 0006. Utiliser un noyau mainline et amorcer depuis la SD via le u-boot d'origine

- Statut : proposée
- Date : 2026-11-03

## Contexte

Le u-boot du fabricant, sur l'eMMC, sait chercher un script sur la SD ou l'USB (`s905_autoscript`, `emmc_autoscript`), mécanisme utilisé par ophub et LibreELEC. On ne doit pas toucher à l'eMMC (ADR 0003).

## Options envisagées

1. **Noyau mainline** (6.12 LTS ou plus récent), config et DTB repris d'ophub et LibreELEC, amorçage par le **u-boot d'origine** qui enchaîne sur la SD.
2. Noyau du fabricant (4.9) : décodage matériel complet mais blobs, pas de Panfrost, pas de mises à jour. Contraire à l'ADR 0001.
3. u-boot mainline installé sur l'eMMC : plus propre mais écrit sur l'eMMC. Rejeté.
4. u-boot mainline chaîné depuis la SD : possible plus tard si le u-boot d'origine limite.

## Décision

Noyau mainline, u-boot d'origine qui enchaîne sur un script de la SD.

## Conséquences

- Démarrage dépendant du u-boot de chaque modèle : vérifier en phase 1 (risque R5).
- Un adaptateur USB-série 3,3 V est fortement conseillé : sans console, un échec est muet.
