import 'dart:ui' as ui;

import 'package:flutter/material.dart';

import '../donnees/etat_os.dart';
import 'fond/foyer.dart';
import 'fond/lucioles.dart';
import 'fond/matiere.dart';
import 'fond/nuit.dart';
import 'fond/pluie.dart';
import 'fond/rythme.dart';
import 'fond/toile.dart';
import 'theme.dart';

/// Fond de l'OS : une pièce sombre et nue, éclairée par la lampe.
///
/// Pas de décor : tout est lumière. La lueur de la lampe reprend la couleur
/// réelle des lumières de la maison (le halo, seul accent fort de l'identité
/// « veilleuse », ADR 0013). Par-dessus, selon l'ambiance : des lucioles, la
/// lueur et les braises d'un foyer, la pluie derrière la vitre, ou une nuit
/// presque immobile (`fond/`). Chaque ambiance a trois plans : loin (net,
/// petit, pâle), milieu, et près de l'œil (grand, flou comme hors mise au
/// point). Les mouvements bouclent sans couture sur deux minutes. En profil
/// 2 Go le fond porte moins de lumières ; il se fige si l'utilisateur a
/// demandé de réduire les animations.
class Fond extends StatefulWidget {
  const Fond({
    super.key,
    required this.couleur,
    this.type = FondOS.lucioles,
    this.allege = false,
    this.intensite = 1,
  });

  final Color couleur;
  final FondOS type;

  /// Vrai en profil 2 Go : moins de lumières à l'écran.
  final bool allege;

  /// De 0 (lumières éteintes) à 1.
  final double intensite;

  @override
  State<Fond> createState() => _FondState();
}

class _FondState extends State<Fond> with SingleTickerProviderStateMixin {
  late final AnimationController _temps = AnimationController(
    vsync: this,
    duration: PeintreFond.boucle,
  );

  @override
  void initState() {
    super.initState();
    final reduit = WidgetsBinding
        .instance
        .platformDispatcher
        .accessibilityFeatures
        .disableAnimations;
    if (reduit) {
      _temps.value = 0.3;
    } else {
      _temps.repeat();
    }
  }

  @override
  void dispose() {
    _temps.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return RepaintBoundary(
      child: TweenAnimationBuilder<Color?>(
        tween: ColorTween(end: widget.couleur),
        duration: Durations.extralong4,
        curve: Easing.standard,
        builder: (context, couleur, _) => TweenAnimationBuilder<double>(
          tween: Tween(end: widget.intensite),
          duration: Durations.extralong4,
          curve: Easing.standard,
          builder: (context, intensite, _) => AnimatedSwitcher(
            duration: Durations.extralong4,
            switchInCurve: Easing.standard,
            child: CustomPaint(
              key: ValueKey(widget.type),
              painter: PeintreFond(
                couleur: couleur ?? widget.couleur,
                intensite: intensite,
                temps: _temps,
                type: widget.type,
                allege: widget.allege,
              ),
              size: Size.infinite,
            ),
          ),
        ),
      ),
    );
  }
}

/// Peintre du fond, exposé pour les tests et les aperçus.
///
/// De l'arrière vers l'avant : le socle (la pièce, cuite une fois en image),
/// la lampe, la scène, puis un grain très fin qui trame les dégradés.
class PeintreFond extends CustomPainter {
  PeintreFond({
    required this.couleur,
    required this.intensite,
    required this.temps,
    required this.type,
    this.allege = false,
    this.miniature = false,
  }) : super(repaint: temps);

  final Color couleur;
  final double intensite;
  final Animation<double> temps;
  final FondOS type;
  final bool allege;

  /// Vrai pour une tuile d'aperçu : la scène est cadrée plus serré, avec
  /// une poignée de lumières, pour rester lisible en petit.
  final bool miniature;

  /// Durée d'une boucle : tous les mouvements y font un nombre entier de
  /// cycles, la reprise ne se voit pas.
  static const boucle = Duration(minutes: 2);

  /// Grossissement des lumières dans une miniature.
  static const _zoomMiniature = 2.6;

  @override
  void paint(Canvas canvas, Size taille) {
    if (taille.isEmpty) return;
    final ecran = Offset.zero & taille;
    final toile = Toile(
      canvas: canvas,
      taille: taille,
      t: temps.value,
      // Les tailles sont pensées pour un écran 1080p.
      echelle:
          taille.width /
          Veilleuse.largeurEcran *
          (miniature ? _zoomMiniature : 1),
      lampe: couleur.toARGB32() & 0xFFFFFF,
      intensite: intensite,
      allege: allege,
      miniature: miniature,
    );
    canvas
      ..save()
      ..clipRect(ecran);
    if (miniature) {
      _Socle.peindre(canvas, ecran, type);
    } else {
      canvas.drawImageRect(
        _Socle.image(type, taille),
        Offset.zero & _Socle.taille(taille),
        ecran,
        Paint()..filterQuality = FilterQuality.low,
      );
    }
    switch (type) {
      case FondOS.lucioles:
        _lampe(toile, force: 1);
        Lucioles.peindre(toile);
      case FondOS.braises:
        _lampe(toile, force: 0.5, flaque: false);
        Foyer.lueurs(toile);
        Foyer.braises(toile);
      case FondOS.pluie:
        Pluie.lumieres(toile);
        _lampe(toile, force: 0.8);
        Pluie.averse(toile);
        Pluie.vitre(toile);
      case FondOS.calme:
        _lampe(toile, force: 0.85);
        Nuit.nappes(toile);
        Nuit.etoiles(toile);
    }
    toile.deposer();
    if (!miniature) {
      canvas.drawRect(
        ecran,
        Paint()
          ..shader = ImageShader(
            Matiere.grain,
            TileMode.repeated,
            TileMode.repeated,
            Matrix4.identity().storage,
          ),
      );
    }
    canvas.restore();
  }

