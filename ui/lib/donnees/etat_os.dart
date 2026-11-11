import 'package:flutter/widgets.dart';

/// Fond de l'OS, choisi dans l'onglet « Ambiance ».
enum FondOS {
  lucioles('Lucioles'),
  braises('Braises'),
  pluie('Pluie'),
  calme('Nuit calme');

  const FondOS(this.nom);
  final String nom;
}

/// Réglages d'ambiance de l'OS. En mémoire pour l'instant ; persistés dans
/// /data en phase 6.
class EtatOS extends ChangeNotifier {
  EtatOS([this._fond = FondOS.lucioles]);

  FondOS _fond;
  FondOS get fond => _fond;

  set fond(FondOS valeur) {
    if (valeur == _fond) return;
    _fond = valeur;
    notifyListeners();
  }

  /// Incrémenté par la touche Accueil : l'écran principal revient sur
  /// « Regarder ».
  final allerAccueil = ValueNotifier<int>(0);

  @override
  void dispose() {
    allerAccueil.dispose();
    super.dispose();
  }
}

class PorteeOS extends InheritedNotifier<EtatOS> {
  const PorteeOS({super.key, required EtatOS etat, required super.child})
    : super(notifier: etat);

  static EtatOS de(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<PorteeOS>()!.notifier!;
}
