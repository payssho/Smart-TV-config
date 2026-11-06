# 0015. Prévisualiser l'interface avec le build web de l'app Flutter

- Statut : proposée
- Date : 2026-11-06

## Contexte

Marius veut concevoir et piloter l'interface depuis Claude, sans attendre la box (reçue en phase 1) ni flasher une carte à chaque retouche. La maquette HTML (#41) valide les idées mais ce n'est pas le code qui tournera sur la télé : chaque écran y est écrit deux fois. L'app est en Flutter (ADR 0008), qui sait compiler pour le web.

## Options envisagées

1. **Build web de la vraie app, publié comme page Claude** : `flutter build web --no-web-resources-cdn` (CanvasKit embarqué, aucune ressource externe), dans une page hôte qui affiche un écran 1080p mis à l'échelle, une télécommande à l'écran et les mesures du banc mémoire. Même code que la télé, republiable en une commande.
2. Garder la maquette HTML comme seule prévisu : rapide à retoucher, mais elle diverge forcément de l'app.
3. Captures d'écran générées par les tests (golden files) : fidèles, mais figées, sans navigation.

## Décision

Option 1. `scripts/previsu/construire.sh` produit `build/previsu/`, publié comme page Claude et en artefact de CI à chaque PR qui touche `ui/`. La maquette HTML reste un carnet d'idées.

## Conséquences

- L'interface se dessine toujours sur 1920 × 1080 logiques, puis se met à l'échelle (`EchelleTele`) : la prévisu, les tests et la télé ont la même mise en page.
- Flutter web refuse les événements clavier synthétiques : la télécommande de la page parle à l'app par `postMessage`, et l'app rend le focus perdu quand on clique hors d'elle (`lib/systeme/telecommande_distante.dart`). Ce canal n'existe que dans le navigateur.
- Le navigateur ne dit rien du processeur de la box : la fluidité se juge sur la télé (J4). Le son passe par le navigateur dans la prévisu, par GStreamer sur la box (ADR 0010, phase 4).
- On reviendrait dessus si le rendu web s'écartait trop du rendu flutter-pi (polices, shaders).
