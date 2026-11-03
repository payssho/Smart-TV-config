# 0008. Écrire l'interface en Flutter, affichée par flutter-pi

- Statut : acceptée
- Date : 2026-11-03

## Contexte

L'interface « 10 pieds » doit être belle, fluide et pilotée à la croix. Marius fait déjà son app en Flutter et veut partager thème et code Dart. [flutter-pi](https://github.com/ardera/flutter-pi) dessine en DRM/KMS sans compositeur et embarque un lecteur vidéo GStreamer, mais il est testé officiellement sur Raspberry Pi seulement.

## Options envisagées

1. **Flutter via flutter-pi** : directement sur KMS (ADR 0007), entrées via libinput, lecteur vidéo intégré.
2. **Repli : Flutter (embedder Linux GTK) sur un compositeur Wayland minimal `cage`** : chemin officiel de Flutter, une couche de plus.
3. Qt/QML : très bon en embarqué mais pas de partage avec l'app. Écarté.
4. Interface web dans un navigateur kiosque : lourd sur 4 A55. Écarté.

## Décision

Flutter via flutter-pi. Si flutter-pi échoue sur S905X3 en phase 2, on bascule sur `cage` + Flutter Linux, via une nouvelle ADR.

## Conséquences

- flutter-pi est à **valider tôt** (phase 2, risque R2). C'est le point de non-retour technique.
- L'app est testable sans la box : Flutter desktop, web et `flutter test`.
