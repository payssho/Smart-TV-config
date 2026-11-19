import 'package:material_ui/material_ui.dart';

import '../donnees/catalogue.dart';
import '../ui/theme.dart';
import '../ui/tuile.dart';

/// Onglet « Ambiance » : la teinte du halo de l'écran d'accueil. « Noir »
/// éteint le halo, pour les séances dans le noir complet.
class Ambiance extends StatelessWidget {
  const Ambiance({super.key, required this.teinte, required this.choisir});

  final Teinte teinte;
  final ValueChanged<Teinte> choisir;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 20,
      runSpacing: 20,
      children: [
        for (final t in teintes)
          Tuile(
            libelle: t.nom,
            largeur: 180,
            hauteur: 180,
            onActive: () => choisir(t),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  width: 72,
                  height: 72,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: t.couleur,
                    border: Border.all(color: Veilleuse.brume, width: 1),
                    boxShadow: [
                      BoxShadow(
                        color: t.couleur.withValues(alpha: 0.5),
                        blurRadius: 28,
                      ),
                    ],
                  ),
                  child: t == teinte
                      ? Icon(
                          Icons.check_rounded,
                          size: 40,
                          color: t.couleur.computeLuminance() > 0.3
                              ? Veilleuse.nuit
                              : Veilleuse.lin,
                        )
                      : null,
                ),
                const SizedBox(height: 16),
                Text(t.nom, style: Theme.of(context).textTheme.titleMedium),
              ],
            ),
          ),
      ],
    );
  }
}
