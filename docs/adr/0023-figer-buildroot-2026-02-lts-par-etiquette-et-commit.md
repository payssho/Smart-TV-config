# 0023. Figer Buildroot 2026.02 LTS par étiquette et commit, et le construire en CI avec cache

- Statut : proposée
- Date : 2026-11-11

## Contexte

L'ADR 0004 retient Buildroot avec un arbre externe dans `buildroot/`. Il reste à dire quelle version, comment on la récupère, et comment un build d'une heure tient dans le budget GitHub Actions du dépôt (dépôt privé, budget plafonné à 5 $ au-delà des minutes incluses). L'image doit être reproductible : le même commit du dépôt doit redonner la même image dans six mois, en CI comme sous WSL2 chez Marius.

Faits vérifiés le 2026-11-11 : la branche à support long en cours est 2026.02 (dernière version 2026.02.3), la version courante est 2026.08.1. Le miroir officiel `github.com/buildroot/buildroot` porte les mêmes étiquettes que le dépôt d'origine.

## Options envisagées

1. **Fichier `buildroot/version` (dépôt, étiquette, commit) lu par un script** : `scripts/image/construire.sh` clone l'étiquette en profondeur 1 et refuse de continuer si le commit obtenu n'est pas celui du fichier. Monter de version = changer deux lignes dans une PR.
2. Sous-module git : même garantie, mais chaque clone du dépôt et chaque job de CI traîne le sous-module, même ceux qui ne construisent pas l'image, et les sous-modules se désynchronisent facilement.
3. Archive `buildroot-X.tar.xz` et son empreinte : équivalent à l'option 1, avec une dépendance au site buildroot.org en plus.
4. Suivre la branche courante (2026.08, puis 2026.11) : paquets plus récents, mais un changement de version tous les trois mois et des correctifs de sécurité arrêtés au bout de trois mois.

Pour la CI : build à chaque PR (trop cher), ou seulement quand l'image change, sur les étiquettes de version et à la demande, avec le dossier des archives (`dl/`) et le cache de compilation (ccache) repris d'un build à l'autre.

## Décision

Option 1 avec **Buildroot 2026.02.3** (branche à support long). `scripts/image/construire.sh` est le seul point d'entrée, en CI comme sous WSL2. Avant tout build, son mode `--verifier` applique la defconfig et échoue si Buildroot en a écarté une ligne : quelques secondes, lancé aussi en tête du workflow.

Le workflow « Image Buildroot » part sur une PR qui touche `buildroot/` ou `scripts/image/`, sur une étiquette `v*` et à la demande. Il garde `dl/` et ccache dans le cache d'Actions, y compris quand le build échoue, publie l'image en artefact `.img.xz`, puis la démarre sur le jumeau (ADR 0019).

## Conséquences

- Chaque archive téléchargée est vérifiée par son empreinte (`BR2_DOWNLOAD_FORCE_CHECK_HASHES`) : une archive modifiée en amont arrête le build au lieu d'entrer dans l'image.
- Une PR qui ne touche pas l'image ne paie pas le build. Une PR qui touche seulement `systeme/` passe par le workflow du jumeau sur l'image Debian, pas par celui-ci : avant une version, lancer « Image Buildroot » à la main.
- Les correctifs de la branche LTS arrivent en changeant l'étiquette et le commit ; à refaire tous les deux ou trois mois.
- Si le build dépasse le budget ou la place du runner malgré le cache, repli sous WSL2 avec la même commande (`buildroot/README.md`).
- On reviendra sur la version si un paquet nécessaire (flutter-pi, Mesa Panfrost pour le Mali-G31, RAUC) manque ou est trop ancien en 2026.02.
