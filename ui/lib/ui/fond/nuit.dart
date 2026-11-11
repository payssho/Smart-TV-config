import 'dart:math' as math;
import 'dart:ui' as ui;

import 'matiere.dart';
import 'rythme.dart';
import 'toile.dart';

/// Nuit : presque rien. Deux nappes de lumière qui dérivent, quelques
/// étoiles qui scintillent à peine et, une fois par boucle, une étoile
/// filante.
abstract final class Nuit {
  static const _froide = 0xDCE4FF;
  static const _chaude = 0xFFE9CF;

  static void nappes(Toile o) {
    final t = o.t;
    final present = 0.4 + 0.6 * o.intensite;
    o
      ..nappe(
        ui.Offset(
          o.l * (0.28 + 0.07 * math.sin(t * tour)),
          o.h * (0.66 + 0.06 * math.cos(t * tour)),
        ),
        o.l * 0.5,
        [teinte(o.lampe, 0.07 * present), teinte(o.lampe, 0)],
        const [0, 1],
      )
      ..nappe(
        ui.Offset(
          o.l * (0.7 + 0.06 * math.sin(t * tour * 2 + 2.1)),
          o.h * (0.36 + 0.07 * math.cos(t * tour * 2 + 2.1)),
        ),
        o.l * 0.46,
        [teinte(0x4654C0, 0.13), teinte(0x4654C0, 0)],
        const [0, 1],
      );
  }

  static void etoiles(Toile o) {
    final lot = Toile.lumiere;
    final k = o.echelle;
    final n = o.combien(72, 46);
    for (var i = 0; i < n; i++) {
      final x = hasard(i, 71);
      // Plus serrées vers le haut.
      final y = 0.02 + 0.9 * math.pow(hasard(i, 72), 1.7);
      final r = hasard(i, 73);
      final pas = 22 + (hasard(i, 74) * 40).floor();
      final scintille = 0.68 + 0.32 * bruit(o.t * pas + i, pas, i);
      final eclat = (0.14 + 0.5 * r * r * r) * (o.miniature ? 2.2 : 1);
      final a = eclat * scintille * o.voile(x, y);
      final couleur = i % 5 == 0 ? _chaude : _froide;
      if (r > 0.86) {
        lot.poser(Matiere.lueur, x * o.l, y * o.h, 22 * k, couleur, 0.28 * a);
      }
      lot.poser(
        Matiere.point,
        x * o.l,
        y * o.h,
        (2.6 + 2.6 * r) * k,
        couleur,
        a,
      );
    }
    if (o.miniature) return;
    // L'étoile filante : un peu moins d'une seconde, une fois par boucle.
    const depart = 0.62;
    const duree = 0.007;
    final s = (o.t - depart) / duree;
    if (s <= 0 || s >= 1) return;
    final avance = 1 - math.pow(1 - s, 2).toDouble();
    final debut = ui.Offset(o.l * 0.64, o.h * 0.1);
    final fin = ui.Offset(o.l * 0.47, o.h * 0.25);
    final p = ui.Offset.lerp(debut, fin, avance)!;
    final direction = fin - debut;
    lot.poser(
      Matiere.trait,
      p.dx,
      p.dy,
      230 * k,
      _froide,
      0.55 * math.sin(s * math.pi),
      math.atan2(direction.dy, direction.dx) - math.pi / 2,
    );
  }
}
