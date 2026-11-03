# Roadmap

Chaque phase livre quelque chose d'utilisable et se termine par une démo sur la vraie télé. Ce fichier donne l'objectif et le critère de fin ; **l'état réel vit dans les [milestones GitHub](https://github.com/payssho/Smart-TV-config/milestones)** et leurs issues. Après chaque phase : courte rétro dans `docs/journal.md`, puis révision de cette roadmap.

Les phases 1 et 2 servent de spikes pour les risques bloquants R1 à R5 de la [vision](vision.md#risques-techniques).

## Phase 0. Cadrage du dépôt

- **Objectif** : un agent sans contexte peut reprendre le projet en lisant le dépôt.
- **Fin** : README, CLAUDE.md, docs, ADR des choix déjà faits, CI verte, milestones et issues créées, usages priorisés.
- **Tâches** : structurer le dépôt et consigner les ADR · mettre en place la CI · prioriser les usages de la télé.

## Phase 1. Validation du matériel sous Armbian ophub

- **Objectif** : savoir exactement ce que la box reçue sait faire sous Linux mainline.
- **Fin** : `docs/materiel.md` rempli (modèle, DTB retenu, HDMI, Ethernet, GPU, CEC, IR, Wi‑Fi, Bluetooth, vidéo), CLAUDE.md à jour, rapport `scripts/materiel/diagnostic.sh` versionné.
- **Tâches** : démarrer Armbian et choisir le DTB · valider HDMI 1080p, Ethernet et Panfrost · valider le CEC avec la télé · valider l'infrarouge · mesurer le décodage 1080p · identifier Wi‑Fi et Bluetooth · rédiger le rapport.
- **Préparation** : [checklist de la phase 1](materiel/checklist-phase-1.md).
- **Dépendances** : la box. Les tâches après le démarrage se font en parallèle.

## Phase 2. Interface sur Armbian

- **Objectif** : une app Flutter plein écran sur la télé, pilotée à la télécommande. Point de non-retour technique.
- **Fin** : « hello TV » via flutter-pi sur la box, navigation au CEC et à l'IR, ADR qui confirme flutter-pi ou bascule sur `cage`.
- **Tâches** : créer l'app Flutter TV et sa CI · poser le thème « veilleuse » et la navigation au focus · compiler flutter-pi pour la box · lancer « hello TV » sur la télé · naviguer à la télécommande · trancher flutter-pi ou cage.
- **Dépendances** : les deux premières tâches avancent sans la box, dès maintenant.

## Phase 3. Image Buildroot

- **Objectif** : notre propre image qui démarre directement sur l'interface.
- **Fin** : `.img.xz` construite en CI et publiée en artefact, démarrage depuis la SD via le u-boot d'origine, interface affichée en moins de 15 s.
- **Tâches** : arbre `BR2_EXTERNAL` et defconfig QEMU · build en GitHub Actions avec cache · test de l'espace utilisateur dans QEMU · noyau mainline et DTB de la box · amorçage depuis la SD · empaqueter flutter-pi et l'app.
- **Dépendances** : phase 1 (DTB, config noyau) pour la partie box ; la partie QEMU peut commencer avant.

## Phase 4. Lecteur vidéo et premiers usages

- **Objectif** : regarder ses vidéos et un premier service sur la télé.
- **Fin** : lecture 1080p de fichiers locaux ou réseau, premier service choisi par Marius, télé allumée et mise en veille par CEC.
- **Tâches** : écran d'accueil · lecteur vidéo · premier service (Jellyfin, IPTV… selon la priorisation) · commandes CEC actives.

## Phase 5. Hub intégré

- **Objectif** : piloter la maison depuis la télé et depuis le S25 via la box.
- **Fin** : hub Rust dans l'image, écran domotique sur la télé, l'app du S25 trouve la box en mDNS.
- **Tâches** : empaqueter le hub · client gRPC et écran domotique · annonce mDNS.
- **Dépendances** : le hub et le contrat Protobuf dans `payssho/Home-device-manager`.

## Phase 6. Solidité

- **Objectif** : une télé qu'on n'a plus besoin de réparer.
- **Fin** : racine en lecture seule, mise à jour A/B RAUC avec retour arrière, Wi‑Fi si la puce le permet, bouton « redémarrer sous Android ».
- **Tâches** : racine en lecture seule · mises à jour RAUC · Wi‑Fi · redémarrer sous Android (mécanisme à valider avec Marius, sans écriture sur l'eMMC sans son accord).

## Phase 7. Extras

- **Tâches** : Chromium + Widevine L3 obtenu légalement · recopie d'écran depuis le S25 · accès distant (WireGuard ou Tailscale).
