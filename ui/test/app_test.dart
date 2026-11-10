import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tele/app.dart';
import 'package:tele/donnees/etat_maison.dart';
import 'package:tele/donnees/etat_os.dart';
import 'package:tele/systeme/memoire.dart';
import 'package:tele/systeme/telecommande_distante.dart';

class Tele {
  Tele(this.maison, this.os);
  final EtatMaison maison;
  final EtatOS os;
}

/// Lance l'app sur un écran 1080p, horloge figée à 21:47, fond figé.
Future<Tele> lancer(
  WidgetTester tester, {
  ProfilMemoire profil = ProfilMemoire.deuxGo,
}) async {
  tester.view
    ..physicalSize = const Size(1920, 1080)
    ..devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  // Fond figé : sinon l'animation sans fin empêche pumpAndSettle d'aboutir.
  tester.platformDispatcher.accessibilityFeaturesTestValue =
      const FakeAccessibilityFeatures(disableAnimations: true);
  addTearDown(tester.platformDispatcher.clearAccessibilityFeaturesTestValue);
  final tele = Tele(EtatMaison(), EtatOS());
  await tester.pumpWidget(
    TeleApp(
      profil: profil,
      horloge: () => DateTime(2026, 11, 6, 21, 47),
      etat: tele.maison,
      os: tele.os,
    ),
  );
  await tester.pumpAndSettle();
  return tele;
}

Future<void> touche(
  WidgetTester tester,
  LogicalKeyboardKey cle, {
  int fois = 1,
}) async {
  for (var i = 0; i < fois; i++) {
    await tester.sendKeyEvent(cle);
    await tester.pumpAndSettle();
  }
}

/// Monte aux onglets puis va sur le n-ième (0 = Regarder).
Future<void> onglet(WidgetTester tester, int n) async {
  await touche(tester, LogicalKeyboardKey.arrowUp);
  await touche(tester, LogicalKeyboardKey.arrowRight, fois: n);
}

String? focus() => FocusManager.instance.primaryFocus?.debugLabel;

