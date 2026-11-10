# 0013. Reprendre l'identité visuelle « veilleuse » de l'app

- Statut : acceptée
- Date : 2026-11-03

## Contexte

L'app Home device manager a une identité « veilleuse » : l'écran s'éclaire de la couleur réelle des lumières (halo), seul accent fort ; ambre pour les actions ; police Bricolage Grotesque (OFL). Tokens dans `app/lib/ui/theme.dart` du dépôt voisin.

## Options envisagées

1. **Reprendre l'identité**, adaptée au « 10 pieds » (tailles, focus, overscan) : les deux produits se ressemblent.
2. Identité propre à la télé : plus libre, mais deux langages visuels à maintenir.

## Décision

Option 1. Le thème est copié pour le prototype, puis partagé par paquet Dart dès qu'il existe.

## Conséquences

- Ne pas dupliquer le thème à la main au-delà du prototype.
- L'état de focus devient un élément central du thème (halo ambre lisible à 3 m).
