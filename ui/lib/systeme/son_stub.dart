import 'package:video_player/video_player.dart';

import 'medias.dart';

/// Boucle sonore sur la box : le lecteur de video_player, que flutter-pi
/// sert par GStreamer (ADR 0010).
class BoucleSonore {
  BoucleSonore(this.asset);

  final String asset;
  VideoPlayerController? _lecteur;

  bool get disponible => Medias.actifs;

  /// Renvoie vrai si le son joue.
  Future<bool> jouer() async {
    if (!disponible) return false;
    try {
      final lecteur = _lecteur ??= VideoPlayerController.asset(asset);
      if (!lecteur.value.isInitialized) await lecteur.initialize();
      await lecteur.setLooping(true);
      await lecteur.play();
      return true;
    } catch (_) {
      return false;
    }
  }

  void arreter() {
    _lecteur?.dispose();
    _lecteur = null;
  }
}
