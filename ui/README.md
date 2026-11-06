# Interface de la télé (Flutter)

App « 10 pieds » de la télé maison : flutter-pi sur la box (ADR 0008), build web pour la prévisualisation (ADR 0015). Identité « veilleuse » (ADR 0013), navigation 100 % télécommande (ADR 0009).

## Écrans

- **Onglets** : Regarder, Lumières, Ambiance de la pièce, Ambiance de l'OS, Réglages. La croix vers le haut mène aux onglets, un onglet affiche sa section dès qu'il a le focus, la croix vers le bas entre dans la section.
- **Regarder** : YouTube, Twitch, Netflix et Canal+ (sous Android, avec confirmation), Médias, puis « Feu de cheminée » (flammes animées et son de feu).
- **Ambiances** : les scènes de lumière et le fond de l'OS (lucioles, braises, nuit calme) colorent l'écran dès qu'elles ont le focus.
- **Touches** : croix, OK, Retour (remonte aux onglets, puis à « Regarder »), Accueil (revient sur la première appli).

## Commandes

```sh
flutter test                                   # tests de navigation et des profils
flutter run -d linux                           # sur le poste
flutter run -d chrome --web-browser-flag=--autoplay-policy=no-user-gesture-required
../scripts/previsu/construire.sh               # prévisu publiable (build/previsu/)
```

Paramètres d'adresse de la prévisu web : `?memoire=2go` (profil 2 Go), `?heure=21:47` (horloge figée).

## Profil mémoire

`lib/systeme/memoire.dart` : en 2 Go, cache d'images de 32 Mo (96 Mo en 4 Go), vidé avant une appli plein écran, et fond allégé. Sur la box, `--dart-define=PROFIL_MEMOIRE=2go`. Le sélecteur dans Réglages > Système n'existe qu'en debug et dans la prévisu.

## Arborescence

- `lib/ui/` : thème « veilleuse », tuile focusable, fond animé, logos, mise à l'échelle 1080p.
- `lib/ecrans/` : écran principal et ses sections, feu de cheminée, dialogue Android.
- `lib/donnees/` : catalogue, état de la maison (démo en attendant le hub), état de l'OS.
- `lib/systeme/` : profil mémoire, son, télécommande de la prévisu (web seulement).
- `assets/` : Bricolage Grotesque (OFL, `assets/fonts/OFL.txt`) et le son du feu, généré par `ffmpeg` (bruit brun filtré et crépitements aléatoires, aucun enregistrement tiers).
