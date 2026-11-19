import 'dart:typed_data';

import 'package:material_ui/material_ui.dart';

import '../donnees/catalogue.dart';
import '../systeme/systeme.dart';
import '../ui/theme.dart';
import '../ui/tuile.dart';

/// Onglet « Regarder » : les services prioritaires en grand, puis toutes les
/// autres applis. Le focus démarre sur la première tuile.
class Regarder extends StatelessWidget {
  const Regarder({
    super.key,
    required this.applis,
    required this.icone,
    required this.lancer,
  });

  /// null tant que la liste n'est pas arrivée.
  final List<Appli>? applis;
  final Future<Uint8List?> Function(String paquet) icone;
  final Future<bool> Function(String paquet) lancer;

  @override
  Widget build(BuildContext context) {
    final liste = applis;
    if (liste == null) return const SizedBox.shrink();
    final (:favoris, :autres) = ranger(liste);
    return SingleChildScrollView(
      clipBehavior: Clip.none,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (favoris.isNotEmpty)
            Wrap(
              spacing: 20,
              runSpacing: 20,
              children: [
                for (final (i, a) in favoris.indexed)
                  _TuileAppli(
                    appli: a,
                    icone: icone(a.paquet),
                    lancer: lancer,
                    largeur: 260,
                    hauteur: 146,
                    autofocus: i == 0,
                  ),
              ],
            ),
          if (autres.isNotEmpty) ...[
            const SizedBox(height: 32),
            Wrap(
              spacing: 16,
              runSpacing: 16,
              children: [
                for (final (i, a) in autres.indexed)
                  _TuileAppli(
                    appli: a,
                    icone: icone(a.paquet),
                    lancer: lancer,
                    largeur: 176,
                    hauteur: 99,
                    autofocus: favoris.isEmpty && i == 0,
                  ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}

class _TuileAppli extends StatelessWidget {
  const _TuileAppli({
    required this.appli,
    required this.icone,
    required this.lancer,
    required this.largeur,
    required this.hauteur,
    this.autofocus = false,
  });

  final Appli appli;
  final Future<Uint8List?> icone;
  final Future<bool> Function(String paquet) lancer;
  final double largeur;
  final double hauteur;
  final bool autofocus;

  @override
  Widget build(BuildContext context) {
    return Tuile(
      libelle: appli.nom,
      autofocus: autofocus,
      largeur: largeur,
      hauteur: hauteur,
      padding: const EdgeInsets.all(10),
      onActive: () => lancer(appli.paquet),
      child: FutureBuilder<Uint8List?>(
        future: icone,
        builder: (context, instantane) {
          final octets = instantane.data;
          if (octets == null) {
            // Pas encore d'image (ou aucune) : le nom, sobrement.
            return Center(
              child: Text(
                appli.nom,
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: Theme.of(context).textTheme.titleMedium,
              ),
            );
          }
          return ClipRRect(
            borderRadius: BorderRadius.circular(Veilleuse.rayonTuile - 6),
            child: Image.memory(
              octets,
              fit: BoxFit.contain,
              gaplessPlayback: true,
              // Décodée à la taille de la tuile : pas de bannière 4K en RAM.
              cacheWidth: largeur.round(),
              semanticLabel: appli.nom,
            ),
          );
        },
      ),
    );
  }
}
