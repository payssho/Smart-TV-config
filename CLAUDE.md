# CLAUDE.md

Projet personnel de Marius : OS de télé maison sur box Amlogic S905X3 (2 Go d'occasion visée, 4 Go en repli, ADR 0017), noyau mainline, interface Flutter via flutter-pi. La box est aussi le hub domotique de la maison (dépôt voisin `payssho/Home-device-manager`). Répondre, commenter le code et écrire l'interface en français.

## Règles

- eMMC de la box (Android d'origine, sert au double démarrage pour Netflix/Canal+) : écriture permise quand elle sert le projet, **après une sauvegarde complète vérifiée** ; Android doit rester démarrable ; un script qui écrit sur l'eMMC le dit, vérifie la sauvegarde et demande confirmation (ADR 0018).
- Aucun contournement de DRM, et pas de recherche d'outils pour le faire. Netflix et Canal+ passent par l'Android d'origine en double démarrage ; dans notre OS, Widevine L3 uniquement, récupéré légalement (ADR 0003).
- Usages prioritaires : YouTube et Twitch dans notre OS, Netflix et Canal+ sous Android (ADR 0014).
- Interface en trois onglets : Regarder (les apps), Ambiance (préréglages de l'OS et de la pièce), Réglages. Les lumières de la maison se gèrent dans l'app mobile Home device manager, qui sert aussi de télécommande de la télé (#46). Le moins de texte possible à l'écran.
- Démarrage : fiable à 100 % d'abord, rapide ensuite.
- Conçu pour 2 Go : la maintenance mémoire ne doit jamais dégrader la fluidité ni l'expérience (ADR 0017). Stockage plafonné dans la durée (#45).
- Cible 1080p, Ethernet d'abord (ADR 0001, 0002). Navigation 100 % télécommande : croix + OK + retour, focus toujours visible, aucune dépendance au tactile ou à la souris (ADR 0009).
- Le contrat gRPC/Protobuf vit dans Home-device-manager, pas ici (ADR 0012).
- L'interface reprend l'identité « veilleuse » de l'app (tokens de thème, police Bricolage Grotesque) (ADR 0013).
- Matériel rejeté, ne pas reproposer : S905X4/Tanix X4, clés Fire TV/certifiées, Raspberry Pi 5, Rockchip RK3528, Allwinner H313 (ADR 0001).
- Builds Buildroot complets (1–2 h, 15–25 Go) : en GitHub Actions ou sous WSL2 chez Marius, jamais dans le conteneur de l'agent. Ce qui se teste sans la box se teste sans la box (flutter test, QEMU) : en attendant le matériel, tout s'avance sur une copie émulée de la box en 2 Go et 4 Go.
- Un ADR par choix technique non trivial dans `docs/adr/` (index dans `docs/adr/README.md`). Une ADR acceptée ne se réécrit pas : on la remplace.
- Une issue = une branche = une PR (`Closes #n`), CI verte avant fusion.
- Après chaque phase : courte rétro dans `docs/journal.md`.

## Commandes

- Vérifs locales de la CI : `scripts/ci/verifier.sh` (shellcheck, markdownlint, index des ADR).
- Milestones GitHub (une par phase, issues rangées par label `phase-N`) : `scripts/github/creer-milestones.sh` (CLI gh).
- Diagnostic matériel (sur la box sous Armbian, lecture seule) : `sudo scripts/materiel/diagnostic.sh > rapport.txt`.
- Prévisu de l'interface : `maquette/banc-interface.html`, publiée comme page Claude (voir `maquette/README.md`).
- Interface Flutter : `cd ui && flutter test` ; prévisu publiable : `scripts/previsu/construire.sh` (ADR 0015, détail dans `ui/README.md`).
- Banc mémoire 2 Go / 4 Go : `scripts/emulation/lancer.sh` (Docker, environ 12 min, ADR 0016, résultats dans `docs/emulation-memoire.md`).
- (à remplir : build Buildroot, test QEMU, flash SD)

## Arborescence

- `docs/` : vision, architecture, roadmap, plan de réalisation (jalons, budget mémoire, stockage), journal des phases, ADR, matériel.
- `maquette/` : banc de prévisu HTML de l'interface (profils 2 Go et 4 Go).
- `scripts/` : outils shell (CI, diagnostic matériel, plus tard image et flash).
- `ui/` : app Flutter TV (trois onglets, ambiances, feu de cheminée), testable sans la box.
- À venir : `buildroot/` (arbre `BR2_EXTERNAL`, phase 3).

## Matériel validé

- Télé : Philips 1080p (modèle exact à relever), HDMI 1 ARC + HDMI 2, CEC « EasyLink ». Box sur HDMI 2.
- Box : pas encore achetée (2026-11-10). Visée : S905X3 2 Go d'occasion, 4 Go en repli (ADR 0017). La HK1 4/32 Go envisagée le 2026-11-03 n'a pas été commandée.
- (à remplir après la phase 1 : modèle reçu, DTB, CEC, IR, Wi‑Fi, vidéo ; détail dans `docs/materiel.md`)
