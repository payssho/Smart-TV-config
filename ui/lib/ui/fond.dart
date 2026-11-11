import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../donnees/etat_os.dart';
import 'theme.dart';

/// Fond de l'OS : une pièce sombre et nue, éclairée par la lampe.
///
/// Pas de décor : la profondeur vient de la lumière. La lueur de la lampe
/// reprend la couleur réelle des lumières de la maison (le halo, seul accent
/// fort de l'identité « veilleuse », ADR 0013) et dépose une flaque douce en
/// bas de l'écran. Par-dessus, selon l'ambiance : des lucioles, des braises,
/// la pluie sur la vitre, ou seulement des nappes de lumière. Chaque ambiance
/// a trois plans : loin (net, petit, pâle), milieu, et près de l'œil (grand,
/// flou comme hors mise au point). Les mouvements bouclent sans couture sur
/// deux minutes. En profil 2 Go le fond est allégé ; il se fige si
/// l'utilisateur a demandé de réduire les animations.
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

  /// Vrai en profil 2 Go : moins de particules, pas de flou.
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
class PeintreFond extends CustomPainter {
  PeintreFond({
    required this.couleur,
    required this.intensite,
    required this.temps,
    required this.type,
    this.allege = false,
  }) : super(repaint: temps);

  final Color couleur;
  final double intensite;
  final Animation<double> temps;
  final FondOS type;
  final bool allege;

  /// Durée d'une boucle : tous les mouvements y font un nombre entier de
  /// cycles, la reprise ne se voit pas.
  static const boucle = Duration(minutes: 2);

  static const _tour = 2 * math.pi;

  /// Échelle de l'écran dessiné par rapport au 1080p.
  double _k = 1;

  static const _luciole = Color(0xFFE9F59A);
  static const _braise = Color(0xFFFF8A3D);
  static const _pluie = Color(0xFFB9C8E6);

  static final _lucioles = _semer(7, 46);
  static final _braises = _semer(11, 64);
  static final _gouttes = _semer(23, 150);
  static final _reflets = _semer(31, 18);

  static List<_Particule> _semer(int graine, int nombre) {
    final h = math.Random(graine);
    return List.generate(nombre, (_) {
      return _Particule(
        x: h.nextDouble(),
        y: h.nextDouble(),
        profondeur: h.nextDouble(),
        cyclesX: 1 + h.nextInt(3),
        cyclesY: 1 + h.nextInt(3),
        cyclesLueur: 3 + h.nextInt(6),
        phase: h.nextDouble() * _tour,
        ampX: 0.02 + h.nextDouble() * 0.06,
        ampY: 0.015 + h.nextDouble() * 0.04,
      );
    });
  }

  @override
  void paint(Canvas canvas, Size taille) {
    final t = temps.value;
    final ecran = Offset.zero & taille;
    // Les tailles sont pensées pour un écran 1080p ; les aperçus réduisent.
    _k = taille.width / Veilleuse.largeurEcran;
    _piece(canvas, ecran);
    _lampe(canvas, taille, t);
    switch (type) {
      case FondOS.lucioles:
        _dessinerLucioles(canvas, taille, t);
      case FondOS.braises:
        _dessinerBraises(canvas, taille, t);
      case FondOS.pluie:
        _dessinerPluie(canvas, taille, t);
      case FondOS.calme:
        _dessinerNappes(canvas, taille, t);
    }
    // Vignette : les bords retombent dans la nuit, le regard reste au centre.
    canvas.drawRect(
      ecran,
      Paint()
        ..shader = RadialGradient(
          center: const Alignment(0.1, -0.1),
          radius: 1.0,
          colors: [Colors.transparent, Veilleuse.nuit.withValues(alpha: 0.8)],
          stops: const [0.5, 1],
        ).createShader(ecran),
    );
  }

