import 'package:flutter/services.dart';

/// Une appli lançable du projecteur.
class Appli {
  const Appli({required this.paquet, required this.nom, this.tv = false});

  final String paquet;
  final String nom;

  /// Prévue pour la TV (catégorie Leanback) : pilotable à la télécommande.
  final bool tv;
}

/// Écran de réglages à ouvrir : par action Android, ou par composant explicite
/// (« paquet/.Activite ») pour les écrans du fabricant.
class Cible {
  const Cible.action(String this.action) : composant = null;
  const Cible.composant(String this.composant) : action = null;

  final String? action;
  final String? composant;

  @override
  String toString() => action ?? composant!;
}

/// Mémoire vive, en octets.
class Memoire {
  const Memoire({required this.disponible, required this.totale});

  final int disponible;
  final int totale;
}

/// Ce que le lanceur demande à Android. Une version factice sert aux tests.
abstract class Systeme {
  Future<List<Appli>> applis();
  Future<Uint8List?> icone(String paquet);
  Future<bool> lancer(String paquet);
  Future<bool> ouvrir(Cible cible);
  Future<Memoire?> memoire();
  Future<String?> lirePref(String cle);
  Future<void> ecrirePref(String cle, String valeur);
}

/// Implémentation réelle : canal vers `MainActivity.kt`.
class SystemeAndroid implements Systeme {
  static const _canal = MethodChannel('veilleuse/systeme');

  @override
  Future<List<Appli>> applis() async {
    final brut = await _canal.invokeListMethod<Map<Object?, Object?>>('applis');
    return [
      for (final a in brut ?? const <Map<Object?, Object?>>[])
        Appli(
          paquet: a['paquet']! as String,
          nom: a['nom']! as String,
          tv: a['tv'] as bool? ?? false,
        ),
    ];
  }

  @override
  Future<Uint8List?> icone(String paquet) =>
      _canal.invokeMethod<Uint8List>('icone', {'paquet': paquet});

  @override
  Future<bool> lancer(String paquet) async =>
      await _canal.invokeMethod<bool>('lancer', {'paquet': paquet}) ?? false;

  @override
  Future<bool> ouvrir(Cible cible) async =>
      await _canal.invokeMethod<bool>('ouvrir', {
        'action': cible.action,
        'composant': cible.composant,
      }) ??
      false;

  @override
  Future<Memoire?> memoire() async {
    final m = await _canal.invokeMapMethod<String, int>('memoire');
    if (m == null) return null;
    return Memoire(disponible: m['disponible']!, totale: m['totale']!);
  }

  @override
  Future<String?> lirePref(String cle) =>
      _canal.invokeMethod<String>('lirePref', {'cle': cle});

  @override
  Future<void> ecrirePref(String cle, String valeur) =>
      _canal.invokeMethod<void>('ecrirePref', {'cle': cle, 'valeur': valeur});
}
