import 'package:flutter/material.dart';

import 'theme.dart';

/// Pictogrammes des usages, dessinés en vectoriel : nets à toute taille et
/// sans fichier à télécharger. Ce sont des évocations simplifiées des
/// marques, pour reconnaître une tuile d'un coup d'œil depuis le canapé ;
/// les logos officiels pourront être déposés dans assets/logos/ plus tard.
class LogoUsage extends StatelessWidget {
  const LogoUsage({super.key, required this.id, this.hauteur = 72});

  final String id;
  final double hauteur;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: hauteur,
      child: switch (id) {
        'youtube' => AspectRatio(
          aspectRatio: 1.42,
          child: CustomPaint(painter: _Lecture()),
        ),
        'twitch' => AspectRatio(
          aspectRatio: 0.92,
          child: CustomPaint(painter: _Bulle()),
        ),
        'netflix' => AspectRatio(
          aspectRatio: 0.55,
          child: CustomPaint(painter: _RubanN()),
        ),
        'canal' => ConstrainedBox(
          constraints: BoxConstraints(maxWidth: hauteur * 1.6),
          child: FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: Text(
              'CANAL+',
              style: TextStyle(
                fontFamily: Veilleuse.policeEtroite,
                fontWeight: FontWeight.w800,
                fontSize: hauteur,
                height: 1,
                letterSpacing: -1,
                color: Veilleuse.lin,
              ),
            ),
          ),
        ),
        _ => AspectRatio(
          aspectRatio: 1,
          child: FittedBox(
            child: Icon(
              Icons.video_library_rounded,
              color: const Color(0xFF4CC38A),
              size: hauteur,
            ),
          ),
        ),
      },
    );
  }
}

/// Rectangle arrondi rouge et triangle de lecture.
class _Lecture extends CustomPainter {
  @override
  void paint(Canvas canvas, Size t) {
    final fond = RRect.fromRectAndRadius(
      Offset.zero & t,
      Radius.circular(t.height * 0.28),
    );
    canvas.drawRRect(fond, Paint()..color = const Color(0xFFFF0033));
    final c = t.center(Offset.zero);
    final h = t.height * 0.42;
    final triangle = Path()
      ..moveTo(c.dx - h * 0.42, c.dy - h / 2)
      ..lineTo(c.dx + h * 0.58, c.dy)
      ..lineTo(c.dx - h * 0.42, c.dy + h / 2)
      ..close();
    canvas.drawPath(triangle, Paint()..color = Colors.white);
  }

  @override
  bool shouldRepaint(covariant CustomPainter ancien) => false;
}

/// Bulle de discussion violette à coin coupé, deux traits verticaux.
class _Bulle extends CustomPainter {
  @override
  void paint(Canvas canvas, Size t) {
    final w = t.width, h = t.height;
    final bulle = Path()
      ..moveTo(w * 0.12, 0)
      ..lineTo(w, 0)
      ..lineTo(w, h * 0.6)
      ..lineTo(w * 0.72, h * 0.84)
      ..lineTo(w * 0.48, h * 0.84)
      ..lineTo(w * 0.3, h)
      ..lineTo(w * 0.3, h * 0.84)
      ..lineTo(0, h * 0.84)
      ..lineTo(0, h * 0.16)
      ..close();
    canvas.drawPath(bulle, Paint()..color = const Color(0xFF9146FF));
    final trait = Paint()..color = Colors.white;
    for (final x in [0.46, 0.7]) {
      canvas.drawRect(
        Rect.fromLTWH(w * x, h * 0.22, w * 0.09, h * 0.28),
        trait,
      );
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter ancien) => false;
}

/// Un N fait de trois rubans rouges, la diagonale par-dessus.
class _RubanN extends CustomPainter {
  @override
  void paint(Canvas canvas, Size t) {
    final w = t.width, h = t.height, b = w * 0.34;
    final sombre = Paint()..color = const Color(0xFFB1060F);
    canvas.drawRect(Rect.fromLTWH(0, 0, b, h), sombre);
    canvas.drawRect(Rect.fromLTWH(w - b, 0, b, h), sombre);
    final diagonale = Path()
      ..moveTo(0, 0)
      ..lineTo(b, 0)
      ..lineTo(w, h)
      ..lineTo(w - b, h)
      ..close();
    canvas.drawPath(diagonale, Paint()..color = const Color(0xFFE50914));
  }

  @override
  bool shouldRepaint(covariant CustomPainter ancien) => false;
}
