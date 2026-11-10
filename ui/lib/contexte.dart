import 'package:flutter/widgets.dart';

import 'systeme/memoire.dart';

typedef Horloge = DateTime Function();

/// Réglages fixés au démarrage, accessibles partout.
class ContexteTele extends InheritedWidget {
  const ContexteTele({
    super.key,
    required this.profil,
    required this.horloge,
    required super.child,
    this.changerProfil,
  });

  final ProfilMemoire profil;
  final Horloge horloge;

  /// Bascule 2 Go / 4 Go à chaud. Nul sur la box (build de production) :
  /// le sélecteur n'existe qu'en debug et dans la prévisualisation web.
  final ValueChanged<ProfilMemoire>? changerProfil;

  static ContexteTele de(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<ContexteTele>()!;

  @override
  bool updateShouldNotify(ContexteTele ancien) =>
      ancien.profil != profil ||
      ancien.horloge != horloge ||
      ancien.changerProfil != changerProfil;
}
