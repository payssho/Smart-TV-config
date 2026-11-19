import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lanceur/donnees/catalogue.dart';
import 'package:lanceur/main.dart';
import 'package:lanceur/systeme/systeme.dart';

/// Projecteur factice : retient ce que le lanceur lui demande.
class SystemeFactice implements Systeme {
  SystemeFactice({this.liste = const [], this.ciblesOuvrables = const {}});

  final List<Appli> liste;

  /// Cibles qui s'ouvrent ; les autres échouent comme sur un vrai firmware.
  final Set<String> ciblesOuvrables;
  final lances = <String>[];
  final essais = <String>[];
  final prefs = <String, String>{};

  @override
  Future<List<Appli>> applis() async => liste;

  @override
  Future<Uint8List?> icone(String paquet) async => null;

  @override
  Future<bool> lancer(String paquet) async {
    lances.add(paquet);
    return true;
  }

  @override
  Future<bool> ouvrir(Cible cible) async {
    essais.add(cible.toString());
    return ciblesOuvrables.contains(cible.toString());
  }

  @override
  Future<Memoire?> memoire() async =>
      const Memoire(disponible: 412 * 1024 * 1024, totale: 1024 * 1024 * 1024);

  @override
  Future<String?> lirePref(String cle) async => prefs[cle];

  @override
  Future<void> ecrirePref(String cle, String valeur) async =>
      prefs[cle] = valeur;
}

const applisProjecteur = [
  Appli(paquet: 'com.exemple.navigateur', nom: 'Navigateur'),
  Appli(paquet: 'com.google.android.youtube.tv', nom: 'YouTube', tv: true),
  Appli(paquet: 'com.exemple.lecteur', nom: 'Lecteur', tv: true),
  Appli(paquet: 'com.netflix.ninja', nom: 'Netflix', tv: true),
  Appli(paquet: 'com.canal.android.canal', nom: 'CANAL+', tv: true),
];

Future<SystemeFactice> demarrer(
  WidgetTester tester, {
  Set<String> ciblesOuvrables = const {},
}) async {
  tester.view.physicalSize = const Size(1280, 720);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  final systeme = SystemeFactice(
    liste: applisProjecteur,
    ciblesOuvrables: ciblesOuvrables,
  );
  await tester.pumpWidget(LanceurApp(systeme: systeme));
  await tester.pumpAndSettle();
  return systeme;
}

Future<void> touche(WidgetTester tester, LogicalKeyboardKey t) async {
  await tester.sendKeyEvent(t);
  await tester.pumpAndSettle();
}

String? libelleFocus() {
  final e = FocusManager.instance.primaryFocus?.context;
  String? libelle;
  e?.visitAncestorElements((a) {
    final w = a.widget;
    if (w is Semantics && w.properties.label != null) {
      libelle = w.properties.label;
      return false;
    }
    return true;
  });
  return libelle;
}

void main() {
  group('ranger', () {
    test('met les favoris dans l\'ordre prévu, puis les applis TV', () {
      final (:favoris, :autres) = ranger(applisProjecteur);
      expect(favoris.map((a) => a.nom), ['Netflix', 'CANAL+', 'YouTube']);
      expect(autres.map((a) => a.nom), ['Lecteur', 'Navigateur']);
    });

    test('préfère la version TV d\'un service quand les deux existent', () {
      final (:favoris, autres: _) = ranger(const [
        Appli(paquet: 'com.google.android.youtube', nom: 'YouTube mobile'),
        Appli(paquet: 'com.google.android.youtube.tv', nom: 'YouTube TV'),
      ]);
      expect(favoris.single.nom, 'YouTube TV');
    });
  });

  testWidgets('le focus démarre sur Netflix et OK le lance', (tester) async {
    final systeme = await demarrer(tester);
    expect(libelleFocus(), 'Netflix');
    await touche(tester, LogicalKeyboardKey.select);
    expect(systeme.lances, ['com.netflix.ninja']);
  });

  testWidgets('la croix mène à Ambiance et la teinte choisie est gardée', (
    tester,
  ) async {
    final systeme = await demarrer(tester);
    await touche(tester, LogicalKeyboardKey.arrowUp);
    expect(libelleFocus(), 'Regarder');
    await touche(tester, LogicalKeyboardKey.arrowRight);
    expect(libelleFocus(), 'Ambiance');
    expect(find.text('Lune'), findsOneWidget);
    await touche(tester, LogicalKeyboardKey.arrowDown);
    await touche(tester, LogicalKeyboardKey.arrowRight);
    expect(libelleFocus(), 'Lune');
    await touche(tester, LogicalKeyboardKey.enter);
    expect(systeme.prefs['teinte'], 'Lune');
  });

  testWidgets('Trapèze retombe sur les réglages d\'affichage', (tester) async {
    final systeme = await demarrer(
      tester,
      ciblesOuvrables: {'android.settings.DISPLAY_SETTINGS'},
    );
    await touche(tester, LogicalKeyboardKey.arrowUp);
    await touche(tester, LogicalKeyboardKey.arrowRight);
    await touche(tester, LogicalKeyboardKey.arrowRight);
    expect(libelleFocus(), 'Réglages');
    expect(find.text('Mémoire libre : 412 Mo sur 1024 Mo'), findsOneWidget);
    await touche(tester, LogicalKeyboardKey.arrowDown);
    expect(libelleFocus(), 'Wi-Fi');
    await touche(tester, LogicalKeyboardKey.arrowRight);
    await touche(tester, LogicalKeyboardKey.arrowRight);
    expect(libelleFocus(), 'Trapèze');
    await touche(tester, LogicalKeyboardKey.select);
    expect(systeme.essais.last, 'android.settings.DISPLAY_SETTINGS');
  });

  testWidgets('Retour remonte aux onglets sans jamais quitter', (tester) async {
    await demarrer(tester);
    // Touche Retour de la télécommande : Android la transmet en « popRoute ».
    await tester.binding.handlePopRoute();
    await tester.pumpAndSettle();
    expect(libelleFocus(), 'Regarder');
    await touche(tester, LogicalKeyboardKey.arrowRight);
    await touche(tester, LogicalKeyboardKey.arrowRight);
    expect(libelleFocus(), 'Réglages');
    await tester.binding.handlePopRoute();
    await tester.pumpAndSettle();
    expect(libelleFocus(), 'Regarder');
    expect(find.text('Netflix'), findsOneWidget);
  });
}
