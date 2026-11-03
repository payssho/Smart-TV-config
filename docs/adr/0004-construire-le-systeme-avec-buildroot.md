# 0004. Construire le système avec Buildroot

- Statut : proposée
- Date : 2026-11-03

## Contexte

On veut une image minimale, reproductible, en lecture seule, qui démarre en quelques secondes sur une seule application plein écran. Une compilation complète prend 1 à 2 h et 15 à 25 Go.

## Options envisagées

1. **Buildroot** avec un arbre externe (`BR2_EXTERNAL`) : simple, rapide à apprendre, image monolithique adaptée à un appareil à une seule fonction. Paquets flutter-pi et Mesa disponibles ou faciles à ajouter.
2. Yocto : plus puissant (couches, SDK, gestion de paquets), mais beaucoup plus lourd à mettre en place et à construire.
3. Rester sur Armbian : pratique pour prototyper, mais distribution générique, lente à démarrer et difficile à figer.

## Décision

Buildroot avec un arbre externe dans `buildroot/` de ce dépôt. Armbian sert seulement à valider le matériel et prototyper (ADR 0005).

## Conséquences

- Build en GitHub Actions (libérer de l'espace, cache `dl/` et ccache) ou sous WSL2 chez Marius, jamais dans le conteneur de l'agent.
- On reviendra vers Yocto si Buildroot coince (paquets introuvables, besoin d'un gestionnaire de paquets).
