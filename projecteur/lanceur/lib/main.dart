import 'package:material_ui/material_ui.dart';
import 'package:flutter/services.dart';

import 'ecrans/accueil.dart';
import 'systeme/systeme.dart';
import 'ui/echelle.dart';
import 'ui/theme.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  // Plein écran, sans barres système : c'est l'écran d'accueil du projecteur.
  SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
  runApp(LanceurApp(systeme: SystemeAndroid()));
}

class LanceurApp extends StatelessWidget {
  const LanceurApp({super.key, required this.systeme});

  final Systeme systeme;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Veilleuse',
      debugShowCheckedModeBanner: false,
      theme: Veilleuse.theme(),
      builder: (context, enfant) => Echelle(child: enfant!),
      home: Accueil(systeme: systeme),
    );
  }
}
