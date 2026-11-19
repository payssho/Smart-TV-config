# 0025. Améliorer le projecteur HY300 Pro sous son Android d'origine, sans root

- Statut : proposée
- Date : 2026-11-19

## Contexte

Marius possède un projecteur Magcubic HY300 Pro (Android 14, dalle native
1280 × 720). La fiche annonce un SoC Allwinner H726 (4 × Cortex-A53,
Mali-G31 MP2, 1 Go de RAM, 8 Go de stockage) ; les anciens lots sont en H713.
L'interface d'origine est lente et chargée, mais le projecteur fait des choses
qu'aucun autre OS ne sait refaire aujourd'hui sur ce matériel :

- correction de trapèze et mise au point motorisée (pilotes et appli du
  fabricant) ;
- Wi-Fi, Bluetooth, sortie audio ;
- Netflix, Canal+, YouTube, avec leurs DRM (Widevine, sans doute L3).

L'étude OS du 2026-11-11 a écarté Linux (seul un projet de recherche sur H713,
rien sur H726). Marius demande un chantier séparé de la box S905X3 : garder
Android, améliorer les performances et l'interface, ne perdre aucune fonction.
Règles du projet qui s'appliquent : aucun contournement de DRM (ADR 0003),
navigation 100 % télécommande (ADR 0009), identité « veilleuse » (ADR 0013).

Ce que permet un `adb shell` sans root sur Android 14 (utilisateur `shell`) :

- `pm disable-user --user 0` et `pm uninstall -k --user 0` : retirer une appli
  système pour l'utilisateur, réversible par `pm enable` ou
  `cmd package install-existing` ;
- `settings put global|secure|system` : échelles d'animation, scans Wi-Fi et
  Bluetooth en tâche de fond, économiseur d'écran ;
- `cmd package set-home-activity` : choisir le lanceur par défaut ;
- `cmd package compile`, `cmd package bg-dexopt-job`, `pm trim-caches` :
  compilation anticipée et vidage des caches ;
- `am set-standby-bucket`, `cmd appops` : brider une appli qu'on garde.

Ce qui demande un accès plus profond (root, `system` ou image signée) :
modifier `/system` ou `/vendor`, changer les propriétés `ro.*`
(`ro.config.low_ram`, densité, résolution de rendu), régler zram et le
gouverneur CPU, remplacer pour de bon le lanceur du fabricant dans l'image.
Sur ce matériel, cela passe par un bootloader déverrouillé ou une image
reconstruite : non documenté pour le H726, risque de casser Widevine et les
applis qui vérifient l'intégrité (Canal+), et le reflash d'usine n'est
qu'un filet partiel.

## Options envisagées

1. **Lanceur custom + allègement adb + réglages, sans root.** Une appli
   Flutter déclarée comme écran d'accueil (`HOME` / `LEANBACK_LAUNCHER`),
   reprise de l'interface de la télé (3 onglets Regarder / Ambiance /
   Réglages). Les fonctions du fabricant restent en place et s'ouvrent depuis
   l'onglet Réglages. Tout est réversible depuis un PC, sans flash.
   Inconvénient : le lanceur d'origine reste installé (il héberge peut-être le
   trapèze), la touche Accueil de la télécommande peut y être câblée en dur.
2. **Lanceur natif Kotlin / Compose for TV.** Plus léger qu'un moteur
   Flutter (environ 30 à 50 Mo de RAM en moins), mais on ne réutilise ni le
   code ni les tests de `ui/`, et l'identité est à refaire.
3. **Lanceur existant (Projectivy, FLauncher) + allègement.** Rapide, mais
   ni identité veilleuse ni intégration future avec la maison.
4. **Root ou image modifiée.** Gains réels (zram, `low_ram`, services
   système retirés), mais aucune méthode connue pour le H726, risque de
   brique et de perdre Netflix / Canal+. Rien qui justifie ce risque tant que
   l'option 1 n'est pas mesurée.

## Décision

Option 1. Dans `projecteur/` : des scripts adb sans root (inventaire en
lecture seule, sauvegarde, allègement et réglages réversibles, restauration)
et un lanceur Flutter « Veilleuse » pour Android. Pas de root, pas de flash.
L'option 2 reste le repli si le lanceur Flutter coûte trop de mémoire sur
1 Go (seuil : plus de 120 Mo de PSS au repos, mesuré par `dumpsys meminfo`).

## Conséquences

- Tout se défait depuis un PC : `restaurer.sh` rejoue le journal de
  l'allègement ; en dernier recours, la réinitialisation d'usine remet les
  applis système désactivées.
- Une liste protégée (trapèze, mise au point, Wi-Fi, Bluetooth, Google Play,
  Widevine, Netflix, Canal+, YouTube, lanceur d'origine) n'est jamais touchée
  par les scripts, même si on la met par erreur dans la liste à alléger.
- La liste à alléger ne peut pas être écrite à l'aveugle : elle se remplit
  après l'inventaire du vrai firmware de Marius.
- Le lanceur doit tenir dans 1 Go partagé avec Netflix : pas de fond animé
  lourd (les fonds de la télé, ADR 0021, sont pensés pour 2 Go et un GPU
  plus gros), rendu en 1280 × 720.
- À surveiller : la touche Accueil. Si le firmware l'envoie toujours au
  lanceur d'origine, piste suivante sans root : un service d'accessibilité
  qui la redirige (comme le font les applis de remappage).
- On reviendrait sur cette décision si une méthode de root sûre, réversible
  et compatible Widevine apparaît pour le H726, ou si Magcubic publie un
  firmware qui règle les lenteurs.
