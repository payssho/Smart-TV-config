import 'package:flutter/painting.dart';

/// Profil mémoire de la box. La première version vise une box 2 Go
/// (d'occasion), avec une 4 Go en repli si 2 Go ne suffit pas
/// (voir docs/emulation-memoire.md).
enum ProfilMemoire {
  deuxGo(
    libelle: '2 Go',
    cacheImagesOctets: 32 << 20,
    cacheImagesNombre: 200,
    cacheNavigateurMo: 256,
    fondAllege: true,
  ),
  quatreGo(
    libelle: '4 Go',
    cacheImagesOctets: 96 << 20,
    cacheImagesNombre: 1000,
    cacheNavigateurMo: 512,
    fondAllege: false,
  );

  const ProfilMemoire({
    required this.libelle,
    required this.cacheImagesOctets,
    required this.cacheImagesNombre,
    required this.cacheNavigateurMo,
    required this.fondAllege,
  });

  final String libelle;

  /// Plafond du cache d'images décodées de Flutter.
  final int cacheImagesOctets;
  final int cacheImagesNombre;

  /// Plafond du cache disque de Chromium sur la carte SD (issue #45).
  final int cacheNavigateurMo;

  /// Fond animé allégé en 2 Go (moins de lumières à l'écran) pour
  /// épargner le GPU quand Chromium ou le lecteur vidéo tournent à côté.
  final bool fondAllege;

  /// Lit le profil : paramètre d'URL `?memoire=2go` (prévisualisation web),
  /// sinon `--dart-define=PROFIL_MEMOIRE=4go`, sinon 2 Go, la cible de la
  /// première version.
  static ProfilMemoire detecter({Uri? adresse}) {
    final depuisUrl = (adresse ?? Uri.base).queryParameters['memoire'];
    const depuisBuild = String.fromEnvironment('PROFIL_MEMOIRE');
    return depuisTexte(depuisUrl ?? depuisBuild);
  }

  static ProfilMemoire depuisTexte(String? texte) =>
      switch (texte?.toLowerCase().replaceAll(' ', '')) {
        '4go' || '4' || '4g' => ProfilMemoire.quatreGo,
        _ => ProfilMemoire.deuxGo,
      };

  /// Politique « sobre » : en 2 Go, on vide le cache d'images avant de
  /// laisser la place à une app plein écran (Chromium, lecteur vidéo).
  void avantAppPleinEcran([ImageCache? cache]) {
    if (this != ProfilMemoire.deuxGo) return;
    final cible = cache ?? PaintingBinding.instance.imageCache;
    cible
      ..clear()
      ..clearLiveImages();
  }

  ProfilMemoire get autre => this == ProfilMemoire.deuxGo
      ? ProfilMemoire.quatreGo
      : ProfilMemoire.deuxGo;

  void appliquer([ImageCache? cache]) {
    final cible = cache ?? PaintingBinding.instance.imageCache;
    cible
      ..maximumSizeBytes = cacheImagesOctets
      ..maximumSize = cacheImagesNombre;
  }
}
