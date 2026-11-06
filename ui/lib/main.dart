import 'package:flutter/material.dart';

import 'app.dart';
import 'systeme/ecoute.dart';
import 'systeme/memoire.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  final profil = ProfilMemoire.detecter()..appliquer();
  ecouterTelecommandeWeb();
  runApp(TeleApp(profil: profil, horloge: horlogeDepuisAdresse()));
  // Repère lu par le banc d'émulation mémoire (scripts/emulation/).
  if (const bool.fromEnvironment('TRACE_DEMARRAGE')) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      debugPrint(
        'tele: premiere-image ${DateTime.now().millisecondsSinceEpoch}',
      );
    });
  }
}

/// `?heure=21:47` fige l'horloge (captures reproductibles de la prévisu).
DateTime Function() horlogeDepuisAdresse() {
  final texte = Uri.base.queryParameters['heure'];
  final morceaux = texte?.split(':');
  if (morceaux == null || morceaux.length != 2) return DateTime.now;
  final h = int.tryParse(morceaux[0]);
  final m = int.tryParse(morceaux[1]);
  if (h == null || m == null) return DateTime.now;
  return () {
    final n = DateTime.now();
    return DateTime(n.year, n.month, n.day, h, m);
  };
}
