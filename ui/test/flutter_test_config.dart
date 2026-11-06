import 'dart:async';
import 'dart:io';

import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

/// Charge les vraies polices de l'app avant les tests : sans elles, Flutter
/// dessine avec une police de test aux métriques différentes et les
/// vérifications de débordement ne veulent plus rien dire.
Future<void> testExecutable(FutureOr<void> Function() testMain) async {
  TestWidgetsFlutterBinding.ensureInitialized();
  Future<void> charger(String famille, List<String> fichiers) async {
    final chargeur = FontLoader(famille);
    for (final f in fichiers) {
      final octets = File('assets/fonts/$f').readAsBytesSync();
      chargeur.addFont(Future.value(ByteData.view(octets.buffer)));
    }
    await chargeur.load();
  }

  await charger('Bricolage', [
    'BricolageGrotesque-400.ttf',
    'BricolageGrotesque-500.ttf',
    'BricolageGrotesque-600.ttf',
    'BricolageGrotesque-700.ttf',
  ]);
  await charger('BricolageEtroite', [
    'BricolageGrotesque-Condensed700.ttf',
    'BricolageGrotesque-Condensed800.ttf',
  ]);
  await testMain();
}
