import 'package:flutter/material.dart';

import '../../contexte.dart';
import '../../donnees/etat_maison.dart';
import '../../donnees/etat_os.dart';
import '../../ui/fond.dart';
import '../../ui/theme.dart';
import '../../ui/tuile.dart';

/// « Ambiance de l'OS » : le fond de l'interface. Comme pour les scènes, le
/// fond change dès qu'un choix a le focus.
class SectionAmbianceOS extends StatelessWidget {
  const SectionAmbianceOS({super.key, required this.onSurvol});

  final ValueChanged<FondOS?> onSurvol;

  @override
  Widget build(BuildContext context) {
    final os = PorteeOS.de(context);
    final maison = PorteeMaison.de(context);
    final profil = ContexteTele.de(context).profil;
    final textes = Theme.of(context).textTheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Le fond reprend la couleur des lumières de la pièce. '
          'Il se met en pause pendant une vidéo.',
          style: textes.bodyLarge,
        ),
        const SizedBox(height: 48),
        FocusTraversalGroup(
          child: Row(
            children: [
              for (final (i, fond) in FondOS.values.indexed) ...[
                if (i > 0) const SizedBox(width: 40),
                Tuile(
                  largeur: 549,
                  hauteur: 360,
                  padding: EdgeInsets.zero,
                  libelleSemantique: 'Fond ${fond.nom}',
                  onFocus: (f) => onSurvol(f ? fond : null),
                  onActive: () => os.fond = fond,
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(
                      Veilleuse.rayonTuile - 4,
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        SizedBox(
                          height: 170,
                          width: double.infinity,
                          child: CustomPaint(
                            painter: PeintreFond(
                              couleur: maison.couleurHalo,
                              intensite: 1,
                              temps: const AlwaysStoppedAnimation(0.27),
                              type: fond,
                            ),
                          ),
                        ),
                        Expanded(
                          child: Padding(
                            padding: const EdgeInsets.fromLTRB(28, 20, 28, 24),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Text(fond.nom, style: textes.titleLarge),
                                    const Spacer(),
                                    if (os.fond == fond)
                                      Text(
                                        'actif',
                                        style: textes.bodyLarge?.copyWith(
                                          fontSize: 24,
                                        ),
                                      ),
                                  ],
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  fond.description,
                                  style: textes.bodyLarge?.copyWith(
                                    fontSize: 24,
                                  ),
                                  maxLines: 2,
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
        const SizedBox(height: 40),
        Text(
          profil.fondAllege
              ? 'Box 2 Go : fond allégé, moins de lucioles et de braises.'
              : 'Box 4 Go : fond complet.',
          style: textes.bodyLarge?.copyWith(fontSize: 24),
        ),
      ],
    );
  }
}
