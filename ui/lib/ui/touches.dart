import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';

/// Touche « retour » de la télécommande.
class RetourIntent extends Intent {
  const RetourIntent();
}

/// Touche « accueil » : revient sur « Regarder ».
class AccueilIntent extends Intent {
  const AccueilIntent();
}

/// Correspondance des touches de la télécommande (ADR 0009).
///
/// La croix et OK sont déjà gérées par Flutter (flèches = focus directionnel,
/// Entrée / Select = activer). On ajoute seulement « retour », qui arrive sous
/// des noms différents selon la source : CEC (KEY_BACK), infrarouge, clavier
/// de développement (Échap, Retour arrière).
final touchesRetour = <LogicalKeyboardKey>{
  LogicalKeyboardKey.escape,
  LogicalKeyboardKey.goBack,
  LogicalKeyboardKey.browserBack,
  LogicalKeyboardKey.backspace,
};

final touchesAccueil = <LogicalKeyboardKey>{
  LogicalKeyboardKey.home,
  LogicalKeyboardKey.browserHome,
  LogicalKeyboardKey.keyH,
};

final touchesValider = <LogicalKeyboardKey>{
  LogicalKeyboardKey.enter,
  LogicalKeyboardKey.numpadEnter,
  LogicalKeyboardKey.select,
  LogicalKeyboardKey.space,
  LogicalKeyboardKey.gameButtonA,
};

/// Raccourcis de l'app : ceux de Flutter, dont on retire les touches qu'on
/// redéfinit. SingleActivator ne redéfinit pas l'égalité : sans ce tri, Échap
/// resterait lié à DismissIntent, la première entrée trouvée.
Map<ShortcutActivator, Intent> raccourcisTelecommande(
  Map<ShortcutActivator, Intent> parDefaut,
) {
  final redefinies = {
    ...touchesRetour,
    ...touchesAccueil,
    LogicalKeyboardKey.select,
  };
  return {
    for (final MapEntry(:key, :value) in parDefaut.entries)
      if (key is! SingleActivator || !redefinies.contains(key.trigger))
        key: value,
    for (final touche in touchesRetour)
      SingleActivator(touche): const RetourIntent(),
    for (final touche in touchesAccueil)
      SingleActivator(touche): const AccueilIntent(),
    // Sur les télécommandes, OK arrive souvent en « select ».
    const SingleActivator(LogicalKeyboardKey.select): const ActivateIntent(),
  };
}
