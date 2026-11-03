# 0009. Recevoir la télécommande de la télé (CEC) et l'infrarouge comme des touches evdev

- Statut : acceptée
- Date : 2026-11-03

## Contexte

On veut piloter la box avec la télécommande de la télé (HDMI-CEC), avec la télécommande infrarouge de la box et avec l'app du S25, sans clavier ni souris. Le noyau expose le passthrough RC du CEC (`meson-ao-cec`) et l'infrarouge (`meson-ir`, `rc-core`, `ir-keytable`) comme des périphériques **evdev**, que flutter-pi lit via libinput.

## Options envisagées

1. **evdev pour la réception**, libcec ou `cec-ctl` pour les commandes actives (allumer la télé, changer d'entrée, veille) : l'interface reçoit des touches clavier sans code spécial.
2. Démon CEC en espace utilisateur qui injecte les touches (uinput) : utile si le passthrough noyau est incomplet.

## Décision

Option 1. L'interface est navigable entièrement à la croix + OK + retour (focus visible, `FocusTraversalGroup`, `Shortcuts`/`Actions`), textes lisibles à 3 m, marges d'overscan.

## Conséquences

- Le CEC n'a jamais été testé avec `meson-ao-cec` sur cette box ni avec la télé de Marius (risque R3) : phase 1.
- Logique d'entrée testée avec de faux évènements clavier dans `flutter test`.
- Repli : option 2, ou infrarouge + app seuls.
