# Jumeau numérique de la box

En attendant la box, l'OS de la télé tourne sur une copie numérique : une machine QEMU arm64 qui imite la S905X3 en 2 Go et en 4 Go (mémoire vue par Linux, carte microSD A1, écran 1080p). Choix, modèle de la mémoire et limites : [ADR 0017](adr/0017-emuler-la-box-dans-un-jumeau-qemu-arm64.md). Réglages mémoire et entretien testés dedans : [ADR 0018](adr/0018-garder-la-box-2-go-fluide-avec-zram-et-un-entretien-au-repos.md).

## En CI (le plus simple)

Workflow « Jumeau de la box » : à chaque PR qui touche `systeme/` ou `scripts/jumeau/`, chaque lundi, ou à la main (onglet Actions, « Run workflow », scénario `complet` ou `fumee`). Le rapport 2 Go / 4 Go s'affiche dans le résumé du workflow ; l'artefact `rapport-jumeau` contient aussi les JSON, les journaux série et les captures de l'écran du jumeau.

## Sur un poste (Linux ou WSL2)

```sh
sudo apt install qemu-system-arm qemu-utils mmdebstrap qemu-user-static binfmt-support e2fsprogs ffmpeg
# App Flutter pour arm64 : à compiler sur une machine arm64 (Flutter ne compile pas le
# bureau Linux en croisé). Sans --appli, l'interface est remplacée par un bloc de 150 Mo.
scripts/jumeau/construire-image.sh [--appli ui/build/linux/arm64/release/bundle]
scripts/jumeau/demarrer.sh --profil 2go              # console série, root sans mot de passe, Ctrl-a x
scripts/jumeau/lancer.sh                             # scénario complet, 2 Go puis 4 Go, rapport
scripts/jumeau/lancer.sh --profils 2go --scenario fumee --palier 20   # essai rapide
```

Les rapports vont dans `scripts/jumeau/resultats/AAAA-MM-JJ/` : un JSON par profil, `rapport.md`, journaux série, captures PNG.

## Le scénario

1. **Démarrage** : `tele-memoire` règle zram et le noyau selon la RAM détectée.
2. **Accueil** : interface Flutter sous cage, hub (40 Mo), capture d'écran.
3. **YouTube** : Chromium en kiosque, un seul processus de rendu, page hors ligne façon YouTube TV.
4. **Retour à l'accueil** : Chromium fermé.
5. **Twitch** : décodage logiciel d'un flux H.264 1080p60.
6. **Pire cas** : YouTube, lecteur, hub en scan Bluetooth, mise à jour en fond.
7. **Pire cas après 2 h** : la même chose avec 600 Mo de dérive du tas de Chromium.
8. **Coût de l'entretien** : décodage de référence seul, puis pendant une lecture avec `tele-entretien` en boucle (il doit s'effacer), puis pendant le vrai ménage au repos.

Le scénario `fumee` ne garde que 1, 2 et 8. Chaque brique est lancée par `tele-role`, avec son rang face à l'OOM.

## Lire le rapport

- **Mémoire** : occupée / disponible au plus bas, et ce que zram a compressé. Un rôle « tué » en gras est un OOM ; le rapport échoue si c'est l'interface ou le hub.
- **Entretien** : seul l'écart en % compte. Pendant la lecture il doit rester dans le bruit (quelques %) et le passage repoussé durer quelques millisecondes.
- **Temps** : le processeur est émulé, les secondes ne sont pas celles de la box.

## Ce qui reste à valider sur la vraie box

GPU Mali et flutter-pi, décodeur vidéo matériel, HDMI-CEC et infrarouge, eMMC et double démarrage Android, Wi-Fi et Bluetooth, chauffe, `MemTotal` et débit SD réels. Tableau complet dans l'ADR 0017.
