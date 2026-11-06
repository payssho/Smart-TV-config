import 'package:flutter/material.dart';

import '../../contexte.dart';
import '../../systeme/memoire.dart';
import '../../ui/theme.dart';
import '../../ui/tuile.dart';
import '../dialogue_android.dart';

enum _Rubrique {
  systeme('Système'),
  telecommande('Télécommande'),
  affichage('Affichage'),
  android('Redémarrer sous Android');

  const _Rubrique(this.titre);
  final String titre;
}

/// Réglages : une colonne de rubriques, le détail de celle qui a le focus.
class SectionReglages extends StatefulWidget {
  const SectionReglages({super.key});

  @override
  State<SectionReglages> createState() => _SectionReglagesState();
}

class _SectionReglagesState extends State<SectionReglages> {
  _Rubrique _rubrique = _Rubrique.systeme;

  @override
  Widget build(BuildContext context) {
    final textes = Theme.of(context).textTheme;
    final contexte = ContexteTele.de(context);
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 560,
          child: FocusTraversalGroup(
            child: Column(
              children: [
                for (final r in _Rubrique.values) ...[
                  Tuile(
                    largeur: 540,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 32,
                      vertical: 24,
                    ),
                    fond: r == _rubrique
                        ? Veilleuse.ardoise
                        : Colors.transparent,
                    onFocus: (f) {
                      if (f) setState(() => _rubrique = r);
                    },
                    onActive: () {
                      switch (r) {
                        case _Rubrique.android:
                          montrerDialogueAndroid(context, 'Android');
                        case _Rubrique.systeme:
                          contexte.changerProfil?.call(contexte.profil.autre);
                        case _Rubrique.telecommande || _Rubrique.affichage:
                          break;
                      }
                    },
                    child: Text(r.titre, style: textes.titleMedium),
                  ),
                  const SizedBox(height: 16),
                ],
              ],
            ),
          ),
        ),
        const SizedBox(width: 96),
        Expanded(
          child: AnimatedSwitcher(
            duration: const Duration(milliseconds: 160),
            child: KeyedSubtree(
              key: ValueKey((_rubrique, contexte.profil)),
              child: _Detail(
                rubrique: _rubrique,
                profil: contexte.profil,
                selecteur: contexte.changerProfil != null,
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _Detail extends StatelessWidget {
  const _Detail({
    required this.rubrique,
    required this.profil,
    required this.selecteur,
  });

  final _Rubrique rubrique;
  final ProfilMemoire profil;
  final bool selecteur;

  @override
  Widget build(BuildContext context) {
    final lignes = switch (rubrique) {
      _Rubrique.systeme => [
        (
          'Mémoire de la box',
          selecteur
              ? '${profil.libelle}, OK pour simuler ${profil.autre.libelle}'
              : profil.libelle,
        ),
        ('Cache d\'images', '${profil.cacheImagesOctets >> 20} Mo'),
        (
          'Fond animé',
          profil.fondAllege ? 'allégé, pour épargner le GPU' : 'complet',
        ),
        ('Version', '0.1.0, prototype'),
        ('Affichage', 'flutter-pi sur la box, navigateur en prévisualisation'),
      ],
      _Rubrique.telecommande => [
        ('Croix', 'déplace le focus'),
        ('OK', 'ouvre ou active'),
        ('Retour', 'revient à l\'écran précédent, puis aux onglets'),
        ('Accueil', 'revient sur « Regarder »'),
        ('Sources', 'télécommande de la télé (CEC) et infrarouge'),
      ],
      _Rubrique.affichage => [
        ('Définition', '1920 × 1080'),
        ('Marge de sécurité', '5 % sur chaque bord'),
        ('Police', 'Bricolage Grotesque'),
      ],
      _Rubrique.android => [
        ('Pourquoi', 'Netflix et Canal+ ne tournent bien que sous Android'),
        ('Durée', 'environ 40 secondes'),
        ('Retour', 'rallumer la box ou choisir « Télé maison »'),
      ],
    };
    final textes = Theme.of(context).textTheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        for (final (libelle, valeur) in lignes)
          Padding(
            padding: const EdgeInsets.only(bottom: 28),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SizedBox(
                  width: 360,
                  child: Text(libelle, style: textes.bodyLarge),
                ),
                Expanded(child: Text(valeur, style: textes.titleMedium)),
              ],
            ),
          ),
      ],
    );
  }
}
