# 0021. Dessiner les fonds animés avec des motifs de lumière précuits

- Statut : proposée
- Date : 2026-11-11

## Contexte

Marius veut des fonds « très propres », cosy, simples et modernes pour
Pluie, Coin du feu, Veillée (lucioles) et Nuit. Ils tournent sans fin
derrière l'accueil, doivent prendre la couleur des lumières de la maison
(ADR 0013) et rester fluides sur la box, dont le processeur graphique
(Mali-G31) est petit, en 2 Go comme en 4 Go.

La première version dessinait chaque particule à la main et floutait les
plus proches à chaque image (`MaskFilter.blur`) : coûteux, et retiré du
profil 2 Go, donc le rendu le plus soigné n'arrivait pas sur la cible.

## Options envisagées

1. **Motifs précuits posés en lot.** Cinq motifs (halo, disque hors mise au
   point, filet, point, goutte) dessinés une fois dans une petite image,
   puis posés par centaines en un seul `drawRawAtlas`, teintés et
   additionnés. Aucun flou calculé pendant l'animation.
2. Un fragment shader plein écran par ambiance : le plus libre visuellement
   (réfraction des gouttes), mais chaque pixel paie tout le calcul à chaque
   image, et le résultat dépend du pilote Panfrost et du moteur de rendu.
3. Des vidéos en boucle : beau, mais lourd en mémoire, figé (pas de couleur
   des lumières), et la boucle se voit.
4. Garder les formes dessinées et les flous à chaque image.

## Décision

Option 1. Le fond se compose, de l'arrière vers l'avant : un socle par
ambiance (dégradés immobiles, cuits une fois à demi-définition), la lampe,
la scène en lots de motifs, puis un grain très fin qui trame les dégradés
sombres. Tous les mouvements sont des fonctions périodiques du temps
(nombre entier de cycles ou bruit replié) : la boucle de deux minutes se
referme sans couture, et un test le vérifie pixel à pixel. Le code est dans
`ui/lib/ui/fond.dart` et `ui/lib/ui/fond/`.

## Conséquences

- Le même rendu en 2 Go et en 4 Go : le profil 2 Go porte seulement moins de
  lumières. Le flou n'est plus un coût, il est dans le motif.
- Environ trois couches plein écran et deux appels de lot par image, quelle
  que soit l'ambiance. À mesurer sur la box en phase 4 (critère : accueil à
  60 images/s) ; si c'est trop, on baisse les quantités, pas la technique.
- Pas de vraie réfraction dans les gouttes de pluie : elles sont imitées par
  un motif. Un shader reste possible plus tard pour une ambiance précise.
- Mémoire : une planche de motifs de 400 × 204, un carreau de grain de
  128 × 128 et un socle de 960 × 540 par ambiance affichée, soit environ
  2,5 Mo.
- Pas de flammes dans « Coin du feu » : on montre la lueur et les braises,
  le vrai feu filmé garde son écran (ADR 0019).
