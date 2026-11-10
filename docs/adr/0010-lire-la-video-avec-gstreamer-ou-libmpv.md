# 0010. Lire la vidéo avec GStreamer (flutter-pi) ou libmpv

- Statut : proposée
- Date : 2026-11-03

## Contexte

Décodage logiciel 1080p (ADR 0002), affichage dans l'interface Flutter (ADR 0008).

## Options envisagées

1. **GStreamer**, via le lecteur intégré à flutter-pi (`video_player`) : déjà branché sur KMS, peu de code.
2. **libmpv** : excellent support des formats et sous-titres, mais intégration à écrire.

## Décision

Commencer par GStreamer via flutter-pi ; trancher en phase 4 après mesure.

## Conséquences

- Une ADR de remplacement fixera le choix final en phase 4.
