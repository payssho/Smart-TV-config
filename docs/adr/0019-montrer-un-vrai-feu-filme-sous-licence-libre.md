# 0019. Montrer un vrai feu filmé et un vrai son, sous licence libre

- Statut : proposée
- Date : 2026-11-10

## Contexte

Le « Feu de cheminée » de la première version était dessiné par le code
(flammes en courbes, bruit brun et crépitements générés par `ffmpeg`).
À la relecture du 2026-11-10, Marius l'a refusé : il veut un vrai feu et un
vrai son, « comme sur Netflix ou YouTube », pas une imitation.

Contraintes : l'écran doit tourner hors ligne sur la box, se publier dans la
prévisualisation (page Claude, fichiers de 16 Mo au plus, aucun hôte externe),
et les médias doivent être réutilisables légalement, crédits compris. Depuis le
conteneur de l'agent, seul GitHub est joignable (Wikimedia, Pexels, Pixabay et
Freesound sont refusés par le proxy).

## Options envisagées

1. Garder le feu dessiné, en plus travaillé : léger, mais c'est justement ce
   que Marius refuse.
2. Vidéo et son sous licence Pexels ou Pixabay : beaucoup de choix, mais pas
   joignables d'ici, et des licences maison moins claires que Creative Commons.
3. Vidéo Wikimedia Commons (CC BY 3.0) et son Freesound (CC0), récupérés via
   des dépôts GitHub qui en documentent la provenance :
   [jeremykenedy/hearth-presence](https://github.com/jeremykenedy/hearth-presence)
   (`media/source/wood-fire.webm`, 1920×1080) et
   [Tafazzolian/still-sounds](https://github.com/Tafazzolian/still-sounds)
   (`files/fireplace-lit-default.ogg`, lurpsis, Freesound 444127).
4. Diffuser une vidéo YouTube de cheminée : dépend du réseau et de YouTube,
   droits non clairs pour un usage embarqué.

## Décision

Option 3. La vidéo est bouclée sans couture (fondu de 2 s, 20 s, H.264 1080p30,
7,4 Mo, sans son) et le son est une boucle séparée de 57 s (fondu de 3 s, MP3
128 kb/s), plus longue que la vidéo pour qu'on n'entende pas la reprise. La
lecture passe par `video_player` : flutter-pi le sert par GStreamer sur la box
(ADR 0010), le navigateur par sa balise vidéo dans la prévisualisation. Sans
lecteur (tests, build Linux de bureau), l'écran montre une image fixe du même
feu. Le crédit CC BY s'affiche dans l'écran du feu et dans Réglages > Crédits ;
le détail des modifications est dans `ui/assets/CREDITS.md`, et
`scripts/medias/preparer-feu.sh` refait les fichiers.

## Conséquences

- Le feu est réel et le son aussi ; plus aucune imitation en code.
- +8,4 Mo dans l'image et la prévisualisation. La lecture H.264 1080p30 utilise
  le décodeur matériel de la box (à vérifier en phase 4 avec ADR 0010) ; en
  profil 2 Go, l'écran du feu ne tourne pas en même temps que Chromium.
- Les fonds de l'OS (lucioles, braises, pluie, nuit calme) restent dessinés par
  le code : ils doivent réagir à la couleur des lumières et tourner sans fin en
  arrière-plan, ce qu'une vidéo ferait moins bien et plus cher en mémoire.
- On remplacera la vidéo par une autre plus longue ou en 4K si une source libre
  meilleure apparaît ; le script et le fichier de crédits sont faits pour ça.
