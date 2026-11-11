import 'package:flutter/widgets.dart';

import '../ui/touches.dart';

FocusNode? _dernierFocus;
bool _suivi = false;

/// Retient le dernier élément qui a eu le focus. Dans le navigateur, Flutter
/// perd le focus dès qu'on clique hors de l'app (sur la télécommande de la
/// page) : on le rend avant de rejouer la touche.
void suivreFocus() {
  if (_suivi) return;
  _suivi = true;
  FocusManager.instance.addListener(() {
    final f = FocusManager.instance.primaryFocus;
    if (f != null && f.context != null && f is! FocusScopeNode) {
      _dernierFocus = f;
    }
  });
}

/// Touche reçue d'une télécommande extérieure à l'app (la télécommande à
/// l'écran de la prévisualisation web). Rejoue ce que ferait la vraie touche.
void appuyer(String touche) {
  var focus = FocusManager.instance.primaryFocus;
  final dernier = _dernierFocus;
  final perdu =
      focus == null || focus.context == null || focus is FocusScopeNode;
  if (perdu && dernier != null && dernier.context != null) {
    dernier.requestFocus();
    focus = dernier;
  }
  if (focus?.context == null) return;
  final contexte = focus?.context;
  switch (touche) {
    case 'ArrowUp':
      _diriger(contexte, TraversalDirection.up);
    case 'ArrowDown':
      _diriger(contexte, TraversalDirection.down);
    case 'ArrowLeft':
      _diriger(contexte, TraversalDirection.left);
    case 'ArrowRight':
      _diriger(contexte, TraversalDirection.right);
    case 'Enter':
      if (contexte != null) {
        Actions.maybeInvoke(contexte, const ActivateIntent());
      }
    case 'Home':
      if (contexte != null) {
        Actions.maybeInvoke(contexte, const AccueilIntent());
      }
    case 'Escape':
      if (contexte != null) {
        Actions.maybeInvoke(contexte, const RetourIntent());
      }
  }
}

/// Passe par les actions de l'app, comme une vraie flèche du clavier, pour
/// que les règles de navigation (onglets, sections) s'appliquent aussi.
void _diriger(BuildContext? contexte, TraversalDirection direction) {
  if (contexte == null) return;
  Actions.maybeInvoke(contexte, DirectionalFocusIntent(direction));
}
