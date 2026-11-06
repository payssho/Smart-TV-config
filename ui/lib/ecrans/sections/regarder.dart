import 'package:flutter/material.dart';

import '../../contexte.dart';
import '../../donnees/catalogue.dart';
import '../../ui/logos.dart';
import '../../ui/theme.dart';
import '../../ui/tuile.dart';
import '../a_venir.dart';
import '../dialogue_android.dart';
import '../feu.dart';

/// « Regarder » : les applis, puis la détente.
class SectionRegarder extends StatefulWidget {
  const SectionRegarder({
    super.key,
    this.autofocus = false,
    this.focusPremiere,
  });

  final bool autofocus;

  /// Focus de la première tuile, pour y revenir avec la touche Accueil.
  final FocusNode? focusPremiere;

  @override
  State<SectionRegarder> createState() => _SectionRegarderState();
}

class _SectionRegarderState extends State<SectionRegarder> {
  String _aide = Catalogue.usages.first.description;

  void _ouvrir(Usage usage) {
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
        Text('Applications', style: textes.titleLarge),
        const SizedBox(height: 24),
        Row(
          children: [
            for (final (i, usage) in Catalogue.usages.indexed) ...[
              if (i > 0) const SizedBox(width: 28),
              Tuile(
                largeur: 322,
                hauteur: 210,
                autofocus: widget.autofocus && i == 0,
                focusNode: i == 0 ? widget.focusPremiere : null,
                libelleSemantique: usage.nom,
                onFocus: (f) {
                  if (f) setState(() => _aide = usage.description);
                },
                onActive: () => _ouvrir(usage),
                child: _ContenuUsage(usage: usage),
              ),
            ],
          ],
        ),
        const SizedBox(height: 28),
        SizedBox(
          height: 40,
          child: AnimatedSwitcher(
            duration: const Duration(milliseconds: 180),
            child: Text(_aide, key: ValueKey(_aide), style: textes.bodyLarge),
          ),
        ),
        const Spacer(),
        Text('Détente', style: textes.titleLarge),
        const SizedBox(height: 24),
        Tuile(
          largeur: 672,
          hauteur: 210,
          padding: EdgeInsets.zero,
          libelleSemantique: 'Feu de cheminée',
          onFocus: (f) {
            if (f) {
              setState(
                () => _aide =
                    'Un feu qui crépite en plein écran, avec le son. '
                    'Retour pour revenir.',
              );
            }
          },
          onActive: () => Navigator.of(context).push(EcranFeu.route()),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(Veilleuse.rayonTuile - 4),
            child: Stack(
              fit: StackFit.expand,
              children: [
                const DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: RadialGradient(
                      center: Alignment(0.55, 1.2),
                      radius: 1.1,
                      colors: [
                        Color(0xFFB8471A),
                        Color(0xFF3A1A0E),
                        Color(0xFF1B1210),
                      ],
                      stops: [0, 0.45, 1],
                    ),
                  ),
                ),
                const Positioned(
                  right: 48,
                  bottom: 20,
                  child: Icon(
                    Icons.local_fire_department_rounded,
                    size: 150,
                    color: Color(0xFFFFA24A),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(32),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'avec le son',
                        style: textes.bodyLarge?.copyWith(fontSize: 22),
                      ),
                      const Spacer(),
                      Text(
                        'Feu de cheminée',
                        style: textes.headlineMedium?.copyWith(
                          fontFamily: Veilleuse.policeEtroite,
                          fontWeight: FontWeight.w700,
                          fontSize: 56,
                        ),
                      ),
                    ],
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
              Text(
                'sous Android',
                style: textes.bodyLarge?.copyWith(fontSize: 22),
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
