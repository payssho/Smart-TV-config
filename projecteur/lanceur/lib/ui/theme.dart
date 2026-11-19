import 'package:material_ui/material_ui.dart';

/// Tokens de l'identité « veilleuse » (ADR 0013), repris de `ui/lib/ui/theme.dart`
/// et redimensionnés pour la dalle 1280 × 720 du projecteur (ADR 0025).
///
/// Un projecteur dans le noir éblouit vite : fond nuit bleutée (jamais blanc),
/// texte lin, et l'ambre réservé au focus.
abstract final class Veilleuse {
  static const nuit = Color(0xFF0F1320);
  static const ardoise = Color(0xFF181D2B);
  static const ardoiseClaire = Color(0xFF232A3B);
  static const lin = Color(0xFFEEE7DA);
  static const brume = Color(0xFFA2A8B6);
  static const ambre = Color(0xFFFFB45E);

  static const police = 'Bricolage';
  static const policeEtroite = 'BricolageEtroite';

  /// Surface de référence : la dalle native du projecteur.
  static const largeurEcran = 1280.0;
  static const hauteurEcran = 720.0;

  /// Marge contre le trapèze et les bords flous de l'image projetée (5 %).
  static const margeSure = EdgeInsets.symmetric(horizontal: 64, vertical: 36);

  static const rayonTuile = 16.0;
  static const dureeFocus = Duration(milliseconds: 140);

  static ThemeData theme() {
    const texte = TextTheme(
      displayLarge: TextStyle(
        fontFamily: policeEtroite,
        fontWeight: FontWeight.w800,
        fontSize: 96,
        height: 0.9,
        letterSpacing: -2,
        color: lin,
      ),
      titleLarge: TextStyle(
        fontWeight: FontWeight.w600,
        fontSize: 26,
        height: 1.15,
        color: lin,
      ),
      titleMedium: TextStyle(
        fontWeight: FontWeight.w600,
        fontSize: 20,
        height: 1.2,
        color: lin,
      ),
      bodyLarge: TextStyle(
        fontWeight: FontWeight.w400,
        fontSize: 18,
        height: 1.35,
        color: brume,
      ),
    );
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      fontFamily: police,
      scaffoldBackgroundColor: nuit,
      colorScheme: const ColorScheme.dark(
        surface: nuit,
        primary: ambre,
        onPrimary: nuit,
        onSurface: lin,
      ),
      textTheme: texte,
      // Rien n'est tactile : pas d'ondulation ni de survol.
      splashFactory: NoSplash.splashFactory,
      highlightColor: Colors.transparent,
      hoverColor: Colors.transparent,
    );
  }
}
