import 'dart:math' as math;
import 'dart:typed_data';
import 'dart:ui' as ui;

/// Un motif de lumière dans la planche [Matiere.planche].
class Lutin {
  const Lutin(this.x, this.y, this.largeur, this.hauteur);

  final double x, y, largeur, hauteur;
}

/// La matière des fonds : quelques motifs de lumière dessinés une seule fois,
/// puis posés par centaines en un seul appel de dessin.
///
/// Aucun flou n'est calculé pendant l'animation : le flou d'un halo ou d'un
/// disque hors mise au point est déjà dans le motif. C'est ce qui garde le
/// fond léger pour le petit processeur graphique de la box (ADR 0021).
abstract final class Matiere {
  /// Halo doux, qui s'éteint sans bord.
  static const lueur = Lutin(4, 4, 128, 128);

  /// Disque hors mise au point : plat, avec un liseré un peu plus clair,
  /// comme une lumière floue dans un objectif.
  static const bokeh = Lutin(140, 4, 160, 160);

  /// Filet de pluie ou étincelle filée : la tête est en bas.
  static const trait = Lutin(308, 4, 12, 192);

  /// Point net, au bord adouci.
  static const point = Lutin(328, 4, 48, 48);

  /// Goutte posée sur une vitre.
  static const goutte = Lutin(328, 60, 64, 64);

  static const _largeur = 400;
  static const _hauteur = 204;
  static const _blanc = 0xFFFFFF;

  static ui.Image? _planche;
  static ui.Image? _grain;

  /// La planche des motifs, cuite au premier usage.
  static ui.Image get planche => _planche ??= _cuirePlanche();

  /// Un carreau de grain très fin, à répéter sur tout l'écran : il casse les
  /// marches que les dégradés sombres laissent sur une dalle de télé.
  static ui.Image get grain => _grain ??= _cuireGrain();

  static ui.Color _b(double alpha) => ui.Color.fromARGB(
    (alpha.clamp(0.0, 1.0) * 255).round(),
    _blanc >> 16,
    (_blanc >> 8) & 0xFF,
    _blanc & 0xFF,
  );

  static ui.Image _cuirePlanche() {
    final enregistreur = ui.PictureRecorder();
    final c = ui.Canvas(enregistreur);
    _radial(c, lueur, (s) => math.exp(-4.4 * s * s) * (1 - _marche(0.6, 1, s)));
    _radial(c, point, (s) => math.pow(1 - _marche(0.3, 1, s), 1.6).toDouble());
    _radial(c, bokeh, (s) {
      if (s > 0.93) return 0.62 * (1 - _marche(0.93, 1, s));
      final plat = 0.5 + 0.08 * s * s;
      final lisere = 0.13 * math.exp(-math.pow((s - 0.86) / 0.05, 2));
      return plat + lisere;
    }, pas: 48);
    _cuireTrait(c);
    _cuireGoutte(c);
    final image = enregistreur.endRecording().toImageSync(_largeur, _hauteur);
    return image;
  }

  static double _marche(double a, double b, double x) {
    final u = ((x - a) / (b - a)).clamp(0.0, 1.0);
    return u * u * (3 - 2 * u);
  }

  /// Dessine un motif rond dont l'opacité suit [profil] du centre au bord.
  static void _radial(
    ui.Canvas c,
    Lutin l,
    double Function(double) profil, {
    int pas = 24,
  }) {
    final centre = ui.Offset(l.x + l.largeur / 2, l.y + l.hauteur / 2);
    final rayon = l.largeur / 2;
    c.drawCircle(
      centre,
      rayon,
      ui.Paint()
        ..shader = ui.Gradient.radial(
          centre,
          rayon,
          [for (var i = 0; i <= pas; i++) _b(profil(i / pas))],
          [for (var i = 0; i <= pas; i++) i / pas],
        ),
    );
  }

  static void _cuireTrait(ui.Canvas c) {
    final r = ui.Rect.fromLTWH(trait.x, trait.y, trait.largeur, trait.hauteur);
    c.saveLayer(r, ui.Paint());
    // Sur la longueur : une traîne qui naît de rien, une tête franche.
    c.drawRect(
      r,
      ui.Paint()
        ..shader = ui.Gradient.linear(
          r.topCenter,
          r.bottomCenter,
          [_b(0), _b(0.12), _b(0.55), _b(1), _b(1), _b(0)],
          [0, 0.3, 0.7, 0.93, 0.975, 1],
        ),
    );
    // Sur la largeur : un cœur fin, des bords fondus.
    c.drawRect(
      r,
      ui.Paint()
        ..blendMode = ui.BlendMode.dstIn
        ..shader = ui.Gradient.linear(
          r.centerLeft,
          r.centerRight,
          [_b(0), _b(0.1), _b(0.6), _b(1), _b(0.6), _b(0.1), _b(0)],
          [0, 0.25, 0.4, 0.5, 0.6, 0.75, 1],
        ),
    );
    c.restore();
  }

