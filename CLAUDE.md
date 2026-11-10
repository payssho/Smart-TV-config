# CLAUDE.md

Projet personnel de Marius : OS de télé maison sur box Amlogic S905X3 (4/32 Go), noyau mainline, interface Flutter via flutter-pi. La box est aussi le hub domotique de la maison (dépôt voisin `payssho/Home-device-manager`). Répondre, commenter le code et écrire l'interface en français.

## Règles

- Ne jamais écrire sur l'eMMC de la box (Android d'origine, sert au double démarrage pour Netflix/Canal+) sans accord explicite de Marius (ADR 0003). Les scripts du dépôt ne touchent qu'à la SD ou à l'USB.
- Aucun contournement de DRM. Widevine L3 uniquement, récupéré légalement (ADR 0003).
- Usages prioritaires : YouTube et Twitch dans notre OS, Netflix et Canal+ sous Android (ADR 0014).
- Cible 1080p, Ethernet d'abord (ADR 0001, 0002). Navigation 100 % télécommande : croix + OK + retour, focus toujours visible, aucune dépendance au tactile ou à la souris (ADR 0009).
- Le contrat gRPC/Protobuf vit dans Home-device-manager, pas ici (ADR 0012).
- L'interface reprend l'identité « veilleuse » de l'app (tokens de thème, police Bricolage Grotesque) (ADR 0013).
- Matériel rejeté, ne pas reproposer : S905X4/Tanix X4, clés Fire TV/certifiées, Raspberry Pi 5, Rockchip RK3528, Allwinner H313 (ADR 0001).
- Builds Buildroot complets (1–2 h, 15–25 Go) : en GitHub Actions ou sous WSL2 chez Marius, jamais dans le conteneur de l'agent. Ce qui se teste sans la box se teste sans la box (flutter test, jumeau QEMU) : tant que la box n'est pas là, chaque phase avance sur le jumeau (ADR 0019), et ce qu'il ne couvre pas est noté « à valider sur la box ».
- Un ADR par choix technique non trivial dans `docs/adr/` (index dans `docs/adr/README.md`). Une ADR acceptée ne se réécrit pas : on la remplace.
- Une issue = une branche = une PR (`Closes #n`), CI verte avant fusion.

## Commandes

- Vérifs locales de la CI : `scripts/ci/verifier.sh` (shellcheck, markdownlint, index des ADR).
- Milestones GitHub (une par phase, issues rangées par label `phase-N`) : `scripts/github/creer-milestones.sh` (CLI gh).
- Diagnostic matériel (sur la box sous Armbian, lecture seule) : `sudo scripts/materiel/diagnostic.sh > rapport.txt`.
- Prévisu de l'interface : `maquette/banc-interface.html`, publiée comme page Claude (voir `maquette/README.md`).
- Interface Flutter : `cd ui && flutter test` ; prévisu publiable : `scripts/previsu/construire.sh` (ADR 0015, détail dans `ui/README.md`).
- Banc mémoire 2 Go / 4 Go : `scripts/emulation/lancer.sh` (Docker, environ 12 min, ADR 0016, résultats dans `docs/emulation-memoire.md`).
- Scripts système de la box (`systeme/` : zram, réglages mémoire, entretien au repos, ADR 0020) : `systeme/tests/tester.sh`.
- Jumeau numérique de la box (QEMU arm64, 2 Go / 4 Go, ADR 0019) : `scripts/jumeau/construire-image.sh` puis `scripts/jumeau/lancer.sh` ; en CI, workflow « Jumeau de la box ». Guide : `docs/jumeau.md`.
- (à remplir : build Buildroot, flash SD)

## Arborescence

- `docs/` : vision, architecture, roadmap, plan de réalisation (jalons, budget mémoire), ADR, matériel.
- `maquette/` : banc de prévisu HTML de l'interface (profils 2 Go et 4 Go).
- `scripts/` : outils shell (CI, diagnostic matériel, plus tard image et flash).
- `ui/` : app Flutter TV (onglets, ambiances, feu de cheminée), testable sans la box.
- `systeme/` : fichiers système de la box (futur overlay Buildroot) : `tele-memoire`, `tele-entretien`, `tele-role`, `/etc/tele/memoire.conf`, unités systemd.
- `scripts/jumeau/` : jumeau QEMU de la box (image arm64, lanceur, scénario, rapport).
- À venir : `buildroot/` (arbre `BR2_EXTERNAL`, phase 3).

## Matériel validé

- Télé : Philips 1080p (modèle exact à relever), HDMI 1 ARC + HDMI 2, CEC « EasyLink ». Box sur HDMI 2.
- Box : pas encore commandée (2026-11-03).
- (à remplir après la phase 1 : modèle reçu, DTB, CEC, IR, Wi‑Fi, vidéo ; détail dans `docs/materiel.md`)