  /// La lampe hors champ, en haut à droite, qui respire très lentement, et
  /// la flaque de lumière qu'elle pose en bas.
  void _lampe(Toile o, {required double force, bool flaque = true}) {
    final souffle = 0.5 + 0.5 * bruit(o.t * 5, 5, 9);
    final a = (0.25 + 0.04 * souffle) * intensite * force;
    o.nappe(
      Offset(o.l * 0.88, o.h * -0.14),
      o.taille.longestSide * (0.64 + 0.02 * souffle),
      [
        teinte(o.lampe, a),
        teinte(o.lampe, a * 0.52),
        teinte(o.lampe, a * 0.17),
        teinte(o.lampe, 0),
      ],
      const [0, 0.28, 0.6, 1],
    );
    if (!flaque) return;
    // Flaque au sol, écrasée en ellipse : donne la profondeur sans décor.
    o.nappe(
      Offset(o.l * 0.62, o.h * 1.04),
      o.l * 0.56,
      [teinte(o.lampe, 0.11 * intensite * force), teinte(o.lampe, 0)],
      const [0, 1],
      ecrasement: 0.34,
    );
  }

  @override
  bool shouldRepaint(PeintreFond ancien) =>
      ancien.couleur != couleur ||
      ancien.intensite != intensite ||
      ancien.type != type ||
      ancien.allege != allege ||
      ancien.miniature != miniature ||
      ancien.temps != temps;
}

/// Le socle d'une ambiance : la pièce vide, sa température, ses bords qui
/// retombent dans la nuit. Rien n'y bouge : il est cuit une fois en image, à
/// demi-définition (ce ne sont que des dégradés), et posé d'un seul geste.
abstract final class _Socle {
  static final _cuits = <(FondOS, int, int), ui.Image>{};

  /// Taille de l'image cuite pour une surface [taille].
  static Size taille(Size taille) => Size(
    (taille.width / 2).ceilToDouble(),
    (taille.height / 2).ceilToDouble(),
  );

  static ui.Image image(FondOS type, Size surface) {
    final t = taille(surface);
    final cle = (type, t.width.toInt(), t.height.toInt());
    final connue = _cuits[cle];
    if (connue != null) return connue;
    // Une surface qui change de taille ne doit pas empiler les images.
    if (_cuits.length >= 8) {
      _cuits.remove(_cuits.keys.first)?.dispose();
    }
    final enregistreur = ui.PictureRecorder();
    peindre(Canvas(enregistreur), Offset.zero & t, type);
    return _cuits[cle] = enregistreur.endRecording().toImageSync(
      cle.$2,
      cle.$3,
    );
  }

  static void peindre(Canvas canvas, Rect ecran, FondOS type) {
    final (haut, milieu, bas) = switch (type) {
      // Une nuit d'été, un soupçon de vert vers le bas.
      FondOS.lucioles => (0xFF0B101C, 0xFF0F1522, 0xFF0D191C),
      // La pièce se réchauffe en descendant vers le foyer.
      FondOS.braises => (0xFF100C11, 0xFF17100F, 0xFF1D120D),
      // Bleu ardoise, froid comme la vitre.
      FondOS.pluie => (0xFF090E17, 0xFF0E1726, 0xFF0B121D),
      FondOS.calme => (0xFF0A0D18, 0xFF0F1320, 0xFF0B0E18),
    };
    canvas.drawRect(
      ecran,
      Paint()
        ..shader = ui.Gradient.linear(
          ecran.topCenter,
          ecran.bottomCenter,
          [Color(haut), Color(milieu), Color(bas)],
          const [0, 0.6, 1],
        ),
    );
    final l = ecran.width;
    final h = ecran.height;
    void halo(double x, double y, double rayon, int rvb, double alpha) {
      final centre = Offset(l * x, h * y);
      canvas.drawRect(
        ecran,
        Paint()
          ..shader = ui.Gradient.radial(centre, l * rayon, [
            teinte(rvb, alpha),
            teinte(rvb, 0),
          ]),
      );
    }

    switch (type) {
      case FondOS.lucioles:
        // Le pré, hors champ : une clarté verte qui monte du bas.
        halo(0.28, 1.2, 0.8, 0x1F5140, 0.3);
      case FondOS.pluie:
        // La rue mouillée, sous la fenêtre.
        halo(0.5, 1.25, 0.85, 0x2B4C80, 0.3);
      case FondOS.braises || FondOS.calme:
        break;
    }
    // Les bords retombent dans la nuit, le regard reste au centre.
    canvas.drawRect(
      ecran,
      Paint()
        ..shader = ui.Gradient.radial(
          Offset(l * 0.5, h * 0.46),
          l * 0.74,
          [const Color(0x00060810), const Color(0x99060810)],
          const [0.48, 1],
        ),
    );
  }
}
