/// Boucle sonore. Sur la box, le son passera par GStreamer (flutter-pi,
/// ADR 0010) en phase 4 ; d'ici là cette version ne joue rien.
class BoucleSonore {
  BoucleSonore(this.asset);

  final String asset;

  /// Faux tant que le son n'est pas branché sur la box.
  bool get disponible => false;

  /// Renvoie vrai si le son joue.
  Future<bool> jouer() async => false;

  void arreter() {}
}
