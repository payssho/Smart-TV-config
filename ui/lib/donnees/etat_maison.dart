import 'package:flutter/widgets.dart';

import '../ui/theme.dart';
import 'catalogue.dart';

/// État de la maison vu par la télé. Données de démonstration pour l'instant ;
/// en phase 5, il sera alimenté par le hub en gRPC (ADR 0012).
class EtatMaison extends ChangeNotifier {
  EtatMaison({List<Lumiere> lumieres = Catalogue.lumieres, Scene? scene})
    : _lumieres = List.of(lumieres),
      _scene = scene ?? Catalogue.scenes.first;

  final List<Lumiere> _lumieres;
  Scene _scene;

  List<Lumiere> get lumieres => List.unmodifiable(_lumieres);
  Scene get scene => _scene;

  int get nombreAllumees => _lumieres.where((l) => l.allumee).length;

  /// Couleur du halo : la moyenne des lumières allumées, pondérée par leur
  /// intensité. Couleur par défaut si tout est éteint.
  Color get couleurHalo {
    final allumees = _lumieres.where((l) => l.allumee).toList();
    if (allumees.isEmpty) return Veilleuse.haloParDefaut;
    var r = 0.0, v = 0.0, b = 0.0, poids = 0.0;
    for (final l in allumees) {
      final p = l.intensite.toDouble();
      r += l.couleur.r * p;
      v += l.couleur.g * p;
      b += l.couleur.b * p;
      poids += p;
    }
    return Color.from(
      alpha: 1,
      red: r / poids,
      green: v / poids,
      blue: b / poids,
    );
  }

  /// De 0 à 1 : le halo faiblit quand la maison s'éteint.
  double get intensiteHalo {
    if (nombreAllumees == 0) return 0.25;
    return (0.55 + 0.45 * nombreAllumees / _lumieres.length).clamp(0, 1);
  }

  void activerScene(Scene scene) {
    _scene = scene;
    for (var i = 0; i < _lumieres.length; i++) {
      final l = _lumieres[i];
      final allumee = switch (scene.id) {
        'nuit' => false,
        'cinema' => l.id == 'l2',
        'lecture' => l.id == 'l3' || l.id == 'l6',
        _ => l.piece == 'Salon' && l.id != 'l3' || l.id == 'l6',
      };
      _lumieres[i] = l.copieAvec(allumee: allumee);
    }
    notifyListeners();
  }

  void basculer(String idLumiere) {
    final i = _lumieres.indexWhere((l) => l.id == idLumiere);
    if (i < 0) return;
    _lumieres[i] = _lumieres[i].copieAvec(allumee: !_lumieres[i].allumee);
    notifyListeners();
  }
}

class PorteeMaison extends InheritedNotifier<EtatMaison> {
  const PorteeMaison({
    super.key,
    required EtatMaison etat,
    required super.child,
  }) : super(notifier: etat);

  static EtatMaison de(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<PorteeMaison>()!.notifier!;
}
