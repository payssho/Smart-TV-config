# Jumeau de la box : 2 Go contre 4 Go

Noyau 6.8.0-31-generic (aarch64), scénario « fumee », paliers de 20 s, Chromium absent.

| | 2 Go | 4 Go |
|---|---:|---:|
| RAM vue par Linux (Mo) | 1645 | 3339 |
| Swap zram (Mo) | 0 | 0 |
| Démarrage jusqu'au scénario (s, émulé) | 49.0 | 54.1 |
| Première image de l'interface (ms, émulé) | — | — |
| OOM au total | 0 | 0 |

## Mémoire par palier

Occupée / disponible au plus bas, en Mo. « zram A→B » : A Mo de tas inactif compressés dans B Mo de RAM.

| Palier | 2 Go | 4 Go |
|---|---|---|
| Accueil | 407 / 1238 | 407 / 2918 |

## Coût de l'entretien

Travail de référence : décoder 90 images 1080p, médiane de 3 essais, en secondes émulées. Seul compte l'écart en %.

| | 2 Go | 4 Go |
|---|---:|---:|
| Référence seule (s) | 7.47 | 7.13 |
| Pendant une lecture, entretien en boucle (s) | 7.94 | 8.02 |
| Surcoût pendant la lecture, boucle serrée (%) | 6.3 | 12.5 |
| Boucle plus fréquente que sur la box (×) | 283 | 291 |
| Surcoût ramené à 1 passage / 10 min (%) | 0.022 | 0.043 |
| Durée d'un passage repoussé (ms) | 1091 | 1008 |
| Garde quand le processeur travaille | repousse (processeur occupé à 94 %) | repousse (processeur occupé à 86 %) |
| Pire cas : ménage forcé en même temps (s) | 8.44 | 8.57 |
| Surcoût du ménage forcé (%) | 13.0 | 20.2 |
| Durée du ménage au repos (s) | 20.0 | 21.8 |
| Cache Chromium avant → après (Mo) | 456 → 255 (plafond 256) | 712 → 511 (plafond 512) |

## Réglages appliqués par tele-memoire

| | 2 Go | 4 Go |
|---|---:|---:|
| memdisponible_mo | 1240 | 2926 |
| memtotal_mo | 1645 | 3339 |
| page-cluster | 0 | 0 |
| profil | 2go | 4go |
| swappiness | 100 | 60 |
| watermark_scale_factor | 125 | 10 |

## Captures de l'écran du jumeau

- [capture-2go-accueil.png](capture-2go-accueil.png)
- [capture-4go-accueil.png](capture-4go-accueil.png)

## Verdict automatique

- ✓ Interface et hub jamais tués, entretien effacé pendant la lecture, caches sous plafond.
