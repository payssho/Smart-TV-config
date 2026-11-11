import 'dart:math' as math;
import 'dart:ui' as ui;

import 'matiere.dart';
import 'rythme.dart';
import 'toile.dart';

/// Pluie : la nuit vue de l'intérieur, derrière une vitre.
///
/// Dehors, les lumières de la rue, hors mise au point. Entre elles et nous,
/// la pluie sur trois plans, poussée par un vent léger. Sur la vitre, des
/// gouttes posées ; de temps en temps l'une d'elles grossit, puis glisse par
/// à-coups en laissant un sillage.
abstract final class Pluie {
  static const _eau = 0xBFD0EE;

  /// Lumières de la rue : sodium et tungstène surtout, un peu de froid.
  static const _rue = [
    0xFFB260, 0xFFD6A0, 0x9EC2FF, 0xFFB260, 0x9EC2FF, 0xFFD6A0, //
    0xFFB260, 0x74D8C8, 0x9EC2FF, 0xFF6A5A, 0xFFB260, 0xFFD6A0,
  ];

  static void lumieres(Toile o) {
    final lot = Toile.lumiere;
    final n = o.combien(22, 14);
    for (var i = 0; i < n; i++) {
      final x = hasard(i, 31);
      // Regroupées en bandeau, comme une rue au loin.
      final y =
          0.6 + 0.2 * (hasard(i, 32) + hasard(i, 33) + hasard(i, 34) - 1.5);
      final r = hasard(i, 35);
      // La pluie qui passe devant les fait trembler.
      final tremble = 0.82 + 0.18 * bruit(o.t * 47 + i, 47, i);
      lot.poser(
        Matiere.bokeh,
        x * o.l,
        y * o.h,
        (70 + 170 * r * r) * o.echelle,
        _rue[i % _rue.length],
        (0.19 - 0.08 * r) * tremble * o.voile(x, y),
      );
    }
  }

  static void averse(Toile o) {
    final lot = Toile.lumiere;
    final k = o.echelle;
    // Le vent : une inclinaison qui respire.
    final pente = 0.1 + 0.03 * bruit(o.t * 9, 9, 6);
    final angle = -math.atan(pente);
    final n = o.combien(130, 84);
    for (var i = 0; i < n; i++) {
      final plan = const [0, 0, 1, 0, 1, 0, 0, 1, 0, 2][i % 10];
      final r = hasard(i, 41);
      // Nombre entier de passages par boucle : plus près, plus vite.
      final passages = const [58, 88, 150][plan] + (r * 24).floor();
      final cycle = o.t * passages + hasard(i, 42) * 9;
      final u = cycle - cycle.floorToDouble();
      // Chaque passage tombe ailleurs.
      final colonne = hasard(cycle.floor() % passages + i * 37, 43);
      final longueur = const [50.0, 96.0, 200.0][plan] * (0.8 + 0.4 * r) * k;
      final y = -longueur + u * (o.h + 2 * longueur);
      final x = (colonne * 1.16 - 0.14) * o.l + pente * y;
      lot.poser(
        Matiere.trait,
        x,
        y,
        longueur,
        _eau,
        const [0.15, 0.2, 0.11][plan] * (0.6 + 0.4 * r),
        angle,
      );
    }
  }

  static void vitre(Toile o) {
    final k = o.echelle;
    final relief = Toile.relief;
    // Gouttes posées : elles apparaissent, restent, puis s'effacent.
    final n = o.miniature ? 3 : o.combien(30, 20);
    for (var i = 0; i < n; i++) {
      final vies = 1 + i % 3;
      final cycle = o.t * vies + hasard(i, 51);
      final u = cycle - cycle.floorToDouble();
      final m = cycle.floor() % vies + i * 19;
      final x = hasard(m, 52);
      final y = hasard(m, 53);
      final presence = lisse(0, 0.06, u) * (1 - lisse(0.8, 0.9, u));
      relief.poser(
        Matiere.goutte,
        x * o.l,
        y * o.h,
        (9 + 15 * math.pow(hasard(m, 54), 2)) *
            (0.7 + 0.3 * lisse(0, 0.5, u)) *
            k,
        0xFFFFFF,
        0.72 * presence,
      );
    }
    // Gouttes qui glissent : elles gonflent, puis descendent par à-coups.
    final sillage = ui.Paint()..strokeCap = ui.StrokeCap.round;
    final coureuses = o.combien(5, 3);
    for (var i = 0; i < coureuses; i++) {
      final courses = 2 + i % 3;
      final cycle = o.t * courses + hasard(i, 61);
      final u = cycle - cycle.floorToDouble();
      final m = cycle.floor() % courses + i * 23;
      const attente = 0.42;
      final presence = lisse(0, 0.08, u) * (1 - lisse(0.92, 1, u));
      if (presence < 0.01) continue;
      final x0 = (0.06 + 0.88 * hasard(m, 62)) * o.l;
      final y0 = (0.04 + 0.4 * hasard(m, 63)) * o.h;
      final course = (0.34 + 0.3 * hasard(m, 64)) * o.h;
      // Trois ou quatre glissades séparées par des arrêts.
      final s = ((u - attente) / (1 - attente)).clamp(0.0, 1.0);
      final etapes = 3 + m % 2;
      final e = s * etapes;
      final avance = (e.floor() + lisse(0.3, 1, e - e.floor())) / etapes;
      final y = y0 + avance * course;
      final x = x0 + 5 * k * bruit(avance * 6 + i, 6, i + 70);
      final taille =
          (24 + 8 * hasard(m, 65)) * (0.55 + 0.45 * lisse(0, attente, u)) * k;
      if (avance > 0) {
        sillage
          ..strokeWidth = taille * 0.34
          ..shader = ui.Gradient.linear(ui.Offset(x0, y0), ui.Offset(x0, y), [
            teinte(_eau, 0),
            teinte(_eau, 0.1 * presence),
          ]);
        o.canvas.drawLine(ui.Offset(x0, y0), ui.Offset(x, y), sillage);
      }
      relief.poser(Matiere.goutte, x, y, taille, 0xFFFFFF, presence);
    }
  }
}
