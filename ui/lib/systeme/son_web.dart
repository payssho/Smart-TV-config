import 'dart:js_interop';

import 'package:web/web.dart' as web;

/// Boucle sonore dans le navigateur (prévisualisation).
class BoucleSonore {
  BoucleSonore(this.asset);

  final String asset;
  web.HTMLAudioElement? _audio;

  bool get disponible => true;

  /// Renvoie faux si le navigateur bloque la lecture (pas encore de clic
  /// dans la page).
  Future<bool> jouer() async {
    final audio = _audio ??= web.HTMLAudioElement()
      ..src = 'assets/$asset'
      ..loop = true
      ..volume = 0.8;
    try {
      await audio.play().toDart;
      return true;
    } catch (_) {
      return false;
    }
  }

  void arreter() {
    _audio?.pause();
    _audio = null;
  }
}
