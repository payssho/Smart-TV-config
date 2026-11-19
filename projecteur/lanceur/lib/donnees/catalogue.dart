import 'package:material_ui/material_ui.dart';

import '../systeme/systeme.dart';

/// Applis mises en avant dans « Regarder », dans cet ordre (usages prioritaires
/// de Marius, ADR 0014). Plusieurs paquets possibles par service : version TV
/// d'abord, version mobile ensuite. Les autres applis vont dans la grille.
const favoris = <String, List<String>>{
  'Netflix': ['com.netflix.ninja', 'com.netflix.mediaclient'],
  'Canal+': ['com.canal.android.canal'],
  'YouTube': ['com.google.android.youtube.tv', 'com.google.android.youtube'],
  'Twitch': ['tv.twitch.android.app'],
  'Prime Video': [
    'com.amazon.amazonvideo.livingroom',
    'com.amazon.avod.thirdpartyclient',
  ],
  'Disney+': ['com.disney.disneyplus'],
};

/// Range les applis : favoris présents (dans l'ordre ci-dessus), puis le
/// reste, applis TV d'abord, par nom.
({List<Appli> favoris, List<Appli> autres}) ranger(List<Appli> applis) {
  final parPaquet = {for (final a in applis) a.paquet: a};
  final enAvant = <Appli>[];
  for (final paquets in favoris.values) {
    for (final p in paquets) {
      final a = parPaquet[p];
      if (a != null) {
        enAvant.add(a);
        break;
      }
    }
  }
  final pris = {for (final a in enAvant) a.paquet};
  final autres =
      [
        for (final a in applis)
          if (!pris.contains(a.paquet)) a,
      ]..sort((a, b) {
        if (a.tv != b.tv) return a.tv ? -1 : 1;
        return a.nom.toLowerCase().compareTo(b.nom.toLowerCase());
      });
  return (favoris: enAvant, autres: autres);
}

/// Un raccourci de l'onglet Réglages : on essaie les cibles dans l'ordre,
/// la première qui s'ouvre gagne.
class Reglage {
  const Reglage(this.nom, this.icone, this.cibles);

  final String nom;
  final IconData icone;
  final List<Cible> cibles;
}

/// Écrans du fabricant (trapèze, mise au point). Leurs noms dépendent du
/// firmware : à remplir avec le résultat de `projecteur/adb/inventaire.sh`
/// (ex. `Cible.composant('paquet.du.fabricant/.KeystoneActivity')`). En
/// attendant, on retombe sur les réglages d'affichage d'Android.
const ciblesTrapeze = <Cible>[];
const ciblesMiseAuPoint = <Cible>[];

final reglages = <Reglage>[
  const Reglage('Wi-Fi', Icons.wifi_rounded, [
    Cible.action('android.settings.WIFI_SETTINGS'),
  ]),
  const Reglage('Bluetooth', Icons.bluetooth_rounded, [
    Cible.action('android.settings.BLUETOOTH_SETTINGS'),
  ]),
  const Reglage('Trapèze', Icons.crop_free_rounded, [
    ...ciblesTrapeze,
    Cible.action('android.settings.DISPLAY_SETTINGS'),
  ]),
  const Reglage('Netteté', Icons.center_focus_strong_rounded, [
    ...ciblesMiseAuPoint,
    Cible.action('android.settings.DISPLAY_SETTINGS'),
  ]),
  const Reglage('Son', Icons.volume_up_rounded, [
    Cible.action('android.settings.SOUND_SETTINGS'),
  ]),
  const Reglage('Applis', Icons.apps_rounded, [
    Cible.action('android.settings.APPLICATION_SETTINGS'),
  ]),
  const Reglage('Tout', Icons.tune_rounded, [
    Cible.action('android.settings.SETTINGS'),
  ]),
];

/// Couleurs de halo de l'onglet Ambiance : la seule couleur forte de l'écran.
class Teinte {
  const Teinte(this.nom, this.couleur);

  final String nom;
  final Color couleur;
}

const teintes = <Teinte>[
  Teinte('Braise', Color(0xFFFFB46B)),
  Teinte('Lune', Color(0xFF8FB4FF)),
  Teinte('Mousse', Color(0xFF8FD6A8)),
  Teinte('Aube', Color(0xFFFF9AA8)),
  Teinte('Noir', Color(0xFF000000)),
];
