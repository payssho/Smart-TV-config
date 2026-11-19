import 'dart:async';

import 'package:material_ui/material_ui.dart';
import 'package:flutter/services.dart';

import '../donnees/catalogue.dart';
import '../systeme/systeme.dart';
import '../ui/theme.dart';
import '../ui/tuile.dart';
import 'ambiance.dart';
import 'regarder.dart';
import 'reglages.dart';

/// Les trois onglets voulus par Marius pour la télé, repris ici.
enum Onglet {
  regarder('Regarder', Icons.play_arrow_rounded),
  ambiance('Ambiance', Icons.wb_twilight_rounded),
  reglages('Réglages', Icons.tune_rounded);

  const Onglet(this.nom, this.icone);
  final String nom;
  final IconData icone;
}

/// Écran d'accueil : barre d'onglets en haut, contenu de l'onglet dessous.
/// L'onglet change dès qu'il reçoit le focus, comme sur les interfaces TV.
class Accueil extends StatefulWidget {
  const Accueil({super.key, required this.systeme});

  final Systeme systeme;

  @override
  State<Accueil> createState() => _AccueilState();
}

class _AccueilState extends State<Accueil> {
  Onglet _onglet = Onglet.regarder;
  List<Appli>? _applis;
  Teinte _teinte = teintes.first;
  final _icones = <String, Future<Uint8List?>>{};
  final _focusOnglets = {for (final o in Onglet.values) o: FocusNode()};
  final _focusContenu = FocusNode(skipTraversal: true);
  late final AppLifecycleListener _cycle;

  @override
  void initState() {
    super.initState();
    _charger();
    _lireTeinte();
    // Au retour d'une appli : la liste a pu changer (installation, retrait).
    _cycle = AppLifecycleListener(onResume: _charger);
  }

  @override
  void dispose() {
    _cycle.dispose();
    for (final f in _focusOnglets.values) {
      f.dispose();
    }
    _focusContenu.dispose();
    super.dispose();
  }

  Future<void> _charger() async {
    final applis = await widget.systeme.applis();
    if (mounted) setState(() => _applis = applis);
  }

  Future<void> _lireTeinte() async {
    final nom = await widget.systeme.lirePref('teinte');
    final t = teintes.where((t) => t.nom == nom).firstOrNull;
    if (t != null && mounted) setState(() => _teinte = t);
  }

  void _choisirTeinte(Teinte t) {
    setState(() => _teinte = t);
    widget.systeme.ecrirePref('teinte', t.nom);
  }

  Future<Uint8List?> _icone(String paquet) =>
      _icones.putIfAbsent(paquet, () => widget.systeme.icone(paquet));

  /// Retour : du contenu vers son onglet, puis vers « Regarder ». Jamais de
  /// sortie : on est l'écran d'accueil.
  void _retour() {
    final ongletActif = _focusOnglets[_onglet]!;
    if (!ongletActif.hasFocus) {
      ongletActif.requestFocus();
    } else if (_onglet != Onglet.regarder) {
      _focusOnglets[Onglet.regarder]!.requestFocus();
    }
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (_, _) => _retour(),
      child: Shortcuts(
        shortcuts: const {
          // Clavier de développement ; la touche Retour de la télécommande
          // arrive par PopScope.
          SingleActivator(LogicalKeyboardKey.escape): _RetourIntent(),
        },
        child: Actions(
          actions: {
            _RetourIntent: CallbackAction<_RetourIntent>(
              onInvoke: (_) {
                _retour();
                return null;
              },
            ),
          },
          child: Scaffold(
            body: Stack(
              children: [
                Positioned.fill(child: _Halo(couleur: _teinte.couleur)),
                Padding(
                  padding: Veilleuse.margeSure,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _barre(),
                      const SizedBox(height: 28),
                      Expanded(child: _contenu()),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  /// Bas depuis la barre : toujours la première tuile de l'onglet, pas celle
  /// qui se trouve géométriquement sous l'onglet.
  KeyEventResult _toucheBarre(FocusNode _, KeyEvent e) {
    if (e is KeyUpEvent || e.logicalKey != LogicalKeyboardKey.arrowDown) {
      return KeyEventResult.ignored;
    }
    final premiere = _focusContenu.traversalDescendants.firstOrNull;
    if (premiere == null) return KeyEventResult.ignored;
    premiere.requestFocus();
    return KeyEventResult.handled;
  }

  Widget _barre() {
    return Focus(
      canRequestFocus: false,
      skipTraversal: true,
      onKeyEvent: _toucheBarre,
      child: Row(
        children: [
          for (final o in Onglet.values) ...[
            Tuile(
              focusNode: _focusOnglets[o],
              libelle: o.nom,
              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
              fond: o == _onglet ? Veilleuse.ardoise : Colors.transparent,
              onFocus: (f) {
                if (f && _onglet != o) setState(() => _onglet = o);
              },
              onActive: () => setState(() => _onglet = o),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(o.icone, size: 24, color: Veilleuse.lin),
                  const SizedBox(width: 8),
                  Text(o.nom, style: Theme.of(context).textTheme.titleMedium),
                ],
              ),
            ),
            const SizedBox(width: 12),
          ],
          const Spacer(),
          const _Horloge(),
        ],
      ),
    );
  }

  Widget _contenu() {
    return Focus(
      focusNode: _focusContenu,
      canRequestFocus: false,
      child: FocusTraversalGroup(
        child: switch (_onglet) {
          Onglet.regarder => Regarder(
            applis: _applis,
            icone: _icone,
            lancer: widget.systeme.lancer,
          ),
          Onglet.ambiance => Ambiance(teinte: _teinte, choisir: _choisirTeinte),
          Onglet.reglages => Reglages(systeme: widget.systeme),
        },
      ),
    );
  }
}

class _RetourIntent extends Intent {
  const _RetourIntent();
}

/// Halo de lumière fixe dans un coin : la teinte d'ambiance, sans animation
/// (1 Go de RAM partagé avec Netflix, rien ne doit tourner en fond).
class _Halo extends StatelessWidget {
  const _Halo({required this.couleur});

  final Color couleur;

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 400),
      decoration: BoxDecoration(
        gradient: RadialGradient(
          center: const Alignment(-0.9, -1.1),
          radius: 1.3,
          colors: [
            couleur.withValues(alpha: couleur == Colors.black ? 0 : 0.22),
            Veilleuse.nuit.withValues(alpha: 0),
          ],
        ),
      ),
    );
  }
}

/// Heure en haut à droite, mise à jour à la minute.
class _Horloge extends StatefulWidget {
  const _Horloge();

  @override
  State<_Horloge> createState() => _HorlogeState();
}

class _HorlogeState extends State<_Horloge> {
  Timer? _minuteur;
  DateTime _maintenant = DateTime.now();

  @override
  void initState() {
    super.initState();
    _caler();
  }

  void _caler() {
    final prochaine = 60 - _maintenant.second;
    _minuteur = Timer(Duration(seconds: prochaine), () {
      if (!mounted) return;
      setState(() => _maintenant = DateTime.now());
      _caler();
    });
  }

  @override
  void dispose() {
    _minuteur?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final h = _maintenant.hour.toString().padLeft(2, '0');
    final m = _maintenant.minute.toString().padLeft(2, '0');
    return Text(
      '$h:$m',
      style: Theme.of(context).textTheme.titleLarge?.copyWith(
        fontFamily: Veilleuse.policeEtroite,
        fontWeight: FontWeight.w800,
      ),
    );
  }
}
