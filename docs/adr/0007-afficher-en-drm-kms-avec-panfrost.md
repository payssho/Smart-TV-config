# 0007. Afficher en DRM/KMS avec Mesa Panfrost, sans X11 ni Wayland

- Statut : acceptée
- Date : 2026-11-03

## Contexte

Une seule application plein écran tourne sur la télé. Le GPU Mali-G31 MP2 a un pilote libre, **Panfrost** (Mesa), en mainline.

## Options envisagées

1. **DRM/KMS + Mesa Panfrost + GBM/EGL**, l'application dessine directement sur l'écran : démarrage rapide, moins de couches, moins de mémoire.
2. Compositeur Wayland : utile pour plusieurs fenêtres, inutile ici sauf en repli (ADR 0008).
3. X11 : lourd et obsolète. Rejeté.

## Décision

DRM/KMS + Panfrost + GBM/EGL, sans serveur graphique.

## Conséquences

- Valider Panfrost en phase 1 (`glmark2-es2-drm`).
- La vidéo doit passer par le même chemin (plans DRM ou textures GL).
