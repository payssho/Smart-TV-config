import 'package:material_ui/material_ui.dart';

import '../ui/theme.dart';
import '../ui/tuile.dart';

/// Netflix et Canal+ tournent sous l'Android d'origine (ADR 0003, 0014) :
/// on prévient avant de redémarrer la box.
Future<void> montrerDialogueAndroid(BuildContext context, String nom) async {
  final confirme = await showGeneralDialog<bool>(
    context: context,
    barrierColor: Veilleuse.nuit.withValues(alpha: 0.82),
    barrierDismissible: false,
    transitionDuration: const Duration(milliseconds: 180),
    pageBuilder: (context, _, _) => _DialogueAndroid(nom: nom),
  );
  if (confirme == true && context.mounted) {
    await Navigator.of(context).push(
      PageRouteBuilder<void>(pageBuilder: (_, _, _) => const _Redemarrage()),
    );
  }
}

class _DialogueAndroid extends StatelessWidget {
  const _DialogueAndroid({required this.nom});

  final String nom;

  @override
  Widget build(BuildContext context) {
    final textes = Theme.of(context).textTheme;
    return Center(
      child: Container(
        width: 980,
        padding: const EdgeInsets.all(64),
        decoration: BoxDecoration(
          color: Veilleuse.ardoise,
          borderRadius: BorderRadius.circular(32),
        ),
        child: FocusTraversalGroup(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('$nom s\'ouvre sous Android', style: textes.headlineMedium),
              const SizedBox(height: 24),
              Text(
                'La box redémarre sur Android, environ 40 secondes. '
                'Pour revenir ici, choisissez « Télé maison » dans Android '
                'ou rallumez la box.',
                style: textes.bodyLarge,
              ),
              const SizedBox(height: 48),
              Row(
                children: [
                  Tuile(
                    autofocus: true,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 36,
                      vertical: 20,
                    ),
                    onActive: () => Navigator.of(context).pop(true),
                    child: Text(
                      'Redémarrer sous Android',
                      style: textes.labelLarge,
                    ),
                  ),
                  const SizedBox(width: 24),
                  Tuile(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 36,
                      vertical: 20,
                    ),
                    fond: Colors.transparent,
                    onActive: () => Navigator.of(context).pop(false),
                    child: Text('Annuler', style: textes.labelLarge),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Redemarrage extends StatelessWidget {
  const _Redemarrage();

  @override
  Widget build(BuildContext context) {
    final textes = Theme.of(context).textTheme;
    return Scaffold(
      body: Focus(
        autofocus: true,
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const SizedBox(
                width: 72,
                height: 72,
                child: CircularProgressIndicator(
                  strokeWidth: 6,
                  color: Veilleuse.ambre,
                ),
              ),
              const SizedBox(height: 48),
              Text('Redémarrage sous Android…', style: textes.headlineMedium),
              const SizedBox(height: 16),
              Text(
                'Prototype : rien ne redémarre vraiment. Retour pour revenir.',
                style: textes.bodyLarge,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
