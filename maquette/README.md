# Maquette de l'interface

`banc-interface.html` est le banc de prévisu de l'interface télé (jalon J1 du [plan de réalisation](../docs/plan-de-realisation.md), issue #41). C'est une maquette HTML, pas l'app Flutter : elle sert à valider les écrans, la navigation au focus et l'identité « veilleuse » à 3 m avant d'écrire le code, et à comparer une box 2 Go et 4 Go.

## Ce qu'elle montre

- Un écran 1920×1080 réel mis à l'échelle, avec la zone de sécurité de surbalayage en option.
- Cinq sections dans un rail à gauche : Regarder, Lumières, Ambiance de la pièce, Ambiance de l'OS, Réglages. Depuis la relecture du 2026-11-10, l'app en a trois (Regarder, Ambiance, Réglages) et les lumières passent par l'app du téléphone. Plus YouTube (Chromium kiosque), Twitch, mémoire, stockage et le dialogue « redémarrer sous Android ».
- Un fond animé original : lucioles (herbes hautes, clignements lents, bokeh ; l'app les veut sans herbe, avec braises, nuit calme et pluie) ou ondes, couleur naturelle ou suivant la lampe, calme ou vivant ; en pause pendant la vidéo, allégé sur 2 Go.
- L'ambiance « Feu de cheminée » plein écran avec un crépitement synthétisé en Web Audio (aucun fichier son), la lampe qui vacille en ambre et une minuterie.
- Une télécommande à l'écran : croix en anneau, Accueil, Retour, volume de l'ampli et raccourcis Regarder, Lumières, Feu.
- La carte SD neuve ou après 2 ans, sans limites ou avec garde-fous (#45).
- La navigation à la télécommande : flèches, Entrée, Échap ou Retour arrière, H pour l'accueil, ou la télécommande à l'écran.
- Un modèle mémoire par composant pour 2 Go et 4 Go, en soirée normale ou en pire cas. Les chiffres sont des **estimations** (constantes `PROFILS` et `composants()` dans le script), à remplacer par les mesures de #43.

## La modifier et la republier

Le fichier est un fragment de page : le `<title>`, le `<style>` et le `<script>` sans `<html>` ni `<body>`, au format des pages Claude.

- Depuis un fil du projet Claude : demander le changement, l'agent modifie le fichier et le republie à la même adresse (outil Artifact, même chemin de fichier dans la session, ou l'URL de la page depuis une autre session).
- En local : l'ouvrir dans un navigateur suffit, le navigateur ajoute la structure manquante.

La vraie app Flutter a maintenant sa propre prévisu, construite par `scripts/previsu/construire.sh` et publiée comme page Claude (ADR 0015) : c'est elle qui fait foi pour l'interface. Cette maquette reste un carnet d'idées rapide à retoucher.

Les tokens de couleur viennent de `app/lib/ui/theme.dart` dans `payssho/Home-device-manager` (palette « nuit »). L'app Flutter et son build web (#42) l'ont remplacée comme référence.