  static void _cuireGoutte(ui.Canvas c) {
    final centre = ui.Offset(
      goutte.x + goutte.largeur / 2,
      goutte.y + goutte.hauteur / 2,
    );
    const rayon = 25.0;
    const ombre = ui.Color(0xFF05080F);
    // Le corps : presque transparent, cerné d'ombre comme une lentille.
    c.drawCircle(
      centre,
      rayon,
      ui.Paint()
        ..shader = ui.Gradient.radial(
          centre.translate(0, -3),
          rayon + 3,
          [
            _b(0.03),
            const ui.Color(0x1AC8D8F4),
            ombre.withValues(alpha: 0.42),
            ombre.withValues(alpha: 0.5),
            ombre.withValues(alpha: 0),
          ],
          [0, 0.5, 0.82, 0.9, 1],
        ),
    );
    // Une goutte renverse ce qu'elle voit : les lumières de la rue, basses,
    // s'y retrouvent en haut, en croissant.
    final croissant = ui.Path.combine(
      ui.PathOperation.difference,
      ui.Path()
        ..addOval(ui.Rect.fromCircle(center: centre, radius: rayon * 0.8)),
      ui.Path()..addOval(
        ui.Rect.fromCircle(
          center: centre.translate(0, rayon * 0.34),
          radius: rayon * 0.9,
        ),
      ),
    );
    c.drawPath(
      croissant,
      ui.Paint()
        ..color = _b(0.62)
        ..maskFilter = const ui.MaskFilter.blur(ui.BlurStyle.normal, 1.6),
    );
    // Le reflet de la lampe de la pièce, en bas.
    c.drawCircle(
      centre.translate(-rayon * 0.28, rayon * 0.44),
      2.4,
      ui.Paint()
        ..color = _b(0.5)
        ..maskFilter = const ui.MaskFilter.blur(ui.BlurStyle.normal, 1.2),
    );
  }

  /// Côté du carreau de grain.
  static const coteGrain = 128;

  static ui.Image _cuireGrain() {
    final h = math.Random(1320);
    // Des points blancs à peine visibles, de 1 à 4 niveaux sur 255 : assez
    // pour tramer un dégradé, trop peu pour se voir comme une texture.
    final niveaux = List.generate(4, (_) => <double>[]);
    for (var y = 0; y < coteGrain; y++) {
      for (var x = 0; x < coteGrain; x++) {
        final v = h.nextDouble();
        final n = v < 0.35
            ? -1
            : v < 0.65
            ? 0
            : v < 0.85
            ? 1
            : v < 0.95
            ? 2
            : 3;
        if (n >= 0) niveaux[n].addAll([x + 0.5, y + 0.5]);
      }
    }
    final enregistreur = ui.PictureRecorder();
    final c = ui.Canvas(enregistreur);
    for (final (n, points) in niveaux.indexed) {
      c.drawRawPoints(
        ui.PointMode.points,
        Float32List.fromList(points),
        ui.Paint()
          ..color = ui.Color.fromARGB(n + 1, 255, 255, 255)
          ..strokeWidth = 1
          ..isAntiAlias = false,
      );
    }
    return enregistreur.endRecording().toImageSync(coteGrain, coteGrain);
  }
}

/// Un lot de motifs à poser d'un seul appel de dessin.
class Lot {
  Lot(this.capacite)
    : _poses = Float32List(capacite * 4),
      _cadres = Float32List(capacite * 4),
      _teintes = Int32List(capacite);

  final int capacite;
  final Float32List _poses;
  final Float32List _cadres;
  final Int32List _teintes;
  final _pinceau = ui.Paint()..filterQuality = ui.FilterQuality.low;
  int _n = 0;

  int get nombre => _n;

  /// Pose le motif [l] centré en ([x], [y]), haut de [taille] pixels, teinté
  /// de la couleur 0xRRVVBB [teinte] à l'opacité [alpha].
  void poser(
    Lutin l,
    double x,
    double y,
    double taille,
    int teinte,
    double alpha, [
    double angle = 0,
  ]) {
    final a = (alpha.clamp(0.0, 1.0) * 255).round();
    if (a == 0 || _n == capacite) return;
    final echelle = taille / l.hauteur;
    final cos = angle == 0 ? echelle : echelle * math.cos(angle);
    final sin = angle == 0 ? 0.0 : echelle * math.sin(angle);
    final ax = l.largeur / 2;
    final ay = l.hauteur / 2;
    final i = _n * 4;
    _poses[i] = cos;
    _poses[i + 1] = sin;
    _poses[i + 2] = x - cos * ax + sin * ay;
    _poses[i + 3] = y - sin * ax - cos * ay;
    _cadres[i] = l.x;
    _cadres[i + 1] = l.y;
    _cadres[i + 2] = l.x + l.largeur;
    _cadres[i + 3] = l.y + l.hauteur;
    _teintes[_n] = (a << 24) | teinte;
    _n++;
  }

  /// Dessine le lot puis le vide. [fusion] vaut `plus` pour de la lumière
  /// qui s'additionne, `srcOver` pour de la matière posée par-dessus.
  void peindre(ui.Canvas canvas, ui.BlendMode fusion) {
    if (_n == 0) return;
    canvas.drawRawAtlas(
      Matiere.planche,
      Float32List.sublistView(_poses, 0, _n * 4),
      Float32List.sublistView(_cadres, 0, _n * 4),
      Int32List.sublistView(_teintes, 0, _n),
      ui.BlendMode.modulate,
      null,
      _pinceau..blendMode = fusion,
    );
    _n = 0;
  }
}