void main() {
  testWidgets("l'écran principal montre l'heure, les onglets et les applis", (
    tester,
  ) async {
    await lancer(tester);
    expect(find.text('21:47'), findsOneWidget);
    expect(find.text('Bonsoir.'), findsOneWidget);
    for (final titre in [
      'Regarder',
      'Lumières',
      'Ambiance de la pièce',
      "Ambiance de l'OS",
      'Réglages',
    ]) {
      expect(find.text(titre), findsOneWidget);
    }
    for (final nom in ['YouTube', 'Twitch', 'Netflix', 'Canal+', 'Médias']) {
      expect(find.text(nom), findsOneWidget);
    }
    expect(find.text('Feu de cheminée'), findsOneWidget);
  });

  testWidgets("la croix déplace le focus et met à jour l'aide", (tester) async {
    await lancer(tester);
    expect(find.textContaining('navigateur TV'), findsOneWidget);
    await touche(tester, LogicalKeyboardKey.arrowRight);
    expect(find.textContaining('Lecteur natif'), findsOneWidget);
    await touche(tester, LogicalKeyboardKey.arrowDown);
    expect(find.textContaining('crépite'), findsOneWidget);
  });

  testWidgets('Netflix demande avant de redémarrer sous Android', (
    tester,
  ) async {
    await lancer(tester);
    await touche(tester, LogicalKeyboardKey.arrowRight, fois: 2);
    await touche(tester, LogicalKeyboardKey.select);
    expect(find.text("Netflix s'ouvre sous Android"), findsOneWidget);
    await touche(tester, LogicalKeyboardKey.arrowRight); // « Annuler »
    await touche(tester, LogicalKeyboardKey.enter);
    expect(find.text("Netflix s'ouvre sous Android"), findsNothing);
  });

  testWidgets('retour quitte une appli, puis remonte aux onglets', (
    tester,
  ) async {
    await lancer(tester);
    await touche(tester, LogicalKeyboardKey.enter); // YouTube
    expect(find.textContaining('arrive avec la phase 4'), findsOneWidget);
    await touche(tester, LogicalKeyboardKey.escape);
    expect(find.text('Applications'), findsOneWidget);
    await touche(tester, LogicalKeyboardKey.backspace);
    expect(focus(), 'regarder');
  });

  testWidgets('onglet Lumières : OK allume ou éteint', (tester) async {
    final tele = await lancer(tester);
    await onglet(tester, 1);
    expect(find.textContaining('sur 6 allumées'), findsOneWidget);
    await touche(tester, LogicalKeyboardKey.arrowDown);
    final avant = tele.maison.nombreAllumees;
    await touche(tester, LogicalKeyboardKey.enter);
    expect(tele.maison.nombreAllumees, isNot(avant));
    // Retour : d'abord l'onglet courant, puis « Regarder ».
    await touche(tester, LogicalKeyboardKey.escape);
    expect(focus(), 'lumieres');
    await touche(tester, LogicalKeyboardKey.escape);
    expect(focus(), 'regarder');
    expect(find.text('Applications'), findsOneWidget);
  });

  testWidgets("ambiance de la pièce : choisir une scène règle les lumières", (
    tester,
  ) async {
    final tele = await lancer(tester);
    await onglet(tester, 2);
    await touche(tester, LogicalKeyboardKey.arrowDown); // Soirée
    await touche(tester, LogicalKeyboardKey.arrowRight); // Cinéma
    await touche(tester, LogicalKeyboardKey.enter);
    expect(tele.maison.scene.id, 'cinema');
    expect(tele.maison.nombreAllumees, 1);
  });

  testWidgets("ambiance de l'OS : choisir le fond", (tester) async {
    final tele = await lancer(tester);
    expect(tele.os.fond, FondOS.lucioles);
    await onglet(tester, 3);
    expect(find.text('Lucioles'), findsOneWidget);
    await touche(tester, LogicalKeyboardKey.arrowDown);
    await touche(tester, LogicalKeyboardKey.arrowRight); // Braises
    await touche(tester, LogicalKeyboardKey.enter);
    expect(tele.os.fond, FondOS.braises);
  });

  testWidgets('réglages : le sélecteur bascule le profil mémoire', (
    tester,
  ) async {
    await lancer(tester);
    await onglet(tester, 4);
    await touche(tester, LogicalKeyboardKey.arrowDown);
    expect(find.text('2 Go, OK pour simuler 4 Go'), findsOneWidget);
    expect(find.text('allégé, pour épargner le GPU'), findsOneWidget);
    await touche(tester, LogicalKeyboardKey.enter);
    expect(find.text('4 Go, OK pour simuler 2 Go'), findsOneWidget);
    expect(find.text('complet'), findsOneWidget);
  });

  testWidgets('accueil revient sur la première appli', (tester) async {
    await lancer(tester);
    await onglet(tester, 3);
    await touche(tester, LogicalKeyboardKey.arrowDown);
    await touche(tester, LogicalKeyboardKey.home);
    expect(find.text('Applications'), findsOneWidget);
    expect(focus(), 'premiere appli');
  });

  testWidgets('feu de cheminée : OK coupe le son, retour revient', (
    tester,
  ) async {
    await lancer(tester);
    await touche(tester, LogicalKeyboardKey.arrowDown);
    await touche(tester, LogicalKeyboardKey.enter);
    expect(find.text('Feu de cheminée'), findsOneWidget);
    expect(find.textContaining('phase 4'), findsOneWidget);
    await touche(tester, LogicalKeyboardKey.escape);
    expect(find.text('Applications'), findsOneWidget);
  });

  testWidgets('la télécommande de la prévisu rejoue les touches', (
    tester,
  ) async {
    await lancer(tester);
    appuyer('ArrowRight');
    appuyer('ArrowRight');
    await tester.pumpAndSettle();
    appuyer('Enter');
    await tester.pumpAndSettle();
    expect(find.text("Netflix s'ouvre sous Android"), findsOneWidget);
    appuyer('Escape');
    await tester.pumpAndSettle();
    expect(find.text("Netflix s'ouvre sous Android"), findsNothing);
    appuyer('ArrowUp');
    await tester.pumpAndSettle();
    appuyer('Home');
    await tester.pumpAndSettle();
    expect(focus(), 'premiere appli');
  });

  testWidgets('les fonds se dessinent en 2 Go et 4 Go, animés', (tester) async {
    tester.view
      ..physicalSize = const Size(1920, 1080)
      ..devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    for (final profil in ProfilMemoire.values) {
      for (final fond in FondOS.values) {
        await tester.pumpWidget(
          TeleApp(
            key: ValueKey((profil, fond)),
            profil: profil,
            os: EtatOS(fond),
            horloge: () => DateTime(2026, 11, 6, 9, 5),
          ),
        );
        // Quelques secondes d'animation, sans attendre une fin qui n'existe pas.
        for (var i = 0; i < 6; i++) {
          await tester.pump(const Duration(milliseconds: 400));
        }
        expect(tester.takeException(), isNull);
        expect(find.text('Bonjour.'), findsOneWidget);
      }
    }
  });

  group('ProfilMemoire', () {
    test("lit le profil depuis le texte ou l'adresse", () {
      expect(ProfilMemoire.depuisTexte('2go'), ProfilMemoire.deuxGo);
      expect(ProfilMemoire.depuisTexte('2 Go'), ProfilMemoire.deuxGo);
      expect(ProfilMemoire.depuisTexte(null), ProfilMemoire.quatreGo);
      expect(
        ProfilMemoire.detecter(adresse: Uri.parse('http://x/?memoire=2go')),
        ProfilMemoire.deuxGo,
      );
    });

    test("borne le cache d'images selon le profil", () {
      final cache = ImageCache();
      ProfilMemoire.deuxGo.appliquer(cache);
      expect(cache.maximumSizeBytes, 32 << 20);
      ProfilMemoire.quatreGo.appliquer(cache);
      expect(cache.maximumSizeBytes, 96 << 20);
    });
  });
}
