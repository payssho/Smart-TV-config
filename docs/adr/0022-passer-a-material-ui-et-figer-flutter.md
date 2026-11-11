# 0022. Passer au paquet material_ui et figer la version de Flutter

- Statut : proposée
- Date : 2026-11-11

## Contexte

Flutter 3.50.0 est sorti sur le canal stable le 11 novembre 2026. Il déclare
`package:flutter/material.dart` obsolète : les widgets Material quittent le
SDK pour le paquet `material_ui`. La CI suivait le canal stable sans numéro
de version : le jour de la sortie, `flutter analyze` a échoué sur les quinze
fichiers de l'app sans qu'une ligne du dépôt ait changé, et la PR du jumeau
QEMU a dû figer Flutter en 3.47.9 pour repasser au vert.

L'app se sert peu de Material (`MaterialApp`, `Scaffold`, `ThemeData`,
`Icons`, couleurs), mais elle s'en sert partout.

## Options envisagées

1. **Importer `material_ui` et figer la version de Flutter en CI.** La
   migration est mécanique (`dart fix --apply` remplace les imports et ajoute
   la dépendance). La version de Flutter devient un numéro écrit dans le
   dépôt, qu'on monte dans une PR.
2. Importer `material_ui` et continuer de suivre le canal stable : rien à
   maintenir, mais la prochaine sortie peut de nouveau casser la CI d'une PR
   sans rapport.
3. Rester en 3.47.9 : aucun travail aujourd'hui, mais plus de correctifs, et
   l'import obsolète finira par disparaître.
4. Se passer de Material et tout réécrire sur `widgets.dart` : l'app n'a pas
   besoin de tout Material, mais c'est une réécriture du thème, des icônes
   et de la navigation, sans gain mesuré.

## Décision

Option 1. Tous les fichiers importent `package:material_ui/material_ui.dart`.
La CI installe Flutter 3.50.0, écrit dans `.github/workflows/ci.yml`,
`banc-memoire.yml` et `jumeau.yml` ; `ui/pubspec.yaml` refuse un SDK plus
ancien. Monter de version se fait dans une PR dédiée, qui change ces numéros
ensemble.

## Conséquences

- Une sortie de Flutter ne casse plus la CI par surprise ; en échange, il
  faut penser à monter la version (une issue par version stable suffit).
- Sur la box, flutter-pi a besoin d'un moteur de la même version que le SDK
  qui a compilé l'app (ADR 0008) : l'image Buildroot de la phase 3 reprendra
  ce même numéro.
- `material_ui` tire `flutter_localizations` et `intl`. Le poids ajouté au
  binaire et à la mémoire est à relever au prochain passage du banc 2 Go /
  4 Go (ADR 0016).
- L'option 4 reste ouverte si le banc montre que Material pèse trop en 2 Go.
