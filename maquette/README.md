# Maquette de l'interface

`banc-interface.html` est le banc de prévisu de l'interface télé (jalon J1 du [plan de réalisation](../docs/plan-de-realisation.md), issue #41). C'est une maquette HTML, pas l'app Flutter : elle sert à valider les écrans, la navigation au focus et l'identité « veilleuse » à 3 m avant d'écrire le code, et à comparer une box 2 Go et 4 Go.

## Ce qu'elle montre

- Un écran 1920×1080 réel mis à l'échelle, avec la zone de sécurité de surbalayage en option.
- Les écrans prévus : accueil, YouTube (Chromium kiosque), Twitch, maison, mémoire, dialogue « redémarrer sous Android ».
- La navigation à la télécommande : flèches, Entrée, Échap ou Retour arrière, H pour l'accueil, ou la télécommande à l'écran.
- Un modèle mémoire par composant pour 2 Go et 4 Go, en soirée normale ou en pire cas. Les chiffres sont des **estimations** (constantes `PROFILS` et `composants()` dans le script), à remplacer par les mesures de #43.

## La modifier et la republier

Le fichier est un fragment de page : le `<title>`, le `<style>` et le `<script>` sans `<html>` ni `<body>`, au format des pages Claude.

- Depuis un fil du projet Claude : demander le changement, l'agent modifie le fichier et le republie à la même adresse (outil Artifact, même chemin de fichier dans la session, ou l'URL de la page depuis une autre session).
- En local : l'ouvrir dans un navigateur suffit, le navigateur ajoute la structure manquante.

Les tokens de couleur viennent de `app/lib/ui/theme.dart` dans `payssho/Home-device-manager` (palette « nuit »). Quand l'app Flutter existera (#42), son build web remplacera cette maquette.
