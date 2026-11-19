# Projecteur HY300 Pro : mieux sous son Android d'origine

Chantier séparé de la box S905X3. But : un projecteur plus vif et une
interface « veilleuse », **sans perdre aucune fonction** (trapèze, mise au
point, Wi-Fi, Bluetooth, Netflix, Canal+, YouTube) et **sans root ni flash**.
Le pourquoi est dans l'[ADR 0025](../docs/adr/0025-ameliorer-le-projecteur-sous-android-sans-root.md).

## Ce qu'on fait, et ce que ça demande

| Levier | Sans root (adb) | Effet attendu |
|---|---|---|
| Lanceur « Veilleuse » (Regarder / Ambiance / Réglages) | oui | interface sobre à la télécommande, moins d'applis lancées au démarrage |
| Désactiver les applis inutiles du fabricant | oui, réversible | RAM libérée sur 1 Go, moins de réveils |
| Animations à 0,5, scans Wi-Fi / Bluetooth permanents coupés | oui, réversible | interface plus vive |
| Vider les caches, compiler les applis à l'avance | oui | applis qui démarrent plus vite |
| zram, `ro.config.low_ram`, gouverneur CPU, retrait dans `/system` | **non** (root ou image modifiée) | gains réels mais risque de brique et de perdre Widevine / Canal+ : écarté |
| Remplacer pour de bon le lanceur dans l'image | **non** | inutile : on choisit le nôtre par adb |

Le lanceur d'origine reste installé : il héberge peut-être le trapèze. Les
réglages du projecteur s'ouvrent depuis l'onglet Réglages du nôtre.

## Plan

1. **Brancher adb** (une fois) : Réglages > Préférences de l'appareil > À
   propos > cliquer 7 fois sur « Build », puis activer le débogage (USB ou
   réseau) dans Options pour les développeurs. Depuis le PC :
   `adb connect <ip-du-projecteur>:5555`.
2. **Inventaire, en lecture seule** : `projecteur/adb/inventaire.sh`. Il range
   tout dans `projecteur/adb/etat/inventaire-…/` (firmware, mémoire par
   processus, paquets, lanceur, Widevine). On en tire la liste à alléger et
   le nom des écrans trapèze / mise au point.
3. **Allègement** : remplir `paquets-a-alleger.txt`, lancer `alleger.sh`
   (simulation), puis `alleger.sh --appliquer`. La liste protégée
   (`paquets-proteges.txt`) passe avant tout. Annuler : `restaurer.sh`.
4. **Réglages de performance** : `regler-perf.sh` (montre), `--appliquer`,
   `--annuler`, et `--entretien` de temps en temps.
5. **Lanceur** : télécharger l'artefact `lanceur-veilleuse-apk` de la CI
   (workflow « Projecteur »), puis `installer-lanceur.sh app-release.apk`.
   Revenir à l'origine : `installer-lanceur.sh --origine`.
6. **Mesurer** avant / après : `dumpsys meminfo` au repos et temps
   d'ouverture de Netflix. Seuil de repli vers un lanceur natif Kotlin :
   plus de 120 Mo de PSS pour Veilleuse au repos.

## Contenu

- `adb/` : scripts bash, sans root. Ils exigent un seul appareil branché
  (`ANDROID_SERIAL` sinon) et gardent sauvegardes et journaux dans `adb/etat/`
  (ignoré par git).
- `lanceur/` : appli Flutter Android (`fr.veilleuse.lanceur`), déclarée écran
  d'accueil et appli TV. Dessinée en 1280 × 720, identité veilleuse, police
  Bricolage Grotesque, navigation croix + OK + retour. Retour ne quitte
  jamais. Teinte d'ambiance gardée entre deux démarrages.

## Vérifier sans le projecteur

```sh
cd projecteur/lanceur
flutter test          # 6 tests : rangement, focus, Ambiance, Réglages, Retour
flutter analyze
```

L'APK se construit en CI (le conteneur de l'agent n'a pas de SDK Android).

## Reste à faire avec le vrai projecteur

- Relever la version du firmware et l'ABI (`inventaire.sh`).
- Remplir `ciblesTrapeze` et `ciblesMiseAuPoint` dans
  `lanceur/lib/donnees/catalogue.dart`, et resserrer les motifs larges de
  `paquets-proteges.txt`.
- Vérifier que la touche Accueil de la télécommande mène bien à Veilleuse ;
  sinon, piste d'un service d'accessibilité qui la redirige (sans root).
