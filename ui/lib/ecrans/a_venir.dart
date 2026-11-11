import 'package:material_ui/material_ui.dart';

import '../donnees/catalogue.dart';
import '../ui/fond.dart';
import '../donnees/etat_os.dart';
import '../ui/theme.dart';
import '../ui/tuile.dart';
import '../contexte.dart';

/// Écran provisoire des usages pas encore branchés (phase 4).
class EcranAVenir extends StatelessWidget {
  const EcranAVenir({super.key, required this.usage});

  final Usage usage;

  static Route<void> route(Usage usage) => PageRouteBuilder(
    pageBuilder: (_, _, _) => EcranAVenir(usage: usage),
    transitionsBuilder: (_, animation, _, enfant) =>
        FadeTransition(opacity: animation, child: enfant),
  );

  @override
  Widget build(BuildContext context) {
    final textes = Theme.of(context).textTheme;
    final ou = switch (usage.lanceur) {
      Lanceur.navigateur => 'dans le navigateur TV (Chromium en kiosque)',
      Lanceur.natif => 'dans un écran natif',
      Lanceur.android => 'sous Android',
    };
    return Scaffold(
      body: Stack(
        fit: StackFit.expand,
        children: [
          Fond(
            couleur: usage.teinte,
            intensite: 0.6,
            type: FondOS.calme,
            allege: ContexteTele.de(context).profil.fondAllege,
          ),
          Padding(
            padding: Veilleuse.margeSure,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(usage.nom, style: textes.displayLarge),
                const SizedBox(height: 32),
                SizedBox(
                  width: 1000,
                  child: Text(
                    '${usage.nom} s\'ouvrira ici $ou. '
                    'Cet écran arrive avec la phase 4.',
                    style: textes.titleMedium?.copyWith(color: Veilleuse.brume),
                  ),
                ),
                const SizedBox(height: 56),
                Tuile(
                  autofocus: true,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 40,
                    vertical: 22,
                  ),
                  onActive: () => Navigator.of(context).pop(),
                  child: Text('Revenir à l\'accueil', style: textes.labelLarge),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
