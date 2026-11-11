import 'package:material_ui/material_ui.dart';

/// Tokens de l'identité « veilleuse » (ADR 0013), adaptés au « 10 pieds ».
/// Valeurs de la palette « nuit » de `app/lib/ui/theme.dart` dans
/// Home-device-manager, comme la maquette ; à remplacer par un paquet Dart
/// partagé dès qu'il existe.
///
/// Principe : l'écran est une pièce dans la pénombre. La seule couleur forte
/// est le halo, qui reprend la couleur réelle des lumières de la maison ;
/// l'ambre est réservé au focus et aux actions.
abstract final class Veilleuse {
  /// Fond : nuit bleutée, jamais noir pur (évite l'effet « écran éteint »).
  static const nuit = Color(0xFF0F1320);

  /// Surfaces posées sur la nuit (tuiles, panneaux).
  static const ardoise = Color(0xFF181D2B);

  /// Surface d'une tuile qui a le focus.
  static const ardoiseClaire = Color(0xFF232A3B);

  /// Texte principal : lin chaud, lisible à 3 m sans éblouir.
  static const lin = Color(0xFFEEE7DA);

  /// Texte secondaire.
  static const brume = Color(0xFFA2A8B6);

  /// Focus et actions.
  static const ambre = Color(0xFFFFB45E);

  /// Halo par défaut quand aucune lumière n'est connue.
  static const haloParDefaut = Color(0xFFFFB46B);

  static const police = 'Bricolage';
  static const policeEtroite = 'BricolageEtroite';

  /// Surface de référence : on dessine toujours en 1920 × 1080 logiques.
  static const largeurEcran = 1920.0;
  static const hauteurEcran = 1080.0;

  /// Marge de sécurité contre l'overscan des télés (5 %).
  static const margeSure = EdgeInsets.symmetric(horizontal: 96, vertical: 54);

  static const rayonTuile = 22.0;
  static const dureeFocus = Duration(milliseconds: 160);

  static ThemeData theme() {
    const texte = TextTheme(
      displayLarge: TextStyle(
        fontFamily: policeEtroite,
        fontWeight: FontWeight.w800,
        fontSize: 168,
        height: 0.9,
        letterSpacing: -4,
        color: lin,
      ),
      headlineMedium: TextStyle(
        fontWeight: FontWeight.w600,
        fontSize: 52,
        height: 1.1,
        letterSpacing: -1,
        color: lin,
      ),
      titleLarge: TextStyle(
        fontWeight: FontWeight.w600,
        fontSize: 36,
        height: 1.15,
        color: lin,
      ),
      titleMedium: TextStyle(
        fontWeight: FontWeight.w500,
        fontSize: 30,
        height: 1.2,
        color: lin,
      ),
      bodyLarge: TextStyle(
        fontWeight: FontWeight.w400,
        fontSize: 28,
        height: 1.35,
        color: brume,
      ),
      labelLarge: TextStyle(
        fontWeight: FontWeight.w600,
        fontSize: 28,
        color: lin,
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
        secondary: haloParDefaut,
        onSurface: lin,
      ),
      textTheme: texte,
      // Pas de surbrillance au survol ni d'ondulation : rien n'est tactile.
      splashFactory: NoSplash.splashFactory,
      highlightColor: Colors.transparent,
      hoverColor: Colors.transparent,
    );
  }
}
