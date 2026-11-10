# 0018. Garder la box 2 Go fluide avec zram et un entretien qui ne tourne qu'au repos

- Statut : proposée
- Date : 2026-11-10

## Contexte

Marius veut une première version sur une box 2 Go, d'occasion si possible, et ne passer à 4 Go que si ça bugue. Il demande des scripts d'optimisation lancés régulièrement, sans aucun impact sur les performances ni sur l'expérience. Le banc de l'ADR 0016 montre que 2 Go tient une soirée normale mais perd l'onglet YouTube après une longue session, et la vision ajoute un risque : le stockage et les caches qui se remplissent avec le temps et ralentissent la box (#45).

Deux pièges : un script « d'optimisation » qui tourne pendant qu'on regarde vole du processeur et de la carte SD, donc crée les saccades qu'il devait éviter ; et vider le cache du noyau (`drop_caches`) libère de la RAM sur le papier mais force à tout relire depuis une SD lente.

## Options envisagées

1. **Le noyau fait le travail, un script d'entretien s'efface** : au démarrage, `tele-memoire` règle une fois pour toutes zram (swap compressé en RAM), swappiness, MGLRU et les écritures SD selon la RAM détectée ; `tele-role` donne à chaque brique son rang face à l'OOM ; toutes les 10 minutes, `tele-entretien` lit trois compteurs et ne fait le ménage (caches plafonnés, Chromium oublié fermé, compaction, `fstrim`) que si la télé est au repos, en priorité minimale.
2. **Un démon de surveillance permanent** (earlyoom, nohang) : réagit plus vite, mais c'est un processus de plus qui tourne en continu, et il tue au jugé là où l'OOM du noyau, bien classé, suffit.
3. **Un nettoyage à heure fixe** (cron nocturne) : simple, mais la box peut être allumée à 3 h, et rien n'est fait si elle est éteinte la nuit.

## Décision

Option 1, dans `systeme/` (futur « overlay » de l'image Buildroot, déjà installé tel quel dans le jumeau de l'ADR 0017) :

- **Profil 2 Go** : zram lz4 à 75 % de la RAM, swappiness 100 (compresser du tas inactif coûte moins cher que relire la SD), `watermark_scale_factor` 125 (kswapd plus tôt, moins d'à-coups), MGLRU `min_ttl_ms` 1000 (sous forte pression, tuer Chromium plutôt que ramer). **Profil 4 Go** : zram 25 %, swappiness 60, réglages du noyau par défaut ailleurs.
- **Rangs OOM** : Chromium 800, mise à jour 300, lecteur −300, hub −800, interface −900.
- **Garde de repos** : activité « veille » ou « accueil » (fichier `/run/tele/activite` écrit par l'interface), inchangée depuis 5 minutes, PSI processeur ≤ 10 % et E/S ≤ 5 %. Sinon l'entretien repart en quelques millisecondes.
- **Au repos** : caches plafonnés (Chromium 256/512 Mo, miniatures 150/300, journal 64, temporaires 128/256), caches vidés si `/data` dépasse 75 %, alerte et mises à jour refusées au-delà de 90 % (vérifié même pendant la lecture, c'est une lecture seule), Chromium fermé s'il traîne hors de YouTube, compaction et `fstrim` hebdomadaire en veille. Jamais de `drop_caches`.
- **Priorités** : unité systemd en `CPUSchedulingPolicy=idle`, `IOSchedulingClass=idle`, `Nice=19`, `MemoryHigh=32M`.

## Conséquences

- L'absence d'impact se mesure : le jumeau relance un décodage 1080p de référence seul, pendant une lecture avec l'entretien en boucle, et pendant le ménage au repos, et le rapport donne l'écart en %. Le rapport échoue si l'entretien travaille pendant une lecture.
- L'interface doit écrire son activité dans `/run/tele/activite` (issue à ouvrir côté `ui/`) ; d'ici là, activité inconnue = on ne touche à rien.
- Les seuils sont des valeurs de départ, réglables dans `/etc/tele/memoire.conf` ; à reprendre avec les rapports du jumeau, puis sur la box.
- Les scripts sont en sh POSIX et testés aussi avec le sh de BusyBox, celui de l'image Buildroot.
