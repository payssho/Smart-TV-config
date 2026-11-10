import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../donnees/etat_os.dart';
import 'theme.dart';

/// Fond de l'OS : la pièce dans la pénombre.
///
/// La lueur reprend la couleur réelle des lumières de la maison (le halo,
/// seul accent fort de l'identité « veilleuse », ADR 0013). Par-dessus, selon
/// l'ambiance choisie : des lucioles, des braises, ou rien. Les mouvements
/// sont lents et bouclent sans couture sur deux minutes. En profil 2 Go le
/// fond est allégé ; il se fige si l'utilisateur a demandé de réduire les
/// animations.
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

  /// Vrai en profil 2 Go : moins de particules.
  final bool allege;

  /// De 0 (lumières éteintes) à 1.
  final double intensite;

  @override
  State<Fond> createState() => _FondState();
}

class _FondState extends State<Fond> with SingleTickerProviderStateMixin {
  late final AnimationController _temps = AnimationController(
    vsync: this,
    duration: const Duration(minutes: 2),
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
        duration: const Duration(milliseconds: 1200),
        curve: Curves.easeOutCubic,
        builder: (context, couleur, _) => TweenAnimationBuilder<double>(
          tween: Tween(end: widget.intensite),
          duration: const Duration(milliseconds: 1200),
          builder: (context, intensite, _) => CustomPaint(
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
    );
  }
}

/// Peintre du fond, exposé pour les tests.
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

  static const _tour = 2 * math.pi;

  /// Couleur des lucioles : vert-jaune chaud, tiré vers la lumière de la pièce.
  static const _luciole = Color(0xFFE6F08A);

  static final List<_Particule> _lucioles = _semer(7, 42);
  static final List<_Particule> _braises = _semer(11, 60);

