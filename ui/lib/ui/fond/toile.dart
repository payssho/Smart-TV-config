import 'dart:ui' as ui;

import 'matiere.dart';
import 'rythme.dart';

/// Ce qu'une scène reçoit pour se peindre : la surface, l'instant, la lampe
/// de la maison, et deux lots de motifs prêts à remplir.
class Toile {
  Toile({
    required this.canvas,
    required this.taille,
    required this.t,
    required this.echelle,
    required this.lampe,
    required this.intensite,
    required this.allege,
    required this.miniature,
  });

  final ui.Canvas canvas;
  final ui.Size taille;

  /// Position dans la boucle, de 0 à 1.
  final double t;

  /// Taille d'un pixel de la maquette 1080p sur cette surface.
  final double echelle;

  /// Couleur 0xRRVVBB des lumières de la maison.
  final int lampe;

  /// De 0 (lumières éteintes) à 1.
  final double intensite;
  final bool allege;
  final bool miniature;

  double get l => taille.width;
  double get h => taille.height;

  /// Lumière qui s'additionne : halos, points, disques flous.
  static final lumiere = Lot(640);

  /// Matière posée par-dessus : les gouttes sur la vitre.
  static final relief = Lot(96);

  /// Nombre d'éléments à dessiner : [plein] sur 4 Go, [leger] sur 2 Go, une
  /// poignée dans une miniature.
  int combien(int plein, int leger) =>
      miniature ? (leger * 0.42).round() : (allege ? leger : plein);

  /// Les bords retombent dans la nuit : facteur d'opacité, de 1 au centre à
  /// 0,5 dans les coins, pour une lumière posée en ([x], [y]) de 0 à 1.
  double voile(double x, double y) {
    final dx = (x - 0.5) * 1.15;
    final dy = (y - 0.46) * 1.3;
    return 1 - 0.5 * lisse(0.42, 0.86, (dx * dx + dy * dy) * 1.6);
  }

  /// Dessine les lots en attente : d'abord la lumière, puis le relief.
  void deposer() {
    lumiere.peindre(canvas, ui.BlendMode.plus);
    relief.peindre(canvas, ui.BlendMode.srcOver);
  }

  /// Une nappe ronde de lumière additive, dégradée du centre au bord.
  void nappe(
    ui.Offset centre,
    double rayon,
    List<ui.Color> couleurs,
    List<double> arrets, {
    double ecrasement = 1,
  }) {
    final pinceau = ui.Paint()..blendMode = ui.BlendMode.plus;
    if (ecrasement == 1) {
      pinceau.shader = ui.Gradient.radial(centre, rayon, couleurs, arrets);
      canvas.drawRect(ui.Offset.zero & taille, pinceau);
      return;
    }
    // Écrasée en ellipse : une flaque de lumière vue de biais.
    pinceau.shader = ui.Gradient.radial(
      ui.Offset.zero,
      rayon,
      couleurs,
      arrets,
    );
    canvas
      ..save()
      ..translate(centre.dx, centre.dy)
      ..scale(1, ecrasement)
      ..drawCircle(ui.Offset.zero, rayon, pinceau)
      ..restore();
  }
}

/// Couleur 0xRRVVBB à l'opacité [alpha].
ui.Color teinte(int rvb, double alpha) => ui.Color.fromARGB(
  (alpha.clamp(0.0, 1.0) * 255).round(),
  rvb >> 16,
  (rvb >> 8) & 0xFF,
  rvb & 0xFF,
);
