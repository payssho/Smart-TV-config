import 'dart:math' as math;

import 'matiere.dart';
import 'rythme.dart';
import 'toile.dart';

/// Veillée : des lucioles dans la pénombre.
///
/// Trois plans. Au loin, des points qui dérivent ; au milieu, des lucioles
/// avec leur halo, qui éclairent un peu l'air autour d'elles ; tout près de
/// l'œil, de grands disques flous. Chacune clignote à son rythme : elle
/// s'allume d'un coup, s'éteint lentement, puis vole dans le noir.
abstract final class Lucioles {
  static const _jaune = 0xD9F27A;
  static const _miel = 0xFFE39A;
  static const _coeur = 0xFBFFE2;
  static const _flou = 0xB6DE4E;

  static final _essaim = List.generate(46, _Luciole.new);

  static void peindre(Toile o) {
    final k = o.echelle;
    final lot = Toile.lumiere;
    for (final f in _essaim.take(o.combien(46, 28))) {
      final cycle = o.t * f.cycles + f.phase;
      final u = cycle - cycle.floorToDouble();
      var e = eclat(u);
      // Certaines lancent deux éclats de suite.
      if (f.double_) e = math.max(e, 0.7 * eclat((u - 0.13) % 1.0));
      // Une miniature est une image fixe : on y garde les lucioles allumées.
      if (o.miniature) e = math.max(e, 0.35 + 0.65 * f.r);
      // Pendant l'éclat, un petit crochet vers le haut.
      final crochet = 0.014 * lisse(0, 0.25, u) * (1 - lisse(0.25, 0.8, u));
      final x =
          f.x +
          f.ampX * bruit(o.t * f.pasX + f.phase, f.pasX, f.graine) +
          0.006 * bruit(o.t * f.pasX * 7 + f.phase, f.pasX * 7, f.graine + 1);
      final y =
          f.y +
          f.ampY * bruit(o.t * f.pasY + f.phase * 1.7, f.pasY, f.graine + 2) +
          0.006 * bruit(o.t * f.pasY * 7 + f.phase, f.pasY * 7, f.graine + 3) -
          crochet;
      final voile = o.voile(x, y);
      final px = x * o.l;
      final py = y * o.h;
      final corps = melange(f.chaude ? _miel : _jaune, o.lampe, 0.1);
      switch (f.plan) {
        case 0:
          // Loin : un point, et un soupçon de halo quand elle s'allume.
          final a = (0.1 + 0.9 * e) * voile;
          lot
            ..poser(Matiere.lueur, px, py, (26 + 14 * f.r) * k, corps, 0.3 * a)
            ..poser(Matiere.point, px, py, (4.5 + 2.5 * f.r) * k, _coeur, a);
        case 1:
          // Milieu : l'air s'éclaire autour, puis le halo, puis le cœur.
          final a = (0.06 + 0.94 * e) * voile;
          lot
            ..poser(Matiere.lueur, px, py, 440 * k, corps, 0.07 * e * voile)
            ..poser(
              Matiere.lueur,
              px,
              py,
              (96 + 64 * f.r) * (0.8 + 0.2 * e) * k,
              corps,
              0.42 * a,
            )
            ..poser(Matiere.lueur, px, py, 30 * k, _coeur, 0.7 * a)
            ..poser(Matiere.point, px, py, (7 + 3 * f.r) * k, _coeur, a);
        default:
          // Tout près : un disque hors mise au point, large et discret.
          lot.poser(
            Matiere.bokeh,
            px,
            py,
            (130 + 120 * f.r) * k,
            melange(_flou, o.lampe, 0.1),
            0.17 * e * voile,
          );
      }
    }
  }
}

class _Luciole {
  _Luciole(int i)
    : plan = const [1, 0, 1, 2, 0, 1, 0][i % 7],
      graine = i * 11,
      x = 0.04 + 0.92 * hasard(i, 1),
      // Plus nombreuses vers le bas, comme au-dessus d'un pré.
      y = 0.97 - 0.74 * math.pow(hasard(i, 2), 1.5),
      r = hasard(i, 3),
      phase = hasard(i, 4) * 40,
      cycles = 17 + (hasard(i, 5) * 14).floor(),
      pasX = 6 + (hasard(i, 6) * 6).floor(),
      pasY = 6 + (hasard(i, 7) * 6).floor(),
      double_ = hasard(i, 8) < 0.24,
      chaude = hasard(i, 9) < 0.22 {
    final portee = const [0.05, 0.1, 0.15][plan];
    ampX = portee * (0.7 + 0.6 * hasard(i, 10));
    ampY = portee * 0.62 * (0.7 + 0.6 * hasard(i, 11));
  }

  final int plan, graine, cycles, pasX, pasY;
  final double x, y, r, phase;
  final bool double_, chaude;
  late final double ampX, ampY;
}
