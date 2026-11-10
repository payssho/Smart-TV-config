# 0011. Mettre à jour l'image en A/B avec RAUC

- Statut : proposée
- Date : 2026-11-03

## Contexte

La télé doit pouvoir se mettre à jour sans risque de rester bloquée, avec une racine en lecture seule.

## Options envisagées

1. **[RAUC](https://rauc.io)** : A/B, signatures, intégré à Buildroot.
2. SWUpdate : équivalent, un peu plus de configuration.
3. Réécrire la SD à la main : suffisant au début, pas au-delà.

## Décision

RAUC en phase 6. D'ici là, on réécrit la SD.

## Conséquences

- Prévoir deux partitions système sur la SD dès la phase 3 pour ne pas tout reformater plus tard.
- Le choix entre u-boot d'origine et u-boot chaîné (ADR 0006) influence la gestion des slots.
