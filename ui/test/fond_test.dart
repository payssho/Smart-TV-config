import 'dart:io';
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:material_ui/material_ui.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tele/donnees/etat_os.dart';
import 'package:tele/ui/fond.dart';
import 'package:tele/ui/fond/rythme.dart';

const _ecran = Size(1920, 1080);

/// Peint un fond hors écran et rend ses pixels (RGBA).
Future<Uint8List> pixels(
  FondOS type,
  double t, {
  Size taille = _ecran,
  bool allege = false,
  bool miniature = false,
  ui.ImageByteFormat format = ui.ImageByteFormat.rawRgba,
}) async {
  final enregistreur = ui.PictureRecorder();
  PeintreFond(
    couleur: const Color(0xFFFFA25C),
    intensite: 1,
    temps: AlwaysStoppedAnimation(t),
    type: type,
    allege: allege,
    miniature: miniature,
  ).paint(Canvas(enregistreur), taille);
  final image = enregistreur.endRecording().toImageSync(
    taille.width.toInt(),
    taille.height.toInt(),
  );
  final octets = await image.toByteData(format: format);
  image.dispose();
  return octets!.buffer.asUint8List();
}

void main() {
  group('rythme', () {
    test('le bruit se referme sur sa période et reste borné', () {
      for (final periode in [3, 7, 47]) {
        for (var i = 0; i <= 200; i++) {
          final x = i / 200 * periode;
          expect(
            bruit(x, periode, 5),
            closeTo(bruit(x + periode, periode, 5), 1e-9),
          );
          expect(bruit(x, periode, 5).abs(), lessThan(1.2));
        }
      }
    });

    test(
      "l'éclat d'une luciole monte vite, retombe lentement, puis s'éteint",
      () {
        expect(eclat(0), 0);
        expect(eclat(0.04), closeTo(1, 1e-9));
        expect(eclat(0.12), inInclusiveRange(0.4, 0.65));
        expect(eclat(0.7), 0);
        expect(eclat(0.99), 0);
      },
    );
  });

  group('fonds', () {
    for (final type in FondOS.values) {
      test(
        '${type.nom} : la boucle de deux minutes se referme sans couture',
        () async {
          final debut = await pixels(type, 0, taille: const Size(480, 270));
          final fin = await pixels(type, 1, taille: const Size(480, 270));
          var ecartMax = 0;
          for (var i = 0; i < debut.length; i++) {
            final e = (debut[i] - fin[i]).abs();
            if (e > ecartMax) ecartMax = e;
          }
          // Un niveau sur 255 au plus : l'arrondi des calculs, rien de visible.
          expect(ecartMax, lessThanOrEqualTo(1));
        },
      );

      test('${type.nom} : le fond bouge et ne brûle pas les yeux', () async {
        final a = await pixels(type, 0.3);
        final b = await pixels(type, 0.31);
        var differents = 0;
        var somme = 0;
        var clairs = 0;
        for (var i = 0; i < a.length; i += 4) {
          if (a[i] != b[i] || a[i + 1] != b[i + 1] || a[i + 2] != b[i + 2]) {
            differents++;
          }
          final lum = (a[i] * 0.2126 + a[i + 1] * 0.7152 + a[i + 2] * 0.0722)
              .round();
          somme += lum;
          if (lum > 200) clairs++;
        }
        final n = a.length ~/ 4;
        expect(differents, greaterThan(n ~/ 2000), reason: 'le fond est figé');
        // Un fond : sombre en moyenne, jamais noir, presque aucun pixel vif.
        expect(somme / n, inInclusiveRange(12, 70));
        expect(clairs / n, lessThan(0.004));
      });
    }

    test('le profil 2 Go et les miniatures se dessinent aussi', () async {
      for (final type in FondOS.values) {
        await pixels(type, 0.27, allege: true);
        await pixels(
          type,
          0.27,
          taille: const Size(322, 330),
          allege: true,
          miniature: true,
        );
        await pixels(
          type,
          0.27,
          taille: const Size(190, 150),
          allege: true,
          miniature: true,
        );
      }
    });
  });

  // Planche de contrôle : `PLANCHE=dossier` écrit chaque fond en PNG, à
  // plusieurs instants, pour les relire à l'œil.
  final dossier = Platform.environment['PLANCHE'];
  test(
    'planche de contrôle',
    skip: dossier == null ? 'PLANCHE non défini' : false,
    timeout: const Timeout(Duration(minutes: 5)),
    () async {
      Directory(dossier!).createSync(recursive: true);
      for (final type in FondOS.values) {
        for (final t in [0.27, 0.3, 0.3016, 0.624]) {
          for (final allege in [false, true]) {
            if (allege && t != 0.3) continue;
            final png = await pixels(
              type,
              t,
              allege: allege,
              format: ui.ImageByteFormat.png,
            );
            File('$dossier/${type.name}-${allege ? '2go-' : ''}$t.png')
                .writeAsBytesSync(png);
          }
        }
        final mini = await pixels(
          type,
          0.27,
          taille: const Size(322, 330),
          allege: true,
          miniature: true,
          format: ui.ImageByteFormat.png,
        );
        File('$dossier/${type.name}-miniature.png').writeAsBytesSync(mini);
      }
    },
  );
}
