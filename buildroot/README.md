# Image Buildroot de la télé

Arbre externe Buildroot (`BR2_EXTERNAL`) : tout ce qui fait notre image vit ici, Buildroot lui-même n'est jamais modifié ni copié dans le dépôt. Décisions : ADR [0004](../docs/adr/0004-construire-le-systeme-avec-buildroot.md), [0023](../docs/adr/0023-figer-buildroot-2026-02-lts-par-etiquette-et-commit.md), [0024](../docs/adr/0024-batir-l-image-sur-systemd-glibc-et-une-chaine-precompilee.md).

## Contenu

| Chemin | Rôle |
|---|---|
| `version` | Version de Buildroot : dépôt, étiquette, commit attendu. |
| `configs/qemu_aarch64_tv_defconfig` | Image pour le jumeau QEMU de la box (ADR 0019). |
| `board/commun/` | Commun à toutes les images : réseau filaire en DHCP, `/data` dans `fstab`, fiche `/etc/tele/image`. |
| `board/qemu-aarch64-tv/linux.fragment` | Ajouts au noyau du jumeau : zram, MGLRU, PSI, cgroups, partages 9p. |
| `package/tele-systeme/` | Installe `systeme/` (tele-memoire, tele-role, tele-entretien) et active ses unités. |
| `package/tele-jumeau/` | Scénario de test du jumeau, avec python3 et ffmpeg. Pas pour la box. |
| `output/` | Sources de Buildroot, archives, cache et builds. Jamais dans git. |

La defconfig de la box (noyau mainline, DTB, amorçage depuis la SD) arrivera au jalon J6, sur le même socle.

## Commandes

Tout passe par `scripts/image/construire.sh`, qui récupère Buildroot à la version de `version` s'il n'est pas déjà là.

```sh
# Valider la defconfig sans rien compiler (quelques secondes, partout).
scripts/image/construire.sh --verifier

# Build complet : 30 à 60 minutes, une dizaine de Go. En CI ou sous WSL2,
# jamais dans le conteneur de l'agent.
scripts/image/construire.sh

# Démarrer l'image sur le jumeau, console série interactive (root, sans
# mot de passe ; Ctrl-a x pour quitter).
scripts/jumeau/demarrer.sh --profil 2go --image buildroot/output/qemu_aarch64_tv/jumeau

# Jouer le scénario court sur les deux profils et écrire le rapport.
scripts/jumeau/lancer.sh --scenario fumee --palier 30 --image buildroot/output/qemu_aarch64_tv/jumeau

# Régler Buildroot ou le noyau, puis reporter le résultat dans la defconfig
# ou le fragment (ne pas laisser la modification dans output/).
scripts/image/construire.sh menuconfig
scripts/image/construire.sh linux-menuconfig

# Après une modification de systeme/ : reprendre le paquet et l'image.
scripts/image/construire.sh tele-systeme-rebuild all
```

## En CI

Le workflow « Image Buildroot » (`.github/workflows/image.yml`) part sur une PR qui touche `buildroot/` ou `scripts/image/`, sur une étiquette `v*`, et à la demande (onglet Actions, « Run workflow »). Il valide la defconfig, construit l'image en reprenant `dl/` et ccache du build précédent, publie l'artefact `image-qemu_aarch64_tv` (noyau `Image` et disque `tele-qemu_aarch64_tv.img.xz`), puis démarre l'image sur le jumeau en 2 Go et en 4 Go avec le scénario court. Le job échoue si une unité systemd est en échec au démarrage ou si le rapport du jumeau relève une règle violée. Durée, tailles et rapport sont dans le résumé du run.

Une PR qui ne touche que `systeme/` ne lance pas ce workflow (elle passe par « Jumeau de la box », sur l'image Debian) : avant une version, le lancer à la main.

## Sous WSL2

Ubuntu 24.04 sous WSL2, dans le système de fichiers Linux (pas sous `/mnt/c`, dix fois plus lent et sans droits Unix) :

```sh
sudo apt install build-essential bc bison flex cpio file rsync unzip wget xz-utils libssl-dev libncurses-dev git
sudo apt install qemu-system-arm qemu-utils ffmpeg e2fsprogs python3   # pour le jumeau
scripts/image/construire.sh
```

Les builds suivants réutilisent `output/dl` et `output/ccache`. Pour repartir de zéro : supprimer `output/qemu_aarch64_tv`.

## Monter de version de Buildroot

Changer `BUILDROOT_VERSION` et `BUILDROOT_COMMIT` dans `version` (le commit se lit avec `git ls-remote --tags https://github.com/buildroot/buildroot.git <étiquette>^{}`), lancer `scripts/image/construire.sh --verifier`, puis laisser la CI construire et démarrer l'image. Une ligne de defconfig écartée par la nouvelle version fait échouer la vérification en la nommant.
