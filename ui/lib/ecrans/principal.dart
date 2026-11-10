import 'dart:async';

import 'package:flutter/material.dart';

import '../contexte.dart';
import '../donnees/catalogue.dart';
import '../donnees/etat_maison.dart';
import '../donnees/etat_os.dart';
import '../ui/fond.dart';
import '../ui/theme.dart';
import '../ui/touches.dart';
import 'sections/ambiance.dart';
import 'sections/regarder.dart';
import 'sections/reglages.dart';

/// Les trois parties de l'OS, dans l'ordre des onglets. Les lumières une
/// par une se pilotent depuis l'app mobile (issue #46).
enum Section {
  regarder('Regarder'),
  ambiance('Ambiance'),
  reglages('Réglages');

  const Section(this.titre);
  final String titre;
}

/// Écran principal : les onglets en haut, la section dessous.
///
/// La croix vers le haut mène aux onglets ; un onglet qui prend le focus
/// affiche sa section tout de suite. Retour remonte aux onglets, puis
/// revient sur « Regarder ». Accueil revient sur la première appli.
class EcranPrincipal extends StatefulWidget {
  const EcranPrincipal({super.key});

  @override
  State<EcranPrincipal> createState() => _EcranPrincipalState();
}

class _EcranPrincipalState extends State<EcranPrincipal> {
  Section _section = Section.regarder;
  final _onglets = {
    for (final s in Section.values) s: FocusNode(debugLabel: s.name),
  };
  final _premiereAppli = FocusNode(debugLabel: 'premiere appli');
  final _contenu = FocusNode(debugLabel: 'contenu', skipTraversal: true);
  Timer? _minuteur;
  EtatOS? _os;

  /// Aperçu : ce qui a le focus devient le fond avant d'être choisi.
  Apercu _apercu = (fond: null, scene: null);

  @override
  void initState() {
    super.initState();
    _minuteur = Timer.periodic(const Duration(seconds: 20), (_) {
      if (mounted) setState(() {});
    });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final os = PorteeOS.de(context);
    if (os != _os) {
      _os?.allerAccueil.removeListener(_accueil);
      _os = os..allerAccueil.addListener(_accueil);
    }
  }

  @override
  void dispose() {
    _os?.allerAccueil.removeListener(_accueil);
    _minuteur?.cancel();
    for (final n in _onglets.values) {
      n.dispose();
    }
    _premiereAppli.dispose();
    _contenu.dispose();
    super.dispose();
  }

