import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../systeme/son.dart';
import '../ui/theme.dart';

/// « Feu de cheminée » : un feu qui crépite en plein écran, avec le son.
/// OK coupe ou remet le son, Retour quitte.
class EcranFeu extends StatefulWidget {
  const EcranFeu({super.key});

  static Route<void> route() => PageRouteBuilder(
    pageBuilder: (_, _, _) => const EcranFeu(),
    transitionDuration: const Duration(milliseconds: 900),
    transitionsBuilder: (_, animation, _, enfant) =>
        FadeTransition(opacity: animation, child: enfant),
  );

  @override
  State<EcranFeu> createState() => _EcranFeuState();
}

class _EcranFeuState extends State<EcranFeu>
    with SingleTickerProviderStateMixin {
  /// Une minute de flammes, en boucle sans couture.
  late final AnimationController _temps = AnimationController(
    vsync: this,
    duration: const Duration(minutes: 1),
  );
  final _son = BoucleSonore('assets/sons/feu.mp3');
  bool _sonActif = true;
  bool _sonBloque = false;
  bool _aideVisible = true;
  Timer? _masquerAide;

  @override
  void initState() {
    super.initState();
    final reduit = WidgetsBinding
        .instance
        .platformDispatcher
        .accessibilityFeatures
        .disableAnimations;
    reduit ? _temps.value = 0.2 : _temps.repeat();
    _lancerSon();
    _masquerAide = Timer(const Duration(seconds: 5), () {
      if (mounted) setState(() => _aideVisible = false);
    });
  }

  Future<void> _lancerSon() async {
    final joue = await _son.jouer();
    if (mounted) setState(() => _sonBloque = !joue);
  }

  void _basculerSon() {
    setState(() {
      _sonActif = !_sonActif;
      _aideVisible = true;
    });
    _sonActif ? _lancerSon() : _son.arreter();
    _masquerAide?.cancel();
    _masquerAide = Timer(const Duration(seconds: 4), () {
      if (mounted) setState(() => _aideVisible = false);
    });
  }

  @override
  void dispose() {
    _masquerAide?.cancel();
    _son.arreter();
    _temps.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final textes = Theme.of(context).textTheme;
    final etatSon = !_son.disponible
        ? 'Le son arrivera avec le lecteur de la phase 4. Retour pour revenir.'
        : !_sonActif
        ? 'Son coupé. OK pour le remettre.'
        : _sonBloque
        ? 'Le navigateur bloque le son : cliquez une fois sur l\'écran.'
        : 'OK coupe le son, Retour revient à l\'accueil.';
    return Scaffold(
      backgroundColor: const Color(0xFF0B0806),
      body: Focus(
        autofocus: true,
        child: Actions(
          actions: {
            ActivateIntent: CallbackAction<ActivateIntent>(
              onInvoke: (_) {
                _basculerSon();
                return null;
              },
            ),
          },
          child: GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: () =>
                _sonBloque && _sonActif ? _lancerSon() : _basculerSon(),
            child: Stack(
              fit: StackFit.expand,
              children: [
                RepaintBoundary(
                  child: CustomPaint(painter: PeintreFeu(temps: _temps)),
                ),
                Positioned(
                  left: Veilleuse.margeSure.left,
                  bottom: Veilleuse.margeSure.bottom,
                  child: AnimatedOpacity(
                    opacity: _aideVisible || (_sonBloque && _son.disponible)
                        ? 1
                        : 0,
                    duration: const Duration(milliseconds: 600),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Feu de cheminée', style: textes.headlineMedium),
                        const SizedBox(height: 8),
                        Text(etatSon, style: textes.bodyLarge),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Peintre du feu : bûches, flammes en trois couches, étincelles et lueur
/// sur les murs. Tout est calculé, aucune image.
class PeintreFeu extends CustomPainter {
  PeintreFeu({required this.temps}) : super(repaint: temps);

  final Animation<double> temps;

  static const _tour = 2 * math.pi;

  /// Fréquence d'un nombre entier de cycles par minute : boucle sans couture.
  static double _onde(double t, int cycles, [double phase = 0]) =>
      math.sin(t * _tour * cycles + phase);

  static final _etincelles = () {
    final h = math.Random(5);
    return List.generate(
      38,
      (_) => (
        x: h.nextDouble() * 2 - 1,
        depart: h.nextDouble(),
        cycles: 8 + h.nextInt(10),
        balancement: 6 + h.nextInt(10),
        phase: h.nextDouble() * _tour,
        taille: 1 + h.nextDouble() * 2.4,
      ),
    );
  }();

  /// Langues de flamme : position, largeur, hauteur, rythme.
  static const _langues = [
    (-0.22, 120.0, 300.0, 47, 0.0),
    (-0.10, 150.0, 420.0, 53, 1.1),
    (0.02, 170.0, 500.0, 59, 2.3),
    (0.13, 150.0, 430.0, 43, 3.7),
    (0.24, 120.0, 320.0, 61, 4.4),
    (-0.04, 110.0, 360.0, 67, 5.2),
    (0.08, 100.0, 340.0, 71, 0.6),
  ];

  @override
  void paint(Canvas canvas, Size taille) {
    final t = temps.value;
    final ecran = Offset.zero & taille;
    final foyer = Offset(taille.width / 2, taille.height * 0.8);
    final vacille =
        0.8 +
        0.1 * _onde(t, 113) +
        0.06 * _onde(t, 197, 1) +
        0.04 * _onde(t, 271, 2);

    // Lueur sur la pièce.
    canvas.drawRect(
      ecran,
      Paint()
        ..shader = RadialGradient(
          center: Alignment(0, foyer.dy / taille.height * 2 - 1),
          radius: 1.0,
          colors: [
            const Color(0xFFFF7A1F).withValues(alpha: 0.38 * vacille),
            const Color(0xFF8A2A08).withValues(alpha: 0.18 * vacille),
            Colors.transparent,
          ],
          stops: const [0, 0.35, 1],
        ).createShader(ecran),
    );

    // Bûches derrière les flammes.
    _buche(canvas, foyer + const Offset(-70, 30), 520, -0.12);
    _buche(canvas, foyer + const Offset(80, 34), 500, 0.14);

    // Flammes : rouge en dehors, orange, cœur presque blanc.
    final couches = [
      (1.0, const Color(0xFFE2421B), 0.75, 18.0),
      (0.72, const Color(0xFFFF9A2E), 0.85, 12.0),
      (0.42, const Color(0xFFFFE7A3), 0.9, 8.0),
    ];
    for (final (echelle, couleur, opacite, flou) in couches) {
      final pinceau = Paint()
        ..color = couleur.withValues(alpha: opacite)
        ..blendMode = BlendMode.plus
        ..maskFilter = MaskFilter.blur(BlurStyle.normal, flou);
      for (final (dx, largeur, hauteur, rythme, phase) in _langues) {
        final h =
            hauteur *
            echelle *
            (0.82 +
                0.12 * _onde(t, rythme, phase) +
                0.06 * _onde(t, rythme * 3, phase));
        final w = largeur * (0.6 + 0.4 * echelle);
        final base = foyer + Offset(dx * taille.width * 0.55, 0);
        final balance =
            26 * _onde(t, rythme ~/ 2 + 7, phase) +
            12 * _onde(t, rythme + 11, phase * 2);
        canvas.drawPath(_langue(base, w, h, balance), pinceau);
      }
    }

    // Bûche de devant et braises au sol.
    _buche(canvas, foyer + const Offset(0, 70), 600, 0.02);
    final braises = Paint()
      ..shader =
          RadialGradient(
            colors: [
              const Color(0xFFFFB347).withValues(alpha: 0.9 * vacille),
              const Color(0xFFB8320C).withValues(alpha: 0.5),
              Colors.transparent,
            ],
          ).createShader(
            Rect.fromCenter(
              center: foyer + const Offset(0, 90),
              width: 760,
              height: 120,
            ),
          );
    canvas.drawOval(
      Rect.fromCenter(
        center: foyer + const Offset(0, 90),
        width: 760,
        height: 120,
      ),
      braises,
    );

    // Étincelles.
    final pinceau = Paint()..blendMode = BlendMode.plus;
    for (final e in _etincelles) {
      final montee = (e.depart + t * e.cycles) % 1.0;
      final y = foyer.dy - 60 - montee * taille.height * 0.7;
      final x =
          foyer.dx +
          e.x * 260 +
          40 * math.sin(t * _tour * e.balancement + e.phase) * montee;
      final vie = math.pow(1 - montee, 1.5).toDouble();
      pinceau.color = const Color(0xFFFFC46B).withValues(alpha: 0.9 * vie);
      canvas.drawCircle(Offset(x, y), e.taille, pinceau);
    }

    // Vignette chaude.
    canvas.drawRect(
      ecran,
      Paint()
        ..shader = RadialGradient(
          radius: 0.95,
          colors: [Colors.transparent, Colors.black.withValues(alpha: 0.7)],
          stops: const [0.55, 1],
        ).createShader(ecran),
    );
  }

  /// Une langue de flamme : large en bas, effilée en haut, la pointe déportée.
  Path _langue(Offset base, double w, double h, double balance) {
    final pointe = base + Offset(balance, -h);
    return Path()
      ..moveTo(base.dx - w / 2, base.dy)
      ..cubicTo(
        base.dx - w * 0.62,
        base.dy - h * 0.35,
        pointe.dx - w * 0.22 - balance * 0.3,
        base.dy - h * 0.62,
        pointe.dx,
        pointe.dy,
      )
      ..cubicTo(
        pointe.dx + w * 0.22 - balance * 0.3,
        base.dy - h * 0.62,
        base.dx + w * 0.62,
        base.dy - h * 0.35,
        base.dx + w / 2,
        base.dy,
      )
      ..close();
  }

  void _buche(Canvas canvas, Offset centre, double longueur, double angle) {
    canvas.save();
    canvas.translate(centre.dx, centre.dy);
    canvas.rotate(angle);
    final r = Rect.fromCenter(center: Offset.zero, width: longueur, height: 74);
    canvas.drawRRect(
      RRect.fromRectAndRadius(r, const Radius.circular(37)),
      Paint()
        ..shader = const LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color(0xFF7A4A2C), Color(0xFF3A2112)],
        ).createShader(r),
    );
    // Braise sur le dessus de la bûche.
    canvas.drawRRect(
      RRect.fromRectAndRadius(r.deflate(4), const Radius.circular(33)),
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 3
        ..color = const Color(0xFFFF6A1A).withValues(alpha: 0.55),
    );
    canvas.restore();
  }

  @override
  bool shouldRepaint(PeintreFeu ancien) => ancien.temps != temps;
}