  /// La pièce vide : un mur à peine plus clair au centre, un sol plus sombre.
  void _piece(Canvas canvas, Rect ecran) {
    final froid = type == FondOS.pluie;
    canvas.drawRect(
      ecran,
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: froid
              ? const [Color(0xFF0C1019), Color(0xFF111725), Color(0xFF0A0D15)]
              : const [Color(0xFF0D1018), Veilleuse.nuit, Color(0xFF0B0E16)],
          stops: const [0, 0.62, 1],
        ).createShader(ecran),
    );
  }

  /// La lampe hors champ, en haut à droite, qui respire très lentement, et
  /// la flaque de lumière qu'elle pose en bas.
  void _lampe(Canvas canvas, Size taille, double t) {
    final souffle = 0.5 + 0.5 * math.sin(t * _tour * 4);
    final ecran = Offset.zero & taille;
    final a = (0.26 + 0.05 * souffle) * intensite;
    final centre = Offset(taille.width * 0.86, taille.height * -0.12);
    final rayon = taille.longestSide * (0.62 + 0.03 * souffle);
    canvas.drawRect(
      ecran,
      Paint()
        ..shader = RadialGradient(
          colors: [
            couleur.withValues(alpha: a),
            couleur.withValues(alpha: a * 0.32),
            couleur.withValues(alpha: 0),
          ],
          stops: const [0, 0.42, 1],
        ).createShader(Rect.fromCircle(center: centre, radius: rayon)),
    );
    // Flaque au sol, écrasée en ellipse : donne la profondeur sans décor.
    final flaque = Rect.fromCenter(
      center: Offset(taille.width * 0.62, taille.height * 1.02),
      width: taille.width * 1.1,
      height: taille.height * 0.42,
    );
    canvas.drawOval(
      flaque,
      Paint()
        ..shader = RadialGradient(
          colors: [
            couleur.withValues(alpha: 0.13 * intensite),
            couleur.withValues(alpha: 0),
          ],
        ).createShader(flaque),
    );
  }

  /// Rayon et flou selon le plan : loin = petit et net, près = grand et flou.
  static double _flou(double profondeur) =>
      profondeur > 0.82 ? 6 + 14 * (profondeur - 0.82) / 0.18 : 0;

  void _dessinerLucioles(Canvas canvas, Size taille, double t) {
    final teinte = Color.lerp(_luciole, couleur, 0.2)!;
    final halo = Paint()..blendMode = BlendMode.plus;
    final coeur = Paint()..blendMode = BlendMode.plus;
    final liste = _lucioles.take(allege ? 18 : _lucioles.length);
    for (final p in liste) {
      // Trajectoire flâneuse : deux sinusoïdes lentes par axe.
      final x =
          p.x +
          p.ampX * math.sin(t * _tour * p.cyclesX + p.phase) +
          p.ampX * 0.4 * math.sin(t * _tour * p.cyclesY * 2 + p.phase * 1.7);
      final y =
          0.12 +
          p.y * 0.82 +
          p.ampY * math.sin(t * _tour * p.cyclesY + p.phase * 0.6) +
          p.ampY * 0.5 * math.cos(t * _tour * p.cyclesX * 3 + p.phase);
      // Clignement doux : longues pauses, brèves lueurs.
      final onde = math.max(0.0, math.sin(t * _tour * p.cyclesLueur + p.phase));
      final lueur = 0.18 + 0.82 * math.pow(onde, 3).toDouble();
      final d = p.profondeur;
      final c = Offset(x * taille.width, y * taille.height);
      final flou = allege ? 0.0 : _flou(d);
      if (flou > 0) {
        // Près de l'œil : un disque de bokeh, large et doux.
        coeur
          ..maskFilter = MaskFilter.blur(BlurStyle.normal, flou * _k)
          ..color = teinte.withValues(alpha: 0.5 * lueur);
        canvas.drawCircle(c, (16 + 26 * d) * _k, coeur);
        continue;
      }
      final presence = 0.45 + 0.55 * d;
      final rayon = (26 + 64 * d) * (0.65 + 0.35 * lueur) * _k;
      halo.shader = RadialGradient(
        colors: [
          teinte.withValues(alpha: 0.75 * lueur * presence),
          teinte.withValues(alpha: 0.18 * lueur * presence),
          teinte.withValues(alpha: 0),
        ],
        stops: const [0, 0.3, 1],
      ).createShader(Rect.fromCircle(center: c, radius: rayon));
      canvas.drawCircle(c, rayon, halo);
      coeur
        ..maskFilter = null
        ..color = Color.lerp(
          teinte,
          Colors.white,
          0.65,
        )!.withValues(alpha: (0.2 + 0.8 * lueur) * presence);
      canvas.drawCircle(c, (1.6 + 3 * d) * _k, coeur);
    }
  }

  void _dessinerBraises(Canvas canvas, Size taille, double t) {
    final ecran = Offset.zero & taille;
    // Foyer hors champ, en bas : une lueur qui vacille.
    final vacille =
        0.78 +
        0.1 * math.sin(t * _tour * 37) +
        0.07 * math.sin(t * _tour * 61 + 1) +
        0.05 * math.sin(t * _tour * 97 + 2);
    canvas.drawRect(
      ecran,
      Paint()
        ..shader = RadialGradient(
          center: const Alignment(-0.1, 1.35),
          radius: 1.0,
          colors: [
            _braise.withValues(alpha: 0.36 * vacille),
            const Color(0xFF8A2A08).withValues(alpha: 0.12 * vacille),
            _braise.withValues(alpha: 0),
          ],
          stops: const [0, 0.45, 1],
        ).createShader(ecran),
    );
    final pinceau = Paint()..blendMode = BlendMode.plus;
    for (final p in _braises.take(allege ? 22 : _braises.length)) {
      final d = p.profondeur;
      // Monte en ondulant, plus vite au premier plan, puis s'éteint.
      final montee = (p.y + t * (p.cyclesY * 2 + (d * 3).floor())) % 1.0;
      final y = 1.04 - montee * 0.95;
      final x =
          p.x + p.ampX * math.sin(t * _tour * p.cyclesX * 4 + p.phase) * montee;
      final vie = math.sin(montee * math.pi);
      final scintille =
          0.6 + 0.4 * math.sin(t * _tour * p.cyclesLueur * 6 + p.phase);
      final flou = allege ? 0.0 : _flou(d);
      pinceau
        ..maskFilter = flou > 0
            ? MaskFilter.blur(BlurStyle.normal, flou * 0.7 * _k)
            : null
        ..color = Color.lerp(
          _braise,
          const Color(0xFFFFD27A),
          d,
        )!.withValues(alpha: (flou > 0 ? 0.55 : 0.95) * vie * scintille);
      final c = Offset(x * taille.width, y * taille.height);
      canvas.drawCircle(
        c,
        (flou > 0 ? 9 + 12 * d : 1.4 + 2.8 * d) * _k,
        pinceau,
      );
      if (flou == 0 && d > 0.4) {
        // Petit halo chaud autour des braises les plus proches.
        pinceau.color = _braise.withValues(alpha: 0.12 * vie * scintille);
        canvas.drawCircle(c, (10 + 10 * d) * _k, pinceau);
      }
    }
  }

  /// La pluie vue depuis la pièce : des lumières floues dehors, des filets
  /// de pluie sur trois plans, quelques gouttes qui glissent sur la vitre.
  void _dessinerPluie(Canvas canvas, Size taille, double t) {
    final pinceau = Paint()..blendMode = BlendMode.plus;
    // Dehors : des lumières de ville hors mise au point, qui scintillent.
    for (final p in _reflets.take(allege ? 8 : _reflets.length)) {
      final c = Offset(p.x * taille.width, (0.2 + p.y * 0.55) * taille.height);
      final chaud = p.cyclesX == 1;
      final teinte = chaud ? const Color(0xFFFFC27A) : const Color(0xFF8FB4FF);
      final pulse = 0.7 + 0.3 * math.sin(t * _tour * p.cyclesLueur + p.phase);
      final r = (30 + 60 * p.profondeur) * _k;
      pinceau
        ..maskFilter = allege
            ? null
            : MaskFilter.blur(BlurStyle.normal, 18 * _k)
        ..shader = null
        ..color = teinte.withValues(alpha: 0.10 * pulse);
      canvas.drawCircle(c, r, pinceau);
    }
    // Filets de pluie, légèrement inclinés par le vent.
    const inclinaison = 0.12;
    final trait = Paint()
      ..blendMode = BlendMode.plus
      ..strokeCap = StrokeCap.round;
    for (final p in _gouttes.take(allege ? 60 : _gouttes.length)) {
      final d = p.profondeur;
      // Chute rapide : 40 à 110 passages par boucle, un nombre entier.
      final passages = 40 + (d * 70).floor();
      final chute = (p.y + t * passages) % 1.0;
      final longueur = taille.height * (0.025 + 0.07 * d);
      final y = -longueur + chute * (taille.height + longueur * 2);
      final x = p.x * taille.width + inclinaison * y;
      trait
        ..strokeWidth = (0.8 + 1.6 * d) * _k
        ..maskFilter = !allege && d > 0.85
            ? MaskFilter.blur(BlurStyle.normal, 3 * _k)
            : null
        ..color = _pluie.withValues(alpha: 0.08 + 0.22 * d);
      canvas.drawLine(
        Offset(x, y),
        Offset(x + inclinaison * longueur, y + longueur),
        trait,
      );
    }
    // Gouttes sur la vitre : elles glissent lentement, avec un reflet.
    final goutte = Paint();
    for (final p in _reflets.take(allege ? 5 : 12)) {
      final glisse = (p.x + t * p.cyclesY) % 1.0;
      final c = Offset(
        (p.y * 0.9 + 0.05) * taille.width,
        glisse * taille.height * 1.1,
      );
      final r = (5 + 7 * p.profondeur) * _k;
      goutte.shader = RadialGradient(
        center: const Alignment(-0.3, -0.4),
        colors: [
          Colors.white.withValues(alpha: 0.35),
          _pluie.withValues(alpha: 0.12),
          _pluie.withValues(alpha: 0),
        ],
        stops: const [0, 0.5, 1],
      ).createShader(Rect.fromCircle(center: c, radius: r));
      canvas.drawCircle(c, r, goutte);
      // Le sillage laissé au-dessus.
      goutte
        ..shader = null
        ..color = _pluie.withValues(alpha: 0.05);
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromLTWH(c.dx - r * 0.35, c.dy - 140 * _k, r * 0.7, 140 * _k),
          Radius.circular(r),
        ),
        goutte,
      );
    }
  }

  /// Nuit calme : trois nappes de lumière qui dérivent sans bruit.
  void _dessinerNappes(Canvas canvas, Size taille, double t) {
    final nappes = [
      (couleur, 0.30, 0.55, 0.55, 1, 0.0, 0.2),
      (const Color(0xFF5B6FD8), 0.72, 0.35, 0.5, 2, 2.1, 0.14),
      (const Color(0xFFB0607A), 0.5, 0.85, 0.45, 1, 4.2, 0.1),
    ];
    for (final (c, cx, cy, r, cycles, phase, a) in nappes) {
      final centre = Offset(
        taille.width * (cx + 0.08 * math.sin(t * _tour * cycles + phase)),
        taille.height * (cy + 0.06 * math.cos(t * _tour * cycles + phase)),
      );
      final rayon = taille.longestSide * r;
      canvas.drawCircle(
        centre,
        rayon,
        Paint()
          ..shader = RadialGradient(
            colors: [
              c.withValues(alpha: a * (0.4 + 0.6 * intensite)),
              c.withValues(alpha: 0),
            ],
          ).createShader(Rect.fromCircle(center: centre, radius: rayon)),
      );
    }
  }

  @override
  bool shouldRepaint(PeintreFond ancien) =>
      ancien.couleur != couleur ||
      ancien.intensite != intensite ||
      ancien.type != type ||
      ancien.allege != allege ||
      ancien.temps != temps;
}

class _Particule {
  const _Particule({
    required this.x,
    required this.y,
    required this.profondeur,
    required this.cyclesX,
    required this.cyclesY,
    required this.cyclesLueur,
    required this.phase,
    required this.ampX,
    required this.ampY,
  });

  final double x, y, profondeur, phase, ampX, ampY;
  final int cyclesX, cyclesY, cyclesLueur;
}