  void _accueil() {
    setState(() => _section = Section.regarder);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_premiereAppli.context != null) _premiereAppli.requestFocus();
    });
  }

  /// Descend des onglets vers le premier élément de la section.
  void _entrerDansSection() {
    for (final n in _contenu.traversalDescendants) {
      if (n.canRequestFocus && n is! FocusScopeNode && n.context != null) {
        n.requestFocus();
        return;
      }
    }
  }

  void _retour() {
    final dansOnglets = _onglets.values.any((n) => n.hasPrimaryFocus);
    if (!dansOnglets) {
      _onglets[_section]!.requestFocus();
    } else if (_section != Section.regarder) {
      _onglets[Section.regarder]!.requestFocus();
    }
  }

  @override
  Widget build(BuildContext context) {
    final contexte = ContexteTele.de(context);
    final maison = PorteeMaison.de(context);
    final os = PorteeOS.de(context);
    final scene = _apercu.scene;
    final couleur = scene?.couleur ?? maison.couleurHalo;
    final intensite = scene == null
        ? maison.intensiteHalo
        : (scene.eteint ? 0.25 : 1.0);

    return Actions(
      actions: {
        RetourIntent: CallbackAction<RetourIntent>(
          onInvoke: (_) {
            _retour();
            return null;
          },
        ),
      },
      child: Scaffold(
        body: Stack(
          fit: StackFit.expand,
          children: [
            Fond(
              couleur: couleur,
              intensite: intensite,
              type: _apercu.fond ?? os.fond,
              allege: contexte.profil.fondAllege,
            ),
            Padding(
              padding: Veilleuse.margeSure,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _EnTete(
                    section: _section,
                    onglets: _onglets,
                    maintenant: contexte.horloge(),
                    maison: maison,
                    onDescendre: _entrerDansSection,
                    onSection: (s) => setState(() {
                      _section = s;
                      _apercu = (fond: null, scene: null);
                    }),
                  ),
                  const SizedBox(height: 64),
                  Expanded(
                    child: Focus(
                      focusNode: _contenu,
                      child: FocusTraversalGroup(
                        child: AnimatedSwitcher(
                          duration: const Duration(milliseconds: 220),
                          switchInCurve: Curves.easeOutCubic,
                          transitionBuilder: (enfant, animation) =>
                              FadeTransition(
                                opacity: animation,
                                child: SlideTransition(
                                  position: Tween(
                                    begin: const Offset(0, 0.015),
                                    end: Offset.zero,
                                  ).animate(animation),
                                  child: enfant,
                                ),
                              ),
                          layoutBuilder: (actuel, precedents) => Stack(
                            alignment: Alignment.topLeft,
                            children: [...precedents, ?actuel],
                          ),
                          child: KeyedSubtree(
                            key: ValueKey(_section),
                            child: switch (_section) {
                              Section.regarder => SectionRegarder(
                                autofocus: true,
                                focusPremiere: _premiereAppli,
                              ),
                              Section.ambiance => SectionAmbiance(
                                onApercu: (a) => setState(() => _apercu = a),
                              ),
                              Section.reglages => const SectionReglages(),
                            },
                          ),
                        ),
                      ),
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

class _EnTete extends StatelessWidget {
  const _EnTete({
    required this.section,
    required this.onglets,
    required this.maintenant,
    required this.maison,
    required this.onSection,
    required this.onDescendre,
  });

  final Section section;
  final VoidCallback onDescendre;
  final Map<Section, FocusNode> onglets;
  final DateTime maintenant;
  final EtatMaison maison;
  final ValueChanged<Section> onSection;

  @override
  Widget build(BuildContext context) {
    final textes = Theme.of(context).textTheme;
    final heure =
        '${maintenant.hour.toString().padLeft(2, '0')}:'
        '${maintenant.minute.toString().padLeft(2, '0')}';
    final salut = maintenant.hour >= 18 || maintenant.hour < 5
        ? 'Bonsoir'
        : 'Bonjour';
    return Row(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '$salut.',
              style: textes.headlineMedium?.copyWith(fontSize: 44),
            ),
            const SizedBox(height: 20),
            Actions(
              actions: {
                // Vers le bas : toujours le premier élément de la section.
                DirectionalFocusIntent: _DescendreAction(onDescendre),
              },
              child: FocusTraversalGroup(
                child: Row(
                  children: [
                    for (final s in Section.values)
                      _Onglet(
                        titre: s.titre,
                        choisi: s == section,
                        focusNode: onglets[s]!,
                        onFocus: () => onSection(s),
                        onActive: onDescendre,
                      ),
                  ],
                ),
              ),
            ),
          ],
        ),
        const Spacer(),
        Column(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text(heure, style: textes.displayLarge?.copyWith(fontSize: 104)),
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 14,
                  height: 14,
                  decoration: BoxDecoration(
                    color: maison.couleurHalo,
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: maison.couleurHalo.withValues(alpha: 0.7),
                        blurRadius: 14,
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 12),
                Text(
                  _nomAmbiance(maison, PorteeOS.de(context).fond),
                  style: textes.bodyLarge?.copyWith(fontSize: 24),
                ),
              ],
            ),
          ],
        ),
      ],
    );
  }
}

/// Nom affiché sous l'heure : le préréglage en cours s'il y en a un, sinon
/// la lumière de la pièce.
String _nomAmbiance(EtatMaison maison, FondOS fond) {
  for (final p in Catalogue.prereglages) {
    if (p.fond == fond && p.scene == maison.scene.id) return p.nom;
  }
  return maison.scene.nom;
}

/// Un onglet : texte seul, souligné d'ambre quand il est choisi, entouré
/// d'ambre quand il a le focus.
class _Onglet extends StatefulWidget {
  const _Onglet({
    required this.titre,
    required this.choisi,
    required this.focusNode,
    required this.onFocus,
    required this.onActive,
  });

  final String titre;
  final bool choisi;
  final FocusNode focusNode;
  final VoidCallback onFocus;
  final VoidCallback onActive;

  @override
  State<_Onglet> createState() => _OngletState();
}

class _OngletState extends State<_Onglet> {
  bool _focus = false;

  @override
  Widget build(BuildContext context) {
    final textes = Theme.of(context).textTheme;
    return FocusableActionDetector(
      focusNode: widget.focusNode,
      onFocusChange: (f) {
        setState(() => _focus = f);
        if (f) widget.onFocus();
      },
      actions: {
        // OK sur un onglet : on descend dans la section.
        ActivateIntent: CallbackAction<ActivateIntent>(
          onInvoke: (_) {
            widget.onActive();
            return null;
          },
        ),
      },
      child: GestureDetector(
        onTap: widget.focusNode.requestFocus,
        child: AnimatedContainer(
          duration: Veilleuse.dureeFocus,
          margin: const EdgeInsets.only(right: 12),
          padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 12),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(999),
            color: _focus ? Veilleuse.ardoiseClaire : Colors.transparent,
            border: Border.all(
              color: _focus ? Veilleuse.ambre : Colors.transparent,
              width: 3,
            ),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                widget.titre,
                style: textes.titleMedium?.copyWith(
                  color: widget.choisi || _focus
                      ? Veilleuse.lin
                      : Veilleuse.brume,
                  fontWeight: widget.choisi ? FontWeight.w600 : FontWeight.w500,
                ),
              ),
              const SizedBox(height: 6),
              AnimatedContainer(
                duration: Veilleuse.dureeFocus,
                height: 4,
                width: widget.choisi ? 36 : 0,
                decoration: BoxDecoration(
                  color: Veilleuse.ambre,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Flèche vers le bas sur un onglet : entre dans la section par son premier
/// élément. Les autres directions gardent le comportement normal.
class _DescendreAction extends DirectionalFocusAction {
  _DescendreAction(this.descendre);

  final VoidCallback descendre;

  @override
  void invoke(DirectionalFocusIntent intent) {
    if (intent.direction == TraversalDirection.down) {
      descendre();
    } else {
      super.invoke(intent);
    }
  }
}