  static List<_Particule> _semer(int graine, int nombre) {
    final h = math.Random(graine);
    return List.generate(nombre, (_) {
      return _Particule(
        x: h.nextDouble(),
        y: h.nextDouble(),
        profondeur: h.nextDouble(),
        // Nombres entiers de cycles par boucle : aucune saute à la reprise.
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
    // Nuit : un dégradé vertical à peine bleuté, plus profond en haut.
    canvas.drawRect(
      ecran,
      Paint()
        ..shader = const LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color(0xFF0E111A), Veilleuse.nuit, Color(0xFF161A24)],
        ).createShader(ecran),
    );
    _lueur(canvas, taille, t);
    switch (type) {
      case FondOS.lucioles:
        _collines(canvas, taille);
        _dessinerLucioles(canvas, taille, t);
      case FondOS.braises:
        _dessinerBraises(canvas, taille, t);
      case FondOS.calme:
        break;
    }
    canvas.drawRect(
      ecran,
      Paint()
        ..shader = RadialGradient(
          radius: 1.05,
          colors: [Colors.transparent, Veilleuse.nuit.withValues(alpha: 0.65)],
        ).createShader(ecran),
    );
  }

  /// La lampe hors champ, en haut à droite, qui respire très lentement.
  void _lueur(Canvas canvas, Size taille, double t) {
    final souffle = 0.5 + 0.5 * math.sin(t * _tour * 4);
    final rayon = taille.longestSide * (0.6 + 0.04 * souffle);
    final centre = Offset(taille.width * 0.88, taille.height * -0.1);
    final a = (0.24 + 0.05 * souffle) * intensite;
    canvas.drawRect(
      Offset.zero & taille,
      Paint()
        ..shader = RadialGradient(
          colors: [
            couleur.withValues(alpha: a),
            couleur.withValues(alpha: a * 0.3),
            couleur.withValues(alpha: 0),
          ],
          stops: const [0, 0.45, 1],
        ).createShader(Rect.fromCircle(center: centre, radius: rayon)),
    );
  }

  /// Deux lignes de collines sombres en bas de l'écran : on regarde par la
  /// fenêtre, les lucioles flottent au-dessus de l'herbe.
  void _collines(Canvas canvas, Size taille) {
    void ligne(double base, double amp, double freq, Color c) {
      final p = Path()..moveTo(0, taille.height);
      for (var x = 0.0; x <= taille.width; x += 16) {
        final u = x / taille.width;
        p.lineTo(
          x,
          taille.height * base -
              amp * math.sin(u * _tour * freq + 1.3) -
              amp * 0.4 * math.sin(u * _tour * freq * 2.7),
        );
      }
      p
        ..lineTo(taille.width, taille.height)
        ..close();
      canvas.drawPath(p, Paint()..color = c);
    }

    ligne(0.86, 34, 0.8, const Color(0xFF151A26));
    ligne(0.93, 22, 1.4, const Color(0xFF10131C));
  }

  void _dessinerLucioles(Canvas canvas, Size taille, double t) {
    final teinte = Color.lerp(_luciole, couleur, 0.25)!;
    final pinceau = Paint();
    final liste = _lucioles.take(allege ? 16 : _lucioles.length);
    for (final p in liste) {
      // Trajectoire flâneuse : deux sinusoïdes lentes par axe.
      final x =
          p.x +
          p.ampX * math.sin(t * _tour * p.cyclesX + p.phase) +
          p.ampX * 0.4 * math.sin(t * _tour * p.cyclesY * 2 + p.phase * 1.7);
      final y =
          0.35 +
          p.y * 0.6 +
          p.ampY * math.sin(t * _tour * p.cyclesY + p.phase * 0.6) +
          p.ampY * 0.5 * math.cos(t * _tour * p.cyclesX * 3 + p.phase);
      // Clignement doux : longues pauses, brèves lueurs.
      final onde = math.max(0.0, math.sin(t * _tour * p.cyclesLueur + p.phase));
      final lueur = 0.22 + 0.78 * math.pow(onde, 3).toDouble();
      final proche = 0.55 + 0.45 * p.profondeur;
      final c = Offset(x * taille.width, y * taille.height);
      final rayon = (16 + 34 * proche) * (0.6 + 0.4 * lueur);
      pinceau.shader = RadialGradient(
        colors: [
          teinte.withValues(alpha: 0.8 * lueur * proche),
          teinte.withValues(alpha: 0.2 * lueur * proche),
          teinte.withValues(alpha: 0),
        ],
        stops: const [0, 0.35, 1],
      ).createShader(Rect.fromCircle(center: c, radius: rayon));
      canvas.drawCircle(c, rayon, pinceau);
      pinceau.shader = null;
      pinceau.color = Color.lerp(
        teinte,
        Colors.white,
        0.6,
      )!.withValues(alpha: (0.25 + 0.75 * lueur) * proche);
      canvas.drawCircle(c, 2 + 2 * proche, pinceau);
    }
  }

  void _dessinerBraises(Canvas canvas, Size taille, double t) {
    const braise = Color(0xFFFF8A3D);
    final ecran = Offset.zero & taille;
    // Lueur de foyer, en bas, qui vacille.
    final vacille =
        0.75 +
        0.12 * math.sin(t * _tour * 37) +
        0.08 * math.sin(t * _tour * 61 + 1);
    canvas.drawRect(
      ecran,
      Paint()
        ..shader = RadialGradient(
          center: const Alignment(0, 1.25),
          radius: 0.9,
          colors: [
            braise.withValues(alpha: 0.32 * vacille),
            braise.withValues(alpha: 0),
          ],
        ).createShader(ecran),
    );
    final pinceau = Paint();
    for (final p in _braises.take(allege ? 20 : _braises.length)) {
      // Monte en ondulant puis s'éteint en haut.
      final montee = (p.y + t * p.cyclesY * 2) % 1.0;
      final y = 1.02 - montee * 0.9;
      final x = p.x + p.ampX * math.sin(t * _tour * p.cyclesX * 4 + p.phase);
      final vie = math.sin(montee * math.pi);
      final scintille =
          0.6 + 0.4 * math.sin(t * _tour * p.cyclesLueur * 6 + p.phase);
      pinceau.color = Color.lerp(
        braise,
        const Color(0xFFFFD27A),
        p.profondeur,
      )!.withValues(alpha: 0.8 * vie * scintille);
      canvas.drawCircle(
        Offset(x * taille.width, y * taille.height),
        1.2 + 2.2 * p.profondeur,
        pinceau,
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
