# Banc mémoire du 2026-11-06

Profils : 2go (1700 Mo vus par Linux), 4go (3500 Mo vus par Linux).
Paliers de 40 s ; valeurs en Mo, régime établi.

## Vue d'ensemble

| Palier | 2go : utilisée / libre | 2go : pic | 2go : tués (OOM) | 4go : utilisée / libre | 4go : pic | 4go : tués (OOM) |
|---|---:|---:|---:|---:|---:|---:|
| Accueil | 408.7 / 1291.3 | 552.7 | 0 | 405.6 / 3094.4 | 507.4 | 0 |
| YouTube (Chromium) | 768.1 / 931.9 | 1323.6 | 0 | 759.1 / 2740.9 | 1165.4 | 0 |
| Retour à l'accueil | 413.7 / 1286.3 | 812.7 | 0 | 414.7 / 3085.3 | 648 | 0 |
| Twitch (lecteur 1080p60) | 481.4 / 1218.6 | 948.4 | 0 | 479 / 3021 | 742.7 | 0 |
| Pire cas | 1038.5 / 661.5 | 1700 (plein) | 0 | 1082.6 / 2417.4 | 1474.9 | 0 |
| Pire cas après 2 h de YouTube | 776.6 / 923.4 | 1700 (plein) | 1 | 1679.2 / 1820.8 | 2147.7 | 0 |

« Utilisée » = mémoire anonyme (tas, piles), non récupérable sans tuer. Le cache de fichiers vient en plus mais se libère sous pression. « Pic » = mémoire totale la plus haute du palier, cache compris ; « plein » = le plafond de la box a été atteint.

## Détail par brique

### 2go

- Première image de l'interface : 731 ms
- Pic mémoire du conteneur : 1700 Mo
- Processus tués par l'OOM : 1

| Palier | Interface Flutter | Chromium | Lecteur 1080p60 | Hub (simulé) | Mise à jour (simulée) | Xvfb (absent sur la box) | Banc et système | Lecteur (vitesse) | Survivants |
|---|---:|---:|---:|---:|---:|---:|---:|---:|---|
| Accueil | 425.5 | n/a | n/a | 45.3 | n/a | 49.4 | 8.4 | n/a | tous |
| YouTube (Chromium) | 401.5 | 643.8 | n/a | 44.9 | n/a | 52.1 | 10.3 | n/a | tous |
| Retour à l'accueil | 423.5 | n/a | n/a | 45.3 | n/a | 51.1 | 8.6 | n/a | tous |
| Twitch (lecteur 1080p60) | 421 | n/a | 98.7 | 45.2 | n/a | 50.2 | 8.5 | 1.01 x | tous |
| Pire cas | 364.3 | 390.2 | 73.2 | 73 | 124 | 36.6 | 8.2 | 1.01 x | tous |
| Pire cas après 2 h de YouTube | 365.9 | 234.5 | 74.8 | 73.1 | 124.4 | 39.4 | 8.1 | 1 x | tous |

### 4go

- Première image de l'interface : 879 ms
- Pic mémoire du conteneur : 2151.4 Mo
- Processus tués par l'OOM : 0

| Palier | Interface Flutter | Chromium | Lecteur 1080p60 | Hub (simulé) | Mise à jour (simulée) | Xvfb (absent sur la box) | Banc et système | Lecteur (vitesse) | Survivants |
|---|---:|---:|---:|---:|---:|---:|---:|---:|---|
| Accueil | 420.7 | n/a | n/a | 45.3 | n/a | 47.5 | 8.5 | n/a | tous |
| YouTube (Chromium) | 400.1 | 649 | n/a | 44.9 | n/a | 51.4 | 10.4 | n/a | tous |
| Retour à l'accueil | 422.8 | n/a | n/a | 45.3 | n/a | 51 | 8.6 | n/a | tous |
| Twitch (lecteur 1080p60) | 416.3 | n/a | 99.9 | 45.2 | n/a | 52.2 | 8.5 | 1.01 x | tous |
| Pire cas | 405.3 | 742.6 | 96 | 74.2 | 125.2 | 51.4 | 9.8 | 1.01 x | tous |
| Pire cas après 2 h de YouTube | 403.9 | 1352.9 | 96 | 74.2 | 125.2 | 51.3 | 9.9 | 1 x | tous |
