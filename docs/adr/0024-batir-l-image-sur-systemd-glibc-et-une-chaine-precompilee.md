# 0024. Bâtir l'image sur systemd, glibc et une chaîne de compilation précompilée

- Statut : proposée
- Date : 2026-11-11

## Contexte

Buildroot laisse choisir l'init (BusyBox, systemd), la bibliothèque C (glibc, musl, uClibc) et la chaîne de compilation (construite sur place ou précompilée). Ces choix sont le socle de toute l'image : en changer plus tard oblige à tout reconstruire et à tout retester.

Ce qui existe déjà et pèse sur le choix : nos scripts système sont livrés avec des unités systemd (`systeme/`, ADR 0020) qui s'appuient sur les cgroups (`CPUWeight=idle`, `MemoryHigh`), les minuteurs et journald ; RAUC (ADR 0011), Chromium (ADR 0014) et le moteur Flutter (ADR 0008) sont développés et testés contre glibc ; la box n'étant pas là, tout doit se valider sur le jumeau QEMU (ADR 0019).

## Options envisagées

1. **systemd + glibc + chaîne Bootlin précompilée** (aarch64, glibc, « stable ») : ce que nos unités attendent, ce que les gros composants supportent, et 20 à 30 minutes de build en moins car on ne compile ni gcc ni glibc.
2. Init BusyBox + musl : image plus petite et démarrage un peu plus court, mais il faudrait réécrire les minuteurs, les priorités et les plafonds mémoire à la main, et ni Chromium ni le moteur Flutter précompilé ne tournent sur musl.
3. Chaîne construite par Buildroot : maîtrise complète des versions, au prix d'une demi-heure par build à froid, sans bénéfice pour nous aujourd'hui.

## Décision

Option 1, et un socle commun aux deux images : la defconfig du jumeau (`qemu_aarch64_tv`) et la future defconfig de la box partagent l'init, la libc, la chaîne, le réglage processeur Cortex-A55 et nos paquets ; seuls le noyau, l'amorçage et le banc de test diffèrent.

- **Nos fichiers entrent par des paquets de l'arbre externe**, pas par une copie à la main : `tele-systeme` installe `systeme/` tel quel et active ses unités par un préréglage systemd ; `tele-jumeau` ajoute le scénario de test, python3 et ffmpeg, et ne sera pas activé dans l'image de la box.
- **util-linux complet** en plus de BusyBox : le BusyBox de Buildroot n'a ni `swapon -p` ni `ionice`, dont `tele-memoire` et `tele-entretien` ont besoin. Il n'a pas non plus `stat`, ajouté par un fragment de configuration BusyBox (`board/commun/busybox.fragment`) ; le premier démarrage sur le jumeau l'a montré : le ménage des caches ne supprimait rien et se disait pourtant fait. `tele-entretien` échoue désormais clairement si un outil lui manque.
- **Noyau 6.18 (LTS)** pour le jumeau, configuration « virt » de Buildroot plus un fragment (zram lz4, MGLRU, PSI, cgroups, partages 9p), tout intégré au noyau : pas d'initramfs.
- **`/data` montée par son étiquette** (`LABEL=data`, `nofail`) : même ligne de `fstab` sur la carte SD de la box et sur le deuxième disque du jumeau.
- **Ethernet en DHCP** par systemd-networkd sur toute interface filaire, sans jamais retenir le démarrage.

## Conséquences

- Le jumeau fait tourner le vrai espace utilisateur de la box ; ce qu'il ne couvre pas reste le tableau de l'ADR 0019 (noyau et DTB Amlogic, GPU, CEC, vidéo).
- systemd pèse plus lourd qu'un init BusyBox en RAM et en temps de démarrage : à mesurer sur la box en J6, à côté de la cible de 15 s.
- La chaîne Bootlin impose sa version de gcc et de glibc ; on passera à une chaîne construite sur place si un composant exige autre chose.
- Racine encore en lecture et écriture, mot de passe root vide sur la console série : acceptable pour le jumeau, à fermer avant la première image de la box (racine en lecture seule en J9, ADR 0011).
- Le noyau de la box (mainline, DTB `meson-sm1`, ADR 0006) reste à choisir avec sa defconfig en J6.
