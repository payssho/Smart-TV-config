# Roadmap

Chaque phase livre quelque chose d'utilisable et se termine par une démo sur la vraie télé. Ce fichier donne l'objectif et le critère de fin ; **l'état réel vit dans les [milestones GitHub](https://github.com/payssho/Smart-TV-config/milestones)** et leurs issues. Après chaque phase : courte rétro dans `docs/journal.md`, puis révision de cette roadmap.

L'ordre, les dépendances, les dates indicatives et le budget mémoire sont dans le [plan de réalisation](plan-de-realisation.md) (jalons J0 à J10).

Les phases 1 et 2 servent de spikes pour les risques bloquants R1 à R5 de la [vision](vision.md#risques-techniques).

**Sans attendre la box** : la box n'est pas encore achetée (ADR 0017). Chaque phase s'avance d'abord sur une copie émulée de la box en 2 Go et en 4 Go ; la démo sur la vraie télé vient à la réception, quitte à corriger ce qui diffère.

## Phase 0. Cadrage du dépôt

- **Objectif** : un agent sans contexte peut reprendre le projet en lisant le dépôt.
- **Fin** : README, CLAUDE.md, docs, ADR des choix déjà faits, CI verte, milestones et issues créées, usages priorisés.
- **Tâches** : structurer le dépôt et consigner les ADR · mettre en place la CI · prioriser les usages de la télé.

### Usages priorisés (Now / Next / Later)

| Horizon | Usage | Où | Phase |
|---|---|---|---|
| Now (dès la réception de la box, après la sauvegarde de l'eMMC) | Netflix, Canal+, YouTube, Twitch | Android d'origine, tel quel | 1 |
| Next | YouTube (`youtube.com/tv`, envoi depuis le S25) | Notre OS, Chromium kiosque | 4 |
| Next | Twitch | Notre OS, écran natif | 4 |
| Next | Bouton « redémarrer sous Android » pour Netflix et Canal+ | Notre OS | 4 |
| Later | IPTV, médias locaux, Jellyfin | Notre OS | 7 |
| Later | Recopie d'écran, Chromium + Widevine L3 | Notre OS | 7 |

Choix et limites : ADR 0014. Netflix et Canal+ ne tourneront jamais en bonne qualité dans notre OS (Widevine L3, ADR 0003).

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
- **Fin** : `.img.xz` construite en CI et publiée en artefact, démarrage depuis la SD via le u-boot d'origine, interface atteinte à **chaque** démarrage (100 démarrages d'affilée sans échec), puis durée réduite au mieux (cible indicative 15 s).
- **Tâches** : arbre `BR2_EXTERNAL` et defconfig QEMU · build en GitHub Actions avec cache · test de l'espace utilisateur dans QEMU · noyau mainline et DTB de la box · amorçage depuis la SD · empaqueter flutter-pi et l'app.
- **Dépendances** : phase 1 (DTB, config noyau) pour la partie box ; la partie QEMU peut commencer avant.

## Phase 4. Lecteur vidéo et premiers usages

- **Objectif** : les quatre usages prioritaires depuis notre écran d'accueil (ADR 0014).
- **Fin** : YouTube et Twitch en 1080p dans notre OS, Netflix et Canal+ à un bouton (redémarrage sous Android), télé allumée et mise en veille par CEC.
- **Tâches** : écran d'accueil · lecteur vidéo (HLS, fichiers) · Chromium kiosque et YouTube TV · Twitch natif · redémarrer sous Android · commandes CEC actives.

## Phase 5. Hub intégré

- **Objectif** : piloter la maison depuis la télé et depuis le S25 via la box.
- **Fin** : hub Rust dans l'image, l'app du S25 trouve la box en mDNS, y règle les lumières et sert de télécommande de la télé ; l'onglet Ambiance de la télé applique les préréglages de la pièce.
- **Tâches** : empaqueter le hub · client gRPC et préréglages d'ambiance · annonce mDNS · écran « Télé » dans l'app (#46).
- **Dépendances** : le hub et le contrat Protobuf dans `payssho/Home-device-manager`.

## Phase 6. Solidité

- **Objectif** : une télé qu'on n'a plus besoin de réparer.
- **Fin** : racine en lecture seule, mise à jour A/B RAUC avec retour arrière, garde-fous de stockage (#45), Wi‑Fi si la puce le permet. Le bouton « redémarrer sous Android » est livré en phase 4.
- **Tâches** : racine en lecture seule · mises à jour RAUC · garde-fous de stockage · Wi‑Fi.

## Phase 7. Extras

- **Tâches** : IPTV · Widevine L3 obtenu légalement dans Chromium · recopie d'écran depuis le S25 · accès distant (WireGuard ou Tailscale).
