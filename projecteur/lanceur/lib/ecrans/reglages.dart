import 'package:material_ui/material_ui.dart';

import '../donnees/catalogue.dart';
import '../systeme/systeme.dart';
import '../ui/theme.dart';
import '../ui/tuile.dart';

/// Onglet « Réglages » : raccourcis vers les écrans d'Android et du fabricant
/// (trapèze, mise au point). Le lanceur ne refait aucun réglage lui-même :
/// toutes les fonctions d'origine restent celles du projecteur.
class Reglages extends StatefulWidget {
  const Reglages({super.key, required this.systeme});

  final Systeme systeme;

  @override
  State<Reglages> createState() => _ReglagesState();
}

class _ReglagesState extends State<Reglages> {
  Memoire? _memoire;

  @override
  void initState() {
    super.initState();
    widget.systeme.memoire().then((m) {
      if (mounted) setState(() => _memoire = m);
    });
  }

  /// Essaie chaque cible dans l'ordre ; la première qui s'ouvre gagne.
  Future<void> _ouvrir(Reglage r) async {
    for (final c in r.cibles) {
      if (await widget.systeme.ouvrir(c)) return;
    }
  }

  @override
  Widget build(BuildContext context) {
    final m = _memoire;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Wrap(
          spacing: 20,
          runSpacing: 20,
          children: [
            for (final r in reglages)
              Tuile(
                libelle: r.nom,
                largeur: 160,
                hauteur: 150,
                onActive: () => _ouvrir(r),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(r.icone, size: 44, color: Veilleuse.lin),
                    const SizedBox(height: 12),
                    Text(r.nom, style: Theme.of(context).textTheme.titleMedium),
                  ],
                ),
              ),
          ],
        ),
        const Spacer(),
        if (m != null)
          Text(
            'Mémoire libre : ${_mo(m.disponible)} sur ${_mo(m.totale)}',
            style: Theme.of(context).textTheme.bodyLarge,
          ),
      ],
    );
  }

  static String _mo(int octets) => '${(octets / (1024 * 1024)).round()} Mo';
}
