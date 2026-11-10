# 0002. Viser le 1080p avec un décodage vidéo logiciel

- Statut : acceptée
- Date : 2026-11-03

## Contexte

Sur noyau mainline, le décodage matériel du S905X3 est incomplet : le pilote V4L2 `meson-vdec` est encore dans `staging`. LibreELEC 12 décode en logiciel sur cette puce ([notes de version](https://libreelec.tv/2025/01/22/libreelec-nexus-12-0-2/)). Les 4 cœurs A55 suffisent pour du 1080p, pas pour la 4K.

## Options envisagées

1. Cible 1080p, décodage logiciel, V4L2 en amélioration : réaliste tout de suite.
2. Cible 4K : impossible sans décodage matériel fiable, donc sans noyau du fabricant. Contraire à l'ADR 0001.

## Décision

L'interface et la vidéo visent le **1080p**. Le décodage matériel V4L2 est une piste d'amélioration, pas un prérequis.

## Conséquences

- Mesurer en phase 1 la charge CPU sur du H.264 et du HEVC 1080p (mpv).
- Le HEVC 10 bits 1080p peut être limite : à surveiller.
- On reviendra dessus si `meson-vdec` sort de staging et marche sur la box.
