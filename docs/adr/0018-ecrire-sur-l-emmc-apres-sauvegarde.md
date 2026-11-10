# 0018. Autoriser l'écriture sur l'eMMC quand elle sert le projet, après une sauvegarde complète

- Statut : acceptée
- Date : 2026-11-10

## Contexte

L'ADR 0003 interdisait d'écrire sur l'eMMC de la box sans accord explicite de Marius, pour protéger l'Android d'origine qui sert à Netflix et Canal+. Cette règle bloque des choses utiles : écrire une variable d'environnement u-boot pour le bouton « redémarrer sous Android » (#33), installer un u-boot plus fiable que celui du fabricant (option rejetée dans l'ADR 0006), ou déplacer une partie de notre OS sur l'eMMC si la carte SD se montre lente ou peu fiable.

Le 2026-11-10, Marius autorise l'écriture sur l'eMMC dès qu'elle permet d'atteindre les objectifs du projet. Le double démarrage et l'interdiction de contourner les DRM, eux, ne changent pas (ADR 0003).

## Options envisagées

1. **Écriture autorisée, avec une sauvegarde complète vérifiée avant la première écriture** : on garde la liberté, et un retour à l'état d'usine reste possible.
2. Écriture autorisée sans garde-fou : plus simple, mais une erreur sur la partition d'Android ou de son u-boot rend la box inutilisable pour Netflix et Canal+, et sans adaptateur USB-série elle reste muette.
3. Garder l'interdiction de l'ADR 0003 : rejetée par Marius.

## Décision

Option 1. Cette ADR remplace la règle « jamais d'écriture sur l'eMMC sans accord » de l'ADR 0003, et rien d'autre : le double démarrage et l'interdiction de contourner les DRM restent.

Garde-fous :

1. **Sauvegarde d'abord** : avant la toute première écriture, image complète de l'eMMC (partitions et zones de démarrage) copiée hors de la box, avec son empreinte SHA-256, et vérifiée en relisant la copie.
2. **Android reste démarrable** : une écriture ne doit pas casser l'Android d'origine sans une décision écrite (nouvelle ADR).
3. **Scripts explicites** : un script qui écrit sur l'eMMC le dit dans son nom ou son aide, vérifie que la sauvegarde existe, et demande une confirmation avant d'écrire.
4. **Procédure de retour** : la restauration de la sauvegarde est écrite et testée une fois.

## Conséquences

- Le bouton « redémarrer sous Android » peut écrire l'environnement u-boot sans nouvelle demande, une fois la sauvegarde faite (#33).
- L'option « u-boot mainline sur l'eMMC » de l'ADR 0006 redevient envisageable si le u-boot d'origine se montre peu fiable.
- `scripts/materiel/diagnostic.sh` reste en lecture seule : il sert à observer, pas à modifier.
- La sauvegarde de l'eMMC devient la première étape à la réception de la box (checklist de la phase 1).
