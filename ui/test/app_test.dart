import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tele/app.dart';
import 'package:tele/donnees/etat_maison.dart';
import 'package:tele/donnees/etat_os.dart';
import 'package:tele/ecrans/feu.dart';
import 'package:tele/systeme/medias.dart';
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
  // Pas de lecteur vidéo en test : l'écran du feu montre l'image fixe.
  Medias.actifs = false;
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

/// Le nom de la tuile qui a le focus (son libellé d'accessibilité).
String? tuileFocus(WidgetTester tester) {
  final noeud = FocusManager.instance.primaryFocus;
  final ctx = noeud?.context;
  if (ctx == null) return null;
  String? libelle;
  ctx.visitAncestorElements((e) {
    final w = e.widget;
    if (w is Semantics && w.properties.label != null) {
      libelle = w.properties.label;
      return false;
    }
    return true;
  });
  return libelle;
}

void main() {
  testWidgets("l'écran principal : trois onglets, les applis, sans aide", (
    tester,
  ) async {
    await lancer(tester);
    expect(find.text('21:47'), findsOneWidget);
    expect(find.text('Bonsoir.'), findsOneWidget);
    for (final titre in ['Regarder', 'Ambiance', 'Réglages']) {
      expect(find.text(titre), findsOneWidget);
    }
    expect(find.text('Lumières'), findsNothing);
    for (final nom in [
      'YouTube',
      'Twitch',
      'Deezer',
      'Médias',
      'Netflix',
      'Canal+',
      'Prime Video',
      'Disney+',
    ]) {
      expect(find.text(nom), findsOneWidget);
    }
    expect(find.text('Feu de cheminée'), findsOneWidget);
    // Plus de texte d'aide sous les tuiles.
    expect(find.textContaining('navigateur'), findsNothing);
    expect(find.text('Veillée'), findsOneWidget); // ambiance en cours
  });

  testWidgets('la croix va des applis au feu et revient', (tester) async {
    await lancer(tester);
    expect(tuileFocus(tester), 'YouTube');
    await touche(tester, LogicalKeyboardKey.arrowRight);
    expect(tuileFocus(tester), 'Twitch');
    await touche(tester, LogicalKeyboardKey.arrowRight);
    expect(tuileFocus(tester), 'Deezer');
    await touche(tester, LogicalKeyboardKey.arrowDown);
    expect(tuileFocus(tester), 'Prime Video, sous Android');
    await touche(tester, LogicalKeyboardKey.arrowRight);
    expect(tuileFocus(tester), 'Disney+, sous Android');
    await touche(tester, LogicalKeyboardKey.arrowLeft, fois: 3);
    expect(tuileFocus(tester), 'Netflix, sous Android');
    await touche(tester, LogicalKeyboardKey.arrowDown);
    expect(tuileFocus(tester), 'Feu de cheminée');
    await touche(tester, LogicalKeyboardKey.arrowUp);
    expect(tuileFocus(tester), isNotNull);
  });

  testWidgets('Netflix demande avant de redémarrer sous Android', (
    tester,
  ) async {
    await lancer(tester);
    await touche(tester, LogicalKeyboardKey.arrowDown);
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
    expect(find.text('YouTube'), findsOneWidget);
    await touche(tester, LogicalKeyboardKey.backspace);
    expect(focus(), 'regarder');
  });

  testWidgets('ambiance : un préréglage règle le fond et la pièce', (
    tester,
  ) async {
    final tele = await lancer(tester);
    await onglet(tester, 1);
    await touche(tester, LogicalKeyboardKey.arrowDown); // Veillée
    expect(tuileFocus(tester), 'Veillée');
    await touche(tester, LogicalKeyboardKey.arrowRight); // Coin du feu
    await touche(tester, LogicalKeyboardKey.enter);
    expect(tele.os.fond, FondOS.braises);
    expect(tele.maison.scene.id, 'soiree');
    await touche(tester, LogicalKeyboardKey.arrowRight, fois: 2); // Cinéma
    await touche(tester, LogicalKeyboardKey.enter);
    expect(tele.os.fond, FondOS.calme);
    expect(tele.maison.scene.id, 'cinema');
    expect(tele.maison.nombreAllumees, 1);
    // Retour : d'abord l'onglet courant, puis « Regarder ».
    await touche(tester, LogicalKeyboardKey.escape);
    expect(focus(), 'ambiance');
    await touche(tester, LogicalKeyboardKey.escape);
    expect(focus(), 'regarder');
    expect(find.text('YouTube'), findsOneWidget);
  });

  testWidgets('ambiance : le fond et la lumière se règlent aussi à part', (
    tester,
  ) async {
    final tele = await lancer(tester);
    await onglet(tester, 1);
    await touche(tester, LogicalKeyboardKey.arrowDown); // préréglages
    await touche(tester, LogicalKeyboardKey.arrowDown); // rangée des fonds
    expect(tuileFocus(tester), 'Lucioles');
    await touche(tester, LogicalKeyboardKey.arrowRight, fois: 2);
    expect(tuileFocus(tester), 'Pluie');
    await touche(tester, LogicalKeyboardKey.enter);
    expect(tele.os.fond, FondOS.pluie);
    expect(tele.maison.scene.id, 'soiree');
    // La rangée des lumières prolonge celle des fonds, à droite.
    await touche(tester, LogicalKeyboardKey.arrowRight, fois: 3);
    expect(tuileFocus(tester), 'Lumière Cinéma');
    await touche(tester, LogicalKeyboardKey.enter);
    expect(tele.maison.scene.id, 'cinema');
    expect(tele.os.fond, FondOS.pluie);
  });

  testWidgets('réglages : le sélecteur bascule le profil mémoire', (
    tester,
  ) async {
    await lancer(tester);
    await onglet(tester, 2);
    await touche(tester, LogicalKeyboardKey.arrowDown);
    expect(find.text('2 Go, OK pour simuler 4 Go'), findsOneWidget);
    expect(find.text('allégé, pour épargner le GPU'), findsOneWidget);
    await touche(tester, LogicalKeyboardKey.enter);
    expect(find.text('4 Go, OK pour simuler 2 Go'), findsOneWidget);
    expect(find.text('complet'), findsOneWidget);
  });

  testWidgets('réglages : stockage et crédits des médias', (tester) async {
    await lancer(tester);
    await onglet(tester, 2);
    await touche(tester, LogicalKeyboardKey.arrowDown); // Système
    await touche(tester, LogicalKeyboardKey.arrowDown); // Stockage
    expect(find.text('256 Mo au plus'), findsOneWidget);
    await touche(tester, LogicalKeyboardKey.enter);
    expect(find.text('vidés'), findsOneWidget);
    await touche(tester, LogicalKeyboardKey.arrowDown, fois: 3); // Crédits
    expect(find.text('free video library, CC BY 3.0'), findsOneWidget);
  });

  testWidgets('accueil revient sur la première appli', (tester) async {
    await lancer(tester);
    await onglet(tester, 1);
    await touche(tester, LogicalKeyboardKey.arrowDown);
    await touche(tester, LogicalKeyboardKey.home);
    expect(find.text('YouTube'), findsOneWidget);
    expect(focus(), 'premiere appli');
  });

  testWidgets('feu de cheminée : un vrai feu, crédité, retour revient', (
    tester,
  ) async {
    await lancer(tester);
    await touche(tester, LogicalKeyboardKey.arrowDown, fois: 2);
    await touche(tester, LogicalKeyboardKey.enter);
    expect(find.text(MediasFeu.credit), findsOneWidget);
    expect(
      find.byWidgetPredicate(
        (w) =>
            w is Image &&
            w.image is AssetImage &&
            (w.image as AssetImage).assetName == MediasFeu.affiche,
      ),
      findsOneWidget,
    );
    // Sans lecteur, pas de son : l'icône le dit, sans phrase.
    expect(find.byIcon(Icons.volume_off_rounded), findsOneWidget);
    await touche(tester, LogicalKeyboardKey.escape);
    expect(find.text('YouTube'), findsOneWidget);
  });

  testWidgets('la télécommande de la prévisu rejoue les touches', (
    tester,
  ) async {
    await lancer(tester);
    appuyer('ArrowDown');
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

  testWidgets('les quatre fonds se dessinent en 2 Go et 4 Go, animés', (
    tester,
  ) async {
    tester.view
      ..physicalSize = const Size(1920, 1080)
      ..devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    expect(FondOS.values.map((f) => f.nom), [
      'Lucioles',
      'Braises',
      'Pluie',
      'Nuit calme',
    ]);
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
      expect(ProfilMemoire.depuisTexte('4 Go'), ProfilMemoire.quatreGo);
      // Sans indication : 2 Go, la cible de la première version.
      expect(ProfilMemoire.depuisTexte(null), ProfilMemoire.deuxGo);
      expect(
        ProfilMemoire.detecter(adresse: Uri.parse('http://x/?memoire=4go')),
        ProfilMemoire.quatreGo,
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
