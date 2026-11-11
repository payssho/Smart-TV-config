# Interface de la télé (Flutter)

App « 10 pieds » de la télé maison : flutter-pi sur la box (ADR 0008), build web pour la prévisualisation (ADR 0015). Identité « veilleuse » (ADR 0013), navigation 100 % télécommande (ADR 0009).

## Écrans

- **Onglets** : Regarder, Ambiance, Réglages. La croix vers le haut mène aux onglets, un onglet affiche sa section dès qu'il a le focus, la croix vers le bas entre dans la section. Les lumières une par une se pilotent depuis l'app mobile (issue #46).
- **Regarder** : deux rangées de quatre. En haut, ce qui s'ouvre dans notre OS : YouTube, Twitch, Deezer, Médias. En dessous, ce qui redémarre sous Android (icône de redémarrage et confirmation) : Netflix, Canal+, Prime Video, Disney+. Puis « Feu de cheminée » : un vrai feu filmé et un vrai crépitement enregistré (crédits dans `assets/CREDITS.md`). Aucun texte d'aide : logo et nom suffisent.
- **Ambiance** : des préréglages (Veillée, Coin du feu, Pluie dehors, Cinéma, Nuit) qui règlent d'un OK le fond de l'OS et la lumière de la pièce, puis le réglage fin : fond seul (lucioles, braises, pluie, nuit calme) et lumière seule. L'écran prend le fond et la couleur du choix qui a le focus.
- **Fonds** : une pièce nue éclairée par la lampe, sans décor, tout en lumière sur trois plans (loin net, près flou comme hors mise au point). Veillée : des lucioles qui s'allument d'un coup et s'éteignent lentement. Coin du feu : la lueur d'un foyer hors champ et ses braises, sans flammes. Pluie : les lumières de la rue, l'averse et les gouttes sur la vitre. Nuit : deux nappes, quelques étoiles, une étoile filante par boucle. Motifs précuits posés en lot (ADR 0021), boucle de deux minutes sans couture, moins de lumières en 2 Go, figés si les animations sont réduites. Code dans `lib/ui/fond/` ; `PLANCHE=dossier` sur `test/fond_test.dart` écrit chaque fond en PNG pour le relire à l'œil.
- **Réglages** : système (profil mémoire), stockage (plafonds de cache, nettoyage, issue #45), télécommande, redémarrer sous Android, crédits.
- **Touches** : croix, OK, Retour (remonte aux onglets, puis à « Regarder »), Accueil (revient sur la première appli).

## Commandes

Flutter 3.50.0, la version figée en CI (ADR 0022). Les widgets Material viennent du paquet `material_ui` : importer `package:material_ui/material_ui.dart`, plus `package:flutter/material.dart`.

```sh
flutter test                                   # tests de navigation et des profils
flutter run -d linux                           # sur le poste
flutter run -d chrome --web-browser-flag=--autoplay-policy=no-user-gesture-required
../scripts/previsu/construire.sh               # prévisu publiable (build/previsu/)
```

Paramètres d'adresse de la prévisu web : `?memoire=4go` (profil 4 Go ; 2 Go par défaut, la cible de la première version), `?heure=21:47` (horloge figée).

## Profil mémoire

`lib/systeme/memoire.dart` : en 2 Go, cache d'images de 32 Mo (96 Mo en 4 Go), vidé avant une appli plein écran, et fond allégé. Sur une box 4 Go, `--dart-define=PROFIL_MEMOIRE=4go`. Le sélecteur dans Réglages > Système n'existe qu'en debug et dans la prévisu.

## Arborescence

- `lib/ui/` : thème « veilleuse », tuile focusable, fond animé, logos, mise à l'échelle 1080p.
- `lib/ecrans/` : écran principal et ses sections, feu de cheminée, dialogue Android.
- `lib/donnees/` : catalogue, état de la maison (démo en attendant le hub), état de l'OS.
- `lib/systeme/` : profil mémoire, son, médias, télécommande de la prévisu (web seulement).
- `assets/` : Bricolage Grotesque (OFL, `assets/fonts/OFL.txt`), la vidéo du feu (Wikimedia Commons, CC BY 3.0), son image fixe et le crépitement (Freesound, CC0). Crédits et modifications : `assets/CREDITS.md` ; pour les refaire : `scripts/medias/preparer-feu.sh`.

## Vidéo et son

`video_player` lit la vidéo du feu : sur la box, flutter-pi le sert par GStreamer (ADR 0010) ; dans la prévisu, c'est la balise vidéo du navigateur (H.264). Sans lecteur (tests, build Linux de bureau), l'écran garde l'image fixe. Le son est une boucle séparée, plus longue que la vidéo, pour qu'on n'entende pas la reprise ; le navigateur ne le joue qu'après un premier clic dans la page.
