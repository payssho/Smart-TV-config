import 'package:flutter/painting.dart';

/// Profil mémoire de la box. La HK1 commandée a 4 Go ; le profil 2 Go sert à
/// vérifier que l'interface reste utilisable sur une box plus petite
/// (voir docs/emulation-memoire.md).
enum ProfilMemoire {
  deuxGo(
    libelle: '2 Go',
    cacheImagesOctets: 32 << 20,
    cacheImagesNombre: 200,
    fondAllege: true,
  ),
  quatreGo(
    libelle: '4 Go',
    cacheImagesOctets: 96 << 20,
    cacheImagesNombre: 1000,
    fondAllege: false,
  );

  const ProfilMemoire({
    required this.libelle,
    required this.cacheImagesOctets,
    required this.cacheImagesNombre,
    required this.fondAllege,
  });

  final String libelle;

  /// Plafond du cache d'images décodées de Flutter.
  final int cacheImagesOctets;
  final int cacheImagesNombre;

  /// Fond animé allégé en 2 Go (un seul ruban, moins de poussières) pour
  /// épargner le GPU quand Chromium ou le lecteur vidéo tournent à côté.
  final bool fondAllege;

  /// Lit le profil : paramètre d'URL `?memoire=2go` (prévisualisation web),
  /// sinon `--dart-define=PROFIL_MEMOIRE=2go`, sinon 4 Go.
  static ProfilMemoire detecter({Uri? adresse}) {
    final depuisUrl = (adresse ?? Uri.base).queryParameters['memoire'];
    const depuisBuild = String.fromEnvironment('PROFIL_MEMOIRE');
    return depuisTexte(depuisUrl ?? depuisBuild);
  }

  static ProfilMemoire depuisTexte(String? texte) =>
      switch (texte?.toLowerCase().replaceAll(' ', '')) {
        '2go' || '2' || '2g' => ProfilMemoire.deuxGo,
        _ => ProfilMemoire.quatreGo,
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
