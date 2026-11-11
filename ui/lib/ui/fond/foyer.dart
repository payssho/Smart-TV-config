import 'dart:math' as math;
import 'dart:ui' as ui;

import 'matiere.dart';
import 'rythme.dart';
import 'toile.dart';

/// Coin du feu : le foyer est juste sous l'écran.
///
/// On ne voit pas les flammes (le vrai feu filmé a son propre écran) : on
/// voit ce qu'elles font à la pièce. Une lueur qui vacille, plus vive d'un
/// côté puis de l'autre, le lit de braises au ras du cadre, et des braises
/// qui montent en ralentissant, refroidissent du jaune au rouge et
/// s'éteignent.
abstract final class Foyer {
  static const _clair = 0xFFE7B0;
  static const _vif = 0xFF9A3D;
  static const _sombre = 0xD23E16;

  static final _braises = List.generate(84, _Braise.new);
  static final _etincelles = List.generate(6, (i) => _Braise(i + 200));

  /// Abscisse du foyer, de 0 à 1.
  static const _foyer = 0.4;

  static void lueurs(Toile o) {
    final t = o.t;
    // Vacillement : un souffle lent, des à-coups rapides par-dessus.
    final f = 0.84 + 0.1 * bruit(t * 83, 83, 1) + 0.07 * bruit(t * 211, 211, 2);
    o
      ..nappe(
        ui.Offset(o.l * _foyer, o.h * 1.1),
        o.h * (1.2 + 0.04 * bruit(t * 61, 61, 3)),
        [
          teinte(0xFFB061, 0.6 * f),
          teinte(0xFF7A2E, 0.36 * f),
          teinte(0xC8431A, 0.17 * f),
          teinte(0x7A2410, 0.06 * f),
          teinte(0x6E1D0A, 0),
        ],
        const [0, 0.2, 0.46, 0.76, 1],
      )
      // La lumière du feu danse sur les murs : un côté, puis l'autre.
      ..nappe(
        ui.Offset(o.l * 0.02, o.h * 0.98),
        o.h * 0.9,
        [
          teinte(0xE0541E, 0.17 * (0.75 + 0.5 * bruit(t * 53, 53, 4))),
          teinte(0xE0541E, 0),
        ],
        const [0, 1],
      )
      ..nappe(
        ui.Offset(o.l * 0.9, o.h * 1.02),
        o.h * 0.95,
        [
          teinte(0xE8662A, 0.15 * (0.75 + 0.5 * bruit(t * 41, 41, 5))),
          teinte(0xE8662A, 0),
        ],
        const [0, 1],
      );
    // Le lit de braises, au ras du cadre.
    final bas = ui.Rect.fromLTRB(0, o.h * 0.9, o.l, o.h);
    o.canvas.drawRect(
      bas,
      ui.Paint()
        ..blendMode = ui.BlendMode.plus
        ..shader = ui.Gradient.linear(bas.topCenter, bas.bottomCenter, [
          teinte(0xFFB872, 0),
          teinte(0xFFB872, 0.2 * f),
        ]),
    );
  }

  static void braises(Toile o) {
    final lot = Toile.lumiere;
    final k = o.echelle;
    for (final b in _braises.take(o.combien(84, 44))) {
      final p = _position(b, o.t);
      if (p == null) continue;
      final (x, y, u, vie) = p;
      final scintille =
          0.72 +
          0.28 * bruit(o.t * b.montees * 11 + b.phase, b.montees * 11, b.g);
      final couleur = u < 0.35
          ? melange(_clair, _vif, u / 0.35)
          : melange(_vif, _sombre, (u - 0.35) / 0.5);
      final a = vie * scintille * o.voile(x, y * 0.8);
      final px = x * o.l;
      final py = y * o.h;
      switch (b.plan) {
        case 0:
          lot.poser(
            Matiere.point,
            px,
            py,
            (4 + 3 * b.r) * k,
            couleur,
            0.85 * a,
          );
        case 1:
          lot
            ..poser(Matiere.lueur, px, py, (40 + 26 * b.r) * k, _vif, 0.3 * a)
            ..poser(Matiere.point, px, py, (6.5 + 4 * b.r) * k, couleur, a);
        default:
          lot.poser(
            Matiere.bokeh,
            px,
            py,
            (64 + 84 * b.r) * (1 - 0.25 * u) * k,
            melange(couleur, _vif, 0.5),
            0.2 * a,
          );
      }
    }
    // De rares étincelles filées, plus rapides, orientées dans leur course.
    const pas = 0.00012;
    for (final e in _etincelles.take(o.combien(6, 4))) {
      final p = _position(e, o.t, vive: true);
      final q = _position(e, o.t - pas, vive: true);
      if (p == null || q == null) continue;
      final (x, y, u, vie) = p;
      final dx = (x - q.$1) * o.l;
      final dy = (y - q.$2) * o.h;
      if (dy >= 0) continue;
      lot.poser(
        Matiere.trait,
        x * o.l,
        y * o.h,
        (40 + 50 * e.r) * (1 - 0.6 * u) * k,
        melange(_clair, _vif, u * 1.6),
        0.8 * vie * o.voile(x, y * 0.8),
        math.atan2(dy, dx) - math.pi / 2,
      );
    }
  }

  /// Où en est la braise : abscisse, ordonnée, avancement de sa montée et
  /// éclat. Nul si elle est éteinte.
  static (double, double, double, double)? _position(
    _Braise b,
    double t, {
    bool vive = false,
  }) {
    final montees = vive ? b.montees * 3 : b.montees;
    final cycle = t * montees + b.phase;
    final u = cycle - cycle.floorToDouble();
    final vie = lisse(0, 0.05, u) * math.pow(1 - lisse(0.5, 1, u), 1.5);
    if (vie < 0.01) return null;
    // Chaque montée part d'un endroit différent du foyer.
    final n = cycle.floor() % montees + b.g * 7;
    final depart =
        _foyer +
        0.46 * (hasard(n, 1) + hasard(n, 2) + hasard(n, 3) - 1.5) / 1.5;
    final hauteur =
        (vive ? 0.6 : 0.2) + 0.62 * hasard(n, 4) * hasard(n, 6) + 0.22 * b.plan;
    // L'air chaud porte vite, puis la braise ralentit.
    final montee = 1 - math.pow(1 - u, vive ? 1.6 : 2.3);
    final remous =
        (0.2 + u) * 0.045 * bruit(cycle * 3 + b.r * 9, montees * 3, b.g + 1);
    final x = depart + (0.05 + 0.06 * (hasard(n, 5) - 0.5)) * montee + remous;
    final y = 1.03 - hauteur * montee;
    return (x, y, u, vie);
  }
}

class _Braise {
  _Braise(int i)
    : plan = const [0, 1, 0, 0, 1, 0, 2][i % 7],
      g = i * 13,
      r = hasard(i, 21),
      phase = hasard(i, 22) * 40,
      montees = 7 + (hasard(i, 23) * 9).floor();

  final int plan, g, montees;
  final double r, phase;
}
