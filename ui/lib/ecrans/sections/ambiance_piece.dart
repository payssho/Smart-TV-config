import 'package:flutter/material.dart';

import '../../donnees/catalogue.dart';
import '../../donnees/etat_maison.dart';
import '../../ui/theme.dart';
import '../../ui/tuile.dart';

/// « Ambiance de la pièce » : les scènes de lumière. Le fond de l'écran
/// prend la couleur de la scène qui a le focus, avant même de la choisir.
class SectionAmbiancePiece extends StatelessWidget {
  const SectionAmbiancePiece({super.key, required this.onSurvol});

  /// Scène qui a le focus (nulle quand le focus sort de la rangée).
  final ValueChanged<Scene?> onSurvol;

  @override
  Widget build(BuildContext context) {
    final maison = PorteeMaison.de(context);
    final textes = Theme.of(context).textTheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Ambiance ${maison.scene.nom.toLowerCase()} en ce moment. '
          'L\'écran montre la couleur de chaque ambiance ; OK pour l\'appliquer.',
          style: textes.bodyLarge,
        ),
        const SizedBox(height: 48),
        FocusTraversalGroup(
          child: Row(
            children: [
              for (final (i, scene) in Catalogue.scenes.indexed) ...[
                if (i > 0) const SizedBox(width: 40),
                Tuile(
                  largeur: 402,
                  hauteur: 320,
                  libelleSemantique: 'Ambiance ${scene.nom}',
                  onFocus: (f) => onSurvol(f ? scene : null),
                  onActive: () => maison.activerScene(scene),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          _Globe(couleur: scene.couleur, eteint: scene.eteint),
                          const Spacer(),
                          if (maison.scene.id == scene.id)
                            Text(
                              'active',
                              style: textes.bodyLarge?.copyWith(fontSize: 24),
                            ),
                        ],
                      ),
                      const Spacer(),
                      Text(scene.nom, style: textes.headlineMedium),
                      const SizedBox(height: 10),
                      Text(
                        scene.description,
                        style: textes.bodyLarge?.copyWith(fontSize: 24),
                        maxLines: 2,
                      ),
                    ],
                  ),
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }
}

class _Globe extends StatelessWidget {
  const _Globe({required this.couleur, required this.eteint});

  final Color couleur;
  final bool eteint;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 72,
      height: 72,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: eteint ? Colors.transparent : couleur,
        border: eteint ? Border.all(color: Veilleuse.brume, width: 3) : null,
        boxShadow: eteint
            ? const []
            : [
                BoxShadow(
                  color: couleur.withValues(alpha: 0.6),
                  blurRadius: 56,
                ),
              ],
      ),
    );
  }
}
