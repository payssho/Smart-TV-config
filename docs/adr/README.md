# Décisions d'architecture (ADR)

Une ADR explique pourquoi le dépôt est comme il est. Format : `NNNN-titre-court.md`, numéro jamais réutilisé. Une ADR acceptée ne se réécrit pas : on en écrit une nouvelle qui la remplace. « Proposée » = choix par défaut pas encore validé par Marius.

| N° | Titre | Statut |
|---|---|---|
| [0001](0001-utiliser-une-box-amlogic-s905x3.md) | Utiliser une box Amlogic S905X3 4/32 Go, en Ethernet d'abord | acceptée |
| [0002](0002-viser-le-1080p-en-decodage-logiciel.md) | Viser le 1080p avec un décodage vidéo logiciel | acceptée |
| [0003](0003-double-demarrage-sans-contournement-drm.md) | Garder Android sur l'eMMC en double démarrage, sans jamais contourner les DRM | acceptée |
| [0004](0004-construire-le-systeme-avec-buildroot.md) | Construire le système avec Buildroot | proposée |
| [0005](0005-valider-le-materiel-sous-armbian-ophub.md) | Valider le matériel et prototyper sous Armbian ophub | acceptée |
| [0006](0006-noyau-mainline-et-amorcage-depuis-la-sd.md) | Utiliser un noyau mainline et amorcer depuis la SD via le u-boot d'origine | proposée |
| [0007](0007-afficher-en-drm-kms-avec-panfrost.md) | Afficher en DRM/KMS avec Mesa Panfrost, sans X11 ni Wayland | acceptée |
| [0008](0008-interface-flutter-via-flutter-pi.md) | Écrire l'interface en Flutter, affichée par flutter-pi | acceptée |
| [0009](0009-entrees-cec-et-infrarouge-en-evdev.md) | Recevoir la télécommande de la télé (CEC) et l'infrarouge comme des touches evdev | acceptée |
| [0010](0010-lire-la-video-avec-gstreamer-ou-libmpv.md) | Lire la vidéo avec GStreamer (flutter-pi) ou libmpv | proposée |
| [0011](0011-mettre-a-jour-en-a-b-avec-rauc.md) | Mettre à jour l'image en A/B avec RAUC | proposée |
| [0012](0012-hub-domotique-rust-dans-home-device-manager.md) | Faire tourner un hub domotique Rust sur la box, développé dans Home-device-manager | acceptée |
| [0013](0013-reprendre-l-identite-veilleuse.md) | Reprendre l'identité visuelle « veilleuse » de l'app | proposée |
| [0014](0014-youtube-et-twitch-dans-notre-os.md) | Regarder YouTube et Twitch dans notre OS, Netflix et Canal+ sous Android | proposée |
| [0015](0015-previsualiser-l-interface-en-build-web.md) | Prévisualiser l'interface avec le build web de l'app Flutter | proposée |
| [0016](0016-comparer-2-go-et-4-go-dans-des-conteneurs-bornes.md) | Comparer 2 Go et 4 Go dans des conteneurs à mémoire bornée | proposée |
| [0019](0019-montrer-un-vrai-feu-filme-sous-licence-libre.md) | Montrer un vrai feu filmé et un vrai son, sous licence libre | proposée |
| [0021](0021-dessiner-les-fonds-avec-des-motifs-de-lumiere-precuits.md) | Dessiner les fonds animés avec des motifs de lumière précuits | proposée |
| [0022](0022-passer-a-material-ui-et-figer-flutter.md) | Passer au paquet material_ui et figer la version de Flutter | proposée |
