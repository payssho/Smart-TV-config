# Verdict du 2026-11-10 (premier passage, en local)

Image de repli Ubuntu 24.04 arm64 (deb.debian.org était injoignable depuis le conteneur), scénario `fumee`, paliers de 20 s, QEMU 8.2 en TCG (Cortex-A55 émulé).

- **Démarrage** : le jumeau arrive au scénario en ~50 s émulées, détecte le bon profil (1 645 Mo vus par Linux en 2 Go, 3 339 Mo en 4 Go) et applique les réglages de `tele-memoire`. L'écran 1080p virtio-gpu répond aux captures.
- **Entretien** : il s'efface pendant la lecture (passage repoussé, rien écrit sur la SD) et quand les 4 cœurs travaillent (garde processeur à 86-94 %). Ramené à un passage toutes les 10 minutes, son coût pendant une lecture est de 0,02 à 0,04 %. Au repos, il ramène le cache Chromium sous son plafond en ~20 s émulées.
- **Pire cas volontaire** (ménage forcé pendant un décodage, ce que la garde empêche) : 13 à 20 % de ralentissement, malgré la priorité minimale. C'est la raison d'être de la garde.

Ce que ce passage ne montre pas encore :

- **zram** : absent du noyau `linux-image-virtual` d'Ubuntu (module dans `linux-modules-extra`) ; `tele-memoire` a continué sans, comme prévu. Le noyau Debian de l'image CI l'a.
- **Chromium et l'app Flutter** : absents de l'image de repli (Chromium n'existe qu'en snap sur Ubuntu, l'app ne se compile pour arm64 que sur une machine arm64). Les paliers YouTube, Twitch et pire cas mémoire attendent l'image Debian en CI.

Défauts trouvés par le jumeau et corrigés avant ce passage : passage repoussé trop coûteux (sous-processus inutiles, écriture du journal), garde aveugle quand le processeur est saturé sans file d'attente (PSI à zéro), plafonnement qui relançait `du` à chaque fichier.
