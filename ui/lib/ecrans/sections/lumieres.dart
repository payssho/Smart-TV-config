import 'package:flutter/material.dart';

import '../../donnees/catalogue.dart';
import '../../donnees/etat_maison.dart';
import '../../ui/theme.dart';
import '../../ui/tuile.dart';

/// Les lumières une par une. OK allume ou éteint ; la lueur du fond suit.
class SectionLumieres extends StatelessWidget {
  const SectionLumieres({super.key});

  @override
  Widget build(BuildContext context) {
    final maison = PorteeMaison.de(context);
    final textes = Theme.of(context).textTheme;
    final lumieres = maison.lumieres;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          maison.nombreAllumees == 0
              ? 'Tout est éteint. OK pour allumer une lumière.'
              : '${maison.nombreAllumees} sur ${lumieres.length} allumées. '
                    'OK pour allumer ou éteindre.',
          style: textes.bodyLarge,
        ),
        const SizedBox(height: 40),
        FocusTraversalGroup(
          child: Wrap(
            spacing: 32,
            runSpacing: 32,
            children: [
              for (final l in lumieres)
                _TuileLumiere(
                  lumiere: l,
                  onActive: () => maison.basculer(l.id),
                ),
            ],
          ),
        ),
      ],
    );
  }
}

class _TuileLumiere extends StatelessWidget {
  const _TuileLumiere({required this.lumiere, required this.onActive});

  final Lumiere lumiere;
  final VoidCallback onActive;

  @override
  Widget build(BuildContext context) {
    final textes = Theme.of(context).textTheme;
    final allumee = lumiere.allumee;
    return Tuile(
      largeur: 554,
      hauteur: 196,
      libelleSemantique:
          '${lumiere.nom}, ${lumiere.piece}, ${allumee ? 'allumée' : 'éteinte'}',
      onActive: onActive,
      child: Row(
        children: [
          AnimatedContainer(
            duration: const Duration(milliseconds: 300),
            width: 88,
            height: 88,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: allumee ? lumiere.couleur : Colors.transparent,
              border: Border.all(
                color: allumee ? lumiere.couleur : Veilleuse.brume,
                width: 3,
              ),
              boxShadow: allumee
                  ? [
                      BoxShadow(
                        color: lumiere.couleur.withValues(alpha: 0.55),
                        blurRadius: 48,
                      ),
                    ]
                  : const [],
            ),
          ),
          const SizedBox(width: 32),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(lumiere.nom, style: textes.titleLarge),
                const SizedBox(height: 8),
                Text(
                  allumee
                      ? '${lumiere.piece}, ${lumiere.intensite} %'
                      : '${lumiere.piece}, éteinte',
                  style: textes.bodyLarge,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
