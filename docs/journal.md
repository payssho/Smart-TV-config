# Journal des phases

Une courte rétro à la fin de chaque phase : ce qui a marché, ce qui a coincé, ce qu'on change. La roadmap et le plan se révisent ensuite.

## Phase 0. Cadrage (2026-11-03 au 2026-11-10)

- **Livré** : docs, 16 ADR, CI, checklist de la phase 1, plan par jalons et maquette (#37, #44), puis l'app Flutter TV, sa prévisu web et le banc mémoire 2 Go / 4 Go (#47). Les trois PR sont fusionnées le 2026-11-10 après la relecture hors ligne de Marius.
- **Ce qui a marché** : relire hors ligne sur un dossier complet, avec un bloc de questions par section ; avancer l'interface et le banc mémoire sans la box.
- **Ce qui a coincé** : trois PR empilées à fusionner dans l'ordre ; GitHub Actions ne démarre plus sur le dépôt depuis le 2026-11-06 (« startup_failure »), les vérifications ont été refaites en local.
- **Ce qu'on change** :
  - Box : pas encore achetée ; une S905X3 2 Go d'occasion d'abord, 4 Go en repli (ADR 0017). Tout s'avance sur une copie émulée en 2 Go et 4 Go.
  - eMMC : écriture permise quand elle sert le projet, après une sauvegarde complète (ADR 0018). Aucun contournement de DRM, inchangé.
  - Démarrage : fiable à 100 % avant d'être rapide.
  - Interface : trois onglets (Regarder, Ambiance, Réglages), le moins de texte possible ; lumières et télécommande dans l'app Home device manager (#46).
  - Nouveau risque R7 : le stockage qui se remplit avec le temps ; plafonds arrêtés dans #45.
  - Le bouton « redémarrer sous Android » reste en phase 4 seulement.
