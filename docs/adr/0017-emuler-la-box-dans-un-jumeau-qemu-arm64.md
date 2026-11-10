# 0017. Émuler la box entière dans un jumeau QEMU arm64, en 2 Go et en 4 Go

- Statut : proposée
- Date : 2026-11-10

## Contexte

La box arrivera plus tard que prévu, et Marius veut avancer toutes les phases sans elle, en testant le code et chaque étape sur une copie numérique de la box en 2 Go (cible prioritaire) et en 4 Go, quitte à corriger à réception. Le banc Docker de l'ADR 0016 borne la mémoire d'un conteneur x86 : rapide, mais ni arm64, ni vrai noyau, ni zram, ni carte SD, ni démarrage. Il ne peut donc pas tester nos scripts système, ni l'image de la phase 3.

## Options envisagées

1. **Jumeau QEMU `virt` arm64** : 4 cœurs Cortex-A55, RAM physique de 2 048 ou 4 096 Mo dont Linux ne voit que ce que la box lui laisse (`mem=`, voir plus bas), disques bridés comme une microSD A1, écran 1080p virtio-gpu, clavier virtio (future télécommande evdev). Image arm64 complète construite en CI sur un runner arm64 natif : aujourd'hui une Debian minimale (noyau, systemd, Chromium, cage, ffmpeg) avec nos scripts système et l'app Flutter compilée pour arm64 ; en J5, l'image Buildroot sur la même machine.
2. **QEMU en machine Amlogic** : QEMU n'émule aucune carte Amlogic (ni S905X3, ni GXL). Il faudrait écrire un modèle de carte, des mois de travail pour un résultat qui n'aurait toujours ni GPU Mali ni décodeur.
3. **Garder le seul banc Docker** : ne teste ni l'arm64, ni le noyau, ni nos réglages mémoire. Insuffisant pour « toutes les étapes ».
4. **Renode ou un émulateur cycle-près** : fidèle au temps, mais aucun modèle de S905X3 non plus, et des heures pour démarrer un Linux complet.

## Décision

Option 1. `scripts/jumeau/construire-image.sh` construit l'image, `scripts/jumeau/demarrer.sh --profil 2go|4go` la démarre (scénario automatique ou console interactive), `scripts/jumeau/lancer.sh` joue les deux profils et écrit le rapport. Le workflow « Jumeau de la box » le fait à chaque PR qui touche `systeme/` ou `scripts/jumeau/`, chaque lundi, et à la demande. Le banc Docker (ADR 0016) reste pour une mesure rapide de l'interface sur un poste x86.

Modèle de la mémoire (à recaler sur la vraie box avec `diagnostic.sh`, #43) :

| Profil | RAM physique | `mem=` laissé à Linux | Retranché |
|---|---:|---:|---|
| 2 Go | 2 048 Mo | 1 728 Mo | CMA vidéo comptée pleine (256), firmware et moniteur sécurisé (~64) |
| 4 Go | 4 096 Mo | 3 520 Mo | idem, plus le trou d'adressage des registres (~256) |

Carte SD : 22 Mo/s en lecture, 10 Mo/s en écriture, 1 500 / 500 IOPS (minimums de la classe A1 derrière le lecteur SD de la S905X3), budget partagé entre la racine et `/data`.

## Ce que le jumeau couvre, et ce qu'il ne couvre pas

| Sujet | Couvert | Remarque |
|---|---|---|
| Jeu d'instructions arm64, binaires réels | oui | Mêmes paquets arm64 que sur la box. |
| Mémoire 2 Go / 4 Go, OOM, zram, MGLRU, PSI | oui | Vrai noyau, vraie pression mémoire. |
| Nos scripts système (`systeme/`) | oui | Exactement les fichiers de la future image. |
| Démarrage systemd, services, ordre d'amorçage | oui | Pas le u-boot ni le DTB de la box. |
| Stockage lent, plafonds de cache, usure | en partie | Débit et IOPS bridés ; pas la latence d'écriture réelle d'une SD pleine. |
| Interface Flutter | en partie | Sous cage en rendu logiciel (Mesa llvmpipe), pas flutter-pi sur Panfrost. |
| Fluidité, images/s, temps de démarrage | non | Processeur émulé (TCG) 10 à 50 fois plus lent, ou processeur hôte plus rapide (KVM). Seuls les écarts relatifs ont un sens. |
| GPU Mali-G31 (Panfrost) | non | virtio-gpu sans accélération. |
| Décodeur vidéo matériel, HDMI, HDR | non | Décodage logiciel seulement. |
| HDMI-CEC, infrarouge | non | Le clavier virtio remplace la télécommande ; le CEC se teste sur la box. |
| eMMC, double démarrage Android | non | Aucune eMMC émulée ; le redémarrage sous Android se teste sur la box. |
| Wi-Fi, Bluetooth | non | Réseau virtio seulement. |
| Chauffe, alimentation | non | Phase 1. |

## Conséquences

- Toutes les phases peuvent avancer sans la box sur ce qui est couvert ; ce qui ne l'est pas reste marqué « à valider sur la box » dans les issues.
- Une PR qui touche les scripts système déclenche le jumeau : environ 30 à 45 minutes de CI par profil, hors du chemin rapide de la CI principale.
- Le runner `ubuntu-24.04-arm` construit l'app et l'image en natif. Si `/dev/kvm` y est disponible, le jumeau tourne avec KVM (rapide, processeur hôte) ; sinon en TCG avec un vrai modèle Cortex-A55.
- À réception de la box : relever `MemTotal`, la CMA et le débit SD réels, corriger le tableau ci-dessus et `demarrer.sh`, puis comparer le rapport du jumeau à la mesure `mem=2G` sur la box (#43).
