import 'package:flutter/foundation.dart';
import 'package:material_ui/material_ui.dart';

import 'contexte.dart';
import 'donnees/etat_maison.dart';
import 'donnees/etat_os.dart';
import 'ecrans/principal.dart';
import 'systeme/memoire.dart';
import 'ui/echelle_tele.dart';
import 'ui/theme.dart';
import 'ui/touches.dart';

class TeleApp extends StatefulWidget {
  const TeleApp({
    this.os,
    super.key,
    required this.profil,
    this.horloge = DateTime.now,
    this.etat,
  });

  final ProfilMemoire profil;
  final Horloge horloge;
  final EtatMaison? etat;
  final EtatOS? os;

  @override
  State<TeleApp> createState() => _TeleAppState();
}

class _TeleAppState extends State<TeleApp> {
  final _navigateur = GlobalKey<NavigatorState>();
  late final EtatMaison _etat = widget.etat ?? EtatMaison();
  late final EtatOS _os = widget.os ?? EtatOS();
  late ProfilMemoire _profil = widget.profil;

  /// Le sélecteur de profil n'existe qu'en debug et dans la prévisu web.
  bool get _selecteurPermis => kDebugMode || kIsWeb;

  @override
  void dispose() {
    if (widget.os == null) _os.dispose();
    super.dispose();
  }

  void _changerProfil(ProfilMemoire profil) {
    profil.appliquer();
    setState(() => _profil = profil);
  }

  @override
  Widget build(BuildContext context) {
    return ContexteTele(
      profil: _profil,
      horloge: widget.horloge,
      changerProfil: _selecteurPermis ? _changerProfil : null,
      child: PorteeMaison(
        etat: _etat,
        child: PorteeOS(
          etat: _os,
          child: MaterialApp(
            title: 'Télé',
            debugShowCheckedModeBanner: false,
            theme: Veilleuse.theme(),
            navigatorKey: _navigateur,
            shortcuts: raccourcisTelecommande(WidgetsApp.defaultShortcuts),
            actions: {
              ...WidgetsApp.defaultActions,
              RetourIntent: CallbackAction<RetourIntent>(
                onInvoke: (_) {
                  _navigateur.currentState?.maybePop();
                  return null;
                },
              ),
              AccueilIntent: CallbackAction<AccueilIntent>(
                onInvoke: (_) {
                  _navigateur.currentState?.popUntil((r) => r.isFirst);
                  _os.allerAccueil.value++;
                  return null;
                },
              ),
            },
            builder: (context, enfant) => EchelleTele(child: enfant!),
            home: const EcranPrincipal(),
          ),
        ),
      ),
    );
  }
}
