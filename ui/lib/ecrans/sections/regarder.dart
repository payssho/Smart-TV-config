import 'package:flutter/material.dart';

import '../../contexte.dart';
import '../../donnees/catalogue.dart';
import '../../ui/logos.dart';
import '../../ui/theme.dart';
import '../../ui/tuile.dart';
import '../a_venir.dart';
import '../dialogue_android.dart';
import '../feu.dart';

/// « Regarder » : les applis sur deux rangées, puis la détente. Aucun texte d'aide :
/// le logo et le nom suffisent, l'icône de redémarrage signale les applis
/// qui s'ouvrent sous Android.
class SectionRegarder extends StatelessWidget {
  const SectionRegarder({
    super.key,
    this.autofocus = false,
    this.focusPremiere,
  });

  final bool autofocus;

  /// Focus de la première tuile, pour y revenir avec la touche Accueil.
  final FocusNode? focusPremiere;

  void _ouvrir(BuildContext context, Usage usage) {
    if (usage.lanceur == Lanceur.android) {
      montrerDialogueAndroid(context, usage.nom);
    } else {
      ContexteTele.de(context).profil.avantAppPleinEcran();
      Navigator.of(context).push(EcranAVenir.route(usage));
    }
  }

  @override
  Widget build(BuildContext context) {
    final textes = Theme.of(context).textTheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Deux rangées de quatre : notre OS en haut, Android en dessous.
        for (var debut = 0; debut < Catalogue.usages.length; debut += 4) ...[
          if (debut > 0) const SizedBox(height: 24),
          Row(
            children: [
              for (final (i, usage)
                  in Catalogue.usages.skip(debut).take(4).indexed) ...[
                if (i > 0) const SizedBox(width: 28),
                Tuile(
                  largeur: 411,
                  hauteur: 196,
                  autofocus: autofocus && debut + i == 0,
                  focusNode: debut + i == 0 ? focusPremiere : null,
                  libelleSemantique: usage.lanceur == Lanceur.android
                      ? '${usage.nom}, sous Android'
                      : usage.nom,
                  onActive: () => _ouvrir(context, usage),
                  child: _ContenuUsage(usage: usage),
                ),
              ],
            ],
          ),
        ],
        const Spacer(),
        Tuile(
          largeur: 850,
          hauteur: 270,
          padding: EdgeInsets.zero,
          libelleSemantique: 'Feu de cheminée',
          onActive: () => Navigator.of(context).push(EcranFeu.route()),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(Veilleuse.rayonTuile - 4),
            child: Stack(
              fit: StackFit.expand,
              children: [
                // Une image du vrai feu, pas un dessin.
                Image.asset(MediasFeu.affiche, fit: BoxFit.cover),
                const DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [Colors.transparent, Color(0xCC0B0806)],
                      stops: [0.35, 1],
                    ),
                  ),
                ),
                Positioned(
                  left: 32,
                  bottom: 24,
                  child: Text(
                    'Feu de cheminée',
                    style: textes.headlineMedium?.copyWith(
                      fontFamily: Veilleuse.policeEtroite,
                      fontWeight: FontWeight.w700,
                      fontSize: 52,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _ContenuUsage extends StatelessWidget {
  const _ContenuUsage({required this.usage});

  final Usage usage;

  @override
  Widget build(BuildContext context) {
    final textes = Theme.of(context).textTheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            LogoUsage(id: usage.id, hauteur: 64),
            const Spacer(),
            if (usage.lanceur == Lanceur.android)
              const Icon(
                Icons.restart_alt_rounded,
                size: 34,
                color: Veilleuse.brume,
              ),
          ],
        ),
        const Spacer(),
        Text(
          usage.nom,
          style: textes.headlineMedium?.copyWith(
            fontFamily: Veilleuse.policeEtroite,
            fontWeight: FontWeight.w700,
            fontSize: 48,
          ),
        ),
      ],
    );
  }
}
