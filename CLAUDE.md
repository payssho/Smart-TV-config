# CLAUDE.md

Projet personnel de Marius : OS de télé maison sur box Amlogic S905X3 (4/32 Go), noyau mainline, interface Flutter via flutter-pi. La box est aussi le hub domotique de la maison (dépôt voisin `payssho/Home-device-manager`). Répondre, commenter le code et écrire l'interface en français.

## Règles

- Ne jamais écrire sur l'eMMC de la box (Android d'origine, sert au double démarrage pour Netflix/Canal+) sans accord explicite de Marius (ADR 0003). Les scripts du dépôt ne touchent qu'à la SD ou à l'USB.
- Aucun contournement de DRM. Widevine L3 uniquement, récupéré légalement (ADR 0003).
- Cible 1080p, Ethernet d'abord (ADR 0001, 0002). Navigation 100 % télécommande : croix + OK + retour, focus toujours visible, aucune dépendance au tactile ou à la souris (ADR 0009).
- Le contrat gRPC/Protobuf vit dans Home-device-manager, pas ici (ADR 0012).
- L'interface reprend l'identité « veilleuse » de l'app (tokens de thème, police Bricolage Grotesque) (ADR 0013).
- Matériel rejeté, ne pas reproposer : S905X4/Tanix X4, clés Fire TV/certifiées, Raspberry Pi 5, Rockchip RK3528, Allwinner H313 (ADR 0001).
- Builds Buildroot complets (1–2 h, 15–25 Go) : en GitHub Actions ou sous WSL2 chez Marius, jamais dans le conteneur de l'agent. Ce qui se teste sans la box se teste sans la box (flutter test, QEMU).
- Un ADR par choix technique non trivial dans `docs/adr/` (index dans `docs/adr/README.md`). Une ADR acceptée ne se réécrit pas : on la remplace.
- Une issue = une branche = une PR (`Closes #n`), CI verte avant fusion.

## Commandes

- Vérifs locales de la CI : `scripts/ci/verifier.sh` (shellcheck, markdownlint, index des ADR).
- Diagnostic matériel (sur la box sous Armbian, lecture seule) : `sudo scripts/materiel/diagnostic.sh > rapport.txt`.
- (à remplir : build Buildroot, test QEMU, tests Flutter, flash SD)

## Arborescence

- `docs/` : vision, architecture, roadmap, ADR, matériel.
- `scripts/` : outils shell (CI, diagnostic matériel, plus tard image et flash).
- À venir : `ui/` (app Flutter TV, phase 2), `buildroot/` (arbre `BR2_EXTERNAL`, phase 3).

## Matériel validé

(à remplir après la phase 1 : modèle reçu, DTB, CEC, IR, Wi‑Fi, vidéo ; détail dans `docs/materiel.md`)
