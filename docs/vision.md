# Vision

## Problème

Les télés « intelligentes » et les clés du commerce (Google TV, Fire TV) sont fermées, pleines de publicité et impossibles à adapter. Marius veut une télé dont il maîtrise tout le logiciel, qui serve aussi de centre de commande pour la maison (lampes, ampoules, récepteur audio).

## Utilisateur

Le foyer de Marius, devant la télé du salon, avec la télécommande de la télé (via HDMI-CEC), la télécommande infrarouge de la box ou l'app Home device manager sur le Galaxy S25.

## Résultat attendu de la v1

> Je rallume la télé avec sa télécommande, j'arrive en quelques secondes sur notre écran d'accueil, je lance une vidéo de mon réseau en 1080p et j'allume les lampes du salon, sans jamais toucher un clavier ni une souris.

## Hors périmètre de la v1

- La 4K et le HDR (décodage logiciel seulement sur noyau mainline, ADR 0002).
- Netflix, Canal+, Disney+ dans notre OS : ils passent par l'Android d'origine en double démarrage (ADR 0003). Aucun contournement de DRM, jamais.
- Google Cast (récepteur certifié impossible).
- Le Wi‑Fi tant que la puce reçue n'est pas identifiée (Ethernet d'abord).
- L'écriture sur l'eMMC de la box.

## Contraintes

- Matériel : box Amlogic S905X3 4/32 Go à ~30 € (X96 Max+, HK1 Box ou H96 Max X3), carte micro-SD, télé 1080p (ADR 0001).
- Licences : briques libres ; police Bricolage Grotesque (OFL).
- Build : une image Buildroot complète prend 1 à 2 h et 15 à 25 Go. Elle se construit en GitHub Actions ou sous WSL2 chez Marius, pas dans le conteneur de l'agent (réseau filtré, disque limité).
- Tests : tout ce qui se teste sans la box se teste sans elle (Flutter en desktop et `flutter test`, image dans QEMU, entrées simulées). Marius teste sur la vraie télé et rapporte.

## Risques techniques

Classés du plus bloquant au moins bloquant. Chaque risque bloquant a son spike avant de planifier la suite.

| # | Risque | Impact | Spike |
|---|---|---|---|
| R1 | La box reçue n'a pas de DTB mainline qui marche (Ethernet, HDMI) | Bloquant | Phase 1 : démarrage Armbian ophub, essai des DTB candidats |
| R2 | flutter-pi ne tourne pas sur Panfrost / S905X3 | Bloquant pour l'UI | Phase 2 : « hello TV » ; repli `cage` + Flutter Linux (ADR 0008) |
| R3 | HDMI-CEC muet avec `meson-ao-cec` ou avec la télé de Marius | Fort : télécommande de la télé inutilisable | Phase 1 : `cec-ctl` ; repli infrarouge + app |
| R4 | Décodage logiciel insuffisant pour du 1080p HEVC | Moyen | Phase 1 : mpv sur échantillons ; piste V4L2 `meson-vdec` |
| R5 | Le u-boot d'origine n'enchaîne pas sur la SD | Bloquant pour l'image | Phase 1 (Armbian utilise le même mécanisme) |
| R6 | Build Buildroot trop gros pour un runner GitHub | Moyen | Phase 3 : libération d'espace, cache `dl/` + ccache ; repli WSL2 |
