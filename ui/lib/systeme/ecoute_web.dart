import 'dart:js_interop';
import 'dart:js_interop_unsafe';

import 'package:web/web.dart' as web;

import 'telecommande_distante.dart';

/// Prévisualisation web : la page hôte envoie `{touche: 'ArrowRight'}` par
/// postMessage. Les événements clavier synthétiques ne sont pas acceptés
/// par Flutter web, d'où ce canal.
void ecouterTelecommandeWeb() {
  suivreFocus();
  web.window.addEventListener(
    'message',
    (web.MessageEvent e) {
      final donnees = e.data;
      if (donnees == null || !donnees.isA<JSObject>()) return;
      final touche = (donnees as JSObject).getProperty<JSAny?>('touche'.toJS);
      if (touche != null && touche.isA<JSString>()) {
        appuyer((touche as JSString).toDart);
      }
    }.toJS,
  );
}
