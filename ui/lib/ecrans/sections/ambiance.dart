import 'package:flutter/material.dart';

import '../../donnees/catalogue.dart';
import '../../donnees/etat_maison.dart';
import '../../donnees/etat_os.dart';
import '../../ui/fond.dart';
import '../../ui/theme.dart';
import '../../ui/tuile.dart';

/// Ce que l'écran montre en aperçu pendant que le focus passe sur un choix.
typedef Apercu = ({FondOS? fond, Scene? scene});

/// « Ambiance » : l'ambiance de l'OS et celle de la pièce, ensemble.
///
/// En haut, les préréglages : un OK règle le fond et la lumière d'un coup.
/// En dessous, le réglage fin : le fond seul, la lumière seule. Le fond de
/// l'écran devient ce qui a le focus avant même qu'on le choisisse. Les
/// lumières une par une se règlent dans l'app mobile (issue #46).
class SectionAmbiance extends StatelessWidget {
  const SectionAmbiance({super.key, required this.onApercu});

  /// Appelé avec l'aperçu du choix qui a le focus, ou deux nuls quand le
  /// focus quitte la section.
  final ValueChanged<Apercu> onApercu;

  @override
  Widget build(BuildContext context) {
    final os = PorteeOS.de(context);
    final maison = PorteeMaison.de(context);
    final textes = Theme.of(context).textTheme;
    void apercu({FondOS? fond, Scene? scene}) =>
        onApercu((fond: fond, scene: scene));

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        FocusTraversalGroup(
          child: Row(
            children: [
              for (final (i, p) in Catalogue.prereglages.indexed) ...[
                if (i > 0) const SizedBox(width: 28),
                _TuileApercu(
                  largeur: 322,
                  hauteur: 330,
                  fond: p.fond,
                  couleur: Catalogue.scene(p.scene).couleur,
                  eteint: Catalogue.scene(p.scene).eteint,
                  titre: p.nom,
                  actif: os.fond == p.fond && maison.scene.id == p.scene,
                  onFocus: (f) => f
                      ? apercu(fond: p.fond, scene: Catalogue.scene(p.scene))
                      : apercu(),
                  onActive: () {
                    os.fond = p.fond;
                    maison.activerScene(Catalogue.scene(p.scene));
                  },
                ),
              ],
            ],
          ),
        ),
        const Spacer(),
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _Rangee(
              titre: 'Fond',
              enfants: [
                for (final f in FondOS.values)
                  _TuileApercu(
                    largeur: 190,
                    hauteur: 150,
                    fond: f,
                    couleur: maison.couleurHalo,
                    titre: f.nom,
                    petit: true,
                    actif: os.fond == f,
                    onFocus: (focus) => focus ? apercu(fond: f) : apercu(),
                    onActive: () => os.fond = f,
                  ),
              ],
            ),
            const SizedBox(width: 72),
            _Rangee(
              titre: 'Lumière de la pièce',
              enfants: [
                for (final s in Catalogue.scenes)
                  Tuile(
                    largeur: 190,
                    hauteur: 150,
                    padding: const EdgeInsets.all(22),
                    libelleSemantique: 'Lumière ${s.nom}',
                    onFocus: (f) => f ? apercu(scene: s) : apercu(),
                    onActive: () => maison.activerScene(s),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            _Globe(couleur: s.couleur, eteint: s.eteint),
                            const Spacer(),
                            if (maison.scene.id == s.id) const _PastilleActif(),
                          ],
                        ),
                        const Spacer(),
                        Text(s.nom, style: textes.titleMedium),
                      ],
                    ),
                  ),
              ],
            ),
          ],
        ),
      ],
    );
  }
}

class _Rangee extends StatelessWidget {
  const _Rangee({required this.titre, required this.enfants});

  final String titre;
  final List<Widget> enfants;

  @override
  Widget build(BuildContext context) {
    final textes = Theme.of(context).textTheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(titre, style: textes.bodyLarge?.copyWith(fontSize: 24)),
        const SizedBox(height: 18),
        FocusTraversalGroup(
          child: Row(
            children: [
              for (final (i, e) in enfants.indexed) ...[
                if (i > 0) const SizedBox(width: 20),
                e,
              ],
            ],
          ),
        ),
      ],
    );
  }
}

/// Une tuile qui montre le fond en vrai (image figée du peintre), avec un
/// voile de la couleur de la lumière.
class _TuileApercu extends StatelessWidget {
  const _TuileApercu({
    required this.largeur,
    required this.hauteur,
    required this.fond,
    required this.couleur,
    required this.titre,
    required this.actif,
    required this.onFocus,
    required this.onActive,
    this.eteint = false,
    this.petit = false,
  });

  final double largeur;
  final double hauteur;
  final FondOS fond;
  final Color couleur;
  final bool eteint;
  final String titre;
  final bool actif;
  final bool petit;
  final ValueChanged<bool> onFocus;
  final VoidCallback onActive;

  @override
  Widget build(BuildContext context) {
    final textes = Theme.of(context).textTheme;
    return Tuile(
      largeur: largeur,
      hauteur: hauteur,
      padding: EdgeInsets.zero,
      libelleSemantique: titre,
      onFocus: onFocus,
      onActive: onActive,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(Veilleuse.rayonTuile - 4),
        child: Stack(
          fit: StackFit.expand,
          children: [
            CustomPaint(
              painter: PeintreFond(
                couleur: couleur,
                intensite: eteint ? 0.25 : 1,
                temps: const AlwaysStoppedAnimation(0.27),
                type: fond,
                allege: true,
                miniature: true,
              ),
            ),
            Padding(
              padding: EdgeInsets.all(petit ? 18 : 26),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Align(
                    alignment: Alignment.topRight,
                    child: actif ? const _PastilleActif() : null,
                  ),
                  const Spacer(),
                  Text(
                    titre,
                    style: petit
                        ? textes.titleMedium
                        : textes.headlineMedium?.copyWith(
                            fontFamily: Veilleuse.policeEtroite,
                            fontWeight: FontWeight.w700,
                            fontSize: 44,
                          ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Le choix en cours : une pastille ambre, pas de mot.
class _PastilleActif extends StatelessWidget {
  const _PastilleActif();

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: 'en cours',
      child: Container(
        width: 16,
        height: 16,
        decoration: BoxDecoration(
          color: Veilleuse.ambre,
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(
              color: Veilleuse.ambre.withValues(alpha: 0.7),
              blurRadius: 12,
            ),
          ],
        ),
      ),
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
      width: 44,
      height: 44,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: eteint ? Colors.transparent : couleur,
        border: eteint ? Border.all(color: Veilleuse.brume, width: 3) : null,
        boxShadow: eteint
            ? const []
            : [
                BoxShadow(
                  color: couleur.withValues(alpha: 0.6),
                  blurRadius: 36,
                ),
              ],
      ),
    );
  }
}
