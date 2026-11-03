# Checklist de la phase 1 : valider la box

À dérouler à la réception de la box, sous Armbian ophub démarré depuis la carte SD (ADR 0005). Chaque bloc correspond à une issue du milestone « Phase 1 ». Les résultats vont dans `docs/materiel.md`.

> **Règle d'or : on ne touche pas à l'eMMC.** Pas de `armbian-install`, pas de `dd` vers un `mmcblk` qui n'est pas la SD, pas de « Install to eMMC ». L'Android d'origine sert au double démarrage (ADR 0003).

## À acheter

| Objet | Nécessaire ? | Pourquoi |
|---|---|---|
| Box S905X3 **4 Go / 32 Go** | Oui | Recommandée : **H96 Max X3**, dont la carte a un DTB dans le noyau mainline (`meson-sm1-h96-max`). Sinon X96 Max+ ou HK1 Box (DTB fournis par ophub). |
| Micro-SD A1/A2 32 Go | Oui | Notre OS démarre dessus, l'eMMC reste à Android. |
| Câble Ethernet | Oui | Le Wi‑Fi n'est pas garanti sous Linux. |
| Adaptateur USB-série 3,3 V | Non, **écarté par Marius** (2026-11-03) | Sans lui, un démarrage raté reste muet : on diagnostique à l'écran et en essayant les autres DTB. À reconsidérer seulement si la box ne démarre jamais. |

## Avant de commencer

- [ ] Box S905X3 **4 Go / 32 Go** reçue ; noter le modèle exact (X96 Max+, HK1 Box, H96 Max X3), la révision imprimée sur la carte mère et une photo de la carte.
- [ ] Carte micro-SD rapide (A1/A2, 32 Go), câble Ethernet, câble HDMI vers la télé.
- [ ] Démarrer une fois sous Android : noter la version, faire une capture des réglages « À propos ».
- [ ] **Usages du premier jour (ADR 0014)** sous Android : installer Netflix, Canal+, YouTube et Twitch ; pour chacun, noter si l'installation passe (Play Store ou non), et la qualité réelle à l'œil. Installer aussi l'appli « DRM Info » pour noter le niveau Widevine d'Android (L1 ou L3) et la certification Play Protect. C'est notre solution tant que notre OS n'est pas prêt.
- [ ] Télé Philips : relever le modèle exact (étiquette « MODEL NO. » derrière, cachée par le support mural, ou menu Réglages > Aide) et activer **EasyLink** (le CEC chez Philips) dans les réglages. Brancher la box sur **HDMI 2** (HDMI 1 ARC reste libre pour une barre de son).

## 1. Démarrer Armbian et choisir le DTB

- [ ] Télécharger l'image ophub pour S905X3 ([amlogic-s9xxx-armbian](https://github.com/ophub/amlogic-s9xxx-armbian), noyau 6.12 ou 6.18) et la flasher sur la SD avec balenaEtcher ou Rufus.
- [ ] Choisir le DTB du modèle dans `/boot/uEnv.txt` sur la SD (par exemple `meson-sm1-x96-max-plus*.dtb`, `meson-sm1-hk1box-vontar-x3.dtb` ou `meson-sm1-h96-max-x3.dtb` selon le modèle reçu).
- [ ] Activer le démarrage sur SD : SD insérée, maintenir le bouton reset (dans le port AV) à l'allumage, ou lancer « Update » depuis Android. Noter la méthode qui a marché.
- [ ] Le démarrage arrive au login (sur la télé). Noter la durée.
- [ ] Si échec : essayer les autres DTB candidats et noter ce qui s'affiche à l'écran avant l'arrêt.
- [ ] Lancer `sudo scripts/materiel/diagnostic.sh > rapport-dtb.txt` et joindre le rapport à l'issue.

## 2. HDMI 1080p, Ethernet et GPU (Panfrost)

- [ ] L'image s'affiche en **1920×1080 à 60 Hz** (`/sys/class/drm/card*-HDMI-A-1/modes`), sans bandes noires ni débordement.
- [ ] Le son sort par HDMI (`speaker-test -c 2`).
- [ ] Ethernet en 1 Gbit/s (`ethtool eth0`), IP obtenue par DHCP. Débit avec `iperf3` vers le PC si possible.
- [ ] Module `panfrost` chargé (`lsmod`, `dmesg | grep panfrost`).
- [ ] `glmark2-es2-drm` tourne en plein écran sans bureau graphique ; noter le score.
- [ ] Températures au repos et après 10 min de glmark2 (`/sys/class/thermal`).

## 3. HDMI-CEC

- [ ] `/dev/cec0` existe, `dmesg | grep -i cec` montre `meson-ao-cec`.
- [ ] `sudo scripts/materiel/diagnostic.sh --cec` : la télé répond (adresse physique, état d'alimentation).
- [ ] Touches de la télécommande de la télé reçues : `cec-ctl -d /dev/cec0 --playback -M` puis appuyer sur flèches, OK, retour. Noter les touches qui passent.
- [ ] Les mêmes touches apparaissent en evdev : `evtest` sur le périphérique CEC.
- [ ] Commandes actives : `cec-ctl --to 0 --image-view-on` (allume la télé), `cec-ctl --to 0 --standby` (veille), changement d'entrée.

## 4. Infrarouge

- [ ] `/sys/class/rc/rc0` existe, `dmesg | grep meson-ir` OK.
- [ ] `ir-keytable -t` : appuyer sur chaque touche de la télécommande de la box, noter le protocole (NEC…) et les scancodes.
- [ ] Créer la keymap (scancodes → `KEY_UP`, `KEY_OK`, `KEY_BACK`…) et vérifier dans `evtest`.

## 5. Décodage vidéo 1080p

- [ ] Installer `mpv` et préparer des échantillons 1080p : H.264 8 bits, HEVC 8 bits, HEVC 10 bits, VP9, AV1, en 24/30/60 i/s.
- [ ] `mpv --vo=gpu --gpu-context=drm` sur chaque échantillon : fluidité, images perdues (`mpv` affiche les « dropped »), charge CPU (`top`), température.
- [ ] Noter si des décodeurs V4L2 existent (`v4l2-ctl --list-devices`) et si `--hwdec=v4l2m2m` marche (piste d'amélioration, ADR 0002).

## 6. Wi‑Fi et Bluetooth

- [ ] Identifier la puce Wi‑Fi (identifiants SDIO dans le rapport, `dmesg`) : Broadcom/Cypress, Realtek, Amlogic, AIC, SSV… et noter si un pilote mainline existe.
- [ ] Si le pilote charge : connexion à la box du foyer, débit avec `iperf3`.
- [ ] Bluetooth : `bluetoothctl list`, `scan on` ; vérifier que la lampe iStrip+ apparaît (utile pour le hub, phase 5).

## 7. Rapport

- [ ] Rédiger `docs/materiel.md` : modèle et révision, DTB retenu, méthode de démarrage SD, et pour chaque point : marche / partiel / ne marche pas, avec la commande de test.
- [ ] Remplir la section « Matériel validé » de `CLAUDE.md`.
- [ ] Ouvrir une ADR si un résultat change une décision (DTB retenu, repli CEC, plan B S905X).
